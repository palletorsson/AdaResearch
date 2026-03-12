extends SceneTree

## Multi-angle screenshot capture for maps and artifacts.
## Takes 4 screenshots from different camera positions and saves them to a folder.
##
## Map mode — loads via MapCatalogDesktop3D, captures above/front/left/right:
##   godot_console --path . --xr-mode off --script res://commons/testing/capture_multi_angle.gd -- \
##     --mode=map --target=LSystems_Grammar_Lab --out=user://multi_shots
##
## Artifact mode — loads artifact from registry, captures front/left/right/top:
##   godot_console --path . --xr-mode off --script res://commons/testing/capture_multi_angle.gd -- \
##     --mode=artifact --target=genetic_tree_sculptor --out=user://multi_shots
##
## Output: <out>/<target>/above.png, front.png, left.png, right.png

const MAP_CATALOG_SCENE: String = "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"
const ARTIFACT_CATALOG_SCENE: String = "res://commons/artifacts/catalog/ArtifactCatalogDesktop3D.tscn"

var _mode: String = ""           # "map" or "artifact"
var _target: String = ""         # map name or artifact lookup_name
var _output_dir: String = "user://multi_shots"
var _wait_seconds: float = 4.0   # wait before first capture
var _settle_seconds: float = 0.5 # settle between angle switches

# ── Angle presets ─────────────────────────────────────────────────

## Map angles: yaw (radians around Y), pitch (radians from horizontal)
## Maps are viewed from outside orbiting the center
const MAP_ANGLES: Array[Dictionary] = [
	{ "name": "above",  "yaw": 0.0,           "pitch_factor": 0.95 },  # near top-down
	{ "name": "front",  "yaw": 0.0,           "pitch_factor": 0.35 },  # 3/4 front-down
	{ "name": "left",   "yaw": PI * 0.5,      "pitch_factor": 0.35 },  # 3/4 from left
	{ "name": "right",  "yaw": PI * -0.5,     "pitch_factor": 0.35 },  # 3/4 from right
]

## Artifact angles: yaw, pitch (orbit around artifact center)
## pitch is positive = above focus, negative = below focus
const ARTIFACT_ANGLES: Array[Dictionary] = [
	{ "name": "front",  "yaw": 0.4,    "pitch": 0.4   },  # hero shot — slightly above, looking down
	{ "name": "left",   "yaw": 1.97,   "pitch": 0.35  },  # 90° left, slightly above
	{ "name": "right",  "yaw": -1.17,  "pitch": 0.35  },  # 90° right, slightly above
	{ "name": "top",    "yaw": 0.4,    "pitch": 1.2   },  # looking down from above
]

# ── Initialization ────────────────────────────────────────────────

func _initialize() -> void:
	_parse_args()

	if _mode.is_empty():
		push_error("capture_multi_angle: --mode=map|artifact is required")
		quit(1)
		return
	if _target.is_empty():
		push_error("capture_multi_angle: --target=<name> is required")
		quit(1)
		return
	if _mode != "map" and _mode != "artifact":
		push_error("capture_multi_angle: --mode must be 'map' or 'artifact', got '%s'" % _mode)
		quit(1)
		return

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
			"mode":
				_mode = value.to_lower()
			"target":
				_target = value
			"out":
				if not value.is_empty():
					_output_dir = value
			"wait":
				if value.is_valid_float():
					_wait_seconds = maxf(1.0, float(value))
			"settle":
				if value.is_valid_float():
					_settle_seconds = maxf(0.1, float(value))

# ── Main runner ───────────────────────────────────────────────────

func _run() -> void:
	if _mode == "map":
		await _run_map_capture()
	else:
		await _run_artifact_capture()

# ── Map capture ───────────────────────────────────────────────────

func _run_map_capture() -> void:
	print("capture_multi_angle [map]: Loading catalog and map '%s'..." % _target)

	var change_err: int = change_scene_to_file(MAP_CATALOG_SCENE)
	if change_err != OK:
		push_error("capture_multi_angle: Failed to load MapCatalog scene")
		quit(1)
		return

	await process_frame
	await process_frame

	var catalog: Node = current_scene
	if catalog == null:
		push_error("capture_multi_angle: current_scene is null")
		quit(1)
		return

	# Hide all overlays
	_hide_overlay_nodes(catalog)

	# Load the target map
	var loaded_ok: bool = bool(catalog.call("load_map_fresh", _target))
	if not loaded_ok:
		push_error("capture_multi_angle: Failed to load map '%s'" % _target)
		quit(1)
		return

	# Wait for map generation to complete
	var ready_ok: bool = await _wait_for_map_ready(catalog, 30.0)
	if not ready_ok:
		push_warning("capture_multi_angle: Map ready timeout, proceeding anyway")

	# Let rendering settle
	await create_timer(_wait_seconds).timeout
	await process_frame
	await process_frame

	# Read orbit parameters from catalog
	var orbit_center: Vector3 = catalog.get("_orbit_center") if "_orbit_center" in catalog else Vector3.ZERO
	var orbit_radius: float = catalog.get("_orbit_radius") if "_orbit_radius" in catalog else 8.0
	var orbit_height: float = catalog.get("_orbit_height") if "_orbit_height" in catalog else 6.0
	var camera: Camera3D = catalog.get("_preview_camera") if "_preview_camera" in catalog else null

	if camera == null:
		push_error("capture_multi_angle: Could not find preview camera")
		quit(1)
		return

	print("capture_multi_angle [map]: orbit_center=%s radius=%.1f height=%.1f" % [
		orbit_center, orbit_radius, orbit_height
	])

	# Stop spin so we control the camera
	if catalog.has_method("set_camera_mode"):
		catalog.call("set_camera_mode", 0)  # STATIC

	# Capture each angle
	var saved: int = 0
	for angle_def in MAP_ANGLES:
		var angle_name: String = angle_def["name"]
		var yaw: float = float(angle_def["yaw"])
		var pitch_factor: float = float(angle_def["pitch_factor"])

		# Position camera using orbit formula
		# pitch_factor: 0 = horizontal, 1 = straight down
		var elevation: float = orbit_height * pitch_factor
		var horizontal_dist: float = orbit_radius * (1.0 - pitch_factor * 0.5)

		var cam_pos := Vector3(
			orbit_center.x + sin(yaw) * horizontal_dist,
			orbit_center.y + elevation,
			orbit_center.z + cos(yaw) * horizontal_dist
		)
		camera.global_position = cam_pos
		camera.look_at(orbit_center, Vector3.UP)

		# Settle
		await create_timer(_settle_seconds).timeout
		await process_frame
		await process_frame

		var shot_path: String = _save_shot(angle_name)
		if not shot_path.is_empty():
			saved += 1
			print("capture_multi_angle [map]: ✅ %s -> %s" % [angle_name, shot_path])
		else:
			push_error("capture_multi_angle [map]: ❌ Failed to save %s" % angle_name)

	print("capture_multi_angle [map]: Done — %d/%d shots saved" % [saved, MAP_ANGLES.size()])
	_save_report(saved)
	quit(0)

# ── Artifact capture ──────────────────────────────────────────────

func _run_artifact_capture() -> void:
	print("capture_multi_angle [artifact]: Loading '%s'..." % _target)

	# Build a minimal 3D scene (same as capture_artifact_shot.gd)
	var scene_root := Node3D.new()
	scene_root.name = "ArtifactMultiCapture"
	root.add_child(scene_root)

	# World environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.12, 0.16)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	scene_root.add_child(world_env)

	# Camera
	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 50.0
	camera.add_to_group("capture_camera")
	scene_root.add_child(camera)

	# Directional light
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.2
	light.shadow_enabled = true
	scene_root.add_child(light)

	# Fill light from opposite side
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 150, 0)
	fill.light_energy = 0.4
	fill.shadow_enabled = false
	scene_root.add_child(fill)

	# Ground plane
	var ground := MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(20, 20)
	ground.mesh = ground_mesh
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.15, 0.15, 0.18)
	ground.material_override = ground_mat
	scene_root.add_child(ground)

	# Load artifact from registry
	var artifact_info: Dictionary = _find_artifact(_target)
	if artifact_info.is_empty():
		push_error("capture_multi_angle: Artifact '%s' not found in any registry" % _target)
		quit(1)
		return

	var scene_path: String = str(artifact_info.get("scene", "")).strip_edges()
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_error("capture_multi_angle: Scene not found: %s" % scene_path)
		quit(1)
		return

	var packed: PackedScene = ResourceLoader.load(scene_path)
	if not packed:
		push_error("capture_multi_angle: Failed to load: %s" % scene_path)
		quit(1)
		return

	var artifact: Node = packed.instantiate()
	if not artifact or not (artifact is Node3D):
		push_error("capture_multi_angle: Scene root is not Node3D")
		if artifact:
			artifact.queue_free()
		quit(1)
		return

	scene_root.add_child(artifact)
	print("capture_multi_angle [artifact]: Instantiated from %s" % scene_path)

	# Let the artifact run _ready()
	await process_frame
	await process_frame
	await process_frame

	# Compute AABB for framing
	var aabb: AABB = _get_combined_aabb(artifact as Node3D)
	var orbit_focus: Vector3 = Vector3(0, 1.0, 0)
	var orbit_distance: float = 5.0

	if aabb.size.length() > 0:
		orbit_focus = aabb.get_center()
		var max_dim: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
		orbit_distance = max_dim * 2.0
		print("capture_multi_angle [artifact]: AABB size=%s center=%s distance=%.1f" % [
			aabb.size, orbit_focus, orbit_distance
		])

	# Wait for rendering
	await create_timer(_wait_seconds).timeout
	await process_frame
	await process_frame

	# Capture each angle
	var saved: int = 0
	for angle_def in ARTIFACT_ANGLES:
		var angle_name: String = angle_def["name"]
		var yaw: float = float(angle_def["yaw"])
		var pitch: float = float(angle_def["pitch"])

		var offset := Vector3(
			sin(yaw) * cos(pitch),
			sin(pitch),
			cos(yaw) * cos(pitch)
		) * orbit_distance
		camera.global_position = orbit_focus + offset
		camera.look_at(orbit_focus, Vector3.UP)

		# Settle
		await create_timer(_settle_seconds).timeout
		await process_frame
		await process_frame

		var shot_path: String = _save_shot(angle_name)
		if not shot_path.is_empty():
			saved += 1
			print("capture_multi_angle [artifact]: ✅ %s -> %s" % [angle_name, shot_path])
		else:
			push_error("capture_multi_angle [artifact]: ❌ Failed to save %s" % angle_name)

	print("capture_multi_angle [artifact]: Done — %d/%d shots saved" % [saved, ARTIFACT_ANGLES.size()])
	_save_report(saved)
	quit(0)

# ── Shared helpers ────────────────────────────────────────────────

func _save_shot(angle_name: String) -> String:
	var image: Image = root.get_texture().get_image()
	if image == null:
		return ""

	var folder: String = _output_dir.path_join(_target)
	var absolute_folder: String = ProjectSettings.globalize_path(folder)
	if not DirAccess.dir_exists_absolute(absolute_folder):
		DirAccess.make_dir_recursive_absolute(absolute_folder)

	var file_name: String = "%s.png" % angle_name
	var absolute_path: String = absolute_folder.path_join(file_name)
	var save_err: int = image.save_png(absolute_path)
	if save_err != OK:
		return ""
	return absolute_path

func _save_report(saved_count: int) -> void:
	var report: Dictionary = {
		"timestamp": Time.get_datetime_string_from_system(true),
		"mode": _mode,
		"target": _target,
		"output_dir": _output_dir,
		"saved_count": saved_count,
		"angles": MAP_ANGLES.size() if _mode == "map" else ARTIFACT_ANGLES.size(),
	}

	var folder: String = _output_dir.path_join(_target)
	var absolute_folder: String = ProjectSettings.globalize_path(folder)
	var report_path: String = absolute_folder.path_join("capture_report.json")
	var file: FileAccess = FileAccess.open(report_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
		print("capture_multi_angle: Report -> %s" % report_path)

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

func _find_artifact(lookup_name: String) -> Dictionary:
	# Check grid_artifacts.json first (largest registry)
	var grid_path: String = "res://commons/artifacts/grid_artifacts.json"
	var grid_text: String = FileAccess.get_file_as_string(grid_path)
	if not grid_text.is_empty():
		var json := JSON.new()
		if json.parse(grid_text) == OK and json.data is Dictionary:
			var data: Dictionary = json.data
			var artifacts: Dictionary = data.get("artifacts", data)
			if artifacts.has(lookup_name):
				return artifacts[lookup_name]

	# Then check registry/ subdirectory
	var registry_dir: String = "res://commons/artifacts/registry"
	var dir := DirAccess.open(registry_dir)
	if not dir:
		push_error("capture_multi_angle: Cannot open registry dir")
		return {}

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var path: String = registry_dir.path_join(file_name)
			var json_text: String = FileAccess.get_file_as_string(path)
			if not json_text.is_empty():
				var json2 := JSON.new()
				if json2.parse(json_text) == OK and json2.data is Dictionary:
					var data2: Dictionary = json2.data
					var artifacts2: Dictionary = data2.get("artifacts", data2)
					if artifacts2.has(lookup_name):
						return artifacts2[lookup_name]
		file_name = dir.get_next()
	dir.list_dir_end()
	return {}

func _get_combined_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for child in node.get_children():
		var child_aabb := AABB()
		var has_aabb := false
		if child is MeshInstance3D:
			var mesh = (child as MeshInstance3D).mesh
			if mesh:
				child_aabb = child.transform * mesh.get_aabb()
				has_aabb = true
		elif child is MultiMeshInstance3D:
			var mm = child.multimesh
			if mm and mm.instance_count > 0:
				child_aabb = child.transform * mm.get_aabb()
				has_aabb = true
		if has_aabb and child_aabb.size.length() > 0:
			if first:
				result = child_aabb
				first = false
			else:
				result = result.merge(child_aabb)
		if child is Node3D:
			var sub_aabb: AABB = _get_combined_aabb(child)
			if sub_aabb.size.length() > 0:
				if first:
					result = sub_aabb
					first = false
				else:
					result = result.merge(sub_aabb)
	return result
