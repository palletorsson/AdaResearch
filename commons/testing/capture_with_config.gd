extends SceneTree

## Capture a .tscn with config injection — loads scene, calls apply_grid_config(),
## then captures screenshot. For builder tool → Godot audit loop.
## Usage:
## godot_console --path . --xr-mode off --no-window --script res://commons/testing/capture_with_config.gd -- \
##   --scene=res://commons/artifacts/grid_editor_board/grid_editor_board_3d.tscn \
##   --config=C:/path/to/config.json \
##   --out=C:/path/to/output.png

var _scene_path: String = ""
var _config_path: String = ""
var _output_path: String = "user://builder_captures/capture.png"
var _wait_seconds: float = 3.0
var _orbit_distance: float = 0.0
var _orbit_yaw: float = 0.4
var _orbit_pitch: float = 0.35
var _show_ground: bool = true
var _lift_to_ground: bool = true

func _initialize() -> void:
	_parse_args()
	if _scene_path.is_empty():
		push_error("capture_with_config: --scene=<path> is required")
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
			"config":
				_config_path = value
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

func _run_capture() -> void:
	print("capture_with_config: Loading scene '%s'..." % _scene_path)

	if not ResourceLoader.exists(_scene_path):
		push_error("capture_with_config: Scene not found: %s" % _scene_path)
		quit(1)
		return

	# --- Build environment scaffold (same as capture_tscn_shot.gd) ---
	var scene_root := Node3D.new()
	scene_root.name = "ConfigCapture"
	root.add_child(scene_root)

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

	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 50.0
	scene_root.add_child(camera)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.2
	light.shadow_enabled = true
	scene_root.add_child(light)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 150, 0)
	fill.light_energy = 0.4
	fill.shadow_enabled = false
	scene_root.add_child(fill)

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

	# --- Load and instantiate ---
	var packed: PackedScene = ResourceLoader.load(_scene_path)
	if not packed:
		push_error("capture_with_config: Failed to load: %s" % _scene_path)
		quit(1)
		return

	var instance: Node = packed.instantiate()
	if not instance:
		push_error("capture_with_config: Failed to instantiate: %s" % _scene_path)
		quit(1)
		return

	scene_root.add_child(instance)
	print("capture_with_config: Instantiated %s" % _scene_path)

	# Let _ready() run
	await process_frame
	await process_frame
	await process_frame

	# --- Config injection ---
	if not _config_path.is_empty():
		var config_data: Dictionary = _load_config_json()
		if not config_data.is_empty() and instance.has_method("apply_grid_config"):
			instance.apply_grid_config(config_data)
			print("capture_with_config: Called apply_grid_config with %d keys" % config_data.size())
			# Extra frames for config to take effect
			await process_frame
			await process_frame
			await process_frame
		elif not config_data.is_empty():
			print("capture_with_config: WARNING — scene root has no apply_grid_config() method")

	# --- Lift to ground ---
	if _lift_to_ground and instance is Node3D:
		var lift_aabb: AABB = _get_combined_aabb(instance as Node3D)
		if lift_aabb.size.length() > 0.01:
			var min_y: float = lift_aabb.position.y
			if abs(min_y) > 0.01:
				(instance as Node3D).position.y -= min_y
				print("capture_with_config: Lifted by %.2f" % [-min_y])

	# --- Camera framing ---
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
		print("capture_with_config: Using built-in CaptureCamera")
	else:
		var target_node: Node3D = instance as Node3D if instance is Node3D else null
		if not target_node:
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
				print("capture_with_config: AABB size=%s center=%s dist=%.1f" % [aabb.size, orbit_focus, orbit_dist])
			else:
				if orbit_dist <= 0.01:
					orbit_dist = 5.0
		else:
			if orbit_dist <= 0.01:
				orbit_dist = 5.0

		var offset := Vector3(
			sin(_orbit_yaw) * cos(_orbit_pitch),
			sin(_orbit_pitch),
			cos(_orbit_yaw) * cos(_orbit_pitch)
		) * orbit_dist
		camera.global_position = orbit_focus + offset
		camera.look_at(orbit_focus, Vector3.UP)

	# Wait for rendering
	await create_timer(_wait_seconds).timeout
	await process_frame
	await process_frame

	# --- Capture ---
	var image: Image = root.get_texture().get_image()
	if image == null:
		push_error("capture_with_config: Could not read viewport image")
		quit(1)
		return

	var absolute_output: String = _output_path
	# Resolve user:// and res:// paths to absolute
	if _output_path.begins_with("user://") or _output_path.begins_with("res://"):
		absolute_output = ProjectSettings.globalize_path(_output_path)

	var output_dir: String = absolute_output.get_base_dir()
	if not DirAccess.dir_exists_absolute(output_dir):
		DirAccess.make_dir_recursive_absolute(output_dir)

	var save_err: int = image.save_png(absolute_output)
	if save_err != OK:
		push_error("capture_with_config: Failed to save PNG: %s" % absolute_output)
		quit(1)
		return

	print("capture_with_config: Saved %s" % absolute_output)
	quit(0)

# ---------------------------------------------------------------------------
# Config loading
# ---------------------------------------------------------------------------

func _load_config_json() -> Dictionary:
	var path: String = _config_path
	# Resolve user:// and res:// paths
	if path.begins_with("user://") or path.begins_with("res://"):
		path = ProjectSettings.globalize_path(path)

	if not FileAccess.file_exists(path):
		push_error("capture_with_config: Config file not found: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("capture_with_config: Could not open config: %s" % path)
		return {}

	var text: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var err: int = json.parse(text)
	if err != OK:
		push_error("capture_with_config: JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return {}

	var data = json.data
	if data is Dictionary:
		return data
	push_error("capture_with_config: Config JSON root must be a Dictionary")
	return {}

# ---------------------------------------------------------------------------
# AABB utilities (same as capture_tscn_shot.gd)
# ---------------------------------------------------------------------------

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
