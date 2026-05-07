extends SceneTree

## capture_first_person.gd
##
## Single-shot first-person screenshot of a map at an exact camera
## position + rotation + FOV. Companion to capture_multi_angle.gd —
## that one renders 4 orbit angles around the artifact's AABB; this
## one places the camera AS the player and captures what they would
## see.
##
## Used by the encyclopedia's /editor Capture tab (first-person mode):
## the user aims a scene camera in Three.js, clicks capture, the API
## passes those camera params here, this script reproduces the view in
## Godot at full fidelity.
##
## Run:
##   godot --xr-mode off --no-window \
##     --script res://commons/testing/capture_first_person.gd -- \
##     --target=<MapName> \
##     --position=x,y,z \
##     --rotation=yaw_deg,pitch_deg \
##     --fov=75 \
##     --out=user://fp_shot
##
## Output:
##   <out>/<target>/first_person.png
##   <out>/<target>/capture_report.json   (echoes inputs + what landed)

const MAP_CATALOG_SCENE: String = "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"

var _target: String = ""
var _output_dir: String = "user://fp_shots"
var _position: Vector3 = Vector3(0.0, 1.6, 0.0)   # player eye-height default
var _yaw_deg: float = 0.0
var _pitch_deg: float = 0.0
var _fov: float = 75.0
var _wait_seconds: float = 3.0


func _initialize() -> void:
	_parse_args()
	if _target.is_empty():
		push_error("capture_first_person: --target=<map name> required")
		quit(1)
		return
	call_deferred("_run")


func _parse_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for raw in args:
		var arg: String = String(raw).strip_edges()
		if not arg.begins_with("--"):
			continue
		var eq: int = arg.find("=")
		if eq <= 2:
			continue
		var key: String = arg.substr(2, eq - 2)
		var value: String = arg.substr(eq + 1).strip_edges()
		match key:
			"target":
				_target = value
			"out":
				if not value.is_empty():
					_output_dir = value
			"wait":
				if value.is_valid_float():
					_wait_seconds = maxf(0.5, float(value))
			"fov":
				if value.is_valid_float():
					_fov = clampf(float(value), 10.0, 170.0)
			"position":
				var p: PackedStringArray = value.split(",")
				if p.size() == 3 and p[0].is_valid_float() and p[1].is_valid_float() and p[2].is_valid_float():
					_position = Vector3(float(p[0]), float(p[1]), float(p[2]))
			"rotation":
				# yaw,pitch (degrees). Yaw rotates around Y (heading);
				# pitch rotates around the local X axis (look up/down).
				var r: PackedStringArray = value.split(",")
				if r.size() >= 1 and r[0].is_valid_float():
					_yaw_deg = float(r[0])
				if r.size() >= 2 and r[1].is_valid_float():
					_pitch_deg = float(r[1])


func _run() -> void:
	# Use change_scene_to_file (not instantiate + add_child) so the
	# catalog's autoloads / readiness wiring fires properly. Mirrors
	# capture_multi_angle.gd::_run_map_capture.
	print("capture_first_person: loading catalog + map '%s'..." % _target)
	var change_err: int = change_scene_to_file(MAP_CATALOG_SCENE)
	if change_err != OK:
		push_error("capture_first_person: failed to load MapCatalog scene")
		quit(1)
		return
	await process_frame
	await process_frame

	var catalog: Node = current_scene
	if catalog == null:
		push_error("capture_first_person: current_scene is null")
		quit(1)
		return

	# Hide overlay UI so the capture shows only the rendered map.
	_hide_overlay_nodes(catalog)

	# Ask the catalog to actually generate the map. This is the missing
	# step that turns a green void into a real scene.
	var loaded_ok: bool = bool(catalog.call("load_map_fresh", _target))
	if not loaded_ok:
		push_error("capture_first_person: failed to load map '%s'" % _target)
		quit(1)
		return

	# Wait for grid generation to complete (signals + is_map_ready poll).
	var ready_ok: bool = await _wait_for_map_ready(catalog, 30.0)
	if not ready_ok:
		push_warning("capture_first_person: map ready timeout, proceeding anyway")

	# Settle frames for shaders / lights / foliage.
	await create_timer(_wait_seconds).timeout
	await process_frame
	await process_frame

	# Reuse the catalog's preview camera instead of creating our own.
	# That way we inherit the catalog's environment + lighting + projection
	# defaults; we just override transform + fov to match the editor's
	# scene-camera widget.
	var camera: Camera3D = catalog.get("_preview_camera") if "_preview_camera" in catalog else null
	if camera == null:
		# Last-resort: walk the tree for any Camera3D and reuse it.
		camera = _find_first_camera(catalog)
	if camera == null:
		push_error("capture_first_person: could not find a Camera3D in the catalog")
		quit(1)
		return

	# Stop the catalog's auto-spin so the camera stays where we put it.
	if catalog.has_method("set_camera_mode"):
		catalog.call("set_camera_mode", 0)  # STATIC
	if "_spin_speed" in catalog:
		catalog.set("_spin_speed", 0.0)
	await process_frame
	# Belt-and-braces: re-set after a frame to clobber any deferred default.
	if catalog.has_method("set_camera_mode"):
		catalog.call("set_camera_mode", 0)
	if "_spin_speed" in catalog:
		catalog.set("_spin_speed", 0.0)

	# Apply the requested camera config.
	camera.fov = _fov
	camera.global_position = _position
	camera.rotation = Vector3.ZERO
	camera.rotate_y(deg_to_rad(_yaw_deg))
	camera.rotate_object_local(Vector3.RIGHT, deg_to_rad(_pitch_deg))
	camera.current = true

	# Final settle, then snapshot.
	await process_frame
	await process_frame
	await create_timer(0.4).timeout
	await process_frame

	var img: Image = root.get_texture().get_image()
	if img == null:
		push_error("capture_first_person: viewport texture was null")
		quit(2)
		return

	var folder: String = _output_dir.path_join(_target)
	var abs_folder: String = ProjectSettings.globalize_path(folder)
	if not DirAccess.dir_exists_absolute(abs_folder):
		DirAccess.make_dir_recursive_absolute(abs_folder)
	var shot_path: String = abs_folder.path_join("first_person.png")
	var save_err: int = img.save_png(shot_path)
	if save_err != OK:
		push_error("capture_first_person: save failed (err=%d)" % save_err)
		quit(3)
		return
	print("capture_first_person: saved %s" % shot_path)

	var report: Dictionary = {
		"timestamp": Time.get_datetime_string_from_system(true),
		"target": _target,
		"output_dir": _output_dir,
		"position": [_position.x, _position.y, _position.z],
		"rotation_deg": [_yaw_deg, _pitch_deg],
		"fov": _fov,
		"shot_path": shot_path,
	}
	var report_path: String = abs_folder.path_join("capture_report.json")
	var f: FileAccess = FileAccess.open(report_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(report, "\t"))
		f.close()
		print("capture_first_person: report -> %s" % report_path)

	quit(0)


# Hide MapCatalog overlay UI so first-person captures show ONLY the
# map view — what the player would actually see, not the desktop
# editor chrome. List mirrors capture_multi_angle.gd::_hide_overlay_nodes.
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


# Walk the scene tree for any Camera3D — last-resort fallback if
# the catalog's _preview_camera property is absent.
func _find_first_camera(node: Node) -> Camera3D:
	if node is Camera3D:
		return node as Camera3D
	for child in node.get_children():
		var found: Camera3D = _find_first_camera(child)
		if found:
			return found
	return null


# Mirror of capture_multi_angle.gd's helper — wait for the catalog's
# grid system to signal map_generation_complete (or for is_map_ready
# to return true). Without this, captures fire before the map renders.
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
