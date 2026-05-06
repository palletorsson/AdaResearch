extends SceneTree
## Captures the four terrain modes side by side for the ecosystem blog post.
## Usage: godot_console --path . --xr-mode off --no-window --script res://commons/testing/capture_ecosystem_stages.gd

var _output_dir: String = "user://ecosystem_captures"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive(_output_dir.replace("user://", ""))

	var modes := ["flat", "noise", "growth", "self_generating"]
	for mode in modes:
		await _capture_mode(mode)

	print("capture_ecosystem: Done! Captured %d modes" % modes.size())
	quit(0)

func _capture_mode(mode: String) -> void:
	# Build scene
	var scene_root := Node3D.new()
	scene_root.name = "EcoCapture"
	root.add_child(scene_root)

	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.08, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.45, 0.5)
	env.ambient_light_energy = 1.2
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	scene_root.add_child(world_env)

	# Camera — angled overhead, close enough to see terrain detail + critters
	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 55.0
	camera.global_position = Vector3(6.0, 4.0, 8.0)
	scene_root.add_child(camera)
	camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)

	# Lights
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -25, 0)
	light.light_energy = 1.4
	light.shadow_enabled = true
	scene_root.add_child(light)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, 140, 0)
	fill.light_energy = 0.35
	scene_root.add_child(fill)

	# Terrain generator
	var TerrainClass = load("res://commons/managers/EcosystemTerrainGenerator.gd")
	var terrain = TerrainClass.new()
	terrain.terrain_size = 16.0
	terrain.resolution = 64
	terrain.max_height = 3.5
	terrain.noise_seed = 42
	scene_root.add_child(terrain)

	# Wait for deferred _connect_signals + _build_initial to finish,
	# then override mode and regenerate
	await process_frame
	await process_frame
	terrain._current_mode = mode
	terrain._generate_terrain()
	print("capture_ecosystem: Forced terrain mode='%s'" % mode)

	# Nature spawner (if not flat)
	if mode != "flat":
		var nature_root := Node3D.new()
		nature_root.name = "NatureRoot"
		scene_root.add_child(nature_root)
		var spawner := CritterSpawner.new(nature_root)
		spawner.default_lod = 2

		var count := 0
		match mode:
			"noise":
				count = 8
				spawner.seed_population(0, count, Vector3.ZERO, 6.0, 42)  # flowers
			"growth":
				count = 15
				spawner.seed_population(0, 6, Vector3.ZERO, 6.0, 42)  # flowers
				spawner.seed_population(2, 5, Vector3.ZERO, 6.0, 43)  # fungus
				spawner.seed_population(1, 4, Vector3.ZERO, 6.0, 44)  # trees
			"self_generating":
				count = 25
				spawner.seed_mixed_population(25, Vector3.ZERO, 7.0, 42)

	# Wait for render — extra frames for critter meshes to generate
	await create_timer(3.0).timeout
	for i in 4:
		await process_frame

	# Capture
	var image: Image = root.get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [_output_dir, mode])
	var save_dir := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(save_dir):
		DirAccess.make_dir_recursive_absolute(save_dir)
	image.save_png(path)
	print("capture_ecosystem: Saved %s" % path)

	# Cleanup
	scene_root.queue_free()
	await process_frame
