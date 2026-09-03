# probe_yaw_span.gd — does the Python span() agree with the engine about yaw?
#
# tools/map_plan.py and tools/stamp.py compute the grid cells a placed body
# covers from three registry numbers and the token's yaw: aabb_size,
# aabb_center, and the rotation. The rotation of the CENTRE OFFSET is the part
# nobody has checked. If the sign is wrong, a body whose centre sits 7 m forward
# is placed 7 m backward, every overrun count in the corpus is wrong, and a
# stamper would carve the wrong cells with total confidence.
#
# So ask Godot. Instantiate the body, rotate it the way the grid does, and
# report the AABB the engine actually produces. The Python side asserts against
# these numbers rather than against its own arithmetic.
#
#   godot --path . --xr-mode off --no-window \
#     --script res://commons/testing/probe_yaw_span.gd -- --token=wall_pattern_gallery

extends SceneTree

const REGISTRY_DIR := "res://commons/artifacts/registry/"
const SETTLE := 1.2

var _token: String = "wall_pattern_gallery"
var _out: String = "res://ada_run/probe_yaw_span.json"


func _initialize() -> void:
	for raw in OS.get_cmdline_user_args():
		var a: String = String(raw).strip_edges()
		if a.begins_with("--token="):
			_token = a.substr(8)
		elif a.begins_with("--out="):
			_out = a.substr(6)
	call_deferred("_run")


func _find_scene(token: String) -> Dictionary:
	var dir := DirAccess.open(REGISTRY_DIR)
	if dir == null:
		return {}
	dir.list_dir_begin()
	var f: String = dir.get_next()
	while f != "":
		if f.ends_with(".json"):
			var txt := FileAccess.get_file_as_string(REGISTRY_DIR + f)
			var parsed: Variant = JSON.parse_string(txt)
			if parsed is Dictionary:
				var ents: Dictionary = parsed
				if ents.has("artifacts") and ents["artifacts"] is Dictionary:
					ents = ents["artifacts"]
				if ents.has(token):
					var e: Dictionary = ents[token]
					var scene: String = str(e.get("scene", ""))
					var cfg: Dictionary = {}
					var deleg: String = str(e.get("delegate_to", ""))
					if scene.is_empty() and not deleg.is_empty() and ents.has(deleg):
						scene = str((ents[deleg] as Dictionary).get("scene", ""))
						cfg = e.get("delegate_params", {})
					dir.list_dir_end()
					return {"scene": scene, "cfg": cfg}
		f = dir.get_next()
	dir.list_dir_end()
	return {}


# The exclusion rules here MUST match measure_artifacts.gd._measure_body, or the
# two instruments answer different questions and their agreement means nothing.
# So: every GeometryInstance3D that is visible in tree, top_level skipped
# (it does not follow the body it is nested under, so rotating the body does not
# rotate it), MultiMesh and CSG given their real extents, degenerate boxes
# dropped. Note this deliberately KEEPS a layers = 0 node: the corpus uses those
# as sizing anchors for artifacts built from multimeshes, and dropping them would
# shrink exactly the bodies that most need a true measurement.
func _merged_aabb(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if not (n is GeometryInstance3D):
			continue
		var vi := n as GeometryInstance3D
		if not vi.is_visible_in_tree() or vi.top_level:
			continue
		var local := AABB()
		if vi is MultiMeshInstance3D:
			var mm: MultiMesh = (vi as MultiMeshInstance3D).multimesh
			if mm == null or mm.instance_count <= 0:
				continue
			local = vi.get_aabb()
		elif vi is CSGShape3D:
			var meshes: Array = (vi as CSGShape3D).get_meshes()
			if meshes.size() < 2 or not (meshes[1] is Mesh):
				continue
			local = (meshes[1] as Mesh).get_aabb()
		elif vi is VisualInstance3D:
			local = (vi as VisualInstance3D).get_aabb()
		else:
			continue
		if local.size.length_squared() < 0.0001:
			continue
		var world: AABB = vi.global_transform * local
		if first:
			box = world
			first = false
		else:
			box = box.merge(world)
	return box


func _report(label: String, yaw: float, body: AABB) -> Dictionary:
	return {
		"yaw": yaw,
		"size": [snappedf(body.size.x, 0.01), snappedf(body.size.y, 0.01), snappedf(body.size.z, 0.01)],
		"center": [snappedf(body.get_center().x, 0.01), snappedf(body.get_center().y, 0.01),
			snappedf(body.get_center().z, 0.01)],
		"min": [snappedf(body.position.x, 0.01), snappedf(body.position.z, 0.01)],
		"max": [snappedf(body.end.x, 0.01), snappedf(body.end.z, 0.01)],
		"label": label,
	}


func _run() -> void:
	var found: Dictionary = _find_scene(_token)
	var scene_path: String = str(found.get("scene", ""))
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		print("PROBE FAIL: no scene for %s" % _token)
		quit(1)
		return

	var holder := Node3D.new()
	root.add_child(holder)
	await process_frame

	var rows: Array = []
	for yaw in [0.0, 90.0, 180.0, 270.0]:
		var packed: PackedScene = ResourceLoader.load(scene_path)
		var inst: Node = packed.instantiate()
		holder.add_child(inst)
		var n3: Node3D = inst as Node3D
		if n3 == null:
			print("PROBE FAIL: %s root is not Node3D" % _token)
			quit(1)
			return
		var cfg: Dictionary = found.get("cfg", {})
		if not cfg.is_empty() and inst.has_method("apply_grid_config"):
			inst.call("apply_grid_config", cfg)
		# The body stands at the ORIGIN and is turned about Y, which is what the
		# grid does to a token carrying a yaw. Everything reported below is
		# therefore relative to the cell centre the token names.
		n3.rotation_degrees = Vector3(0.0, yaw, 0.0)
		await process_frame
		await process_frame
		await create_timer(SETTLE).timeout
		var box: AABB = _merged_aabb(n3)
		rows.append(_report(_token, yaw, box))
		print("yaw %6.1f   size %6.2f x %6.2f   x[%7.2f, %7.2f]  z[%7.2f, %7.2f]"
			% [yaw, box.size.x, box.size.z, box.position.x, box.end.x, box.position.z, box.end.z])
		inst.queue_free()
		await process_frame

	var f := FileAccess.open(_out, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"token": _token, "rotations": rows}, "\t"))
		f.close()
		print("wrote %s" % _out)
	print("PROBE OK")
	quit(0)
