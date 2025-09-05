# next_cube.gd - A cube that sends a "next" signal and respawns after 3 seconds
extends Node3D

class_name NextCube

@export var rotation_speed: float = 1.5
@export var bob_height: float = 0.15
@export var bob_speed: float = 1.8
@export var respawn_time: float = 3.0

var original_y: float
var time_passed: float = 0.0
var has_been_activated: bool = false

# Signal emitted when the cube is activated
signal next_requested(from_position: Vector3)

# Reference to the activation sound
var activation_sound: AudioStreamPlayer3D

func _ready() -> void:
	# Store original position for bobbing motion
	original_y = global_position.y
	
	# Create and configure the activation sound
	setup_activation_sound()
	
	# Connect to global signal manager if it exists
	if GameManager:
		next_requested.connect(_on_next_requested)
	
	print("NextCube: Ready at position %s" % global_position)

func _process(delta: float) -> void:
	if has_been_activated:
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

func setup_activation_sound() -> void:
	# Create an AudioStreamPlayer3D node for the activation sound
	activation_sound = AudioStreamPlayer3D.new()
	add_child(activation_sound)
	
	# Configure the audio properties
	activation_sound.unit_size = 2.0
	activation_sound.max_distance = 20.0
	activation_sound.volume_db = -3.0  # Slightly louder than pickup
	
	# Create a synthesized "next" sound (rising tone sequence)
	var sample_rate = 44100
	var sample_hz_1 = 523.3  # C5 note
	var sample_hz_2 = 659.3  # E5 note  
	var sample_hz_3 = 783.9  # G5 note
	
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	
	# Generate a rising three-tone "next" sound
	var data = PackedByteArray()
	var length = 0.4  # Sound duration in seconds
	var samples = length * sample_rate
	
	for i in range(samples):
		var t = float(i) / sample_rate
		var progress = t / length
		
		# Create three tone sequence that rises
		var tone1_amp = 1.0 - smoothstep(0.0, 0.3, progress)
		var tone2_amp = smoothstep(0.2, 0.5, progress) - smoothstep(0.4, 0.7, progress)
		var tone3_amp = smoothstep(0.6, 1.0, progress)
		
		# Overall amplitude envelope (slight fade out)
		var amplitude = 0.4 * (1.0 - progress * 0.3)
		
		# Mix three rising tones
		var sample_value = amplitude * (
			tone1_amp * sin(TAU * t * sample_hz_1) +
			tone2_amp * sin(TAU * t * sample_hz_2) +
			tone3_amp * sin(TAU * t * sample_hz_3)
		)
		
		# Convert to 16-bit PCM
		var sample_int = int(sample_value * 32767.0)
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)
	
	stream.data = data
	activation_sound.stream = stream

func activate() -> void:
	if has_been_activated:
		return
	
	has_been_activated = true
	
	print("NextCube: Activated! Requesting next example from position %s" % global_position)
	
	# Emit the next signal
	next_requested.emit(global_position)
	
	# Play activation sound before hiding the cube
	var sound_clone = AudioStreamPlayer3D.new()
	get_tree().root.add_child(sound_clone)
	sound_clone.stream = activation_sound.stream
	sound_clone.global_position = global_position
	sound_clone.volume_db = activation_sound.volume_db
	sound_clone.pitch_scale = 1.2  # Slightly higher pitch for "next"
	sound_clone.play()
	
	# Free the cloned sound after it finishes playing
	sound_clone.finished.connect(func(): sound_clone.queue_free())
	
	# Visual feedback effect
	_play_activation_effect()
	
	# Hide the cube temporarily
	await get_tree().create_timer(0.2).timeout
	visible = false
	
	# Respawn after the respawn time
	await get_tree().create_timer(respawn_time).timeout
	_respawn()

func _play_activation_effect():
	"""Activation effect - scale up with blue glow and fade"""
	var mesh_instance = find_child("CubeBaseMesh", true, false)
	if mesh_instance:
		var tween = create_tween()
		
		# Scale up effect
		tween.parallel().tween_property(mesh_instance, "scale", mesh_instance.scale * 1.8, 0.3)
		
		# Blue glow effect by modifying shader parameters
		var material = mesh_instance.material_override
		if material and material is ShaderMaterial:
			var shader_material = material as ShaderMaterial
			var original_emission = shader_material.get_shader_parameter("emissionColor")
			var glow_color = Color.CYAN * 2.0  # Bright cyan glow
			
			# Glow effect
			tween.parallel().tween_method(
				func(color): shader_material.set_shader_parameter("emissionColor", color),
				original_emission,
				glow_color,
				0.15
			)
			tween.parallel().tween_method(
				func(color): shader_material.set_shader_parameter("emissionColor", color),
				glow_color,
				original_emission,
				0.15
			).set_delay(0.15)

func _respawn():
	"""Respawn the cube at the original position"""
	has_been_activated = false
	visible = true
	global_position.y = original_y
	
	# Reset scale and apply spawn effect
	var mesh_instance = find_child("CubeBaseMesh", true, false)
	if mesh_instance:
		mesh_instance.scale = Vector3(0.5, 0.5, 0.5)  # Original scale from scene
		
		# Spawn effect - fade in using shader opacity
		var tween = create_tween()
		var material = mesh_instance.material_override
		if material and material is ShaderMaterial:
			var shader_material = material as ShaderMaterial
			# Fade in by adjusting model opacity
			var original_opacity = shader_material.get_shader_parameter("modelOpacity")
			if original_opacity == null:
				original_opacity = 0.9
			
			shader_material.set_shader_parameter("modelOpacity", 0.0)
			tween.tween_method(
				func(opacity): shader_material.set_shader_parameter("modelOpacity", opacity),
				0.0,
				original_opacity,
				0.5
			)
		else:
			# Fallback: scale effect if no shader material
			mesh_instance.scale = Vector3.ZERO
			tween.tween_property(mesh_instance, "scale", Vector3(0.5, 0.5, 0.5), 0.5)
	
	print("NextCube: Respawned at position %s" % global_position)

func _on_detection_area_body_entered(body: Node3D) -> void:
	if _is_player(body):
		print("NextCube: Player detected, activating next cube")
		activate()

func _on_next_requested(from_position: Vector3) -> void:
	"""Handle the next signal - can be connected to scene managers"""
	print("NextCube: Next signal received from position %s" % from_position)
	# This can be connected to external listeners that need to handle "next" functionality

# Public API for external control
func force_activate() -> void:
	"""Force activation from external scripts"""
	activate()

func set_respawn_time(new_time: float) -> void:
	"""Set custom respawn time"""
	respawn_time = new_time
	print("NextCube: Respawn time set to %.1f seconds" % respawn_time)
