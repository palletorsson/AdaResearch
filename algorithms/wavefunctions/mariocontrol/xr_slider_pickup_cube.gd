# xr_slider_pickup_cube.gd - Enhanced with XR Tools slider-controlled sound
extends Node3D

class_name XRSliderPickupCube

@export var points_value: int = 1
@export var rotation_speed: float = 2.0
@export var bob_height: float = 0.2
@export var bob_speed: float = 2.0

# XR Slider sound control references
@export var pitch_slider: XRToolsInteractableSlider
@export var volume_slider: XRToolsInteractableSlider
@export var tone_slider: XRToolsInteractableSlider
@export var harmony_slider: XRToolsInteractableSlider
@export var reverb_slider: XRToolsInteractableSlider

var original_y: float
var time_passed: float = 0.0
var has_been_collected: bool = false

# Enhanced pickup sound system
var pickup_sound: AudioStreamPlayer3D
var sound_generator: XRSliderSoundGenerator

# Current sound parameters controlled by sliders
var current_pitch: float = 1.0
var current_volume: float = 0.5
var current_tone_blend: float = 0.5
var current_harmony: float = 0.3
var current_reverb: float = 0.2

func _ready() -> void:
	original_y = global_position.y
	setup_xr_slider_sound_system()
	connect_slider_signals()
	print("XRSliderPickupCube: Ready with XR slider-controlled sound")

func _process(delta: float) -> void:
	if has_been_collected:
		return
	
	# Rotate and bob the cube
	rotate_y(rotation_speed * delta)
	time_passed += delta
	var bob_offset = sin(time_passed * bob_speed) * bob_height
	global_position.y = original_y + bob_offset
	
	# Update sound parameters from sliders in real-time
	update_sound_parameters()

func setup_xr_slider_sound_system() -> void:
	# Create sound generator
	sound_generator = XRSliderSoundGenerator.new()
	add_child(sound_generator)
	
	# Create 3D audio player
	pickup_sound = AudioStreamPlayer3D.new()
	add_child(pickup_sound)
	pickup_sound.unit_size = 2.0
	pickup_sound.max_distance = 20.0

func connect_slider_signals() -> void:
	# Connect to slider movement signals if sliders exist
	if pitch_slider:
		pitch_slider.slider_moved.connect(_on_pitch_changed)
	if volume_slider:
		volume_slider.slider_moved.connect(_on_volume_changed)
	if tone_slider:
		tone_slider.slider_moved.connect(_on_tone_changed)
	if harmony_slider:
		harmony_slider.slider_moved.connect(_on_harmony_changed)
	if reverb_slider:
		reverb_slider.slider_moved.connect(_on_reverb_changed)

func update_sound_parameters() -> void:
	# Read current slider values if available
	if pitch_slider:
		current_pitch = lerp(0.5, 2.0, pitch_slider.slider_position)
	if volume_slider:
		current_volume = volume_slider.slider_position
	if tone_slider:
		current_tone_blend = tone_slider.slider_position
	if harmony_slider:
		current_harmony = harmony_slider.slider_position
	if reverb_slider:
		current_reverb = reverb_slider.slider_position

func _on_pitch_changed(position: float) -> void:
	current_pitch = lerp(0.5, 2.0, position)
	print("Pitch changed to: ", current_pitch)

func _on_volume_changed(position: float) -> void:
	current_volume = position
	print("Volume changed to: ", current_volume)

func _on_tone_changed(position: float) -> void:
	current_tone_blend = position
	print("Tone blend changed to: ", current_tone_blend)

func _on_harmony_changed(position: float) -> void:
	current_harmony = position
	print("Harmony changed to: ", current_harmony)

func _on_reverb_changed(position: float) -> void:
	current_reverb = position
	print("Reverb changed to: ", current_reverb)

func _is_player(body: Node3D) -> bool:
	return body.is_in_group("player") or body.is_in_group("vr_player") or body.name.contains("Player") or body.is_in_group("player_body")

func collect() -> void:
	if has_been_collected:
		return
	
	has_been_collected = true
	print("XRSliderPickupCube: Collected! Generating dynamic sound")
	
	# Generate dynamic pickup sound based on current slider values
	var dynamic_sound = sound_generator.generate_pickup_sound(
		current_pitch,
		current_volume,
		current_tone_blend,
		current_harmony,
		current_reverb
	)
	
	# Play the dynamically generated sound
	var sound_clone = AudioStreamPlayer3D.new()
	get_tree().root.add_child(sound_clone)
	sound_clone.stream = dynamic_sound
	sound_clone.global_position = global_position
	sound_clone.volume_db = lerp(-20, 0, current_volume)
	sound_clone.pitch_scale = current_pitch
	sound_clone.play()
	
	# Add reverb effect if slider indicates it
	if current_reverb > 0.1:
		add_reverb_effect(sound_clone)
	
	sound_clone.finished.connect(func(): sound_clone.queue_free())
	
	# Send to GameManager
	GameManager.add_points(points_value, global_position)
	
	# Visual effect
	_play_collection_effect()
	
	await get_tree().create_timer(0.1).timeout
	queue_free()

func add_reverb_effect(audio_player: AudioStreamPlayer3D) -> void:
	# Create a bus with reverb for this specific sound
	var bus_name = "TempReverb_" + str(randi())
	var bus_idx = AudioServer.get_bus_count()
	AudioServer.add_bus(bus_idx)
	AudioServer.set_bus_name(bus_idx, bus_name)
	AudioServer.set_bus_send(bus_idx, "Master")
	
	# Add reverb effect
	var reverb = AudioEffectReverb.new()
	reverb.room_size = lerp(0.1, 0.9, current_reverb)
	reverb.damping = 0.3
	reverb.wet = lerp(0.1, 0.6, current_reverb)
	AudioServer.add_bus_effect(bus_idx, reverb)
	
	# Assign the bus to our audio player
	audio_player.bus = bus_name
	
	# Clean up the bus after the sound finishes
	audio_player.finished.connect(func(): 
		AudioServer.remove_bus(bus_idx)
	)

func _play_collection_effect():
	var mesh_instance = find_child("CubeBaseMesh", true, false)
	if mesh_instance:
		var tween = create_tween()
		tween.parallel().tween_property(mesh_instance, "scale", mesh_instance.scale * 1.5, 0.2)
		tween.parallel().tween_property(mesh_instance, "modulate", Color.TRANSPARENT, 0.2)

func _on_detection_area_body_entered(body: Node3D) -> void:
	if _is_player(body):
		print("XRSliderPickupCube: Player detected, collecting with current slider settings")
		collect()

# Public API
func set_points_value(new_value: int) -> void:
	points_value = new_value
	print("XRSliderPickupCube: Points value set to %d" % points_value)

# XR Slider Sound Generator Class
class XRSliderSoundGenerator:
	extends Node
	
	var sample_rate = 44100
	
	func generate_pickup_sound(pitch: float, volume: float, tone_blend: float, harmony: float, reverb: float) -> AudioStreamWAV:
		var stream = AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = sample_rate
		stream.stereo = false
		
		var duration = 0.4  # Sound length in seconds
		var samples = int(duration * sample_rate)
		var data = PackedByteArray()
		data.resize(samples * 2)  # 16-bit mono
		
		# Base frequencies influenced by sliders
		var base_freq = lerp(400, 1200, tone_blend) * pitch
		var harmony_freq = base_freq * lerp(1.0, 1.5, harmony)
		var sub_freq = base_freq * 0.5
		
		for i in range(samples):
			var t = float(i) / sample_rate
			var sample_value = 0.0
			
			# Envelope (attack, sustain, decay)
			var envelope = 1.0
			if t < 0.05:  # Attack
				envelope = t / 0.05
			elif t > duration - 0.15:  # Decay
				envelope = (duration - t) / 0.15
			
			# Main tone with slider-controlled characteristics
			var main_tone = sin(TAU * base_freq * t)
			
			# Harmony component
			var harmony_tone = sin(TAU * harmony_freq * t) * harmony
			
			# Sub-bass component for fullness
			var sub_tone = sin(TAU * sub_freq * t) * 0.3
			
			# Blend tones based on tone slider
			var bright_component = sin(TAU * base_freq * 2.0 * t) * tone_blend
			var warm_component = sin(TAU * base_freq * 0.5 * t) * (1.0 - tone_blend)
			
			# Combine all components
			sample_value = (main_tone + harmony_tone + sub_tone + bright_component * 0.5 + warm_component * 0.3) * envelope
			
			# Add some texture with controlled noise
			var noise = (randf() - 0.5) * 0.1 * tone_blend
			sample_value += noise
			
			# Apply volume
			sample_value *= volume * 0.6  # Overall level control
			
			# Clamp and convert to 16-bit
			sample_value = clamp(sample_value, -1.0, 1.0)
			var sample_int = int(sample_value * 32767.0)
			
			# Store in byte array
			data.encode_s16(i * 2, sample_int)
		
		stream.data = data
		return stream

# Scene setup helper function (call this from the scene's _ready)
func setup_xr_slider_scene() -> void:
	# This function helps set up a complete XR slider control scene
	print("Setting up XR slider control scene for pickup cube")
	
	# You would create sliders here if they don't exist
	# This is just a helper for scene organization
	if not pitch_slider:
		print("Warning: No pitch slider assigned")
	if not volume_slider:
		print("Warning: No volume slider assigned")
	if not tone_slider:
		print("Warning: No tone slider assigned")
	if not harmony_slider:
		print("Warning: No harmony slider assigned")
	if not reverb_slider:
		print("Warning: No reverb slider assigned")