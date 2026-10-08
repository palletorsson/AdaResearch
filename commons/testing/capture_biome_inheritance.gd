extends SceneTree
const Bridge := preload("res://commons/artifacts/biome_inheritance/biome_inheritance.gd")
const OUT := "res://ada_run/biome_inheritance"
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
	root.size = Vector2i(1280,800)
	DirAccess.make_dir_recursive_absolute(OUT.path_join("frames"))
	var scene := Node3D.new()
	root.add_child(scene)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("343c39")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dfdfcd")
	env.ambient_light_energy = .75
	world.environment = env
	scene.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42,-35,0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	scene.add_child(sun)
	var camera := Camera3D.new()
	camera.current = true
	scene.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 17
	camera.position = Vector3(12,12,17)
	camera.look_at(Vector3(0,.9,0))
	var early = load("res://commons/artifacts/biome_primitives/biome_primitives.tscn").instantiate()
	early.stage = "Trans_Scale"
	early.demo = true
	early.hinge_preview_degrees = 45
	scene.add_child(early)
	await photo("earlier")
	early.free()
	var bridge := Bridge.new()
	bridge.habitat_stage = "Primitives_Melencolia"
	bridge.automatic = false
	scene.add_child(bridge)
	await photo("first_cover")
	bridge.free()
	bridge = Bridge.new()
	bridge.automatic = false
	scene.add_child(bridge)
	bridge.habitat.process_mode = Node.PROCESS_MODE_DISABLED
	await photo("later_narrow")
	var narrow: Dictionary = bridge.get_state()
	bridge.apply_width(1.25)
	await photo("later_wide")
	var wide: Dictionary = bridge.get_state()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 80
	var standing_y: float = bridge.habitat._h_at(1.0,5.5)+1.65
	camera.position = Vector3(1.0,standing_y,5.5)
	camera.look_at(Vector3(0,1.1,-.6))
	await photo("inside")
	# A close overview keeps the foliage changes visible throughout the film.
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 14.5
	camera.position = Vector3(8,13,14)
	camera.look_at(Vector3(0,.5,0))
	for frame in range(144):
		bridge.apply_width(Bridge.width_at(frame/12.0))
		await process_frame
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png(OUT.path_join("frames/%04d.png" % frame))
		if result != OK:
			push_error("Inheritance capture failed")
			quit(1)
			return
	var file := FileAccess.open(OUT.path_join("capture.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"method":"native Godot; fixed simulation steps; not a headset performance test",
		"frames":144,"fps":12,"duration":12,"narrow":narrow,"wide":wide,"standing_camera_y":standing_y},"  "))
	file.close()
	print("[biome_inheritance] native capture complete")
	quit(0)

func photo(label: String) -> void:
	for frame in range(5): await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(OUT.path_join(label+".png"))
	assert(error == OK)
	print("Captured "+label)
