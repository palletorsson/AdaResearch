extends Camera3D

## Static front camera for desktop rack testing.
## No movement — mouse controls a pointer that interacts with VR controls.

signal pointing_event(event)

@export var distance: float = 5.0
@export var collision_mask_value: int = 1310720  # layers 18 (handles) + 20 (area buttons)

var _raycast: RayCast3D

# Pointer state
var _last_target: Node3D = null
var _last_position: Vector3 = Vector3.ZERO
var _locked_target: Node3D = null
var _is_pressed: bool = false

# Crosshair
var _crosshair: ColorRect


func _ready() -> void:
	# Build raycast — projects from mouse position via camera
	_raycast = RayCast3D.new()
	_raycast.name = "PointerRay"
	_raycast.target_position = Vector3(0, 0, -distance)
	_raycast.collision_mask = collision_mask_value
	_raycast.collide_with_bodies = true
	_raycast.collide_with_areas = true
	add_child(_raycast)

	# Crosshair dot
	_crosshair = ColorRect.new()
	_crosshair.name = "Crosshair"
	_crosshair.color = Color(1, 1, 1, 0.6)
	_crosshair.size = Vector2(6, 6)
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_crosshair)

	if GameManager:
		GameManager.register_player(self)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# Aim the raycast toward the mouse position in world space
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := project_ray_origin(mouse_pos)
	var ray_dir := project_ray_normal(mouse_pos)

	_raycast.global_position = ray_origin
	_raycast.global_transform = _raycast.global_transform.looking_at(ray_origin + ray_dir, Vector3.UP)
	_raycast.target_position = Vector3(0, 0, -distance)
	_raycast.force_raycast_update()

	# Move crosshair to mouse
	_crosshair.position = mouse_pos - _crosshair.size * 0.5

	var raw_collider: Node3D = null
	var hit_position := Vector3.ZERO

	if _raycast.is_colliding():
		raw_collider = _raycast.get_collider() as Node3D
		hit_position = _raycast.get_collision_point()

	var new_target := _resolve_pointer_target(raw_collider)
	var new_at := hit_position

	# Lock to target during drag
	if _is_pressed and _locked_target:
		new_target = _locked_target
		if not _raycast.is_colliding() or _resolve_pointer_target(raw_collider) != _locked_target:
			new_at = _project_to_target_plane(mouse_pos)

	_emit_hover_events(new_target, new_at)

	# Crosshair color
	if _is_pressed and _locked_target:
		_crosshair.color = Color(1.0, 0.6, 0.1, 0.9)  # Orange dragging
	elif new_target:
		_crosshair.color = Color(1.0, 1.0, 0.2, 0.9)  # Yellow hover
	else:
		_crosshair.color = Color(1, 1, 1, 0.6)

	_last_target = new_target
	_last_position = new_at


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _last_target:
				_locked_target = _last_target
				_is_pressed = true
				XRToolsPointerEvent.pressed(self, _locked_target, _last_position)
				get_viewport().set_input_as_handled()
		else:
			if _locked_target:
				XRToolsPointerEvent.released(self, _locked_target, _last_position)
				_locked_target = null
			_is_pressed = false


func _emit_hover_events(new_target: Node3D, new_at: Vector3) -> void:
	if new_target and not _last_target:
		XRToolsPointerEvent.entered(self, new_target, new_at)
		XRToolsPointerEvent.moved(self, new_target, new_at, new_at)
	elif not new_target and _last_target:
		XRToolsPointerEvent.exited(self, _last_target, _last_position)
	elif new_target != _last_target:
		if _last_target:
			XRToolsPointerEvent.exited(self, _last_target, _last_position)
		if new_target:
			XRToolsPointerEvent.entered(self, new_target, new_at)
			XRToolsPointerEvent.moved(self, new_target, new_at, new_at)
	elif new_target and new_at != _last_position:
		XRToolsPointerEvent.moved(self, new_target, new_at, _last_position)


func _resolve_pointer_target(collider: Node) -> Node3D:
	if not collider:
		return null
	var current := collider
	while current:
		if current.has_method("pointer_event"):
			return current as Node3D
		if current.has_signal("pointer_event"):
			return current as Node3D
		current = current.get_parent()
	return null


func _project_to_target_plane(mouse_pos: Vector2) -> Vector3:
	if not _locked_target:
		return _last_position
	var target_pos := _locked_target.global_position
	var cam_pos := global_position
	var plane_normal := (cam_pos - target_pos).normalized()
	var plane := Plane(plane_normal, target_pos)
	var ray_origin := project_ray_origin(mouse_pos)
	var ray_dir := project_ray_normal(mouse_pos)
	var hit = plane.intersects_ray(ray_origin, ray_dir)
	if hit:
		return hit
	return _last_position
