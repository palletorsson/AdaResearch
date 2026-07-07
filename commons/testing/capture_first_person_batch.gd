extends SceneTree

## capture_first_person_batch.gd
##
## Multi-shot single-map FPV. Loads map ONCE via MapCatalogDesktop3D,
## then renders N captures at different (position, rotation, fov) per
## shot. Companion to capture_first_person.gd (single-shot) — same
## visual pipeline (real biome / lighting / overlays hidden), but
## avoids per-capture Godot startup + map-load cost.
##
## Config JSON shape:
##   {
##     "map": "Demo_Catalyst_Arc",
##     "wait": 3.0,
##     "shots": [
##       {
##         "name": "00_foe",
##         "position": [0.25, 1.0, 0.93],
##         "rotation": [180, -27],   // [yaw_deg, pitch_deg]
##         "fov": 60
##       },
##       ...
##     ]
##   }
##
## Output:
##   <out>/<map>/<shot.name>.png  per shot
##   <out>/<map>/batch_report.json
##
## Run:
##   godot --xr-mode off --no-window \
##     --script res://commons/testing/capture_first_person_batch.gd -- \
##     --config=<path-to-json> --out=user://fp_batch

const MAP_CATALOG_SCENE: String = "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"

var _config_path: String = ""
var _output_dir: String = "user://fp_batch"
var _wait_seconds: float = 3.0


func _initialize() -> void:
	_parse_args()
	if _config_path.is_empty():
		push_error("capture_first_person_batch: --config=<path> required")
		quit(1)
		return
	call_deferred("_run")


func _parse_args() -> void:
	for raw in OS.get_cmdline_user_args():
		var arg: String = String(raw).strip_edges()
		if not arg.begins_with("--"):
			continue
		var eq: int = arg.find("=")
		if eq <= 2:
			continue
		var key: String = arg.substr(2, eq - 2)
		var value: String = arg.substr(eq + 1).strip_edges()
		match key:
			"config":
				_config_path = value
			"out":
				if not value.is_empty():
					_output_dir = value
			"wait":
				if value.is_valid_float():
					_wait_seconds = maxf(0.5, float(value))


func _run() -> void:
	# Read config
	var cfg_file: FileAccess = FileAccess.open(_config_path, FileAccess.READ)
	if cfg_file == null:
		push_error("config not found: " + _config_path)
		quit(1)
		return
	var cfg_text: String = cfg_file.get_as_text()
	cfg_file.close()
	var cfg = JSON.parse_string(cfg_text)
	if not (cfg is Dictionary):
		push_error("config not a dictionary")
		quit(1)
		return

	var target: String = String(cfg.get("map", ""))
	if target.is_empty():
		push_error("config missing 'map'")
		quit(1)
		return

	var shots: Array = cfg.get("shots", [])
	if shots.is_empty():
		push_error("config has no shots")
		quit(1)
		return

	if cfg.has("wait"):
		_wait_seconds = float(cfg["wait"])

	print("capture_first_person_batch: target=%s shots=%d" % [target, shots.size()])

	# Load catalog scene + map
	var err: int = change_scene_to_file(MAP_CATALOG_SCENE)
	if err != OK:
		push_error("failed to load catalog scene")
		quit(1)
		return
	await process_frame
	await process_frame

	var catalog: Node = current_scene
	if catalog == null:
		push_error("current_scene is null")
		quit(1)
		return

	_hide_overlay_nodes(catalog)

	var loaded_ok: bool = bool(catalog.call("load_map_fresh", target))
	if not loaded_ok:
		push_error("load_map_fresh failed for '%s'" % target)
		quit(1)
		return

	var ready_ok: bool = await _wait_for_map_ready(catalog, 30.0)
	if not ready_ok:
		push_warning("map ready timeout, proceeding")

	# Let shaders / foliage / lights settle.
	await create_timer(_wait_seconds).timeout
	await process_frame
	await process_frame

	# Get the camera. Re-used for every shot.
	var camera: Camera3D = catalog.get("_preview_camera") if "_preview_camera" in catalog else null
	if camera == null:
		camera = _find_first_camera(catalog)
	if camera == null:
		push_error("could not find a Camera3D in the catalog")
		quit(1)
		return

	# Stop the catalog's auto-spin so our positions stick.
	if catalog.has_method("set_camera_mode"):
		catalog.call("set_camera_mode", 0)
	if "_spin_speed" in catalog:
		catalog.set("_spin_speed", 0.0)
	await process_frame
	if catalog.has_method("set_camera_mode"):
		catalog.call("set_camera_mode", 0)
	if "_spin_speed" in catalog:
		catalog.set("_spin_speed", 0.0)
	camera.current = true

	# Make sure output directory exists.
	var folder: String = _output_dir.path_join(target)
	var abs_folder: String = ProjectSettings.globalize_path(folder)
	if not DirAccess.dir_exists_absolute(abs_folder):
		DirAccess.make_dir_recursive_absolute(abs_folder)

	var saved: Array = []

	# Iterate shots — set camera transform, snap, save.
	for i in range(shots.size()):
		var shot = shots[i]
		if not (shot is Dictionary):
			continue
		var shot_dict: Dictionary = shot
		var shot_name: String = String(shot_dict.get("name", "shot_%d" % i))
		var position_arr: Array = shot_dict.get("position", [0.0, 1.6, 0.0])
		var rotation_arr: Array = shot_dict.get("rotation", [0.0, 0.0])
		var fov_val: float = float(shot_dict.get("fov", 75.0))

		if position_arr.size() < 3:
			push_warning("shot %s: position missing components — skipping" % shot_name)
			continue
		var px: float = float(position_arr[0])
		var py: float = float(position_arr[1])
		var pz: float = float(position_arr[2])
		var yaw_deg: float = 0.0
		var pitch_deg: float = 0.0
		if rotation_arr.size() >= 1:
			yaw_deg = float(rotation_arr[0])
		if rotation_arr.size() >= 2:
			pitch_deg = float(rotation_arr[1])

		camera.fov = clampf(fov_val, 10.0, 170.0)
		camera.global_position = Vector3(px, py, pz)
		camera.rotation = Vector3.ZERO
		camera.rotate_y(deg_to_rad(yaw_deg))
		camera.rotate_object_local(Vector3.RIGHT, deg_to_rad(pitch_deg))

		# Settle for this shot — short, since the map is already built.
		await process_frame
		await process_frame
		await create_timer(0.3).timeout
		await process_frame

		var img: Image = root.get_texture().get_image()
		if img == null:
			push_warning("shot %s: null image" % shot_name)
			continue
		var shot_path: String = abs_folder.path_join(shot_name + ".png")
		var save_err: int = img.save_png(shot_path)
		if save_err != OK:
			push_warning("shot %s: save failed err=%d" % [shot_name, save_err])
			continue
		saved.append({
			"name": shot_name,
			"path": shot_path,
			"position": [px, py, pz],
			"rotation_deg": [yaw_deg, pitch_deg],
			"fov": camera.fov,
		})
		print("capture_first_person_batch: [%d/%d] saved %s" % [i + 1, shots.size(), shot_path])

	# Write report
	var report := {
		"timestamp": Time.get_datetime_string_from_system(true),
		"target": target,
		"shot_count": shots.size(),
		"saved_count": saved.size(),
		"saved": saved,
	}
	var report_path: String = abs_folder.path_join("batch_report.json")
	var rf: FileAccess = FileAccess.open(report_path, FileAccess.WRITE)
	if rf:
		rf.store_string(JSON.stringify(report, "\t"))
		rf.close()
		print("capture_first_person_batch: report -> %s" % report_path)

	print("capture_first_person_batch: done %d/%d shots saved" % [saved.size(), shots.size()])
	quit(0)


# Hide MapCatalog overlay UI so first-person captures show only the map view.
func _hide_overlay_nodes(catalog: Node) -> void:
	var names: Array[String] = [
		"DesktopMapSwitcherOverlay",
		"MapDataEditorOverlay",
		"MapLayerEditorOverlay",
		"ProjectDashboardOverlay",
		"StatusLabel",
		"MapBrowser3D",
		"HelpLabel",
	]
	for n in names:
		var node: Node = catalog.get_node_or_null(n)
		if node == null:
			continue
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
		elif node is Node3D:
			(node as Node3D).visible = false
		elif node is CanvasItem:
			(node as CanvasItem).visible = false


func _find_first_camera(node: Node) -> Camera3D:
	if node is Camera3D:
		return node as Camera3D
	for child in node.get_children():
		var found: Camera3D = _find_first_camera(child)
		if found:
			return found
	return null


func _wait_for_map_ready(catalog: Node, timeout_seconds: float) -> bool:
	var grid_system: Node = catalog.get("_grid_system") if "_grid_system" in catalog else null
	if grid_system == null:
		await create_timer(minf(timeout_seconds, 2.0)).timeout
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
