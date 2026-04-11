# narrate_all.gd — Batch narration across curriculum spine
# Iterates spine sequences in order, narrates each map via SceneNarrator.
#
# Usage:
#   godot_console --path . --xr-mode off --no-window \
#     --script res://commons/testing/narrate_all.gd -- \
#     --outdir=res://ada_run/narrations \
#     --sequence=cellularautomata \
#     --wait=3
#
# Flags:
#   --outdir=<path>      Output root (default: res://ada_run/narrations)
#   --sequence=<name>    Only narrate maps from this sequence (default: all spine)
#   --wait=<seconds>     Per-map settle time before narrating (default: 3.0)

extends SceneTree

const SPINE_PATH := "res://commons/maps/curriculum_spine.json"
const SEQUENCES_DIR := "res://commons/maps/sequences/"

# CLI options
var _outdir: String = "res://ada_run/narrations"
var _sequence_filter: String = ""
var _wait_seconds: float = 3.0

# Runtime state
var _start_time: int = 0
var _stats := { "narrated": 0, "failed": 0, "skipped": 0 }
var _failed_list: PackedStringArray = []
var _all_map_results: Array = []  # per-map journey data for report
var _map_generated: bool = false  # signal flag for current map
var _sequence_results: Array = []  # per-sequence summary

func _initialize() -> void:
	_parse_args()
	call_deferred("_run")

func _parse_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for raw_arg in args:
		var arg: String = String(raw_arg).strip_edges()
		if not arg.begins_with("--") or arg.find("=") <= 2:
			continue
		var eq_idx: int = arg.find("=")
		var key: String = arg.substr(2, eq_idx - 2)
		var value: String = arg.substr(eq_idx + 1).strip_edges()
		match key:
			"outdir":
				_outdir = value
			"sequence":
				_sequence_filter = value
			"wait":
				if value.is_valid_float():
					_wait_seconds = maxf(1.0, float(value))

# ══════════════════════════════════════════════════════════════════
# MAIN PIPELINE
# ══════════════════════════════════════════════════════════════════

func _run() -> void:
	_start_time = Time.get_ticks_msec()
	print("=" .repeat(60))
	print("  NARRATE ALL — Batch Map Narration")
	print("=" .repeat(60))
	print("  Output:    %s" % _outdir)
	print("  Sequence:  %s" % (_sequence_filter if not _sequence_filter.is_empty() else "ALL SPINE"))
	print("  Wait:      %.1fs" % _wait_seconds)
	print("")

	# Enumerate sequences and maps
	var sequences: Array = _get_ordered_sequences()
	print("  Sequences: %d" % sequences.size())

	var total_maps: int = 0
	for seq in sequences:
		total_maps += seq.maps.size()
	print("  Maps:      %d" % total_maps)
	print("")

	# Process each sequence
	var map_index: int = 0
	for seq in sequences:
		print("─── Sequence: %s (%d maps) ───" % [seq.name, seq.maps.size()])
		var seq_result := {
			"name": seq.name,
			"order": seq.order,
			"maps": [],
		}

		for map_name in seq.maps:
			map_index += 1
			print("[%d/%d] %s/%s" % [map_index, total_maps, seq.name, map_name])
			var result: Dictionary = await _narrate_map(map_name, seq.name)
			seq_result.maps.append(result)
			_all_map_results.append(result)

		_sequence_results.append(seq_result)
		print("")

	# Write summary report
	_write_summary_report()
	_print_report()
	quit(0)

# ══════════════════════════════════════════════════════════════════
# SEQUENCE ENUMERATION
# ══════════════════════════════════════════════════════════════════

func _get_ordered_sequences() -> Array:
	var text: String = FileAccess.get_file_as_string(SPINE_PATH)
	if text.is_empty():
		push_error("narrate_all: Cannot read curriculum spine")
		return []
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("narrate_all: Invalid spine JSON")
		return []
	var data: Dictionary = json.data if json.data is Dictionary else {}

	var result: Array = []

	# Spine sequences (ordered)
	var spine: Dictionary = data.get("spine", {})
	var spine_seqs: Array = spine.get("sequences", [])
	for seq in spine_seqs:
		if not seq is Dictionary or not seq.has("name"):
			continue
		var seq_name: String = str(seq["name"])
		if not _sequence_filter.is_empty() and seq_name != _sequence_filter:
			continue
		var order: int = int(seq.get("order", 0))
		var maps: Array = _load_sequence_maps(seq_name)
		if maps.size() > 0:
			result.append({"name": seq_name, "order": order, "maps": maps})

	# Sort by order
	result.sort_custom(func(a, b): return a.order < b.order)
	return result

func _load_sequence_maps(seq_name: String) -> Array:
	var path: String = SEQUENCES_DIR.path_join(seq_name + ".json")
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_warning("narrate_all: Cannot read sequence: %s" % path)
		return []
	var json := JSON.new()
	if json.parse(text) != OK:
		return []
	var data: Dictionary = json.data if json.data is Dictionary else {}
	var inner: Dictionary = data.get("sequences", {})
	if inner.has(seq_name):
		var seq_data: Dictionary = inner[seq_name]
		return seq_data.get("maps", [])
	return data.get("maps", [])

# ══════════════════════════════════════════════════════════════════
# SINGLE MAP NARRATION
# ══════════════════════════════════════════════════════════════════

func _narrate_map(map_name: String, seq_name: String) -> Dictionary:
	# Check map_data.json exists
	var map_data_path: String = "res://commons/maps/%s/map_data.json" % map_name
	if not FileAccess.file_exists(map_data_path):
		print("  → SKIP (no map_data.json)")
		_stats["skipped"] += 1
		return {"map_name": map_name, "sequence": seq_name, "status": "skipped", "reason": "no map_data.json"}

	# Load GridSystem
	var grid_scene = load("res://commons/grid/grid_system.tscn")
	if not grid_scene:
		print("  → FAIL (cannot load grid_system.tscn)")
		_stats["failed"] += 1
		_failed_list.append("%s (grid_system.tscn load failed)" % map_name)
		return {"map_name": map_name, "sequence": seq_name, "status": "failed", "reason": "grid scene load failed"}

	var gs = grid_scene.instantiate()
	gs.map_name = map_name
	gs.auto_load_map_on_ready = true

	# Disable auto-narration from SceneNarrator autoload BEFORE adding to tree
	var narrator = root.get_node_or_null("SceneNarrator")
	if narrator:
		narrator.auto_narrate_on_map_load = false

	# Hide desktop overlay (text board / comment panel) during narration
	var overlay = root.get_node_or_null("DesktopMapSwitcherOverlay")
	if overlay and overlay.has_method("_set_overlay_visible"):
		overlay._set_overlay_visible(false)

	# Connect signal BEFORE add_child so we catch the deferred generation
	_map_generated = false
	if gs.has_signal("map_generation_complete"):
		gs.map_generation_complete.connect(_on_map_generated, CONNECT_ONE_SHOT)

	root.add_child(gs)

	# Wait for map generation — use wall-clock time (not frame-counted time)
	# because heavy artifact _process() can make frames take seconds
	var wait_start: int = Time.get_ticks_msec()
	var timeout_ms: int = 10000  # 10 seconds wall-clock
	while not _map_generated and (Time.get_ticks_msec() - wait_start) < timeout_ms:
		await create_timer(0.25).timeout

	if not _map_generated:
		if gs.has_signal("map_generation_complete") and gs.map_generation_complete.is_connected(_on_map_generated):
			gs.map_generation_complete.disconnect(_on_map_generated)
		print("  → WARN (generation timeout after %.1fs, proceeding anyway)" % ((Time.get_ticks_msec() - wait_start) / 1000.0))

	# Disable ALL processing after generation to prevent heavy artifact _process() loops
	# (CA artifacts with 64³ grids can consume entire frame budgets)
	_disable_processing_recursive(gs)

	# Brief settle — timer should fire now that heavy processing is disabled
	await create_timer(0.5).timeout

	# Force SceneNarrator to reconnect to this GridSystem
	if narrator and narrator.has_method("_try_connect_grid_system"):
		narrator._try_connect_grid_system()

	# Get narration data
	var spatial_data: Dictionary = {}
	var journey_data: Dictionary = {}
	var walkthrough_data: Dictionary = {}
	if narrator:
		spatial_data = narrator.get_spatial_data()
		journey_data = narrator.get_journey_data()
		walkthrough_data = narrator.get_walkthrough_data()
	else:
		print("  → FAIL (SceneNarrator not found)")
		_stats["failed"] += 1
		_failed_list.append("%s (no SceneNarrator)" % map_name)
		gs.queue_free()
		await process_frame
		await process_frame
		return {"map_name": map_name, "sequence": seq_name, "status": "failed", "reason": "no SceneNarrator"}

	# Write per-map output files
	var map_dir: String = _outdir.path_join(seq_name).path_join(map_name)

	# Markdown outputs
	var spatial_path: String = map_dir.path_join("scene_spatial.md")
	var journey_path: String = map_dir.path_join("journey_narrative.md")
	narrator.narrate_full_to(spatial_path, journey_path)

	# Walkthrough narrative
	var walkthrough_md: String = narrator.build_walkthrough_narrative(gs)
	_write_file_raw(map_dir.path_join("walkthrough.md"), walkthrough_md)

	# Structured JSON
	var narration_json: Dictionary = {
		"map_name": map_name,
		"sequence": seq_name,
		"timestamp": Time.get_datetime_string_from_system(true),
		"spatial": spatial_data,
		"journey": journey_data,
		"walkthrough": walkthrough_data,
	}
	_write_json(map_dir.path_join("narration.json"), narration_json)

	# Summary for report
	var issue_count: int = journey_data.get("issues", []).size()
	var artifact_count: int = journey_data.get("artifacts", []).size()
	var reachable_count: int = journey_data.get("pacing", {}).get("reachable_artifacts", 0)
	var tp = journey_data.get("teleporter", null)
	var tp_reachable: bool = tp != null and tp.get("reachable", false) if tp is Dictionary else false

	var status_str: String = "ok" if issue_count == 0 else "issues"
	print("  → %s (%d artifacts, %d issues)" % [status_str.to_upper(), artifact_count, issue_count])

	_stats["narrated"] += 1

	# Teardown
	gs.queue_free()
	await process_frame
	await process_frame

	return {
		"map_name": map_name,
		"sequence": seq_name,
		"status": status_str,
		"artifacts": artifact_count,
		"reachable": reachable_count,
		"teleporter_reachable": tp_reachable,
		"dead_ends": journey_data.get("dead_ends", []).size(),
		"issues": journey_data.get("issues", []),
	}

# ══════════════════════════════════════════════════════════════════
# SUMMARY REPORT
# ══════════════════════════════════════════════════════════════════

func _write_summary_report() -> void:
	# Collect global issues
	var global_issues: Array = []
	var maps_with_issues: int = 0
	var total_unreachable_tp: int = 0
	var total_unreachable_art: int = 0
	var total_pacing_sum: float = 0.0
	var pacing_count: int = 0

	for result in _all_map_results:
		var issues: Array = result.get("issues", [])
		if issues.size() > 0:
			maps_with_issues += 1
		for issue in issues:
			var gi = issue.duplicate()
			gi["map"] = result.get("map_name", "")
			gi["sequence"] = result.get("sequence", "")
			global_issues.append(gi)
			if issue.get("type", "") == "unreachable_teleporter":
				total_unreachable_tp += 1
			elif issue.get("type", "") == "unreachable_artifact":
				total_unreachable_art += 1

	# JSON report
	var report := {
		"timestamp": Time.get_datetime_string_from_system(true),
		"total_maps": _all_map_results.size(),
		"sequences": _sequence_results,
		"global_issues": global_issues,
		"statistics": {
			"maps_with_issues": maps_with_issues,
			"unreachable_teleporters": total_unreachable_tp,
			"unreachable_artifacts": total_unreachable_art,
			"narrated": _stats["narrated"],
			"failed": _stats["failed"],
			"skipped": _stats["skipped"],
		},
	}
	_write_json(_outdir.path_join("narration_report.json"), report)

	# Markdown report
	var md: PackedStringArray = []
	md.append("# Narration Report")
	md.append("Generated: %s\n" % Time.get_datetime_string_from_system())
	md.append("## Summary")
	md.append("- Total maps: %d" % _all_map_results.size())
	md.append("- Narrated: %d" % _stats["narrated"])
	md.append("- Failed: %d" % _stats["failed"])
	md.append("- Skipped: %d" % _stats["skipped"])
	md.append("- Maps with issues: %d" % maps_with_issues)
	md.append("")

	md.append("## Sequences\n")
	md.append("| Sequence | Maps | Issues | Status |")
	md.append("|----------|------|--------|--------|")
	for seq in _sequence_results:
		var seq_issues: int = 0
		for m in seq.get("maps", []):
			seq_issues += m.get("issues", []).size()
		var status = "OK" if seq_issues == 0 else "%d issues" % seq_issues
		md.append("| %s | %d | %d | %s |" % [seq.get("name", "?"), seq.get("maps", []).size(), seq_issues, status])
	md.append("")

	if global_issues.size() > 0:
		md.append("## Issues\n")
		# Critical first
		for issue in global_issues:
			if issue.get("severity", "") == "critical":
				md.append("- **CRITICAL** [%s/%s] %s" % [issue.get("sequence", ""), issue.get("map", ""), issue.get("description", "")])
		for issue in global_issues:
			if issue.get("severity", "") == "high":
				md.append("- **HIGH** [%s/%s] %s" % [issue.get("sequence", ""), issue.get("map", ""), issue.get("description", "")])
		for issue in global_issues:
			if issue.get("severity", "") == "low":
				md.append("- low [%s/%s] %s" % [issue.get("sequence", ""), issue.get("map", ""), issue.get("description", "")])
		md.append("")

	_write_file_raw(_outdir.path_join("narration_report.md"), "\n".join(md))

# ══════════════════════════════════════════════════════════════════
# UTILITIES
# ══════════════════════════════════════════════════════════════════

func _on_map_generated() -> void:
	_map_generated = true

func _disable_processing_recursive(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	node.set_process_internal(false)
	node.set_physics_process_internal(false)
	for child in node.get_children():
		_disable_processing_recursive(child)

# ══════════════════════════════════════════════════════════════════
# FILE I/O
# ══════════════════════════════════════════════════════════════════

func _write_json(path: String, data: Dictionary) -> void:
	var abs_path: String = _globalize(path)
	_ensure_dir(abs_path.get_base_dir())
	var file = FileAccess.open(abs_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func _write_file_raw(path: String, content: String) -> void:
	var abs_path: String = _globalize(path)
	_ensure_dir(abs_path.get_base_dir())
	var file = FileAccess.open(abs_path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()

func _globalize(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	return path

func _ensure_dir(dir_path: String) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

# ══════════════════════════════════════════════════════════════════
# REPORTING
# ══════════════════════════════════════════════════════════════════

func _print_report() -> void:
	var elapsed: float = (Time.get_ticks_msec() - _start_time) / 1000.0
	print("=" .repeat(60))
	print("  NARRATION REPORT")
	print("=" .repeat(60))
	print("  Narrated: %d" % _stats["narrated"])
	print("  Failed:   %d" % _stats["failed"])
	print("  Skipped:  %d" % _stats["skipped"])
	print("  Time:     %.1f seconds (%.1f minutes)" % [elapsed, elapsed / 60.0])

	if _failed_list.size() > 0:
		print("")
		print("  Failed targets:")
		for line in _failed_list:
			print("    - %s" % line)

	print("")
	print("  Output:   %s" % _outdir)
	print("  Report:   %s" % _outdir.path_join("narration_report.json"))
	print("=" .repeat(60))
