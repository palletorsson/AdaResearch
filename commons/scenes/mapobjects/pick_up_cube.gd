extends Node3D

class_name PickupCube

@export var xp_value: int = 1
@export var rotation_speed: float = 2.0
@export var bob_height: float = 0.2
@export var bob_speed: float = 2.0

var original_y: float
var time_passed: float = 0.0

# Reference to the pickup sound
var pickup_sound: AudioStreamPlayer3D


func _ready() -> void:
	# Store original position for bobbing motion
	original_y = global_position.y
	
	# Create and configure the pickup sound
	setup_pickup_sound()


func _process(delta: float) -> void:
	# Rotate the cube
	rotate_y(rotation_speed * delta)
	
	# Make the cube bob up and down
	time_passed += delta
	var bob_offset = sin(time_passed * bob_speed) * bob_height
	global_position.y = original_y + bob_offset

func _is_player(body: Node3D) -> bool:
	# More flexible player detection
	return body.is_in_group("player") or body.is_in_group("vr_player") or body.name.contains("Player")


func setup_pickup_sound() -> void:
	# Create an AudioStreamPlayer3D node for the pickup sound
	pickup_sound = AudioStreamPlayer3D.new()
	add_child(pickup_sound)
	
	# Configure the audio properties
	pickup_sound.unit_size = 2.0  # Adjust to control how far the sound can be heard
	pickup_sound.max_distance = 20.0
	
	# Create a synthesized pickup sound (simple sine wave)
	var sample_rate = 44100
	var sample_hz = 880  # A5 note
	var sample_hz_2 = 1318.5  # E6 note
	
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	
	# Generate a simple two-tone pickup sound
	var data = PackedByteArray()
	var length = 0.2  # Sound duration in seconds
	var samples = length * sample_rate
	
	for i in range(samples):
		var t = float(i) / sample_rate
		var phase_1 = t * sample_hz
		var phase_2 = t * sample_hz_2
		
		# Amplitude envelope (fade out)
		var amplitude = 0.5 * (1.0 - t / length)
		
		# Mix two tones for a more interesting sound
		var sample_value = amplitude * (sin(TAU * phase_1) + sin(TAU * phase_2))
		
		# Convert to 16-bit PCM
		var sample_int = int(sample_value * 32767.0)
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)
	
	stream.data = data
	pickup_sound.stream = stream

func collect() -> void:
	# Add XP through the GameManager
	GameManager.update_xp(xp_value)
	
	# Play pickup sound before removing the cube
	# Clone the AudioStreamPlayer3D and make it a child of the scene root
	# so the sound continues playing after the cube is freed
	var sound_clone = AudioStreamPlayer3D.new()
	get_tree().root.add_child(sound_clone)
	sound_clone.stream = pickup_sound.stream
	sound_clone.global_position = global_position
	sound_clone.volume_db = pickup_sound.volume_db
	sound_clone.pitch_scale = 1.0
	sound_clone.play()
	
	# Free the cloned sound after it finishes playing
	sound_clone.finished.connect(func(): sound_clone.queue_free())
	
	# Visual feedback (optional)
	# You could add a particle effect here
	
	# Remove the pickup from the scene
	queue_free()


func _on_detection_area_body_entered(body: Node3D) -> void:
	if _is_player(body):
		print("Player detected, collecting item")
		collect()
