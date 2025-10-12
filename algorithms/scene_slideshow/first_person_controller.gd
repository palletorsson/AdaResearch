extends CharacterBody3D
class_name FirstPersonController

# First-person controller with WASD movement and mouse look

@export var move_speed: float = 5.0
@export var sprint_speed: float = 10.0
@export var mouse_sensitivity: float = 0.003
@export var vertical_look_limit: float = 89.0

@onready var camera = $Camera3D

var rotation_x: float = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# Mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Rotate horizontally (around Y axis)
		rotate_y(-event.relative.x * mouse_sensitivity)

		# Rotate vertically (camera only)
		rotation_x -= event.relative.y * mouse_sensitivity
		rotation_x = clamp(rotation_x, -deg_to_rad(vertical_look_limit), deg_to_rad(vertical_look_limit))
		camera.rotation.x = rotation_x

	# Toggle mouse capture
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# Get movement input
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Calculate movement direction relative to camera
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Apply speed (sprint with shift)
	var speed = sprint_speed if Input.is_action_pressed("action_sprint") else move_speed

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# Simple gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	move_and_slide()
