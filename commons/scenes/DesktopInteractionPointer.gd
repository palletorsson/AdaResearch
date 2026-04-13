extends Node3D

## Desktop mouse pointer for VR interactables.
## Raycasts from camera center, delivers XRToolsPointerEvent to targets.
## Supports click (buttons) and click-drag (sliders, knobs).

signal pointing_event(event)

@export var distance: float = 5.0
@export var collision_mask_value: int = 1310720  # layers 19 (handles) + 21 (area buttons)

var _raycast: RayCast3D
var _camera: Camera3D

# Pointer state
var _last_target: Node3D = null
var _last_position: Vector3 = Vector3.ZERO
var _locked_target: Node3D = null
var _is_pressed: bool = false


func _ready() -> void:
	# Create raycast child
	_raycast = RayCast3D.new()
	_raycast.name = "PointerRay"
	_raycast.target_position = Vector3(0, 0, -distance)
	_raycast.collision_mask = collision_mask_value
	_raycast.collide_with_bodies = true
	_raycast.collide_with_areas = true
	add_child(_raycast)

	# Find camera (sibling under Head)
	_camera = get_parent().get_node_or_null("Camera3D") as Camera3D


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or not _raycast:
		return

	var raw_collider: Node3D = null
	var hit_position := Vector3.ZERO

	if _raycast.is_colliding():
		raw_collider = _raycast.get_collider() as Node3D
		hit_position = _raycast.get_collision_point()

	# Resolve to nearest ancestor with pointer_event()
	var new_target := _resolve_pointer_target(raw_collider)
	var new_at := hit_position

	# If pressed and locked, keep the locked target
	if _is_pressed and _locked_target:
		new_target = _locked_target
		if not _raycast.is_colliding() or _resolve_pointer_target(raw_collider) != _locked_target:
			# Ray missed or hit something else — project mouse onto target plane
			new_at = _project_to_target_plane()

	# Emit hover events (enter / exit / move)
	_emit_hover_events(new_target, new_at)

	_last_target = new_target
	_last_position = new_at


func _input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

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
		# Entered new target
		XRToolsPointerEvent.entered(self, new_target, new_at)
		XRToolsPointerEvent.moved(self, new_target, new_at, new_at)
	elif not new_target and _last_target:
		# Exited last target
		XRToolsPointerEvent.exited(self, _last_target, _last_position)
	elif new_target != _last_target:
		# Switched targets
		if _last_target:
			XRToolsPointerEvent.exited(self, _last_target, _last_position)
		if new_target:
			XRToolsPointerEvent.entered(self, new_target, new_at)
			XRToolsPointerEvent.moved(self, new_target, new_at, new_at)
	elif new_target and new_at != _last_position:
		# Moved on same target
		XRToolsPointerEvent.moved(self, new_target, new_at, _last_position)


func _resolve_pointer_target(collider: Node) -> Node3D:
	if not collider:
		return null
	var current := collider
	# Walk up the tree to find the node that handles pointer events
	while current:
		if current.has_method("pointer_event"):
			return current as Node3D
		if current.has_signal("pointer_event"):
			return current as Node3D
		current = current.get_parent()
	return null


func _project_to_target_plane() -> Vector3:
	if not _locked_target or not _camera:
		return _last_position
	var target_pos := _locked_target.global_position
	var cam_pos := _camera.global_position
	var plane_normal := (cam_pos - target_pos).normalized()
	var plane := Plane(plane_normal, target_pos)
	# Project from camera center (crosshair)
	var viewport_center := get_viewport().get_visible_rect().size * 0.5
	var ray_origin := _camera.project_ray_origin(viewport_center)
	var ray_dir := _camera.project_ray_normal(viewport_center)
	var hit = plane.intersects_ray(ray_origin, ray_dir)
	if hit:
		return hit
	return _last_position


## True when user is click-dragging on a control
func is_dragging() -> bool:
	return _is_pressed and _locked_target != null


## True when pointer hovers over a pointable control
func has_hover_target() -> bool:
	return _last_target != null
