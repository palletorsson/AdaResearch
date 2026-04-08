extends SceneTree

## Capture the living ground — builds a terrain with manually deposited
## presence patterns, then captures from multiple angles.

const _PresenceGrid = preload("res://algorithms/nature_system/systems/presence_grid.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("capture_living_ground: Building scene...")

	var scene_root := Node3D.new()
	scene_root.name = "LivingGroundTest"
	root.add_child(scene_root)

	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.08, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.55, 0.6)
	env.ambient_light_energy = 0.9
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
	key.light_energy = 1.3
	key.shadow_enabled = true
	scene_root.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 150, 0)
	fill.light_energy = 0.5
	scene_root.add_child(fill)

	# Create presence grid
	var terrain_size: float = 20.0
	var presence := _PresenceGrid.new(128, Vector2(terrain_size, terrain_size))

	# Manually deposit presence patterns — simulate organisms
	print("capture_living_ground: Depositing presence...")

	# Tree cluster (top-left)
	for i in 20:
		presence.deposit(Vector3(4.0, 0, 4.0), 0, 0.3, 3.0)
		presence.deposit(Vector3(5.5, 0, 3.0), 0, 0.25, 2.5)
		presence.deposit(Vector3(3.0, 0, 5.5), 0, 0.2, 2.0)
		presence.process(0.1)

	# Fungus cluster (top-right)
	for i in 20:
		presence.deposit(Vector3(-4.0, 0, 4.0), 3, 0.35, 2.5)
		presence.deposit(Vector3(-5.0, 0, 3.0), 3, 0.3, 2.0)
		presence.deposit(Vector3(-3.0, 0, 5.0), 3, 0.25, 3.0)
		presence.process(0.1)

	# Flower scatter (bottom)
	for i in 15:
		presence.deposit(Vector3(0.0, 0, -4.0), 2, 0.3, 2.0)
		presence.deposit(Vector3(2.0, 0, -5.0), 2, 0.25, 2.5)
		presence.deposit(Vector3(-2.0, 0, -3.5), 2, 0.2, 2.0)
		presence.process(0.1)

	# Creature trail (diagonal)
	for i in 30:
		var t: float = float(i) / 30.0
		var pos := Vector3(lerp(-6.0, 6.0, t), 0, lerp(-6.0, 6.0, t))
		presence.deposit(pos, 1, 0.15, 1.5)
		presence.process(0.05)

	# Final diffusion passes
	for i in 10:
		presence.process(0.1)

	# Build terrain with living ground shader
	var terrain := MeshInstance3D.new()
	terrain.name = "Terrain"
	var plane := PlaneMesh.new()
	plane.size = Vector2(terrain_size, terrain_size)
	plane.subdivide_depth = 64
	plane.subdivide_width = 64
	terrain.mesh = plane

	var shader: Shader = load("res://algorithms/nature_system/shaders/living_ground.gdshader")
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("world_size", Vector2(terrain_size, terrain_size))
	mat.set_shader_parameter("world_offset", Vector2.ZERO)
	mat.set_shader_parameter("presence_map", presence.get_texture())
	terrain.material_override = mat
	scene_root.add_child(terrain)

	await process_frame
	await process_frame
	await process_frame

	# Wait for render
	var timer := Timer.new()
	root.add_child(timer)
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.start()
	await timer.timeout
	timer.queue_free()

	print("capture_living_ground: Capturing...")
	var out_dir := "user://living_ground"

	# Top-down
	camera.position = Vector3(0, 15.0, 0.1)
	camera.look_at(Vector3.ZERO, Vector3(0, 0, -1))
	await process_frame
	await process_frame
	_save(out_dir + "/top_down.png")
	print("  Saved top_down.png")

	# Angled overview
	camera.position = Vector3(-8, 10.0, -8)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	await process_frame
	await process_frame
	_save(out_dir + "/overview.png")
	print("  Saved overview.png")

	# Low angle
	camera.position = Vector3(-8, 2.5, -2)
	camera.look_at(Vector3(2, 0, 3), Vector3.UP)
	await process_frame
	await process_frame
	_save(out_dir + "/ground_level.png")
	print("  Saved ground_level.png")

	# Tree zone close-up
	camera.position = Vector3(4, 4.0, 1)
	camera.look_at(Vector3(4, 0, 4), Vector3.UP)
	await process_frame
	await process_frame
	_save(out_dir + "/tree_zone.png")
	print("  Saved tree_zone.png")

	# Fungus zone close-up
	camera.position = Vector3(-4, 4.0, 1)
	camera.look_at(Vector3(-4, 0, 4), Vector3.UP)
	await process_frame
	await process_frame
	_save(out_dir + "/fungus_zone.png")
	print("  Saved fungus_zone.png")

	print("capture_living_ground: Done!")
	quit(0)


func _save(path: String) -> void:
	var image: Image = root.get_texture().get_image()
	if image:
		var abs_path: String = ProjectSettings.globalize_path(path)
		DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
		image.save_png(abs_path)
