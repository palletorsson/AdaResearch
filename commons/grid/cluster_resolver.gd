extends Node3D
class_name ClusterResolver
# Expands a curated CLUSTER (a curated_walls-style pieces[] list) at runtime.
#
# Used by GridInteractablesComponent's additive `cluster:<name>:<rotation>` token branch: the grid
# places this node at the anchor cell with a Y-rotation, and it instantiates the cluster's station
# props + artifacts as its OWN CHILDREN — so this node's transform gives free rotation + translation
# (cluster piece x/y/z are local metres, 1:1 with grid cells). It then re-grounds each content
# artifact onto the base beneath it and hides floating chrome — the same trio WallHangarEditor uses.
#
# Non-invasive by construction: it touches no existing grid token path; it is only ever reached via
# the new `cluster:` prefix, which no current map uses.

const REGISTRY_DIR := "res://commons/artifacts/registry"
const CLUSTERS_DIR := "res://commons/data/curated_walls/clusters"

var _scene_map := {}
var _placed: Array = []

# config: { cluster: "<name>", rotation: <deg> }
func apply_grid_config(config: Dictionary) -> void:
	var cname := str(config.get("cluster", config.get("name", "")))
	if cname == "":
		return
	rotation_degrees.y = float(config.get("rotation", config.get("rot", 0.0)))
	_build_scene_map()
	_load_cluster(cname)
	call_deferred("_settle")


func _build_scene_map() -> void:
	# token -> scene path, scanning every artifact registry (same index the editor builds).
	var dir := DirAccess.open(REGISTRY_DIR)
	if dir == null:
		return
	for f in dir.get_files():
		if not str(f).ends_with(".json"):
			continue
		var d = JSON.parse_string(FileAccess.get_file_as_string("%s/%s" % [REGISTRY_DIR, f]))
		var table = d
		if d is Dictionary and d.has("artifacts") and d["artifacts"] is Dictionary:
			table = d["artifacts"]
		if table is Dictionary:
			for k in table.keys():
				var e = table[k]
				if e is Dictionary and e.has("scene"):
					_scene_map[str(e.get("lookup_name", k))] = str(e["scene"])


func _load_cluster(cname: String) -> void:
	var path := "%s/%s.json" % [CLUSTERS_DIR, cname]
	if not FileAccess.file_exists(path):
		push_warning("ClusterResolver: cluster not found: " + path)
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (data is Dictionary):
		push_warning("ClusterResolver: bad cluster JSON: " + path)
		return
	var pieces: Variant = data.get("pieces", [])
	if not (pieces is Array):
		return
	for item in pieces:
		if not (item is Dictionary):
			continue
		var token := str(item.get("token", ""))
		var spath: String = _scene_map.get(token, "")
		if spath == "" or not ResourceLoader.exists(spath):
			push_warning("ClusterResolver: unknown cluster piece token: " + token)
			continue
		var inst: Node = load(spath).instantiate()
		inst.set_meta("token", token)
		inst.set_meta("wall_piece", bool(item.get("wall", false)))
		add_child(inst)   # CHILD of this node — gets the anchor + rotation transform for free
		if inst is Node3D:
			(inst as Node3D).position = Vector3(item.get("x", 0.0), item.get("y", 0.0), item.get("z", 0.0))
		var cfg: Variant = item.get("config", {})
		if cfg is Dictionary and not (cfg as Dictionary).is_empty() and inst.has_method("apply_grid_config"):
			inst.apply_grid_config(cfg)   # size plinths/micropods/stages to the artifact footprint
		_placed.append(inst)


func _settle() -> void:
	# Let the deferred-built station geometry settle, then re-seat each CONTENT artifact onto the
	# base beneath it at its real measured height + hide its floating chrome (Label3D / UI / camera).
	for _i in range(40):
		await get_tree().process_frame
	for n in _placed:
		if not is_instance_valid(n):
			continue
		_clean_loaded(n)
		if bool(n.get_meta("wall_piece", false)):
			continue
		if str(n.get_meta("token", "")).begins_with("station_"):
			continue   # a staging prop, not the content artifact
		var box := _local_aabb(n)
		if box.size.y <= 0.001:
			continue
		var target := _stack_top(n.position.x, n.position.z, n)
		var shift := target - box.position.y
		if absf(shift) > 0.003 and absf(shift) < 6.0:
			var lp: Vector3 = n.position
			lp.y += shift
			n.position = lp   # local frame: Y-rotation-safe re-grounding


func _stack_top(x: float, z: float, exclude: Node3D) -> float:
	# x/z are in THIS resolver's LOCAL frame (see _settle) so footprint matching is rotation-safe.
	var top := 0.0
	for n in _placed:
		if n == exclude or not is_instance_valid(n):
			continue
		if bool(n.get_meta("wall_piece", false)):
			continue
		var box := _local_aabb(n)
		if box.size.y <= 0.001:
			continue
		var cx := box.position.x + box.size.x * 0.5
		var cz := box.position.z + box.size.z * 0.5
		if absf(x - cx) <= box.size.x * 0.5 + 0.05 and absf(z - cz) <= box.size.z * 0.5 + 0.05:
			top = maxf(top, box.position.y + box.size.y)
	return top


func _world_aabb(n: Node3D) -> AABB:
	var box := AABB()
	var found := false
	var stack: Array = [n]
	while not stack.is_empty():
		var node = stack.pop_back()
		for ch in node.get_children():
			stack.append(ch)
		if node is VisualInstance3D and not (node is GPUParticles3D) and (node as VisualInstance3D).is_visible_in_tree():
			var gb: AABB = (node as VisualInstance3D).global_transform * (node as VisualInstance3D).get_aabb()
			if not found:
				box = gb
				found = true
			else:
				box = box.merge(gb)
	return box if found else AABB()


func _local_aabb(n: Node3D) -> AABB:
	# Like _world_aabb but in THIS resolver's local frame, so a Y-rotated cluster's footprints stay
	# axis-aligned — global AABBs swell at non-orthogonal angles and mis-match neighbouring bases.
	var inv := global_transform.affine_inverse()
	var box := AABB()
	var found := false
	var stack: Array = [n]
	while not stack.is_empty():
		var node = stack.pop_back()
		for ch in node.get_children():
			stack.append(ch)
		if node is VisualInstance3D and not (node is GPUParticles3D) and (node as VisualInstance3D).is_visible_in_tree():
			var lt: Transform3D = inv * (node as VisualInstance3D).global_transform
			var gb: AABB = lt * (node as VisualInstance3D).get_aabb()
			if not found:
				box = gb
				found = true
			else:
				box = box.merge(gb)
	return box if found else AABB()


func _clean_loaded(n: Node) -> void:
	for c in n.get_children():
		if c is Label3D:
			(c as Label3D).visible = false
		elif c is CanvasLayer:
			(c as CanvasLayer).visible = false
		elif c is Camera3D:
			(c as Camera3D).current = false
		_clean_loaded(c)
