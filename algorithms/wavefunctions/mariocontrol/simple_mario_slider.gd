# simple_mario_slider.gd
extends Control

class_name SimpleMarioSlider

# UI Elements
@onready var freq1_slider = $VBox/Freq1Container/Freq1Slider
@onready var freq1_label = $VBox/Freq1Container/Freq1Label
@onready var freq2_slider = $VBox/Freq2Container/Freq2Slider
@onready var freq2_label = $VBox/Freq2Container/Freq2Label
@onready var volume_slider = $VBox/VolumeContainer/VolumeSlider
@onready var volume_label = $VBox/VolumeContainer/VolumeLabel
@onready var length_slider = $VBox/LengthContainer/LengthSlider
@onready var length_label = $VBox/LengthContainer/LengthLabel
@onready var test_button = $VBox/TestButton
@onready var waveform_display = $VBox/WaveformDisplay

# Sound parameters
var freq1: float = 880.0  # A5 note
var freq2: float = 1318.5  # E6 note  
var volume: float = 0.5
var sound_length: float = 0.2

# Audio player for testing
var audio_player: AudioStreamPlayer

# Waveform visualization data
var waveform_points: PackedFloat32Array
var sample_rate: int = 44100
var display_samples: int = 1024

func _ready():
	setup_sliders()
	connect_signals()
	create_audio_player()
	setup_waveform_display()
	update_all_labels()
	update_waveform()

func setup_sliders():
	# Frequency 1 slider (200Hz to 2000Hz)
	if freq1_slider:
		freq1_slider.min_value = 200.0
		freq1_slider.max_value = 2000.0
		freq1_slider.value = freq1
		freq1_slider.step = 10.0
	
	# Frequency 2 slider (400Hz to 3000Hz)
	if freq2_slider:
		freq2_slider.min_value = 400.0
		freq2_slider.max_value = 3000.0
		freq2_slider.value = freq2
		freq2_slider.step = 10.0
	
	# Volume slider (0 to 1)
	if volume_slider:
		volume_slider.min_value = 0.0
		volume_slider.max_value = 1.0
		volume_slider.value = volume
		volume_slider.step = 0.01
	
	# Length slider (0.1 to 0.5 seconds)
	if length_slider:
		length_slider.min_value = 0.1
		length_slider.max_value = 0.5
		length_slider.value = sound_length
		length_slider.step = 0.01

func setup_waveform_display():
	waveform_points.resize(display_samples)
	if waveform_display:
		waveform_display.custom_minimum_size = Vector2(400, 150)
		waveform_display.draw.connect(_on_waveform_draw)

func connect_signals():
	if freq1_slider:
		freq1_slider.value_changed.connect(_on_freq1_changed)
	if freq2_slider:
		freq2_slider.value_changed.connect(_on_freq2_changed)
	if volume_slider:
		volume_slider.value_changed.connect(_on_volume_changed)
	if length_slider:
		length_slider.value_changed.connect(_on_length_changed)
	if test_button:
		test_button.pressed.connect(_on_test_pressed)

func create_audio_player():
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

func _on_freq1_changed(value: float):
	freq1 = value
	freq1_label.text = "Frequency 1: %.0f Hz" % value
	update_waveform()

func _on_freq2_changed(value: float):
	freq2 = value
	freq2_label.text = "Frequency 2: %.0f Hz" % value
	update_waveform()

func _on_volume_changed(value: float):
	volume = value
	volume_label.text = "Volume: %.2f" % value
	update_waveform()

func _on_length_changed(value: float):
	sound_length = value
	length_label.text = "Length: %.2fs" % value
	update_waveform()

func _on_test_pressed():
	var sound = create_mario_sound()
	audio_player.stream = sound
	audio_player.volume_db = lerp(-20, 0, volume)
	audio_player.play()

func update_waveform():
	# Generate waveform data for visualization
	waveform_points.clear()
	waveform_points.resize(display_samples)
	
	# Calculate how much of the sound length to display (max 0.1 seconds for clarity)
	var display_time = min(sound_length, 0.1)
	
	for i in range(display_samples):
		var t = float(i) / display_samples * display_time
		
		# Generate the same waveform as the mario sound
		var phase_1 = t * freq1
		var phase_2 = t * freq2
		
		# Amplitude envelope (fade out over the display time)
		var amplitude = volume * (1.0 - t / sound_length) if t < sound_length else 0.0
		
		# Mix two tones (same as mario sound generation)
		var sample_value = amplitude * (sin(TAU * phase_1) + sin(TAU * phase_2))
		
		waveform_points[i] = sample_value
	
	# Trigger redraw
	if waveform_display:
		waveform_display.queue_redraw()

func _on_waveform_draw():
	if not waveform_display or waveform_points.is_empty():
		return
	
	var rect = waveform_display.get_rect()
	
	# Draw background
	waveform_display.draw_rect(rect, Color(0.1, 0.1, 0.1, 1.0))
	
	# Draw center line
	var center_y = rect.size.y * 0.5
	waveform_display.draw_line(
		Vector2(0, center_y), 
		Vector2(rect.size.x, center_y), 
		Color(0.3, 0.3, 0.3), 
		1.0
	)
	
	# Draw waveform
	var points = PackedVector2Array()
	for i in range(waveform_points.size()):
		var x = (float(i) / waveform_points.size()) * rect.size.x
		var y = center_y - (waveform_points[i] * rect.size.y * 0.4)
		points.append(Vector2(x, y))
	
	if points.size() > 1:
		# Draw the waveform line with a gradient effect
		for i in range(points.size() - 1):
			var color_intensity = abs(waveform_points[i]) + 0.3
			var color = Color(0.2 + color_intensity * 0.8, 0.8, 0.2 + color_intensity * 0.8)
			waveform_display.draw_line(points[i], points[i + 1], color, 2.0)
	
	# Draw frequency labels
	var font = ThemeDB.fallback_font
	var font_size = 12
	waveform_display.draw_string(font, Vector2(10, 20), "Freq1: %.0fHz" % freq1, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	waveform_display.draw_string(font, Vector2(10, 35), "Freq2: %.0fHz" % freq2, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	waveform_display.draw_string(font, Vector2(10, rect.size.y - 10), "Volume: %.2f" % volume, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

func update_all_labels():
	if freq1_slider:
		_on_freq1_changed(freq1_slider.value)
	if freq2_slider:
		_on_freq2_changed(freq2_slider.value)
	if volume_slider:
		_on_volume_changed(volume_slider.value)
	if length_slider:
		_on_length_changed(length_slider.value)

func create_mario_sound() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	
	# Generate the two-tone pickup sound using current slider values
	var data = PackedByteArray()
	var samples = sound_length * sample_rate
	
	for i in range(samples):
		var t = float(i) / sample_rate
		var phase_1 = t * freq1
		var phase_2 = t * freq2
		
		# Amplitude envelope (fade out)
		var amplitude = volume * (1.0 - t / sound_length)
		
		# Mix two tones
		var sample_value = amplitude * (sin(TAU * phase_1) + sin(TAU * phase_2))
		
		# Convert to 16-bit PCM
		var sample_int = int(sample_value * 32767.0)
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)
	
	stream.data = data
	return stream

# Public API for pickup cubes
func get_mario_sound() -> AudioStreamWAV:
	return create_mario_sound()

func get_sound_settings() -> Dictionary:
	return {
		"freq1": freq1,
		"freq2": freq2,
		"volume": volume,
		"length": sound_length
	}

# Enhanced pickup cube that uses these simple sliders
class SimpleMarioPickupCube:
	extends Node3D
	
	@export var points_value: int = 1
	@export var rotation_speed: float = 2.0
	@export var bob_height: float = 0.2
	@export var bob_speed: float = 2.0
	
	var original_y: float
	var time_passed: float = 0.0
	var has_been_collected: bool = false
	var pickup_sound: AudioStreamPlayer3D
	
	# Reference to the simple slider control
	var mario_slider: SimpleMarioSlider
	
	func _ready() -> void:
		original_y = global_position.y
		setup_pickup_sound()
		find_mario_slider()
		print("SimpleMarioPickupCube ready")
	
	func _process(delta: float) -> void:
		if has_been_collected:
			return
		
		rotate_y(rotation_speed * delta)
		time_passed += delta
		var bob_offset = sin(time_passed * bob_speed) * bob_height
		global_position.y = original_y + bob_offset
	
	func setup_pickup_sound() -> void:
		pickup_sound = AudioStreamPlayer3D.new()
		add_child(pickup_sound)
		pickup_sound.unit_size = 2.0
		pickup_sound.max_distance = 20.0
	
	func find_mario_slider() -> void:
		mario_slider = get_tree().get_first_node_in_group("mario_slider_control")
		if not mario_slider:
			print("Warning: No SimpleMarioSlider found in scene")
	
	func collect() -> void:
		if has_been_collected:
			return
		
		has_been_collected = true
		
		# Get dynamic sound from slider settings
		var dynamic_sound = null
		if mario_slider:
			dynamic_sound = mario_slider.get_mario_sound()
			var settings = mario_slider.get_sound_settings()
			pickup_sound.volume_db = lerp(-20, 0, settings.volume)
		else:
			# Fallback to default mario sound
			dynamic_sound = create_default_mario_sound()
		
		# Play sound
		var sound_clone = AudioStreamPlayer3D.new()
		get_tree().root.add_child(sound_clone)
		sound_clone.stream = dynamic_sound
		sound_clone.global_position = global_position
		sound_clone.volume_db = pickup_sound.volume_db
		sound_clone.play()
		
		sound_clone.finished.connect(func(): sound_clone.queue_free())
		
		# Game logic
		GameManager.add_points(points_value, global_position)
		_play_collection_effect()
		
		await get_tree().create_timer(0.1).timeout
		queue_free()
	
	func create_default_mario_sound() -> AudioStreamWAV:
		# Default mario sound (same as original)
		var sample_rate = 44100
		var sample_hz = 880  # A5 note
		var sample_hz_2 = 1318.5  # E6 note
		
		var stream = AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = sample_rate
		
		var data = PackedByteArray()
		var length = 0.2
		var samples = length * sample_rate
		
		for i in range(samples):
			var t = float(i) / sample_rate
			var phase_1 = t * sample_hz
			var phase_2 = t * sample_hz_2
			var amplitude = 0.5 * (1.0 - t / length)
			var sample_value = amplitude * (sin(TAU * phase_1) + sin(TAU * phase_2))
			var sample_int = int(sample_value * 32767.0)
			data.append(sample_int & 0xFF)
			data.append((sample_int >> 8) & 0xFF)
		
		stream.data = data
		return stream
	
	func _play_collection_effect():
		var mesh_instance = find_child("CubeBaseMesh", true, false)
		if mesh_instance:
			var tween = create_tween()
			tween.parallel().tween_property(mesh_instance, "scale", mesh_instance.scale * 1.5, 0.2)
			tween.parallel().tween_property(mesh_instance, "modulate", Color.TRANSPARENT, 0.2)
	
	func _on_detection_area_body_entered(body: Node3D) -> void:
		if _is_player(body):
			collect()
	
	func _is_player(body: Node3D) -> bool:
		return body.is_in_group("player") or body.is_in_group("vr_player") or body.name.contains("Player")
