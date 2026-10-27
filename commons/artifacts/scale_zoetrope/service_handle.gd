extends StaticBody3D
var exhibit: Node3D
func pointer_event(event: XRToolsPointerEvent) -> void:
	if event.event_type == XRToolsPointerEvent.Type.PRESSED and is_instance_valid(exhibit):
		exhibit.toggle_service()
