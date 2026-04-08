extends SceneTree

## Capture the ecosystem self-organizing over time.
## Seeds 3 organisms, simulates 60 seconds of ecosystem,
## captures snapshots at intervals showing the ground filling in.

const _PresenceGrid = preload("res://algorithms/nature_system/systems/presence_grid.gd")
const _GroundSpawner = preload("res://algorithms/nature_system/systems/ground_spawner.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== ECOSYSTEM TIMELAPSE ===")

	var scene_root := Node3D.new()
	scene_root.name = "EcoTimelapse"
	root.add_child(scene_root)

	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.06, 0.1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.52, 0.58)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	scene_root.add_child(world_env)

	# Camera — top-down overview
	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 50.0
	scene_root.add_child(camera)

	# Lights
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-50, -30, 0)
	key.light_energy = 1.3
	key.shadow_enabled = true
	scene_root.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 150, 0)
	fill.light_energy = 0.5
	scene_root.add_child(fill)

	# Terrain
	var terrain_size: float = 20.0
	var presence := _PresenceGrid.new(128, Vector2(terrain_size, terrain_size))

	var terrain := MeshInstance3D.new()
	terrain.name = "Terrain"
	var plane := PlaneMesh.new()
	plane.size = Vector2(terrain_size, terrain_size)
	plane.subdivide_depth = 48
	plane.subdivide_width = 48
	terrain.mesh = plane
	var shader: Shader = load("res://algorithms/nature_system/shaders/living_ground.gdshader")
	var ground_mat := ShaderMaterial.new()
	ground_mat.shader = shader
	ground_mat.set_shader_parameter("world_size", Vector2(terrain_size, terrain_size))
	ground_mat.set_shader_parameter("world_offset", Vector2.ZERO)
	ground_mat.set_shader_parameter("presence_map", presence.get_texture())
	terrain.material_override = ground_mat
	scene_root.add_child(terrain)

	# Spawner
	var spawner := CritterSpawner.new(scene_root)
	spawner.max_population = 60

	# Ground spawner
	var gs := _GroundSpawner.new()
	gs.spawner = spawner
	gs.presence = presence
	gs.terrain_size = terrain_size
	gs.check_interval = 1.0       # Check every 1 sim-second
	gs.spawn_threshold = 0.2      # Low threshold for demo
	gs.spawn_chance = 0.6         # High chance for demo
	gs.max_ground_population = 40
	gs.min_spacing = 1.5
	gs.sample_count = 40          # More samples per check
	gs.debug = true

	# Trait mapper for morphology
	var trait_mapper := CritterTraitMapper.new()

	await process_frame
	await process_frame

	# ── SEED: Place just 3 organisms to start ──
	print("\n--- SEEDING: 3 organisms ---")

	# One tree
	var tree_dna := CritterDNA.random_kingdom(0, 42)
	tree_dna.scale = 1.2
	tree_dna.scent_strength = 0.8  # Strong ground marking
	var tree_ent := spawner.spawn(tree_dna, Vector3(4, 0, 0))
	print("  Tree at (4, 0)")

	# One flower
	var flower_dna := CritterDNA.random_kingdom(2, 99)
	flower_dna.scale = 1.0
	flower_dna.scent_strength = 0.7
	var flower_ent := spawner.spawn(flower_dna, Vector3(-4, 0, 3))
	print("  Flower at (-4, 3)")

	# One fungus
	var fungus_dna := CritterDNA.random_kingdom(3, 77)
	fungus_dna.scale = 0.8
	fungus_dna.scent_strength = 0.9
	fungus_dna.sociality = 0.9  # High spread
	var fungus_ent := spawner.spawn(fungus_dna, Vector3(0, 0, -4))
	print("  Fungus at (0, -4)")

	await process_frame
	await process_frame

	var out_dir := "user://eco_timelapse"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	# ── SIMULATE: Run 60 seconds in steps, capture every 10s ──
	var sim_time: float = 0.0
	var snapshot: int = 0
	var dt: float = 0.2  # Sim step size

	for step in 300:  # 300 × 0.2 = 60 simulated seconds
		sim_time += dt

		# Deposit presence from all organisms (boosted for demo speed)
		for entity in spawner.get_active_critters():
			if is_instance_valid(entity) and entity.dna:
				presence.deposit(
					entity.global_position,
					entity.get_kingdom(),
					entity.dna.scent_strength * entity.dna.scale * 0.8,  # Stronger deposit
					entity.dna.scale * 3.0  # Wider radius
				)

		# Process presence (decay + diffuse)
		presence.process(dt)

		# Process ground spawner
		gs.process(dt)

		# Update ground texture
		ground_mat.set_shader_parameter("presence_map", presence.get_texture())

		# Render frame
		await process_frame

		# Capture snapshot every 10 sim-seconds
		if int(sim_time) % 10 == 0 and int(sim_time) != int(sim_time - dt):
			snapshot += 1
			var pop: int = spawner.get_population_count()
			var summary: Dictionary = spawner.get_population_summary()
			print("\n--- t=%.0fs | pop=%d (tree=%d creature=%d flower=%d fungus=%d) ---" % [
				sim_time, pop,
				summary.get("tree", 0),
				summary.get("creature", 0),
				summary.get("flower", 0),
				summary.get("fungus", 0),
			])

			# Top-down
			camera.position = Vector3(0, 15.0, 0.1)
			camera.look_at(Vector3.ZERO, Vector3(0, 0, -1))
			await process_frame
			await process_frame
			_save(out_dir + "/t%02d_top.png" % snapshot)

			# Angled
			camera.position = Vector3(-8, 10.0, -8)
			camera.look_at(Vector3.ZERO, Vector3.UP)
			await process_frame
			await process_frame
			_save(out_dir + "/t%02d_angle.png" % snapshot)

			print("  Saved t%02d" % snapshot)

	# Final close-ups
	print("\n--- FINAL CLOSE-UPS ---")
	camera.position = Vector3(4, 3.0, -2)
	camera.look_at(Vector3(2, 0, 2), Vector3.UP)
	await process_frame
	await process_frame
	_save(out_dir + "/final_closeup.png")

	camera.position = Vector3(0, 12.0, 0.1)
	camera.look_at(Vector3.ZERO, Vector3(0, 0, -1))
	await process_frame
	await process_frame
	_save(out_dir + "/final_top.png")

	var final_pop: Dictionary = spawner.get_population_summary()
	print("\n=== DONE ===")
	print("Final population: %d" % final_pop.get("total", 0))
	print("  Trees: %d" % final_pop.get("tree", 0))
	print("  Creatures: %d" % final_pop.get("creature", 0))
	print("  Flowers: %d" % final_pop.get("flower", 0))
	print("  Fungi: %d" % final_pop.get("fungus", 0))
	print("  Ground-spawned: %d" % gs.get_ground_spawned_count())

	quit(0)


func _save(path: String) -> void:
	var image: Image = root.get_texture().get_image()
	if image:
		var abs_path: String = ProjectSettings.globalize_path(path)
		DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
		image.save_png(abs_path)
