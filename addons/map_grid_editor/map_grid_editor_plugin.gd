@tool
extends EditorPlugin

var dock: Control

func _enter_tree() -> void:
	dock = preload("res://addons/map_grid_editor/map_grid_editor_dock.tscn").instantiate()
	add_control_to_bottom_panel(dock, "Map Grid")

func _exit_tree() -> void:
	if dock:
		remove_control_from_bottom_panel(dock)
		dock.queue_free()
