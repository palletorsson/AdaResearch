# xr_slider_control_panel.gd - Scene setup for XR slider-controlled pickup sounds
extends Node3D

class_name XRSliderControlPanel

# References to the slider controls
@onready var pitch_slider = $SliderPanel/PitchSlider
@onready var volume_slider = $SliderPanel/VolumeSlider  
@onready var tone_slider = $SliderPanel/ToneSlider
@onready var harmony_slider = $SliderPanel/HarmonySlider
@onready var reverb_slider = $SliderPanel/ReverbSlider

# Reference to pickup cubes in the scene
var pickup_cubes: Array[XRSliderPickupCube] = []

# UI Labels for real-time feedback
@onready var pitch_label = $SliderPanel/Labels/PitchLabel
@onready var volume_label = $SliderPanel/Labels/VolumeLabel
@onready var tone_label = $SliderPanel/Labels/ToneLabel
@onready var harmony_label = $SliderPanel/Labels/HarmonyLabel
@onready var reverb_label = $SliderPanel/Labels/ReverbLabel

func _ready() -> void:
	setup_slider_ranges()
	connect_slider_signals()
	find_pickup_cubes()
	update_all_labels()
	print("XR Slider Control Panel ready")

func setup_slider_ranges() -> void:
	# Configure slider limits and default positions
	
	# Pitch slider: 0.5x to 2.0x pitch
	pitch_slider.slider_limit_min = 0.0
	pitch_slider.slider_limit_max = 1.0
	pitch_slider.slider_position = 0.5  # Default to 1.0x pitch
	pitch_slider.default_position = 0.5
	pitch_slider.default_on_release = false
	
	# Volume slider: 0% to 100%
	volume_slider.slider_limit_min = 0.0
	volume_slider.slider_limit_max = 1.0
	volume_slider.slider_position = 0.7  # Default to 70% volume
	volume_slider.default_position = 0.7
	
	# Tone slider: Dark to Bright
	tone_slider.slider_limit_min = 0.0
	tone_slider.slider_limit_max = 1.0
	tone_slider.slider_position = 0.5  # Balanced tone
	tone_slider.default_position = 0.5
	
	# Harmony slider: No harmony to full harmony
	harmony_slider.slider_limit_min = 0.0
	harmony_slider.slider_limit_max = 1.0
	harmony_slider.slider_position = 0.3  # Light harmony
	harmony_slider.default_position = 0.3
	
	# Reverb slider: Dry to Wet
	reverb_slider.slider_limit_min = 0.0
	reverb_slider.slider_limit_max = 1.0
	reverb_slider.slider_position = 0.2  # Light reverb
	reverb_slider.default_position = 0.2

func connect_slider_signals() -> void:
	# Connect all slider movement signals
	pitch_slider.slider_moved.connect(_on_pitch_slider_moved)
	volume_slider.slider_moved.connect(_on_volume_slider_moved)
	tone_slider.slider_moved.connect(_on_tone_slider_moved)
	harmony_slider.slider_moved.connect(_on_harmony_slider_moved)
	reverb_slider.slider_moved.connect(_on_reverb_slider_moved)

func find_pickup_cubes() -> void:
	# Find all XRSliderPickupCube instances in the scene
	pickup_cubes.clear()
	_find_pickup_cubes_recursive(get_tree().root)
	
	# Assign slider references to all pickup cubes
	for cube in pickup_cubes:
		cube.pitch_slider = pitch_slider
		cube.volume_slider = volume_slider
		cube.tone_slider = tone_slider
		cube.harmony_slider = harmony_slider
		cube.reverb_slider = reverb_slider
	
	print("Found and configured %d pickup cubes" % pickup_cubes.size())

func _find_pickup_cubes_recursive(node: Node) -> void:
	if node is XRSliderPickupCube:
		pickup_cubes.append(node as XRSliderPickupCube)
	
	for child in node.get_children():
		_find_pickup_cubes_recursive(child)

# Slider signal handlers
func _on_pitch_slider_moved(position: float) -> void:
	var pitch_value = lerp(0.5, 2.0, position)
	pitch_label.text = "Pitch: %.2fx" % pitch_value
	print("Pitch adjusted to: %.2fx" % pitch_value)

func _on_volume_slider_moved(position: float) -> void:
	var volume_percent = position * 100
	volume_label.text = "Volume: %d%%" % volume_percent
	print("Volume adjusted to: %d%%" % volume_percent)

func _on_tone_slider_moved(position: float) -> void:
	var tone_description = ""
	if position < 0.3:
		tone_description = "Dark"
	elif position < 0.7:
		tone_description = "Balanced"
	else:
		tone_description = "Bright"
	
	tone_label.text = "Tone: %s" % tone_description
	print("Tone adjusted to: %s (%.2f)" % [tone_description, position])

func _on_harmony_slider_moved(position: float) -> void:
	var harmony_percent = position * 100
	harmony_label.text = "Harmony: %d%%" % harmony_percent
	print("Harmony adjusted to: %d%%" % harmony_percent)

func _on_reverb_slider_moved(position: float) -> void:
	var reverb_description = ""
	if position < 0.2:
		reverb_description = "Dry"
	elif position < 0.5:
		reverb_description = "Room"
	elif position < 0.8:
		reverb_description = "Hall"
	else:
		reverb_description = "Cathedral"
	
	reverb_label.text = "Reverb: %s" % reverb_description
	print("Reverb adjusted to: %s (%.2f)" % [reverb_description, position])

func update_all_labels() -> void:
	# Update all labels with current slider values
	_on_pitch_slider_moved(pitch_slider.slider_position)
	_on_volume_slider_moved(volume_slider.slider_position)
	_on_tone_slider_moved(tone_slider.slider_position)
	_on_harmony_slider_moved(harmony_slider.slider_position)
	_on_reverb_slider_moved(reverb_slider.slider_position)

# Preset functions for quick sound adjustments
func set_mario_classic_preset() -> void:
	pitch_slider.move_slider(0.6)  # Slightly higher pitch
	volume_slider.move_slider(0.8)  # Loud
	tone_slider.move_slider(0.7)   # Bright
	harmony_slider.move_slider(0.4) # Some harmony
	reverb_slider.move_slider(0.1)  # Minimal reverb
	print("Applied Mario Classic preset")

func set_ethereal_preset() -> void:
	pitch_slider.move_slider(0.3)  # Lower pitch
	volume_slider.move_slider(0.6)  # Moderate volume
	tone_slider.move_slider(0.2)   # Dark tone
	harmony_slider.move_slider(0.8) # Rich harmony
	reverb_slider.move_slider(0.9)  # Heavy reverb
	print("Applied Ethereal preset")

func set_retro_8bit_preset() -> void:
	pitch_slider.move_slider(0.8)  # High pitch
	volume_slider.move_slider(0.9)  # Very loud
	tone_slider.move_slider(0.9)   # Very bright
	harmony_slider.move_slider(0.1) # Minimal harmony
	reverb_slider.move_slider(0.0)  # No reverb
	print("Applied Retro 8-bit preset")

func set_ambient_preset() -> void:
	pitch_slider.move_slider(0.2)  # Very low pitch
	volume_slider.move_slider(0.4)  # Quiet
	tone_slider.move_slider(0.1)   # Very dark
	harmony_slider.move_slider(0.6) # Moderate harmony
	reverb_slider.move_slider(0.7)  # Significant reverb
	print("Applied Ambient preset")

# Reset all sliders to default
func reset_to_defaults() -> void:
	pitch_slider.move_slider(pitch_slider.default_position)
	volume_slider.move_slider(volume_slider.default_position)
	tone_slider.move_slider(tone_slider.default_position)
	harmony_slider.move_slider(harmony_slider.default_position)
	reverb_slider.move_slider(reverb_slider.default_position)
	print("Reset all sliders to default positions")

# Test sound generation (for previewing without collecting a cube)
func test_current_sound() -> void:
	print("Testing current sound settings...")
	
	# Create a temporary sound generator
	var temp_generator = XRSliderPickupCube.XRSliderSoundGenerator.new()
	add_child(temp_generator)
	
	# Generate sound with current slider values
	var pitch_value = lerp(0.5, 2.0, pitch_slider.slider_position)
	var test_sound = temp_generator.generate_pickup_sound(
		pitch_value,
		volume_slider.slider_position,
		tone_slider.slider_position,
		harmony_slider.slider_position,
		reverb_slider.slider_position
	)
	
	# Play the test sound
	var test_player = AudioStreamPlayer3D.new()
	add_child(test_player)
	test_player.stream = test_sound
	test_player.global_position = global_position
	test_player.volume_db = lerp(-20, 0, volume_slider.slider_position)
	test_player.pitch_scale = pitch_value
	test_player.play()
	
	# Clean up after playing
	test_player.finished.connect(func(): 
		test_player.queue_free()
		temp_generator.queue_free()
	)

# Public API for external scene control
func get_current_settings() -> Dictionary:
	return {
		"pitch": lerp(0.5, 2.0, pitch_slider.slider_position),
		"volume": volume_slider.slider_position,
		"tone": tone_slider.slider_position,
		"harmony": harmony_slider.slider_position,
		"reverb": reverb_slider.slider_position
	}

func apply_settings(settings: Dictionary) -> void:
	if settings.has("pitch"):
		var pitch_slider_pos = inverse_lerp(0.5, 2.0, settings.pitch)
		pitch_slider.move_slider(pitch_slider_pos)
	if settings.has("volume"):
		volume_slider.move_slider(settings.volume)
	if settings.has("tone"):
		tone_slider.move_slider(settings.tone)
	if settings.has("harmony"):
		harmony_slider.move_slider(settings.harmony)
	if settings.has("reverb"):
		reverb_slider.move_slider(settings.reverb)
	
	print("Applied custom settings: ", settings)# xr_slider_control_panel.gd - Scene setup for XR slider-controlled pickup sounds
