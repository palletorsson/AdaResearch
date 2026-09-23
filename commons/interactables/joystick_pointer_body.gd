extends StaticBody3D
@export var control_path: NodePath = NodePath("..")
func pointer_event(event: XRToolsPointerEvent) -> void:
	get_node(control_path).pointer_event(event)
