# ParameterRandomizer.gd
# Smart parameter randomization with constraints, grouping, and presets

extends RefCounted
class_name ParameterRandomizer

# Parameter definition with constraints
class ParamDef:
	var name: String
	var min_val: float
	var max_val: float
	var default_val: float
	var step: float = 0.0  # 0 = continuous
	var group: String = ""
	var locked: bool = false
	var randomize_range: Vector2 = Vector2(0.0, 1.0)  # Normalized range for randomization
	
	func _init(p_name: String, p_min: float, p_max: float, p_default: float = 0.0, p_group: String = ""):
		name = p_name
		min_val = p_min
		max_val = p_max
		default_val = p_default if p_default != 0.0 else (p_min + p_max) / 2.0
		group = p_group
	
	func randomize_value() -> float:
		if locked:
			return default_val
		
		var range_min = lerp(min_val, max_val, randomize_range.x)
		var range_max = lerp(min_val, max_val, randomize_range.y)
		
		var value = randf_range(range_min, range_max)
		
		if step > 0:
			value = snapped(value, step)
		
		return clamp(value, min_val, max_val)
	
	func normalize(value: float) -> float:
		return (value - min_val) / (max_val - min_val)
	
	func denormalize(normalized: float) -> float:
		return lerp(min_val, max_val, normalized)


var _params: Dictionary = {}  # name -> ParamDef
var _groups: Dictionary = {}  # group_name -> [param_names]


func add_param(name: String, min_val: float, max_val: float, default_val: float = 0.0, group: String = "") -> ParamDef:
	var param = ParamDef.new(name, min_val, max_val, default_val, group)
	_params[name] = param
	
	if group != "":
		if not _groups.has(group):
			_groups[group] = []
		_groups[group].append(name)
	
	return param


func get_param(name: String) -> ParamDef:
	return _params.get(name)


func set_locked(name: String, locked: bool):
	if _params.has(name):
		_params[name].locked = locked


func set_group_locked(group: String, locked: bool):
	if _groups.has(group):
		for param_name in _groups[group]:
			_params[param_name].locked = locked


func set_randomize_range(name: String, range_min: float, range_max: float):
	if _params.has(name):
		_params[name].randomize_range = Vector2(range_min, range_max)


func randomize_param(name: String) -> float:
	if _params.has(name):
		return _params[name].randomize_value()
	return 0.0


func randomize_group(group: String) -> Dictionary:
	var result = {}
	if _groups.has(group):
		for param_name in _groups[group]:
			result[param_name] = _params[param_name].randomize_value()
	return result


func randomize_all() -> Dictionary:
	var result = {}
	for param_name in _params.keys():
		result[param_name] = _params[param_name].randomize_value()
	return result


func randomize_unlocked() -> Dictionary:
	var result = {}
	for param_name in _params.keys():
		if not _params[param_name].locked:
			result[param_name] = _params[param_name].randomize_value()
	return result


func get_defaults() -> Dictionary:
	var result = {}
	for param_name in _params.keys():
		result[param_name] = _params[param_name].default_val
	return result


func get_groups() -> Array:
	return _groups.keys()


func get_group_params(group: String) -> Array:
	return _groups.get(group, [])


# Chaos modes - different randomization strategies
enum ChaosMode {
	UNIFORM,      # Pure random within constraints
	CONSERVATIVE, # Small deviations from current values
	EXTREME,      # Push toward extremes
	MUSICAL,      # Weighted toward "nice" values
	EVOLVE        # Gradual mutation over time
}

var _evolution_memory: Dictionary = {}


func randomize_with_mode(current_values: Dictionary, chaos_mode: ChaosMode, intensity: float = 1.0) -> Dictionary:
	var result = current_values.duplicate()
	
	match chaos_mode:
		ChaosMode.UNIFORM:
			for param_name in _params.keys():
				if not _params[param_name].locked:
					result[param_name] = _params[param_name].randomize_value()
		
		ChaosMode.CONSERVATIVE:
			# Small deviations from current
			for param_name in _params.keys():
				if not _params[param_name].locked and current_values.has(param_name):
					var param = _params[param_name]
					var current = current_values[param_name]
					var range_size = (param.max_val - param.min_val) * 0.1 * intensity
					var delta = randf_range(-range_size, range_size)
					result[param_name] = clamp(current + delta, param.min_val, param.max_val)
		
		ChaosMode.EXTREME:
			# Push toward min or max
			for param_name in _params.keys():
				if not _params[param_name].locked:
					var param = _params[param_name]
					var target = param.max_val if randf() > 0.5 else param.min_val
					var current = current_values.get(param_name, param.default_val)
					result[param_name] = lerp(current, target, intensity * randf())
		
		ChaosMode.MUSICAL:
			# Weighted toward "good" values (middle, common ratios)
			for param_name in _params.keys():
				if not _params[param_name].locked:
					var param = _params[param_name]
					var weights = [0.25, 0.33, 0.5, 0.67, 0.75]  # Common musical ratios
					var weight = weights[randi() % weights.size()]
					var base = param.denormalize(weight)
					var range_size = (param.max_val - param.min_val) * 0.2 * intensity
					result[param_name] = clamp(base + randf_range(-range_size, range_size), param.min_val, param.max_val)
		
		ChaosMode.EVOLVE:
			# Gradual mutation - remember and build on previous
			for param_name in _params.keys():
				if not _params[param_name].locked:
					var param = _params[param_name]
					var current = current_values.get(param_name, param.default_val)
					
					# Small mutation
					var mutation = randf_range(-0.05, 0.05) * (param.max_val - param.min_val) * intensity
					var new_val = clamp(current + mutation, param.min_val, param.max_val)
					
					# Occasionally jump (5% chance)
					if randf() < 0.05 * intensity:
						new_val = param.randomize_value()
					
					result[param_name] = new_val
	
	return result


# Setup typical synth parameters
static func create_synth_randomizer() -> ParameterRandomizer:
	var r = ParameterRandomizer.new()
	
	# Oscillator
	r.add_param("osc_mix", 0.0, 1.0, 0.5, "oscillator")
	r.add_param("osc_detune", 0.0, 50.0, 10.0, "oscillator")
	r.add_param("osc_voices", 1.0, 8.0, 4.0, "oscillator").step = 1.0
	
	# Filter
	r.add_param("filter_cutoff", 100.0, 8000.0, 2000.0, "filter")
	r.add_param("filter_resonance", 0.0, 1.0, 0.3, "filter")
	r.add_param("filter_env_amount", 0.0, 1.0, 0.5, "filter")
	
	# Envelope
	r.add_param("env_attack", 0.001, 2.0, 0.01, "envelope")
	r.add_param("env_decay", 0.01, 2.0, 0.3, "envelope")
	r.add_param("env_sustain", 0.0, 1.0, 0.7, "envelope")
	r.add_param("env_release", 0.01, 4.0, 0.5, "envelope")
	
	# Effects
	r.add_param("reverb_mix", 0.0, 1.0, 0.2, "effects")
	r.add_param("delay_mix", 0.0, 1.0, 0.15, "effects")
	r.add_param("delay_time", 0.05, 1.0, 0.375, "effects")
	r.add_param("chorus_depth", 0.0, 1.0, 0.3, "effects")
	
	# Output
	r.add_param("volume", -24.0, 6.0, 0.0, "output")
	r.add_param("pan", -1.0, 1.0, 0.0, "output")
	
	return r
