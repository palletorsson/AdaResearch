extends SceneTree

## Smoke test for GridPartMutator. Builds a small self-contained MultiMesh,
## mounts the part mutator + part-expressions, applies each grammar in turn,
## and paints the multimesh per-role so the role-tagging is visually legible.
##
## Usage:
##   godot_console --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_part_test.gd \
##     -- --grammar=flower_grammar --out=user://part_test

const SHADER_PATH := "res://commons/resourses/shaders/SimpleGrid.gdshader"
const PART_MUTATOR_PATH := "res://commons/grid/mutators/grid_part_mutator.gd"
const PART_EXPR_PATH := "res://commons/grid/mutators/grid_part_expressions.gd"

# Per-grammar palette: role -> colour. Roles not in the dict get white.
const FLOWER_PALETTE := {
	&"pistil": Color(1.0, 0.85, 0.2),     # gold
	&"stamen": Color(0.95, 0.55, 0.85),   # pink
	&"petal":  Color(0.65, 0.2, 0.5),     # magenta
	&"sepal":  Color(0.3, 0.6, 0.35),     # green
}
const INSECT_PALETTE := {
	&"head":    Color(0.85, 0.3, 0.25),   # red
	&"thorax":  Color(0.95, 0.75, 0.2),   # amber
	&"abdomen": Color(0.35, 0.4, 0.7),    # indigo
}
const BIRD_PALETTE := {
	&"head":    Color(0.85, 0.3, 0.25),
	&"throat":  Color(0.95, 0.55, 0.4),
	&"breast":  Color(0.95, 0.75, 0.2),
	&"belly":   Color(0.92, 0.92, 0.85),
	&"back":    Color(0.45, 0.5, 0.6),
	&"flanks":  Color(0.7, 0.7, 0.55),
	&"wing":    Color(0.25, 0.3, 0.45),
	&"tail":    Color(0.35, 0.45, 0.5),
	&"vent":    Color(0.6, 0.55, 0.45),
}

var _grammar: String = "flower_grammar"
var _outdir: String = "user://part_test"
var _grid_dims: Vector3i = Vector3i(13, 5, 13)


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
			"grammar":
				_grammar = value
			"out":
				_outdir = value


func _run() -> void:
	print("capture_part_test: grammar=%s outdir=%s" % [_grammar, _outdir])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_outdir))

	var scene_root := Node3D.new()
	scene_root.name = "PartTestRoot"
	root.add_child(scene_root)
	_build_environment(scene_root)
	var mmi: MultiMeshInstance3D = _build_multimesh(scene_root)

	var part_script: GDScript = load(PART_MUTATOR_PATH)
	var part_expr_script: GDScript = load(PART_EXPR_PATH)
	var part: Node = part_script.new()
	part.name = "GridPartMutator"
	part.multimesh_path = NodePath("../GridMultiMesh")
	part.grid_dims = _grid_dims
	part.auto_cycle_enabled = false
	part.debug_logs = true
	scene_root.add_child(part)
	var part_expr: Node = part_expr_script.new()
	scene_root.add_child(part_expr)
	part_expr.register_for(part)

	await create_timer(1.5).timeout

	# Run each grammar; for the requested grammar, capture; for others, log only.
	var grammars: Array = ["flower_grammar", "insect_grammar", "bird_grammar"]
	for g in grammars:
		# Set pattern by walking the registry.
		for j in range(part.get_pattern_count()):
			part.set_pattern_by_index(j)
			if part.get_current_pattern_name() == g:
				break
		await create_timer(0.4).timeout
		_paint_by_role(mmi, part, _palette_for(g))
		await process_frame
		await process_frame
		_save("part_%s" % g)
		print("  -> %s: %s" % [g, str(part.get_role_counts())])

	quit(0)


func _palette_for(grammar: String) -> Dictionary:
	match grammar:
		"flower_grammar":
			return FLOWER_PALETTE
		"insect_grammar":
			return INSECT_PALETTE
		"bird_grammar":
			return BIRD_PALETTE
	return {}


func _paint_by_role(mmi: MultiMeshInstance3D, part_mutator: Node, palette: Dictionary) -> void:
	var mm: MultiMesh = mmi.multimesh
	for i in range(mm.instance_count):
		var role: StringName = part_mutator.get_role(i)
		var color: Color = palette.get(role, Color.WHITE)
		mm.set_instance_color(i, color)


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
	camera.size = float(max(_grid_dims.x, _grid_dims.z)) * 1.5
	var center := Vector3(_grid_dims.x * 0.5, _grid_dims.y * 0.5, _grid_dims.z * 0.5)
	var radius := float(max(_grid_dims.x, _grid_dims.z)) * 1.6 + _grid_dims.y * 0.5
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


func _save(label: String) -> void:
	await process_frame
	await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	if not img:
		print("  [shot] %s -> NULL" % label)
		return
	var path: String = "%s/%s.png" % [_outdir, label]
	img.save_png(path)
	print("  [shot] %s -> %s" % [label, path])
