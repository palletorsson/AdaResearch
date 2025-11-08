# pick_up_cube.gd - Updated to work with GameManager singleton
extends Node3D

class_name PickupCube

@export var points_value: int = 1
@export var rotation_speed: float = 2.0
@export var bob_height: float = 0.2
@export var bob_speed: float = 2.0

# Mario-style sound parameters
@export var freq_start: float = 440.0  ## Start frequency (200-800 Hz)
@export var freq_end: float = 880.0    ## End frequency (400-1200 Hz)
@export var decay_rate: float = 8.0    ## Decay rate (2.0-12.0)
@export var sound_duration: float = 0.5  ## Sound duration in seconds

var original_y: float
var time_passed: float = 0.0
var has_been_collected: bool = false

# Reference to the pickup sound
var pickup_sound: AudioStreamPlayer3D

# Static variables for shared pickup stream management
static var shared_pickup_stream: AudioStream = null
static var default_pickup_stream: AudioStream = null

# Static variables for shared Mario sound parameters
static var shared_freq_start: float = 440.0
static var shared_freq_end: float = 880.0
static var shared_decay_rate: float = 8.0
static var shared_sound_duration: float = 0.5
static var use_shared_parameters: bool = false

func _ready() -> void:
	# Store original position for bobbing motion
	original_y = global_position.y
	
	# Create and configure the pickup sound
	setup_pickup_sound()
	
	print("PickupCube: Ready with %d point value" % points_value)

func _process(delta: float) -> void:
	if has_been_collected:
		return
	
	# Rotate the cube
	rotate_y(rotation_speed * delta)
	
	# Make the cube bob up and down
	time_passed += delta
	var bob_offset = sin(time_passed * bob_speed) * bob_height
	global_position.y = original_y + bob_offset

func _is_player(body: Node3D) -> bool:
	# More flexible player detection
	return body.is_in_group("player") or body.is_in_group("vr_player") or body.name.contains("Player") or body.is_in_group("player_body")

func setup_pickup_sound() -> void:
	# Create an AudioStreamPlayer3D node for the pickup sound
	pickup_sound = AudioStreamPlayer3D.new()
	add_child(pickup_sound)

	# Configure the audio properties
	pickup_sound.unit_size = 2.0
	pickup_sound.max_distance = 20.0
	pickup_sound.volume_db = -6.0  # Moderate volume

	# Generate Mario-style pickup sound
	pickup_sound.stream = _generate_mario_pickup_sound()

func _generate_mario_pickup_sound() -> AudioStreamWAV:
	"""Generate Mario-style pickup sound with frequency sweep and exponential decay"""
	const SAMPLE_RATE = 44100

	# Use shared parameters if available (from MarioSoundController)
	var start_freq = shared_freq_start if use_shared_parameters else freq_start
	var end_freq = shared_freq_end if use_shared_parameters else freq_end
	var decay = shared_decay_rate if use_shared_parameters else decay_rate
	var duration = shared_sound_duration if use_shared_parameters else sound_duration

	# Debug output
	var source = "SHARED" if use_shared_parameters else "LOCAL"
	print("PickupCube: Generating %s sound - start:%.1f Hz, end:%.1f Hz, decay:%.2f" % [source, start_freq, end_freq, decay])

	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count

		# Rising frequency from start to end (classic Mario pickup sweep)
		var freq = start_freq + ((end_freq - start_freq) * progress)

		# Exponential decay envelope
		var envelope = exp(-progress * decay)

		# Square wave for retro Mario feel
		var wave = 1.0 if sin(2.0 * PI * freq * t) > 0 else -1.0

		# Apply envelope and convert to 16-bit audio
		var sample_value = wave * envelope * 0.3
		var sample_int = int(sample_value * 32767.0)

		# Append as 16-bit PCM (little endian)
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)

	# Create AudioStreamWAV
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data

	return stream

func collect() -> void:
	if has_been_collected:
		return

	has_been_collected = true

	print("PickupCube: Collected! Adding %d points" % points_value)

	# Send signal to GameManager singleton with pickup position
	GameManager.add_points(points_value, global_position)

	# Regenerate sound with latest parameters (from MarioSoundController if available)
	var fresh_sound = _generate_mario_pickup_sound()

	# Play pickup sound before removing the cube
	var sound_clone = AudioStreamPlayer3D.new()
	get_tree().root.add_child(sound_clone)
	sound_clone.stream = fresh_sound
	sound_clone.global_position = global_position
	sound_clone.volume_db = pickup_sound.volume_db
	sound_clone.pitch_scale = 1.0
	sound_clone.play()

	# Free the cloned sound after it finishes playing
	sound_clone.finished.connect(func(): sound_clone.queue_free())

	# Visual feedback effect
	_play_collection_effect()

	# Remove the pickup from the scene after a brief delay
	await get_tree().create_timer(0.1).timeout
	queue_free()

func _play_collection_effect():
	"""Simple collection effect - scale up and fade"""
	var mesh_instance = find_child("CubeBaseMesh", true, false)
	if mesh_instance:
		var tween = create_tween()
		tween.parallel().tween_property(mesh_instance, "scale", mesh_instance.scale * 1.5, 0.2)
		tween.parallel().tween_property(mesh_instance, "modulate", Color.TRANSPARENT, 0.2)

func _on_detection_area_body_entered(body: Node3D) -> void:
	if _is_player(body):
		print("PickupCube: Player detected, collecting item")
		collect()

# Public API for testing
func set_points_value(new_value: int) -> void:
	points_value = new_value
	print("PickupCube: Points value set to %d" % points_value)

# Static functions for shared pickup stream management
static func get_shared_pickup_stream() -> AudioStream:
	return shared_pickup_stream

static func get_default_pickup_stream() -> AudioStream:
	if default_pickup_stream == null:
		_create_default_pickup_stream()
	return default_pickup_stream

static func set_shared_pickup_stream(stream: AudioStream) -> void:
	shared_pickup_stream = stream

static func reset_shared_pickup_stream() -> AudioStream:
	shared_pickup_stream = get_default_pickup_stream()
	return shared_pickup_stream

static func set_shared_mario_parameters(start_freq: float, end_freq: float, decay: float, duration: float) -> void:
	"""Called by MarioSoundController to update shared sound parameters"""
	shared_freq_start = start_freq
	shared_freq_end = end_freq
	shared_decay_rate = decay
	shared_sound_duration = duration
	use_shared_parameters = true
	print("PickupCube: Shared Mario sound updated - start:%.1f Hz, end:%.1f Hz, decay:%.2f" % [start_freq, end_freq, decay])

static func get_shared_mario_parameters() -> Dictionary:
	"""Get the current shared Mario sound parameters"""
	return {
		"freq_start": shared_freq_start,
		"freq_end": shared_freq_end,
		"decay_rate": shared_decay_rate,
		"duration": shared_sound_duration,
		"enabled": use_shared_parameters
	}

static func disable_shared_parameters() -> void:
	"""Disable shared parameters, use individual cube settings instead"""
	use_shared_parameters = false
	print("PickupCube: Shared parameters disabled, using individual cube settings")

static func _create_default_pickup_stream() -> void:
	# Create a simple default pickup sound
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	
	# Generate a simple Mario-style pickup sound
	var sample_rate = 44100
	var duration = 0.2
	var samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t = float(i) / sample_rate
		var freq1 = 880.0
		var freq2 = 1318.5
		var normalized = clamp(t / duration, 0.0, 1.0)
		var sweep_freq = lerp(freq1, freq2, pow(normalized, 0.7))
		var envelope = 1.0 - normalized  # Simple decay
		var sample = sin(TAU * sweep_freq * t) * envelope * 0.5
		var sample_int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_int)
	
	stream.data = data
	default_pickup_stream = stream
