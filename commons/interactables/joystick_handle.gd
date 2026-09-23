extends XRToolsInteractableHandle
func pointer_event(event: XRToolsPointerEvent) -> void:
	get_node("../../../..").pointer_event(event)
