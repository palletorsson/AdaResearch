# WordSynthBridge.gd
# Translates semantic words â†’ actual synth parameters
# Handles conflict resolution when multiple words apply
# Configuration is loaded from word_synthesis_map.json (single source of truth)

extends RefCounted
class_name WordSynthBridge

const WORD_MAP_PATH = "res://commons/audio/parameters/word_synthesis_map.json"

var _word_map: Dictionary = {}
var _param_spec: Dictionary = {}
var _conflict_rules: Dictionary = {}

# Loaded from JSON - layer-specific word weight adjustments
var layer_priority: Dictionary = {}

# Loaded from JSON - maps namespaced params to SongDevTools live_params
var param_mapping: Dictionary = {}

# Loaded from JSON - trait detection rules
var trait_rules: Dictionary = {}


func _init():
	_load_word_map()


func _load_word_map():
	if FileAccess.file_exists(WORD_MAP_PATH):
		var file = FileAccess.open(WORD_MAP_PATH, FileAccess.READ)
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		file.close()
		
		if error == OK:
			_word_map = json.data
			_param_spec = _word_map.get("param_spec", {})
			_conflict_rules = _word_map.get("conflict_rules", {})
			
			# Load centralized configs from JSON
			layer_priority = _word_map.get("layer_priority", {})
			param_mapping = _word_map.get("param_mapping", {})
			trait_rules = _word_map.get("trait_rules", {})
			
			print("WordSynthBridge: Loaded word map with %d trait rules" % trait_rules.size())
		else:
			push_warning("WordSynthBridge: Failed to parse word map")
	else:
		push_warning("WordSynthBridge: word_synthesis_map.json not found")


func get_word_params(word: String) -> Dictionary:
	"""Get raw param dict for a word"""
	for category in ["timbral_words", "envelope_words", "spatial_words", "movement_words", "experimental_words"]:
		if _word_map.get(category, {}).has(word):
			return _word_map[category][word].get("params", {})
	return {}


func get_word_category(word: String) -> String:
	"""Get category for a word"""
	for category in ["timbral_words", "envelope_words", "spatial_words", "movement_words", "experimental_words"]:
		if _word_map.get(category, {}).has(word):
			return category.replace("_words", "")
	return "unknown"


func resolve_param_value(_param_name: String, param_data) -> float:
	"""Convert word param data to a concrete value"""
	if param_data is Dictionary:
		if param_data.has("value"):
			return param_data["value"]
		elif param_data.has("range"):
			var r = param_data["range"]
			var tendency = param_data.get("tendency", "middle")
			match tendency:
				"low": return r[0] + (r[1] - r[0]) * 0.25
				"high": return r[0] + (r[1] - r[0]) * 0.75
				_: return (r[0] + r[1]) / 2.0
	elif param_data is float or param_data is int:
		return float(param_data)
	return 0.0


func words_to_live_params(layer: String, words: Array) -> Dictionary:
	"""Convert a list of words for a layer into live_params dict"""
	var result: Dictionary = {}
	var param_contributions: Dictionary = {}  # param -> [{value, weight}]
	
	var layer_key = layer.to_lower().split(" ")[0]  # "Filter Bass" â†’ "filter"
	# Map common layer names
	if "bass" in layer.to_lower(): layer_key = "bass"
	elif "pad" in layer.to_lower(): layer_key = "pad"
	elif "lead" in layer.to_lower(): layer_key = "lead"
	elif "drum" in layer.to_lower(): layer_key = "drums"
	elif "key" in layer.to_lower(): layer_key = "keys"
	
	# Check for conflicting words - later word in list wins for exclusive pairs
	var exclusive_pairs = _conflict_rules.get("exclusive_pairs", [])
	var excluded_words = {}  # word â†’ true if excluded by a later exclusive
	
	# Process in reverse to let later words win
	for i in range(words.size() - 1, -1, -1):
		var word = words[i]
		for pair in exclusive_pairs:
			if word in pair:
				for other in pair:
					if other != word and other in words and not excluded_words.has(other):
						# This word excludes earlier occurrences of its opposite
						for j in range(i):
							if words[j] == other:
								excluded_words[other] = true
	
	var active_words = []
	for word in words:
		if not excluded_words.has(word):
			active_words.append(word)
	
	# Get params from each word
	for word in active_words:
		var word_params = get_word_params(word)
		var category = get_word_category(word)
		
		# Base priority from category
		var category_priority = _conflict_rules.get("priority_groups", {}).get(category, 0.7)
		
		# Layer-specific boost
		var layer_boosts = layer_priority.get(layer_key, {})
		var word_priority = category_priority * layer_boosts.get(word, 1.0)
		
		for param_name in word_params.keys():
			var value = resolve_param_value(param_name, word_params[param_name])
			
			if not param_contributions.has(param_name):
				param_contributions[param_name] = []
			param_contributions[param_name].append({"value": value, "weight": word_priority})
	
	# Resolve conflicts via weighted average
	for param_name in param_contributions.keys():
		var contributions = param_contributions[param_name]
		var total_weight = 0.0
		var weighted_sum = 0.0
		
		for c in contributions:
			weighted_sum += c["value"] * c["weight"]
			total_weight += c["weight"]
		
		var resolved_value = weighted_sum / max(total_weight, 0.001)
		
		# Map to live_params name
		var mapping = param_mapping.get(param_name, "_unmapped")
		if mapping is Dictionary:
			var live_param = mapping.get(layer_key, mapping.get("_default", "_unmapped"))
			if live_param != "_unmapped":
				result[live_param] = resolved_value
		elif mapping is String and mapping != "_unmapped":
			result[mapping] = resolved_value
	
	return result


func apply_words_to_params(layer: String, words: Array, current_params: Dictionary) -> Dictionary:
	"""Blend word-derived params into current params"""
	var word_params = words_to_live_params(layer, words)
	var result = current_params.duplicate()
	
	for key in word_params.keys():
		if result.has(key):
			# Blend: 70% word-derived, 30% current (adjustable)
			result[key] = lerp(result[key], word_params[key], 0.7)
		else:
			result[key] = word_params[key]
	
	return result


func suggest_words_from_params(_layer: String, params: Dictionary) -> Array:
	"""Reverse mapping: given params, suggest appropriate words"""
	var suggestions: Array = []
	
	# Normalize param names (handle both namespaced and flat)
	var p = _normalize_params(params)
	
	# === TIMBRAL ===
	
	# Brightness (filter cutoff)
	var cutoff = p.get("filter.cutoff", 1000.0)
	if cutoff > 4000:
		suggestions.append("bright")
	elif cutoff < 600:
		suggestions.append("dark")
	
	# Warmth (low cutoff + some distortion + detune)
	var distortion = p.get("fx.distortion", 0.0)
	var drift = p.get("osc.drift", 0.0)
	if cutoff < 1200 and (distortion > 0.1 or drift > 0.03):
		suggestions.append("warm")
	elif cutoff > 3000 and distortion < 0.05 and drift < 0.02:
		suggestions.append("cold")
	
	# Thickness (voices + detune + sub)
	var voices = p.get("osc.voices", 1)
	var detune = p.get("osc.detune", 0.0)
	var sub = p.get("sub.level_db", -60)
	if voices >= 4 or detune > 15 or sub > -6:
		suggestions.append("thick")
	elif voices <= 1 and detune < 5:
		suggestions.append("thin")
	
	# Aggression (distortion + resonance + fast attack)
	var resonance = p.get("filter.resonance", 0.0)
	var attack = p.get("env.attack", 0.01)
	if distortion > 0.25 or (resonance > 0.6 and attack < 0.01):
		suggestions.append("aggressive")
	elif distortion < 0.1 and attack > 0.05:
		suggestions.append("soft")
	
	# Analog character
	if drift > 0.04 or distortion > 0.1:
		suggestions.append("analog")
	elif drift < 0.01 and distortion < 0.05:
		suggestions.append("digital")
	
	# === ENVELOPE ===
	
	var decay = p.get("env.decay", 0.1)
	var sustain = p.get("env.sustain", 0.5)
	var release = p.get("env.release", 0.3)
	
	if attack < 0.005 and decay < 0.2 and sustain < 0.3:
		suggestions.append("plucky")
	elif attack < 0.005 and decay < 0.1 and sustain == 0:
		suggestions.append("percussive")
	elif attack > 0.3 and sustain > 0.6:
		suggestions.append("swelling")
	elif attack > 0.2 and release > 1.0:
		suggestions.append("pad-like")
	elif sustain > 0.7:
		suggestions.append("sustained")
	
	# Punchy
	if attack < 0.005 and decay > 0.05 and decay < 0.25:
		suggestions.append("punchy")
	
	# === SPATIAL ===
	
	var reverb_mix = p.get("fx.reverb.mix", 0.0)
	var reverb_decay = p.get("fx.reverb.decay", 1.5)
	var stereo = p.get("mix.stereo_width", 1.0)
	
	if stereo > 1.2:
		suggestions.append("wide")
	elif stereo < 0.4:
		suggestions.append("narrow")
	
	if reverb_mix > 0.5 and reverb_decay > 3.0:
		suggestions.append("spacious")
	elif reverb_mix > 0.6:
		suggestions.append("dreamy")
	elif reverb_mix < 0.15:
		suggestions.append("dry")
	
	if reverb_mix > 0.4 and p.get("mix.high_shelf_db", 0) < -3:
		suggestions.append("distant")
	elif reverb_mix < 0.2 and p.get("mix.high_shelf_db", 0) > 2:
		suggestions.append("present")
	
	# === MOVEMENT ===
	
	var lfo_depth = p.get("mod.lfo.depth", 0.0)
	var lfo_rate = p.get("mod.lfo.rate", 1.0)
	var lfo_target = p.get("mod.lfo.target", "")
	var chorus = p.get("fx.chorus.depth", 0.0)
	
	if lfo_depth < 0.05 and chorus < 0.1:
		suggestions.append("static")
	elif lfo_depth > 0.2 and lfo_rate < 0.2:
		suggestions.append("evolving")
	
	if lfo_depth > 0.3 and lfo_rate > 2 and lfo_target == "amplitude":
		suggestions.append("pulsing")
	elif lfo_depth > 0.3 and lfo_target == "filter":
		suggestions.append("wobbling")
	
	if chorus > 0.3:
		suggestions.append("shimmering")
	
	# === EXPERIMENTAL ===
	
	var bitcrush = p.get("fx.bitcrush.depth", 16)
	if bitcrush < 12:
		suggestions.append("glitchy")
	if bitcrush < 10 and distortion > 0.2:
		suggestions.append("rusty")
	
	if reverb_decay > 6:
		suggestions.append("cathedral")
	elif reverb_decay < 0.5 and reverb_mix > 0.5:
		suggestions.append("claustrophobic")
	
	return suggestions


func _normalize_params(params: Dictionary) -> Dictionary:
	"""Normalize param names to namespaced format"""
	var result = params.duplicate()
	
	# Map common flat names to namespaced
	var mappings = {
		"cutoff": "filter.cutoff",
		"filter_cutoff": "filter.cutoff",
		"resonance": "filter.resonance",
		"filter_resonance": "filter.resonance",
		"attack": "env.attack",
		"decay": "env.decay",
		"sustain": "env.sustain",
		"release": "env.release",
		"voices": "osc.voices",
		"detune": "osc.detune",
		"drift": "osc.drift",
		"reverb": "fx.reverb.mix",
		"reverb_mix": "fx.reverb.mix",
		"delay": "fx.delay.mix",
		"delay_mix": "fx.delay.mix",
		"distortion": "fx.distortion",
		"chorus": "fx.chorus.depth",
		"lfo_rate": "mod.lfo.rate",
		"lfo_depth": "mod.lfo.depth",
		"stereo_width": "mix.stereo_width",
	}
	
	for flat_name in mappings.keys():
		if params.has(flat_name) and not result.has(mappings[flat_name]):
			result[mappings[flat_name]] = params[flat_name]
	
	return result


func analyze_sound(layer: String, params: Dictionary) -> Dictionary:
	"""Full analysis of a sound: params + derived words + features"""
	var words = suggest_words_from_params(layer, params)
	var p = _normalize_params(params)
	
	# Compute feature scores (0-1)
	var features = {}
	
	# Brightness
	var cutoff = p.get("filter.cutoff", 1000.0)
	features["brightness"] = clampf((log(cutoff) - log(200)) / (log(10000) - log(200)), 0, 1)
	
	# Warmth
	var warmth = 0.0
	warmth += (1.0 - features["brightness"]) * 0.4
	warmth += clampf(p.get("fx.distortion", 0) / 0.5, 0, 1) * 0.3
	warmth += clampf(p.get("osc.drift", 0) / 0.1, 0, 1) * 0.3
	features["warmth"] = clampf(warmth, 0, 1)
	
	# Movement
	var movement = 0.0
	movement += clampf(p.get("mod.lfo.depth", 0) / 0.5, 0, 1) * 0.5
	movement += clampf(p.get("fx.chorus.depth", 0) / 0.5, 0, 1) * 0.3
	movement += clampf(p.get("osc.detune", 0) / 30.0, 0, 1) * 0.2
	features["movement"] = clampf(movement, 0, 1)
	
	# Space
	var space = 0.0
	space += clampf(p.get("fx.reverb.mix", 0) / 0.8, 0, 1) * 0.5
	space += clampf(p.get("fx.reverb.decay", 1.5) / 10.0, 0, 1) * 0.3
	space += clampf((p.get("mix.stereo_width", 1.0) - 0.5) / 1.0, 0, 1) * 0.2
	features["space"] = clampf(space, 0, 1)
	
	# Thickness
	var thickness = 0.0
	thickness += clampf((p.get("osc.voices", 1) - 1) / 7.0, 0, 1) * 0.4
	thickness += clampf(p.get("osc.detune", 0) / 30.0, 0, 1) * 0.3
	thickness += clampf((p.get("sub.level_db", -60) + 60) / 66.0, 0, 1) * 0.3
	features["thickness"] = clampf(thickness, 0, 1)
	
	# Aggression
	var aggression = 0.0
	aggression += clampf(p.get("fx.distortion", 0) / 0.6, 0, 1) * 0.4
	aggression += clampf(p.get("filter.resonance", 0) / 0.8, 0, 1) * 0.3
	aggression += clampf((0.1 - p.get("env.attack", 0.01)) / 0.1, 0, 1) * 0.3
	features["aggression"] = clampf(aggression, 0, 1)
	
	return {
		"words": words,
		"features": features,
		"params": p,
		"layer": layer
	}


func get_opposites(word: String) -> Array:
	"""Get opposite words for a given word"""
	for category in ["timbral_words", "envelope_words", "spatial_words", "movement_words", "experimental_words"]:
		if _word_map.get(category, {}).has(word):
			return _word_map[category][word].get("opposites", [])
	return []


func get_all_words_in_category(category: String) -> Array:
	"""Get all words in a category"""
	var key = category + "_words" if not category.ends_with("_words") else category
	return _word_map.get(key, {}).keys()
