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
	# Load the map via the catalog scene (same path map-mode multi_angle uses).
	var catalog_scene: PackedScene = load(MAP_CATALOG_SCENE)
	if catalog_scene == null:
		push_error("capture_first_person: could not load %s" % MAP_CATALOG_SCENE)
		quit(1)
		return
	var catalog: Node = catalog_scene.instantiate()
	get_root().add_child(catalog)
	if catalog.has_method("set_target_map"):
		catalog.call("set_target_map", _target)
	elif "target_map_name" in catalog:
		catalog.set("target_map_name", _target)

	# Disable any existing cameras + overlay UI the catalog instantiated.
	# The MapCatalog comes with a desktop UI (map browser sidebar, status
	# label, comment writer panel, etc.) that would otherwise occupy
	# half the viewport. Hide those — the player wouldn't see them.
	await create_timer(0.4).timeout
	await process_frame
	_disable_cameras_recursive(catalog)
	_hide_overlay_nodes(catalog)

	# Camera at player eye position, rotated by yaw+pitch.
	var cam := Camera3D.new()
	cam.fov = _fov
	cam.near = 0.05
	cam.far = 500.0
	cam.current = true
	get_root().add_child(cam)

	# Order matters: yaw first (around world Y), then pitch (around
	# local X). Result is a typical FPS look-direction:
	#   forward = -Z after rotation; up = +Y.
	cam.global_position = _position
	cam.rotation = Vector3.ZERO
	cam.rotate_y(deg_to_rad(_yaw_deg))
	cam.rotate_object_local(Vector3.RIGHT, deg_to_rad(_pitch_deg))

	# Wait for the map to render (foliage / shaders / lights etc.).
	await create_timer(_wait_seconds).timeout
	await process_frame
	await process_frame

	var img: Image = root.get_texture().get_image()
	if img == null:
		push_error("capture_first_person: viewport texture was null")
		quit(2)
		return

	# Save PNG + report.
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


func _disable_cameras_recursive(node: Node) -> void:
	if node is Camera3D:
		(node as Camera3D).current = false
	for child in node.get_children():
		_disable_cameras_recursive(child)


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
