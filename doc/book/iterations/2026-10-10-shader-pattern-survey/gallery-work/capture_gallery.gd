extends SceneTree

# Review-only staging: existing scenes, separate viewport, unchanged artifact code.
var jobs_path := ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--jobs="):
			jobs_path = arg.substr(7)
	call_deferred("_run")

func _run() -> void:
	var jobs: Array = JSON.parse_string(FileAccess.get_file_as_string(jobs_path))
	for job in jobs:
		await _capture(job)
	quit()

func _capture(job: Dictionary) -> void:
	print("GALLERY_START ", job.id)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, int(job.get("height", 900)))
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(viewport)
	var stage := Node3D.new()
	viewport.add_child(stage)
	var artifact: Node3D
	if job.has("shader"):
		# Explicitly labelled review receiver for an existing shader, not a new exhibit.
		artifact = Node3D.new()
		var receiver := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(2.4, 1.8)
		receiver.mesh = quad
		var material := ShaderMaterial.new()
		material.shader = load(String(job.shader))
		receiver.material_override = material
		artifact.add_child(receiver)
	else:
		var packed := load(String(job.scene)) as PackedScene
		if packed == null:
			print("GALLERY_FAILED ", job.id)
			viewport.queue_free()
			return
		artifact = packed.instantiate()
	for key in job.get("props", {}):
		artifact.set(key, job.props[key])
	if job.has("config") and artifact.has_method("apply_grid_config"):
		artifact.call("apply_grid_config", job.config)
	stage.add_child(artifact)
	await create_timer(float(job.get("wait", 2.0))).timeout
	var subject: Node = artifact
	if job.has("focus_child"):
		subject = artifact.get_node_or_null(NodePath(job.focus_child))
		if subject == null:
			print("GALLERY_FAILED_FOCUS ", job.id)
			viewport.queue_free()
			return
		for child in artifact.get_children():
			if child is Node3D and child != subject:
				child.visible = false
	# Replace specimen cameras/environments only in the review viewport.
	for n in _descendants(artifact):
		if n is Camera3D:
			n.current = false
		elif n is WorldEnvironment:
			n.environment = null
	var environment := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("22262d")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("c5cddd")
	e.ambient_light_energy = 0.65
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = e
	stage.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.4
	stage.add_child(light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 140, 0)
	fill.light_energy = 0.55
	stage.add_child(fill)
	var points: Array[Vector3] = []
	for n in _descendants(subject):
		if n is MeshInstance3D and n.mesh != null and n.is_visible_in_tree():
			var box: AABB = n.get_aabb()
			for i in range(8):
				points.append(n.global_transform * box.get_endpoint(i))
		elif n is Label3D:
			points.append(n.global_position)
	if points.is_empty():
		print("GALLERY_EMPTY ", job.id)
		viewport.queue_free()
		return
	var bounds := AABB(points[0], Vector3.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	var center := bounds.get_center()
	var direction := Vector3(0.35, 0.75, 1).normalized()
	if job.get("camera", "oblique") == "front":
		direction = Vector3(0, 0.1, 1).normalized()
	elif job.get("camera", "oblique") == "top":
		direction = Vector3(0, 1, 0.03).normalized()
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.position = center + direction * (bounds.size.length() * 2.0 + 5.0)
	camera.look_at(center)
	camera.far = maxf(400.0, bounds.size.length() * 5.0)
	var width := 0.0
	var height := 0.0
	for point in points:
		var offset: Vector3 = camera.global_basis.inverse() * (point - center)
		width = maxf(width, absf(offset.x) * 2.0)
		height = maxf(height, absf(offset.y) * 2.0)
	camera.size = maxf(height, width / (1600.0 / viewport.size.y)) * 1.12
	camera.make_current()
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var out: String = job.out
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var error := viewport.get_texture().get_image().save_png(out)
	print("GALLERY_SAVED ", job.id, " ", error, " bounds=", bounds)
	viewport.queue_free()
	await process_frame

func _descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = [node]
	for child in node.get_children():
		result.append_array(_descendants(child))
	return result
