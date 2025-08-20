extends Node3D

# Camera Controller for Evolutionary Ecosystem Visualization
# Provides smooth camera movement and interaction controls

@export var camera_speed: float = 10.0
@export var mouse_sensitivity: float = 0.002
@export var zoom_speed: float = 2.0
@export var smooth_factor: float = 5.0

var camera: Camera3D
var is_rotating: bool = false
var rotation_start: Vector2
var target_position: Vector3
var target_rotation: Vector3

func _ready():
	camera = $Camera3D
	target_position = global_position
	target_rotation = rotation_degrees

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_rotating = event.pressed
			rotation_start = event.position
			if is_rotating:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()
	
	elif event is InputEventMouseMotion and is_rotating:
		var delta = event.relative
		rotate_camera(delta)

func _process(delta):
	handle_keyboard_input(delta)
	smooth_camera_movement(delta)

func handle_keyboard_input(delta):
	var input_vector = Vector3.ZERO
	
	# Movement input
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_vector.z -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_vector.z += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_vector.x += 1
	if Input.is_key_pressed(KEY_Q):
		input_vector.y -= 1
	if Input.is_key_pressed(KEY_E):
		input_vector.y += 1
	
	# Apply movement
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		var movement = transform.basis * input_vector * camera_speed * delta
		target_position += movement

func rotate_camera(delta: Vector2):
	# Horizontal rotation (around Y axis)
	target_rotation.y -= delta.x * mouse_sensitivity * 100
	
	# Vertical rotation (around X axis)
	target_rotation.x -= delta.y * mouse_sensitivity * 100
	target_rotation.x = clamp(target_rotation.x, -80, 80)

func zoom_in():
	var forward = -transform.basis.z
	target_position += forward * zoom_speed

func zoom_out():
	var forward = -transform.basis.z
	target_position -= forward * zoom_speed

func smooth_camera_movement(delta):
	# Smooth position
	global_position = global_position.lerp(target_position, smooth_factor * delta)
	
	# Smooth rotation
	rotation_degrees = rotation_degrees.lerp(target_rotation, smooth_factor * delta)

func focus_on_position(pos: Vector3, distance: float = 20.0):
	"""Focus camera on a specific position"""
	var direction = (global_position - pos).normalized()
	target_position = pos + direction * distance
	look_at(pos, Vector3.UP)
	target_rotation = rotation_degrees

func set_camera_mode(mode: String):
	"""Set predefined camera modes"""
	match mode:
		"overview":
			target_position = Vector3(0, 25, 25)
			target_rotation = Vector3(-30, 0, 0)
		"close":
			target_position = Vector3(0, 10, 10)
			target_rotation = Vector3(-20, 0, 0)
		"side":
			target_position = Vector3(30, 15, 0)
			target_rotation = Vector3(-15, -90, 0)
		"top":
			target_position = Vector3(0, 50, 0)
			target_rotation = Vector3(-90, 0, 0) 