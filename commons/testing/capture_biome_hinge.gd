extends SceneTree
## Native render frames at fixed simulation steps. No generated or composited art.
var out := "res://ada_run/biome_primitives/hinge"
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var scaling := "--scale" in OS.get_cmdline_user_args()
	var hall := "Trans_Scale" if scaling else "Trans_Rotation"
	var label_prefix := "scale" if scaling else "hinge"
	var frame_count := 576 if scaling else 240
	var still_frames := {0:"narrow",288:"broad",420:"open"} if scaling else {0:"closed",72:"turning",132:"open"}
	if scaling: out = "res://ada_run/biome_primitives/scale"
	var hand := root.get_node_or_null("MushroomHand")
	if hand != null:
		hand.set("show_desktop_count", false)
		for child in hand.get_children():
			if child is CanvasLayer: child.visible = false
	for name in ["NatureRenderer", "FloraSpawner", "BiomeAccrualManager"]:
		var bridge := root.get_node_or_null(name)
		if bridge != null: bridge.process_mode = Node.PROCESS_MODE_DISABLED
	root.size = Vector2i(1280,800)
	DirAccess.make_dir_recursive_absolute(out.path_join("frames"))
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
	camera.position = Vector3(1.5,1.65,5)
	camera.look_at(Vector3(0,.9,-.7))
	var biome = load("res://commons/artifacts/biome_primitives/biome_primitives.tscn").instantiate()
	biome.stage = hall
	biome.demo = true
	scene.add_child(biome)
	for frame in range(8): await process_frame
	for frame in range(frame_count):
		if frame > 0:
			biome.model.advance_hinge(1.0/12.0, false)
			biome.model.advance(1.0/12.0, false)
			biome._update_form_poses()
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var result := image.save_png(out.path_join("frames/%04d.png" % frame))
		if result != OK:
			push_error("Hinge frame failed: %d" % frame)
			quit(1)
			return
		if frame in still_frames:
			image.save_png(out.path_join(label_prefix+"_"+str(still_frames[frame])+".png"))
		if frame == (360 if scaling else 72): image.save_png("res://ada_run/biome_primitives/inside/"+hall+".png")
		if frame % 48 == 0: print("%s recording: %d / %d frames" % [hall,frame,frame_count])
	var file := FileAccess.open(out.path_join("capture.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"scene":"res://commons/artifacts/biome_primitives/biome_primitives.tscn",
		"stage":hall,"frames":frame_count,"fps":12,"seconds":frame_count/12,"visitor_in_sweep":false,
		"camera_position":[1.5,1.65,5],"camera_target":[0,.9,-.7],"resolution":[1280,800],
		"method":"native Godot renders with fixed simulation steps; movie is not a headset recording"},"  "))
	file.close()
	print("Hinge recording complete")
	quit(0)
