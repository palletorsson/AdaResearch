extends SceneTree

## Like capture_scene_path.gd but lets the scene run for N seconds before
## capturing — so dynamic content (trails, animations, harvester movement)
## has time to develop. Captures a single front view.
##
## Usage:
##   godot --xr-mode off --no-window \
##     --script res://commons/testing/capture_running_scene.gd -- \
##     --scene=res://commons/primitives/harvester/harvester_color.tscn \
##     --out=user://harvester_capture --seconds=6

var _scene_path: String = ""
var _output_dir: String = "user://running_scene_out"
var _run_seconds: float = 6.0
var _camera_distance: float = 8.0
var _camera_yaw: float = 0.6
var _camera_pitch: float = 0.5
var _width: int = 1024
var _height: int = 576


func _initialize() -> void:
	_parse_args()
	if _scene_path.is_empty():
		push_error("capture_running_scene: --scene=res://... required")
		quit(1)
		return

	var packed: PackedScene = ResourceLoader.load(_scene_path)
	if not packed:
		push_error("failed to load %s" % _scene_path)
		quit(1)
		return

	root.size = Vector2i(_width, _height)

	var scene_root := Node3D.new()
	root.add_child(scene_root)

	# Environment
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.62, 0.45, 1.0)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.65, 0.67, 0.70, 1.0)
	e.ambient_light_energy = 1.4
	env.environment = e
	scene_root.add_child(env)

	# Three-point lighting
	for rot_deg in [Vector3(-40, 30, 0), Vector3(-30, -45, 0), Vector3(20, 180, 0)]:
		var l := DirectionalLight3D.new()
		l.rotation_degrees = rot_deg
		l.light_energy = 1.0
		scene_root.add_child(l)

	# A simple grass/floor plane so the harvester has something to roll over
	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(20, 20)
	floor.mesh = floor_mesh
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.30, 0.32, 0.28, 1.0)
	floor_mat.metallic = 0.0
	floor_mat.roughness = 0.9
	floor.material_override = floor_mat
	scene_root.add_child(floor)

	# Camera
	var camera := Camera3D.new()
	camera.fov = 45.0
	scene_root.add_child(camera)
	camera.current = true

	# Instantiate the actual scene under test
	var artifact: Node = packed.instantiate()
	scene_root.add_child(artifact)

	# Run for N seconds — give the scene's _process time to evolve
	await process_frame
	await process_frame

	var elapsed: float = 0.0
	while elapsed < _run_seconds:
		await create_timer(0.1).timeout
		elapsed += 0.1

	# Frame the camera to fit whatever the scene grew into
	var aabb: AABB = _get_combined_aabb(artifact as Node3D)
	var orbit_focus: Vector3 = Vector3.ZERO
	var dist: float = _camera_distance
	if aabb.size.length() > 0:
		orbit_focus = aabb.get_center()
		var max_dim: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
		dist = max(max_dim * 0.7, _camera_distance * 0.5)

	var cam_offset := Vector3(
		sin(_camera_yaw) * cos(_camera_pitch),
		sin(_camera_pitch),
		cos(_camera_yaw) * cos(_camera_pitch)
	) * dist
	camera.global_position = orbit_focus + cam_offset
	camera.look_at(orbit_focus, Vector3.UP)

	await process_frame
	await process_frame
	await create_timer(0.2).timeout
	await process_frame

	var img: Image = root.get_texture().get_image()
	if img:
		var output_abs: String = ProjectSettings.globalize_path(_output_dir)
		DirAccess.make_dir_recursive_absolute(output_abs)
		var path: String = output_abs.path_join("after_run.png")
		img.save_png(path)
		print("capture_running_scene: saved %s after %.1fs" % [path, _run_seconds])

	quit(0)


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		var eq: int = arg.find("=")
		if eq < 0:
			continue
		var k: String = arg.substr(0, eq).lstrip("-")
		var v: String = arg.substr(eq + 1)
		match k:
			"scene": _scene_path = v
			"out", "output": _output_dir = v
			"seconds": _run_seconds = float(v)
			"yaw": _camera_yaw = float(v)
			"pitch": _camera_pitch = float(v)
			"distance": _camera_distance = float(v)


func _get_combined_aabb(root_node: Node3D) -> AABB:
	var combined := AABB()
	var first := true
	for n in _walk(root_node):
		if n is VisualInstance3D:
			var ab: AABB = (n as VisualInstance3D).get_aabb()
			var xform: Transform3D = (n as Node3D).global_transform
			ab = xform * ab
			if first:
				combined = ab
				first = false
			else:
				combined = combined.merge(ab)
	return combined


func _walk(node: Node) -> Array:
	var out := [node]
	for c in node.get_children():
		out.append_array(_walk(c))
	return out
