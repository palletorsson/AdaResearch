# camera_controller.gd
extends Camera3D

var move_speed = 10.0
var rotate_speed = 0.5

func _process(delta):
	# Rotation
	if Input.is_action_pressed("ui_left"):
		rotate_y(rotate_speed * delta)
	if Input.is_action_pressed("ui_right"):
		rotate_y(-rotate_speed * delta)
		
	# Movement
	var direction = Vector3.ZERO
	if Input.is_action_pressed("ui_up"):
		direction -= transform.basis.z
	if Input.is_action_pressed("ui_down"):
		direction += transform.basis.z
	if Input.is_action_pressed("ui_page_up"):
		direction += Vector3.UP
	if Input.is_action_pressed("ui_page_down"):
		direction += Vector3.DOWN
		
	position += direction * move_speed * delta
