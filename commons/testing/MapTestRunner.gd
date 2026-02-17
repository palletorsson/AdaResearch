## MapTestRunner — Automated runtime map load tester.
## Loads every map through GridSystem.reload_map in spine sequence order,
## validates each map loads correctly, records results, and produces a
## JSON report + console summary.
##
## Catches runtime errors that static validation can't: broken scripts,
## missing XROrigin3D, GPU texture crashes, null tweens, MultiMesh bounds,
## missing artifacts, hung map generation, etc.
##
## Usage: Open map_test_runner.tscn, configure export vars in inspector,
## run with F6 (or Project > Run Current Scene).
extends Node3D
class_name MapTestRunner

# ============================================================================
# CONFIGURATION
# ============================================================================

## Test mode: spine_only = all spine sequences; single_sequence = one specific sequence
@export_enum("spine_only", "single_sequence") var test_mode := "spine_only"

## Jump to this sequence (skip earlier ones). Empty = start from beginning.
@export var start_sequence: String = ""

## For single_sequence mode: which sequence to test
@export var single_sequence_name: String = ""

## Maximum seconds to wait for a map to finish generating
@export var timeout_seconds: float = 10.0

## Start testing automatically on scene load
@export var auto_start: bool = true

## Also test Lab/map_data_post_* maps between sequences
@export var include_lab_posts: bool = true

## Capture a screenshot for each map (saved to user://map_test_screenshots/)
@export var take_screenshots: bool = false

## Load time threshold (ms) — maps slower than this get flagged as SLOW
@export var slow_threshold_ms: float = 3000.0

# ============================================================================
# CONSTANTS
# ============================================================================

## Children of LabGridSystem that must survive between map reloads
const _GRID_ESSENTIAL := [
	"CubeScene",
	"GridDataComponent", "GridStructureComponent", "GridUtilitiesComponent",
	"GridInteractablesComponent", "GridSpawnComponent", "GridCeilingComponent",
	"GridWallComponent", "GridAudioComponent",
]

# ============================================================================
# REFERENCES
# ============================================================================
var lab_grid_system: Node
var timeout_timer: Timer
var status_label: Label
var detail_label: Label
var title_label: Label
var progress_bar: ProgressBar

# ============================================================================
# STATE
# ============================================================================
var test_queue: Array[Dictionary] = []  # [{map_name, sequence_name, is_lab_post}]
var current_test_index: int = 0
var is_testing: bool = false
var _test_start_time: int = 0
var _test_start_memory: float = 0.0
var _map_ready: bool = false
var _map_timed_out: bool = false
var _run_start_time: float = 0.0

# Snapshot for stray node cleanup
var _root_snapshot: Array[StringName] = []

# Results
var results: Array[Dictionary] = []
var pass_count: int = 0
var warn_count: int = 0
var fail_count: int = 0
var timeout_count: int = 0

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	lab_grid_system = get_node_or_null("../LabGridSystem")
	timeout_timer = get_node_or_null("TimeoutTimer")

	# Find UI elements
	status_label = get_node_or_null("../TestOverlay/InfoPanel/VBox/StatusLabel")
	detail_label = get_node_or_null("../TestOverlay/InfoPanel/VBox/DetailLabel")
	title_label = get_node_or_null("../TestOverlay/InfoPanel/VBox/TitleLabel")
	progress_bar = get_node_or_null("../TestOverlay/InfoPanel/VBox/ProgressBar")

	if not lab_grid_system:
		push_error("MapTestRunner: LabGridSystem not found!")
		_set_status("ERROR: LabGridSystem not found")
		return

	if timeout_timer:
		timeout_timer.timeout.connect(_on_timeout)

	# No mouse capture
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	call_deferred("_deferred_start")

func _deferred_start() -> void:
	_take_snapshot()

	# Disconnect LabGridSystem's catalog setup — test runner doesn't need
	# the DesktopArtifactCatalog, and its synchronous load() blocks transitions.
	if lab_grid_system and lab_grid_system.has_signal("map_generation_complete"):
		if lab_grid_system.has_method("_on_lab_map_ready_for_catalog"):
			if lab_grid_system.map_generation_complete.is_connected(
					lab_grid_system._on_lab_map_ready_for_catalog):
				lab_grid_system.map_generation_complete.disconnect(
					lab_grid_system._on_lab_map_ready_for_catalog)
				print("MapTestRunner: Disconnected catalog setup")

	if auto_start:
		# Wait for initial Lab map to finish loading
		await _wait_for_initial_load()
		_start_tests()

# ============================================================================
# WAIT FOR INITIAL MAP
# ============================================================================
func _wait_for_initial_load() -> void:
	_set_status("Waiting for initial map load...")
	var signal_received := false
	var _on_complete := func(): signal_received = true

	if lab_grid_system.has_signal("map_generation_complete"):
		lab_grid_system.map_generation_complete.connect(_on_complete, CONNECT_ONE_SHOT)

	var wait_time: float = 0.0
	while not signal_received and wait_time < 15.0:
		if lab_grid_system.has_method("is_map_ready") and lab_grid_system.is_map_ready():
			break
		await get_tree().create_timer(0.05).timeout
		wait_time += 0.05

	if not signal_received:
		if lab_grid_system.has_signal("map_generation_complete"):
			if lab_grid_system.map_generation_complete.is_connected(_on_complete):
				lab_grid_system.map_generation_complete.disconnect(_on_complete)

	# Stop any audio that auto-started
	_stop_audio()
	await get_tree().process_frame
	print("MapTestRunner: Initial load complete (%.2fs)" % wait_time)

# ============================================================================
# QUEUE BUILDING
# ============================================================================
func _start_tests() -> void:
	_run_start_time = Time.get_unix_time_from_system()
	_build_test_queue()

	if test_queue.is_empty():
		push_error("MapTestRunner: No maps to test!")
		_set_status("ERROR: No maps found in test queue")
		return

	# Count sequences
	var seq_names: Dictionary = {}
	for entry in test_queue:
		seq_names[entry.sequence_name] = true

	var header := "====== MAP TEST RUNNER ======"
	print("\n" + header)
	print("Mode: %s | Maps: %d across %d sequences" % [
		test_mode, test_queue.size(), seq_names.size()])
	print(header.replace("=", "-") + "\n")

	if progress_bar:
		progress_bar.max_value = test_queue.size()
		progress_bar.value = 0

	is_testing = true
	current_test_index = 0
	_test_next_map()

func _build_test_queue() -> void:
	test_queue.clear()

	var spine_path := "res://commons/maps/curriculum_spine.json"
	if not FileAccess.file_exists(spine_path):
		push_error("MapTestRunner: curriculum_spine.json not found!")
		return

	var spine_file := FileAccess.open(spine_path, FileAccess.READ)
	var spine_json = JSON.parse_string(spine_file.get_as_text())
	spine_file.close()

	if spine_json == null or not spine_json.has("spine"):
		push_error("MapTestRunner: Invalid curriculum_spine.json (missing 'spine')")
		return

	# Get spine sequences sorted by order
	var sequences: Array = spine_json["spine"]["sequences"]
	sequences.sort_custom(func(a, b): return a.get("order", 999) < b.get("order", 999))

	# Filter for single_sequence mode
	if test_mode == "single_sequence" and single_sequence_name != "":
		sequences = sequences.filter(
			func(s): return s.get("name", "") == single_sequence_name)

	# Skip to start_sequence if set
	var found_start := false
	if start_sequence != "":
		var filtered: Array = []
		for s in sequences:
			if s.get("name", "") == start_sequence:
				found_start = true
			if found_start:
				filtered.append(s)
		if found_start:
			sequences = filtered
		else:
			push_warning("MapTestRunner: start_sequence '%s' not found, testing all" % start_sequence)

	# Build queue from sequences
	for spine_entry in sequences:
		var seq_name: String = spine_entry.get("name", "")
		if seq_name == "":
			continue

		# Load sequence JSON to get maps array
		var maps: Array = _load_sequence_maps(seq_name)
		if maps.is_empty():
			print("MapTestRunner: WARNING — No maps for sequence '%s', skipping" % seq_name)
			continue

		for map_name in maps:
			test_queue.append({
				"map_name": map_name,
				"sequence_name": seq_name,
				"is_lab_post": false,
			})

		# Optionally include lab_post map
		if include_lab_posts:
			var lab_post: String = spine_entry.get("lab_post", "")
			if lab_post != "":
				test_queue.append({
					"map_name": lab_post,
					"sequence_name": seq_name + " (lab_post)",
					"is_lab_post": true,
				})

	print("MapTestRunner: Built queue with %d maps" % test_queue.size())

func _load_sequence_maps(seq_name: String) -> Array:
	var seq_path := "res://commons/maps/sequences/%s.json" % seq_name
	if not FileAccess.file_exists(seq_path):
		return []
	var seq_file := FileAccess.open(seq_path, FileAccess.READ)
	var seq_json = JSON.parse_string(seq_file.get_as_text())
	seq_file.close()

	if seq_json == null or not seq_json.has("sequences"):
		return []

	var seq_dict: Dictionary = seq_json["sequences"]
	var data: Dictionary = {}
	if seq_dict.has(seq_name):
		data = seq_dict[seq_name]
	else:
		# Take the first entry
		for key in seq_dict:
			data = seq_dict[key]
			break

	return data.get("maps", [])

# ============================================================================
# TEST LOOP — nuke / reload / signal / validate
# ============================================================================
func _test_next_map() -> void:
	if current_test_index >= test_queue.size():
		_finish_tests()
		return

	var entry: Dictionary = test_queue[current_test_index]
	var map_name: String = entry.map_name
	var seq_name: String = entry.sequence_name

	# Update UI
	var progress_text := "[%d/%d] %s / %s" % [
		current_test_index + 1, test_queue.size(), seq_name, map_name]
	_set_status(progress_text)
	_set_detail("Loading...")
	if progress_bar:
		progress_bar.value = current_test_index

	# Record start metrics
	_test_start_time = Time.get_ticks_msec()
	_test_start_memory = Performance.get_monitor(Performance.MEMORY_STATIC)
	_map_ready = false
	_map_timed_out = false

	# Nuke previous map content
	_nuke_map_content()
	await get_tree().process_frame

	# Stop any lingering audio
	_stop_audio()

	# Signal-before-trigger pattern: connect BEFORE reload
	var _on_done := func(): _map_ready = true
	lab_grid_system.map_generation_complete.connect(_on_done, CONNECT_ONE_SHOT)

	# Start timeout timer
	if timeout_timer:
		timeout_timer.wait_time = timeout_seconds
		timeout_timer.start()

	# Trigger map load
	lab_grid_system.map_name = map_name
	lab_grid_system.reload_map = true

	# Wait for signal or timeout
	var wait_time: float = 0.0
	while not _map_ready and not _map_timed_out and wait_time < timeout_seconds + 1.0:
		await get_tree().create_timer(0.05).timeout
		wait_time += 0.05

	# Stop timeout timer
	if timeout_timer:
		timeout_timer.stop()

	# Disconnect signal if still connected
	if not _map_ready and lab_grid_system.map_generation_complete.is_connected(_on_done):
		lab_grid_system.map_generation_complete.disconnect(_on_done)

	# Let interactables finish _ready()
	await get_tree().process_frame
	await get_tree().process_frame

	# Stop auto-started audio
	_stop_audio()

	# Run validation
	if _map_timed_out:
		_record_timeout(entry)
	else:
		_validate_map(entry)

	# Optional screenshot
	if take_screenshots:
		await get_tree().process_frame
		_capture_screenshot(map_name)

	# Next map
	current_test_index += 1
	# Small delay between maps to let GC settle
	await get_tree().create_timer(0.1).timeout
	_test_next_map()

func _on_timeout() -> void:
	_map_timed_out = true

# ============================================================================
# VALIDATION — runtime checks per map
# ============================================================================
func _validate_map(entry: Dictionary) -> void:
	var map_name: String = entry.map_name
	var seq_name: String = entry.sequence_name
	var load_time: int = Time.get_ticks_msec() - _test_start_time
	var memory_now: float = Performance.get_monitor(Performance.MEMORY_STATIC)
	var memory_delta: float = memory_now - _test_start_memory

	var status := "PASS"
	var issues: Array[String] = []
	var warnings: Array[String] = []

	# Check 1: GridSystem load error
	if lab_grid_system.has_method("has_load_error") and lab_grid_system.has_load_error():
		status = "FAIL"
		var error_info: String = ""
		if lab_grid_system.has_method("get_error_info"):
			error_info = str(lab_grid_system.get_error_info())
		issues.append("load_error: %s" % error_info)

	# Check 2: Data component loaded
	var data_comp = lab_grid_system.get_node_or_null("GridDataComponent")
	if data_comp:
		if data_comp.has_method("is_data_loaded") and not data_comp.is_data_loaded():
			status = "FAIL"
			issues.append("data_component: data not loaded")
	else:
		status = "FAIL"
		issues.append("GridDataComponent missing")

	# Check 3: Essential components exist
	for comp_name in _GRID_ESSENTIAL:
		if comp_name == "CubeScene":
			continue  # CubeScene isn't a component
		var comp = lab_grid_system.get_node_or_null(comp_name)
		if not comp:
			if status != "FAIL":
				status = "WARN"
			warnings.append("missing component: %s" % comp_name)

	# Check 4: GridInteractablesComponent validation errors/warnings
	var interactables = lab_grid_system.get_node_or_null("GridInteractablesComponent")
	if interactables:
		if interactables.get("validation_errors"):
			var val_errors: Array = interactables.validation_errors
			if val_errors.size() > 0:
				status = "FAIL"
				for ve in val_errors:
					issues.append("validation_error: %s" % str(ve))

		if interactables.get("validation_warnings"):
			var val_warns: Array = interactables.validation_warnings
			if val_warns.size() > 0:
				if status == "PASS":
					status = "WARN"
				for vw in val_warns:
					warnings.append("validation_warning: %s" % str(vw))

	# Check 5: Interactable count vs expected
	var actual_count: int = 0
	var expected_count: int = _count_expected_interactables(map_name)
	if interactables and interactables.has_method("get_all_interactable_positions"):
		actual_count = interactables.get_all_interactable_positions().size()
	if expected_count > 0 and actual_count == 0:
		if status == "PASS":
			status = "WARN"
		warnings.append("expected %d interactables but found 0" % expected_count)
	elif expected_count > 0 and actual_count < expected_count:
		if status == "PASS":
			status = "WARN"
		warnings.append("expected %d interactables, found %d" % [expected_count, actual_count])

	# Check 6: Load time threshold
	if load_time > slow_threshold_ms:
		if status == "PASS":
			status = "WARN"
		warnings.append("slow load: %dms (threshold: %dms)" % [
			load_time, int(slow_threshold_ms)])

	# Record result
	var result := {
		"map_name": map_name,
		"sequence": seq_name,
		"is_lab_post": entry.is_lab_post,
		"status": status,
		"load_time_ms": load_time,
		"memory_mb": snapped(memory_now / 1048576.0, 0.1),
		"memory_delta_mb": snapped(memory_delta / 1048576.0, 0.1),
		"has_load_error": lab_grid_system.has_method("has_load_error") and lab_grid_system.has_load_error(),
		"interactable_count": actual_count,
		"expected_interactables": expected_count,
		"issues": issues,
		"warnings": warnings,
	}
	results.append(result)

	# Update counters
	match status:
		"PASS":
			pass_count += 1
		"WARN":
			warn_count += 1
		"FAIL":
			fail_count += 1

	# Console output
	var status_str := _colorize_status(status)
	var suffix := ""
	if issues.size() > 0:
		suffix = " -- %s" % issues[0]
	elif warnings.size() > 0:
		suffix = " -- %d warning(s)" % warnings.size()

	print("[%s/%d] %s  %s / %s (%dms)%s" % [
		str(current_test_index + 1).lpad(3),
		test_queue.size(),
		status_str,
		seq_name,
		map_name,
		load_time,
		suffix,
	])

	_set_detail("%s (%dms)" % [status, load_time])

func _record_timeout(entry: Dictionary) -> void:
	var map_name: String = entry.map_name
	var seq_name: String = entry.sequence_name

	var result := {
		"map_name": map_name,
		"sequence": seq_name,
		"is_lab_post": entry.is_lab_post,
		"status": "TIMEOUT",
		"load_time_ms": int(timeout_seconds * 1000),
		"memory_mb": snapped(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
		"memory_delta_mb": 0.0,
		"has_load_error": false,
		"interactable_count": 0,
		"expected_interactables": 0,
		"issues": ["timeout after %.1fs" % timeout_seconds],
		"warnings": [],
	}
	results.append(result)
	timeout_count += 1

	print("[%s/%d] TIMEOUT  %s / %s -- no signal after %.1fs" % [
		str(current_test_index + 1).lpad(3),
		test_queue.size(),
		seq_name,
		map_name,
		timeout_seconds,
	])

	_set_detail("TIMEOUT (%.1fs)" % timeout_seconds)

# ============================================================================
# EXPECTED INTERACTABLE COUNT — parse map JSON to count non-empty tokens
# ============================================================================
func _count_expected_interactables(map_name: String) -> int:
	var map_path := "res://commons/maps/%s/map_data.json" % map_name
	if not FileAccess.file_exists(map_path):
		# Try Lab/ prefix for lab_post maps
		map_path = "res://commons/maps/%s.json" % map_name
		if not FileAccess.file_exists(map_path):
			return 0

	var f := FileAccess.open(map_path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()

	if data == null:
		return 0

	var layers = data.get("layers", {})
	var interactables = layers.get("interactables", [])
	var count: int = 0
	for row in interactables:
		if row is Array:
			for token in row:
				if token is String and token.strip_edges() != "":
					count += 1
	return count

# ============================================================================
# CLEANUP — nuke all non-essential content (from CameraTourManager pattern)
# ============================================================================
func _take_snapshot() -> void:
	_root_snapshot.clear()
	for child in get_tree().root.get_children():
		_root_snapshot.append(child.name)
	print("MapTestRunner: Snapshot taken -- root: %d nodes" % _root_snapshot.size())

func _nuke_map_content() -> void:
	var removed: int = 0

	if lab_grid_system:
		for child in lab_grid_system.get_children():
			if child.name not in _GRID_ESSENTIAL:
				child.queue_free()
				removed += 1
		# Null out catalog refs
		if lab_grid_system.get("desktop_catalog"):
			lab_grid_system.desktop_catalog = null
		if lab_grid_system.get("artifact_spawn_manager"):
			lab_grid_system.artifact_spawn_manager = null

	# Destroy stray root nodes
	for child in get_tree().root.get_children():
		if child.name not in _root_snapshot:
			child.queue_free()
			removed += 1

	if removed > 0:
		print("MapTestRunner: Nuked %d nodes" % removed)

func _stop_audio() -> void:
	if not lab_grid_system:
		return
	var audio_comp = lab_grid_system.get_node_or_null("GridAudioComponent")
	if audio_comp and audio_comp.has_method("stop_ambient"):
		audio_comp.stop_ambient()

# ============================================================================
# SCREENSHOT CAPTURE
# ============================================================================
func _capture_screenshot(map_name: String) -> void:
	var image := get_viewport().get_texture().get_image()
	if image == null:
		return
	var dir_path := "user://map_test_screenshots/"
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	var safe_name := map_name.replace("/", "_").replace("\\", "_")
	var file_path := dir_path + safe_name + ".png"
	image.save_png(file_path)

# ============================================================================
# FINISH — console summary + JSON report
# ============================================================================
func _finish_tests() -> void:
	is_testing = false
	var total_time: float = Time.get_unix_time_from_system() - _run_start_time

	# Console summary
	var sep := "\n====== RESULTS ======"
	print(sep)
	print("PASS: %d | WARN: %d | FAIL: %d | TIMEOUT: %d" % [
		pass_count, warn_count, fail_count, timeout_count])
	print("Total: %.0fs | Avg: %dms" % [
		total_time,
		int(total_time * 1000.0 / maxf(results.size(), 1))])

	# Failures
	var failures: Array[Dictionary] = results.filter(func(r): return r.status == "FAIL")
	if failures.size() > 0:
		print("\nFAILURES:")
		for f in failures:
			var issue_str: String = f.issues[0] if f.issues.size() > 0 else "unknown"
			print("  %s / %s -- %s" % [f.sequence, f.map_name, issue_str])

	# Timeouts
	var timeouts: Array[Dictionary] = results.filter(func(r): return r.status == "TIMEOUT")
	if timeouts.size() > 0:
		print("\nTIMEOUTS:")
		for t in timeouts:
			print("  %s / %s -- %.1fs" % [t.sequence, t.map_name, timeout_seconds])

	# Warnings
	var warned: Array[Dictionary] = results.filter(func(r): return r.status == "WARN")
	if warned.size() > 0:
		print("\nWARNINGS (%d):" % warned.size())
		for w in warned:
			var warn_str: String = w.warnings[0] if w.warnings.size() > 0 else "unknown"
			print("  %s / %s -- %s" % [w.sequence, w.map_name, warn_str])

	# Slowest maps
	var sorted_by_time: Array[Dictionary] = results.duplicate()
	sorted_by_time.sort_custom(func(a, b): return a.load_time_ms > b.load_time_ms)
	print("\nSLOWEST:")
	for i in mini(5, sorted_by_time.size()):
		print("  %d. %s / %s -- %dms" % [
			i + 1,
			sorted_by_time[i].sequence,
			sorted_by_time[i].map_name,
			sorted_by_time[i].load_time_ms])

	# Save JSON report
	_save_json_report(total_time)

	print("\n=================================\n")

	# Update UI
	_set_status("DONE: %d PASS, %d WARN, %d FAIL, %d TIMEOUT" % [
		pass_count, warn_count, fail_count, timeout_count])
	_set_detail("Report saved to user://map_test_report.json")
	if progress_bar:
		progress_bar.value = progress_bar.max_value

func _save_json_report(total_time: float) -> void:
	var report := {
		"timestamp": Time.get_datetime_string_from_system(true),
		"test_mode": test_mode,
		"godot_version": Engine.get_version_info().get("string", "unknown"),
		"total_maps": results.size(),
		"passed": pass_count,
		"warnings": warn_count,
		"failed": fail_count,
		"timeouts": timeout_count,
		"total_time_seconds": snapped(total_time, 0.1),
		"timeout_threshold_seconds": timeout_seconds,
		"slow_threshold_ms": slow_threshold_ms,
		"results": results,
	}

	var report_path := "user://map_test_report.json"
	var f := FileAccess.open(report_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(report, "\t"))
		f.close()
		print("Report saved to: %s" % report_path)
	else:
		push_error("MapTestRunner: Failed to write report to %s" % report_path)

# ============================================================================
# UI HELPERS
# ============================================================================
func _set_status(text: String) -> void:
	if status_label:
		status_label.text = text

func _set_detail(text: String) -> void:
	if detail_label:
		detail_label.text = text

func _colorize_status(status: String) -> String:
	# Console doesn't support colors, but padding helps visual scanning
	match status:
		"PASS":
			return "PASS   "
		"WARN":
			return "WARN   "
		"FAIL":
			return "FAIL   "
		"TIMEOUT":
			return "TIMEOUT"
	return status

# ============================================================================
# INPUT — ESC to quit, R to restart
# ============================================================================
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	match event.keycode:
		KEY_ESCAPE:
			get_tree().quit()
		KEY_R:
			if not is_testing:
				# Reset and restart
				results.clear()
				pass_count = 0
				warn_count = 0
				fail_count = 0
				timeout_count = 0
				current_test_index = 0
				_start_tests()
