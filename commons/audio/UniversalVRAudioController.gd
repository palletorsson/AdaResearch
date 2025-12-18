@tool
extends Node3D

## Universal VR Audio Controller (UVAC)
## The central brain of the modular synth rack.

const SLIDER_SCENE = preload("res://commons/audio/interfaces/VRAudioControlSlider.tscn")
const DIAL_SCENE = preload("res://commons/audio/interfaces/VRAudioControlDial.tscn")

signal sound_played(stream)

@onready var parameter_container = $ParameterGrid
@onready var preview_player = $AudioStreamPlayer3D
@onready var category_label = $SelectionPanel/CategoryLabel
@onready var sound_label = $SelectionPanel/SoundLabel

var current_category: String = "basic"
var current_sound_key: String = "basic_sine_wave"
var active_controls: Dictionary = {}

var categories = ["basic", "synth", "noir", "trap"]
var sounds_in_category = []

func _ready():
	# Connect buttons
	$Buttons/PlayButton/InteractableAreaButton.button_pressed.connect(_on_play_pressed)
	$Buttons/SaveButton/InteractableAreaButton.button_pressed.connect(_on_save_pressed)
	
	# Connect selection dials
	$SelectionPanel/CategoryDial.hinge_moved.connect(_on_category_dial_moved)
	$SelectionPanel/SoundDial.hinge_moved.connect(_on_sound_dial_moved)
	
	_update_category(0)
	load_sound(current_sound_key)

func _on_category_dial_moved(angle):
	var idx = int(remap(angle, -150, 150, 0, categories.size() - 1))
	if categories[idx] != current_category:
		_update_category(idx)

func _on_sound_dial_moved(angle):
	if sounds_in_category.is_empty(): return
	var idx = int(remap(angle, -150, 150, 0, sounds_in_category.size() - 1))
	if sounds_in_category[idx] != current_sound_key:
		load_sound(sounds_in_category[idx])

func _update_category(idx: int):
	current_category = categories[idx]
	category_label.text = current_category.to_upper()
	# Get all available sound types and filter by category (or just show all for now)
	sounds_in_category = SoundParameterManager.get_available_sound_types()
	
	# Simple filter for demo purposes
	if current_category != "all":
		var filtered = []
		for s in sounds_in_category:
			if current_category in s.to_lower():
				filtered.append(s)
		if filtered.is_empty(): filtered = [sounds_in_category[0]]
		sounds_in_category = filtered
		
	current_sound_key = sounds_in_category[0]
	sound_label.text = current_sound_key.capitalize().replace("_", " ")
	load_sound(current_sound_key)

func _on_play_pressed(_btn):
	play_current_sound()

func _on_save_pressed(_btn):
	var values = _get_current_values()
	SoundParameterManager.save_sound_parameters(current_sound_key, values)

func _get_mock_sounds_for_category(_cat: String) -> Array:
	return SoundParameterManager.get_available_sound_types()

func load_sound(sound_key: String):
	current_sound_key = sound_key
	var params = SoundParameterManager.get_sound_parameters(sound_key)
	_clear_controls()
	_spawn_controls(params)

func _clear_controls():
	for child in parameter_container.get_children():
		child.queue_free()
	active_controls.clear()

func _spawn_controls(params: Dictionary):
	var count = 0
	# Get defaults to fill in missing min/max if we have flat params
	var defaults = SoundParameterManager.get_sound_parameters(current_sound_key)
	
	for p_name in params.keys():
		var p_data = params[p_name]
		
		# Define range and current value
		var val = 0.5
		var p_min = 0.0
		var p_max = 1.0
		
		if p_data is Dictionary:
			val = p_data.get("value", 0.5)
			p_min = p_data.get("min", 0.0)
			p_max = p_data.get("max", 1.0)
		else:
			# Flat param, try to find range in defaults
			val = float(p_data)
			var d_data = defaults.get(p_name, {})
			if d_data is Dictionary:
				p_min = d_data.get("min", 0.0)
				p_max = d_data.get("max", 1.0)
			else:
				# Fallback range logic
				if "freq" in p_name: p_max = 2000.0
				elif "amp" in p_name: p_max = 1.0
				elif "dur" in p_name: p_max = 10.0
		
		# Choose Dial for specific keywords
		var control
		if _is_dial_param(p_name):
			control = DIAL_SCENE.instantiate()
		else:
			control = SLIDER_SCENE.instantiate()
			
		parameter_container.add_child(control)
		control.transform.origin = _get_layout_position(count)
		control.set_param_name(p_name)
		
		# Set initial values
		var norm = remap(val, p_min, p_max, 0.0, 1.0)
		if control.has_method("set_normalized_value"):
			control.set_normalized_value(norm)
			
		# Connect real-time updates
		if control.has_signal("slider_moved"):
			control.slider_moved.connect(_on_parameter_changed.bind(p_name))
		elif control.has_signal("hinge_moved"):
			control.hinge_moved.connect(_on_parameter_changed.bind(p_name))
			
		active_controls[p_name] = control
		count += 1

var _update_timer: SceneTreeTimer = null

func _on_parameter_changed(_value, _p_name: String):
	# Real-time tweak with debounce to prevent stuttering
	if _update_timer: return
	
	_update_timer = get_tree().create_timer(0.05) # 50ms is enough for snappy feedback
	_update_timer.timeout.connect(func(): 
		_update_timer = null
		play_current_sound()
	)

func _is_dial_param(p_name: String) -> bool:
	var dial_keywords = ["hard", "qual", "ring", "mod", "detune", "blend", "category", "sound"]
	for k in dial_keywords:
		if k in p_name.to_lower(): return true
	return false

func _get_layout_position(index: int) -> Vector3:
	# 2 columns for wider horizontal sliders
	var col_spacing = 0.22
	var row_spacing = 0.1
	var cols = 2
	
	var x = (index % cols) * col_spacing
	var y = -floor(index / float(cols)) * row_spacing
	
	# Center the grid and move up towards the display
	return Vector3(x - ((cols-1) * col_spacing * 0.5), y + 0.05, 0)

func play_current_sound():
	var values = _get_current_values()
	var sound_type = _resolve_sound_type(current_sound_key)
	
	var stream = CustomSoundGenerator.generate_custom_sound(sound_type, values)
	if stream:
		preview_player.stream = stream
		preview_player.play()
		sound_played.emit(stream)

func _get_current_values() -> Dictionary:
	var values = {}
	# Get defaults to ensure we have ranges even if current params are flat
	var defaults = SoundParameterManager.get_sound_parameters(current_sound_key)
	
	for p_name in active_controls.keys():
		var control = active_controls[p_name]
		var norm = 0.5
		if control.has_method("get_normalized_value"):
			norm = control.get_normalized_value()
		
		# Map back to real range
		var p_min = 0.0
		var p_max = 1.0
		
		# Look for range in defaults
		var d_data = defaults.get(p_name, {})
		if d_data is Dictionary:
			p_min = d_data.get("min", 0.0)
			p_max = d_data.get("max", 1.0)
		else:
			# Fallback if not in defaults
			if "freq" in p_name: p_max = 2000.0
			elif "amp" in p_name: p_max = 1.0
			elif "dur" in p_name: p_max = 10.0
			
		values[p_name] = lerp(p_min, p_max, norm)
		
	return values

func _resolve_sound_type(key: String):
	# Basic lookup, in a real app this would be more robust
	var s_type = key.to_upper()
	if AudioSynthesizer.SoundType.has(s_type):
		return AudioSynthesizer.SoundType[s_type]
	return AudioSynthesizer.SoundType.BASIC_SINE_WAVE
