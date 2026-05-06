extends SceneTree

## Render a facade-preset config to a PNG.
## DNA = the preset JSON itself (facade structure, zones, materials, bays).
## Reuses commons/facade_parts/facade_composer.gd — no duplication.
##
## Usage:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/render_facade.gd -- \
##     --config=<path.json> --out=user://facade_gallery/<id>.png --size=640

const FacadeComposerScript = preload("res://commons/facade_parts/facade_composer.gd")

var _config_path: String = ""
var _output_path: String = "user://facade_gallery/out.png"
var _size: int = 640
var _wait: float = 0.8


func _initialize() -> void:
	_parse_args()
	if _config_path.is_empty():
		push_error("render_facade: --config required"); quit(1); return
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
	# Scene
	var scene := Node3D.new()
	scene.name = "FacadeRender"
	root.add_child(scene)

	# Bauhaus-neutral background, matches other gallery renderers
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.88, 0.86, 0.80)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.95, 0.93, 0.88)
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	var we := WorldEnvironment.new(); we.environment = env
	scene.add_child(we)

	# Sun + fill
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-40, -32, 0)
	key.light_energy = 1.4
	key.shadow_enabled = true
	scene.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 130, 0)
	fill.light_energy = 0.4
	scene.add_child(fill)

	# Ground (ground-street look)
	var ground := MeshInstance3D.new()
	var gm := PlaneMesh.new(); gm.size = Vector2(60, 60)
	ground.mesh = gm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.78, 0.76, 0.72); gmat.roughness = 0.9
	ground.material_override = gmat
	scene.add_child(ground)

	# Build facade via existing composer — load JSON from disk
	var abs_cfg := ProjectSettings.globalize_path(_config_path) if _config_path.begins_with("res://") else _config_path
	var facade: Node3D = FacadeComposerScript.build_from_file(_config_path)
	if facade == null:
		# Try absolute path form
		facade = FacadeComposerScript.build_from_file(abs_cfg)
	if facade == null:
		push_error("render_facade: composer returned null for %s" % _config_path)
		quit(1); return
	scene.add_child(facade)

	await process_frame
	await process_frame

	# Frame camera — use the facade's AABB
	var aabb := _combined_aabb(facade)
	var center: Vector3 = aabb.get_center()
	var max_dim: float = maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
	var dist: float = maxf(max_dim * 1.4, 3.0)
	var cam := Camera3D.new()
	cam.current = true; cam.fov = 42
	scene.add_child(cam)
	# Slight 3/4 angle from above, facade-front oriented
	var yaw: float = 0.3
	var pitch: float = 0.12
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
		push_error("render_facade: no viewport image"); quit(1); return
	var abs_out := ProjectSettings.globalize_path(_output_path)
	var od := abs_out.get_base_dir()
	if not DirAccess.dir_exists_absolute(od):
		DirAccess.make_dir_recursive_absolute(od)
	var err := img.save_png(abs_out)
	if err != OK:
		push_error("render_facade: save failed"); quit(1); return
	print("render_facade: saved %s" % abs_out)
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
		elif n is CSGShape3D:
			var csg := n as CSGShape3D
			var ab2: AABB = csg.global_transform * csg.get_aabb()
			if first: total = ab2; first = false
			else: total = total.merge(ab2)
		for c in n.get_children():
			if c is Node3D: stack.append(c)
	if first:
		return AABB(Vector3(-5, 0, -5), Vector3(10, 10, 10))
	return total
