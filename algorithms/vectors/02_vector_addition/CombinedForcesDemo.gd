extends "res://algorithms/vectors/shared/force_containment_base.gd"

## Combined Forces Demo
## Demonstrates: F_net = F1 + F2 (vector addition)
## Concept: Forces combine using tip-to-tail addition
## Agent-PhysicsArchitect: Shows superposition principle
## Protocol: IACP v2.2

var force1_vector: Node3D
var force2_vector: Node3D
var net_force_vector: Node3D
var velocity_vector: Node3D

# Cached nodes
var _force1_cache: Dictionary = {}
var _force2_cache: Dictionary = {}
var _net_cache: Dictionary = {}
var _velocity_cache: Dictionary = {}

var accumulator: float = 0.0
const UPDATE_INTERVAL = 0.1

func _ready():
	super._ready()
	_setup_demo()
	print("CombinedForcesDemo: Ready - Drag the force vectors!")

func _setup_demo():
	"""Setup combined forces demonstration"""
	# Force 1 (user can drag) - Red
	force1_vector = create_force_vector(
		"Force 1",
		Vector3(1.5, 0, 0),
		Color(1.0, 0.3, 0.3, 1.0),
		true
	)
	_force1_cache = _cached_vector_nodes["Force 1"]
	
	# Force 2 (user can drag) - Orange
	force2_vector = create_force_vector(
		"Force 2",
		Vector3(0, 1.5, 0),
		Color(1.0, 0.6, 0.2, 1.0),
		true
	)
	_force2_cache = _cached_vector_nodes["Force 2"]
	
	# Net force (read-only, shows F1 + F2) - Yellow
	net_force_vector = create_force_vector(
		"Net Force",
		Vector3.ZERO,
		Color(1.0, 1.0, 0.3, 1.0),
		false
	)
	_net_cache = _cached_vector_nodes["Net Force"]
	
	# Velocity (read-only) - Green
	velocity_vector = create_force_vector(
		"Velocity",
		Vector3.ZERO,
		Color(0.3, 1.0, 0.3, 1.0),
		false
	)
	_velocity_cache = _cached_vector_nodes["Velocity"]
	
	update_info_text([
		"Combined Forces Demo",
		"Drag RED and ORANGE vectors",
		"F_net = F1 + F2",
		"Forces add as vectors"
	])

func _physics_process(delta):
	update_force_vector_position()
	
	# Get forces (logical units)
	var f1 = _get_vector_fast_cached(_force1_cache)
	var f2 = _get_vector_fast_cached(_force2_cache)
	
	# Calculate net force (vector addition!)
	var f_net = f1 + f2
	
	# Update net force vector visualization
	_update_vector_fast_cached(_net_cache, f_net)
	
	# Apply net force to ball
	physics_ball.apply_central_force(f_net * SCENE_SCALE)
	
	# Get velocity
	var velocity = physics_ball.linear_velocity / SCENE_SCALE
	_update_vector_fast_cached(_velocity_cache, velocity)
	
	# Throttled info update
	accumulator += delta
	if accumulator >= UPDATE_INTERVAL:
		_update_info(f1, f2, f_net, velocity)
		accumulator = 0.0

func _update_info(f1: Vector3, f2: Vector3, f_net: Vector3, velocity: Vector3):
	"""Update info display"""
	var lines = [
		"Combined Forces Demo",
		"",
		"Force 1: %.2f N" % f1.length(),
		"F1 = (%.2f, %.2f, %.2f)" % [f1.x, f1.y, f1.z],
		"",
		"Force 2: %.2f N" % f2.length(),
		"F2 = (%.2f, %.2f, %.2f)" % [f2.x, f2.y, f2.z],
		"",
		"Net Force: %.2f N" % f_net.length(),
		"F_net = F1 + F2",
		"F_net = (%.2f, %.2f, %.2f)" % [f_net.x, f_net.y, f_net.z],
		"",
		"Velocity: %.2f m/s" % velocity.length()
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
	
	# Reset force 1
	var end1: Node3D = _force1_cache.get("end")
	if end1:
		end1.position = Vector3(1.5, 0, 0) * SCENE_SCALE
	var line1: Node3D = _force1_cache.get("line_container")
	if line1 and line1.has_method("refresh_connections"):
		line1.refresh_connections()
	
	# Reset force 2
	var end2: Node3D = _force2_cache.get("end")
	if end2:
		end2.position = Vector3(0, 1.5, 0) * SCENE_SCALE
	var line2: Node3D = _force2_cache.get("line_container")
	if line2 and line2.has_method("refresh_connections"):
		line2.refresh_connections()
	
	print("CombinedForcesDemo: Reset")
