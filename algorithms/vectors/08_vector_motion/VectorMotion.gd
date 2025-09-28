extends VectorSceneBase

var ball: RigidBody3D
var acceleration_vector: Node3D
var velocity_vector: Node3D
var position_vector: Node3D
var info_label: Label3D
var accumulator := 0.0

func _ready():
	super._ready()
	create_axes(4.0)
	create_floor(10.0)
	ball = create_ball(Vector3(0.0, 1.0, 0.0), 0.2, 1.0, Color(0.9, 0.4, 0.7, 1.0))
	ball.linear_damp = 0.02
	ball.angular_damp = 0.05
	acceleration_vector = spawn_vector(ball.global_position, Vector3(1.5, 0.5, 0.0), Color(1.0, 0.6, 0.3, 1.0), "Acceleration")
	velocity_vector = spawn_vector(ball.global_position, Vector3.ZERO, Color(0.3, 0.9, 1.0, 1.0), "Velocity", false)
	position_vector = spawn_vector(Vector3.ZERO, ball.global_position, Color(0.6, 1.0, 0.6, 1.0), "Position", false)
	info_label = create_info_panel("Motion Vectors", Vector3(-3.2, 2.4, 0.0))

func _physics_process(delta):
	if not ball:
		return
	acceleration_vector.position = ball.global_position
	velocity_vector.position = ball.global_position
	var accel = get_vector(acceleration_vector)
	ball.apply_central_force(accel * ball.mass)
	update_vector(velocity_vector, ball.linear_velocity)
	update_vector(position_vector, ball.global_position)
	accumulator += delta
	if accumulator > 0.1:
		_update_info(accel)
		accumulator = 0.0

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_reset_ball()
		if event.keycode == KEY_SPACE:
			ball.linear_velocity = Vector3.ZERO
			ball.angular_velocity = Vector3.ZERO

func _reset_ball():
	ball.global_position = Vector3(0.0, 1.0, 0.0)
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	acceleration_vector.position = ball.global_position
	velocity_vector.position = ball.global_position
	update_vector(position_vector, ball.global_position)

func _update_info(accel: Vector3):
	var builder := []
	builder.append("Acceleration = (%.2f, %.2f, %.2f)" % [accel.x, accel.y, accel.z])
	builder.append("Velocity = (%.2f, %.2f, %.2f)" % [ball.linear_velocity.x, ball.linear_velocity.y, ball.linear_velocity.z])
	builder.append("Speed = %.2f" % ball.linear_velocity.length())
	builder.append("Position = (%.2f, %.2f, %.2f)" % [ball.global_position.x, ball.global_position.y, ball.global_position.z])
	info_label.text = "\n".join(builder)
