extends SceneTree

## Render a primitive stack config to a PNG.
## Usage:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/render_primitive_stack.gd -- \
##     --config=<path.json> --out=user://ps_gallery/<id>.png --size=640

const PrimitiveStackScript = preload("res://commons/primitive_grammar/primitive_stack.gd")
const NoiseDisplacePS      = preload("res://commons/noise_grammar/noise_displace.gd")

var _config_path: String = ""
var _output_path: String = "user://ps_gallery/out.png"
var _size: int = 640
var _wait: float = 1.0


func _initialize() -> void:
	_parse_args()
	if _config_path.is_empty():
		push_error("render_primitive_stack: --config required")
		quit(1); return
	call_deferred("_run")


func _parse_args() -> void:
	for raw in OS.get_cmdline_user_args():
		var a := String(raw).strip_edges()
		if not a.begins_with("--"): continue
		var eq := a.find("=")
		if eq <= 2: continue
		var key := a.substr(2, eq - 2)
		var val := a.substr(eq + 1)
		match key:
			"config": _config_path = val
			"out":    _output_path = val
			"size":   if val.is_valid_int(): _size = clampi(int(val), 128, 2048)
			"wait":   if val.is_valid_float(): _wait = float(val)


func _run() -> void:
	var txt := FileAccess.get_file_as_string(_config_path)
	if txt.is_empty():
		txt = FileAccess.get_file_as_string(ProjectSettings.globalize_path(_config_path))
	if txt.is_empty():
		push_error("render_primitive_stack: empty config"); quit(1); return
	var j := JSON.new()
	if j.parse(txt) != OK or not (j.data is Dictionary):
		push_error("render_primitive_stack: bad JSON"); quit(1); return
	var cfg: Dictionary = j.data

	# Scene
	var scene := Node3D.new()
	scene.name = "PSRender"
	root.add_child(scene)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.92, 0.92, 0.88)  # Bauhaus-catalogue neutral
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.95, 0.95, 0.92)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	var we := WorldEnvironment.new(); we.environment = env
	scene.add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-45, -28, 0)
	key.light_energy = 1.3
	key.shadow_enabled = true
	scene.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 130, 0)
	fill.light_energy = 0.35
	scene.add_child(fill)

	# Ground — use a neutral surface that matches catalog photo aesthetic
	var ground := MeshInstance3D.new()
	var gm := PlaneMesh.new(); gm.size = Vector2(10, 10)
	ground.mesh = gm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.85, 0.85, 0.82)
	gmat.roughness = 0.9
	ground.material_override = gmat
	scene.add_child(ground)

	# Build the primitive stack
	var stack: Node3D = PrimitiveStackScript.build(cfg)
	scene.add_child(stack)

	# Universal post-ops: noise displace each child primitive's position.
	var post_ops: Array = cfg.get("post_ops", [])
	if post_ops.size() > 0:
		var positions := PackedVector3Array()
		var children: Array = []
		for child in stack.get_children():
			if child is Node3D:
				children.append(child)
				positions.append((child as Node3D).position)
		positions = NoiseDisplacePS.apply_post_ops(positions, post_ops)
		for i in children.size():
			(children[i] as Node3D).position = positions[i]
		print("render_primitive_stack: applied %d post_ops to %d children" % [
			post_ops.size(), children.size()])

	await process_frame
	await process_frame

	# Camera
	var aabb := _combined_aabb(stack)
	var center: Vector3 = aabb.get_center()
	var max_dim: float = maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
	var dist: float = maxf(max_dim * 2.4, 1.5)
	var cam := Camera3D.new()
	cam.current = true; cam.fov = 38
	scene.add_child(cam)
	var yaw: float = float(cfg.get("camera_yaw", 0.4))
	var pitch: float = float(cfg.get("camera_pitch", 0.15))
	var offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * dist
	cam.global_position = center + offset
	cam.look_at(center, Vector3.UP)

	root.content_scale_size = Vector2i(_size, _size)
	root.size = Vector2i(_size, _size)

	await create_timer(_wait).timeout
	await process_frame
	await process_frame

	var img: Image = root.get_texture().get_image()
	if img == null:
		push_error("render_primitive_stack: no viewport image"); quit(1); return
	var abs_out := ProjectSettings.globalize_path(_output_path)
	var od := abs_out.get_base_dir()
	if not DirAccess.dir_exists_absolute(od):
		DirAccess.make_dir_recursive_absolute(od)
	var err := img.save_png(abs_out)
	if err != OK:
		push_error("render_primitive_stack: save failed"); quit(1); return
	print("render_primitive_stack: saved %s" % abs_out)
	quit(0)


func _combined_aabb(node: Node3D) -> AABB:
	var first := true
	var total := AABB()
	var stack: Array = [node]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is MeshInstance3D and n.mesh:
			var ab: AABB = n.global_transform * n.get_aabb()
			if first: total = ab; first = false
			else: total = total.merge(ab)
		for c in n.get_children():
			if c is Node3D: stack.append(c)
	if first:
		return AABB(Vector3(-1, 0, -1), Vector3(2, 2, 2))
	return total
