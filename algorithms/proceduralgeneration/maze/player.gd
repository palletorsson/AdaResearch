# player.gd - First-person player controller
extends CharacterBody3D

@export var movement_speed := 4.0
@export var rotation_speed := 180.0
@export var mouse_sensitivity := 5.0
@export var starting_vertical_angle := 10.0

var eye_angles := Vector2.ZERO
var camera: Camera3D

func _ready():
	camera = $Camera3D
	
	var collision = $CollisionShape3D
	var shape = CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.6
	collision.shape = shape
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouse_delta = rotation_speed * mouse_sensitivity * get_process_delta_time()
		eye_angles.x += event.relative.x * mouse_delta * 0.1
		eye_angles.y -= event.relative.y * mouse_delta * 0.1
	
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func start_new_game(pos: Vector3):
	eye_angles.x = randf() * 360.0
	eye_angles.y = starting_vertical_angle
	position = pos

func move(delta: float) -> Vector3:
	update_eye_angles(delta)
	update_position(delta)
	return position

func update_eye_angles(delta: float):
	var rotation_delta = rotation_speed * delta
	
	if Input.is_action_pressed("ui_left"):
		eye_angles.x -= rotation_delta
	if Input.is_action_pressed("ui_right"):
		eye_angles.x += rotation_delta
	
	eye_angles.x = fmod(eye_angles.x, 360.0)
	if eye_angles.x < 0:
		eye_angles.x += 360.0
	
	eye_angles.y = clamp(eye_angles.y, -45.0, 45.0)
	
	camera.rotation_degrees = Vector3(eye_angles.y, eye_angles.x, 0)

func update_position(delta: float):
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.y += 1.0
	if Input.is_action_pressed("move_backward"):
		input_dir.y -= 1.0
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1.0
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1.0
	
	if input_dir.length_squared() > 1.0:
		input_dir = input_dir.normalized()
	
	input_dir *= movement_speed
	
	var angle_rad = deg_to_rad(eye_angles.x)
	var forward = Vector2(sin(angle_rad), cos(angle_rad))
	var right = Vector2(forward.y, -forward.x)
	
	var movement_2d = right * input_dir.x + forward * input_dir.y
	
	velocity.x = movement_2d.x
	velocity.z = movement_2d.y
	velocity.y = 0.0
	
	move_and_slide()
