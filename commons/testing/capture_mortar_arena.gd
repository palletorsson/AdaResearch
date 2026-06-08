# Fixed-camera capture of mortar_vector_siege — positioned to see the arena/mortar/
# drones/explosion, ignoring the large emissive sky-dome that breaks AABB framing.
extends SceneTree

func _initialize() -> void:
	_run()

func _run() -> void:
	var root := get_root()
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.06, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.55, 0.65)
	env.ambient_light_energy = 0.8
	we.environment = env
	root.add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-55, -40, 0)
	key.light_energy = 1.0
	root.add_child(key)

	var inst = load("res://commons/artifacts/mortar_vector_siege/mortar_vector_siege.tscn").instantiate()
	root.add_child(inst)

	# Let the desktop auto-fire loft a couple of shells and detonate.
	await create_timer(7.0).timeout

	var cam := Camera3D.new()
	cam.fov = 58
	root.add_child(cam)
	cam.make_current()
	cam.position = Vector3(7.5, 5.5, 9.0)    # outside the arena rim, inside the dome
	cam.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)

	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png("user://mortar_arena.png")
	print("[mortar] saved arena shot")
	quit()
