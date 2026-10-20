@tool
extends EditorPlugin
var dock: Control
func _enter_tree() -> void:
	dock=preload("dock.gd").new()
	add_control_to_bottom_panel(dock,"Void Floors")
func _exit_tree() -> void:
	remove_control_from_bottom_panel(dock)
	dock.queue_free()
