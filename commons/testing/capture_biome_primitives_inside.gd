extends SceneTree
const OUT := "res://ada_run/biome_primitives/inside"
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	# This isolated study has no inventory. Do not photograph a delayed autoload HUD.
	var hand := root.get_node_or_null("MushroomHand")
	if hand != null:
		hand.set("show_desktop_count", false)
		for child in hand.get_children():
			if child is CanvasLayer: child.visible = false
	root.size = Vector2i(1280,800)
	DirAccess.make_dir_recursive_absolute(OUT)
	var scene := Node3D.new()
	root.add_child(scene)
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("29322e")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("e2e5da")
	settings.ambient_light_energy = .7
	env.environment = settings
	scene.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52,-25,0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	scene.add_child(sun)
	var camera := Camera3D.new()
	camera.fov = 75
	camera.current = true
	scene.add_child(camera)
	camera.position = Vector3(1.5,1.65,5.0)
	camera.look_at(Vector3(0,.05,1.5))
	var resource: PackedScene = load("res://commons/artifacts/biome_primitives/biome_primitives.tscn")
	for hall in ["Point_One","Point_Lines","Point_Trace","Point_Line_Grid","Point_Triangle_Context","Primitives_Polythedra"]:
		camera.look_at(Vector3(0,.9,-.7) if hall in ["Point_Triangle_Context","Primitives_Polythedra"] else Vector3(0,.05,1.5))
		var biome: Node3D = resource.instantiate()
		biome.stage = hall
		biome.demo = true
		scene.add_child(biome)
		for frame in range(8): await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var result := image.save_png(OUT.path_join(hall+".png"))
		if result != OK:
			push_error("Capture failed: "+hall)
			quit(1)
			return
		biome.free()
	var done := FileAccess.open(OUT.path_join("_done.txt"),FileAccess.WRITE)
	done.store_string("Six full-size stages, camera at 1.65 m; shared viewpoint within each comparison.\n")
	done.close()
	quit(0)
