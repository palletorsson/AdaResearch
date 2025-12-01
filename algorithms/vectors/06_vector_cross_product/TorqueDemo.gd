extends "res://algorithms/vectors/shared/force_containment_base.gd"

## Torque Demo
## Demonstrates: τ = r × F (cross product)
## Concept: Rotational force depends on position and direction
## Agent-PhysicsArchitect: Shows angular acceleration
## Protocol: IACP v2.2

var force_vector: Node3D
var position_vector: Node3D
var torque_vector: Node3D

# Cached nodes
var _force_cache: Dictionary = {}
var _position_cache: Dictionary = {}
var _torque_cache: Dictionary = {}

var accumulator: float = 0.0
const UPDATE_INTERVAL = 0.1

# Force application point (offset from center)
var force_offset: Vector3 = Vector3(0.15, 0, 0)

func _ready():
	super._ready()
	_setup_demo()
	print("TorqueDemo: Ready - Apply force off-center!")

func _setup_demo():
	"""Setup torque demonstration"""
	# Position vector (from center to force application point) - Cyan
	position_vector = create_force_vector(
		"Position (r)",
		force_offset,
		Color(0.3, 0.8, 1.0, 1.0),
		true  # Can drag to change application point
	)
	_position_cache = _cached_vector_nodes["Position (r)"]
	
	# Force vector (user can drag) - Red
	force_vector = create_force_vector(
		"Force (F)",
		Vector3(0, 2.0, 0),
		Color(1.0, 0.3, 0.3, 1.0),
		true
	)
	_force_cache = _cached_vector_nodes["Force (F)"]
	
	# Torque vector (read-only, shows τ = r × F) - Purple
	torque_vector = create_force_vector(
		"Torque (τ)",
		Vector3.ZERO,
		Color(0.8, 0.3, 1.0, 1.0),
		false
	)
	_torque_cache = _cached_vector_nodes["Torque (τ)"]
	
	update_info_text([
		"Torque Demo",
		"Drag CYAN (position)",
		"Drag RED (force)",
		"τ = r × F"
	])

func _physics_process(delta):
	# Get position and force (logical)
	var r = _get_vector_fast_cached(_position_cache)
	var f = _get_vector_fast_cached(_force_cache)
	
	# Calculate torque: τ = r × F (cross product!)
	var torque = r.cross(f)
	
	# Update torque vector visualization
	_update_vector_fast_cached(_torque_cache, torque * 0.5)  # Scale for visibility
	
	# Apply torque to ball (scaled)
	physics_ball.apply_torque(torque * SCENE_SCALE)
	
	# Also apply the force at the offset position
	# This makes the physics more realistic
	var force_world_pos = physics_ball.global_position + (r * SCENE_SCALE)
	physics_ball.apply_force(f * SCENE_SCALE, r * SCENE_SCALE)
	
	# Update vector positions
	var ball_pos_scaled = physics_ball.global_position
	position_vector.position = ball_pos_scaled
	force_vector.position = ball_pos_scaled + (r * SCENE_SCALE)
	torque_vector.position = ball_pos_scaled
	
	# Throttled info update
	accumulator += delta
	if accumulator >= UPDATE_INTERVAL:
		_update_info(r, f, torque)
		accumulator = 0.0

func _update_info(r: Vector3, f: Vector3, torque: Vector3):
	"""Update info display"""
	var angular_vel = physics_ball.angular_velocity / SCENE_SCALE
	
	var lines = [
		"Torque Demo",
		"",
		"Position: %.2f m" % r.length(),
		"r = (%.2f, %.2f, %.2f)" % [r.x, r.y, r.z],
		"",
		"Force: %.2f N" % f.length(),
		"F = (%.2f, %.2f, %.2f)" % [f.x, f.y, f.z],
		"",
		"Torque: %.2f N·m" % torque.length(),
		"τ = r × F",
		"τ = (%.2f, %.2f, %.2f)" % [torque.x, torque.y, torque.z],
		"",
		"Angular Velocity: %.2f rad/s" % angular_vel.length(),
		"ω = (%.2f, %.2f, %.2f)" % [angular_vel.x, angular_vel.y, angular_vel.z]
	]
	update_info_text(lines)

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_reset_demo()
		elif event.keycode == KEY_SPACE:
			physics_ball.linear_velocity = Vector3.ZERO
			physics_ball.angular_velocity = Vector3.ZERO

func _reset_demo():
	"""Reset to initial state"""
	reset_ball(Vector3.ZERO)
	
	# Reset position vector
	var end_r: Node3D = _position_cache.get("end")
	if end_r:
		end_r.position = Vector3(0.15, 0, 0) * SCENE_SCALE
	var line_r: Node3D = _position_cache.get("line_container")
	if line_r and line_r.has_method("refresh_connections"):
		line_r.refresh_connections()
	
	# Reset force vector
	var end_f: Node3D = _force_cache.get("end")
	if end_f:
		end_f.position = Vector3(0, 2.0, 0) * SCENE_SCALE
	var line_f: Node3D = _force_cache.get("line_container")
	if line_f and line_f.has_method("refresh_connections"):
		line_f.refresh_connections()
	
	print("TorqueDemo: Reset")
