extends SceneTree

## Render one substrate config to a PNG. Reads a JSON config, builds a
## synthetic MultiMesh scene, mounts the channels per config, applies the
## chosen patterns, captures one PNG. Mirror of render_mesh_grammar.gd's
## convention so the same auto-research pipeline (tools/substrate_research.py)
## drives both at the same shape.
##
## Usage:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/render_substrate_config.gd -- \
##     --config=<path>.json --out=user://sub_gallery/<id>.png --size=640

const SHADER_PATH := "res://commons/resourses/shaders/SimpleGrid.gdshader"
const VIS_MUTATOR_PATH := "res://commons/grid/mutators/grid_visibility_mutator.gd"
const VIS_EXPR_PATH := "res://commons/grid/mutators/grid_visibility_expressions.gd"
const VIS_EXPR_3D_PATH := "res://commons/grid/mutators/grid_visibility_expressions_3d.gd"
const COLOR_MUTATOR_PATH := "res://commons/grid/mutators/grid_color_mutator.gd"
const TRANSFORM_MUTATOR_PATH := "res://commons/grid/mutators/grid_transform_mutator.gd"
const TRANSFORM_EXPR_PATH := "res://commons/grid/mutators/grid_transform_expressions.gd"
const GLYPH_MUTATOR_PATH := "res://commons/grid/mutators/grid_glyph_mutator.gd"
const GLYPH_EXPR_PATH := "res://commons/grid/mutators/grid_glyph_expressions.gd"
const PART_MUTATOR_PATH := "res://commons/grid/mutators/grid_part_mutator.gd"
const PART_EXPR_PATH := "res://commons/grid/mutators/grid_part_expressions.gd"

var _config_path: String = ""
var _out_path: String = "user://sub_gallery/render.png"
var _size: int = 640


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
			"config":
				_config_path = value
			"out":
				_out_path = value
			"size":
				if value.is_valid_int():
					_size = max(int(value), 128)
	if _config_path.is_empty():
		push_error("render_substrate_config: --config=<path> required")
		quit(1)
		return
	call_deferred("_run")


func _load_config() -> Dictionary:
	var f := FileAccess.open(_config_path, FileAccess.READ)
	if not f:
		return {}
	var raw: String = f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(raw)
	return parsed if parsed is Dictionary else {}


func _run() -> void:
	var cfg: Dictionary = _load_config()
	if cfg.is_empty():
		push_error("render_substrate_config: failed to load config from %s" % _config_path)
		quit(1)
		return
	var cid: String = str(cfg.get("id", "untitled"))
	print("render_substrate_config: id=%s out=%s" % [cid, _out_path])

	# Volume dims
	var dims_arr: Array = cfg.get("grid_dims", [12, 4, 12])
	var grid_dims := Vector3i(int(dims_arr[0]), int(dims_arr[1]), int(dims_arr[2]))

	# Build scene
	var scene_root := Node3D.new()
	scene_root.name = "SubstrateRenderRoot"
	root.add_child(scene_root)
	_build_environment(scene_root, grid_dims, cfg)
	var mmi := _build_multimesh(scene_root, grid_dims)

	# Mount visibility (always — it's the substrate's spine)
	var vis_script: GDScript = load(VIS_MUTATOR_PATH)
	var vis_expr_script: GDScript = load(VIS_EXPR_PATH)
	var vis: Node = vis_script.new()
	vis.name = "GridVisibilityMutator"
	vis.multimesh_path = NodePath("../GridMultiMesh")
	vis.grid_dims = grid_dims
	vis.auto_cycle_enabled = false
	vis.debug_logs = false
	scene_root.add_child(vis)
	var vis_expr: Node = vis_expr_script.new()
	scene_root.add_child(vis_expr)
	vis_expr.register_for(vis)
	if cfg.get("enable_3d_expressions", false) and grid_dims.y > 1:
		var vis3d_script: GDScript = load(VIS_EXPR_3D_PATH)
		if vis3d_script:
			var vis3d: Node = vis3d_script.new()
			scene_root.add_child(vis3d)
			vis3d.register_for(vis)

	# Optional channels
	var part: Node = null
	if cfg.get("enable_part", false):
		var part_script: GDScript = load(PART_MUTATOR_PATH)
		var part_expr_script: GDScript = load(PART_EXPR_PATH)
		part = part_script.new()
		part.name = "GridPartMutator"
		part.multimesh_path = NodePath("../GridMultiMesh")
		part.grid_dims = grid_dims
		part.auto_cycle_enabled = false
		scene_root.add_child(part)
		var part_expr: Node = part_expr_script.new()
		scene_root.add_child(part_expr)
		part_expr.register_for(part)

	var glyph: Node = null
	if cfg.get("enable_glyph", false):
		var glyph_script: GDScript = load(GLYPH_MUTATOR_PATH)
		var glyph_expr_script: GDScript = load(GLYPH_EXPR_PATH)
		glyph = glyph_script.new()
		glyph.name = "GridGlyphMutator"
		glyph.multimesh_path = NodePath("../GridMultiMesh")
		glyph.grid_dims = grid_dims
		glyph.auto_cycle_enabled = false
		glyph.cube_size = 1.0
		glyph.max_subdivided_cells = int(cfg.get("glyph_max_cells", 64))
		glyph.viewer_radius = float(cfg.get("glyph_viewer_radius", 4.0))
		# Centre attention for repeatable shots
		glyph.viewer_position = Vector3(grid_dims.x * 0.5, 0, grid_dims.z * 0.5)
		scene_root.add_child(glyph)
		var glyph_expr: Node = glyph_expr_script.new()
		scene_root.add_child(glyph_expr)
		glyph_expr.register_for(glyph)

	# Wait for all mutators to find the multimesh.
	await create_timer(1.5).timeout

	# Set seed/target for PATH_GUARANTEE if requested.
	if cfg.has("floor_plan_mode"):
		vis.floor_plan_mode = int(cfg["floor_plan_mode"])
	if cfg.has("path_seed"):
		var ps: Array = cfg["path_seed"]
		vis.floor_plan_seed = Vector3i(int(ps[0]), int(ps[1]), int(ps[2]))
	if cfg.has("path_target"):
		var pt: Array = cfg["path_target"]
		vis.floor_plan_target = Vector3i(int(pt[0]), int(pt[1]), int(pt[2]))

	# Apply chosen visibility pattern.
	var vis_pattern: String = str(cfg.get("visibility", "rule_30"))
	for j in range(vis.get_pattern_count()):
		vis.set_pattern_by_index(j)
		if vis.get_current_pattern_name() == vis_pattern:
			break

	# Apply chosen part grammar (if part enabled).
	if part and cfg.has("part_grammar"):
		var part_pat: String = str(cfg["part_grammar"])
		for j in range(part.get_pattern_count()):
			part.set_pattern_by_index(j)
			if part.get_current_pattern_name() == part_pat:
				break

	# Apply chosen glyph policy (if glyph enabled).
	if glyph and cfg.has("glyph_policy"):
		var gp: String = str(cfg["glyph_policy"])
		for j in range(glyph.get_pattern_count()):
			glyph.set_pattern_by_index(j)
			if glyph.get_current_pattern_name() == gp:
				break

	# If part + color-by-role, paint per palette.
	if part and cfg.has("color_by_role"):
		await create_timer(0.4).timeout
		var palette: Dictionary = cfg["color_by_role"]
		var mm: MultiMesh = mmi.multimesh
		for i in range(mm.instance_count):
			var role: StringName = part.get_role(i)
			var key: String = String(role)
			var color: Color = Color.WHITE
			if palette.has(key):
				var c: Array = palette[key]
				color = Color(float(c[0]), float(c[1]), float(c[2]))
			mm.set_instance_color(i, color)

	# Settle, then capture.
	await create_timer(0.6).timeout
	await process_frame
	await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	if not img:
		push_error("render_substrate_config: viewport returned null image")
		quit(1)
		return
	# Ensure the output directory exists.
	var out_abs: String = ProjectSettings.globalize_path(_out_path)
	DirAccess.make_dir_recursive_absolute(out_abs.get_base_dir())
	var err: int = img.save_png(_out_path)
	if err != OK:
		push_error("render_substrate_config: save_png err=%d at %s" % [err, _out_path])
		quit(1)
		return
	print("render_substrate_config: wrote %s" % _out_path)
	quit(0)


func _build_environment(scene_root: Node3D, dims: Vector3i, cfg: Dictionary) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	var bg: Array = cfg.get("background", [0.10, 0.10, 0.13])
	env.background_color = Color(float(bg[0]), float(bg[1]), float(bg[2]))
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.65)
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	scene_root.add_child(we)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -45, 0)
	light.light_energy = 1.2
	scene_root.add_child(light)
	var camera := Camera3D.new()
	camera.current = true
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = float(max(dims.x, dims.z)) * 1.4
	var center := Vector3(dims.x * 0.5, dims.y * 0.5, dims.z * 0.5)
	var radius := float(max(dims.x, dims.z)) * 1.6 + dims.y * 0.5
	camera.position = center + Vector3(radius * 0.65, radius * 0.85, radius * 0.65)
	scene_root.add_child(camera)
	camera.look_at(center, Vector3.UP)


func _build_multimesh(scene_root: Node3D, dims: Vector3i) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "GridMultiMesh"
	scene_root.add_child(mmi)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var box := BoxMesh.new()
	box.size = Vector3(0.92, 0.92, 0.92)
	mm.mesh = box
	mm.instance_count = dims.x * dims.y * dims.z
	for y in range(dims.y):
		for z in range(dims.z):
			for x in range(dims.x):
				var idx: int = y * (dims.x * dims.z) + z * dims.x + x
				var xf := Transform3D()
				xf.origin = Vector3(float(x), float(y), float(z))
				mm.set_instance_transform(idx, xf)
				mm.set_instance_color(idx, Color.WHITE)
	mmi.multimesh = mm
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("show_interior", true)
		mat.set_shader_parameter("modelColor", Color.WHITE)
		mat.set_shader_parameter("wireframeColor", Color(0.4, 0.5, 0.8, 0.6))
		mat.set_shader_parameter("modelOpacity", 1.0)
		mat.set_shader_parameter("wireframeOpacity", 0.4)
		mmi.material_override = mat
	return mmi
