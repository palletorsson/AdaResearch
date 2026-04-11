# VoxelSaveManager.gd — Serialize grid state → JSON → map_data.json
#
# Takes the current editable layout from GridStructureComponent and writes
# it back to the map_data.json file, preserving all non-structure data
# (map_info, utilities, interactables, settings, etc.)

class_name VoxelSaveManager
extends RefCounted


## Save the current grid state to map_data.json.
## Preserves everything except the structure layer.
static func save(map_name: String, structure_component: GridStructureComponent) -> bool:
	var layout: Array = structure_component.get_editable_layout()
	if layout.is_empty():
		push_warning("[VoxelSaveManager] No editable layout to save")
		return false

	var map_path: String = "res://commons/maps/%s/map_data.json" % map_name
	var abs_path: String = ProjectSettings.globalize_path(map_path)

	# Read existing file to preserve non-structure data
	if not FileAccess.file_exists(abs_path):
		push_error("[VoxelSaveManager] Map file not found: %s" % abs_path)
		return false

	var file := FileAccess.open(abs_path, FileAccess.READ)
	if not file:
		push_error("[VoxelSaveManager] Cannot read: %s" % abs_path)
		return false

	var json_str: String = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_str)
	if not parsed is Dictionary:
		push_error("[VoxelSaveManager] Invalid JSON in: %s" % abs_path)
		return false

	var data: Dictionary = parsed as Dictionary

	# Update only the structure layer
	if not data.has("layers"):
		data["layers"] = {}
	data["layers"]["structure"] = layout

	# Write back with pretty formatting
	var output: String = JSON.stringify(data, "  ")
	var out_file := FileAccess.open(abs_path, FileAccess.WRITE)
	if not out_file:
		push_error("[VoxelSaveManager] Cannot write: %s" % abs_path)
		return false

	out_file.store_string(output + "\n")
	out_file.close()

	print("[VoxelSaveManager] Saved %s (%d rows)" % [map_name, layout.size()])
	return true
