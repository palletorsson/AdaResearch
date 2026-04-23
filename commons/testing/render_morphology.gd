extends SceneTree

const MorphologySimClass = preload("res://commons/morphology_grammar/morphology_sim.gd")

var _config_path: String = ""
var _output_path: String = "user://morphology_gallery/out.png"
var _size: int = 640
var _wait: float = 1.0


func _initialize() -> void:
	_parse_args()
	if _config_path.is_empty():
		push_error("render_morphology: --config=<path> required")
		quit(1)
		return
	call_deferred("_run")


func _parse_args() -> void:
	for raw in OS.get_cmdline_user_args():
		var a := String(raw).strip_edges()
		if not a.begins_with("--"):
			continue
		var eq := a.find("=")
		if eq <= 2:
			continue
		var key := a.substr(2, eq - 2)
		var val := a.substr(eq + 1)
		match key:
			"config":
				_config_path = val
			"out":
				_output_path = val
			"size":
				if val.is_valid_int():
					_size = clampi(int(val), 128, 2048)
			"wait":
				if val.is_valid_float():
					_wait = float(val)


func _run() -> void:
	var txt := FileAccess.get_file_as_string(_config_path)
	if txt.is_empty():
		txt = FileAccess.get_file_as_string(ProjectSettings.globalize_path(_config_path))
	if txt.is_empty():
		push_error("render_morphology: empty config")
		quit(1)
		return
	var json := JSON.new()
	if json.parse(txt) != OK or not (json.data is Dictionary):
		push_error("render_morphology: invalid JSON")
		quit(1)
		return
	var cfg: Dictionary = json.data

	var sim = MorphologySimClass.new()
	var result: Dictionary = sim.simulate(cfg)
	var mesh: ArrayMesh = result.get("mesh")
	var mesh_data = result.get("mesh_data")
	var surface_names: Array = result.get("surface_names", [])
	if mesh == null or mesh.get_surface_count() == 0 or mesh_data == null:
		push_error("render_morphology: empty mesh")
		quit(1)
		return
	var render_mode := str(cfg.get("render_mode", "shaded"))

	var scene := Node3D.new()
	scene.name = "MorphologyRender"
	root.add_child(scene)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = _color(cfg.get("background", [0.09, 0.10, 0.14]))
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.58, 0.58, 0.64)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	scene.add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, -30, 0)
	key.light_energy = 1.35
	key.shadow_enabled = true
	scene.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-18, 126, 0)
	fill.light_energy = 0.35
	scene.add_child(fill)

	if render_mode != "wireframe":
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		for i in range(surface_names.size()):
			mi.set_surface_override_material(i, _material_for_role(_role_name(str(surface_names[i]))))
		scene.add_child(mi)
	if render_mode == "wireframe" or render_mode == "shaded_wire":
		scene.add_child(_build_wire_depth_occluder(mesh))
		scene.add_child(_build_wireframe(mesh_data, render_mode == "wireframe"))

	await process_frame
	await process_frame

	var aabb := mesh.get_aabb()
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(18, 18)
	ground.mesh = plane
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.12, 0.13, 0.16)
	ground_mat.roughness = 0.96
	ground.material_override = ground_mat
	ground.position = Vector3(0, aabb.position.y - 0.01, 0)
	scene.add_child(ground)

	var cam := Camera3D.new()
	cam.current = true
	cam.fov = 44
	scene.add_child(cam)
	var center := aabb.get_center()
	var max_dim := maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
	var dist := maxf(max_dim * 2.2, 2.3)
	var yaw := float(cfg.get("camera_yaw", 0.72))
	var pitch := float(cfg.get("camera_pitch", 0.42))
	var offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * dist
	cam.global_position = center + offset
	cam.look_at(center + Vector3(0, aabb.size.y * 0.08, 0), Vector3.UP)

	root.content_scale_size = Vector2i(_size, _size)
	root.size = Vector2i(_size, _size)

	await create_timer(_wait).timeout
	await process_frame
	await process_frame

	var img: Image = root.get_texture().get_image()
	if img == null:
		push_error("render_morphology: no image")
		quit(1)
		return

	var abs_out := ProjectSettings.globalize_path(_output_path)
	var out_dir := abs_out.get_base_dir()
	if not DirAccess.dir_exists_absolute(out_dir):
		DirAccess.make_dir_recursive_absolute(out_dir)
	var err := img.save_png(abs_out)
	if err != OK:
		push_error("render_morphology: save failed")
		quit(1)
		return
	print("render_morphology: saved %s" % abs_out)
	quit(0)


func _role_name(tag: String) -> String:
	return tag.trim_prefix("role:")


func _material_for_role(role: String) -> Material:
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.72
	mat.metallic = 0.0
	match role:
		"body", "wall":
			mat.albedo_color = Color(0.76, 0.68, 0.56)
		"cushion":
			mat.albedo_color = Color(0.78, 0.88, 0.92)
			mat.roughness = 0.62
		"support":
			mat.albedo_color = Color(0.72, 0.76, 0.82)
			mat.roughness = 0.28
			mat.metallic = 0.18
		"garment":
			mat.albedo_color = Color(0.88, 0.33, 0.62)
			mat.roughness = 0.46
		"hair":
			mat.albedo_color = Color(0.91, 0.78, 0.3)
			mat.roughness = 0.58
		"heel":
			mat.albedo_color = Color(0.15, 0.14, 0.18)
			mat.roughness = 0.34
		"ornament":
			mat.albedo_color = Color(0.52, 0.84, 0.86)
			mat.roughness = 0.26
			mat.metallic = 0.12
		"trunk", "branch":
			mat.albedo_color = Color(0.42, 0.28, 0.17)
			mat.roughness = 0.88
		"tip":
			mat.albedo_color = Color(0.36, 0.63, 0.31)
		"aperture":
			mat.albedo_color = Color(0.16, 0.19, 0.24)
			mat.roughness = 0.92
		"cap":
			mat.albedo_color = Color(0.63, 0.24, 0.18)
			mat.roughness = 0.78
		_:
			mat.albedo_color = Color(0.78, 0.78, 0.82)
	return mat


func _color(raw: Variant) -> Color:
	if raw is Array and raw.size() >= 3:
		return Color(float(raw[0]), float(raw[1]), float(raw[2]))
	return Color(0.09, 0.10, 0.14)


func _build_wireframe(mesh_data, wire_only: bool) -> MeshInstance3D:
	var im := ImmediateMesh.new()
	var drawn: Dictionary = {}
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for face in mesh_data.faces:
		if not (face is PackedInt32Array) or face.size() != 3:
			continue
		_add_wire_edge(im, mesh_data, drawn, int(face[0]), int(face[1]), wire_only)
		_add_wire_edge(im, mesh_data, drawn, int(face[1]), int(face[2]), wire_only)
		_add_wire_edge(im, mesh_data, drawn, int(face[2]), int(face[0]), wire_only)
	im.surface_end()

	var mi := MeshInstance3D.new()
	mi.mesh = im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.95, 0.98, 1.0) if wire_only else Color(0.04, 0.05, 0.06)
	mat.no_depth_test = false
	mat.flags_transparent = false
	mi.material_override = mat
	return mi


func _build_wire_depth_occluder(mesh: ArrayMesh) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.36, 0.39, 0.41)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.disable_receive_shadows = true
	mat.no_depth_test = false
	mi.material_override = mat
	return mi


func _add_wire_edge(im: ImmediateMesh, mesh_data, drawn: Dictionary, a: int, b: int, wire_only: bool) -> void:
	var lo := mini(a, b)
	var hi := maxi(a, b)
	var key := "%d_%d" % [lo, hi]
	if drawn.has(key):
		return
	drawn[key] = true
	var offset := Vector3.ZERO if wire_only else Vector3(0, 0.0008, 0)
	im.surface_add_vertex(mesh_data.vertices[a] + offset)
	im.surface_add_vertex(mesh_data.vertices[b] + offset)
