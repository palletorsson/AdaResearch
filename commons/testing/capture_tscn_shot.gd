extends SceneTree

## Capture a single .tscn file by path — inserts camera, lights, environment.
## Works for ANY .tscn, no registry dependency.
## Usage:
## godot_console --path . --xr-mode off --script res://commons/testing/capture_tscn_shot.gd -- \
##   --scene=res://algorithms/fractals/koch/koch_curve.tscn \
##   --out=user://scene_shots/koch_curve.png \
##   --wait=3.0 --distance=0

var _scene_path: String = ""
var _output_path: String = "user://scene_shots/capture.png"
var _wait_seconds: float = 3.0
var _orbit_distance: float = 0.0  # 0 = auto from AABB
var _orbit_yaw: float = 0.4
var _orbit_pitch: float = 0.35  # positive = above looking down
var _show_ground: bool = true  # false = skip scaffold ground plane
var _lift_to_ground: bool = true  # shift instance up so AABB bottom sits at y=0
var _orbit_focus_override: Vector3 = Vector3.INF  # INF = auto from AABB

func _initialize() -> void:
	_parse_args()
	if _scene_path.is_empty():
		push_error("capture_tscn_shot: --scene=<path> is required")
		quit(1)
		return
	call_deferred("_run_capture")

func _parse_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for raw_arg in args:
		var arg: String = String(raw_arg).strip_edges()
		if not arg.begins_with("--"):
			continue
		var eq_idx: int = arg.find("=")
		if eq_idx <= 2:
			continue
		var key: String = arg.substr(2, eq_idx - 2)
		var value: String = arg.substr(eq_idx + 1).strip_edges()
		match key:
			"scene":
				_scene_path = value
			"out":
				_output_path = value
			"wait":
				if value.is_valid_float():
					_wait_seconds = maxf(0.5, float(value))
			"distance":
				if value.is_valid_float():
					_orbit_distance = maxf(0.0, float(value))
			"yaw":
				if value.is_valid_float():
					_orbit_yaw = float(value)
			"pitch":
				if value.is_valid_float():
					_orbit_pitch = float(value)
			"ground":
				_show_ground = (value.to_lower() != "false" and value != "0")
			"lift":
				_lift_to_ground = (value.to_lower() != "false" and value != "0")
			"focus":
				# Format: "x,y,z" e.g. "0,0,0"
				var parts = value.split(",")
				if parts.size() == 3:
					var px = parts[0].strip_edges()
					var py = parts[1].strip_edges()
					var pz = parts[2].strip_edges()
					if px.is_valid_float() and py.is_valid_float() and pz.is_valid_float():
						_orbit_focus_override = Vector3(float(px), float(py), float(pz))

func _run_capture() -> void:
	print("capture_tscn_shot: Loading scene '%s'..." % _scene_path)

	if not ResourceLoader.exists(_scene_path):
		push_error("capture_tscn_shot: Scene not found: %s" % _scene_path)
		quit(1)
		return

	# --- Build environment scaffold ---
	var scene_root := Node3D.new()
	scene_root.name = "TscnCapture"
	root.add_child(scene_root)

	# World environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.12, 0.16)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	scene_root.add_child(world_env)

	# Camera
	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 50.0
	scene_root.add_child(camera)

	# Key light
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.2
	light.shadow_enabled = true
	scene_root.add_child(light)

	# Fill light
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 150, 0)
	fill.light_energy = 0.4
	fill.shadow_enabled = false
	scene_root.add_child(fill)

	# Ground plane (optional via --ground=false)
	var ground: MeshInstance3D = null
	if _show_ground:
		ground = MeshInstance3D.new()
		var ground_mesh := PlaneMesh.new()
		ground_mesh.size = Vector2(20, 20)
		ground.mesh = ground_mesh
		var ground_mat := StandardMaterial3D.new()
		ground_mat.albedo_color = Color(0.15, 0.15, 0.18)
		ground.material_override = ground_mat
		scene_root.add_child(ground)

	# --- Load and instantiate the .tscn ---
	var packed: PackedScene = ResourceLoader.load(_scene_path)
	if not packed:
		push_error("capture_tscn_shot: Failed to load: %s" % _scene_path)
		quit(1)
		return

	var instance: Node = packed.instantiate()
	if not instance:
		push_error("capture_tscn_shot: Failed to instantiate: %s" % _scene_path)
		quit(1)
		return

	scene_root.add_child(instance)
	print("capture_tscn_shot: Instantiated %s" % _scene_path)

	# Let _ready() and a few physics frames run
	await process_frame
	await process_frame
	await process_frame

	# --- Lift to ground: shift instance so AABB bottom sits at y=0 ---
	if _lift_to_ground and instance is Node3D:
		var lift_aabb: AABB = _get_combined_aabb(instance as Node3D)
		if lift_aabb.size.length() > 0.01:
			var min_y: float = lift_aabb.position.y
			if abs(min_y) > 0.01:
				(instance as Node3D).position.y -= min_y
				print("capture_tscn_shot: Lifted by %.2f (AABB min_y was %.2f)" % [-min_y, min_y])

	# --- Camera framing ---
	# Check for built-in CaptureCamera
	var capture_cam: Camera3D = null
	if instance is Node3D:
		capture_cam = (instance as Node3D).find_child("CaptureCamera", true, false) as Camera3D
	elif instance.get_child_count() > 0:
		for child in instance.get_children():
			if child is Node3D:
				capture_cam = (child as Node3D).find_child("CaptureCamera", true, false) as Camera3D
				if capture_cam:
					break

	if capture_cam:
		capture_cam.current = true
		camera.current = false
		if ground:
			ground.visible = false
		print("capture_tscn_shot: Using built-in CaptureCamera")
	else:
		# Auto-fit from AABB
		var target_node: Node3D = instance as Node3D if instance is Node3D else null
		if not target_node:
			# Try to find the first Node3D child
			for child in instance.get_children():
				if child is Node3D:
					target_node = child
					break

		var orbit_focus := Vector3(0, 1.0, 0)
		var orbit_dist := _orbit_distance

		if target_node:
			var aabb: AABB = _get_combined_aabb(target_node)
			if aabb.size.length() > 0.01:
				orbit_focus = aabb.get_center()
				var max_dim: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
				if orbit_dist <= 0.01:
					orbit_dist = max_dim * 2.0
				print("capture_tscn_shot: AABB size=%s center=%s dist=%.1f" % [aabb.size, orbit_focus, orbit_dist])
			else:
				print("capture_tscn_shot: Empty AABB, using defaults")
				if orbit_dist <= 0.01:
					orbit_dist = 5.0
		else:
			print("capture_tscn_shot: No Node3D root, using defaults")
			if orbit_dist <= 0.01:
				orbit_dist = 5.0

		# Override focus if specified via --focus=x,y,z
		if _orbit_focus_override != Vector3.INF:
			orbit_focus = _orbit_focus_override
			print("capture_tscn_shot: Focus overridden to %s" % orbit_focus)

		var offset := Vector3(
			sin(_orbit_yaw) * cos(_orbit_pitch),
			sin(_orbit_pitch),
			cos(_orbit_yaw) * cos(_orbit_pitch)
		) * orbit_dist
		camera.global_position = orbit_focus + offset
		camera.look_at(orbit_focus, Vector3.UP)

	# Wait for rendering to settle
	await create_timer(_wait_seconds).timeout
	await process_frame
	await process_frame


	# --- Capture screenshot ---
	var image: Image = root.get_texture().get_image()
	if image == null:
		push_error("capture_tscn_shot: Could not read viewport image")
		quit(1)
		return

	var absolute_output: String = ProjectSettings.globalize_path(_output_path)
	var output_dir: String = absolute_output.get_base_dir()
	if not DirAccess.dir_exists_absolute(output_dir):
		DirAccess.make_dir_recursive_absolute(output_dir)

	var save_err: int = image.save_png(absolute_output)
	if save_err != OK:
		push_error("capture_tscn_shot: Failed to save PNG: %s" % absolute_output)
		quit(1)
		return

	print("capture_tscn_shot: Saved %s" % absolute_output)
	quit(0)

func _get_combined_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for child in node.get_children():
		var child_aabb := AABB()
		var has_aabb := false
		if child is MeshInstance3D:
			var mesh = (child as MeshInstance3D).mesh
			if mesh:
				child_aabb = child.transform * mesh.get_aabb()
				has_aabb = true
		elif child is MultiMeshInstance3D:
			var mm = child.multimesh
			if mm and mm.instance_count > 0:
				child_aabb = child.transform * mm.get_aabb()
				has_aabb = true
		elif child is CSGShape3D:
			var child_meshes: Array = child.get_meshes()
			if child_meshes.size() >= 2:
				var m = child_meshes[1]
				if m is Mesh:
					child_aabb = child.transform * m.get_aabb()
					has_aabb = true
		elif child is GPUParticles3D:
			child_aabb = child.transform * child.visibility_aabb
			has_aabb = true
		if has_aabb and child_aabb.size.length() > 0:
			if first:
				result = child_aabb
				first = false
			else:
				result = result.merge(child_aabb)
		if child is Node3D:
			var sub_aabb: AABB = _get_combined_aabb(child)
			if sub_aabb.size.length() > 0:
				if first:
					result = sub_aabb
					first = false
				else:
					result = result.merge(sub_aabb)
	return result
