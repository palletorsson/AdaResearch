# WordSynthBridge.gd
# Translates semantic words → actual synth parameters
# Handles conflict resolution when multiple words apply

extends RefCounted
class_name WordSynthBridge

const WORD_MAP_PATH = "res://commons/audio/parameters/word_synthesis_map.json"

var _word_map: Dictionary = {}
var _param_spec: Dictionary = {}
var _conflict_rules: Dictionary = {}

# Layer-specific priority overrides (bass prefers warmth, lead prefers brightness)
var layer_priority: Dictionary = {
	"bass": {"warm": 1.2, "thick": 1.3, "subby": 1.4, "bright": 0.7, "thin": 0.5},
	"pad": {"wide": 1.2, "evolving": 1.2, "dreamy": 1.3, "punchy": 0.6},
	"lead": {"bright": 1.2, "aggressive": 1.1, "present": 1.2, "warm": 0.8, "soft": 0.7},
	"drums": {"punchy": 1.3, "crisp": 1.2, "soft": 0.6},
	"keys": {"warm": 1.1, "plucky": 1.2, "glassy": 1.1}
}

# Map from word_synthesis_map param names → SongDevTools live_params names
var param_mapping: Dictionary = {
	# Filter
	"filter.cutoff": {
		"bass": "bass_filter_cutoff",
		"pad": "pad_filter_cutoff",
		"lead": "lead_filter_cutoff",
		"_default": "bass_filter_cutoff"
	},
	"filter.resonance": {
		"bass": "bass_filter_resonance",
		"_default": "bass_filter_resonance"
	},
	# Oscillator
	"osc.detune": {
		"pad": "pad_detune",
		"_default": "pad_detune"
	},
	# Envelope (not yet in live_params, but could be added)
	"env.attack": "_unmapped",
	"env.decay": "_unmapped",
	"env.sustain": "_unmapped",
	"env.release": "_unmapped",
	# FX
	"fx.reverb.mix": {
		"_default": "reverb_mix"
	},
	"fx.delay.mix": {
		"_default": "delay_mix"
	},
	"fx.delay.time": {
		"_default": "delay_time"
	},
	# Volume
	"mix.volume_db": {
		"bass": "bass_volume",
		"pad": "pad_volume",
		"lead": "lead_volume",
		"drums": "drums_volume",
		"_default": "master_volume"
	},
	# Modulation
	"mod.lfo.depth": {
		"lead": "lead_vibrato_depth",
		"_default": "lead_vibrato_depth"
	}
}


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
			print("WordSynthBridge: Loaded word map")
		else:
			push_warning("WordSynthBridge: Failed to parse word map")


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


func resolve_param_value(param_name: String, param_data) -> float:
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
	
	var layer_key = layer.to_lower().split(" ")[0]  # "Filter Bass" → "filter"
	# Map common layer names
	if "bass" in layer.to_lower(): layer_key = "bass"
	elif "pad" in layer.to_lower(): layer_key = "pad"
	elif "lead" in layer.to_lower(): layer_key = "lead"
	elif "drum" in layer.to_lower(): layer_key = "drums"
	elif "key" in layer.to_lower(): layer_key = "keys"
	
	# Check for conflicting words
	var exclusive_pairs = _conflict_rules.get("exclusive_pairs", [])
	var active_words = []
	for word in words:
		var dominated = false
		for pair in exclusive_pairs:
			if word in pair:
				for other in pair:
					if other != word and other in words:
						# Both exclusive words present - later one wins for now
						# (could do weighted blend instead)
						pass
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


func suggest_words_from_params(layer: String, params: Dictionary) -> Array:
	"""Reverse mapping: given params, suggest appropriate words"""
	# TODO: Implement feature extraction from param_spec["features"]
	# For now, simple threshold matching
	var suggestions = []
	
	var layer_key = layer.to_lower()
	if "bass" in layer_key: layer_key = "bass"
	elif "pad" in layer_key: layer_key = "pad"
	elif "lead" in layer_key: layer_key = "lead"
	
	# Get filter cutoff for brightness check
	var cutoff_param = param_mapping.get("filter.cutoff", {})
	var cutoff_key = cutoff_param.get(layer_key, cutoff_param.get("_default", ""))
	var cutoff = params.get(cutoff_key, 1000.0)
	
	if cutoff > 4000:
		suggestions.append("bright")
	elif cutoff < 500:
		suggestions.append("dark")
	elif cutoff < 1000:
		suggestions.append("warm")
	
	# Reverb check
	var reverb = params.get("reverb_mix", 0.0)
	if reverb > 0.5:
		suggestions.append("spacious")
	elif reverb < 0.15:
		suggestions.append("dry")
	
	# Could expand with full feature extraction...
	
	return suggestions


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
