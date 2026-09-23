extends XRToolsInteractableHandle
## The wheel nests its grip one level deeper than the lever.
@export var control_path: NodePath = NodePath("../../../..")
func pointer_event(event: XRToolsPointerEvent) -> void:
	get_node(control_path).pointer_event(event)
