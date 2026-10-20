extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-15-seed-window-body/"
var camera: Camera3D
func _initialize() -> void: call_deferred("run")
func capture(file: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+file+".png")
func run() -> void:
	root.size=Vector2i(1400,1500)
	var world:=WorldEnvironment.new()
	world.environment=Environment.new()
	world.environment.background_mode=Environment.BG_COLOR
	world.environment.background_color=Color("687879")
	world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color=Color.WHITE
	world.environment.ambient_light_energy=0.8
	root.add_child(world)
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-35,-20,0)
	root.add_child(light)
	camera=Camera3D.new(); root.add_child(camera); camera.current=true
	camera.position=Vector3(0.25,2.65,7.1)
	camera.look_at(Vector3(0.25,2.65,0)); camera.fov=47
	var room:=Node3D.new(); room.set_meta("em_map","Random_Definition"); root.add_child(room)
	var demo=load("res://algorithms/randomness/seed_replay/seed_replay_demo.tscn").instantiate()
	var config={"comparison":"seed_witness","display":"wall","surface":"glass","mapping_study":"true","stand":"table","side":4,"seed":435,"atmosphere":"true","recorded_atmosphere":"true","controls":"compact","control_front":1.0}
	demo.apply_grid_config(config)
	room.add_child(demo)
	var stage=load("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
	stage.install(demo,config)
	var floor_root:=Node3D.new(); root.add_child(floor_root)
	stage.box(floor_root,Vector3(0,-0.04,0),Vector3(12,0.08,12),Color("465456"))
	await capture("windows")
	demo.toggle_extra_draw()
	await capture("one-draw-later")
	demo.toggle_extra_draw(); demo.cycle_mapping()
	await capture("same-draws-new-mapping")
	demo.reset_mapping()
	camera.position=Vector3(0.25,1.6,4.5)
	camera.look_at(Vector3(0.25,2.65,0)); camera.fov=66
	await capture("standing")
	camera.position=Vector3(2.7,1.7,4.5)
	camera.look_at(Vector3(0.16,2.65,0)); camera.fov=63
	await capture("one-body")
	camera.position=Vector3(0.16,1.15,2.0)
	camera.look_at(Vector3(0.16,0.65,0)); camera.fov=83
	await capture("controls")
	print("SEED WINDOW RENDER COMPLETE")
	quit()
