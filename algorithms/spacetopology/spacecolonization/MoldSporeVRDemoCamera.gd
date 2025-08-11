# MoldSporeVRDemoCamera.gd
# Camera controller for the Mold Spore VR Demo
# Provides smooth camera movement and mouse look

extends Camera3D

# Camera movement parameters
@export var movement_speed: float = 2.0
@export var sprint_speed: float = 4.0
@export var mouse_sensitivity: float = 0.002
@export var zoom_speed: float = 1.0
@export var min_zoom_distance: float = 1.0
@export var max_zoom_distance: float = 8.0

# Camera state
var camera_rotation: Vector2 = Vector2.ZERO
var is_mouse_captured: bool = false
var zoom_distance: float = 3.0
var orbit_center: Vector3 = Vector3(0.5, 0.5, 0.5)  # Center of 1x1x1 space

func _ready():
	# Position camera to look at the generation space
	look_at_generation_space()
	
	print("MoldSporeVRDemo Camera: Use WASD to move, mouse to look around")
	print("MoldSporeVRDemo Camera: Right-click to capture/release mouse")
	print("MoldSporeVRDemo Camera: Mouse wheel to zoom, F to focus on center")

func _input(event):
	# Handle mouse capture toggle
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			toggle_mouse_capture()
	
	# Handle mouse movement
	if event is InputEventMouseMotion and is_mouse_captured:
		handle_mouse_look(event.relative)
	
	# Handle zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()
	
	# Handle keyboard shortcuts
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F:
				focus_on_generation_space()
			KEY_ESCAPE:
				release_mouse()

func _process(delta):
	handle_movement(delta)

func handle_movement(delta):
	"""Handle WASD movement"""
	var input_dir = Vector3()
	
	# Get movement input
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_dir -= transform.basis.x
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_dir += transform.basis.x
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_dir -= transform.basis.z
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_dir += transform.basis.z
	
	# Vertical movement
	if Input.is_key_pressed(KEY_SPACE):
		input_dir += Vector3.UP
	if Input.is_key_pressed(KEY_SHIFT):
		input_dir -= Vector3.UP
	
	# Apply movement
	if input_dir != Vector3.ZERO:
		input_dir = input_dir.normalized()
		var speed = sprint_speed if Input.is_key_pressed(KEY_CTRL) else movement_speed
		global_position += input_dir * speed * delta

func handle_mouse_look(mouse_delta):
	"""Handle mouse look rotation"""
	camera_rotation.x -= mouse_delta.y * mouse_sensitivity
	camera_rotation.y -= mouse_delta.x * mouse_sensitivity
	
	# Clamp vertical rotation
	camera_rotation.x = clamp(camera_rotation.x, -PI/2 + 0.1, PI/2 - 0.1)
	
	# Apply rotation
	transform.basis = Basis()
	rotate_object_local(Vector3.UP, camera_rotation.y)
	rotate_object_local(Vector3.RIGHT, camera_rotation.x)

func toggle_mouse_capture():
	"""Toggle mouse capture for look controls"""
	if is_mouse_captured:
		release_mouse()
	else:
		capture_mouse()

func capture_mouse():
	"""Capture mouse for look controls"""
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	is_mouse_captured = true
	print("MoldSporeVRDemo Camera: Mouse captured - move mouse to look around")

func release_mouse():
	"""Release mouse capture"""
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	is_mouse_captured = false
	print("MoldSporeVRDemo Camera: Mouse released")

func zoom_in():
	"""Zoom camera closer to center"""
	zoom_distance = max(min_zoom_distance, zoom_distance - zoom_speed * 0.1)
	update_camera_position()

func zoom_out():
	"""Zoom camera further from center"""
	zoom_distance = min(max_zoom_distance, zoom_distance + zoom_speed * 0.1)
	update_camera_position()

func update_camera_position():
	"""Update camera position based on zoom distance"""
	var direction = (global_position - orbit_center).normalized()
	global_position = orbit_center + direction * zoom_distance

func look_at_generation_space():
	"""Position camera to look at the 1x1x1 generation space"""
	global_position = Vector3(2, 1.5, 2)
	look_at(orbit_center, Vector3.UP)
	
	# Initialize rotation values based on current orientation
	var euler = transform.basis.get_euler()
	camera_rotation.x = euler.x
	camera_rotation.y = euler.y

func focus_on_generation_space():
	"""Focus camera on the generation space center"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Smooth movement to good viewing position
	var target_position = orbit_center + Vector3(1.5, 1, 1.5)
	tween.tween_property(self, "global_position", target_position, 1.0)
	
	# Smooth rotation to look at center
	tween.tween_method(smooth_look_at, transform.basis, 
		Basis.looking_at(orbit_center - target_position, Vector3.UP), 1.0)
	
	print("MoldSporeVRDemo Camera: Focusing on generation space")

func smooth_look_at(basis: Basis):
	"""Smooth basis interpolation for camera rotation"""
	transform.basis = basis

func get_camera_info() -> Dictionary:
	"""Get current camera information"""
	return {
		"position": global_position,
		"rotation": camera_rotation,
		"zoom_distance": zoom_distance,
		"looking_at": orbit_center,
		"mouse_captured": is_mouse_captured
	} 