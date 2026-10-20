extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-15-random-abacus/"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1100,1000)
	var world := WorldEnvironment.new()
	world.environment=Environment.new()
	world.environment.background_mode=Environment.BG_COLOR
	world.environment.background_color=Color("303c40")
	world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color=Color.WHITE
	world.environment.ambient_light_energy=.9
	root.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-30,-20,0)
	root.add_child(light)
	var camera := Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	root.add_child(camera)
	camera.current=true
	var artifact = load("res://commons/artifacts/random_touch/random_touch.tscn").instantiate()
	root.add_child(artifact)
	artifact.set_physics_process(false)
	camera.position=Vector3(0,1.1,4)
	camera.look_at(Vector3(0,1.1,0))
	camera.size=2.35
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"front.png")
	# Show the fifth bead off its resting rod without needing a headset.
	artifact.offsets[4]=artifact.Motion.offset(artifact.record,4,2.4)
	artifact._update_pose()
	camera.position=Vector3(1.8,1.7,4)
	camera.look_at(Vector3(0,1.1,0))
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"oblique.png")
	print("ABACUS RENDER COMPLETE")
	quit()
