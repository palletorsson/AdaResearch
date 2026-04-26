extends SceneTree

## Capture every named pattern of every grid mutator (color + visibility) on a
## small self-contained MultiMesh — no GridSystem, no map dependency. Validates
## that the substrate split (GridMutatorBase + GridColorMutator + GridVisibilityMutator)
## still produces the expected per-pattern frames.
##
## Usage (2D, default):
##   godot_console --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_mutator_cycle.gd \
##     -- --grid_size=16 --outdir=user://mutator_shots
##
## Usage (3D volume — 12 wide × 8 tall × 12 deep):
##   godot_console --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_mutator_cycle.gd \
##     -- --grid_dims=12,8,12 --outdir=user://mutator_shots_3d
##
## Output: <outdir>/<channel>_<pattern>.png + capture_report.json

const SHADER_PATH := "res://commons/resourses/shaders/SimpleGrid.gdshader"
const PALETTES_PATH := "res://algorithms/color/color_palettes.tres"
const GRID_COLOR_MUTATOR_PATH := "res://commons/grid/mutators/grid_color_mutator.gd"
const GRID_VISIBILITY_MUTATOR_PATH := "res://commons/grid/mutators/grid_visibility_mutator.gd"
const GRID_VISIBILITY_EXPRESSIONS_PATH := "res://commons/grid/mutators/grid_visibility_expressions.gd"
const GRID_VISIBILITY_EXPRESSIONS_3D_PATH := "res://commons/grid/mutators/grid_visibility_expressions_3d.gd"
const GRID_TRANSFORM_MUTATOR_PATH := "res://commons/grid/mutators/grid_transform_mutator.gd"
const GRID_TRANSFORM_EXPRESSIONS_PATH := "res://commons/grid/mutators/grid_transform_expressions.gd"

var _grid_size: int = 16
var _grid_dims: Vector3i = Vector3i.ZERO  # explicit 3D dims; ZERO falls back to (grid_size, 1, grid_size)
var _outdir: String = "user://mutator_shots"
var _wait_seconds: float = 1.5
var _per_pattern_settle: float = 0.25
var _capture_combined: bool = true

var _multimesh_instance: MultiMeshInstance3D = null
var _multimesh: MultiMesh = null
var _color_mutator: Node = null
var _visibility_mutator: Node = null
var _transform_mutator: Node = null
var _viewport: Viewport = null

var _report := {
	"started_at_ms": 0,
	"grid_size": 0,
	"shots": [],
	"errors": [],
}


func _initialize() -> void:
	_parse_args()
	# If --grid_dims wasn't passed, fall back to a square 2D grid from --grid_size.
	if _grid_dims == Vector3i.ZERO:
		_grid_dims = Vector3i(_grid_size, 1, _grid_size)
	_report.started_at_ms = Time.get_ticks_msec()
	_report.grid_size = _grid_size
	_report["grid_dims"] = "%d,%d,%d" % [_grid_dims.x, _grid_dims.y, _grid_dims.z]
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
			"grid_size":
				if value.is_valid_int():
					_grid_size = max(int(value), 4)
			"grid_dims":
				# format: W,H,D  (e.g. 12,8,12)
				var parts: PackedStringArray = value.split(",")
				if parts.size() == 3 and parts[0].is_valid_int() and parts[1].is_valid_int() and parts[2].is_valid_int():
					_grid_dims = Vector3i(max(int(parts[0]), 1), max(int(parts[1]), 1), max(int(parts[2]), 1))
				else:
					push_warning("capture_mutator_cycle: invalid --grid_dims=%s (expected W,H,D)" % value)
			"outdir":
				_outdir = value
			"wait":
				if value.is_valid_float():
					_wait_seconds = float(value)
			"settle":
				if value.is_valid_float():
					_per_pattern_settle = float(value)
			"combined":
				_capture_combined = value.to_lower() in ["1", "true", "yes"]


func _run() -> void:
	print("capture_mutator_cycle: grid_dims=%d×%d×%d outdir=%s" % [_grid_dims.x, _grid_dims.y, _grid_dims.z, _outdir])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_outdir))

	_build_scene()
	await create_timer(_wait_seconds).timeout

	if not _multimesh or _multimesh.instance_count == 0:
		_fail("MultiMesh not built")
		return
	if not _color_mutator or _color_mutator.get_pattern_count() == 0:
		_fail("color mutator has no patterns (check GameManager + color_palettes.tres)")
		return
	if not _visibility_mutator or _visibility_mutator.get_pattern_count() == 0:
		_fail("visibility mutator has no expressions (check GridVisibilityExpressions wiring)")
		return

	# Capture each color pattern alone (visibility = all cubes shown).
	_visibility_mutator.disable_auto_cycle()
	_color_mutator.disable_auto_cycle()
	_show_all_cubes()
	for i in range(_color_mutator.get_pattern_count()):
		_color_mutator.set_pattern_by_index(i)
		var name: String = _color_mutator.get_current_pattern_name()
		await create_timer(_per_pattern_settle).timeout
		_capture("color/%s" % name)

	# Capture each visibility pattern alone (color = white).
	_apply_solid_white()
	for j in range(_visibility_mutator.get_pattern_count()):
		_visibility_mutator.set_pattern_by_index(j)
		var name2: String = _visibility_mutator.get_current_pattern_name()
		await create_timer(_per_pattern_settle).timeout
		_capture("visibility/%s" % name2)

	# WALK-PATH carve: re-render the four most pattern-dense visibility expressions
	# with a 2×2×2 L-shaped corridor cut through the volume. Proves the player can
	# walk through the substrate regardless of what the pattern produced.
	if _grid_dims.y > 1 and _visibility_mutator.has_method("set"):
		_show_all_cubes()
		_apply_solid_white()
		# L-path through the volume at mid-height so the corridor is visible from
		# the capture camera (which looks down at the front-facing cubes). The
		# path enters one wall, turns at the centre, exits the perpendicular wall.
		# Coordinates are cube indices.
		var px: int = _grid_dims.x / 2
		var pz: int = _grid_dims.z / 2
		var py: int = _grid_dims.y / 3  # lift one third of the way up so it's not on the floor
		_visibility_mutator.walk_path_points = [
			Vector3i(0, py, pz),
			Vector3i(px, py, pz),
			Vector3i(px, py, _grid_dims.z - 1),
		] as Array[Vector3i]
		_visibility_mutator.walk_path_width = 3
		_visibility_mutator.walk_path_height = 3
		_visibility_mutator.walk_path_enabled = true
		_visibility_mutator.refresh_walk_path()
		var carve_targets: Array = ["menger_sponge", "sphere_shell", "rule_30", "bfs_frontier_t6"]
		for vname in carve_targets:
			_set_visibility_pattern_by_name(vname)
			await create_timer(_per_pattern_settle).timeout
			_capture("walkpath/%s" % vname)
		_visibility_mutator.walk_path_enabled = false
		_visibility_mutator.refresh_walk_path()

	# Capture each transform pattern alone (visibility = all shown, color = white).
	_show_all_cubes()
	_apply_solid_white()
	for k in range(_transform_mutator.get_pattern_count()):
		# Transforms compose onto cached transforms; refresh so each pattern starts
		# from the original authored grid layout, not from the previous pattern's output.
		_reset_multimesh_transforms()
		_transform_mutator.refresh_cached_transforms()
		_transform_mutator.set_pattern_by_index(k)
		var name3: String = _transform_mutator.get_current_pattern_name()
		await create_timer(_per_pattern_settle).timeout
		_capture("transform/%s" % name3)

	# Combined sweep — proves all three mutators write to the same MultiMesh
	# without interference. Color × visibility × one transform.
	if _capture_combined:
		var palette_names: Array = ["mondrian_grid", "neon_cyberpunk"]
		var vis_names: Array = []
		for kk in range(_visibility_mutator.get_pattern_count()):
			_visibility_mutator.set_pattern_by_index(kk)
			vis_names.append(_visibility_mutator.get_current_pattern_name())
		for pname in palette_names:
			for vname in vis_names:
				_reset_multimesh_transforms()
				_visibility_mutator.refresh_cached_transforms()
				_set_color_pattern_by_name(pname)
				_set_visibility_pattern_by_name(vname)
				await create_timer(_per_pattern_settle).timeout
				_capture("combined/%s__%s" % [pname, vname])

		# Triple-channel: color × visibility × rotate_by_distance, on a small subset
		# to keep the matrix manageable.
		for pname2 in ["frida_kahlo"]:
			for vname2 in ["sierpinski", "rings"]:
				for tname in ["rotate_by_distance", "scale_pulse"]:
					_reset_multimesh_transforms()
					_visibility_mutator.refresh_cached_transforms()
					_transform_mutator.refresh_cached_transforms()
					_set_color_pattern_by_name(pname2)
					_set_visibility_pattern_by_name(vname2)
					_set_transform_pattern_by_name(tname)
					await create_timer(_per_pattern_settle).timeout
					_capture("triple/%s__%s__%s" % [pname2, vname2, tname])

	# Let the last async _capture finish saving before we quit.
	await create_timer(0.5).timeout
	_write_report()
	print("capture_mutator_cycle: %d shots saved" % _report.shots.size())
	quit()


# --- scene building --------------------------------------------------------

func _build_scene() -> void:
	var scene_root := Node3D.new()
	scene_root.name = "MutatorCaptureRoot"
	root.add_child(scene_root)

	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.10, 0.10, 0.13)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.65)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	scene_root.add_child(world_env)

	# Light
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -45, 0)
	light.light_energy = 1.2
	scene_root.add_child(light)

	# Camera — orthographic isometric. For 3D volumes, lift and orbit so y is visible.
	var camera := Camera3D.new()
	camera.current = true
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	var w: float = float(_grid_dims.x)
	var h: float = float(_grid_dims.y)
	var d: float = float(_grid_dims.z)
	# Frame on the largest horizontal extent plus a head-room factor for height.
	var frame_extent: float = max(w, d) + h * 0.35
	camera.size = frame_extent * 1.4
	var center: Vector3 = Vector3(w * 0.5, h * 0.5, d * 0.5)
	# View angle: 30° down from the side, far enough out that the box fits.
	var radius: float = max(w, d) * 1.6 + h * 0.6
	camera.position = center + Vector3(radius * 0.65, radius * 0.85, radius * 0.65)
	scene_root.add_child(camera)
	camera.look_at(center, Vector3.UP)

	# MultiMesh — W × H × D box of unit cubes. Layout: i = y*(W*D) + z*W + x
	# matching GridMutatorBase.cell_xyz so mutator iteration aligns with our layout.
	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = "GridMultiMesh"
	scene_root.add_child(_multimesh_instance)

	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.mesh = BoxMesh.new()
	_multimesh.instance_count = _grid_dims.x * _grid_dims.y * _grid_dims.z

	for y in range(_grid_dims.y):
		for z in range(_grid_dims.z):
			for x in range(_grid_dims.x):
				var idx: int = y * (_grid_dims.x * _grid_dims.z) + z * _grid_dims.x + x
				var xf := Transform3D()
				xf.origin = Vector3(float(x), float(y), float(z))
				_multimesh.set_instance_transform(idx, xf)
				_multimesh.set_instance_color(idx, Color.WHITE)
	_multimesh_instance.multimesh = _multimesh

	# Material — SimpleGrid shader so per-instance colors show
	var shader := load(SHADER_PATH)
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("show_interior", true)
		mat.set_shader_parameter("modelColor", Color.WHITE)
		mat.set_shader_parameter("wireframeColor", Color(0.0, 0.0, 0.0, 0.4))
		mat.set_shader_parameter("modelOpacity", 1.0)
		mat.set_shader_parameter("wireframeOpacity", 0.4)
		_multimesh_instance.material_override = mat
	else:
		var fallback := StandardMaterial3D.new()
		fallback.vertex_color_use_as_albedo = true
		_multimesh_instance.material_override = fallback

	# Mutators (loaded at runtime so the project's class registry is built first)
	var color_script: GDScript = load(GRID_COLOR_MUTATOR_PATH)
	var vis_script: GDScript = load(GRID_VISIBILITY_MUTATOR_PATH)
	var vis_expr_script: GDScript = load(GRID_VISIBILITY_EXPRESSIONS_PATH)
	var xform_script: GDScript = load(GRID_TRANSFORM_MUTATOR_PATH)
	var xform_expr_script: GDScript = load(GRID_TRANSFORM_EXPRESSIONS_PATH)
	if color_script == null or vis_script == null or vis_expr_script == null or xform_script == null or xform_expr_script == null:
		_fail("could not load mutator scripts")
		return

	_color_mutator = color_script.new()
	_color_mutator.name = "GridColorMutator"
	_color_mutator.multimesh_path = NodePath("../GridMultiMesh")
	_color_mutator.auto_cycle_enabled = false
	_color_mutator.debug_logs = false
	_color_mutator.grid_dims = _grid_dims
	scene_root.add_child(_color_mutator)

	_visibility_mutator = vis_script.new()
	_visibility_mutator.name = "GridVisibilityMutator"
	_visibility_mutator.multimesh_path = NodePath("../GridMultiMesh")
	_visibility_mutator.auto_cycle_enabled = false
	_visibility_mutator.debug_logs = false
	_visibility_mutator.grid_dims = _grid_dims
	scene_root.add_child(_visibility_mutator)

	_transform_mutator = xform_script.new()
	_transform_mutator.name = "GridTransformMutator"
	_transform_mutator.multimesh_path = NodePath("../GridMultiMesh")
	_transform_mutator.auto_cycle_enabled = false
	_transform_mutator.debug_logs = false
	_transform_mutator.grid_dims = _grid_dims
	scene_root.add_child(_transform_mutator)

	# Visibility expression registry — 2D (always) and 3D (only when volumetric)
	var vis_expressions: Node = vis_expr_script.new()
	vis_expressions.name = "GridVisibilityExpressions"
	scene_root.add_child(vis_expressions)
	vis_expressions.register_for(_visibility_mutator)

	if _grid_dims.y > 1:
		var vis3d_script: GDScript = load(GRID_VISIBILITY_EXPRESSIONS_3D_PATH)
		if vis3d_script:
			var vis3d: Node = vis3d_script.new()
			vis3d.name = "GridVisibilityExpressions3D"
			# Seed BFS at one corner so the frontier sweeps the box across the 8 steps.
			vis3d.bfs_seed = Vector3i(0, 0, 0)
			vis3d.bfs_steps = 8
			scene_root.add_child(vis3d)
			vis3d.register_for(_visibility_mutator)

	# Transform expression registry
	var xform_expressions: Node = xform_expr_script.new()
	xform_expressions.name = "GridTransformExpressions"
	scene_root.add_child(xform_expressions)
	xform_expressions.register_for(_transform_mutator)
	# Re-init the mutator's pattern list now that expressions exist
	_visibility_mutator.start_pattern_cycling()
	_visibility_mutator.disable_auto_cycle()

	_viewport = root.get_viewport()


# --- helpers ---------------------------------------------------------------

func _show_all_cubes() -> void:
	_reset_multimesh_transforms()
	_visibility_mutator.refresh_cached_transforms()


func _apply_solid_white() -> void:
	for i in range(_multimesh.instance_count):
		_multimesh.set_instance_color(i, Color.WHITE)


func _set_color_pattern_by_name(name: String) -> void:
	for i in range(_color_mutator.get_pattern_count()):
		_color_mutator.set_pattern_by_index(i)
		if _color_mutator.get_current_pattern_name() == name:
			return


func _set_visibility_pattern_by_name(name: String) -> void:
	for i in range(_visibility_mutator.get_pattern_count()):
		_visibility_mutator.set_pattern_by_index(i)
		if _visibility_mutator.get_current_pattern_name() == name:
			return


func _set_transform_pattern_by_name(name: String) -> void:
	for i in range(_transform_mutator.get_pattern_count()):
		_transform_mutator.set_pattern_by_index(i)
		if _transform_mutator.get_current_pattern_name() == name:
			return


# Reset all instance transforms to authored grid layout — no rotation, no
# offset, scale 1. Used between transform-pattern captures so each starts
# from a clean slate. Iteration matches the layout used in _build_scene.
func _reset_multimesh_transforms() -> void:
	for y in range(_grid_dims.y):
		for z in range(_grid_dims.z):
			for x in range(_grid_dims.x):
				var idx: int = y * (_grid_dims.x * _grid_dims.z) + z * _grid_dims.x + x
				var xf := Transform3D()
				xf.origin = Vector3(float(x), float(y), float(z))
				_multimesh.set_instance_transform(idx, xf)


func _capture(label: String) -> void:
	if not _viewport:
		_viewport = root.get_viewport()
	# Wait two frames so the MultiMesh re-uploads instance data
	await process_frame
	await process_frame
	var img: Image = _viewport.get_texture().get_image()
	if not img:
		_report.errors.append({"label": label, "reason": "viewport returned null image"})
		return
	var safe_label: String = label.replace("/", "_").replace("\\", "_")
	var path: String = "%s/%s.png" % [_outdir, safe_label]
	var abs_path: String = ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	var err: int = img.save_png(path)
	if err != OK:
		_report.errors.append({"label": label, "reason": "save_png err=%d" % err})
		return
	_report.shots.append({"label": label, "path": path, "abs": abs_path})
	print("  [shot] %s -> %s" % [label, path])


func _write_report() -> void:
	var path: String = "%s/capture_report.json" % _outdir
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_report, "  "))
		f.close()
		print("capture_mutator_cycle: report -> %s" % path)


func _fail(reason: String) -> void:
	push_error("capture_mutator_cycle: %s" % reason)
	_report.errors.append({"label": "fatal", "reason": reason})
	_write_report()
	quit(1)
