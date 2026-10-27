extends CharacterBody3D
## Desktop companion for the same descent. The VR mode uses XRToolsPlayerBody.
const Rules := preload("player_rules.gd")
const Hand := preload("desktop_hand.gd")
const FlightBox := preload("res://commons/movement/museum_flight_box.gd")
const SPEED := Rules.SPEED
const JUMP := Rules.JUMP
var camera: Camera3D
var desktop_pointer: Node3D
var enabled := true
var jump_queued := false
var drive := Vector2.ZERO # Also used by the deterministic physics probe.
var scripted_input := false
var flight_vertical := 0.0 # Deterministic counterpart of Space / Ctrl.
var was_flying := false

func _ready() -> void:
	collision_layer = 524288
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.2
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.85
	add_child(shape)
	camera = Camera3D.new()
	camera.position.y = 1.6
	camera.near = 0.05
	add_child(camera)
	camera.make_current()
	desktop_pointer = Hand.new()
	desktop_pointer.name = "DesktopHand"
	desktop_pointer.cam = camera
	desktop_pointer.world = get_parent()
	add_child(desktop_pointer)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not enabled: return
	var axes := drive
	if not scripted_input:
		axes = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	var zone: Node3D = FlightBox.at_point(get_tree(),global_position)
	if zone != null:
		var vertical := flight_vertical if scripted_input else float(Input.is_physical_key_pressed(KEY_SPACE))-float(Input.is_physical_key_pressed(KEY_CTRL))
		velocity = zone.flight_velocity(camera.global_basis,Vector2(axes.x,-axes.y),vertical)
		jump_queued = false
		was_flying = true
		move_and_slide()
		return
	if was_flying:
		velocity = Vector3.ZERO
		was_flying = false
	var slippery := _slippery_support()
	floor_stop_on_slope = not slippery
	var direction := basis * Vector3(axes.x, 0, axes.y).limit_length()
	var horizontal := Vector3(velocity.x, 0, velocity.z)
	if direction.length() >= 0.1:
		horizontal = horizontal.lerp(direction * SPEED, clampf(Rules.TRACTION * delta, 0, 1))
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if is_on_floor():
		if jump_queued: velocity.y = JUMP
		elif not slippery: velocity.y = 0.0
	# XRTools applies the world's gravity on the jump frame too.
	velocity += PhysicsServer3D.body_get_direct_state(get_rid()).total_gravity * delta
	jump_queued = false
	# Same opted-in carry contract as the museum and XR movement provider.
	# Sleeping floors must never drive the active desktop body.
	var carry_zone: Node3D = null
	for medium in get_tree().get_nodes_in_group("ada_museum_carry"):
		if carry_zone == null and medium.can_process() and medium._point_inside(global_position):
			carry_zone = medium
		else:
			medium.release_carry(self)
	if carry_zone != null:
		velocity = carry_zone.carry_velocity(self, delta, velocity)
	move_and_slide()
	if carry_zone != null:
		carry_zone.record_carry(self)
		return
	if direction.length() < 0.1 and not slippery:
		horizontal = Vector3(velocity.x, 0, velocity.z).lerp(Vector3.ZERO, clampf(Rules.DRAG * delta, 0, 1))
		if horizontal.length() < Rules.STOP_SPEED: horizontal = Vector3.ZERO
		velocity.x = horizontal.x
		velocity.z = horizontal.z

func _slippery_support() -> bool:
	if not is_on_floor(): return false
	var query := PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*.12,global_position-Vector3.UP*.20,1)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and bool(hit.collider.get_meta("void_slippery_surface",false))

func _unhandled_input(event: InputEvent) -> void:
	if not enabled: return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.002)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * 0.002, -1.45, 1.45)
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE: jump_queued = true
		if event.keycode == KEY_ESCAPE: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
