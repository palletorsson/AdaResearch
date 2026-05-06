extends SceneTree

## Smoke test for GridGlyphMutator. Builds a small 12×8×12 self-contained
## MultiMesh, mounts a visibility mutator + the glyph mutator on top, runs
## one visibility expression and one glyph policy, captures.
##
## Usage:
##   godot_console --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_glyph_test.gd \
##     -- --vis=rule_30 --glyph=subdivide_by_attention --out=user://glyph_test

const SHADER_PATH := "res://commons/resourses/shaders/SimpleGrid.gdshader"
const VIS_MUTATOR_PATH := "res://commons/grid/mutators/grid_visibility_mutator.gd"
const VIS_EXPR_PATH := "res://commons/grid/mutators/grid_visibility_expressions.gd"
const GLYPH_MUTATOR_PATH := "res://commons/grid/mutators/grid_glyph_mutator.gd"
const GLYPH_EXPR_PATH := "res://commons/grid/mutators/grid_glyph_expressions.gd"

var _vis_pattern: String = "rule_30"
var _glyph_pattern: String = "subdivide_by_attention"
var _outdir: String = "user://glyph_test"
var _grid_dims: Vector3i = Vector3i(12, 1, 12)  # flat for clarity


func _initialize() -> void:
	_parse_args()
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
			"vis":
				_vis_pattern = value
			"glyph":
				_glyph_pattern = value
			"out":
				_outdir = value


func _run() -> void:
	print("capture_glyph_test: vis=%s glyph=%s outdir=%s" % [_vis_pattern, _glyph_pattern, _outdir])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_outdir))

	var scene_root := Node3D.new()
	scene_root.name = "GlyphTestRoot"
	root.add_child(scene_root)
	_build_environment(scene_root)
	var mmi: MultiMeshInstance3D = _build_multimesh(scene_root)

	# Mount visibility.
	var vis_script: GDScript = load(VIS_MUTATOR_PATH)
	var vis_expr_script: GDScript = load(VIS_EXPR_PATH)
	var vis: Node = vis_script.new()
	vis.name = "GridVisibilityMutator"
	vis.multimesh_path = NodePath("../GridMultiMesh")
	vis.grid_dims = _grid_dims
	vis.auto_cycle_enabled = false
	scene_root.add_child(vis)
	var vis_expr: Node = vis_expr_script.new()
	scene_root.add_child(vis_expr)
	vis_expr.register_for(vis)

	# Wait for vis _ready (it does an internal 1s timer).
	await create_timer(1.5).timeout

	# Force the chosen vis pattern.
	vis.disable_auto_cycle()
	for j in range(vis.get_pattern_count()):
		vis.set_pattern_by_index(j)
		if vis.get_current_pattern_name() == _vis_pattern:
			break
	await create_timer(0.4).timeout
	_save(mmi, scene_root, "01_vis_only")

	# Mount glyph on top.
	var glyph_script: GDScript = load(GLYPH_MUTATOR_PATH)
	var glyph_expr_script: GDScript = load(GLYPH_EXPR_PATH)
	var glyph: Node = glyph_script.new()
	glyph.name = "GridGlyphMutator"
	glyph.multimesh_path = NodePath("../GridMultiMesh")
	glyph.grid_dims = _grid_dims
	glyph.auto_cycle_enabled = false
	glyph.cube_size = 1.0
	glyph.max_subdivided_cells = 64
	glyph.viewer_position = Vector3(_grid_dims.x * 0.5, 0, _grid_dims.z * 0.5)  # centre
	glyph.viewer_radius = 4.0
	glyph.debug_logs = true
	scene_root.add_child(glyph)
	var glyph_expr: Node = glyph_expr_script.new()
	scene_root.add_child(glyph_expr)
	glyph_expr.register_for(glyph)

	await create_timer(1.5).timeout

	# Force the chosen glyph policy.
	glyph.disable_auto_cycle()
	for j in range(glyph.get_pattern_count()):
		glyph.set_pattern_by_index(j)
		if glyph.get_current_pattern_name() == _glyph_pattern:
			break
	await create_timer(0.4).timeout
	_save(mmi, scene_root, "02_vis_plus_glyph")

	await create_timer(0.4).timeout

	# Quick walkability / state report.
	var sub_count := 0
	if "_subdivided" in glyph:
		var sb: PackedByteArray = glyph._subdivided
		for k in range(sb.size()):
			if sb[k] != 0:
				sub_count += 1
	print("capture_glyph_test: subdivided %d parents (max %d)" % [sub_count, glyph.max_subdivided_cells])

	quit(0)


func _build_environment(scene_root: Node3D) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.10, 0.10, 0.13)
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
	camera.size = float(max(_grid_dims.x, _grid_dims.z)) * 1.4
	var center := Vector3(_grid_dims.x * 0.5, _grid_dims.y * 0.5, _grid_dims.z * 0.5)
	var radius := float(max(_grid_dims.x, _grid_dims.z)) * 1.6
	camera.position = center + Vector3(radius * 0.65, radius * 0.85, radius * 0.65)
	scene_root.add_child(camera)
	camera.look_at(center, Vector3.UP)


func _build_multimesh(scene_root: Node3D) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "GridMultiMesh"
	scene_root.add_child(mmi)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var box := BoxMesh.new()
	box.size = Vector3(0.92, 0.92, 0.92)
	mm.mesh = box
	mm.instance_count = _grid_dims.x * _grid_dims.y * _grid_dims.z
	for y in range(_grid_dims.y):
		for z in range(_grid_dims.z):
			for x in range(_grid_dims.x):
				var idx: int = y * (_grid_dims.x * _grid_dims.z) + z * _grid_dims.x + x
				var xf := Transform3D()
				xf.origin = Vector3(float(x), float(y), float(z))
				mm.set_instance_transform(idx, xf)
				mm.set_instance_color(idx, Color.WHITE)
	mmi.multimesh = mm
	# Material — SimpleGrid.
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("show_interior", true)
		mat.set_shader_parameter("modelColor", Color.WHITE)
		mat.set_shader_parameter("wireframeColor", Color(0.4, 0.5, 0.8, 0.6))
		mat.set_shader_parameter("modelOpacity", 1.0)
		mat.set_shader_parameter("wireframeOpacity", 0.5)
		mmi.material_override = mat
	return mmi


func _save(_mmi: MultiMeshInstance3D, _scene_root: Node3D, label: String) -> void:
	await process_frame
	await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	if not img:
		print("  [shot] %s -> NULL" % label)
		return
	var path: String = "%s/%s.png" % [_outdir, label]
	img.save_png(path)
	print("  [shot] %s -> %s" % [label, path])
