extends SceneTree

## Headless registry sweep for VR-facing artifact visibility.
##
## Loads every artifact registry entry, checks that the scene exists, loads,
## instantiates, enters the tree, and exposes at least some visible geometry.
##
## Usage:
##   godot --path . --xr-mode off --no-window --script \
##     res://commons/testing/artifact_vr_spawn_sweep.gd
##
## Optional:
##   --registry=res://commons/artifacts/registry/commons_artifacts.json
##   --out=user://artifact_vr_spawn_sweep.json
##   --contains=dna

const REGISTRY_DIR := "res://commons/artifacts/registry/"

var _registry_filter: String = ""
var _contains_filter: String = ""
var _out_path: String = "user://artifact_vr_spawn_sweep.json"


func _initialize() -> void:
	_parse_args()
	call_deferred("_run")


func _parse_args() -> void:
	for raw in OS.get_cmdline_user_args():
		var arg := String(raw).strip_edges()
		if not arg.begins_with("--"):
			continue
		var eq := arg.find("=")
		if eq <= 2:
			continue
		var key := arg.substr(2, eq - 2)
		var value := arg.substr(eq + 1).strip_edges()
		match key:
			"registry":
				_registry_filter = value
			"contains":
				_contains_filter = value.to_lower()
			"out":
				_out_path = value


func _run() -> void:
	var report := {
		"generated_at": Time.get_datetime_string_from_system(),
		"total": 0,
		"ok": 0,
		"failed": 0,
		"entries": [],
	}

	for entry in _load_registry_entries():
		var item_report := await _test_entry(entry)
		report["entries"].append(item_report)
		report["total"] += 1
		if bool(item_report.get("ok", false)):
			report["ok"] += 1
		else:
			report["failed"] += 1
		print("[%d/%d] %s %s" % [
			report["total"],
			-1,
			"OK" if bool(item_report.get("ok", false)) else "FAIL",
			str(item_report.get("lookup_name", "?"))
		])

	_write_report(report)
	print("artifact_vr_spawn_sweep: %d total, %d ok, %d failed" % [
		report["total"], report["ok"], report["failed"]
	])
	quit(0 if int(report["failed"]) == 0 else 2)


func _load_registry_entries() -> Array:
	var out: Array = []
	if not _registry_filter.is_empty():
		var dict := _load_registry_file(_registry_filter)
		for key in dict.keys():
			var info: Dictionary = dict[key]
			if _matches_filter(key):
				out.append({
					"lookup_name": key,
					"registry_path": _registry_filter,
					"artifact": info,
				})
		return out

	var dir := DirAccess.open(REGISTRY_DIR)
	if not dir:
		return out
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var res_path := REGISTRY_DIR + file_name
			var dict := _load_registry_file(res_path)
			for key in dict.keys():
				var info: Dictionary = dict[key]
				if _matches_filter(key):
					out.append({
						"lookup_name": key,
						"registry_path": res_path,
						"artifact": info,
					})
		file_name = dir.get_next()
	dir.list_dir_end()
	out.sort_custom(func(a, b): return str(a["lookup_name"]) < str(b["lookup_name"]))
	return out


func _matches_filter(key: String) -> bool:
	return _contains_filter.is_empty() or key.to_lower().contains(_contains_filter)


func _load_registry_file(path: String) -> Dictionary:
	var txt := FileAccess.get_file_as_string(path)
	if txt.is_empty():
		return {}
	var json := JSON.new()
	if json.parse(txt) != OK:
		return {}
	var data: Variant = json.data
	if not (data is Dictionary):
		return {}
	var dict: Dictionary = data
	var artifacts: Variant = dict.get("artifacts", dict)
	return artifacts if artifacts is Dictionary else {}


func _test_entry(entry: Dictionary) -> Dictionary:
	var lookup_name: String = str(entry.get("lookup_name", ""))
	var artifact: Dictionary = entry.get("artifact", {})
	var scene_path: String = str(artifact.get("scene", ""))
	var report := {
		"lookup_name": lookup_name,
		"registry_path": str(entry.get("registry_path", "")),
		"scene": scene_path,
		"ok": false,
		"scene_exists": false,
		"loaded": false,
		"instantiated": false,
		"visual_count": 0,
		"aabb_size": [0.0, 0.0, 0.0],
		"issues": [],
	}

	if scene_path.is_empty():
		report["issues"].append("no scene path")
		return report
	report["scene_exists"] = ResourceLoader.exists(scene_path)
	if not bool(report["scene_exists"]):
		report["issues"].append("scene missing")
		return report

	var packed: PackedScene = ResourceLoader.load(scene_path)
	if packed == null:
		report["issues"].append("scene load failed")
		return report
	report["loaded"] = true

	var instance: Node = packed.instantiate()
	if instance == null:
		report["issues"].append("instantiate failed")
		return report
	report["instantiated"] = true
	root.add_child(instance)
	await process_frame
	await process_frame

	var visual_count := _count_visuals(instance)
	report["visual_count"] = visual_count
	var aabb := _collect_aabb(instance)
	report["aabb_size"] = [aabb.size.x, aabb.size.y, aabb.size.z]
	if visual_count == 0:
		report["issues"].append("no VisualInstance3D descendants")
	if aabb.size.length() < 0.001:
		report["issues"].append("empty visual AABB")

	if instance.has_method("apply_grid_config"):
		report["issues"].append("scene depends on grid config; manual VR test recommended")

	report["ok"] = int(report["issues"].size()) == 0 or (
		visual_count > 0 and aabb.size.length() >= 0.001
	)

	instance.queue_free()
	await process_frame
	return report


func _count_visuals(node: Node) -> int:
	var count := 0
	var stack: Array = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is VisualInstance3D:
			count += 1
		for child in current.get_children():
			stack.append(child)
	return count


func _collect_aabb(node: Node) -> AABB:
	var total := AABB()
	var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is VisualInstance3D:
			var vi := current as VisualInstance3D
			var aabb := vi.get_aabb()
			var xaabb := vi.global_transform * aabb
			if aabb.size.length() > 0.0:
				if first:
					total = xaabb
					first = false
				else:
					total = total.merge(xaabb)
		for child in current.get_children():
			stack.append(child)
	if first:
		return AABB()
	return total


func _write_report(report: Dictionary) -> void:
	var out := _out_path
	if out.begins_with("user://"):
		out = ProjectSettings.globalize_path(out)
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var file := FileAccess.open(out, FileAccess.WRITE)
	if file == null:
		push_error("artifact_vr_spawn_sweep: failed to write %s" % out)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("artifact_vr_spawn_sweep: wrote %s" % out)

