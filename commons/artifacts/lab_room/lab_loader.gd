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

	# NOTE: lab_room block is applied directly by lab_room.gd in
	# _apply_lab_room_block_from_json() during _read_metadata_overrides
	# (before _build_room runs), so we don't touch it here. lab_loader
	# only handles mounted_props.

	var props: Array = parsed.get("mounted_props", [])
	if not (props is Array):
		return nodes

	var artifact_index: Dictionary = _index_artifact_scenes()

	# Room dimensions (from the lab_room block) — stamped onto each prop so the
	# in-VR catalyst Lab mode can net-classify (which face) and snap without
	# having to inspect the lab_room node.
	var lr: Dictionary = parsed.get("lab_room", {}) if (parsed.get("lab_room") is Dictionary) else {}
	var room_W: float = float(lr.get("room_width", 8.0))
	var room_D: float = float(lr.get("room_depth", 7.0))
	var room_H: float = float(lr.get("room_height", 4.5))

	for raw_p in props:
		if not (raw_p is Dictionary):
			continue
		var p: Dictionary = raw_p
		# Accept both snake_case (lookup_name) and camelCase (lookupName) —
		# the encyclopedia's /lab-editor saves camelCase; older labs and the
		# script's docstring use snake_case.
		var lookup: String = str(p.get("lookup_name", p.get("lookupName", ""))).strip_edges()
		if lookup.is_empty():
			continue

		var scene_path: String = str(artifact_index.get(lookup, ""))
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
			# Accept both rotation_y (snake) and rotationY (camel).
			var rot_y: float = float(p.get("rotation_y", p.get("rotationY", 0.0)))
			instance.rotation.y = deg_to_rad(rot_y)

		# Forward per-prop config to the artifact's apply_grid_config if it has one.
		var cfg: Dictionary = p.get("config", {}) if (p.get("config") is Dictionary) else {}
		if not cfg.is_empty():
			for k in cfg.keys():
				instance.set_meta("config_%s" % str(k), cfg[k])
			if instance.has_method("apply_grid_config"):
				instance.call_deferred("apply_grid_config", cfg.duplicate(true))

		host_mount.add_child(instance)

		# Tag for in-VR net editing (catalyst Lab mode): a targetable group plus
		# the data needed to net-snap and save back to this lab JSON by id.
		if instance is Node3D:
			instance.add_to_group("vr_lab_prop")
			var pid: String = str(p.get("id", "")).strip_edges()
			if pid.is_empty():
				pid = "%s_%d" % [lookup, nodes.size()]
			instance.set_meta("lab_prop_id", pid)
			instance.set_meta("lab_lookup", lookup)
			instance.set_meta("lab_json_path", json_path)
			instance.set_meta("lab_room_dims", Vector3(room_W, room_D, room_H))  # (W, D, H)

		nodes.append(instance)

		# Auto-collider: if the prop doesn't already include any
		# StaticBody3D / CollisionShape3D / RigidBody3D in its subtree
		# (most procedural artifacts don't), wrap its visual AABB with
		# a single BoxShape so the VR player can bump into it. Skipped
		# for the `origin` prop and anything tagged config.no_collider
		# = true (e.g. holograms, lights, decorative floor disks).
		var skip_collider: bool = str(p.get("lookup_name",
			p.get("lookupName", ""))) == "origin"
		if cfg.has("no_collider"):
			var v: String = str(cfg["no_collider"]).to_lower()
			if v == "true" or v == "1" or v == "yes":
				skip_collider = true
		if not skip_collider and instance is Node3D:
			_attach_auto_collider(instance)

	print("LabLoader: instantiated %d props from %s" % [nodes.size(), json_path])
	return nodes


## Walk every MeshInstance3D under `root`, union their AABBs, and
## attach a StaticBody3D + BoxShape3D matching the bounds. Skips if any
## physics body already exists in the subtree.
static func _attach_auto_collider(root: Node3D) -> void:
	# Bail if collision is already present (artifact author handled it).
	var has_body := false
	for child in root.get_children():
		if child is StaticBody3D or child is RigidBody3D \
				or child is CharacterBody3D or child is Area3D:
			has_body = true
			break
		# Also check one level deep for nested bodies (common pattern).
		for grandchild in child.get_children():
			if grandchild is StaticBody3D or grandchild is RigidBody3D \
					or grandchild is CharacterBody3D:
				has_body = true
				break
		if has_body:
			break
	if has_body:
		return

	# Union all MeshInstance3D AABBs in the subtree (local to root).
	var combined := AABB()
	var any := false
	var stack: Array = [root]
	while not stack.is_empty():
		var node = stack.pop_back()
		if node is MeshInstance3D and node.mesh != null:
			var aabb: AABB = node.get_aabb()
			# Transform from node-local to root-local space.
			var t: Transform3D = node.transform
			var p2: Node = node.get_parent()
			while p2 != null and p2 != root:
				if p2 is Node3D:
					t = p2.transform * t
				p2 = p2.get_parent()
			# Apply transform corners.
			for i in range(8):
				var c := Vector3(
					aabb.position.x + (aabb.size.x if (i & 1) else 0.0),
					aabb.position.y + (aabb.size.y if (i & 2) else 0.0),
					aabb.position.z + (aabb.size.z if (i & 4) else 0.0))
				var wc: Vector3 = t * c
				if not any:
					combined = AABB(wc, Vector3.ZERO)
					any = true
				else:
					combined = combined.expand(wc)
		for ch in node.get_children():
			stack.append(ch)

	if not any or combined.size.length() < 0.01:
		return

	var body := StaticBody3D.new()
	body.name = "AutoCollider"
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	# Clamp tiny dimensions so the BoxShape3D is valid.
	box.size = Vector3(
		max(combined.size.x, 0.05),
		max(combined.size.y, 0.05),
		max(combined.size.z, 0.05))
	cs.shape = box
	cs.position = combined.position + combined.size * 0.5
	body.add_child(cs)
	root.add_child(body)


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
		var scene_path: String = str(entry.get("scene", ""))
		if scene_path.is_empty():
			# Try `scene_path` or `path`
			scene_path = str(entry.get("scene_path", entry.get("path", "")))
		if scene_path.is_empty():
			# Fall back to the conventional location
			scene_path = "res://commons/artifacts/%s/%s.tscn" % [str(lookup), str(lookup)]
			if not ResourceLoader.exists(scene_path):
				continue
		out[str(lookup)] = scene_path
