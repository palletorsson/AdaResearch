extends StaticBody3D
## Shared desktop/XR pointer target. Invisible collision, visible owner highlight.
var action: Callable
func _init() -> void:
	collision_layer = 1048576; collision_mask = 0
func pointer_event(event: XRToolsPointerEvent) -> void:
	if event.event_type == XRToolsPointerEvent.Type.PRESSED and action.is_valid(): action.call()
