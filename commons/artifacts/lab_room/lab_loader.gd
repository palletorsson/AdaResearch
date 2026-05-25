extends Node
class_name LabLoader

## Reads a lab.json file produced by the encyclopedia's /lab-editor
## page and arranges its props inside a host lab_room artifact.
##
## Usage from map_data.json:
##   "interactables": [
##     [" ", "lab_room#mounted_lab_json:res://commons/labs/turing_v2.lab.json#room_width:8.0#..."]
##   ]
## lab_room.gd watches for `config_mounted_lab_json` metadata and calls
## LabLoader.load_into(self, json_path) instead of (or in addition to)
## `mounted_artifact_scene`.
##
## Schema (matching the LabEditor.tsx LabJson type):
##   {
##     "name": "<lab_name>",
##     "description": "...",
##     "lab_room": {
##       "room_width": 8.0, "room_depth": 7.0, "room_height": 3.8,
##       "accent_color": [0.227, 0.482, 1.0],
##       "signage_top": "...", "signage_sub": "...",
##       "show_back_window": true, "back_window_size": [6.5, 2.4],
##       "show_front_window": true, "front_window_size": [1.4, 0.7],
##       "show_sliding_door": true, "door_wall": "east",
##       "show_floor_window": false, "floor_window_size": [3.0, 3.0]
##     },
##     "mounted_props": [
##       { "lookup_name": "conveyor_belt",
##         "position": [x, y, z],
##         "rotation_y": 0,
##         "config": { "belt_length": 4.0, ... } }
##     ]
##   }
##
## Coordinate convention: Three.js (web editor) and Godot are both
## metres, Y-up. The lab_room's origin is the floor centre. Prop
## positions are expressed in that local frame.

const REGISTRY_DIR := "res://commons/artifacts/registry/"


## Load a lab.json file and instantiate its props as children of
## `host_mount`. Returns the array of instantiated nodes, or [] on error.
static func load_into(host_mount: Node3D, json_path: String) -> Array:
	var nodes: Array = []
	if host_mount == null:
		push_warning("LabLoader: no host_mount given")
		return nodes
	if not FileAccess.file_exists(json_path):
		push_warning("LabLoader: lab json not found: %s" % json_path)
		return nodes

	var raw: String = FileAccess.get_file_as_string(json_path)
	if raw.is_empty():
		push_warning("LabLoader: empty lab json: %s" % json_path)
		return nodes

	var parsed = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		push_warning("LabLoader: lab json parse failed: %s" % json_path)
		return nodes

	var props: Array = parsed.get("mounted_props", [])
	if not (props is Array):
		return nodes

	var artifact_index: Dictionary = _index_artifact_scenes()

	for raw_p in props:
		if not (raw_p is Dictionary):
			continue
		var p: Dictionary = raw_p
		var lookup: String = String(p.get("lookup_name", "")).strip_edges()
		if lookup.is_empty():
			continue

		var scene_path: String = String(artifact_index.get(lookup, ""))
		if scene_path.is_empty():
			push_warning("LabLoader: no scene found for lookup_name '%s' — skipping" % lookup)
			continue

		var packed: PackedScene = load(scene_path)
		if packed == null:
			push_warning("LabLoader: failed to load scene '%s'" % scene_path)
			continue

		var instance: Node = packed.instantiate()
		if instance == null:
			continue

		if instance is Node3D:
			var pos_arr: Array = p.get("position", [0.0, 0.0, 0.0])
			if pos_arr.size() == 3:
				instance.position = Vector3(
					float(pos_arr[0]),
					float(pos_arr[1]),
					float(pos_arr[2])
				)
			var rot_y: float = float(p.get("rotation_y", 0.0))
			instance.rotation.y = deg_to_rad(rot_y)

		# Forward per-prop config to the artifact's apply_grid_config if it has one.
		var cfg: Dictionary = p.get("config", {}) if (p.get("config") is Dictionary) else {}
		if not cfg.is_empty():
			for k in cfg.keys():
				instance.set_meta("config_%s" % str(k), cfg[k])
			if instance.has_method("apply_grid_config"):
				instance.call_deferred("apply_grid_config", cfg.duplicate(true))

		host_mount.add_child(instance)
		nodes.append(instance)

	print("LabLoader: instantiated %d props from %s" % [nodes.size(), json_path])
	return nodes


## Walk the registry directory and build a lookup_name → scene_path map.
## Mirrors what GridInteractablesComponent does but standalone so this
## loader doesn't depend on a live grid.
static func _index_artifact_scenes() -> Dictionary:
	var out: Dictionary = {}
	var dir := DirAccess.open(REGISTRY_DIR)
	if not dir:
		push_warning("LabLoader: cannot open registry dir %s" % REGISTRY_DIR)
		return out
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json") and not file_name.ends_with(".bak"):
			_merge_registry_file(REGISTRY_DIR + file_name, out)
		file_name = dir.get_next()
	return out


static func _merge_registry_file(path: String, out: Dictionary) -> void:
	var raw: String = FileAccess.get_file_as_string(path)
	if raw.is_empty():
		return
	var parsed = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return
	var artifacts: Dictionary = parsed.get("artifacts", {})
	if not (artifacts is Dictionary):
		return
	for lookup in artifacts.keys():
		var entry = artifacts[lookup]
		if not (entry is Dictionary):
			continue
		var scene_path: String = String(entry.get("scene", ""))
		if scene_path.is_empty():
			# Try `scene_path` or `path`
			scene_path = String(entry.get("scene_path", entry.get("path", "")))
		if scene_path.is_empty():
			# Fall back to the conventional location
			scene_path = "res://commons/artifacts/%s/%s.tscn" % [String(lookup), String(lookup)]
			if not ResourceLoader.exists(scene_path):
				continue
		out[String(lookup)] = scene_path
