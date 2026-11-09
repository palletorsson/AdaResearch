extends "res://addons/godot-xr-tools/objects/pickable.gd"
## The carousel ring's handle: an invisible held proxy (like movable_pivot's grips). The visible yoke stays on the
## ball's carriage; XRTools (XR hand, or the Void's desktop right-click carry) moves this body, and the ring reads its
## position as the hand's. A desktop left-click drag arrives as pointer events and is projected onto the grip's plane.
var ring: Node3D
var pointer_owner: Node3D

func pointer_event(event: XRToolsPointerEvent) -> void:
	if not event or is_picked_up() or not is_instance_valid(ring): return
	match event.event_type:
		XRToolsPointerEvent.Type.PRESSED:
			if is_instance_valid(pointer_owner): return
			pointer_owner = event.pointer
			ring.hold_begin(event.pointer)
			ring.hold_to(projected_point(event))
		XRToolsPointerEvent.Type.MOVED:
			if event.pointer == pointer_owner:
				ring.hold_to(projected_point(event))
		XRToolsPointerEvent.Type.RELEASED, XRToolsPointerEvent.Type.EXITED:
			if event.pointer == pointer_owner:
				pointer_owner = null
				ring.hold_end(event.pointer)

## Where the crosshair ray meets the horizontal plane at grip height: a long drag stays meaningful after the ray has
## left the small collider, and only the angle of the point is used, so the ball cannot leave the ring.
func projected_point(event: XRToolsPointerEvent) -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		var ray := -camera.global_basis.z
		var normal := ring.global_basis.y.normalized()
		var denominator := normal.dot(ray)
		if absf(denominator) > .01:
			var distance := normal.dot(global_position - camera.global_position) / denominator
			if distance > 0: return camera.global_position + ray * distance
	return event.position

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(pointer_owner):
		pointer_owner = null
		if is_instance_valid(ring): ring.hold_end()
