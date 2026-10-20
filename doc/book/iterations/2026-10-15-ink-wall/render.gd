extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-15-ink-wall/"
var camera: Camera3D
func _initialize() -> void: call_deferred("run")
func capture(file: String) -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+file+".png")
func run() -> void:
	root.size=Vector2i(1100,1100)
	var world := WorldEnvironment.new()
	world.environment=Environment.new()
	world.environment.background_mode=Environment.BG_COLOR
	world.environment.background_color=Color("303c40")
	world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color=Color.WHITE
	world.environment.ambient_light_energy=.8
	root.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-30,-20,0)
	root.add_child(light)
	camera=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	root.add_child(camera); camera.current=true
	camera.position=Vector3(0,1.1,4)
	camera.look_at(Vector3(0,1.1,0)); camera.size=2.30
	var scene = load("res://commons/artifacts/random_touch/random_touch.tscn").instantiate()
	root.add_child(scene); scene.set_physics_process(false)
	var pointer := Node3D.new(); root.add_child(pointer)
	await capture("empty")
	for mode in 2:
		for lane in 5:
			scene.points[lane].on_desktop_grab(pointer); scene._sync_hand()
			scene.advance(48.0/scene.Motion.RATES[lane])
			scene.points[lane].on_desktop_drop(); scene._sync_hand(); scene.advance(2)
		await capture("uniform" if mode==0 else "gaussian")
		if mode==0: scene.act(4)
	camera.position=Vector3(1.5,1.65,4)
	camera.look_at(Vector3(0,1.1,0))
	await capture("oblique")
	print("INK WALL RENDER COMPLETE")
	quit()
