extends SceneTree
const Bridge := preload("res://commons/artifacts/biome_inheritance/biome_inheritance.gd")
const OUT := "res://ada_run/biome_inheritance/evolution"
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
	root.size = Vector2i(1200,800)
	DirAccess.make_dir_recursive_absolute(OUT)
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
	camera.look_at(Vector3(0,2,0))
	var bridge := Bridge.new()
	bridge.evolution_stage = "Point_One"
	scene.add_child(bridge)
	var records: Array = []
	for hall in ["Point_One","Point_Triangle_Context","Trans_Translation","Trans_Rotation","Trans_Scale","Color_Context_Placed","Pattern_Foundry","Random_Mushrooms","LSystems_Growth"]:
		assert(bridge.set_hall(hall))
		bridge.habitat.process_mode = Node.PROCESS_MODE_DISABLED
		for frame in range(5): await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(OUT.path_join(hall+".png"))==OK)
		records.append(bridge.get_state())
		print("Captured map "+hall)
	var file := FileAccess.open(OUT.path_join("capture.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"method":"native Godot; one live specimen, explicit hall transitions, fixed camera","states":records},"  "))
	file.close()
	print("[biome_map_evolution] native capture complete")
	quit(0)
