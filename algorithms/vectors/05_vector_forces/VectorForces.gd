extends "res://algorithms/vectors/shared/vector_scene_base.gd"

const DRAG_COEFFICIENT := 0.8

var ball: RigidBody3D
var gravity_vector: Node3D
var thrust_vector: Node3D
var drag_vector: Node3D
var info_label: Label3D
var accumulator := 0.0

func _ready():
	super._ready()
	create_axes(4.0)
	_create_ground()
	ball = create_ball(Vector3(0.0, 1.2, 0.0), 0.22, 1.2, Color(0.9, 0.5, 1.0, 1.0))
	gravity_vector = spawn_vector(ball.global_position, Vector3(0.0, -6.0, 0.0), Color(0.4, 0.8, 1.0, 1.0), "Gravity")
	thrust_vector = spawn_vector(ball.global_position, Vector3(2.5, 0.0, 0.0), Color(1.0, 0.6, 0.4, 1.0), "Thrust")
	drag_vector = spawn_vector(ball.global_position, Vector3.ZERO, Color(0.6, 0.7, 1.0, 0.7), "Drag", false)
	info_label = create_info_panel("Forces", Vector3(-3.0, 2.4, 0.0))

func _physics_process(delta):
	if not ball:
		return
	gravity_vector.position = ball.global_position
	thrust_vector.position = ball.global_position
	drag_vector.position = ball.global_position
	var gravity_force = get_vector(gravity_vector) * ball.mass
	var thrust_force = get_vector(thrust_vector)
	var drag_force = -ball.linear_velocity * DRAG_COEFFICIENT
	update_vector(drag_vector, drag_force)
	var net_force = gravity_force + thrust_force + drag_force
	ball.apply_central_force(net_force)
	accumulator += delta
	if accumulator > 0.1:
		_update_info(gravity_force, thrust_force, drag_force, net_force)
		accumulator = 0.0

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_reset_ball()
		if event.keycode == KEY_SPACE:
			ball.linear_velocity = Vector3.ZERO
			ball.angular_velocity = Vector3.ZERO

func _reset_ball():
	ball.global_position = Vector3(0.0, 1.2, 0.0)
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	gravity_vector.position = ball.global_position
	thrust_vector.position = ball.global_position
	drag_vector.position = ball.global_position

func _update_info(gravity_force: Vector3, thrust_force: Vector3, drag_force: Vector3, net_force: Vector3):
	var builder := []
	builder.append("Gravity = (%.2f, %.2f, %.2f)" % [gravity_force.x, gravity_force.y, gravity_force.z])
	builder.append("Thrust = (%.2f, %.2f, %.2f)" % [thrust_force.x, thrust_force.y, thrust_force.z])
	builder.append("Drag = (%.2f, %.2f, %.2f)" % [drag_force.x, drag_force.y, drag_force.z])
	builder.append("Net = (%.2f, %.2f, %.2f)" % [net_force.x, net_force.y, net_force.z])
	builder.append("Acceleration = (%.2f, %.2f, %.2f)" % [(net_force / ball.mass).x, (net_force / ball.mass).y, (net_force / ball.mass).z])
	builder.append("Velocity = (%.2f, %.2f, %.2f)" % [ball.linear_velocity.x, ball.linear_velocity.y, ball.linear_velocity.z])
	info_label.text = "\n".join(builder)

func _create_ground():
	var ground = StaticBody3D.new()
	ground.name = "Ground"
	var collider = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(20, 0.1, 20)  # Very thin box to simulate a plane
	collider.shape = box
	ground.add_child(collider)
	add_child(ground)
