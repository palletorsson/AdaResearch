extends SceneTree

## Capture the catalyst bracelet at different progression stages.
## Builds a bracelet with 1, 3, 6, and 11 stones and captures each.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== BRACELET STAGES ===")

	var out_dir := "user://bracelet_stages"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	# Stage configurations: how many modes unlocked at each progression point
	var stages: Array[Dictionary] = [
		{"label": "01_start", "title": "New Player (1 stone)", "modes": ["voxel_editor"]},
		{"label": "02_early", "title": "After Color (3 stones)", "modes": ["voxel_editor", "primitives", "transformation"]},
		{"label": "03_mid", "title": "After Randomness (6 stones)", "modes": ["voxel_editor", "primitives", "transformation", "chromatic", "forces", "waveform"]},
		{"label": "04_late", "title": "After L-Systems (9 stones)", "modes": ["voxel_editor", "primitives", "transformation", "chromatic", "forces", "waveform", "chaos", "cellular", "branching"]},
		{"label": "05_full", "title": "All Complete (11 stones)", "modes": ["voxel_editor", "primitives", "transformation", "chromatic", "forces", "waveform", "chaos", "cellular", "fractal", "branching", "swarm"]},
	]

	for stage in stages:
		print("--- %s ---" % stage["title"])
		await _render_bracelet_stage(stage, out_dir)

	print("=== DONE ===")
	quit(0)


func _render_bracelet_stage(stage: Dictionary, out_dir: String) -> void:
	var scene_root := Node3D.new()
	scene_root.name = "BraceletStage"
	root.add_child(scene_root)

	# Dark environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.06, 0.1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.6)
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	scene_root.add_child(world_env)

	# Camera — close-up on bracelet
	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 40.0
	scene_root.add_child(camera)

	# Lights
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-40, -20, 0)
	key.light_energy = 1.5
	key.shadow_enabled = true
	scene_root.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, 160, 0)
	fill.light_energy = 0.6
	scene_root.add_child(fill)

	# Build bracelet manually (without XRTools dependency)
	var bracelet := Node3D.new()
	bracelet.name = "Bracelet"
	scene_root.add_child(bracelet)

	# Ring torus
	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.035
	torus.outer_radius = 0.045
	torus.rings = 32
	torus.ring_segments = 12
	ring.mesh = torus
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.2, 0.22, 0.3)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.3, 0.32, 0.45)
	ring_mat.emission_energy_multiplier = 0.8
	ring_mat.metallic = 0.4
	ring_mat.roughness = 0.3
	ring.material_override = ring_mat
	bracelet.add_child(ring)

	# Place gems
	var modes: Array = stage["modes"]
	var count: int = modes.size()
	var mid_radius: float = 0.040

	# Mode colors (matching CatalystVisual.MODE_COLORS)
	var colors: Dictionary = {
		"voxel_editor": Color(0.3, 0.7, 1.0),
		"primitives": Color(0.85, 0.85, 0.9),
		"transformation": Color(0.7, 0.3, 0.85),
		"chromatic": Color(1.0, 0.4, 0.4),
		"forces": Color(1.0, 0.75, 0.3),
		"waveform": Color(0.3, 0.85, 0.85),
		"chaos": Color(0.9, 0.2, 0.5),
		"cellular": Color(0.95, 0.95, 0.95),
		"fractal": Color(0.4, 0.7, 1.0),
		"branching": Color(0.4, 0.75, 0.3),
		"swarm": Color(1.0, 0.85, 0.4),
	}

	for i in count:
		var mode_id: String = str(modes[i])
		var angle: float = (TAU / float(count)) * float(i)
		var pos := Vector3(cos(angle) * mid_radius, 0, sin(angle) * mid_radius)

		var gem := MeshInstance3D.new()
		gem.name = "Gem_%s" % mode_id

		# Mode-specific mesh
		var gem_radius: float = 0.01
		var is_first: bool = (i == 0)  # First gem (voxel_editor) is active
		var scale_mult: float = 2.2 if is_first else 0.7

		match mode_id:
			"voxel_editor":
				var m := BoxMesh.new()
				m.size = Vector3.ONE * gem_radius * 2.5
				gem.mesh = m
			"primitives":
				var m := SphereMesh.new()
				m.radius = gem_radius
				m.height = gem_radius * 2.0
				gem.mesh = m
			"transformation":
				var m := PrismMesh.new()
				m.size = Vector3.ONE * gem_radius * 2.5
				gem.mesh = m
			"chromatic":
				var m := CylinderMesh.new()
				m.height = gem_radius * 1.5
				m.top_radius = gem_radius * 0.8
				m.bottom_radius = gem_radius * 0.8
				gem.mesh = m
			"forces":
				var m := BoxMesh.new()
				m.size = Vector3(gem_radius * 3.0, gem_radius, gem_radius)
				gem.mesh = m
			"waveform":
				var m := TorusMesh.new()
				m.inner_radius = gem_radius * 0.3
				m.outer_radius = gem_radius * 1.0
				gem.mesh = m
			"branching":
				var m := CylinderMesh.new()
				m.height = gem_radius * 3.0
				m.top_radius = gem_radius * 0.2
				m.bottom_radius = gem_radius * 0.6
				gem.mesh = m
			_:
				var m := SphereMesh.new()
				m.radius = gem_radius
				m.height = gem_radius * 2.0
				gem.mesh = m

		gem.position = pos
		gem.scale = Vector3.ONE * scale_mult

		var color: Color = colors.get(mode_id, Color.WHITE)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(color.r, color.g, color.b, 0.9)
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 3.0 if is_first else 1.2
		mat.metallic = 0.2
		mat.roughness = 0.3
		gem.material_override = mat
		bracelet.add_child(gem)

	await process_frame
	await process_frame

	var timer := Timer.new()
	root.add_child(timer)
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.start()
	await timer.timeout
	timer.queue_free()

	# Capture from two angles
	# Front view
	camera.position = Vector3(0.08, 0.06, 0)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	await process_frame
	await process_frame
	_save(out_dir + "/%s_front.png" % stage["label"])
	print("  Saved %s_front.png" % stage["label"])

	# Top-down
	camera.position = Vector3(0, 0.1, 0.001)
	camera.look_at(Vector3.ZERO, Vector3(0, 0, -1))
	await process_frame
	await process_frame
	_save(out_dir + "/%s_top.png" % stage["label"])
	print("  Saved %s_top.png" % stage["label"])

	# Cleanup
	scene_root.queue_free()
	await process_frame


func _save(path: String) -> void:
	var image: Image = root.get_texture().get_image()
	if image:
		var abs_path: String = ProjectSettings.globalize_path(path)
		DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
		image.save_png(abs_path)
