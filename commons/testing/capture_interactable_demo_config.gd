extends SceneTree

## Render one JSON-configured InteractableDemo board to a PNG.
##
## Usage:
##   godot --path . --xr-mode off --no-window --script \
##     res://commons/testing/capture_interactable_demo_config.gd -- \
##     --config=res://commons/interactables/demo_configs/auto/foo.json \
##     --out=user://interactable_layouts_gallery/foo.png

const InteractableDemoScript = preload("res://commons/interactables/InteractableDemo.gd")

var _config_path: String = ""
var _out_path: String = ""
var _size: int = 900


func _initialize() -> void:
	_parse_args()
	if _config_path.is_empty() or _out_path.is_empty():
		push_error("capture_interactable_demo_config: --config and --out are required")
		quit(1)
		return
	call_deferred("_run")


func _parse_args() -> void:
	for raw in OS.get_cmdline_user_args():
		var arg := String(raw).strip_edges()
		if not arg.begins_with("--"):
			continue
		var eq := arg.find("=")
		if eq <= 2:
			continue
		var key := arg.substr(2, eq - 2)
		var value := arg.substr(eq + 1).strip_edges()
		match key:
			"config":
				_config_path = value
			"out":
				_out_path = value
			"size":
				if value.is_valid_int():
					_size = clampi(int(value), 256, 2048)


func _load_config() -> Dictionary:
	var abs := _config_path
	if abs.begins_with("res://"):
		abs = ProjectSettings.globalize_path(abs)
	var file := FileAccess.open(abs, FileAccess.READ)
	if not file:
		push_error("capture_interactable_demo_config: cannot open %s" % abs)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return parsed
	push_error("capture_interactable_demo_config: invalid JSON in %s" % abs)
	return {}


func _run() -> void:
	var config := _load_config()
	if config.is_empty():
		quit(1)
		return

	root.content_scale_size = Vector2i(_size, _size)
	root.size = Vector2i(_size, _size)

	var scene := Node3D.new()
	scene.name = "InteractableDemoCapture"
	root.add_child(scene)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.09, 0.11)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.52, 0.54, 0.6)
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	scene.add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-40, -28, 0)
	key.light_energy = 1.2
	key.shadow_enabled = true
	scene.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-10, 140, 0)
	fill.light_energy = 0.35
	scene.add_child(fill)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	ground.mesh = plane
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.10, 0.11, 0.13)
	ground_mat.roughness = 0.95
	ground.material_override = ground_mat
	scene.add_child(ground)

	var demo: Node3D = InteractableDemoScript.new()
	demo.auto_build = false
	demo.load_demo_config_from_dict(config)
	demo.auto_build = true
	scene.add_child(demo)

	await process_frame
	await process_frame
	await process_frame

	var camera := Camera3D.new()
	camera.current = true
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	scene.add_child(camera)

	var aabb := _combined_aabb(demo)
	var focus := aabb.get_center()
	var width := maxf(aabb.size.x, 0.5)
	var height := maxf(aabb.size.y, 0.5)
	ground.position.y = aabb.position.y - maxf(height * 0.18, 0.28)
	camera.size = maxf(width, height) * 1.08
	var aim := focus + Vector3(0, height * 0.01, 0)
	camera.global_position = focus + Vector3(width * 0.01, height * 0.045, maxf(aabb.size.z * 2.5, 6.0))
	camera.look_at(aim, Vector3.UP)

	await process_frame
	await process_frame

	var image := root.get_texture().get_image()
	if image == null:
		push_error("capture_interactable_demo_config: no image")
		quit(1)
		return

	var abs_out := _out_path
	if abs_out.begins_with("user://"):
		abs_out = ProjectSettings.globalize_path(abs_out)
	DirAccess.make_dir_recursive_absolute(abs_out.get_base_dir())
	var err := image.save_png(abs_out)
	if err != OK:
		push_error("capture_interactable_demo_config: failed to save %s (err=%d)" % [abs_out, err])
		quit(1)
		return

	print("capture_interactable_demo_config: saved %s" % abs_out)
	quit(0)


func _combined_aabb(node: Node3D) -> AABB:
	var total := AABB()
	var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var current = stack.pop_back()
		if current is MeshInstance3D and current.mesh:
			var mesh_aabb: AABB = current.global_transform * current.get_aabb()
			if first:
				total = mesh_aabb
				first = false
			else:
				total = total.merge(mesh_aabb)
		for child in current.get_children():
			if child is Node3D:
				stack.append(child)
	if first:
		return AABB(Vector3(-1, 0, -1), Vector3(2, 2, 2))
	return total
