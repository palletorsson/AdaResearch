extends "res://addons/godot-xr-tools/objects/pickable.gd"
## A retained physical grip. The visible cap stays on its constrained carriage;
## XRTools owns the invisible held proxy. Desktop uses the same parameter path.
var mechanism: Node3D
var role := "pivot"
var pointer_owner: Node3D
var start_point := Vector3.ZERO
var start_value := 0.0
var xr_start := Vector3.ZERO
var xr_value := 0.0

func pick_up(by) -> void:
	if is_instance_valid(pointer_owner): return
	xr_start = mechanism.to_local(global_position)
	xr_value = mechanism.target_pivot if role == "pivot" else mechanism.target_angle
	super(by)

func pointer_event(event: XRToolsPointerEvent) -> void:
	if not event or is_picked_up(): return
	match event.event_type:
		XRToolsPointerEvent.Type.PRESSED:
			if is_instance_valid(pointer_owner): return
			pointer_owner = event.pointer
			start_point = projected_point(event)
			start_value = mechanism.target_pivot if role == "pivot" else mechanism.target_angle
		XRToolsPointerEvent.Type.MOVED:
			if event.pointer == pointer_owner:
				move_from(start_point, projected_point(event), start_value)
		XRToolsPointerEvent.Type.RELEASED, XRToolsPointerEvent.Type.EXITED:
			if event.pointer == pointer_owner: pointer_owner = null

func projected_point(event: XRToolsPointerEvent) -> Vector3:
	# Intersect the pointing ray with the horizontal grip plane. This keeps a
	# long desktop drag meaningful even when its ray leaves the small collider.
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		var ray := -camera.global_basis.z
		var normal := mechanism.global_basis.y.normalized()
		var denominator := normal.dot(ray)
		if absf(denominator) > .01:
			var distance := normal.dot(mechanism.to_global(Vector3(0, 1.02, 0)) - camera.global_position) / denominator
			if distance > 0: return mechanism.to_local(camera.global_position + ray * distance)
	return mechanism.to_local(event.position)

func move_from(from: Vector3, to: Vector3, value: float) -> void:
	if role == "pivot":
		mechanism.target_pivot = clampf(value + to.x - from.x, -1.5, 1.5)
	else:
		var centre := Vector3(mechanism.pivot_x, 0, 0)
		var a := from - centre; a.y = 0
		var b := to - centre; b.y = 0
		if a.length() > .2 and b.length() > .2:
			mechanism.target_angle = clampf(value + rad_to_deg(a.signed_angle_to(b, Vector3.UP)), -22, 22)

func update_held() -> void:
	if is_picked_up(): move_from(xr_start, mechanism.to_local(global_position), xr_value)

func rest_at(at: Vector3) -> void:
	if is_picked_up(): return
	position = at
	PhysicsServer3D.body_set_state(get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, global_transform)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: pointer_owner = null
