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
# Optional framing override — set both to lock the camera to specific
# focus + distance instead of auto-AABB. Used by the chamber to keep
# before/after captures at identical framing (any AABB change from
# entrance animations or proposed new geometry would otherwise cause
# the camera to pull back, making visual diff invalid).
var _fixed_distance: float = -1.0                # -1 sentinel: not set
var _fixed_focus: Vector3 = Vector3(NAN, NAN, NAN)  # NAN sentinel: not set
# Framing actually used (filled in during run, written to capture_report.json
# so consumers can read it back to lock subsequent captures to the same view).
var _used_distance: float = -1.0
var _used_focus: Vector3 = Vector3.ZERO

# ── Angle presets ─────────────────────────────────────────────────

## Map angles: yaw (radians around Y), pitch (radians from horizontal)
## Maps are viewed from outside orbiting the center
const MAP_ANGLES: Array[Dictionary] = [
	# Primary gallery angle — true isometric (45° azimuth × 30°
	# elevation, orthographic projection) sized to the map so the
	# whole grid fits in frame with no perspective distortion.
	# Cubes look the same size everywhere, height differences are
	# legible, parallel lines stay parallel. Single best view.
	{ "name": "iso_perfect", "yaw": PI * 0.25, "pitch_factor": 1.0, "iso_perfect": true },
	# Other angles still produced for debugging / alternates.
	{ "name": "top",         "yaw": 0.0,        "pitch_factor": 1.0  },
	{ "name": "iso",         "yaw": PI * 0.25,  "pitch_factor": 0.65 },
	{ "name": "front",       "yaw": 0.0,        "pitch_factor": 0.55 },
	{ "name": "left",        "yaw": PI * 0.5,   "pitch_factor": 0.55 },
]

## Artifact angles: yaw, pitch (orbit around artifact center)
## pitch is positive = above focus, negative = below focus
const ARTIFACT_ANGLES: Array[Dictionary] = [
	{ "name": "front",  "yaw": 0.4,    "pitch": 0.4   },  # hero shot — slightly above, looking down
	{ "name": "left",   "yaw": 1.97,   "pitch": 0.35  },  # 90° left, slightly above
	{ "name": "right",  "yaw": -1.17,  "pitch": 0.35  },  # 90° right, slightly above
	{ "name": "top",    "yaw": 0.001,  "pitch": 1.5607 },  # straight down (near PI/2)
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
			"fixed-distance":
				if value.is_valid_float():
					_fixed_distance = float(value)
			"fixed-focus":
				# Format: x,y,z (no spaces)
				var parts: PackedStringArray = value.split(",")
				if parts.size() == 3 and \
						parts[0].is_valid_float() and \
						parts[1].is_valid_float() and \
						parts[2].is_valid_float():
					_fixed_focus = Vector3(
						float(parts[0]), float(parts[1]), float(parts[2])
					)

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

	# Stop spin so we control the camera. Belt-and-braces:
	#   1) call set_camera_mode(STATIC) — official path
	#   2) zero the spin speed directly so any deferred re-enable can't drift
	#   3) re-set STATIC after a frame to clobber call_deferred("_start_default_spin")
	if catalog.has_method("set_camera_mode"):
		catalog.call("set_camera_mode", 0)  # STATIC
	if "_spin_speed" in catalog:
		catalog.set("_spin_speed", 0.0)
	await process_frame
	if catalog.has_method("set_camera_mode"):
		catalog.call("set_camera_mode", 0)  # again — beats the deferred default
	if "_spin_speed" in catalog:
		catalog.set("_spin_speed", 0.0)

	# Tighten framing to map size: catalog's defaults assume bigger rooms,
	# leaving small variant maps adrift in a sea of sky. Pull the radius
	# in toward 1.4× the map's half-diagonal so the structure fills the
	# frame, and recentre the look-at on the cube grid's center-of-mass
	# (slightly above floor level so the bottom of the frame isn't void).
	var grid_dims := _get_grid_dims_from(catalog)
	if grid_dims != Vector3i.ZERO:
		var half_diag: float = sqrt(float(grid_dims.x * grid_dims.x + grid_dims.z * grid_dims.z)) * 0.5
		orbit_radius = max(5.0, half_diag * 1.6)
		orbit_height = max(4.0, half_diag * 1.2)
		# Look at the floor's center, lifted a bit so the cube grid
		# (not the dark void below) anchors the frame.
		orbit_center = Vector3(
			float(grid_dims.x) * 0.5,
			min(float(grid_dims.y) * 0.5, 2.5),
			float(grid_dims.z) * 0.5,
		)
		print("capture_multi_angle [map]: framed for %s — radius=%.1f height=%.1f center=%s" % [
			str(grid_dims), orbit_radius, orbit_height, orbit_center,
		])

	# Capture each angle
	var saved: int = 0
	for angle_def in MAP_ANGLES:
		var angle_name: String = angle_def["name"]
		var yaw: float = float(angle_def["yaw"])
		var pitch_factor: float = float(angle_def["pitch_factor"])

		var cam_pos: Vector3
		var iso_perfect: bool = bool(angle_def.get("iso_perfect", false))

		if iso_perfect:
			# True isometric: orthographic camera at 45° azimuth × 30°
			# elevation. Size the ortho frustum so the whole iso
			# projection of the grid fits with a 5% margin. Parallel
			# lines stay parallel — exactly what a structural thumb wants.
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			var span_x: float = float(grid_dims.x) if grid_dims != Vector3i.ZERO else 12.0
			var span_z: float = float(grid_dims.z) if grid_dims != Vector3i.ZERO else 12.0
			var span_y: float = float(grid_dims.y) if grid_dims != Vector3i.ZERO else 4.0
			# Iso projection extents (45° az × 30° el). For an axis-
			# aligned grid of size span_x × span_z × span_y:
			#   horizontal screen extent = (span_x + span_z) * cos(45°)
			#                            ≈ 0.707 × (x + z)
			#   vertical screen extent   = (span_x + span_z) * sin(45°) * sin(30°)
			#                            + span_y * cos(30°)
			#                            ≈ 0.354 × (x + z) + 0.866 × y
			var iso_w: float = (span_x + span_z) * 0.707
			var iso_h: float = (span_x + span_z) * 0.354 + span_y * 0.866
			# Godot's `camera.size` is the *vertical* frustum size.
			# Horizontal extent of the frustum = size * aspect.
			# So size must be ≥ iso_h AND size*aspect ≥ iso_w.
			# Read aspect ratio from the actual root viewport (the one
			# we capture from in _save_shot via root.get_texture()),
			# not the camera's own viewport which can be a sub-vp.
			var vp_size = get_root().get_texture().get_image().get_size() if get_root() and get_root().get_texture() else Vector2i.ZERO
			var aspect: float = 16.0 / 9.0
			if vp_size.x > 0 and vp_size.y > 0:
				aspect = float(vp_size.x) / float(vp_size.y)
			# Fit the iso projection box to whichever screen axis is
			# the binding constraint. camera.size is the *vertical*
			# size of the ortho frustum.
			var by_height: float = iso_h
			var by_width: float = iso_w / max(aspect, 0.1)
			# Empirical: 1.02× = 50% fill; 0.55× overflows; 0.62× ≈ 90%
			# fill with a small margin. The analytical iso bounding box
			# under-predicts what's actually rendered (likely Godot's
			# ortho keep-aspect treats `size` differently than docs say).
			camera.size = max(by_height, by_width) * 0.65
			print("capture_multi_angle [iso_perfect]: vp=%s aspect=%.2f iso_w=%.1f iso_h=%.1f size=%.1f" % [
				str(vp_size), aspect, iso_w, iso_h, camera.size,
			])
			# Camera position along the iso direction. For 45° azimuth
			# × 30° elevation, the unit direction is:
			#   (cos(30°)·cos(45°), sin(30°), cos(30°)·sin(45°))
			#   = (0.612, 0.5, 0.612) — already unit-length.
			var iso_dir := Vector3(0.6124, 0.5, 0.6124)
			var iso_ofs := Vector3(
				sin(yaw) * iso_dir.x + cos(yaw) * iso_dir.z,
				iso_dir.y,
				cos(yaw) * iso_dir.x - sin(yaw) * iso_dir.z,
			) * 50.0
			# Iso target = midpoint between floor centre and the projected
			# upper edge. Lifting it pushes the image toward the bottom
			# of the frame, since looking at a higher target tilts the
			# camera downward (the frame fills from below).
			var iso_target := Vector3(
				orbit_center.x,
				span_y * 0.55,
				orbit_center.z,
			)
			cam_pos = iso_target + iso_ofs
			camera.global_position = cam_pos
			camera.look_at(iso_target, Vector3.UP)
		elif angle_name == "top":
			# Pure top-down. Compute the camera height to fit the whole
			# grid (with 10% margin) at the camera's actual FOV. This
			# avoids the orbit formula's pitch_factor=1.0 degeneracy
			# (which collapses horizontal_dist to half).
			var fov_deg: float = camera.fov if camera else 60.0
			var span: float = max(float(grid_dims.x), float(grid_dims.z)) if grid_dims != Vector3i.ZERO else 12.0
			# height = (span/2) / tan(fov/2), with 1.1× margin and the
			# camera looking down at the floor (origin) plus the cube
			# stack height so a tall map's top still fits.
			var h: float = (span * 0.5) / max(0.1, tan(deg_to_rad(fov_deg) * 0.5))
			h = h * 1.1 + (float(grid_dims.y) * 0.5 if grid_dims != Vector3i.ZERO else 2.0)
			cam_pos = Vector3(orbit_center.x, orbit_center.y + h, orbit_center.z)
			# Orient so "up" in the image points toward -z (north of map),
			# avoiding the gimbal flip when looking exactly straight down.
			camera.global_position = cam_pos
			camera.look_at(orbit_center, Vector3.FORWARD)
		else:
			# Position camera using orbit formula
			# pitch_factor: 0 = horizontal, 1 = straight down
			var elevation: float = orbit_height * pitch_factor
			var horizontal_dist: float = orbit_radius * (1.0 - pitch_factor * 0.5)
			cam_pos = Vector3(
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

		# Restore perspective projection after iso_perfect — so the
		# perspective angles that follow it aren't ortho-shot.
		if iso_perfect:
			camera.projection = Camera3D.PROJECTION_PERSPECTIVE

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

	# Load artifact from registry (ground added later if scene lacks its own)
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

	# Stamp the lookup name BEFORE _ready(), the same contract the grid honours
	# (GridInteractablesComponent). One-scene-many-names artifacts (array_probe,
	# specimen_plinth, the bricolage affordances) read it to pick their variant;
	# without it every name in the family captures as the fallback. Single-name
	# artifacts never read the meta, so this is inert for them.
	artifact.set_meta("artifact_lookup_name", _target)

	scene_root.add_child(artifact)
	print("capture_multi_angle [artifact]: Instantiated from %s" % scene_path)

	# Let the artifact run _ready()
	await process_frame
	await process_frame
	await process_frame

	# Disable any cameras the artifact created (they override our capture camera)
	_disable_cameras_recursive(artifact)
	camera.current = true

	# Add ground plane only if artifact doesn't provide its own WorldEnvironment
	var has_own_env := false
	for child in (artifact as Node).get_children():
		if child is WorldEnvironment:
			has_own_env = true
			break
	# Ground plane removed — was clipping interactive panels at low Y positions

	# Compute AABB for framing (default — auto-fit camera to artifact bounds)
	var aabb: AABB = _get_combined_aabb(artifact as Node3D)
	var orbit_focus: Vector3 = Vector3(0, 1.0, 0)
	var base_distance: float = 5.0

	if aabb.size.length() > 0:
		orbit_focus = aabb.get_center()
		var max_dim: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
		base_distance = max_dim * 1.0
		print("capture_multi_angle [artifact]: AABB size=%s center=%s base_dist=%.1f" % [
			aabb.size, orbit_focus, base_distance
		])

	# CLI overrides take precedence — used by the chamber to lock framing
	# across before/after captures so visual diff stays valid.
	if not is_nan(_fixed_focus.x):
		orbit_focus = _fixed_focus
		print("capture_multi_angle [artifact]: --fixed-focus -> %s" % orbit_focus)
	if _fixed_distance > 0.0:
		base_distance = _fixed_distance
		print("capture_multi_angle [artifact]: --fixed-distance -> %.3f" % base_distance)

	# Record the framing actually used so the chamber can read it back and
	# lock subsequent captures to identical params.
	_used_focus = orbit_focus
	_used_distance = base_distance

	# Wait for rendering (trails need time to build)
	await create_timer(_wait_seconds).timeout
	await process_frame
	await process_frame

	# --- ZOOM SWEEP: 3 distances (wide / sweet / tight), default = sweet ---
	var zoom_factors: Array[float] = [1.4, 1.0, 0.65]

	var saved: int = 0
	for angle_def in ARTIFACT_ANGLES:
		var angle_name: String = angle_def["name"]
		var yaw: float = float(angle_def["yaw"])
		var pitch: float = float(angle_def["pitch"])

		# Capture at all 3 distances
		for zi in range(zoom_factors.size()):
			var zoom: float = zoom_factors[zi]
			var dist: float = base_distance * zoom
			var cam_offset := Vector3(
				sin(yaw) * cos(pitch),
				sin(pitch),
				cos(yaw) * cos(pitch)
			) * dist
			camera.global_position = orbit_focus + cam_offset
			camera.look_at(orbit_focus, Vector3.UP)

			await process_frame
			await process_frame
			await create_timer(0.15).timeout
			await process_frame

			var img: Image = root.get_texture().get_image()
			if img == null:
				continue

			# Save with zoom suffix (far/mid/close)
			var zoom_name: String = ["far", "mid", "close"][zi]
			var suffix: String = angle_name + "_" + zoom_name
			var shot_path: String = _save_shot(suffix)
			if not shot_path.is_empty():
				print("capture_multi_angle [artifact]:   %s @ dist=%.1f -> %s" % [suffix, dist, shot_path])

		# Save the wide zoom (full artifact visible) as the default
		var sweet_dist: float = base_distance * zoom_factors[0]
		var cam_offset := Vector3(
			sin(yaw) * cos(pitch),
			sin(pitch),
			cos(yaw) * cos(pitch)
		) * sweet_dist
		camera.global_position = orbit_focus + cam_offset
		camera.look_at(orbit_focus, Vector3.UP)
		await process_frame
		await process_frame

		var shot_path: String = _save_shot(angle_name)
		if not shot_path.is_empty():
			saved += 1
			print("capture_multi_angle [artifact]: ✅ %s -> %s (dist=%.1f)" % [
				angle_name, shot_path, sweet_dist
			])

	print("capture_multi_angle [artifact]: Done — %d/%d shots saved" % [saved, ARTIFACT_ANGLES.size()])
	if saved == 0:
		print("capture_multi_angle: TIP — If artifact invisible, run: python tools/flow_query.py screenshot")
	_save_report(saved)
	quit(0)

# ── Shared helpers ────────────────────────────────────────────────

## Read the loaded grid_system's data dimensions so we can frame the
## camera around the actual map size — not the catalog's defaults.
func _get_grid_dims_from(catalog: Node) -> Vector3i:
	var grid: Node = catalog.get("_grid_system") if "_grid_system" in catalog else null
	if grid == null:
		return Vector3i.ZERO
	# Try data_component first (the canonical source).
	var data_comp = null
	if "data_component" in grid:
		data_comp = grid.get("data_component")
	if data_comp and data_comp.has_method("get_grid_dimensions"):
		var dims = data_comp.call("get_grid_dimensions")
		if dims is Vector3i:
			return dims
	# Fall back to grid_dimensions if exposed directly.
	if "grid_dimensions" in grid:
		var d = grid.get("grid_dimensions")
		if d is Vector3i:
			return d
	return Vector3i.ZERO


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
		# Framing actually used. Consumers (chamber.py) can pass these back
		# as --fixed-focus / --fixed-distance to lock subsequent captures
		# to the same view — essential for valid before/after comparison.
		"framing": {
			"focus": [_used_focus.x, _used_focus.y, _used_focus.z],
			"distance": _used_distance,
			"focus_was_overridden": not is_nan(_fixed_focus.x),
			"distance_was_overridden": _fixed_distance > 0.0,
		},
	}

	var folder: String = _output_dir.path_join(_target)
	var absolute_folder: String = ProjectSettings.globalize_path(folder)
	var report_path: String = absolute_folder.path_join("capture_report.json")
	var file: FileAccess = FileAccess.open(report_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
		print("capture_multi_angle: Report -> %s" % report_path)

func _disable_cameras_recursive(node: Node) -> void:
	if node is Camera3D:
		(node as Camera3D).current = false
	for child in node.get_children():
		_disable_cameras_recursive(child)

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
	# Check registry/ directory
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
		elif child is CSGShape3D:
			# CSG nodes have get_meshes() which returns [Transform3D, Mesh] pairs
			var meshes = (child as CSGShape3D).get_meshes()
			if meshes.size() >= 2 and meshes[1] is Mesh:
				child_aabb = child.transform * (meshes[1] as Mesh).get_aabb()
				has_aabb = true
			elif child is CSGPrimitive3D:
				# Fallback: estimate from position + size for CSGBox3D etc.
				var sz := Vector3(1, 1, 1)
				if child is CSGBox3D:
					sz = (child as CSGBox3D).size
				elif child is CSGCylinder3D:
					var r: float = (child as CSGCylinder3D).radius
					var h: float = (child as CSGCylinder3D).height
					sz = Vector3(r * 2, h, r * 2)
				child_aabb = child.transform * AABB(-sz * 0.5, sz)
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
				# Transform sub-AABB into parent's space
				sub_aabb = (child as Node3D).transform * sub_aabb
				if first:
					result = sub_aabb
					first = false
				else:
					result = result.merge(sub_aabb)
	return result
