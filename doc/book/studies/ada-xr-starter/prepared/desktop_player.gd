extends CharacterBody3D
## Prepared viewing and movement infrastructure. Lesson scripts don't depend on it.

signal reset_requested

const DesktopGrab = preload("res://prepared/desktop_grab.gd")
var camera := Camera3D.new()
var grabber := DesktopGrab.new()

func _ready() -> void:
	collision_layer = 524288
	collision_mask = 1
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.24
	capsule.height = 1.7
	var collision := CollisionShape3D.new()
	collision.shape = capsule
	collision.position.y = 0.85
	add_child(collision)
	camera.position.y = 1.65
	camera.current = true
	camera.fov = 65
	add_child(camera)
	grabber.position = Vector3(0.25, -0.2, -0.9)
	camera.add_child(grabber)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			interact()
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.002)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * 0.002, -1.4, 1.4)
	if event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("interact"):
		interact()
	if event.is_action_pressed("reset_object"):
		reset_requested.emit()

func _physics_process(delta: float) -> void:
	var direction := Vector3.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		direction = basis * Vector3(input.x, 0, input.y)
	velocity.x = direction.x * 2.5
	velocity.z = direction.z * 2.5
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	move_and_slide()

func interact() -> void:
	if is_instance_valid(grabber.picked_up_object):
		grabber.drop_object()
		return
	var start := camera.global_position
	# Include architecture in the ray so we cannot pick up through a wall.
	var query := PhysicsRayQueryParameters3D.create(start, start - camera.global_basis.z * 2.5, 5)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider is XRToolsPickable:
		grabber.take(hit.collider)
