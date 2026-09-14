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
@export var auto_start: bool = false  # If true, starts moving automatically without player trigger

# THE COMPOSED RIDES (2026-09-05, Palle: "add translate plus rotation in
# translation, and translation plus scale up and down the space like when we
# take the scale pill but a lot less"). Over the travel the cube turns by
# ride_rotation_degrees and carries its rider round with it, and the SPACE
# scales to ride_scale - the pill's move at a fraction of its dose (the pill is
# x100; a ride says 1.3). Both follow the progress of the travel, so the return
# trip unwinds them, and a rider who steps off is put back to size.
# Map:  tc:3:z#rot:90     tc:6:y#scale:1.3     (the #tail is the registry's grammar)
@export var ride_rotation_degrees: float = 0.0
@export var ride_scale: float = 1.0   # the space at the far end: 1.3 = a third bigger, 0.8 = smaller

var _base_yaw: float = 0.0
var _ride_yaw: float = 0.0            # radians applied so far
var _space_rider: Node3D = null       # whose space is scaled right now
var _space_base_world: float = 1.0
var _space_eye: Node3D = null
var _space_eye_y: float = 0.0

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
	_base_yaw = rotation.y
	
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


	# Auto-start if enabled
	if auto_start:
		start_transport()

func setup_transport_material():
	"""Apply cyan/blue transport cube material"""
	if cube_mesh and cube_mesh.material_override:
		var material = cube_mesh.material_override
		if material is ShaderMaterial:
			var shader_material = material as ShaderMaterial
			# Clone the material to avoid affecting other cubes
			var new_material = shader_material.duplicate()
			
			# Set transport cube colors (cyan theme for movement)
			new_material.set_shader_parameter("fill_color", Color(0.0, 0.8, 1.0, 1.0))  # Light cyan
			new_material.set_shader_parameter("wireframe_color", Color(0.0, 1.0, 1.0, 1.0))  # Cyan wireframe
			
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

				# Auto-restart if auto_start is enabled (continuous loop)
				if auto_start:
					start_transport()
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
	
	elif return_timer > 0 and global_position.distance_to(target_position) < 0.01:
		# Handle return timer
		return_timer -= delta
		if return_timer <= 0:
			start_return()
	
	# No idle animations - transport cube stays perfectly still when not moving

	# the composed rides follow the travel, out and back
	if not is_zero_approx(ride_rotation_degrees) or not is_equal_approx(ride_scale, 1.0):
		_compose_ride()

## How far along the travel the cube stands: 0 at the start, 1 at the far end.
func ride_progress() -> float:
	return clampf(global_position.distance_to(initial_position) / maxf(absf(move_distance), 0.001), 0.0, 1.0)


func _compose_ride() -> void:
	var progress: float = ride_progress()
	var rider: Node3D = carried_player if (carried_player != null and is_instance_valid(carried_player)) else null
	if not is_zero_approx(ride_rotation_degrees):
		var want: float = deg_to_rad(ride_rotation_degrees) * progress
		var dyaw: float = want - _ride_yaw
		if absf(dyaw) > 1e-6:
			rotation.y = _base_yaw + want
			_ride_yaw = want
			if rider != null:
				_turn_rider(rider, dyaw)
	if not is_equal_approx(ride_scale, 1.0):
		if rider != null:
			_scale_space(rider, lerpf(1.0, ride_scale, progress))
		elif _space_rider != null:
			_restore_space()


## The rider turns with the cube: round the cube's centre, and about their own
## axis. A VR rig turns as a whole (the origin); the desktop player keeps its
## heading in a variable it writes every frame, so that is turned too; the
## museum's walker keeps its heading in its owner's `_yaw`.
func _turn_rider(rider: Node3D, dyaw: float) -> void:
	var target: Node3D = rider
	var parent: Node = rider.get_parent()
	if parent is XROrigin3D:
		target = parent as Node3D
	var off: Vector3 = target.global_position - global_position
	target.global_position = global_position + off.rotated(Vector3.UP, dyaw)
	target.rotate_y(dyaw)
	var cr: Variant = target.get("camera_rotation")
	if cr is Vector3 or cr is Vector2:
		cr.y += dyaw
		target.set("camera_rotation", cr)
	if parent != null and not (parent is XROrigin3D) and parent.get("_yaw") != null:
		parent.set("_yaw", float(parent.get("_yaw")) + dyaw)


## The pill's move at a small dose: the space at f times its size is the rider
## at 1/f. In VR that is XRServer.world_scale, which the player body reads live
## for its height and radius; on desktop and for the museum's walker it is the
## eye's height - the first node above the camera that carries a height.
func _scale_space(rider: Node3D, f: float) -> void:
	if _space_rider != rider:
		_restore_space()
		_space_rider = rider
		_space_base_world = XRServer.world_scale
		_space_eye = _eye_of(rider)
		_space_eye_y = _space_eye.position.y if _space_eye != null else 0.0
	if rider.get_parent() is XROrigin3D:
		XRServer.world_scale = _space_base_world / f
	elif _space_eye != null and is_instance_valid(_space_eye):
		_space_eye.position.y = _space_eye_y / f


func _eye_of(rider: Node3D) -> Node3D:
	var cams: Array = rider.find_children("*", "Camera3D", true, false)
	if cams.is_empty():
		return null
	var n: Node = cams[0]
	while n != null and n != rider:
		if n is Node3D and absf((n as Node3D).position.y) > 0.05:
			return n as Node3D
		n = n.get_parent()
	return null


func _restore_space() -> void:
	if _space_rider == null:
		return
	if is_instance_valid(_space_rider) and _space_rider.get_parent() is XROrigin3D:
		XRServer.world_scale = _space_base_world
	elif _space_eye != null and is_instance_valid(_space_eye):
		_space_eye.position.y = _space_eye_y
	_space_rider = null
	_space_eye = null


func _exit_tree() -> void:
	_restore_space()


func _is_player(body: Node3D) -> bool:
	"""Check if the body is a player"""
	# em_walker: the endless museum's desktop walker, which is named "Walker"
	# and joins none of the four below (2026-08-25)
	return body.is_in_group("player") or body.is_in_group("vr_player") or body.name.contains("Player") or body.is_in_group("player_body") or body.is_in_group("em_walker")

func _on_detection_area_body_entered(body: Node3D) -> void:
	if _is_player(body):
		player_on_cube = true
		carried_player = body
		detection_sound.play()
		
		start_transport()

func _on_detection_area_body_exited(body: Node3D) -> void:
	if _is_player(body):
		player_on_cube = false
		if carried_player == body:
			_restore_space()   # whoever steps off is put back to size
			carried_player = null
		
		# Cancel start delay if player exits during delay
		if waiting_to_start:
			waiting_to_start = false
			start_timer = 0.0

func start_transport():
	"""Start the transport sequence"""
	# Only start if at initial position and not already moving
	if global_position.distance_to(initial_position) < 0.01 and not is_moving and not waiting_to_start:
		if start_delay > 0:
			waiting_to_start = true
			start_timer = start_delay
		else:
			is_moving = true
			is_returning = false
			movement_sound.play()

func start_return():
	"""Start the return journey"""
	if global_position.distance_to(target_position) < 0.01:
		is_moving = true
		is_returning = true
		movement_sound.play()

# Public API for configuration
func set_transport_parameters(distance: float, direction: Vector3):
	"""Set transport distance and direction"""
	move_distance = distance
	move_direction = direction.normalized()
	target_position = initial_position + (move_direction * move_distance)

func set_movement_speed(speed: float):
	"""Set movement speed"""
	move_speed = speed

func set_auto_start(enabled: bool):
	"""Enable or disable auto-start mode"""
	auto_start = enabled
	# Only start if already in tree, otherwise _ready() will handle it
	if enabled and is_inside_tree() and not is_moving and not waiting_to_start:
		start_transport()

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
