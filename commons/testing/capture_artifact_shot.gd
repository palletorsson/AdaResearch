extends SceneTree

## Capture a single artifact by lookup_name — clean 3D render without UI overlays.
## Usage:
## godot_console --path . --script res://commons/testing/capture_artifact_shot.gd -- \
##   --artifact=pattern_maker_station --out=user://artifact_shots/pattern_maker_station.png \
##   --wait=3.0 --distance=5.0 --yaw=0.4 --pitch=-0.35

var _artifact_name: String = ""
var _output_path: String = "user://artifact_shots/artifact_capture.png"
var _wait_seconds: float = 3.0
var _orbit_distance: float = 5.0
var _orbit_yaw: float = 0.4
var _orbit_pitch: float = -0.35
var _orbit_focus: Vector3 = Vector3(0, 1.0, 0)

func _initialize() -> void:
	_parse_args()
	if _artifact_name.is_empty():
		push_error("capture_artifact_shot: --artifact=<lookup_name> is required")
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
			"artifact":
				_artifact_name = value
			"out":
				_output_path = value
			"wait":
				if value.is_valid_float():
					_wait_seconds = maxf(0.5, float(value))
			"distance":
				if value.is_valid_float():
					_orbit_distance = maxf(0.5, float(value))
			"yaw":
				if value.is_valid_float():
					_orbit_yaw = float(value)
			"pitch":
				if value.is_valid_float():
					_orbit_pitch = float(value)

func _run_capture() -> void:
	print("capture_artifact_shot: Loading artifact '%s'..." % _artifact_name)

	# --- Build a minimal 3D scene: environment + camera + light + artifact ---
	var scene_root := Node3D.new()
	scene_root.name = "ArtifactCapture"
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

	# Directional light
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.2
	light.shadow_enabled = true
	scene_root.add_child(light)

	# Fill light from opposite side
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 150, 0)
	fill.light_energy = 0.4
	fill.shadow_enabled = false
	scene_root.add_child(fill)

	# Ground plane for context
	var ground := MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(20, 20)
	ground.mesh = ground_mesh
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.15, 0.15, 0.18)
	ground.material_override = ground_mat
	scene_root.add_child(ground)

	# --- Load artifact from registry ---
	var artifact_info: Dictionary = _find_artifact(_artifact_name)
	if artifact_info.is_empty():
		push_error("capture_artifact_shot: Artifact '%s' not found in any registry" % _artifact_name)
		quit(1)
		return

	var scene_path: String = str(artifact_info.get("scene", "")).strip_edges()
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_error("capture_artifact_shot: Scene not found: %s" % scene_path)
		quit(1)
		return

	var packed: PackedScene = ResourceLoader.load(scene_path)
	if not packed:
		push_error("capture_artifact_shot: Failed to load: %s" % scene_path)
		quit(1)
		return

	var artifact: Node = packed.instantiate()
	if not artifact or not (artifact is Node3D):
		push_error("capture_artifact_shot: Scene root is not Node3D")
		if artifact:
			artifact.queue_free()
		quit(1)
		return

	scene_root.add_child(artifact)
	print("capture_artifact_shot: Artifact instantiated from %s" % scene_path)

	# Let the artifact run _ready() and a few frames
	await process_frame
	await process_frame
	await process_frame

	# Check if artifact has a built-in CaptureCamera
	var capture_cam: Camera3D = (artifact as Node3D).find_child("CaptureCamera", true, false) as Camera3D
	if capture_cam:
		capture_cam.current = true
		camera.current = false
		ground.visible = false  # Hide capture script's ground — artifact provides its own context
		print("capture_artifact_shot: Using artifact's built-in CaptureCamera")
	else:
		# Auto-fit: compute AABB and adjust camera distance
		var aabb: AABB = _get_combined_aabb(artifact as Node3D)
		if aabb.size.length() > 0:
			var center: Vector3 = aabb.get_center()
			_orbit_focus = center
			var max_dim: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
			if _orbit_distance <= 0.5:
				_orbit_distance = max_dim * 2.0
			print("capture_artifact_shot: AABB size=%s center=%s, distance=%.1f" % [aabb.size, center, _orbit_distance])

		# Position camera using orbit parameters
		var offset := Vector3(
			sin(_orbit_yaw) * cos(_orbit_pitch),
			sin(_orbit_pitch),
			cos(_orbit_yaw) * cos(_orbit_pitch)
		) * _orbit_distance
		camera.global_position = _orbit_focus + offset
		camera.look_at(_orbit_focus, Vector3.UP)

	# Wait for rendering to settle
	await create_timer(_wait_seconds).timeout
	await process_frame
	await process_frame

	# Capture
	var image: Image = root.get_texture().get_image()
	if image == null:
		push_error("capture_artifact_shot: Could not read viewport image")
		quit(1)
		return

	var absolute_output: String = ProjectSettings.globalize_path(_output_path)
	var output_dir: String = absolute_output.get_base_dir()
	if not DirAccess.dir_exists_absolute(output_dir):
		DirAccess.make_dir_recursive_absolute(output_dir)

	var save_err: int = image.save_png(absolute_output)
	if save_err != OK:
		push_error("capture_artifact_shot: Failed to save PNG: %s" % absolute_output)
		quit(1)
		return

	print("capture_artifact_shot: ✅ Saved %s" % absolute_output)
	quit(0)

func _find_artifact(lookup_name: String) -> Dictionary:
	"""Search all registry JSON files for the artifact."""
	var registry_dir: String = "res://commons/artifacts/registry"
	var dir := DirAccess.open(registry_dir)
	if not dir:
		push_error("capture_artifact_shot: Cannot open registry dir")
		return {}

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var path: String = registry_dir.path_join(file_name)
			var json_text: String = FileAccess.get_file_as_string(path)
			if not json_text.is_empty():
				var json := JSON.new()
				if json.parse(json_text) == OK and json.data is Dictionary:
					var data: Dictionary = json.data
					# Check top-level "artifacts" dict or flat dict
					var artifacts: Dictionary = data.get("artifacts", data)
					if artifacts.has(lookup_name):
						return artifacts[lookup_name]
		file_name = dir.get_next()
	dir.list_dir_end()
	return {}

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
