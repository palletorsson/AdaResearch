# SoundIdentity.gd
# Dual representation of a sound: perceptual traits + generative recipe
# Enables bidirectional understanding: "what is it" ↔ "how is it made"

extends RefCounted
class_name SoundIdentity

# === PERCEPTUAL LAYER (what it sounds like) ===

# Traits organized by category
var traits: Dictionary = {
	"timbral": [],    # warm, bright, thick, aggressive...
	"envelope": [],   # plucky, sustained, swelling...
	"spatial": [],    # wide, dry, spacious, distant...
	"movement": [],   # evolving, pulsing, static...
	"character": []   # analog, digital, lo-fi, clean...
}

# Normalized feature vector (0-1) for similarity/interpolation
var features: Dictionary = {
	"brightness": 0.5,
	"warmth": 0.5,
	"thickness": 0.5,
	"aggression": 0.3,
	"space": 0.3,
	"movement": 0.2,
	"attack_speed": 0.5,
	"decay_length": 0.5,
	"width": 0.5
}

# Confidence scores for each trait (how strongly it applies)
var trait_confidence: Dictionary = {}  # trait_name → 0.0-1.0


# === GENERATIVE LAYER (how it's made) ===

# Signal chain recipe
var recipe: Array = []  # Array of RecipeNode

# Raw parameter values (namespaced)
var params: Dictionary = {}


# === EXPLANATION LAYER (why) ===

# Maps trait → reasons (which params caused it)
var trait_sources: Dictionary = {}  # trait_name → [explanations]

# Maps param → effects (what traits it influences)
var param_effects: Dictionary = {}  # param_name → [trait_names]


# === METADATA ===

var name: String = ""
var layer_type: String = ""  # bass, pad, lead, drums, etc.
var synth_type: String = ""  # "Juno-106 DCO", "303 acid", etc.


# === CONSTRUCTION ===

static func from_params(layer: String, raw_params: Dictionary) -> SoundIdentity:
	"""Create SoundIdentity by analyzing parameters"""
	var identity = SoundIdentity.new()
	identity.name = layer
	identity.layer_type = _classify_layer(layer)
	identity.params = raw_params.duplicate()
	identity.synth_type = raw_params.get("type", "unknown")
	
	# Build recipe from params
	identity._build_recipe()
	
	# Derive features from params
	identity._compute_features()
	
	# Derive traits from features + params
	identity._derive_traits()
	
	# Build explanations
	identity._build_explanations()
	
	return identity


static func _classify_layer(name: String) -> String:
	var lower = name.to_lower()
	if "bass" in lower: return "bass"
	if "pad" in lower: return "pad"
	if "lead" in lower: return "lead"
	if "key" in lower: return "keys"
	if "drum" in lower or "kick" in lower or "snare" in lower: return "drums"
	if "arp" in lower: return "arp"
	if "seq" in lower: return "sequencer"
	if "stab" in lower: return "stab"
	if "string" in lower: return "strings"
	return "other"


# === RECIPE BUILDING ===

class RecipeNode:
	var type: String  # osc, filter, env, fx, mod
	var subtype: String  # saw, lowpass, ADSR, reverb, lfo
	var params: Dictionary
	var contributes_to: Array = []  # which traits this node affects
	
	func _to_string() -> String:
		return "[%s:%s]" % [type, subtype]


func _build_recipe():
	"""Convert flat params into signal chain"""
	recipe.clear()
	
	# 1. Oscillator
	var osc = RecipeNode.new()
	osc.type = "osc"
	osc.subtype = _infer_osc_type()
	osc.params = {
		"voices": params.get("osc.voices", 1),
		"detune": params.get("osc.detune", 0),
		"drift": params.get("osc.drift", 0)
	}
	osc.contributes_to = ["thickness", "warmth", "movement"]
	recipe.append(osc)
	
	# 2. Filter
	var filter = RecipeNode.new()
	filter.type = "filter"
	filter.subtype = params.get("filter.type", "lowpass")
	filter.params = {
		"cutoff": params.get("filter.cutoff", 1000),
		"resonance": params.get("filter.resonance", 0)
	}
	filter.contributes_to = ["brightness", "warmth", "aggression"]
	recipe.append(filter)
	
	# 3. Envelope
	var env = RecipeNode.new()
	env.type = "env"
	env.subtype = "ADSR"
	env.params = {
		"attack": params.get("env.attack", 0.01),
		"decay": params.get("env.decay", 0.1),
		"sustain": params.get("env.sustain", 0.7),
		"release": params.get("env.release", 0.3)
	}
	env.contributes_to = ["attack_speed", "decay_length"]
	recipe.append(env)
	
	# 4. Effects (if present)
	if params.get("fx.distortion", 0) > 0.05:
		var dist = RecipeNode.new()
		dist.type = "fx"
		dist.subtype = "distortion"
		dist.params = {"drive": params.get("fx.distortion", 0)}
		dist.contributes_to = ["warmth", "aggression"]
		recipe.append(dist)
	
	if params.get("fx.chorus.depth", 0) > 0.05:
		var chorus = RecipeNode.new()
		chorus.type = "fx"
		chorus.subtype = "chorus"
		chorus.params = {
			"depth": params.get("fx.chorus.depth", 0),
			"rate": params.get("fx.chorus.rate", 1.0)
		}
		chorus.contributes_to = ["width", "movement"]
		recipe.append(chorus)
	
	if params.get("fx.reverb.mix", 0) > 0.1:
		var reverb = RecipeNode.new()
		reverb.type = "fx"
		reverb.subtype = "reverb"
		reverb.params = {
			"mix": params.get("fx.reverb.mix", 0),
			"decay": params.get("fx.reverb.decay", 1.5)
		}
		reverb.contributes_to = ["space", "width"]
		recipe.append(reverb)
	
	if params.get("fx.delay.mix", 0) > 0.1:
		var delay = RecipeNode.new()
		delay.type = "fx"
		delay.subtype = "delay"
		delay.params = {
			"mix": params.get("fx.delay.mix", 0),
			"time": params.get("fx.delay.time", 0.25)
		}
		delay.contributes_to = ["space", "movement"]
		recipe.append(delay)
	
	# 5. Modulation
	if params.get("mod.lfo.depth", 0) > 0.05:
		var lfo = RecipeNode.new()
		lfo.type = "mod"
		lfo.subtype = "lfo"
		lfo.params = {
			"rate": params.get("mod.lfo.rate", 1.0),
			"depth": params.get("mod.lfo.depth", 0),
			"target": params.get("mod.lfo.target", "filter")
		}
		lfo.contributes_to = ["movement"]
		recipe.append(lfo)


func _infer_osc_type() -> String:
	var type_hint = params.get("type", "").to_lower()
	if "saw" in type_hint: return "saw"
	if "square" in type_hint: return "square"
	if "sine" in type_hint or "sub" in type_hint: return "sine"
	if "fm" in type_hint: return "fm"
	if "wavetable" in type_hint: return "wavetable"
	if "noise" in type_hint: return "noise"
	# Default based on layer type
	match layer_type:
		"bass": return "saw"
		"pad": return "saw"
		"lead": return "saw"
		"keys": return "fm"
		_: return "saw"


# === FEATURE COMPUTATION ===

func _compute_features():
	"""Compute normalized feature values from params"""
	var p = params
	
	# Brightness (filter cutoff, high shelf)
	var cutoff = p.get("filter.cutoff", 1000.0)
	features["brightness"] = clampf((log(cutoff) - log(200)) / (log(12000) - log(200)), 0, 1)
	
	# Warmth (low cutoff + distortion + analog drift)
	var warmth = 0.0
	warmth += (1.0 - features["brightness"]) * 0.4
	warmth += clampf(p.get("fx.distortion", 0) / 0.4, 0, 1) * 0.3
	warmth += clampf(p.get("osc.drift", 0) / 0.1, 0, 1) * 0.3
	features["warmth"] = clampf(warmth, 0, 1)
	
	# Thickness (voices + detune + sub)
	var thickness = 0.0
	thickness += clampf((p.get("osc.voices", 1) - 1) / 7.0, 0, 1) * 0.4
	thickness += clampf(p.get("osc.detune", 0) / 30.0, 0, 1) * 0.3
	thickness += clampf((p.get("sub.level_db", -60) + 60) / 66.0, 0, 1) * 0.3
	features["thickness"] = clampf(thickness, 0, 1)
	
	# Aggression (distortion + resonance + fast attack)
	var aggression = 0.0
	aggression += clampf(p.get("fx.distortion", 0) / 0.5, 0, 1) * 0.4
	aggression += clampf(p.get("filter.resonance", 0) / 0.8, 0, 1) * 0.3
	aggression += clampf((0.05 - p.get("env.attack", 0.01)) / 0.05, 0, 1) * 0.3
	features["aggression"] = clampf(aggression, 0, 1)
	
	# Space (reverb + delay)
	var space = 0.0
	space += clampf(p.get("fx.reverb.mix", 0) / 0.7, 0, 1) * 0.6
	space += clampf(p.get("fx.delay.mix", 0) / 0.5, 0, 1) * 0.4
	features["space"] = clampf(space, 0, 1)
	
	# Movement (LFO + chorus + detune)
	var movement = 0.0
	movement += clampf(p.get("mod.lfo.depth", 0) / 0.5, 0, 1) * 0.5
	movement += clampf(p.get("fx.chorus.depth", 0) / 0.5, 0, 1) * 0.3
	movement += clampf(p.get("osc.detune", 0) / 20.0, 0, 1) * 0.2
	features["movement"] = clampf(movement, 0, 1)
	
	# Attack speed (inverse of attack time)
	var attack = p.get("env.attack", 0.01)
	features["attack_speed"] = clampf(1.0 - (log(attack + 0.001) - log(0.001)) / (log(2.0) - log(0.001)), 0, 1)
	
	# Decay length
	var decay = p.get("env.decay", 0.1)
	var release = p.get("env.release", 0.3)
	features["decay_length"] = clampf((log(decay + release + 0.01) - log(0.01)) / (log(10.0) - log(0.01)), 0, 1)
	
	# Width (stereo + chorus + reverb)
	var width = 0.0
	width += clampf((p.get("mix.stereo_width", 1.0) - 0.5) / 1.0, 0, 1) * 0.4
	width += clampf(p.get("fx.chorus.depth", 0) / 0.5, 0, 1) * 0.3
	width += clampf(p.get("fx.reverb.mix", 0) / 0.6, 0, 1) * 0.3
	features["width"] = clampf(width, 0, 1)


# === TRAIT DERIVATION ===

const WORD_MAP_PATH = "res://commons/audio/parameters/word_synthesis_map.json"

# Trait rules loaded from JSON - single source of truth
static var _trait_rules: Dictionary = {}
static var _trait_rules_loaded: bool = false


static func _load_trait_rules():
	"""Load trait rules from JSON config"""
	if _trait_rules_loaded:
		return
	
	if FileAccess.file_exists(WORD_MAP_PATH):
		var file = FileAccess.open(WORD_MAP_PATH, FileAccess.READ)
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		file.close()
		
		if error == OK:
			_trait_rules = json.data.get("trait_rules", {})
			print("SoundIdentity: Loaded %d trait rules from JSON" % _trait_rules.size())
		else:
			push_warning("SoundIdentity: Failed to parse word_synthesis_map.json")
			_load_fallback_rules()
	else:
		push_warning("SoundIdentity: word_synthesis_map.json not found, using fallback")
		_load_fallback_rules()
	
	_trait_rules_loaded = true


static func _load_fallback_rules():
	"""Fallback rules if JSON fails to load"""
	_trait_rules = {
		"bright": {"feature": "brightness", "min": 0.65, "category": "timbral"},
		"dark": {"feature": "brightness", "max": 0.35, "category": "timbral"},
		"warm": {"feature": "warmth", "min": 0.55, "category": "timbral"},
		"cold": {"feature": "warmth", "max": 0.3, "category": "timbral"},
		"thick": {"feature": "thickness", "min": 0.55, "category": "timbral"},
		"thin": {"feature": "thickness", "max": 0.3, "category": "timbral"},
		"spacious": {"feature": "space", "min": 0.55, "category": "spatial"},
		"dry": {"feature": "space", "max": 0.2, "category": "spatial"},
	}


static func get_trait_rules() -> Dictionary:
	"""Get trait rules (loads from JSON if needed)"""
	_load_trait_rules()
	return _trait_rules


func _derive_traits():
	"""Apply trait rules to determine which traits apply"""
	# Clear existing
	for cat in traits.keys():
		traits[cat].clear()
	trait_confidence.clear()
	
	var rules = SoundIdentity.get_trait_rules()
	for trait_name in rules.keys():
		var rule = rules[trait_name]
		var confidence = _evaluate_rule(rule)
		
		if confidence > 0.5:
			var category = rule.get("category", "timbral")
			if not trait_name in traits[category]:
				traits[category].append(trait_name)
			trait_confidence[trait_name] = confidence


func _evaluate_rule(rule: Dictionary) -> float:
	"""Evaluate a trait rule, return confidence 0-1"""
	var score = 1.0
	var conditions_met = 0
	var total_conditions = 0
	
	# Feature-based conditions
	if rule.has("feature"):
		total_conditions += 1
		var val = features.get(rule["feature"], 0.5)
		if rule.has("min") and val >= rule["min"]:
			conditions_met += 1
			score *= (val - rule["min"]) / (1.0 - rule["min"]) * 0.5 + 0.5
		elif rule.has("max") and val <= rule["max"]:
			conditions_met += 1
			score *= (rule["max"] - val) / rule["max"] * 0.5 + 0.5
		else:
			return 0.0
	
	if rule.has("feature2"):
		total_conditions += 1
		var val = features.get(rule["feature2"], 0.5)
		if rule.has("min2") and val >= rule["min2"]:
			conditions_met += 1
		elif rule.has("max2") and val <= rule["max2"]:
			conditions_met += 1
		else:
			return 0.0
	
	# Param-based conditions
	if rule.has("param"):
		total_conditions += 1
		var val = params.get(rule["param"], 0)
		if rule.has("equals"):
			if str(val) == str(rule["equals"]):
				conditions_met += 1
			else:
				return 0.0
		elif rule.has("min") and not rule.has("feature"):
			if val >= rule["min"]:
				conditions_met += 1
			else:
				return 0.0
		elif rule.has("max") and not rule.has("feature"):
			if val <= rule["max"]:
				conditions_met += 1
			else:
				return 0.0
		else:
			conditions_met += 1
	
	if rule.has("param2"):
		total_conditions += 1
		var val = params.get(rule["param2"], 0)
		if rule.has("min2") and val >= rule["min2"]:
			conditions_met += 1
		elif rule.has("max2") and val <= rule["max2"]:
			conditions_met += 1
		else:
			return 0.0
	
	if total_conditions == 0:
		return 0.0
	
	return score * (float(conditions_met) / float(total_conditions))


# === EXPLANATION BUILDING ===

func _build_explanations():
	"""Build bidirectional explanations"""
	trait_sources.clear()
	param_effects.clear()
	
	# For each derived trait, explain why
	for category in traits.keys():
		for trait_name in traits[category]:
			trait_sources[trait_name] = _explain_trait(trait_name)
	
	# For each param, list what traits it affects
	for node in recipe:
		for param_name in node.params.keys():
			var full_name = "%s.%s" % [node.type, param_name]
			param_effects[full_name] = node.contributes_to.duplicate()


func _explain_trait(trait_name: String) -> Array:
	"""Generate human-readable explanations for why a trait applies"""
	var explanations = []
	var rules = SoundIdentity.get_trait_rules()
	
	if not rules.has(trait_name):
		return explanations
	
	var rule = rules[trait_name]
	
	# Feature-based explanation
	if rule.has("feature"):
		var feature_name = rule["feature"]
		var val = features.get(feature_name, 0)
		if rule.has("min"):
			explanations.append("%s is high (%.0f%%)" % [feature_name, val * 100])
		elif rule.has("max"):
			explanations.append("%s is low (%.0f%%)" % [feature_name, val * 100])
	
	# Param-based explanation
	if rule.has("param"):
		var param_name = rule["param"]
		var val = params.get(param_name, 0)
		if rule.has("equals"):
			explanations.append("%s = %s" % [param_name, val])
		elif rule.has("min"):
			explanations.append("%s ≥ %.2f (is %.2f)" % [param_name, rule["min"], val])
		elif rule.has("max"):
			explanations.append("%s ≤ %.2f (is %.2f)" % [param_name, rule["max"], val])
	
	# Add contributing recipe nodes
	for node in recipe:
		if trait_name in _get_traits_for_feature(node.contributes_to):
			var param_strs = []
			for k in node.params.keys():
				param_strs.append("%s=%.2f" % [k, node.params[k]] if node.params[k] is float else "%s=%s" % [k, node.params[k]])
			explanations.append("via %s (%s)" % [node, ", ".join(param_strs)])
	
	return explanations


func _get_traits_for_feature(feature_names: Array) -> Array:
	"""Get traits that depend on given features"""
	var result = []
	var rules = SoundIdentity.get_trait_rules()
	for trait_name in rules.keys():
		var rule = rules[trait_name]
		if rule.has("feature") and rule["feature"] in feature_names:
			result.append(trait_name)
	return result


# === QUERIES ===

func get_all_traits() -> Array:
	"""Get flat list of all traits"""
	var result = []
	for category in traits.keys():
		result.append_array(traits[category])
	return result


func get_trait_explanation(trait_name: String) -> String:
	"""Get human-readable explanation for a trait"""
	if trait_sources.has(trait_name):
		return "\n".join(trait_sources[trait_name])
	return "Unknown"


func get_param_impact(param_name: String) -> Array:
	"""Get what traits a param affects"""
	return param_effects.get(param_name, [])


func get_recipe_string() -> String:
	"""Get signal chain as readable string"""
	var parts = []
	for node in recipe:
		parts.append(str(node))
	return " → ".join(parts)


func get_feature_vector() -> PackedFloat32Array:
	"""Get feature values as array (for similarity computation)"""
	var vec = PackedFloat32Array()
	vec.append(features["brightness"])
	vec.append(features["warmth"])
	vec.append(features["thickness"])
	vec.append(features["aggression"])
	vec.append(features["space"])
	vec.append(features["movement"])
	vec.append(features["attack_speed"])
	vec.append(features["decay_length"])
	vec.append(features["width"])
	return vec


static func similarity(a: SoundIdentity, b: SoundIdentity) -> float:
	"""Compute similarity between two sounds (0-1)"""
	var vec_a = a.get_feature_vector()
	var vec_b = b.get_feature_vector()
	
	# Cosine similarity
	var dot = 0.0
	var mag_a = 0.0
	var mag_b = 0.0
	
	for i in range(vec_a.size()):
		dot += vec_a[i] * vec_b[i]
		mag_a += vec_a[i] * vec_a[i]
		mag_b += vec_b[i] * vec_b[i]
	
	if mag_a == 0 or mag_b == 0:
		return 0.0
	
	return dot / (sqrt(mag_a) * sqrt(mag_b))


# === MODIFICATION SUGGESTIONS ===

func suggest_changes_for_trait(target_trait: String) -> Dictionary:
	"""Suggest param changes to achieve a target trait"""
	var rules = SoundIdentity.get_trait_rules()
	if not rules.has(target_trait):
		return {}
	
	var rule = rules[target_trait]
	var suggestions = {}
	
	# Feature-based suggestions
	if rule.has("feature"):
		var feature_name = rule["feature"]
		var current = features.get(feature_name, 0.5)
		var target = rule.get("min", rule.get("max", 0.5))
		
		if rule.has("min") and current < target:
			suggestions[feature_name] = {"direction": "increase", "current": current, "target": target}
		elif rule.has("max") and current > target:
			suggestions[feature_name] = {"direction": "decrease", "current": current, "target": target}
	
	# Map feature suggestions to param suggestions
	var param_suggestions = {}
	for feature_name in suggestions.keys():
		var direction = suggestions[feature_name]["direction"]
		match feature_name:
			"brightness":
				param_suggestions["filter.cutoff"] = "increase" if direction == "increase" else "decrease"
			"warmth":
				if direction == "increase":
					param_suggestions["filter.cutoff"] = "decrease"
					param_suggestions["fx.distortion"] = "increase"
					param_suggestions["osc.drift"] = "increase"
				else:
					param_suggestions["filter.cutoff"] = "increase"
					param_suggestions["fx.distortion"] = "decrease"
			"thickness":
				param_suggestions["osc.voices"] = "increase" if direction == "increase" else "decrease"
				param_suggestions["osc.detune"] = "increase" if direction == "increase" else "decrease"
			"space":
				param_suggestions["fx.reverb.mix"] = "increase" if direction == "increase" else "decrease"
			"movement":
				param_suggestions["mod.lfo.depth"] = "increase" if direction == "increase" else "decrease"
				param_suggestions["fx.chorus.depth"] = "increase" if direction == "increase" else "decrease"
	
	return param_suggestions


func to_dict() -> Dictionary:
	"""Serialize to dictionary"""
	return {
		"name": name,
		"layer_type": layer_type,
		"synth_type": synth_type,
		"traits": traits,
		"features": features,
		"trait_confidence": trait_confidence,
		"params": params,
		"recipe": get_recipe_string(),
		"trait_sources": trait_sources
	}
