## Capture a first-person view from inside a map's spawn point looking down the corridor.
## Usage: --script res://commons/testing/capture_entrance.gd -- --target=MapName
extends SceneTree

const MAP_CATALOG_SCENE := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"

var _target: String = ""
var _out_dir: String = ""

func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--target="):
			_target = arg.substr(9)
	if _target == "":
		push_error("capture_entrance: --target=MapName required")
		quit(1)
		return
	_out_dir = "user://multi_shots/%s" % _target
	DirAccess.make_dir_recursive_absolute(_out_dir)
	call_deferred("_run")

func _run() -> void:
	var change_err: int = change_scene_to_file(MAP_CATALOG_SCENE)
	if change_err != OK:
		quit(1)
		return

	await process_frame
	await process_frame

	var catalog: Node = current_scene
	if catalog == null:
		quit(1)
		return

	# Hide ALL overlays/UI — same as multi_angle
	var hide_names: Array[String] = [
		"DesktopMapSwitcherOverlay", "MapDataEditorOverlay",
		"MapLayerEditorOverlay", "ProjectDashboardOverlay",
		"StatusLabel", "MapBrowser3D",
	]
	for node_name in hide_names:
		var node: Node = catalog.get_node_or_null(node_name)
		if node == null:
			continue
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
		elif node is Node3D:
			(node as Node3D).visible = false
		elif node is CanvasItem:
			(node as CanvasItem).visible = false

	# Also hide any remaining CanvasLayer children
	for child in catalog.get_children():
		if child is CanvasLayer:
			child.visible = false
		if child is Control:
			child.visible = false

	var loaded_ok: bool = bool(catalog.call("load_map_fresh", _target))
	if not loaded_ok:
		quit(1)
		return

	var ready_ok: bool = await _wait_for_map_ready(catalog, 30.0)
	if not ready_ok:
		print("capture_entrance: Map ready timeout, proceeding anyway")

	await create_timer(3.0).timeout
	await process_frame
	await process_frame

	var camera: Camera3D = catalog.get("_preview_camera") if "_preview_camera" in catalog else null
	if camera == null:
		camera = _find_camera(catalog)
	if camera == null:
		push_error("capture_entrance: No camera found")
		quit(1)
		return

	# Stop spin
	if catalog.has_method("set_camera_mode"):
		catalog.call("set_camera_mode", 0)

	# Get orbit center to know where the map is
	var orbit_center: Vector3 = catalog.get("_orbit_center") if "_orbit_center" in catalog else Vector3.ZERO

	# Entrance: at spawn position, eye height (1.6m), looking down Z corridor
	camera.global_position = Vector3(orbit_center.x, 1.6, 1.0)
	camera.look_at(Vector3(orbit_center.x, 1.6, orbit_center.z), Vector3.UP)
	camera.fov = 75.0

	await create_timer(0.5).timeout
	await process_frame

	var viewport := root.get_viewport()
	await RenderingServer.frame_post_draw
	var img: Image = viewport.get_texture().get_image()
	var path := _out_dir + "/entrance.png"
	img.save_png(path)
	print("capture_entrance: ✅ entrance -> %s" % path)

	quit(0)

func _wait_for_map_ready(catalog: Node, timeout: float) -> bool:
	var elapsed := 0.0
	while elapsed < timeout:
		if catalog.get("_map_ready"):
			return true
		await create_timer(0.25).timeout
		elapsed += 0.25
	return false

func _find_camera(node: Node) -> Camera3D:
	if node is Camera3D:
		return node
	for child in node.get_children():
		var found := _find_camera(child)
		if found:
			return found
	return null
