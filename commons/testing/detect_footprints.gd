# detect_footprints.gd — Measure real AABB footprints for all artifacts
#
# Loads each artifact scene, waits 2 frames for procedural generation,
# measures the combined AABB via PerfectShotFramer, converts to grid cells,
# and writes updated footprint + size_group back to registry JSON files.
#
# Zero AI tokens — pure geometry measurement.
#
# Usage:
#   godot_console --path . --xr-mode off --no-window \
#     --script res://commons/testing/detect_footprints.gd
#
#   # Dry run (report only, no writes):
#   ... -- --dry-run
#
#   # Single artifact:
#   ... -- --target=dark_sphere
#
#   # All artifacts in a sequence:
#   ... -- --sequence=lsystems --dry-run
#
#   # Custom timeout (default 10s):
#   ... -- --timeout=15
#
# Output:
#   user://footprint_report.json — full report with all measurements

extends SceneTree

const _Framer = preload("res://commons/testing/perfect_shot_framer.gd")

var _dry_run: bool = false
var _target: String = ""
var _sequence: String = ""
var _cube_size: float = 1.0
var _wait_frames: int = 3
var _timeout_sec: float = 10.0
var _report: Array[Dictionary] = []
var _registry_updates: Dictionary = {}  # registry_file -> { lookup_name -> {footprint, size_group} }
var _scene_root: Node3D = null
var _timed_out: bool = false
var _timeout_list: Array[String] = []
var _sequence_artifacts: Dictionary = {}  # lookup_name -> true (filter set)


func _init() -> void:
	_parse_args()
	# Use call_deferred so the tree is ready
	(func(): _run_detection()).call_deferred()


func _parse_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for arg in args:
		if arg == "--dry-run":
			_dry_run = true
		elif arg.begins_with("--target="):
			_target = arg.substr(9)
		elif arg.begins_with("--cube-size="):
			_cube_size = float(arg.substr(12))
		elif arg.begins_with("--wait-frames="):
			_wait_frames = int(arg.substr(14))
		elif arg.begins_with("--timeout="):
			_timeout_sec = float(arg.substr(10))
		elif arg.begins_with("--sequence="):
			_sequence = arg.substr(11)


func _run_detection() -> void:
	print("=== Footprint Detection ===")
	if _dry_run:
		print("  Mode: DRY RUN (no registry writes)")
	if _target != "":
		print("  Target: %s" % _target)
	if _sequence != "":
		print("  Sequence: %s" % _sequence)
	print("  Cube size: %.1f" % _cube_size)
	print("  Timeout: %.1fs per artifact" % _timeout_sec)
	print("")

	# Load sequence filter if specified
	if _sequence != "":
		_sequence_artifacts = _load_sequence_artifacts(_sequence)
		if _sequence_artifacts.is_empty():
			print("ERROR: No artifacts found for sequence '%s'" % _sequence)
			quit()
			return
		print("  Sequence artifacts: %d" % _sequence_artifacts.size())
		print("")

	# Create a root node to hold instantiated scenes
	_scene_root = Node3D.new()
	_scene_root.name = "FootprintDetection"
	root.add_child(_scene_root)

	# Load all registries
	var registries: Dictionary = _load_all_registries()

	var total: int = 0
	var measured: int = 0
	var skipped: int = 0
	var errors: int = 0

	for registry_file: String in registries:
		var registry_data: Dictionary = registries[registry_file]
		var artifacts: Dictionary = registry_data.get("artifacts", {})

		for lookup_name: String in artifacts:
			if _target != "" and lookup_name != _target:
				continue
			if not _sequence_artifacts.is_empty() and not _sequence_artifacts.has(lookup_name):
				continue

			total += 1
			var entry: Dictionary = artifacts[lookup_name]
			var scene_path: String = entry.get("scene", "")

			if scene_path == "" or not ResourceLoader.exists(scene_path):
				skipped += 1
				continue

			# Measure this artifact
			var result: Dictionary = await _measure_artifact(lookup_name, scene_path)

			if result.is_empty():
				errors += 1
				continue

			measured += 1
			result["registry_file"] = registry_file
			result["lookup_name"] = lookup_name

			# Store old values for comparison
			var old_fp: Array = entry.get("footprint", entry.get("parameters", {}).get("footprint", [1, 1, 1]))
			var old_sg: String = entry.get("size_group", entry.get("parameters", {}).get("size_group", "compact"))
			result["old_footprint"] = old_fp
			result["old_size_group"] = old_sg

			var changed: bool = false
			if old_fp is Array and old_fp.size() >= 3:
				if old_fp[0] != result["footprint"][0] or old_fp[1] != result["footprint"][1] or old_fp[2] != result["footprint"][2]:
					changed = true
			else:
				changed = true
			if old_sg != result["size_group"]:
				changed = true

			result["changed"] = changed
			_report.append(result)

			# Queue registry update
			if changed:
				if not _registry_updates.has(registry_file):
					_registry_updates[registry_file] = {}
				_registry_updates[registry_file][lookup_name] = {
					"footprint": result["footprint"],
					"size_group": result["size_group"],
					"aabb_size": result["aabb_size"],
				}

			# Progress
			if measured % 25 == 0:
				print("  ... measured %d / %d" % [measured, total])

	print("")
	print("=== Results ===")
	print("  Total: %d" % total)
	print("  Measured: %d" % measured)
	print("  Skipped (no scene): %d" % skipped)
	print("  Errors: %d" % errors)

	var changed_count: int = 0
	for r: Dictionary in _report:
		if r.get("changed", false):
			changed_count += 1
	print("  Changed: %d" % changed_count)
	print("  Timed out: %d" % _timeout_list.size())

	if _timeout_list.size() > 0:
		print("")
		print("Timed out artifacts (%.1fs limit):" % _timeout_sec)
		for t: String in _timeout_list:
			print("  %s" % t)

	# Print changed artifacts
	if changed_count > 0:
		print("")
		print("Changed artifacts:")
		for r: Dictionary in _report:
			if r.get("changed", false):
				print("  %s: [%d,%d,%d] %s -> [%d,%d,%d] %s" % [
					r["lookup_name"],
					r["old_footprint"][0] if r["old_footprint"] is Array and r["old_footprint"].size() >= 3 else 1,
					r["old_footprint"][1] if r["old_footprint"] is Array and r["old_footprint"].size() >= 3 else 1,
					r["old_footprint"][2] if r["old_footprint"] is Array and r["old_footprint"].size() >= 3 else 1,
					r["old_size_group"],
					r["footprint"][0], r["footprint"][1], r["footprint"][2],
					r["size_group"],
				])

	# Write report
	_save_report()

	# Write registry updates
	if not _dry_run and changed_count > 0:
		_apply_registry_updates(registries)
		print("")
		print("Registry files updated: %d" % _registry_updates.size())
	elif _dry_run and changed_count > 0:
		print("")
		print("DRY RUN — no registry files modified. Run without --dry-run to apply.")

	# Clean up and quit
	_scene_root.queue_free()
	await _wait_one_frame()
	quit()


func _measure_artifact(lookup_name: String, scene_path: String) -> Dictionary:
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		push_warning("detect_footprints: Cannot load scene: %s" % scene_path)
		return {}

	var instance: Node3D = scene.instantiate() as Node3D
	if instance == null:
		push_warning("detect_footprints: Scene is not Node3D: %s" % scene_path)
		return {}

	# Start a timeout timer — if the scene hangs, we bail out
	_timed_out = false
	var timeout_timer := create_timer(_timeout_sec)
	timeout_timer.timeout.connect(func():
		_timed_out = true
	)

	_scene_root.add_child(instance)

	# Wait frames for procedural generation (_ready, deferred calls, _process buildup)
	for i in range(_wait_frames):
		if _timed_out:
			break
		await _wait_one_frame()

	# Additional real-time wait for _process-based generators (if not timed out)
	if not _timed_out:
		var settle_timer := create_timer(0.5)
		settle_timer.timeout.connect(func(): pass)  # just need the signal
		await settle_timer.timeout

	# Check timeout
	if _timed_out:
		push_warning("detect_footprints: TIMEOUT on %s (%.1fs) — skipping" % [lookup_name, _timeout_sec])
		_timeout_list.append(lookup_name)
		# Force cleanup — free the stuck instance
		if is_instance_valid(instance):
			instance.queue_free()
		await _wait_one_frame()
		return {}

	# Measure AABB
	var aabb: AABB = _Framer.get_combined_aabb(instance)

	# Clean up
	if is_instance_valid(instance):
		instance.queue_free()
	await _wait_one_frame()

	if aabb.size.length() < 0.001:
		return {}

	# Convert AABB to grid footprint (cells)
	var fp_x: int = maxi(1, ceili(aabb.size.x / _cube_size))
	var fp_y: int = maxi(1, ceili(aabb.size.y / _cube_size))
	var fp_z: int = maxi(1, ceili(aabb.size.z / _cube_size))

	# Classify size group
	var max_dim: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	var size_group: String = _classify_size_group(max_dim, fp_x, fp_z)

	return {
		"footprint": [fp_x, fp_y, fp_z],
		"size_group": size_group,
		"aabb_size": [snapped(aabb.size.x, 0.01), snapped(aabb.size.y, 0.01), snapped(aabb.size.z, 0.01)],
		"aabb_position": [snapped(aabb.position.x, 0.01), snapped(aabb.position.y, 0.01), snapped(aabb.position.z, 0.01)],
	}


func _classify_size_group(max_dim: float, fp_x: int, fp_z: int) -> String:
	var footprint_cells: int = fp_x * fp_z
	if footprint_cells <= 1:
		return "compact"
	elif footprint_cells <= 4:
		return "standard"
	elif footprint_cells <= 9:
		return "large"
	else:
		return "xlarge"


func _load_sequence_artifacts(seq_id: String) -> Dictionary:
	## Collect all artifact lookup names belonging to a sequence.
	## Sources: artifact_groups in sequence JSON + interactables in map_data.json.
	var result: Dictionary = {}
	var seq_dir: String = "res://commons/maps/sequences"
	var dir := DirAccess.open(seq_dir)
	if not dir:
		return result

	# Find the sequence JSON
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var path: String = seq_dir.path_join(file_name)
			var json_text: String = FileAccess.get_file_as_string(path)
			if not json_text.is_empty():
				var json := JSON.new()
				if json.parse(json_text) == OK and json.data is Dictionary:
					var data: Dictionary = json.data
					var sequences: Dictionary = data.get("sequences", {})
					if sequences.has(seq_id):
						var seq: Dictionary = sequences[seq_id]
						# Collect from artifact_groups
						var groups: Array = seq.get("artifact_groups", [])
						for g: Variant in groups:
							if g is Dictionary:
								var arts: Array = (g as Dictionary).get("artifacts", [])
								for a: Variant in arts:
									if a is String:
										result[a as String] = true
						# Collect from map interactables
						var maps: Array = seq.get("maps", [])
						for map_name: Variant in maps:
							if map_name is String:
								_collect_map_interactables(map_name as String, result)
						break
		file_name = dir.get_next()
	dir.list_dir_end()

	# Also check top-level artifact_groups (outside sequences dict)
	dir.list_dir_begin()
	file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json") and file_name.replace(".json", "") == seq_id:
			var path: String = seq_dir.path_join(file_name)
			var json_text: String = FileAccess.get_file_as_string(path)
			if not json_text.is_empty():
				var json := JSON.new()
				if json.parse(json_text) == OK and json.data is Dictionary:
					var data: Dictionary = json.data
					var groups: Array = data.get("artifact_groups", [])
					for g: Variant in groups:
						if g is Dictionary:
							var arts: Array = (g as Dictionary).get("artifacts", [])
							for a: Variant in arts:
								if a is String:
									result[a as String] = true
		file_name = dir.get_next()
	dir.list_dir_end()
	return result


func _collect_map_interactables(map_name: String, out: Dictionary) -> void:
	## Read map_data.json and collect artifact tokens from the interactables layer.
	var map_path: String = "res://commons/maps/%s/map_data.json" % map_name
	if not FileAccess.file_exists(map_path):
		return
	var json_text: String = FileAccess.get_file_as_string(map_path)
	if json_text.is_empty():
		return
	var json := JSON.new()
	if json.parse(json_text) != OK or not json.data is Dictionary:
		return
	var layers: Dictionary = (json.data as Dictionary).get("layers", {})
	var inter: Array = layers.get("interactables", [])
	for row: Variant in inter:
		if row is Array:
			for cell: Variant in row:
				if cell is String:
					var token: String = (cell as String).strip_edges()
					if token != "" and token != " ":
						# Strip rotation/offset suffix
						out[token.split(":")[0]] = true


func _load_all_registries() -> Dictionary:
	var result: Dictionary = {}
	var registry_dir: String = "res://commons/artifacts/registry"
	var dir := DirAccess.open(registry_dir)
	if not dir:
		push_error("detect_footprints: Cannot open registry dir")
		return result

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var path: String = registry_dir.path_join(file_name)
			var json_text: String = FileAccess.get_file_as_string(path)
			if not json_text.is_empty():
				var json := JSON.new()
				if json.parse(json_text) == OK and json.data is Dictionary:
					result[file_name] = json.data
		file_name = dir.get_next()
	dir.list_dir_end()
	return result


func _save_report() -> void:
	var report_path: String = "user://footprint_report.json"
	var data: Dictionary = {
		"timestamp": Time.get_datetime_string_from_system(),
		"cube_size": _cube_size,
		"timeout_sec": _timeout_sec,
		"total_measured": _report.size(),
		"changed": _report.filter(func(r: Dictionary) -> bool: return r.get("changed", false)).size(),
		"timed_out": _timeout_list,
		"artifacts": _report,
	}
	var json_str: String = JSON.stringify(data, "  ")
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		print("Report saved: %s" % ProjectSettings.globalize_path(report_path))


func _apply_registry_updates(registries: Dictionary) -> void:
	for registry_file: String in _registry_updates:
		var updates: Dictionary = _registry_updates[registry_file]
		var registry_data: Dictionary = registries[registry_file]
		var artifacts: Dictionary = registry_data.get("artifacts", {})

		for lookup_name: String in updates:
			if not artifacts.has(lookup_name):
				continue
			var entry: Dictionary = artifacts[lookup_name]
			var update: Dictionary = updates[lookup_name]

			# Update top-level footprint and size_group
			entry["footprint"] = update["footprint"]
			entry["size_group"] = update["size_group"]

			# Also update inside parameters if it exists
			if entry.has("parameters") and entry["parameters"] is Dictionary:
				entry["parameters"]["footprint"] = update["footprint"]
				entry["parameters"]["size_group"] = update["size_group"]

		# Write back to file
		var path: String = "res://commons/artifacts/registry".path_join(registry_file)
		var global_path: String = ProjectSettings.globalize_path(path)
		var json_str: String = JSON.stringify(registry_data, "\t")
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string(json_str)
			file.close()
			print("  Updated: %s (%d artifacts)" % [registry_file, updates.size()])
		else:
			push_error("detect_footprints: Cannot write: %s" % global_path)


func _wait_one_frame() -> Signal:
	return process_frame
