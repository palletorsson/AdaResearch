extends SceneTree

## Batch map screenshot runner using MapCatalogDesktop3D.
## Example:
## godot_console --path . --script res://commons/testing/catalog_batch_screenshot_runner.gd -- \
##   --sequence=primitives --max-maps=5 --out=user://catalog_map_screenshots

const CATALOG_SCENE_PATH: String = "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"
const SPINE_PATH: String = "res://commons/maps/curriculum_spine.json"

var _sequence_filter: String = ""
var _start_index: int = 0
var _max_maps: int = -1
var _timeout_seconds: float = 30.0
var _settle_seconds: float = 0.8
var _output_dir: String = "user://catalog_map_screenshots"
var _include_lab_posts: bool = false
var _camera_mode: int = 2  # 0=Static, 1=Iso, 2=Spin, 3=Player
var _hide_overlays: bool = true

var _map_queue: Array[String] = []
var _results: Array[Dictionary] = []

func _initialize() -> void:
	_parse_args()
	call_deferred("_run")

func _parse_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for raw_arg in args:
		var arg: String = String(raw_arg).strip_edges()
		if not arg.begins_with("--"):
			continue

		var eq_idx: int = arg.find("=")
		if eq_idx <= 2:
			continue

		var key: String = arg.substr(2, eq_idx - 2)
		var value: String = arg.substr(eq_idx + 1).strip_edges()

		match key:
			"sequence":
				_sequence_filter = value
			"start-index":
				if value.is_valid_int():
					_start_index = max(0, int(value))
			"max-maps":
				if value.is_valid_int():
					_max_maps = int(value)
			"timeout":
				if value.is_valid_float():
					_timeout_seconds = maxf(1.0, float(value))
			"settle":
				if value.is_valid_float():
					_settle_seconds = maxf(0.0, float(value))
			"out":
				if not value.is_empty():
					_output_dir = value
			"include-lab-posts":
				_include_lab_posts = _parse_bool(value, _include_lab_posts)
			"camera-mode":
				if value.is_valid_int():
					_camera_mode = clampi(int(value), 0, 3)
			"hide-overlays":
				_hide_overlays = _parse_bool(value, _hide_overlays)

func _parse_bool(value: String, fallback: bool) -> bool:
	var lowered: String = value.to_lower().strip_edges()
	if lowered in ["1", "true", "yes", "on"]:
		return true
	if lowered in ["0", "false", "no", "off"]:
		return false
	return fallback

func _run() -> void:
	var change_err: int = change_scene_to_file(CATALOG_SCENE_PATH)
	if change_err != OK:
		push_error("catalog_batch_screenshot_runner: Failed to load scene: %s" % CATALOG_SCENE_PATH)
		quit(1)
		return

	await process_frame
	await process_frame

	var catalog: Node = current_scene
	if catalog == null:
		push_error("catalog_batch_screenshot_runner: current_scene is null")
		quit(1)
		return

	if _hide_overlays:
		_hide_overlay_nodes(catalog)

	_build_queue()
	if _map_queue.is_empty():
		push_error("catalog_batch_screenshot_runner: No maps found for queue")
		quit(1)
		return

	print("catalog_batch_screenshot_runner: Queue size=%d start_index=%d max_maps=%d" % [
		_map_queue.size(), _start_index, _max_maps
	])

	var processed: int = 0
	var hard_stop: int = _map_queue.size()
	if _max_maps > 0:
		hard_stop = min(_map_queue.size(), _start_index + _max_maps)

	for i in range(_start_index, hard_stop):
		var map_name: String = _map_queue[i]
		var loaded_ok: bool = bool(catalog.call("load_map_fresh", map_name))
		if not loaded_ok:
			_results.append({
				"map": map_name,
				"status": "load_failed",
				"screenshot": ""
			})
			continue

		var ready_ok: bool = await _wait_for_map_ready(catalog, _timeout_seconds)
		if catalog.has_method("set_camera_mode"):
			catalog.call("set_camera_mode", _camera_mode)
		await process_frame
		await process_frame

		if _settle_seconds > 0.0:
			await create_timer(_settle_seconds).timeout
		await process_frame

		var shot_path: String = _save_screenshot(i + 1, map_name)
		_results.append({
			"map": map_name,
			"status": "ok" if ready_ok else "timeout",
			"screenshot": shot_path
		})

		processed += 1
		print("catalog_batch_screenshot_runner: [%d/%d] %s -> %s" % [
			processed, hard_stop - _start_index, map_name, shot_path
		])

	_save_report()
	quit(0)

func _hide_overlay_nodes(catalog: Node) -> void:
	var names: Array[String] = [
		"DesktopMapSwitcherOverlay",
		"MapDataEditorOverlay",
		"MapLayerEditorOverlay",
		"ProjectDashboardOverlay",
		"StatusLabel",
		"MapBrowser3D",
	]
	for node_name in names:
		var node: Node = catalog.get_node_or_null(node_name)
		if node == null:
			continue
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
		elif node is Node3D:
			(node as Node3D).visible = false
		elif node is CanvasItem:
			(node as CanvasItem).visible = false

func _wait_for_map_ready(catalog: Node, timeout_seconds: float) -> bool:
	var grid_system: Node = catalog.get("_grid_system")
	if grid_system == null:
		var fallback_wait: float = minf(timeout_seconds, 2.0)
		await create_timer(fallback_wait).timeout
		return false

	var done: bool = false
	var on_done := func() -> void:
		done = true

	if grid_system.has_signal("map_generation_complete"):
		grid_system.map_generation_complete.connect(on_done, CONNECT_ONE_SHOT)

	var elapsed: float = 0.0
	while elapsed < timeout_seconds and not done:
		if grid_system.has_method("is_map_ready") and bool(grid_system.call("is_map_ready")):
			done = true
			break
		await create_timer(0.1).timeout
		elapsed += 0.1

	if not done and grid_system.has_signal("map_generation_complete"):
		if grid_system.map_generation_complete.is_connected(on_done):
			grid_system.map_generation_complete.disconnect(on_done)

	return done

func _save_screenshot(index: int, map_name: String) -> String:
	var image: Image = root.get_texture().get_image()
	if image == null:
		return ""

	var absolute_dir: String = ProjectSettings.globalize_path(_output_dir)
	if not DirAccess.dir_exists_absolute(absolute_dir):
		DirAccess.make_dir_recursive_absolute(absolute_dir)

	var safe_name: String = map_name.replace("/", "_").replace("\\", "_")
	var file_name: String = "%03d_%s.png" % [index, safe_name]
	var absolute_path: String = absolute_dir.path_join(file_name)
	var save_err: int = image.save_png(absolute_path)
	if save_err != OK:
		return ""
	return absolute_path

func _build_queue() -> void:
	_map_queue.clear()

	if not FileAccess.file_exists(SPINE_PATH):
		return

	var spine_file: FileAccess = FileAccess.open(SPINE_PATH, FileAccess.READ)
	if spine_file == null:
		return

	var spine_parsed: Variant = JSON.parse_string(spine_file.get_as_text())
	spine_file.close()
	if spine_parsed == null or not (spine_parsed is Dictionary):
		return

	var spine_root: Dictionary = spine_parsed as Dictionary
	var spine_data: Dictionary = spine_root.get("spine", {})
	var sequences_variant: Variant = spine_data.get("sequences", [])
	if not (sequences_variant is Array):
		return

	var sequences: Array = sequences_variant as Array
	sequences.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("order", 99999)) < int(b.get("order", 99999))
	)

	for sequence_entry_variant in sequences:
		if not (sequence_entry_variant is Dictionary):
			continue
		var sequence_entry: Dictionary = sequence_entry_variant as Dictionary
		var sequence_name: String = str(sequence_entry.get("name", "")).strip_edges()
		if sequence_name.is_empty():
			continue
		if not _sequence_filter.is_empty() and sequence_name != _sequence_filter:
			continue

		var maps: Array[String] = _load_sequence_maps(sequence_name)
		for map_name in maps:
			_map_queue.append(map_name)

		if _include_lab_posts:
			var lab_post: String = str(sequence_entry.get("lab_post", "")).strip_edges()
			if not lab_post.is_empty():
				_map_queue.append(lab_post)

func _load_sequence_maps(sequence_name: String) -> Array[String]:
	var out: Array[String] = []
	var seq_path: String = "res://commons/maps/sequences/%s.json" % sequence_name
	if not FileAccess.file_exists(seq_path):
		return out

	var seq_file: FileAccess = FileAccess.open(seq_path, FileAccess.READ)
	if seq_file == null:
		return out

	var parsed: Variant = JSON.parse_string(seq_file.get_as_text())
	seq_file.close()
	if parsed == null or not (parsed is Dictionary):
		return out

	var seq_root: Dictionary = parsed as Dictionary
	var seq_dict: Dictionary = seq_root.get("sequences", {})
	if seq_dict.is_empty():
		return out

	var seq_data: Dictionary = {}
	if seq_dict.has(sequence_name):
		seq_data = seq_dict.get(sequence_name, {})
	else:
		for key in seq_dict.keys():
			var candidate: Variant = seq_dict.get(key)
			if candidate is Dictionary:
				seq_data = candidate as Dictionary
				break

	var maps_variant: Variant = seq_data.get("maps", [])
	if maps_variant is Array:
		for item in maps_variant:
			var map_name: String = str(item).strip_edges()
			if not map_name.is_empty():
				out.append(map_name)

	return out

func _save_report() -> void:
	var report: Dictionary = {
		"timestamp": Time.get_datetime_string_from_system(true),
		"scene": CATALOG_SCENE_PATH,
		"sequence_filter": _sequence_filter,
		"start_index": _start_index,
		"max_maps": _max_maps,
		"timeout_seconds": _timeout_seconds,
		"output_dir": _output_dir,
		"count": _results.size(),
		"results": _results
	}

	var report_path: String = "user://catalog_map_screenshot_report.json"
	var file: FileAccess = FileAccess.open(report_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
		print("catalog_batch_screenshot_runner: Report saved -> %s" % ProjectSettings.globalize_path(report_path))
