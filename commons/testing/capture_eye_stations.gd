extends SceneTree

## Eye shots at ARBITRARY grid stations — the occupant pass's own findings, seen.
##
## capture_multi_angle.gd renders a map from OUTSIDE (iso / top / front). This
## one stands INSIDE it: the camera goes to eye height on a named grid cell,
## facing a named direction, at the wide FOV a body actually has. That is the
## difference between judging a position from the plan and judging it from
## where the occupant stands.
##
## Stations come from `tools/walk_polish.py --shots`, which writes
## {cell, facing, y, tag, why} per finding — so the pass says "this position is
## dull" and this script produces the picture that confirms or refutes it.
##
## Usage:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_eye_stations.gd -- \
##     --map=Thread_Gate --stations=user://eye_stations.json \
##     --outdir=user://eye_shots
##
## FACING, not yaw. The station file gives a grid direction (dx, dz). A camera
## at rotation_degrees.y = t looks down (-sin t, 0, -cos t), so the yaw is
## atan2(-dx, -dz) — the grid's own prop-rotation convention plus 180 deg. The
## first version of this script trusted a yaw computed on the Python side and
## every shot faced the wrong way; the conversion belongs where the camera is.

const MAP_CATALOG_SCENE: String = "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"
const PRINCIPLES: String = "res://commons/data/museum_principles.json"
const FOV_FALLBACK: float = 90.0
const EYE_FALLBACK: float = 1.65      # a standing body, not a drone

## The body this camera stands as, read from the Vitruvian block of
## museum_principles.json. That block cites THIS FILE as the source of both
## numbers, which was true when it was written and would quietly stop being
## true the moment either side moved. One body, one place to change it: the
## table is the truth and the tools read it. Falls back to the literals so a
## missing canon file degrades to the old behaviour rather than to no camera.
static func _body(key: String, fallback: float) -> float:
	var text: String = FileAccess.get_file_as_string(PRINCIPLES)
	if text.is_empty():
		return fallback
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return fallback
	var vitruvian: Variant = (parsed as Dictionary).get("vitruvian", {})
	if typeof(vitruvian) != TYPE_DICTIONARY:
		return fallback
	var entry: Variant = (vitruvian as Dictionary).get(key, null)
	if typeof(entry) != TYPE_DICTIONARY:
		return fallback
	return float((entry as Dictionary).get("value", fallback))

var _map_name: String = ""
var _stations_path: String = ""
var _outdir: String = "user://eye_shots"
var _wait_seconds: float = 3.0
var _settle: float = 0.35
var _fov: float = FOV_FALLBACK
var _eye: float = EYE_FALLBACK


func _initialize() -> void:
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
			"map": _map_name = value
			"stations": _stations_path = value
			"outdir": _outdir = value
			"wait":
				if value.is_valid_float():
					_wait_seconds = maxf(0.5, float(value))
			"settle":
				if value.is_valid_float():
					_settle = maxf(0.1, float(value))
	if _map_name.is_empty() or _stations_path.is_empty():
		push_error("capture_eye_stations: --map and --stations are required")
		quit(1)
		return
	_fov = _body("fov_deg", FOV_FALLBACK)
	_eye = _body("eye_height_m", EYE_FALLBACK)
	call_deferred("_run")


func _load_stations() -> Array:
	var text: String = FileAccess.get_file_as_string(_stations_path)
	if text.is_empty():
		push_error("capture_eye_stations: cannot read %s" % _stations_path)
		return []
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("capture_eye_stations: station file is not an object")
		return []
	var arr: Variant = (parsed as Dictionary).get("stations", [])
	return arr if typeof(arr) == TYPE_ARRAY else []


func _run() -> void:
	var stations: Array = _load_stations()
	if stations.is_empty():
		push_error("capture_eye_stations: no stations in %s" % _stations_path)
		quit(1)
		return

	if change_scene_to_file(MAP_CATALOG_SCENE) != OK:
		push_error("capture_eye_stations: cannot load the map catalog")
		quit(1)
		return
	await process_frame
	await process_frame

	var catalog: Node = current_scene
	if catalog == null:
		push_error("capture_eye_stations: current_scene is null")
		quit(1)
		return

	# The desktop chrome (map list, comment writer, grade panel) renders over
	# half the frame. An eye shot is worthless with a UI in front of the eye.
	_hide_overlays(catalog)

	# load_map_fresh is the catalog's real loader. The first version called
	# load_map/switch_to_map on a lab scene, silently kept the default map, and
	# produced 25 shots of Point_One labelled Track_Symmetry.
	if not bool(catalog.call("load_map_fresh", _map_name)):
		push_error("capture_eye_stations: failed to load map '%s'" % _map_name)
		quit(1)
		return
	await _wait_for_map_ready(catalog, 30.0)
	await create_timer(_wait_seconds).timeout
	_hide_overlays(catalog)

	var camera: Camera3D = catalog.get("_preview_camera") if "_preview_camera" in catalog else null
	if camera == null:
		push_error("capture_eye_stations: no preview camera")
		quit(1)
		return

	# Stop the catalog spinning its camera, twice — the deferred default spin
	# re-arms after a frame and would drag every station off its mark.
	for _i in range(2):
		if catalog.has_method("set_camera_mode"):
			catalog.call("set_camera_mode", 0)   # STATIC
		if "_spin_speed" in catalog:
			catalog.set("_spin_speed", 0.0)
		await process_frame
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = _fov
	camera.current = true

	var total: float = _cell_pitch(catalog)
	var absolute_out: String = ProjectSettings.globalize_path(_outdir)
	DirAccess.make_dir_recursive_absolute(absolute_out)

	var report: Array = []
	for st in stations:
		var d: Dictionary = st
		var cell: Array = d.get("cell", [0, 0])
		var facing: Array = d.get("facing", [0, 1])
		var tag: String = str(d.get("tag", "station"))
		var fx: float = float(facing[0])
		var fz: float = float(facing[1]) if facing.size() > 1 else 1.0
		if is_zero_approx(fx) and is_zero_approx(fz):
			fz = 1.0
		var yaw: float = rad_to_deg(atan2(-fx, -fz))
		# Floor top of the stack, the same seat GridCommon gives a prop.
		var stack: int = int(d.get("y", 1))
		var floor_y: float = 0.0 if stack <= 0 else float(stack - 1) * total + 0.5
		camera.global_position = Vector3(float(cell[0]) * total,
			floor_y + _eye, float(cell[1]) * total)
		camera.rotation_degrees = Vector3(float(d.get("pitch", -4.0)), yaw, 0.0)

		await create_timer(_settle).timeout
		await process_frame
		await process_frame

		var img: Image = root.get_texture().get_image()
		if img == null:
			push_warning("capture_eye_stations: no frame for %s" % tag)
			continue
		var file_name: String = "%s_%s.png" % [_map_name, tag]
		if img.save_png(absolute_out.path_join(file_name)) != OK:
			push_warning("capture_eye_stations: could not save %s" % file_name)
			continue
		report.append({"tag": tag, "cell": cell, "facing": facing, "yaw": yaw,
			"file": file_name, "why": d.get("why", "")})
		print("capture_eye_stations: %s @ (%s,%s) facing (%s,%s) yaw %.0f" % [
			tag, cell[0], cell[1], facing[0], facing[1], yaw])

	var f: FileAccess = FileAccess.open(
		absolute_out.path_join("%s_stations.json" % _map_name), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"map": _map_name, "fov": _fov,
			"eye_height": _eye, "shots": report}, "\t"))
		f.close()
	print("capture_eye_stations: %d/%d shots -> %s" % [report.size(), stations.size(), absolute_out])
	quit(0)


## Cell pitch in world units — cube_size + gutter, the same total GridCommon
## multiplies a cell index by. Reading it from the live grid means a map with a
## non-default cube size still puts the eye in the right place.
func _cell_pitch(catalog: Node) -> float:
	var grid: Node = catalog.get("_grid_system") if "_grid_system" in catalog else null
	if grid == null:
		return 1.0
	var cube: float = float(grid.get("cube_size")) if "cube_size" in grid else 1.0
	var gutter: float = float(grid.get("gutter")) if "gutter" in grid else 0.0
	return maxf(0.1, cube + gutter)


func _hide_overlays(catalog: Node) -> void:
	for node_name in ["DesktopMapSwitcherOverlay", "MapDataEditorOverlay",
			"MapLayerEditorOverlay", "ProjectDashboardOverlay", "StatusLabel",
			"MapBrowser3D"]:
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
	var grid: Node = catalog.get("_grid_system") if "_grid_system" in catalog else null
	if grid == null:
		await create_timer(minf(timeout_seconds, 2.0)).timeout
		return false
	var elapsed: float = 0.0
	while elapsed < timeout_seconds:
		if grid.has_method("is_map_ready") and bool(grid.call("is_map_ready")):
			return true
		await create_timer(0.1).timeout
		elapsed += 0.1
	return false
