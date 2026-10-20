extends "res://addons/godot-xr-tools/objects/pickable.gd"
## VR grab uses XRTools; desktop rays drag the same centre marker.
var pointer_owner: Node3D
var pointer_start := Vector3.ZERO
var handle_start := Vector3.ZERO
func pointer_event(event: XRToolsPointerEvent) -> void:
	match event.event_type:
		XRToolsPointerEvent.Type.PRESSED:
			pointer_owner=event.pointer
			pointer_start=event.position
			handle_start=global_position
		XRToolsPointerEvent.Type.MOVED:
			if is_instance_valid(pointer_owner) and pointer_owner==event.pointer:
				global_position=handle_start+event.position-pointer_start
		XRToolsPointerEvent.Type.RELEASED:
			pointer_owner=null
