extends CharacterBody3D
## Small collision-based desktop walker for the comparison scene only.

var home := Vector3.ZERO
var eyes: Camera3D

func _ready() -> void:
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.75
	collider.shape = capsule
	collider.position.y = 0.88
	add_child(collider)
	eyes = Camera3D.new()
	eyes.name = "Eyes"
	eyes.position.y = 1.65
	eyes.fov = 78
	eyes.near = 0.05
	add_child(eyes)
	eyes.make_current()
	floor_snap_length = 0.25

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.003)
		eyes.rotation.x = clampf(eyes.rotation.x - event.relative.y * 0.003, -1.4, 1.4)

func _physics_process(delta: float) -> void:
	var axis := Vector2.ZERO
	axis.x = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	axis.y = float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	var direction := global_basis * Vector3(axis.x, 0, axis.y).limit_length(1.0)
	var speed := 4.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 2.3
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	move_and_slide()
	if global_position.y < -5:
		global_position = home
		velocity = Vector3.ZERO

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
