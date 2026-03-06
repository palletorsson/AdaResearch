extends SceneTree

## Batch capture ALL scenes from a catalog JSON in a single Godot process.
## Loads each scene sequentially: instantiate -> frame camera -> capture -> free -> next.
## Much faster than restarting Godot per screenshot.
##
## Usage:
## godot_console --path . --xr-mode off --no-window --script res://commons/testing/batch_capture_inline.gd -- \
##   --catalog=C:/path/to/scene-catalog.json \
##   --outdir=C:/path/to/output/directory \
##   --wait=1.0 --skip-existing

var _catalog_path: String = ""
var _output_dir: String = ""
var _wait_seconds: float = 1.0
var _skip_existing: bool = true
var _orbit_yaw: float = 0.4
var _orbit_pitch: float = 0.35  # positive = above looking down

# Persistent scaffold nodes (reused across captures)
var _scene_root: Node3D
var _camera: Camera3D
var _ground: MeshInstance3D
var _instance_container: Node3D

func _initialize() -> void:
	_parse_args()
	if _catalog_path.is_empty():
		push_error("batch_capture_inline: --catalog=<path> is required")
		quit(1)
		return
	if _output_dir.is_empty():
		push_error("batch_capture_inline: --outdir=<path> is required")
		quit(1)
		return
	call_deferred("_run_batch")

func _parse_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for raw_arg in args:
		var arg: String = String(raw_arg).strip_edges()
		if not arg.begins_with("--"):
			continue
		if arg == "--skip-existing":
			_skip_existing = true
			continue
		if arg == "--no-skip":
			_skip_existing = false
			continue
		var eq_idx: int = arg.find("=")
		if eq_idx <= 2:
			continue
		var key: String = arg.substr(2, eq_idx - 2)
		var value: String = arg.substr(eq_idx + 1).strip_edges()
		match key:
			"catalog":
				_catalog_path = value
			"outdir":
				_output_dir = value
			"wait":
				if value.is_valid_float():
					_wait_seconds = maxf(0.3, float(value))
			"yaw":
				if value.is_valid_float():
					_orbit_yaw = float(value)
			"pitch":
				if value.is_valid_float():
					_orbit_pitch = float(value)

func _run_batch() -> void:
	# ── Read catalog JSON ─────────────────────────────────────────────────
	var file := FileAccess.open(_catalog_path, FileAccess.READ)
	if not file:
		push_error("batch_capture_inline: Cannot open catalog: %s" % _catalog_path)
		quit(1)
		return

	var json_text: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var err: int = json.parse(json_text)
	if err != OK:
		push_error("batch_capture_inline: JSON parse error: %s" % json.get_error_message())
		quit(1)
		return

	var catalog: Dictionary = json.data
	var entries: Array = catalog.get("entries", [])
	var total: int = entries.size()

	print("=== Batch Capture Inline ===")
	print("Total scenes: %d" % total)
	print("Output dir: %s" % _output_dir)
	print("Camera: yaw=%.2f pitch=%.2f (above looking down)" % [_orbit_yaw, _orbit_pitch])
	print("Wait: %.1fs per scene" % _wait_seconds)
	print("")

	# Ensure output directory exists
	if not DirAccess.dir_exists_absolute(_output_dir):
		DirAccess.make_dir_recursive_absolute(_output_dir)

	# ── Build persistent environment scaffold ─────────────────────────────
	_build_scaffold()

	var captured: int = 0
	var skipped: int = 0
	var failed: int = 0
	var failed_list: PackedStringArray = []
	var start_time: int = Time.get_ticks_msec()

	for i in range(total):
		var entry: Dictionary = entries[i]
		var scene_path: String = str(entry.get("scenePath", ""))
		var screenshot: String = str(entry.get("screenshot", ""))
		var lookup: String = str(entry.get("lookupName", ""))
		var png_filename: String = screenshot.get_file()
		var output_path: String = _output_dir.path_join(png_filename)
		var label: String = lookup if (not lookup.is_empty() and lookup != "null") else png_filename
		var idx: int = i + 1

		# Skip if PNG already exists on disk
		if _skip_existing and FileAccess.file_exists(output_path):
			if idx % 200 == 0 or idx == total:
				print("[%d/%d] ... skipping (already captured)" % [idx, total])
			skipped += 1
			continue

		# Capture this scene
		var ok: bool = await _capture_one(scene_path, output_path)
		if ok:
			print("[%d/%d] %s - OK" % [idx, total, label])
			captured += 1
		else:
			print("[%d/%d] %s - FAIL" % [idx, total, label])
			failed += 1
			failed_list.append("  - %s (%s)" % [label, scene_path])

		# Progress report every 100 captures
		if captured > 0 and captured % 100 == 0:
			var elapsed: float = (Time.get_ticks_msec() - start_time) / 1000.0
			var rate: float = captured / elapsed if elapsed > 0 else 0
			var remaining_count: int = total - skipped - captured - failed
			var remaining_sec: float = remaining_count / rate if rate > 0 else 0
			print("    --- Progress: %d captured, %d failed, ~%.0f min remaining ---" % [
				captured, failed, remaining_sec / 60.0
			])

	# ── Summary ───────────────────────────────────────────────────────────
	var elapsed: float = (Time.get_ticks_msec() - start_time) / 1000.0
	print("")
	print("=== Batch Capture Summary ===")
	print("  Total:    %d" % total)
	print("  Captured: %d" % captured)
	print("  Skipped:  %d (already existed)" % skipped)
	print("  Failed:   %d" % failed)
	print("  Time:     %.1f minutes" % (elapsed / 60.0))

	if failed_list.size() > 0:
		print("")
		print("Failed scenes:")
		for line in failed_list:
			print(line)

	print("")
	print("Done.")
	quit(0)


# ── Environment Scaffold (persistent, reused for every capture) ───────────

func _build_scaffold() -> void:
	_scene_root = Node3D.new()
	_scene_root.name = "BatchCapture"
	root.add_child(_scene_root)

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
	_scene_root.add_child(world_env)

	# Camera
	_camera = Camera3D.new()
	_camera.current = true
	_camera.fov = 50.0
	_scene_root.add_child(_camera)

	# Key light
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.2
	light.shadow_enabled = true
	_scene_root.add_child(light)

	# Fill light
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 150, 0)
	fill.light_energy = 0.4
	fill.shadow_enabled = false
	_scene_root.add_child(fill)

	# Ground plane
	_ground = MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(20, 20)
	_ground.mesh = ground_mesh
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.15, 0.15, 0.18)
	_ground.material_override = ground_mat
	_scene_root.add_child(_ground)

	# Container for loaded scenes (makes cleanup easy)
	_instance_container = Node3D.new()
	_instance_container.name = "InstanceContainer"
	_scene_root.add_child(_instance_container)


# ── Single Scene Capture ──────────────────────────────────────────────────

func _capture_one(scene_path: String, output_path: String) -> bool:
	if not ResourceLoader.exists(scene_path):
		return false

	var packed: PackedScene = ResourceLoader.load(scene_path)
	if not packed:
		return false

	var instance: Node = packed.instantiate()
	if not instance:
		return false

	_instance_container.add_child(instance)

	# Let _ready() and physics run
	await process_frame
	await process_frame

	# Verify scaffold integrity (some scenes may free our nodes)
	_ensure_scaffold()

	# Reset scaffold state
	if is_instance_valid(_ground):
		_ground.visible = true
	if is_instance_valid(_camera):
		_camera.current = true

	# Lift to ground: shift instance so AABB bottom sits at y=0
	if instance is Node3D:
		var lift_aabb: AABB = _get_combined_aabb(instance as Node3D)
		if lift_aabb.size.length() > 0.01:
			var min_y: float = lift_aabb.position.y
			if abs(min_y) > 0.01:
				(instance as Node3D).position.y -= min_y

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
		if is_instance_valid(_camera):
			_camera.current = false
		if is_instance_valid(_ground):
			_ground.visible = false
	else:
		_frame_camera(instance)

	# Wait for rendering to settle
	await create_timer(_wait_seconds).timeout
	await process_frame

	# Capture screenshot
	var image: Image = root.get_texture().get_image()
	if image == null:
		_cleanup_instance()
		return false

	# Ensure output directory exists
	var dir_path: String = output_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	var save_err: int = image.save_png(output_path)

	# Clean up: restore our camera, free the instance
	_cleanup_instance()

	return save_err == OK


func _ensure_scaffold() -> void:
	"""Recreate scaffold nodes if a loaded scene destroyed them."""
	if not is_instance_valid(_camera):
		_camera = Camera3D.new()
		_camera.current = true
		_camera.fov = 50.0
		_scene_root.add_child(_camera)

	if not is_instance_valid(_ground):
		_ground = MeshInstance3D.new()
		var ground_mesh := PlaneMesh.new()
		ground_mesh.size = Vector2(20, 20)
		_ground.mesh = ground_mesh
		var ground_mat := StandardMaterial3D.new()
		ground_mat.albedo_color = Color(0.15, 0.15, 0.18)
		_ground.material_override = ground_mat
		_scene_root.add_child(_ground)

	if not is_instance_valid(_instance_container):
		_instance_container = Node3D.new()
		_instance_container.name = "InstanceContainer"
		_scene_root.add_child(_instance_container)


func _cleanup_instance() -> void:
	"""Remove all children from instance container and restore camera."""
	if is_instance_valid(_camera):
		_camera.current = true
	for child in _instance_container.get_children():
		child.queue_free()
	# Wait for queue_free to complete
	await process_frame
	# Verify scaffold after cleanup
	_ensure_scaffold()


func _frame_camera(instance: Node) -> void:
	"""Position camera using AABB to frame the scene from above."""
	if not is_instance_valid(_camera):
		_ensure_scaffold()

	var target_node: Node3D = instance as Node3D if instance is Node3D else null
	if not target_node:
		for child in instance.get_children():
			if child is Node3D:
				target_node = child
				break

	var orbit_focus := Vector3(0, 1.0, 0)
	var orbit_dist: float = 5.0

	if target_node:
		var aabb: AABB = _get_combined_aabb(target_node)
		if aabb.size.length() > 0.01:
			orbit_focus = aabb.get_center()
			var max_dim: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
			orbit_dist = max_dim * 2.0

	var offset := Vector3(
		sin(_orbit_yaw) * cos(_orbit_pitch),
		sin(_orbit_pitch),
		cos(_orbit_yaw) * cos(_orbit_pitch)
	) * orbit_dist
	_camera.global_position = orbit_focus + offset
	_camera.look_at(orbit_focus, Vector3.UP)


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
