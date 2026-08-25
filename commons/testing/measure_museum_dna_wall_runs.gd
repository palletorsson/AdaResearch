## Measure the exact configured bodies which the endless museum may hang as a
## DNA wall run.  This is deliberately narrower than measure_artifacts.gd:
## it never edits a registry and it measures the configured value, not merely
## the scene's shipped default.
##
## The ordering mirrors endless_museum.gd::_stamp_plan_wall_variant:
## configure outside the tree, add (so _ready builds), then read the immediate
## mesh/collision envelope.  Deferred apply_grid_config calls are intentionally
## not awaited because the assembler makes its fit decision in that same frame.
##
## Usage:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/measure_museum_dna_wall_runs.gd -- \
##     --spec=res://ada_run/museum_dna_wall_measure_spec.json \
##     --out=res://ada_run/museum_dna_wall_measurements.json

extends SceneTree

const MULTIPLES := preload("res://commons/scenes/em/em_multiples.gd")

var _spec_path := "res://ada_run/museum_dna_wall_measure_spec.json"
var _out_path := "res://ada_run/museum_dna_wall_measurements.json"
var _progress_path := "res://ada_run/museum_dna_wall_measurements.progress.txt"


func _initialize() -> void:
	_parse_args()
	call_deferred("_run")


func _parse_args() -> void:
	for raw_v in OS.get_cmdline_user_args():
		var raw := String(raw_v)
		if raw.begins_with("--spec="):
			_spec_path = raw.trim_prefix("--spec=")
		elif raw.begins_with("--out="):
			_out_path = raw.trim_prefix("--out=")
		elif raw.begins_with("--progress="):
			_progress_path = raw.trim_prefix("--progress=")


func _run() -> void:
	var spec := _read_json(_spec_path)
	if spec.is_empty():
		push_error("dna_wall_measure: missing or invalid spec %s" % _spec_path)
		quit(2)
		return
	var run_id := String(spec.get("run_id", ""))
	var report := _read_json(_out_path)
	if String(report.get("run_id", "")) != run_id:
		report = {
			"schema": "adaresearch.museum_dna_wall_measurements.v1",
			"run_id": run_id,
			"measurements": [],
			"skipped": [],
		}
	var done: Dictionary = {}
	for row_v in report.get("measurements", []):
		var row: Dictionary = row_v
		done[_key(row)] = true
	for row_v in report.get("skipped", []):
		var row: Dictionary = row_v
		done[_key(row)] = true
	var skip: Dictionary = {}
	for key_v in spec.get("skip", []):
		skip[String(key_v)] = true

	var holder := Node3D.new()
	holder.name = "DNAWallMeasurementHolder"
	root.add_child(holder)
	await process_frame

	var offered := 0
	for family_v in spec.get("families", []):
		var family: Dictionary = family_v
		offered += (family.get("variants", []) as Array).size()
		for variant_v in family.get("variants", []):
			var variant: Dictionary = variant_v
			var identity := {
				"anchor": String(family.get("anchor", "")),
				"axis": String(family.get("axis", "")),
				"value": String(variant.get("value", "")),
			}
			var variant_key := _key(identity)
			if done.has(variant_key):
				continue
			_write_text(_progress_path, variant_key + "\n")
			if skip.has(variant_key):
				identity["why"] = "producer crashed or stalled while measuring this variant"
				(report["skipped"] as Array).append(identity)
				done[variant_key] = true
				_write_json(_out_path, report)
				continue
			var row := _measure_variant(holder, family, variant)
			(report["measurements"] as Array).append(row)
			done[variant_key] = true
			_write_json(_out_path, report)
			await process_frame

	report["offered"] = offered
	report["measured"] = (report.get("measurements", []) as Array).size()
	report["skipped_count"] = (report.get("skipped", []) as Array).size()
	report["complete"] = int(report["measured"]) + int(report["skipped_count"]) == offered
	_write_json(_out_path, report)
	_write_text(_progress_path, "complete\n")
	print("dna_wall_measure: %d measured, %d skipped, %d offered" % [
		int(report["measured"]), int(report["skipped_count"]), offered])
	quit(0 if bool(report["complete"]) else 3)


func _measure_variant(holder: Node3D, family: Dictionary,
		variant: Dictionary) -> Dictionary:
	var anchor := String(family.get("anchor", ""))
	var axis := String(family.get("axis", ""))
	var value := String(variant.get("value", ""))
	var scene_path := String(family.get("scene", ""))
	var row := {"anchor": anchor, "axis": axis, "value": value,
		"scene": scene_path, "ok": false}
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		row["why"] = "scene missing"
		return row
	var packed := load(scene_path) as PackedScene
	if packed == null:
		row["why"] = "scene failed to load"
		return row
	var node := packed.instantiate() as Node3D
	if node == null:
		row["why"] = "scene root is not Node3D"
		return row
	node.set_meta("artifact_lookup_name", anchor)
	# A shipped value is a real first rung on a wall lineage.  Mark it bare so
	# MULTIPLES.stage does not reject it as a duplicate of itself.
	var is_shipped := false
	for prop_v in node.get_property_list():
		var prop: Dictionary = prop_v
		if String(prop.get("name", "")) == axis:
			is_shipped = str(node.get(axis)) == value
			break
	var staged: Dictionary = MULTIPLES.stage(node, {
		"axis": axis, "value": value, "is_default": is_shipped,
	})
	if not bool(staged.get("ok", false)):
		node.free()
		row["why"] = "axis refused: %s" % String(staged.get("why", ""))
		return row
	node.rotation = Vector3.ZERO
	holder.add_child(node)
	var box := _extent_of(node)
	if box.size.length_squared() < 0.000001 or not _finite(box):
		holder.remove_child(node)
		node.queue_free()
		row["why"] = "built no finite measurable body"
		return row
	row["ok"] = true
	row["configured"] = String(staged.get("value", value)) if not is_shipped else value
	# Contract order is width, depth, height.  Centre is retained so a later
	# seating pass can distinguish a large object from an off-origin one.
	row["size_wdh"] = [_r(box.size.x), _r(box.size.z), _r(box.size.y)]
	row["center_xyz"] = [_r(box.get_center().x), _r(box.get_center().y),
		_r(box.get_center().z)]
	# A body measurement must travel with its root.  Several artifact scenes
	# contain top-level geometry which stays behind when the artifact is moved;
	# at the origin it reads as a 34 cm object, while on a museum wall its merged
	# world AABB stretches twenty metres back to (0,0,0).  That is a scene
	# contract fault, not a demand for a twenty-metre gallery.  Translate in the
	# same frame and prove both size and centre are invariant.
	var probe_offset := Vector3(17.0, 0.0, 23.0)
	node.position += probe_offset
	var moved_box := _extent_of(node)
	var size_delta := (moved_box.size - box.size).abs()
	var centre_error := (moved_box.get_center() - box.get_center() - probe_offset).length()
	row["portable"] = size_delta.length() <= 0.05 and centre_error <= 0.05
	row["translation_error_m"] = _r(centre_error)
	if not bool(row["portable"]):
		row["translated_size_wdh"] = [_r(moved_box.size.x), _r(moved_box.size.z),
			_r(moved_box.size.y)]
	holder.remove_child(node)
	node.queue_free()
	return row


func _extent_of(node_root: Node3D) -> AABB:
	var acc := AABB()
	var got := false
	var stack: Array = [node_root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		var box := AABB()
		var have := false
		if node is MeshInstance3D:
			var mesh_node := node as MeshInstance3D
			if mesh_node.mesh != null:
				box = mesh_node.global_transform * mesh_node.get_aabb()
				have = true
		elif node is CollisionShape3D:
			var collision := node as CollisionShape3D
			if collision.shape != null:
				var debug_mesh := collision.shape.get_debug_mesh()
				if debug_mesh != null:
					box = collision.global_transform * debug_mesh.get_aabb()
					have = true
		if have:
			acc = acc.merge(box) if got else box
			got = true
	return acc


func _finite(box: AABB) -> bool:
	for value in [box.position.x, box.position.y, box.position.z,
			box.size.x, box.size.y, box.size.z]:
		if is_nan(value) or is_inf(value):
			return false
	return true


func _r(value: float) -> float:
	return snappedf(value, 0.001)


func _key(row: Dictionary) -> String:
	return "%s|%s|%s" % [String(row.get("anchor", "")),
		String(row.get("axis", "")), String(row.get("value", ""))]


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed as Dictionary if parsed is Dictionary else {}


func _write_json(path: String, data: Dictionary) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, " "))
		file.close()


func _write_text(path: String, text: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)
		file.close()
