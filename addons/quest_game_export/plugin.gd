@tool
extends EditorPlugin
## Packaging only. Does not modify scenes, layouts, user saves or interactions.
var boundary: EditorExportPlugin
func _enter_tree() -> void:
	boundary = preload("exporter.gd").new()
	add_export_plugin(boundary)
func _exit_tree() -> void:
	if boundary != null: remove_export_plugin(boundary)
