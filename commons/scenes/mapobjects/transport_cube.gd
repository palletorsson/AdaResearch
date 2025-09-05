# transport_cube.gd - A cube that transports players across voids
# Based on cube_scene.tscn with movement capabilities similar to platform utility
extends Node3D

class_name TransportCube

# Movement configuration
@export var move_distance: float = 4.0  # Distance to move in world units
@export var move_direction: Vector3 = Vector3(1, 0, 0)  # Direction vector (will be normalized)
@export var move_speed: float = 2.0  # Speed of movement
@export var return_delay: float = 3.0  # Seconds to wait before returning
@export var start_delay: float = 1.0  # Seconds to wait before starting to move

# Visual effects
@export var rotation_speed: float = 0.5  # Cube rotation while idle
@export var bob_height: float = 0.1  # Bobbing motion amplitude
@export var bob_speed: float = 1.5  # Bobbing motion speed

# Internal state
var initial_position: Vector3
var target_position: Vector3
var is_moving: bool = false
var is_returning: bool = false
var player_on_cube: bool = false
var return_timer: float = 0.0
var start_timer: float = 0.0
var waiting_to_start: bool = false

# Visual state
var original_y: float
var time_passed: float = 0.0
var carried_player: Node3D = null

# Audio
var movement_sound: AudioStreamPlayer3D
var detection_sound: AudioStreamPlayer3D

# References to scene components
@onready var detection_area: Area3D = $CubeBaseStaticBody3D/DetectionArea
@onready var cube_mesh: MeshInstance3D = $CubeBaseStaticBody3D/CubeBaseStaticBody3D/CubeBaseMesh
@onready var static_body: StaticBody3D = $CubeBaseStaticBody3D/CubeBaseStaticBody3D

func _ready() -> void:
	# Store initial position
	initial_position = global_position
	original_y = global_position.y
	
	# Normalize and calculate target position
	move_direction = move_direction.normalized()
	target_position = initial_position + (move_direction * move_distance)
	
	# Setup audio
	setup_audio()
	
	# Setup detection area connections if not already connected
	if not detection_area.body_entered.is_connected(_on_detection_area_body_entered):
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	# Apply transport cube material
	setup_transport_material()
	
	print("TransportCube: Ready to transport from %s to %s (distance: %.1f)" % [initial_position, target_position, move_distance])

func setup_transport_material():
	"""Apply cyan/blue transport cube material"""
	if cube_mesh and cube_mesh.material_override:
		var material = cube_mesh.material_override
		if material is ShaderMaterial:
			var shader_material = material as ShaderMaterial
			# Clone the material to avoid affecting other cubes
			var new_material = shader_material.duplicate()
			
			# Set transport cube colors (cyan theme for movement)
			new_material.set_shader_parameter("modelColor", Color(0.2, 0.8, 1.0, 1.0))  # Light cyan
			new_material.set_shader_parameter("wireframeColor", Color(0.0, 1.0, 1.0, 1.0))  # Cyan wireframe
			new_material.set_shader_parameter("emissionColor", Color(0.3, 0.9, 1.0, 1.0))  # Bright cyan emission
			new_material.set_shader_parameter("emission_strength", 1.8)
			
			cube_mesh.material_override = new_material

func setup_audio():
	"""Setup audio players for transport cube"""
	# Movement sound
	movement_sound = AudioStreamPlayer3D.new()
	add_child(movement_sound)
	movement_sound.unit_size = 2.0
	movement_sound.max_distance = 15.0
	movement_sound.volume_db = -6.0
	
	# Detection sound  
	detection_sound = AudioStreamPlayer3D.new()
	add_child(detection_sound)
	detection_sound.unit_size = 2.0
	detection_sound.max_distance = 10.0
	detection_sound.volume_db = -9.0
	
	# Generate transport sounds
	create_transport_sounds()

func create_transport_sounds():
	"""Create synthesized transport sounds"""
	var sample_rate = 44100
	
	# Movement sound - smooth whooshing
	var movement_stream = AudioStreamWAV.new()
	movement_stream.format = AudioStreamWAV.FORMAT_16_BITS
	movement_stream.mix_rate = sample_rate
	
	var movement_data = PackedByteArray()
	var movement_length = 1.0  # 1 second loop
	var movement_samples = movement_length * sample_rate
	
	for i in range(movement_samples):
		var t = float(i) / sample_rate
		var progress = t / movement_length
		
		# Create whooshing sound with modulated sine wave
		var base_freq = 120.0 + sin(progress * TAU * 2.0) * 40.0
		var amplitude = 0.3 * (1.0 - progress * 0.3)  # Slight fade
		
		# Add harmonic for richness
		var sample_value = amplitude * (
			sin(TAU * t * base_freq) * 0.7 +
			sin(TAU * t * base_freq * 1.5) * 0.3
		)
		
		var sample_int = int(sample_value * 32767.0)
		movement_data.append(sample_int & 0xFF)
		movement_data.append((sample_int >> 8) & 0xFF)
	
	movement_stream.data = movement_data
	movement_sound.stream = movement_stream
	
	# Detection sound - welcoming chime
	var detection_stream = AudioStreamWAV.new()
	detection_stream.format = AudioStreamWAV.FORMAT_16_BITS
	detection_stream.mix_rate = sample_rate
	
	var detection_data = PackedByteArray()
	var detection_length = 0.5
	var detection_samples = detection_length * sample_rate
	
	for i in range(detection_samples):
		var t = float(i) / sample_rate
		var progress = t / detection_length
		
		# Two-tone chime
		var freq1 = 523.3  # C5
		var freq2 = 783.9  # G5
		var amplitude = 0.4 * (1.0 - progress)  # Fade out
		
		var sample_value = amplitude * (
			sin(TAU * t * freq1) * 0.6 +
			sin(TAU * t * freq2) * 0.4
		)
		
		var sample_int = int(sample_value * 32767.0)
		detection_data.append(sample_int & 0xFF)
		detection_data.append((sample_int >> 8) & 0xFF)
	
	detection_stream.data = detection_data
	detection_sound.stream = detection_stream

func _process(delta: float) -> void:
	time_passed += delta
	
	# Handle start delay timer
	if waiting_to_start:
		start_timer -= delta
		if start_timer <= 0:
			waiting_to_start = false
			is_moving = true
			movement_sound.play()
			print("TransportCube: Starting movement to %s" % target_position)
	
	elif is_moving:
		# Move towards target
		var previous_position = global_position
		
		if is_returning:
			global_position = global_position.move_toward(initial_position, move_speed * delta)
			
			# Move carried player with the cube
			if carried_player and is_instance_valid(carried_player):
				var movement_delta = global_position - previous_position
				carried_player.global_position += movement_delta
			
			# Check if reached initial position
			if global_position.distance_to(initial_position) < 0.01:
				global_position = initial_position
				is_moving = false
				is_returning = false
				movement_sound.stop()
				print("TransportCube: Returned to start position")
		else:
			global_position = global_position.move_toward(target_position, move_speed * delta)
			
			# Move carried player with the cube
			if carried_player and is_instance_valid(carried_player):
				var movement_delta = global_position - previous_position
				carried_player.global_position += movement_delta
			
			# Check if reached target position
			if global_position.distance_to(target_position) < 0.01:
				global_position = target_position
				is_moving = false
				movement_sound.stop()
				return_timer = return_delay
				print("TransportCube: Reached destination, returning in %.1f seconds" % return_delay)
	
	elif return_timer > 0 and global_position.distance_to(target_position) < 0.01:
		# Handle return timer
		return_timer -= delta
		if return_timer <= 0:
			start_return()
	
	# No idle animations - transport cube stays perfectly still when not moving

func _is_player(body: Node3D) -> bool:
	"""Check if the body is a player"""
	return body.is_in_group("player") or body.is_in_group("vr_player") or body.name.contains("Player") or body.is_in_group("player_body")

func _on_detection_area_body_entered(body: Node3D) -> void:
	if _is_player(body):
		player_on_cube = true
		carried_player = body
		detection_sound.play()
		
		print("TransportCube: Player %s detected, preparing transport" % body.name)
		start_transport()

func _on_detection_area_body_exited(body: Node3D) -> void:
	if _is_player(body):
		player_on_cube = false
		if carried_player == body:
			carried_player = null
		
		# Cancel start delay if player exits during delay
		if waiting_to_start:
			waiting_to_start = false
			start_timer = 0.0
			print("TransportCube: Transport cancelled - player left cube")

func start_transport():
	"""Start the transport sequence"""
	# Only start if at initial position and not already moving
	if global_position.distance_to(initial_position) < 0.01 and not is_moving and not waiting_to_start:
		if start_delay > 0:
			waiting_to_start = true
			start_timer = start_delay
			print("TransportCube: Transport starting in %.1f seconds" % start_delay)
		else:
			is_moving = true
			is_returning = false
			movement_sound.play()
			print("TransportCube: Transport started immediately")

func start_return():
	"""Start the return journey"""
	if global_position.distance_to(target_position) < 0.01:
		is_moving = true
		is_returning = true
		movement_sound.play()
		print("TransportCube: Returning to start position")

# Public API for configuration
func set_transport_parameters(distance: float, direction: Vector3):
	"""Set transport distance and direction"""
	move_distance = distance
	move_direction = direction.normalized()
	target_position = initial_position + (move_direction * move_distance)
	print("TransportCube: Updated transport to %s (distance: %.1f)" % [target_position, move_distance])

func set_movement_speed(speed: float):
	"""Set movement speed"""
	move_speed = speed

func set_return_delay(delay: float):
	"""Set return delay"""
	return_delay = delay

# Utility function for parameter parsing
static func parse_parameters(param_string: String) -> Dictionary:
	"""Parse parameter string like '4:z' or '3.5:1,0,0'"""
	var result = {"distance": 4.0, "direction": Vector3(1, 0, 0)}
	
	if param_string.is_empty():
		return result
	
	var parts = param_string.split(":")
	if parts.size() >= 1:
		result.distance = parts[0].to_float()
	
	if parts.size() >= 2:
		var dir_str = parts[1].strip_edges()
		match dir_str.to_lower():
			"x":
				result.direction = Vector3(1, 0, 0)
			"y":
				result.direction = Vector3(0, 1, 0)
			"z":
				result.direction = Vector3(0, 0, 1)
			"-x":
				result.direction = Vector3(-1, 0, 0)
			"-y":
				result.direction = Vector3(0, -1, 0)
			"-z":
				result.direction = Vector3(0, 0, -1)
			_:
				# Try parsing as comma-separated values
				var coords = dir_str.split(",")
				if coords.size() >= 3:
					result.direction = Vector3(
						coords[0].to_float(),
						coords[1].to_float(),
						coords[2].to_float()
					)
	
	return result
