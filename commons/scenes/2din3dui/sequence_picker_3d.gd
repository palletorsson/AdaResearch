extends Node3D

## 3D wrapper for the sequence picker. Mounts the 2D Control via
## Viewport2Din3D and re-emits its signals at the 3D level so the
## main menu can connect to a single node.

signal sequence_play_requested(sequence_name: String)
signal back_requested

@onready var _viewport_2d_in_3d: Node = $Screen/Viewport2Din3D


func _ready() -> void:
	# Wait for the viewport's scene_node to be available, then connect.
	await get_tree().process_frame
	var content: Node = _viewport_2d_in_3d.get_scene_instance() if _viewport_2d_in_3d.has_method("get_scene_instance") else null
	if content == null:
		# Fallback: search the viewport's children for our Control
		content = _find_content_in(_viewport_2d_in_3d)
	if content == null:
		push_warning("SequencePicker3D: could not find 2D content")
		return
	if content.has_signal("sequence_play_requested"):
		content.sequence_play_requested.connect(_on_play_requested)
	if content.has_signal("back_requested"):
		content.back_requested.connect(_on_back_requested)


func _find_content_in(node: Node) -> Node:
	# Depth-first search for any node with a sequence_play_requested signal.
	for child in node.get_children():
		if child.has_signal("sequence_play_requested"):
			return child
		var found: Node = _find_content_in(child)
		if found != null:
			return found
	return null


func _on_play_requested(sequence_name: String) -> void:
	sequence_play_requested.emit(sequence_name)


func _on_back_requested() -> void:
	back_requested.emit()
