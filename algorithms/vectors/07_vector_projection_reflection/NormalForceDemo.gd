extends "res://algorithms/vectors/shared/force_containment_base.gd"

## Normal Force Demo
## Demonstrates: Force projection onto surface normal
## Concept: N = F · n̂ (component perpendicular to surface)
## Agent-PhysicsArchitect: Shows force decomposition
## Protocol: IACP v2.2

var gravity_vector: Node3D
var normal_vector: Node3D
var parallel_vector: Node3D
var surface_plane: MeshInstance3D

var _gravity_cache: Dictionary = {}
var _normal_cache: Dictionary = {}
var _parallel_cache: Dictionary = {}

var accumulator: float = 0.0
const UPDATE_INTERVAL = 0.1

# Surface angle (can be adjusted)
var surface_angle: float = 30.0  # degrees
var surface_normal: Vector3 = Vector3.ZERO

func _ready():
	super._ready()
	_setup_demo()
	_update_surface_normal()
	print("NormalForceDemo: Ready - See force decomposition!")

func _setup_demo():
	"""Setup normal force demonstration"""
	# Create angled surface
	_create_surface()
	
	# Gravity (constant downward) - Blue
	gravity_vector = create_force_vector(
		"Gravity",
		Vector3(0, -3.0, 0),
		Color(0.3, 0.5, 1.0, 1.0),
		false
	)
	_gravity_cache = _cached_vector_nodes["Gravity"]
	
	# Normal force (perpendicular to surface) - Green
	normal_vector = create_force_vector(
		"Normal",
		Vector3.ZERO,
		Color(0.3, 1.0, 0.3, 1.0),
		false
	)
	_normal_cache = _cached_vector_nodes["Normal"]
	
	# Parallel force (along surface) - Red
	parallel_vector = create_force_vector(
		"Parallel",
		Vector3.ZERO,
		Color(1.0, 0.3, 0.3, 1.0),
		false
	)
	_parallel_cache = _cached_vector_nodes["Parallel"]
	
	update_info_text([
		"Normal Force Demo",
		"Gravity decomposes into:",
		"Normal (⊥ surface)",
		"Parallel (∥ surface)"
	])

func _create_surface():
	"""Create angled surface plane"""
	surface_plane = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(0.6, 0.6) * SCENE_SCALE
	surface_plane.mesh = plane_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.7, 0.3, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface_plane.material_override = mat
	
	# Position and rotate surface
	surface_plane.position = Vector3(0, -0.2, 0) * SCENE_SCALE
	surface_plane.rotation_degrees = Vector3(-surface_angle, 0, 0)
	
	add_child(surface_plane)

func _update_surface_normal():
	"""Calculate surface normal from angle"""
	var angle_rad = deg_to_rad(surface_angle)
	surface_normal = Vector3(0, cos(angle_rad), sin(angle_rad)).normalized()

func _physics_process(delta):
	update_force_vector_position()
	
	# Gravity force (constant)
	var gravity = Vector3(0, -3.0, 0)
	
	# Project gravity onto surface normal: F_normal = (F · n̂) * n̂
	var normal_magnitude = gravity.dot(surface_normal)
	var f_normal = surface_normal * normal_magnitude
	
	# Parallel component: F_parallel = F - F_normal
	var f_parallel = gravity - f_normal
	
	# Update vectors
	_update_vector_fast_cached(_gravity_cache, gravity)
	_update_vector_fast_cached(_normal_cache, f_normal)
	_update_vector_fast_cached(_parallel_cache, f_parallel)
	
	# Apply forces (normal cancels with surface, parallel causes sliding)
	physics_ball.apply_central_force(f_parallel * SCENE_SCALE)
	
	# Throttled info update
	accumulator += delta
	if accumulator >= UPDATE_INTERVAL:
		_update_info(gravity, f_normal, f_parallel)
		accumulator = 0.0

func _update_info(gravity: Vector3, f_normal: Vector3, f_parallel: Vector3):
	"""Update info display"""
	var lines = [
		"Normal Force Demo",
		"Surface Angle: %.1f°" % surface_angle,
		"",
		"Gravity: %.2f N" % gravity.length(),
		"g = (%.2f, %.2f, %.2f)" % [gravity.x, gravity.y, gravity.z],
		"",
		"Normal Force: %.2f N" % f_normal.length(),
		"N = (g · n̂) * n̂",
		"N = (%.2f, %.2f, %.2f)" % [f_normal.x, f_normal.y, f_normal.z],
		"",
		"Parallel Force: %.2f N" % f_parallel.length(),
		"F∥ = g - N",
		"F∥ = (%.2f, %.2f, %.2f)" % [f_parallel.x, f_parallel.y, f_parallel.z]
	]
	update_info_text(lines)

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_reset_demo()
		elif event.keycode == KEY_SPACE:
			physics_ball.linear_velocity = Vector3.ZERO
			physics_ball.angular_velocity = Vector3.ZERO
		elif event.keycode == KEY_UP:
			surface_angle = clamp(surface_angle + 5.0, 0.0, 60.0)
			_update_surface_angle()
		elif event.keycode == KEY_DOWN:
			surface_angle = clamp(surface_angle - 5.0, 0.0, 60.0)
			_update_surface_angle()

func _update_surface_angle():
	"""Update surface angle and normal"""
	surface_plane.rotation_degrees = Vector3(-surface_angle, 0, 0)
	_update_surface_normal()
	print("NormalForceDemo: Angle = %.1f°" % surface_angle)

func _reset_demo():
	"""Reset to initial state"""
	reset_ball(Vector3(0, 0.1, 0))
	print("NormalForceDemo: Reset")
