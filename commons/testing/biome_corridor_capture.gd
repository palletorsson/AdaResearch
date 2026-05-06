extends SceneTree

## biome_corridor_capture.gd
##
## Walks a camera down a long corridor map (Biome_Zoo or Biome_Spine),
## stopping at each zone's centre and capturing a player-eye photograph
## of the painted floor + the corridor stretching ahead. The boundary
## between the current zone and the next is intentionally in frame —
## that's the most interesting part of the timeline.
##
## Output: <out>/<target>/zone_NN.png + walk_report.json
##
## Run:
##   godot --xr-mode off --no-window \
##     --script res://commons/testing/biome_corridor_capture.gd -- \
##     --target=Biome_Spine --zone-width=4 --out=user://biome_corridor

const MAP_CATALOG_SCENE: String = "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"

var _target: String = ""
var _zone_width: int = 4
var _output_dir: String = "user://biome_corridor"
var _settle_seconds: float = 1.5
var _wait_seconds: float = 4.0
# Camera tilt: slight downward angle so the painted floor reads but the
# corridor's depth still shows. Pure horizontal hides the paint; pure
# top-down loses the spatial-walk feel.
var _eye_height: float = 4.5     # camera lifted above corridor — "drone shot"
var _look_drop: float = 3.5      # how far below eye the camera looks (steeper angle)
var _look_forward: float = 5.0   # how far forward along corridor it looks
var _fov_deg: float = 60.0


func _initialize() -> void:
	_parse_args()
	if _target.is_empty():
		push_error("biome_corridor_capture: --target=<map_name> is required")
		quit(1)
		return
	call_deferred("_run")


func _parse_args() -> void:
	for raw_arg in OS.get_cmdline_user_args():
		var arg: String = String(raw_arg).strip_edges()
		if not arg.begins_with("--"):
			continue
		var eq_idx: int = arg.find("=")
		if eq_idx <= 2:
			continue
		var key: String = arg.substr(2, eq_idx - 2)
		var value: String = arg.substr(eq_idx + 1).strip_edges()
		match key:
			"target":     _target = value
			"zone-width": if value.is_valid_int(): _zone_width = max(1, int(value))
			"out":        if not value.is_empty(): _output_dir = value
			"settle":     if value.is_valid_float(): _settle_seconds = maxf(0.1, float(value))
			"wait":       if value.is_valid_float(): _wait_seconds = maxf(1.0, float(value))


func _run() -> void:
	print("[biome_corridor] loading '%s'..." % _target)

	if change_scene_to_file(MAP_CATALOG_SCENE) != OK:
		push_error("[biome_corridor] failed to load MapCatalog scene")
		quit(1); return

	await process_frame
	await process_frame

	var catalog: Node = current_scene
	if catalog == null:
		push_error("[biome_corridor] current_scene is null"); quit(1); return

	_hide_overlay_nodes(catalog)

	if not bool(catalog.call("load_map_fresh", _target)):
		push_error("[biome_corridor] failed to load map '%s'" % _target)
		quit(1); return

	# Wait for the map to finish generating.
	if not await _wait_for_map_ready(catalog, 30.0):
		push_warning("[biome_corridor] map ready timeout, proceeding anyway")

	await create_timer(_wait_seconds).timeout
	await process_frame; await process_frame

	# Stop the catalog's default orbit spin — we drive the camera manually.
	if catalog.has_method("set_camera_mode"):
		catalog.call("set_camera_mode", 0)  # STATIC
	if "_spin_speed" in catalog:
		catalog.set("_spin_speed", 0.0)
	await process_frame
	# Beat any deferred re-spin.
	if catalog.has_method("set_camera_mode"):
		catalog.call("set_camera_mode", 0)
	if "_spin_speed" in catalog:
		catalog.set("_spin_speed", 0.0)

	var camera: Camera3D = catalog.get("_preview_camera") if "_preview_camera" in catalog else null
	if camera == null:
		push_error("[biome_corridor] could not find preview camera"); quit(1); return

	# Disable any other cameras that might steal the viewport, then make
	# our preview camera the active one.
	_disable_cameras_recursive(catalog)
	camera.current = true
	camera.fov = _fov_deg
	camera.near = 0.1
	camera.far = 200.0

	# Read map dimensions from the catalog so we know corridor length + depth.
	var dims: Vector3i = _get_grid_dims_from(catalog)
	if dims == Vector3i.ZERO:
		push_error("[biome_corridor] could not read grid dims"); quit(1); return

	var corridor_length: int = dims.x  # cells along the long axis
	var corridor_depth: int = dims.z
	var zone_count: int = corridor_length / _zone_width

	print("[biome_corridor] dims=%s zones=%d (zone_width=%d)" % [dims, zone_count, _zone_width])

	# Output dir
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	var target_dir: String = _output_dir + "/" + _target
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target_dir))

	var saved: int = 0
	var report: Array = []
	for z in zone_count:
		# Camera lifted above the corridor and tilted down — drone-shot
		# style — so the painted floor dominates the frame. Pulled back a
		# bit from zone centre so the boundary into the next zone is in
		# frame too (the transition is the most interesting part).
		var zone_centre_x: float = float(z * _zone_width) + (float(_zone_width) * 0.5)
		var camera_z: float = float(corridor_depth) * 0.5
		var camera_x: float = zone_centre_x - 2.0
		camera.global_position = Vector3(camera_x, _eye_height, camera_z)
		var look_target := Vector3(camera_x + _look_forward, _eye_height - _look_drop, camera_z)
		camera.look_at(look_target, Vector3.UP)
		# Persist into the catalog's static-camera slots so any re-apply
		# (process tick, frame settle, deferred call) doesn't stomp our
		# position back to the startup default.
		if "_static_camera_position" in catalog:
			catalog.set("_static_camera_position", camera.global_position)
		if "_static_camera_rotation" in catalog:
			catalog.set("_static_camera_rotation", camera.rotation)
		if "fly_mode_enabled" in catalog:
			catalog.set("fly_mode_enabled", false)

		await create_timer(_settle_seconds).timeout
		await process_frame; await process_frame
		# Re-apply right before capture in case anything moved it during settle.
		camera.global_position = Vector3(camera_x, _eye_height, camera_z)
		camera.look_at(look_target, Vector3.UP)
		await process_frame

		var fname: String = "zone_%02d.png" % (z + 1)
		var path: String = target_dir + "/" + fname
		var img: Image = root.get_viewport().get_texture().get_image()
		if img == null:
			push_warning("[biome_corridor] viewport image null at zone %d" % (z + 1))
			continue
		img.save_png(path)
		saved += 1
		report.append({
			"zone": z + 1,
			"camera_pos": [camera.global_position.x, camera.global_position.y, camera.global_position.z],
			"file": fname,
		})
		print("  saved %s (camera at %.1f, %.1f, %.1f)" % [
			fname, camera.global_position.x, camera.global_position.y, camera.global_position.z])

	# Write report
	var report_path: String = target_dir + "/walk_report.json"
	var f := FileAccess.open(report_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"target": _target,
			"zone_count": zone_count,
			"zone_width": _zone_width,
			"saved": saved,
			"corridor_dims": [dims.x, dims.y, dims.z],
			"zones": report,
		}, "  "))
		f.close()

	print("[biome_corridor] DONE: %d/%d zones captured" % [saved, zone_count])
	quit(0)


func _wait_for_map_ready(catalog: Node, timeout_s: float) -> bool:
	var elapsed: float = 0.0
	var step: float = 0.25
	while elapsed < timeout_s:
		await create_timer(step).timeout
		elapsed += step
		# Heuristic: catalog has a "_map_ready" flag or grid component count
		if "_map_ready" in catalog and bool(catalog.get("_map_ready")):
			return true
		# Fallback: check if any GridStructureComponent has been added
		var grid_comp := _find_first_grid_component(catalog)
		if grid_comp != null and "_built" in grid_comp and bool(grid_comp.get("_built")):
			return true
		# Last resort: assume ready after 4s if nothing else triggered
		if elapsed >= 4.0:
			return true
	return false


func _find_first_grid_component(node: Node) -> Node:
	if node == null:
		return null
	if node.get_class().contains("GridStructure") or "GridStructure" in node.name:
		return node
	for child in node.get_children():
		var found = _find_first_grid_component(child)
		if found != null:
			return found
	return null


func _hide_overlay_nodes(catalog: Node) -> void:
	# Same named-overlay list capture_multi_angle uses. The catalog scene
	# has a sidebar / customise panel / status label that bleed into the
	# captured frame if not explicitly hidden.
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


func _disable_cameras_recursive(node: Node) -> void:
	# Make sure no other Camera3D in the tree steals the viewport from us.
	if node is Camera3D:
		(node as Camera3D).current = false
	for child in node.get_children():
		_disable_cameras_recursive(child)


func _get_grid_dims_from(catalog: Node) -> Vector3i:
	# Walk children looking for something that exposes grid dimensions.
	# MapCatalogDesktop3D usually has a GridDataComponent or similar that
	# can answer this; if not, we fall back to the loaded JSON's dims.
	for prop in ["_current_grid_dims", "_grid_dims", "grid_dims"]:
		if prop in catalog:
			var v = catalog.get(prop)
			if v is Vector3i:
				return v
	# Fallback: read the map file directly.
	var path := "res://commons/maps/%s/map_data.json" % _target
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return Vector3i.ZERO
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		return Vector3i.ZERO
	var d = json.data
	if not (d is Dictionary):
		return Vector3i.ZERO
	var dims = (d as Dictionary).get("map_info", {}).get("dimensions", {})
	return Vector3i(
		int(dims.get("width", 0)),
		int(dims.get("max_height", 5)),
		int(dims.get("depth", 0)),
	)
