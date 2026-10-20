extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-15-hand-and-interfaces/"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,960)
	var world := WorldEnvironment.new()
	world.environment=Environment.new()
	world.environment.background_mode=Environment.BG_COLOR
	world.environment.background_color=Color("404b50")
	world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color=Color.WHITE
	world.environment.ambient_light_energy=.8
	root.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-30,-20,0)
	root.add_child(light)
	var camera := Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	root.add_child(camera)
	camera.current=true
	var specs := [
		["geiger","res://commons/artifacts/geiger_counter/geiger_counter.gd",Vector3(0,1.5,6),Vector3(0,1.5,0),3.5],
		["lava","res://commons/artifacts/lava_entropy_wall/lava_entropy_wall.gd",Vector3(0,1.7,7),Vector3(0,1.7,0),3.8],
		["touch","res://commons/artifacts/random_touch/random_touch.gd",Vector3(5,4,8),Vector3(0,1,0),6.5],
		["return","res://commons/artifacts/random_return/random_return.gd",Vector3(5,5,7),Vector3(0,1,0),6.5]]
	for spec in specs:
		var artifact = load(spec[1]).new()
		if spec[0]=="return": artifact.route_link="preview"
		root.add_child(artifact)
		camera.position=spec[2]; camera.look_at(spec[3]); camera.size=spec[4]
		for i in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+spec[0]+".png")
		artifact.queue_free()
		await process_frame
	var page = load("res://algorithms/randomness/randomnumbergeneration/scenes/random_number_book_page_1955.tscn").instantiate()
	page.row_stream=true; page.position.y=3
	root.add_child(page)
	page.set_process(false)
	for i in 5: page._cascade_step(); page._advance_stream(2)
	camera.position=Vector3(0,3,-10); camera.look_at(Vector3(0,3,0)); camera.size=6.8
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"page.png")
	camera.position=Vector3(0,1,-3); camera.look_at(Vector3(0,.95,-.65)); camera.size=1.4
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"select.png")
	print("RENDER COMPLETE")
	quit()
