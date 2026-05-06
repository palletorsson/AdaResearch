extends SceneTree

## Capture a grid map with bio organisms placed at specific cells.
## Builds a small map from scratch with structure + algorithm artifact + critter_placer.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== GRID WITH BIO ===")

	var scene_root := Node3D.new()
	scene_root.name = "GridBioTest"
	root.add_child(scene_root)

	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.14, 0.18)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.52, 0.56)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	scene_root.add_child(world_env)

	# Camera
	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 50.0
	scene_root.add_child(camera)

	# Lights
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-45, -30, 0)
	key.light_energy = 1.2
	key.shadow_enabled = true
	scene_root.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 150, 0)
	fill.light_energy = 0.5
	scene_root.add_child(fill)

	# ── Build a simple grid floor (8x6) ──
	var cube_size: float = 1.0
	var width: int = 8
	var depth: int = 6
	var floor_container := Node3D.new()
	floor_container.name = "GridFloor"
	scene_root.add_child(floor_container)

	# Floor tiles
	for z in depth:
		for x in width:
			# Skip walls (border)
			var is_wall: bool = x == 0 or x == width - 1 or z == 0 or z == depth - 1
			var tile := MeshInstance3D.new()
			if is_wall:
				var box := BoxMesh.new()
				box.size = Vector3(cube_size * 0.95, cube_size * 0.8, cube_size * 0.95)
				tile.mesh = box
				tile.position = Vector3(float(x) * cube_size, cube_size * 0.4, float(z) * cube_size)
				var mat := StandardMaterial3D.new()
				mat.albedo_color = Color(0.25, 0.25, 0.3)
				mat.roughness = 0.6
				tile.material_override = mat
			else:
				var box := BoxMesh.new()
				box.size = Vector3(cube_size * 0.95, 0.1, cube_size * 0.95)
				tile.mesh = box
				tile.position = Vector3(float(x) * cube_size, 0.05, float(z) * cube_size)
				var mat := StandardMaterial3D.new()
				mat.albedo_color = Color(0.3, 0.3, 0.33)
				mat.roughness = 0.5
				tile.material_override = mat
			floor_container.add_child(tile)

	# ── Place organisms at specific grid cells ──
	var trait_mapper := CritterTraitMapper.new()

	# Cell (2,2): L-system tree preset
	print("Placing lsystem_tree at (2,2)...")
	var tree_dna := CritterDNA.random_kingdom(0, 42)
	tree_dna.segments = 5.0
	tree_dna.branch_angle = 45.0
	tree_dna.symmetry = 3.0
	tree_dna.scale = 0.8
	tree_dna.leaf_density = 0.7
	tree_dna.branch_decay = 0.65
	tree_dna.primary_color = Color.html("2ecc71")
	tree_dna.secondary_color = Color.html("8b4513")
	var tree_node := Node3D.new()
	tree_node.name = "Bio_LSystemTree"
	tree_node.position = Vector3(2.0 * cube_size, 0.1, 2.0 * cube_size)
	scene_root.add_child(tree_node)
	MorphologyRouter.build(tree_dna, tree_node, trait_mapper, 0)

	# Cell (5,2): Fibonacci flower
	print("Placing fibonacci_flower at (5,2)...")
	var flower_dna := CritterDNA.random_kingdom(2, 99)
	flower_dna.symmetry = 8.0
	flower_dna.phyllotaxis = 0.618
	flower_dna.segments = 3.0
	flower_dna.scale = 0.7
	flower_dna.scent_strength = 0.7
	flower_dna.branch_angle = 60.0
	flower_dna.primary_color = Color.html("ff6b6b")
	flower_dna.secondary_color = Color.html("c44569")
	var flower_node := Node3D.new()
	flower_node.name = "Bio_FibonacciFlower"
	flower_node.position = Vector3(5.0 * cube_size, 0.1, 2.0 * cube_size)
	scene_root.add_child(flower_node)
	MorphologyRouter.build(flower_dna, flower_node, trait_mapper, 0)

	# Cell (2,4): Turing fungus
	print("Placing turing_fungus at (2,4)...")
	var fungus_dna := CritterDNA.random_kingdom(3, 77)
	fungus_dna.sociality = 0.9
	fungus_dna.pattern_type = 0.5
	fungus_dna.scale = 0.6
	fungus_dna.transparency = 0.15
	fungus_dna.primary_color = Color.html("a29bfe")
	fungus_dna.secondary_color = Color.html("6c5ce7")
	var fungus_node := Node3D.new()
	fungus_node.name = "Bio_TuringFungus"
	fungus_node.position = Vector3(2.0 * cube_size, 0.1, 4.0 * cube_size)
	scene_root.add_child(fungus_node)
	MorphologyRouter.build(fungus_dna, fungus_node, trait_mapper, 0)

	# Cell (5,4): Flocking creature
	print("Placing flocking_creature at (5,4)...")
	var creature_dna := CritterDNA.random_kingdom(1, 55)
	creature_dna.mobility = 0.8
	creature_dna.sociality = 0.7
	creature_dna.curiosity = 0.6
	creature_dna.segments = 6.0
	creature_dna.scale = 0.6
	creature_dna.primary_color = Color.html("e84393")
	creature_dna.secondary_color = Color.html("6c5ce7")
	var creature_node := Node3D.new()
	creature_node.name = "Bio_FlockingCreature"
	creature_node.position = Vector3(5.0 * cube_size, 0.1, 4.0 * cube_size)
	scene_root.add_child(creature_node)
	MorphologyRouter.build(creature_dna, creature_node, trait_mapper, 0)

	# Cell (3.5, 3): A "catalyst" placeholder (orange crystal)
	var catalyst := MeshInstance3D.new()
	catalyst.name = "CatalystPlaceholder"
	var crystal := CylinderMesh.new()
	crystal.top_radius = 0.0
	crystal.bottom_radius = 0.15
	crystal.height = 0.4
	crystal.radial_segments = 6
	catalyst.mesh = crystal
	catalyst.position = Vector3(3.5 * cube_size, 0.3, 3.0 * cube_size)
	var cat_mat := StandardMaterial3D.new()
	cat_mat.albedo_color = Color(0.9, 0.5, 0.1)
	cat_mat.emission_enabled = true
	cat_mat.emission = Color(0.9, 0.5, 0.1)
	cat_mat.emission_energy_multiplier = 0.5
	cat_mat.roughness = 0.2
	cat_mat.metallic = 0.3
	catalyst.material_override = cat_mat
	scene_root.add_child(catalyst)

	# ── Labels (simple cubes with color to mark cells) ──
	# Small colored markers at each bio cell
	for cell_info in [
		[Vector3(2, 0, 2), Color(0.2, 0.8, 0.3, 0.3)],  # tree = green
		[Vector3(5, 0, 2), Color(0.9, 0.3, 0.5, 0.3)],  # flower = pink
		[Vector3(2, 0, 4), Color(0.6, 0.3, 0.9, 0.3)],  # fungus = purple
		[Vector3(5, 0, 4), Color(0.9, 0.5, 0.1, 0.3)],  # creature = orange
	]:
		var marker := MeshInstance3D.new()
		var mbox := BoxMesh.new()
		mbox.size = Vector3(cube_size * 0.9, 0.02, cube_size * 0.9)
		marker.mesh = mbox
		marker.position = (cell_info[0] as Vector3) * cube_size + Vector3(0, 0.12, 0)
		var mmat := StandardMaterial3D.new()
		mmat.albedo_color = cell_info[1] as Color
		mmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		marker.material_override = mmat
		scene_root.add_child(marker)

	await process_frame
	await process_frame
	await process_frame

	# Wait for morphology to build
	var timer := Timer.new()
	root.add_child(timer)
	timer.wait_time = 2.5
	timer.one_shot = true
	timer.start()
	await timer.timeout
	timer.queue_free()

	print("Capturing...")
	var out_dir := "user://grid_bio"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	# Center of the grid
	var center := Vector3(3.5 * cube_size, 0, 3.0 * cube_size)

	# Overview — see the whole grid with all organisms
	camera.position = Vector3(3.5, 8.0, -2.0)
	camera.look_at(center, Vector3.UP)
	await process_frame
	await process_frame
	_save(out_dir + "/overview.png")
	print("  Saved overview.png")

	# Top-down — grid layout visible
	camera.position = Vector3(3.5, 10.0, 3.0)
	camera.look_at(center, Vector3(0, 0, -1))
	await process_frame
	await process_frame
	_save(out_dir + "/top_down.png")
	print("  Saved top_down.png")

	# Walk-through perspective — player eye level
	camera.position = Vector3(1.0, 1.6, 1.0)
	camera.look_at(Vector3(3.5, 0.5, 3.0), Vector3.UP)
	await process_frame
	await process_frame
	_save(out_dir + "/player_view.png")
	print("  Saved player_view.png")

	# Close-up on tree at (2,2)
	camera.position = Vector3(1.5, 2.0, 1.0)
	camera.look_at(Vector3(2.0, 0.5, 2.0), Vector3.UP)
	await process_frame
	await process_frame
	_save(out_dir + "/tree_closeup.png")
	print("  Saved tree_closeup.png")

	# Close-up on fungus + creature side
	camera.position = Vector3(6.0, 2.0, 5.0)
	camera.look_at(Vector3(3.5, 0.3, 4.0), Vector3.UP)
	await process_frame
	await process_frame
	_save(out_dir + "/bio_side.png")
	print("  Saved bio_side.png")

	print("=== DONE ===")
	quit(0)


func _save(path: String) -> void:
	var image: Image = root.get_texture().get_image()
	if image:
		var abs_path: String = ProjectSettings.globalize_path(path)
		DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
		image.save_png(abs_path)
