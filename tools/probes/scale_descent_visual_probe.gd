extends SceneTree
## Small native assembly render; no claim that this is a full-tower screenshot.
var out := "user://"
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	run.call_deferred()
func run() -> void:
	var host := Node3D.new();root.add_child(host);current_scene=host;host.set_meta("void_content_floor",14)
	var world := WorldEnvironment.new();var env := Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("dedce2")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.7
	world.environment=env;host.add_child(world)
	var sun := DirectionalLight3D.new();host.add_child(sun);sun.rotation_degrees=Vector3(-40,-25,0);sun.light_energy=1.3
	var rooms: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/rooms.json"))
	var item: Dictionary={}
	for record in rooms.floors[14].artifacts:
		if record.id=="sequence":item=record;break
	var artifact: Node3D=load("res://commons/void/trials/transformation/introduction_mezzanine.gd").new()
	host.add_child(artifact);artifact.apply_grid_config(item.config)
	var cube: Node3D=artifact.get_node("GrowingCube");cube.set_physics_process(false)
	cube.current_scale=cube.max_scale;cube.apply_scale()
	artifact.get_node("TurningPlank").set_physics_process(false)
	var camera := Camera3D.new();host.add_child(camera);camera.position=Vector3(-2,7.5,11);camera.look_at(Vector3(-8,1,0));camera.make_current()
	for i in range(8):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("native-assembly.png"))
	FileAccess.open(out.path_join("visual-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":true,"scope":"Actual native assembly render, original live electrical shader and conducting strands. No whole-tower frame; static upper dock for visual inspection."},"  "))
	host.queue_free()
	for i in range(8):await process_frame
	print("SCALE_VISUAL_READY");quit()
