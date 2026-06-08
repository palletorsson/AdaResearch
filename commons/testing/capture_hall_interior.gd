# Interior capture of reflection_hall — camera inside the sealed room so the
# bouncing balls + d/n̂/r reflection annotations + trails are visible.
extends SceneTree

func _initialize() -> void:
	_run()

func _run() -> void:
	var root := get_root()
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.09, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.72, 0.8)
	env.ambient_light_energy = 1.4
	we.environment = env
	root.add_child(we)
	var omni := OmniLight3D.new()
	omni.position = Vector3(0, 2.4, 0)
	omni.omni_range = 12.0
	omni.light_energy = 2.0
	root.add_child(omni)

	var inst = load("res://commons/artifacts/reflection_hall/reflection_hall.tscn").instantiate()
	root.add_child(inst)

	# Let the desktop auto-fire launch several balls and bounce them around.
	await create_timer(7.5).timeout

	var cam := Camera3D.new()
	cam.fov = 75
	root.add_child(cam)
	cam.make_current()
	cam.position = Vector3(2.0, 2.55, 2.0)   # inside, just under the ceiling, a corner
	cam.look_at(Vector3(-0.3, 0.6, -0.4), Vector3.UP)

	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png("user://reflection_hall_interior.png")
	print("[hall] saved interior shot")
	quit()
