extends SceneTree

## probe_artifact_elements.gd — MEASURE THE REAL ELEMENTS inside artifacts.
##
## The fractal thread's bottom rung ("the last perfect placement of elements
## inside each artifact") should carry measured truth, not inference. This
## probe instantiates each artifact the way the grid does — lookup_name meta
## stamped BEFORE add_child, so one-scene-many-names wrappers build their
## real variant — lets _ready() run, then walks the tree recording every
## visual element: name, class, mesh kind, position in artifact-root space,
## and AABB size. Output feeds /api/fractal/thread (elements rung) and the
## per-level lateral search.
##
## Usage (headless, serialize Godot instances, wrap in godot_watchdog):
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/probe_artifact_elements.gd -- \
##     --targets=a,b,c            probe exactly these lookups
##     [--out=res://commons/data/artifact_elements.json]
##     [--force]                  re-measure entries already present
##     [--max-elements=400]       per-artifact element cap (truncated flag set)
##
## Incremental: the output file is re-written after EVERY artifact, so a
## crash mid-batch (GPU teardown class) loses nothing already measured.

var _targets: PackedStringArray = []
var _out_path: String = "res://commons/data/artifact_elements.json"
var _force: bool = false
var _max_elements: int = 400

var _registry: Dictionary = {}      # lookup -> entry
var _results: Dictionary = {}       # lookup -> measurement (loaded + extended)


func _initialize() -> void:
	_parse_args()
	if _targets.is_empty():
		push_error("probe_artifact_elements: no --targets given")
		quit(1)
		return
	_load_registry()
	_load_existing()
	call_deferred("_run")


func _parse_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for a in args:
		var arg: String = String(a)
		if arg.begins_with("--targets="):
			for t in arg.substr(10).split(","):
				var name: String = String(t).strip_edges()
				if name != "":
					_targets.append(name)
		elif arg.begins_with("--out="):
			_out_path = arg.substr(6)
		elif arg == "--force":
			_force = true
		elif arg.begins_with("--max-elements="):
			_max_elements = maxi(10, int(arg.substr(15)))


func _load_registry() -> void:
	var dir := DirAccess.open("res://commons/artifacts/registry")
	if dir == null:
		return
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".json") and fname != "substrate_vectors.json":
			var f := FileAccess.open("res://commons/artifacts/registry/" + fname, FileAccess.READ)
			if f:
				var parsed: Variant = JSON.parse_string(f.get_as_text())
				if parsed is Dictionary:
					var arts: Variant = (parsed as Dictionary).get("artifacts", parsed)
					if arts is Dictionary:
						for k in (arts as Dictionary).keys():
							var v: Variant = (arts as Dictionary)[k]
							if v is Dictionary and not _registry.has(k):
								_registry[k] = v
		fname = dir.get_next()
	dir.list_dir_end()


func _load_existing() -> void:
	if FileAccess.file_exists(_out_path):
		var f := FileAccess.open(_out_path, FileAccess.READ)
		if f:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary and (parsed as Dictionary).has("artifacts"):
				_results = (parsed as Dictionary)["artifacts"]


func _save() -> void:
	var f := FileAccess.open(_out_path, FileAccess.WRITE)
	if f:
		var doc: Dictionary = {
			"_comment": "Measured elements inside each artifact. Written by commons/testing/probe_artifact_elements.gd; read by /api/fractal/thread (elements rung) and the per-level lateral search. Positions are in artifact-root space, sizes are world-scale AABB extents.",
			"artifacts": _results,
		}
		f.store_string(JSON.stringify(doc, " "))
		f.store_string("\n")


func _run() -> void:
	var done: int = 0
	for lookup in _targets:
		if _results.has(lookup) and not _force:
			print("probe_elements: SKIP %s (measured; --force to redo)" % lookup)
			continue
		var m: Dictionary = await _probe_one(String(lookup))
		if not m.is_empty():
			_results[lookup] = m
			_save()
			done += 1
			print("probe_elements: OK %s — %d elements" % [lookup, int(m.get("element_count", 0))])
	print("probe_elements: DONE — %d measured this run, %d total in file" % [done, _results.size()])
	quit(0)


func _probe_one(lookup: String) -> Dictionary:
	var info: Variant = _registry.get(lookup)
	if info == null:
		print("probe_elements: %s not in registry" % lookup)
		return {}
	var entry: Dictionary = info

	# delegate_to support — same contract as the grid and the capture harness
	var delegate_params: Dictionary = {}
	var scene_path: String = str(entry.get("scene", "")).strip_edges()
	if scene_path.is_empty() and str(entry.get("delegate_to", "")).strip_edges() != "":
		var target_info: Variant = _registry.get(str(entry.get("delegate_to", "")).strip_edges())
		if target_info is Dictionary:
			var dp: Variant = entry.get("delegate_params", {})
			if dp is Dictionary:
				delegate_params = dp
			scene_path = str((target_info as Dictionary).get("scene", "")).strip_edges()
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		print("probe_elements: %s scene missing (%s)" % [lookup, scene_path])
		return {}

	var packed: PackedScene = ResourceLoader.load(scene_path)
	if packed == null:
		return {}
	var artifact: Node = packed.instantiate()
	if artifact == null or not (artifact is Node3D):
		if artifact:
			artifact.free()
		return {}

	# THE CONTRACT: stamp before add_child so wrapper families build their variant.
	artifact.set_meta("artifact_lookup_name", lookup)
	root.add_child(artifact)
	if not delegate_params.is_empty() and artifact.has_method("apply_grid_config"):
		artifact.call_deferred("apply_grid_config", delegate_params.duplicate(true))

	# let _ready() and deferred builders run
	await process_frame
	await process_frame
	await process_frame

	var art3d: Node3D = artifact as Node3D
	var inv: Transform3D = art3d.global_transform.affine_inverse()
	var elements: Array = []
	var classes: Dictionary = {}
	var union_min: Vector3 = Vector3.INF
	var union_max: Vector3 = -Vector3.INF
	var total: int = 0
	var truncated: bool = false

	var stack: Array = [artifact]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if not (n is VisualInstance3D):
			continue
		var vi: VisualInstance3D = n as VisualInstance3D
		total += 1
		var cls: String = vi.get_class()
		classes[cls] = int(classes.get(cls, 0)) + 1

		var local_aabb: AABB = vi.get_aabb()
		# element AABB in artifact-root space
		var to_root: Transform3D = inv * vi.global_transform
		var root_aabb: AABB = to_root * local_aabb
		union_min = union_min.min(root_aabb.position)
		union_max = union_max.max(root_aabb.position + root_aabb.size)

		if elements.size() >= _max_elements:
			truncated = true
			continue
		var el: Dictionary = {
			"name": String(vi.name),
			"class": cls,
			"pos": _v3(to_root.origin),
			"size": _v3(root_aabb.size),
		}
		if vi is MeshInstance3D:
			var mi: MeshInstance3D = vi as MeshInstance3D
			if mi.mesh:
				el["mesh"] = mi.mesh.get_class()
			if mi.material_override:
				el["material"] = mi.material_override.get_class()
		elif vi is MultiMeshInstance3D:
			var mm: MultiMeshInstance3D = vi as MultiMeshInstance3D
			if mm.multimesh:
				el["instances"] = mm.multimesh.instance_count
				if mm.multimesh.mesh:
					el["mesh"] = mm.multimesh.mesh.get_class()
		elif vi is GPUParticles3D:
			el["mesh"] = "particles"
		elif vi is Label3D:
			el["mesh"] = "label"
			el["text"] = String((vi as Label3D).text).left(60)
		elements.append(el)

	var union: Dictionary = {}
	if total > 0 and union_min.x != INF:
		var usize: Vector3 = union_max - union_min
		var ucenter: Vector3 = union_min + usize * 0.5
		union = {"size": _v3(usize), "center": _v3(ucenter)}

	# teardown — honour the GPU release contract before freeing
	if artifact.has_method("release"):
		artifact.call("release")
	artifact.queue_free()
	await process_frame
	await process_frame

	return {
		"scene": scene_path,
		"measured_at": Time.get_datetime_string_from_system(true) + "Z",
		"element_count": total,
		"truncated": truncated,
		"classes": classes,
		"union_aabb": union,
		"elements": elements,
	}


func _v3(v: Vector3) -> Array:
	return [snappedf(v.x, 0.001), snappedf(v.y, 0.001), snappedf(v.z, 0.001)]
