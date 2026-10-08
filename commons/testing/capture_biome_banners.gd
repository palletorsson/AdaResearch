extends SceneTree
const Bridge := preload("res://commons/artifacts/biome_inheritance/biome_inheritance.gd")
const OUT := "res://ada_run/biome_inheritance/banners"
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	var hand := root.get_node_or_null("MushroomHand")
	if hand != null:
		hand.set("show_desktop_count",false)
		for child in hand.get_children():
			if child is CanvasLayer: child.visible = false
	for name in ["NatureRenderer","FloraSpawner","BiomeAccrualManager"]:
		var autoload := root.get_node_or_null(name)
		if autoload != null: autoload.process_mode = Node.PROCESS_MODE_DISABLED
	root.size = Vector2i(1440,900)
	DirAccess.make_dir_recursive_absolute(OUT.path_join("frames"))
	var scene := Node3D.new()
	root.add_child(scene)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("303f43")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("f4eddd")
	env.ambient_light_energy = .7
	world.environment = env
	scene.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38,-30,0)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	scene.add_child(sun)
	var camera := Camera3D.new()
	camera.current = true
	scene.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 15.5
	camera.position = Vector3(10,8,17)
	camera.look_at(Vector3(0,2.0,0))
	var bridge := Bridge.new()
	bridge.banners = true
	bridge.automatic = false
	scene.add_child(bridge)
	bridge.habitat.process_mode = Node.PROCESS_MODE_DISABLED
	bridge.apply_banner_time(0)
	await photo("doors")
	var lowered: Dictionary = bridge.get_state()
	bridge.apply_banner_time(8)
	await photo("banners")
	var raised: Dictionary = bridge.get_state()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 83
	var eye_y: float = bridge.habitat._h_at(1.0,5.5)+1.65
	camera.position = Vector3(1.0,eye_y,5.5)
	camera.look_at(Vector3(0,3.25,0))
	await photo("inside")
	camera.fov = 58
	camera.position = Vector3(1,4.5,6.0)
	camera.look_at(Vector3(-1.25,3.35,0))
	await photo("patterns")
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 15.5
	camera.position = Vector3(10,8,17)
	camera.look_at(Vector3(0,2.0,0))
	for frame in range(240):
		bridge.apply_banner_time(frame/12.0)
		await process_frame
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png(OUT.path_join("frames/%04d.png" % frame))
		if result != OK:
			push_error("Banner capture failed")
			quit(1)
			return
	var file := FileAccess.open(OUT.path_join("capture.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"method":"native Godot; fixed simulation steps; not headset performance",
		"frames":240,"fps":12,"duration":20,"lowered":lowered,"raised":raised,"standing_camera_y":eye_y},"  "))
	file.close()
	print("[biome_banners] native capture complete")
	quit(0)

func photo(label: String) -> void:
	for frame in range(5): await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(OUT.path_join(label+".png"))
	assert(error == OK)
	print("Captured "+label)
