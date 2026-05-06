extends SceneTree

## Render a single body_recipe form with custom DNA to a PNG.
## Used by the Form Gallery + Form Studio in the encyclopedia.
##
## Usage:
##   godot_console --path . --xr-mode off --no-window \
##     --script res://commons/testing/render_form.gd -- \
##     --recipe=res://commons/morphology/sdf/flower_body.gd \
##     --dna='{"scale":0.8,"segments":4,"symmetry":6}' \
##     --materials=flower \
##     --out=user://form_gallery/flower_classic.png \
##     --size=512
##
## DNA is a JSON object. Materials is one of: flower | fungus | walker | tree |
## stone | ceramic | neutral.

const SHADER_PLANT = preload("res://commons/morphology/sdf/shaders/plant.gdshader")
const SHADER_FLESH = preload("res://commons/morphology/sdf/shaders/flesh.gdshader")
const SHADER_BARK  = preload("res://commons/morphology/sdf/shaders/bark.gdshader")

var _recipe_path: String = ""
var _dna_json: String = "{}"
var _materials_key: String = "neutral"
var _output_path: String = "user://form_renders/out.png"
var _size: int = 512
var _wait: float = 1.2
var _yaw: float = 0.55
var _pitch: float = -0.3


func _initialize() -> void:
	_parse_args()
	if _recipe_path.is_empty():
		push_error("render_form: --recipe=<path> is required")
		quit(1); return
	call_deferred("_run")


func _parse_args() -> void:
	for raw in OS.get_cmdline_user_args():
		var arg := String(raw).strip_edges()
		if not arg.begins_with("--"): continue
		var eq := arg.find("=")
		if eq <= 2: continue
		var key := arg.substr(2, eq - 2)
		var val := arg.substr(eq + 1)
		match key:
			"recipe":    _recipe_path = val
			"dna":       _dna_json = val
			"materials": _materials_key = val
			"out":       _output_path = val
			"size":      if val.is_valid_int(): _size = clampi(int(val), 128, 2048)
			"wait":      if val.is_valid_float(): _wait = float(val)
			"yaw":       if val.is_valid_float(): _yaw = float(val)
			"pitch":     if val.is_valid_float(): _pitch = float(val)


func _run() -> void:
	# Parse DNA
	var json := JSON.new()
	var dna: Dictionary = {}
	if json.parse(_dna_json) == OK and json.data is Dictionary:
		dna = json.data
	else:
		push_warning("render_form: DNA failed to parse, using empty dict")

	# Load recipe
	if not ResourceLoader.exists(_recipe_path):
		push_error("render_form: Recipe not found: %s" % _recipe_path)
		quit(1); return
	var recipe_script: GDScript = load(_recipe_path)
	var recipe = recipe_script.new()
	recipe.dna = dna
	if "joint_k" in recipe:
		recipe.joint_k = 0.08
	recipe.build()

	# Scene scaffold
	var scene := Node3D.new()
	scene.name = "RenderScene"
	root.add_child(scene)

	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.13, 0.14, 0.18)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.52, 0.6)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.ssao_intensity = 0.4
	var we := WorldEnvironment.new()
	we.environment = env
	scene.add_child(we)

	# Key + fill light
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, -28, 0)
	key.light_energy = 1.25
	key.shadow_enabled = true
	scene.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-18, 150, 0)
	fill.light_energy = 0.4
	scene.add_child(fill)

	# Ground
	var ground := MeshInstance3D.new()
	var gm := PlaneMesh.new(); gm.size = Vector2(12, 12)
	ground.mesh = gm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.12, 0.13, 0.16)
	gmat.roughness = 0.95
	ground.material_override = gmat
	scene.add_child(ground)

	# Build body
	var materials := _materials_for_key(_materials_key)
	var body: Node3D = recipe.build_mesh_body(materials)
	if body == null:
		push_error("render_form: recipe returned null body")
		quit(1); return
	scene.add_child(body)

	# Camera — auto-fit via AABB
	var cam := Camera3D.new()
	cam.current = true
	cam.fov = 42.0
	scene.add_child(cam)

	await process_frame
	await process_frame

	var aabb: AABB = _combined_aabb(body)
	var focus: Vector3 = aabb.get_center()
	var max_dim: float = maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
	var dist: float = maxf(max_dim * 2.0, 1.5)
	var offset := Vector3(
		sin(_yaw) * cos(_pitch),
		sin(_pitch),
		cos(_yaw) * cos(_pitch)
	) * dist
	cam.global_position = focus + offset
	cam.look_at(focus, Vector3.UP)

	# Set viewport render size
	root.content_scale_size = Vector2i(_size, _size)
	root.size = Vector2i(_size, _size)

	await create_timer(_wait).timeout
	await process_frame
	await process_frame

	# Save
	var image: Image = root.get_texture().get_image()
	if image == null:
		push_error("render_form: could not read viewport image")
		quit(1); return

	var abs_out: String = ProjectSettings.globalize_path(_output_path)
	var out_dir := abs_out.get_base_dir()
	if not DirAccess.dir_exists_absolute(out_dir):
		DirAccess.make_dir_recursive_absolute(out_dir)

	var err := image.save_png(abs_out)
	if err != OK:
		push_error("render_form: failed to save %s (err=%d)" % [abs_out, err])
		quit(1); return

	print("render_form: saved %s" % abs_out)
	quit(0)


func _combined_aabb(node: Node3D) -> AABB:
	var total: AABB = AABB()
	var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is MeshInstance3D and n.mesh:
			var m_aabb: AABB = n.global_transform * n.get_aabb()
			if first:
				total = m_aabb; first = false
			else:
				total = total.merge(m_aabb)
		for c in n.get_children():
			if c is Node3D: stack.append(c)
	if first:
		return AABB(Vector3(-1, 0, -1), Vector3(2, 2, 2))
	return total


# ─── Material library ───────────────────────────────────────────

func _materials_for_key(key: String) -> Dictionary:
	match key:
		"flower":  return _flower_materials()
		"fungus":  return _fungus_materials()
		"walker":  return _walker_materials()
		"tree":    return _tree_materials()
		"stone":   return _stone_materials()
		"ceramic": return _ceramic_materials()
		_:         return _neutral_materials()


func _neutral_materials() -> Dictionary:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.88, 0.85, 0.75)
	mat.roughness = 0.6
	return {"default": mat, "body": mat}

func _stone_materials() -> Dictionary:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.78, 0.76, 0.72)
	mat.roughness = 0.9
	mat.metallic = 0.0
	return {"default": mat, "body": mat,
		"shaft": mat, "plinth": mat, "capital": mat, "abacus": mat,
		"base": mat, "die": mat, "cornice": mat,
		"wall_block": mat, "rubble": mat, "base_course": mat}

func _ceramic_materials() -> Dictionary:
	var body := StandardMaterial3D.new()
	body.albedo_color = Color(0.55, 0.28, 0.18)
	body.roughness = 0.55
	body.metallic = 0.1
	return {"default": body, "body": body,
		"foot": body, "belly": body, "shoulder": body,
		"neck": body, "lip": body, "handle": body}

func _tree_materials() -> Dictionary:
	var bark := ShaderMaterial.new()
	bark.shader = SHADER_BARK
	bark.set_shader_parameter("bark_color", Color(0.38, 0.25, 0.17))
	bark.set_shader_parameter("crevice_color", Color(0.12, 0.08, 0.05))
	var leaf := ShaderMaterial.new()
	leaf.shader = SHADER_PLANT
	leaf.set_shader_parameter("base_color", Color(0.25, 0.5, 0.2))
	leaf.set_shader_parameter("edge_color", Color(0.8, 0.9, 0.5))
	return {"body": bark, "default": leaf}

func _walker_materials() -> Dictionary:
	var skin := ShaderMaterial.new()
	skin.shader = SHADER_FLESH
	skin.set_shader_parameter("skin_color", Color(0.75, 0.62, 0.5))
	skin.set_shader_parameter("interior_color", Color(0.9, 0.4, 0.3))
	return {"default": skin, "body": skin}

func _flower_materials() -> Dictionary:
	var stem := ShaderMaterial.new(); stem.shader = SHADER_PLANT
	stem.set_shader_parameter("base_color", Color(0.25, 0.48, 0.18))
	var leaf := ShaderMaterial.new(); leaf.shader = SHADER_PLANT
	leaf.set_shader_parameter("base_color", Color(0.3, 0.55, 0.2))
	leaf.set_shader_parameter("vein_strength", 0.25)
	var petal := ShaderMaterial.new(); petal.shader = SHADER_PLANT
	petal.set_shader_parameter("base_color", Color(0.95, 0.45, 0.65))
	petal.set_shader_parameter("edge_color", Color(1.0, 0.85, 0.9))
	petal.set_shader_parameter("rim_strength", 1.5)
	var stamen := ShaderMaterial.new(); stamen.shader = SHADER_FLESH
	stamen.set_shader_parameter("skin_color", Color(1.0, 0.85, 0.3))
	stamen.set_shader_parameter("interior_color", Color(1.0, 0.5, 0.1))
	return {"stem": stem, "leaf": leaf, "petal": petal, "stamen": stamen, "default": stem}

func _fungus_materials() -> Dictionary:
	var stem := ShaderMaterial.new(); stem.shader = SHADER_BARK
	stem.set_shader_parameter("bark_color", Color(0.85, 0.78, 0.65))
	stem.set_shader_parameter("crevice_color", Color(0.55, 0.45, 0.35))
	var cap := ShaderMaterial.new(); cap.shader = SHADER_FLESH
	cap.set_shader_parameter("skin_color", Color(0.65, 0.28, 0.25))
	cap.set_shader_parameter("interior_color", Color(0.35, 0.1, 0.08))
	return {"default": stem, "body": stem, "cap": cap}
