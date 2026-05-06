extends SceneTree

## Capture how the living ground looks at each spine stage.
## Renders 7 maps representing the progression from barren lab to full ecosystem.

const _PresenceGrid = preload("res://algorithms/nature_system/systems/presence_grid.gd")

# Representative maps for each stage of the progression
const STAGE_MAPS: Array[Dictionary] = [
	{"label": "01_barren", "density": 0.0, "kingdoms": [], "terrain": "flat", "title": "Primitives (Order 1) — Barren Lab"},
	{"label": "02_flowers", "density": 0.1, "kingdoms": ["flower"], "terrain": "flat", "title": "Color (Order 3) — First Flowers"},
	{"label": "03_trees", "density": 0.15, "kingdoms": ["flower", "tree"], "terrain": "flat", "title": "Forces (Order 4) — Trees Join"},
	{"label": "04_noise", "density": 0.4, "kingdoms": ["flower", "tree", "fungus"], "terrain": "noise", "title": "Noise (Order 8) — Terrain Sculpted"},
	{"label": "05_growth", "density": 0.5, "kingdoms": ["flower", "tree", "fungus"], "terrain": "growth", "title": "Cellular Automata (Order 9) — Ground Remembers"},
	{"label": "06_selfgen", "density": 0.8, "kingdoms": ["flower", "tree", "fungus", "creature"], "terrain": "self_generating", "title": "Procgen (Order 12) — Self-Organizing"},
	{"label": "07_full", "density": 1.0, "kingdoms": ["flower", "tree", "fungus", "creature"], "terrain": "self_generating", "title": "QFEP Lab (Order 17) — Full Life"},
]

const KINGDOM_MAP: Dictionary = {
	"tree": 0,
	"creature": 1,
	"flower": 2,
	"fungus": 3,
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== SPINE GROUND PROGRESSION ===\n")

	var out_base := "user://spine_ground"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_base))

	for stage in STAGE_MAPS:
		print("--- %s ---" % stage["title"])
		await _render_stage(stage, out_base)
		print("")

	print("=== DONE ===")
	quit(0)


func _render_stage(stage: Dictionary, out_base: String) -> void:
	var label: String = stage["label"]
	var density: float = stage["density"]
	var kingdoms: Array = stage["kingdoms"]
	var terrain: String = stage["terrain"]

	# Build scene
	var scene_root := Node3D.new()
	scene_root.name = "Stage_%s" % label
	root.add_child(scene_root)

	# Environment — shifts with density
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	# Early = clinical white-grey, late = warm dark
	var bg_warmth: float = density
	env.background_color = Color(
		lerp(0.2, 0.06, bg_warmth),
		lerp(0.2, 0.06, bg_warmth),
		lerp(0.22, 0.1, bg_warmth)
	)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(
		lerp(0.6, 0.5, bg_warmth),
		lerp(0.6, 0.52, bg_warmth),
		lerp(0.62, 0.58, bg_warmth)
	)
	env.ambient_light_energy = lerp(0.5, 0.9, density)
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
	key.rotation_degrees = Vector3(-50, -30, 0)
	key.light_energy = lerp(1.0, 1.3, density)
	key.shadow_enabled = true
	scene_root.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 150, 0)
	fill.light_energy = 0.5
	scene_root.add_child(fill)

	# Terrain
	var terrain_size: float = 16.0
	var terrain_mesh := MeshInstance3D.new()
	terrain_mesh.name = "Terrain"
	var plane := PlaneMesh.new()
	plane.size = Vector2(terrain_size, terrain_size)
	plane.subdivide_depth = 48
	plane.subdivide_width = 48
	terrain_mesh.mesh = plane

	if terrain == "flat" and density < 0.05:
		# Barren lab — clean grey floor
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.35, 0.38)
		mat.roughness = 0.5
		terrain_mesh.material_override = mat
	elif terrain == "flat":
		# Flat with slight warmth — life is starting
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(
			lerp(0.3, 0.22, density),
			lerp(0.3, 0.24, density),
			lerp(0.32, 0.18, density)
		)
		mat.roughness = 0.7
		terrain_mesh.material_override = mat
	else:
		# Living ground shader
		var presence := _PresenceGrid.new(128, Vector2(terrain_size, terrain_size))

		# Deposit presence based on kingdoms + density
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(label)
		var half: float = terrain_size * 0.5

		# Simulate organisms marking the ground
		for _pass in 30:
			for kingdom_name in kingdoms:
				var k: int = KINGDOM_MAP.get(kingdom_name, 0)
				var count: int = int(density * 5)
				for _i in count:
					var pos := Vector3(
						rng.randf_range(-half * 0.8, half * 0.8),
						0,
						rng.randf_range(-half * 0.8, half * 0.8)
					)
					presence.deposit(pos, k, density * 0.5, 3.0)
			presence.process(0.1)

		# Extra diffusion
		for _i in 10:
			presence.process(0.1)

		var shader: Shader = load("res://algorithms/nature_system/shaders/living_ground.gdshader")
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("world_size", Vector2(terrain_size, terrain_size))
		mat.set_shader_parameter("world_offset", Vector2.ZERO)
		mat.set_shader_parameter("presence_map", presence.get_texture())
		terrain_mesh.material_override = mat

	scene_root.add_child(terrain_mesh)

	# Spawn some organisms on the ground (visual reference)
	if density > 0.05:
		var spawner := CritterSpawner.new(scene_root)
		spawner.max_population = int(density * 15)
		var trait_mapper := CritterTraitMapper.new()

		var rng2 := RandomNumberGenerator.new()
		rng2.seed = hash(label) + 999
		var half: float = terrain_size * 0.5

		for kingdom_name in kingdoms:
			var k: int = KINGDOM_MAP.get(kingdom_name, 0)
			var count: int = maxi(int(density * 4), 1)
			for _i in count:
				var dna := CritterDNA.random_kingdom(k, rng2.randi())
				dna.scale *= lerp(0.5, 1.0, density)
				var pos := Vector3(
					rng2.randf_range(-half * 0.7, half * 0.7),
					0,
					rng2.randf_range(-half * 0.7, half * 0.7)
				)
				spawner.spawn(dna, pos, 1)  # LOD 1 for speed

	await process_frame
	await process_frame
	await process_frame

	# Wait for meshes to build
	var timer := Timer.new()
	root.add_child(timer)
	timer.wait_time = 1.5
	timer.one_shot = true
	timer.start()
	await timer.timeout
	timer.queue_free()

	# Top-down shot
	camera.position = Vector3(0, 14.0, 0.1)
	camera.look_at(Vector3.ZERO, Vector3(0, 0, -1))
	await process_frame
	await process_frame
	_save(out_base + "/%s_top.png" % label)
	print("  Saved %s_top.png" % label)

	# Angled overview
	camera.position = Vector3(-7, 8.0, -7)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	await process_frame
	await process_frame
	_save(out_base + "/%s_angle.png" % label)
	print("  Saved %s_angle.png" % label)

	# Cleanup
	scene_root.queue_free()
	await process_frame


func _save(path: String) -> void:
	var image: Image = root.get_texture().get_image()
	if image:
		var abs_path: String = ProjectSettings.globalize_path(path)
		DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
		image.save_png(abs_path)
