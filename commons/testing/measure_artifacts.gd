# measure_artifacts.gd — Batch AABB measurement for all registered artifacts
# Loads every artifact scene, measures its bounding box, outputs dimensions JSON.
#
# Usage:
#   godot --path . --xr-mode off --no-window \
#     --script res://commons/testing/measure_artifacts.gd \
#     -- --outdir=res://ada_run
#
# Flags:
#   --outdir=<path>      Output directory (default: res://ada_run)
#   --registry=<name>    Only measure artifacts from this registry (default: all)

extends SceneTree

const REGISTRY_DIR := "res://commons/artifacts/registry/"

var _outdir: String = "res://ada_run"
var _registry_filter: String = ""
var _start_time: int = 0

func _initialize() -> void:
	_parse_args()
	call_deferred("_run")

func _parse_args() -> void:
	for raw_arg in OS.get_cmdline_user_args():
		var arg: String = String(raw_arg).strip_edges()
		if not arg.begins_with("--") or arg.find("=") <= 2:
			continue
		var eq_idx: int = arg.find("=")
		var key: String = arg.substr(2, eq_idx - 2)
		var value: String = arg.substr(eq_idx + 1).strip_edges()
		match key:
			"outdir":
				_outdir = value
			"registry":
				_registry_filter = value

# ══════════════════════════════════════════════════════════════════
# MAIN PIPELINE
# ══════════════════════════════════════════════════════════════════

func _run() -> void:
	_start_time = Time.get_ticks_msec()
	print("measure_artifacts: Starting...")

	# 1. Load all artifacts from registries
	var artifacts: Dictionary = _load_all_artifacts()
	print("measure_artifacts: Found %d unique artifacts" % artifacts.size())

	# 2. Measure each artifact
	var holder := Node3D.new()
	holder.name = "MeasurementHolder"
	root.add_child(holder)
	await process_frame

	var results: Array = []
	var measured: int = 0
	var skipped: int = 0
	var errors: int = 0

	var lookup_names: Array = artifacts.keys()
	lookup_names.sort()

	# Resume support: if we have a partial report, skip everything up to
	# and including the last entry it contains.
	var checkpoint_path: String = _outdir.path_join("artifact_measurements.checkpoint.json")
	var skip_list_path: String = _outdir.path_join("artifact_measurements.skip_list.txt")
	var done_set: Dictionary = {}
	if FileAccess.file_exists(checkpoint_path):
		var prior := _load_json(checkpoint_path)
		var prior_arts: Array = prior.get("artifacts", []) as Array
		for r in prior_arts:
			if r is Dictionary and r.has("lookup_name"):
				done_set[r["lookup_name"]] = true
				results.append(r)
		print("measure_artifacts: resuming, %d previously measured" % done_set.size())
	# Skip list: artifacts known to crash Godot. One lookup_name per line.
	var skip_set: Dictionary = {}
	if FileAccess.file_exists(skip_list_path):
		var sf := FileAccess.open(skip_list_path, FileAccess.READ)
		while sf and not sf.eof_reached():
			var line: String = sf.get_line().strip_edges()
			if not line.is_empty() and not line.begins_with("#"):
				skip_set[line] = true
		if sf: sf.close()
		print("measure_artifacts: skip-list loaded, %d names" % skip_set.size())

	for lookup_name in lookup_names:
		if done_set.has(lookup_name):
			continue
		if skip_set.has(lookup_name):
			results.append({
				"lookup_name": lookup_name,
				"scene": (artifacts[lookup_name] as Dictionary).get("scene", ""),
				"registry": (artifacts[lookup_name] as Dictionary).get("_registry_source", ""),
				"error": "skipped_crashes_godot",
			})
			skipped += 1
			continue
		var entry: Dictionary = artifacts[lookup_name]
		var scene_path: String = entry.get("scene", "")

		# Write progress marker so we know who was being processed if Godot crashes.
		_write_progress(_outdir.path_join("artifact_measurements.progress.txt"),
			"%s\n%s\n" % [lookup_name, scene_path])

		if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
			skipped += 1
			continue

		var packed: PackedScene = ResourceLoader.load(scene_path)
		if not packed:
			errors += 1
			results.append({
				"lookup_name": lookup_name,
				"scene": scene_path,
				"error": "failed_to_load",
				"registry": entry.get("_registry_source", ""),
			})
			continue

		var instance: Node = packed.instantiate()
		if not instance:
			errors += 1
			continue

		holder.add_child(instance)

		# Disable processing to prevent simulations from running
		_disable_processing_recursive(instance)

		# Give _ready() two frames
		await process_frame
		await process_frame

		var target: Node3D = instance as Node3D if instance is Node3D else null
		if not target:
			for child in instance.get_children():
				if child is Node3D:
					target = child
					break

		if target:
			var aabb: AABB = _get_combined_aabb(target)

			# Clamp extreme values (particles, hidden geometry)
			if aabb.size.length() > 100.0:
				aabb = AABB()  # discard nonsense

			var size_x: float = snapped(aabb.size.x, 0.01)
			var size_y: float = snapped(aabb.size.y, 0.01)
			var size_z: float = snapped(aabb.size.z, 0.01)
			var max_dim: float = maxf(size_x, maxf(size_y, size_z))

			# Grid cells: ceil to nearest integer, minimum 1
			var grid_w: int = maxi(1, ceili(size_x))
			var grid_h: int = maxi(1, ceili(size_y))
			var grid_d: int = maxi(1, ceili(size_z))

			results.append({
				"lookup_name": lookup_name,
				"scene": scene_path,
				"registry": entry.get("_registry_source", ""),
				"aabb_size": [size_x, size_y, size_z],
				"aabb_center": [
					snapped(aabb.get_center().x, 0.01),
					snapped(aabb.get_center().y, 0.01),
					snapped(aabb.get_center().z, 0.01),
				],
				"grid_cells": [grid_w, grid_d],  # width x depth (XZ plane)
				"max_dimension_m": snapped(max_dim, 0.01),
				"interaction": entry.get("interaction", ""),
				"category": entry.get("category", ""),
				"tags": entry.get("tags", []),
			})
		else:
			results.append({
				"lookup_name": lookup_name,
				"scene": scene_path,
				"registry": entry.get("_registry_source", ""),
				"error": "no_node3d",
			})

		instance.queue_free()
		await process_frame

		measured += 1
		if measured % 25 == 0:
			var elapsed: float = (Time.get_ticks_msec() - _start_time) / 1000.0
			print("measure_artifacts: %d / %d measured (%.1fs)" % [measured, lookup_names.size(), elapsed])
			# Flush checkpoint every 25 artifacts so crashes don't lose much.
			_write_json(checkpoint_path, {
				"generated": Time.get_datetime_string_from_system(true),
				"artifacts": results,
			})

	# 3. Build report
	var report := {
		"generated": Time.get_datetime_string_from_system(true),
		"total_artifacts": lookup_names.size(),
		"measured": measured,
		"skipped": skipped,
		"errors": errors,
		"artifacts": results,
	}

	# Size distribution summary
	var size_buckets := { "tiny": 0, "small": 0, "medium": 0, "large": 0, "huge": 0 }
	for r in results:
		if r.has("error"):
			continue
		var max_d: float = r.get("max_dimension_m", 0.0)
		if max_d <= 0.3:
			size_buckets["tiny"] += 1
		elif max_d <= 1.0:
			size_buckets["small"] += 1
		elif max_d <= 2.0:
			size_buckets["medium"] += 1
		elif max_d <= 4.0:
			size_buckets["large"] += 1
		else:
			size_buckets["huge"] += 1
	report["size_distribution"] = size_buckets

	# 4. Write output
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_outdir))
	var out_path: String = _outdir.path_join("artifact_measurements.json")
	_write_json(out_path, report)

	var elapsed_total: float = (Time.get_ticks_msec() - _start_time) / 1000.0
	print("")
	print("═══════════════════════════════════════════")
	print("measure_artifacts: COMPLETE")
	print("  Measured: %d" % measured)
	print("  Skipped:  %d (no scene)" % skipped)
	print("  Errors:   %d" % errors)
	print("  Time:     %.1fs" % elapsed_total)
	print("")
	print("  Size distribution:")
	print("    tiny  (≤0.3m): %d" % size_buckets["tiny"])
	print("    small (≤1.0m): %d" % size_buckets["small"])
	print("    medium(≤2.0m): %d" % size_buckets["medium"])
	print("    large (≤4.0m): %d" % size_buckets["large"])
	print("    huge  (>4.0m): %d" % size_buckets["huge"])
	print("")
	var abs_path: String = ProjectSettings.globalize_path(out_path)
	print("  Output: %s" % abs_path)
	print("═══════════════════════════════════════════")

	quit(0)

# ══════════════════════════════════════════════════════════════════
# REGISTRY LOADING
# ══════════════════════════════════════════════════════════════════

func _load_all_artifacts() -> Dictionary:
	var all_artifacts: Dictionary = {}

	# Load all registries from registry/ directory
	var dir := DirAccess.open(REGISTRY_DIR)
	if dir:
		dir.list_dir_begin()
		var fname: String = dir.get_next()
		while fname != "":
			if fname.ends_with(".json"):
				if _registry_filter.is_empty() or fname.begins_with(_registry_filter):
					var path: String = REGISTRY_DIR.path_join(fname)
					var data := _load_json(path)
					if data.has("artifacts"):
						var arts = data["artifacts"]
						if arts is Dictionary:
							for key in arts:
								var entry: Dictionary = arts[key]
								var lname: String = entry.get("lookup_name", key)
								entry["_registry_source"] = fname
								all_artifacts[lname] = entry
						elif arts is Array:
							for entry in arts:
								if entry is Dictionary:
									var lname: String = entry.get("lookup_name", "")
									if not lname.is_empty():
										entry["_registry_source"] = fname
										all_artifacts[lname] = entry
			fname = dir.get_next()
		dir.list_dir_end()

	return all_artifacts

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		push_warning("measure_artifacts: Failed to parse %s" % path)
		return {}
	if json.data is Dictionary:
		return json.data
	return {}

# ══════════════════════════════════════════════════════════════════
# AABB MEASUREMENT (from check_aabb_below_ground.gd)
# ══════════════════════════════════════════════════════════════════

func _get_combined_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for child in node.get_children():
		var child_aabb := AABB()
		var has_aabb := false
		if child is MeshInstance3D:
			var mesh = (child as MeshInstance3D).mesh
			if mesh:
				child_aabb = child.transform * mesh.get_aabb()
				has_aabb = true
		elif child is MultiMeshInstance3D:
			var mm = child.multimesh
			if mm and mm.instance_count > 0:
				child_aabb = child.transform * mm.get_aabb()
				has_aabb = true
		elif child is CSGShape3D:
			var child_meshes: Array = child.get_meshes()
			if child_meshes.size() >= 2:
				var m = child_meshes[1]
				if m is Mesh:
					child_aabb = child.transform * m.get_aabb()
					has_aabb = true
		elif child is GPUParticles3D:
			child_aabb = child.transform * child.visibility_aabb
			has_aabb = true
		if has_aabb and child_aabb.size.length() > 0:
			if first:
				result = child_aabb
				first = false
			else:
				result = result.merge(child_aabb)
		if child is Node3D:
			var sub_aabb: AABB = _get_combined_aabb(child)
			if sub_aabb.size.length() > 0:
				sub_aabb = child.transform * sub_aabb
				if first:
					result = sub_aabb
					first = false
				else:
					result = result.merge(sub_aabb)
	return result

# ══════════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════════

func _disable_processing_recursive(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	node.set_process_internal(false)
	node.set_physics_process_internal(false)
	for child in node.get_children():
		_disable_processing_recursive(child)

func _write_progress(path: String, body: String) -> void:
	var abs_path: String = ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(body)
		file.close()


func _write_json(path: String, data: Dictionary) -> void:
	var abs_path: String = ProjectSettings.globalize_path(path)
	var dir_path: String = abs_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir_path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "  "))
		file.close()
	else:
		push_error("measure_artifacts: Cannot write %s" % path)
