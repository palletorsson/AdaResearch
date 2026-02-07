extends "res://algorithms/vectors/shared/vector_scene_base.gd"

const DRAG_COEFFICIENT := 0.8
const CatapultGadgetScript = preload("res://algorithms/vectors/shared/gadgets/catapult_gadget.gd")

var ball: RigidBody3D
var gravity_vector: Node3D
var thrust_vector: Node3D
var drag_vector: Node3D
var net_vector: Node3D
var velocity_vector: Node3D
var accel_vector: Node3D
var info_label: Label3D
var accumulator := 0.0
var catapult_gadget: Node3D

# Cached nodes
var _cached_gravity_nodes: Dictionary = {}
var _cached_thrust_nodes: Dictionary = {}
var _cached_drag_nodes: Dictionary = {}
var _cached_net_nodes: Dictionary = {}
var _cached_velocity_nodes: Dictionary = {}
var _cached_accel_nodes: Dictionary = {}

func _ready():
	super._ready()
	# Half-size for exhibition display
	scale = Vector3(0.5, 0.5, 0.5)

	create_axes(1.5)
	_create_ground()
	ball = create_ball(Vector3(0.0, 1.2, 0.0), 0.22, 1.2, Color(0.9, 0.5, 1.0, 1.0))

	# Force vectors: light blue gravity, warm thrust, cool drag, bright green net
	gravity_vector = spawn_vector(Vector3.ZERO, Vector3(0.0, -6.0, 0.0), Color(0.5, 0.75, 1.0, 1.0), "Gravity")
	thrust_vector = spawn_vector(Vector3.ZERO, Vector3(2.5, 0.0, 0.0), Color(1.0, 0.55, 0.35, 1.0), "Thrust")
	drag_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.65, 0.75, 1.0, 0.6), "Drag", false)
	net_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.45, 1.0, 0.4, 0.9), "Net Force", false)
	velocity_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.55, 0.95, 1.0, 0.8), "Velocity", false)
	accel_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(1.0, 0.9, 0.45, 0.85), "Acceleration", false)

	info_label = create_info_panel("Vector Forces", Vector3(0, 2.5, -0.8), Vector2(2.4, 1.0), "F_net = sum(F_i)", "Net force from thrust, gravity, drag")

	# Catapult gadget
	catapult_gadget = CatapultGadgetScript.new()
	catapult_gadget.position = Vector3(-0.6, 0, 0)
	add_child(catapult_gadget)

	# Cache nodes
	_cache_vector_nodes(gravity_vector, _cached_gravity_nodes)
	_cache_vector_nodes(thrust_vector, _cached_thrust_nodes)
	_cache_vector_nodes(drag_vector, _cached_drag_nodes)
	_cache_vector_nodes(net_vector, _cached_net_nodes)
	_cache_vector_nodes(velocity_vector, _cached_velocity_nodes)
	_cache_vector_nodes(accel_vector, _cached_accel_nodes)

func _physics_process(delta):
	if not ball:
		return
	
	# ball.global_position is already in Scaled World Space.
	# gravity_vector.position expects Scaled World Space (because parent is unscaled).
	# So we can assign directly.
	var ball_pos_scaled = ball.global_position

	gravity_vector.position = ball_pos_scaled
	thrust_vector.position = ball_pos_scaled
	drag_vector.position = ball_pos_scaled
	net_vector.position = ball_pos_scaled
	velocity_vector.position = ball_pos_scaled
	accel_vector.position = ball_pos_scaled

	# get_vector returns LOGICAL force (unscaled).
	var gravity_logical = _get_vector_fast(gravity_vector, _cached_gravity_nodes)
	var gravity_force_logical = gravity_logical * ball.mass
	
	var thrust_force_logical = _get_vector_fast(thrust_vector, _cached_thrust_nodes)
	
	# Calculate LOGICAL velocity from physical scaled velocity
	var velocity_logical = ball.linear_velocity / SCENE_SCALE
	var drag_force_logical = -velocity_logical * DRAG_COEFFICIENT
	
	# Update drag vector visual with LOGICAL force
	_update_vector_fast(drag_vector, drag_force_logical, _cached_drag_nodes)

	# Sum LOGICAL forces
	var net_force_logical = gravity_force_logical + thrust_force_logical + drag_force_logical

	# Update net force vector visual
	_update_vector_fast(net_vector, net_force_logical, _cached_net_nodes)
	# Update velocity / acceleration visuals
	_update_vector_fast(velocity_vector, velocity_logical, _cached_velocity_nodes)
	var accel_logical = net_force_logical / ball.mass
	_update_vector_fast(accel_vector, accel_logical, _cached_accel_nodes)

	# Apply SCALED force to physics body so simulation matches visual scale
	ball.apply_central_force(net_force_logical * SCENE_SCALE)

	# Update catapult gadget — follow ball position
	if catapult_gadget:
		catapult_gadget.update_from_vectors(thrust_force_logical, gravity_force_logical)

	accumulator += delta
	if accumulator > 0.1:
		_update_info(gravity_force_logical, thrust_force_logical, drag_force_logical, net_force_logical, velocity_logical)
		accumulator = 0.0

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_reset_ball()
		if event.keycode == KEY_SPACE:
			ball.linear_velocity = Vector3.ZERO
			ball.angular_velocity = Vector3.ZERO

func _reset_ball():
	# Reset to scaled position
	ball.global_position = Vector3(0.0, 1.2, 0.0) * SCENE_SCALE
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	
	var ball_pos_scaled = ball.global_position
	gravity_vector.position = ball_pos_scaled
	thrust_vector.position = ball_pos_scaled
	drag_vector.position = ball_pos_scaled
	net_vector.position = ball_pos_scaled
	velocity_vector.position = ball_pos_scaled
	accel_vector.position = ball_pos_scaled

func _update_info(gravity_force: Vector3, thrust_force: Vector3, drag_force: Vector3, net_force: Vector3, velocity: Vector3):
	var builder := []
	builder.append("Gravity = (%.2f, %.2f, %.2f)" % [gravity_force.x, gravity_force.y, gravity_force.z])
	builder.append("Thrust = (%.2f, %.2f, %.2f)" % [thrust_force.x, thrust_force.y, thrust_force.z])
	builder.append("Drag = (%.2f, %.2f, %.2f)" % [drag_force.x, drag_force.y, drag_force.z])
	builder.append("Net = (%.2f, %.2f, %.2f)" % [net_force.x, net_force.y, net_force.z])
	# Acceleration = F/m (Logical)
	var acc = net_force / ball.mass
	builder.append("Acceleration = (%.2f, %.2f, %.2f)" % [acc.x, acc.y, acc.z])
	builder.append("Velocity = (%.2f, %.2f, %.2f)" % [velocity.x, velocity.y, velocity.z])
	info_label.text = "\n".join(builder)

func _create_ground():
	var ground = StaticBody3D.new()
	ground.name = "Ground"
	var collider = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(20, 0.1, 20) * SCENE_SCALE # Scale the ground
	collider.shape = box
	ground.add_child(collider)
	add_child(ground)

# --- Caching Helpers (Local Implementation) ---

func _cache_vector_nodes(arrow: Node3D, cache_dict: Dictionary):
	if arrow == null: return
	cache_dict["start"] = arrow.get_node_or_null("lineContainer/GrabSphere")
	cache_dict["end"] = arrow.get_node_or_null("lineContainer/GrabSphere2")
	cache_dict["line_container"] = arrow.get_node_or_null("lineContainer")

func _get_vector_fast(arrow: Node3D, cache_dict: Dictionary) -> Vector3:
	var start: Node3D = cache_dict.get("start")
	var end: Node3D = cache_dict.get("end")
	if start and end:
		return (end.global_position - start.global_position) / (SCENE_SCALE * scale.x)
	if arrow.has_method("get_vector"):
		return arrow.get_vector()
	return Vector3.ZERO

func _update_vector_fast(arrow: Node3D, vector: Vector3, cache_dict: Dictionary):
	var end_node: Node3D = cache_dict.get("end")
	if end_node:
		end_node.position = vector * SCENE_SCALE
	var line_container: Node3D = cache_dict.get("line_container")
	if line_container and line_container.has_method("refresh_connections"):
		line_container.refresh_connections()
