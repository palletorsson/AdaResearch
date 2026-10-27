extends "res://tools/probes/transformation_walkability.gd"
## Follow-up only: wedge joins and bank access changed after the full trials.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	Source.use_main_tower=true
	scene=Node3D.new();root.add_child(scene);current_scene=scene
	building=load("res://commons/void/architecture.gd").new();building.stream_content=true;scene.add_child(building)
	building.content.load_floor(16)
	var shown:Array[int]=[16];building.show_floor_window(shown)
	root.size=Vector2i(1440,900)
	var env:=WorldEnvironment.new();env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("20252d")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("d7dfef");env.environment.ambient_light_energy=.4
	env.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	scene.add_child(env)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-55,-35,0);light.light_energy=1;light.shadow_enabled=true;scene.add_child(light)
	lens=Camera3D.new();lens.fov=80;lens.far=90;scene.add_child(lens);lens.current=true
	await frames(45)
	var y:float=building.spec.levels[16]
	var body:=visitor(Vector3(-13.4,y+.03,-7.5))
	var crossed:bool=await walk(body,Vector3(-6.5,y+3,-7.5),8)
	check("real body climbs all three joined original wedges",crossed and absf(body.global_position.y-y-3)<.1)
	observations.climb_position=[body.global_position.x,body.global_position.y-y,body.global_position.z]
	body.queue_free();await frames(2)
	body=visitor(Vector3(6.5,y+3.03,7.5))
	crossed=await walk(body,Vector3(13.4,y,7.5),8)
	check("real body descends the finish bank without a jump",crossed and absf(body.global_position.y-y)<.1)
	body.queue_free();await frames(2)
	var hinge:Node3D=exhibit(16,"hinge")
	var hinge_boxes:Array=[];geometry(hinge,hinge_boxes)
	var bounds:AABB=hinge_boxes[0]
	for box in hinge_boxes:bounds=bounds.merge(box)
	check("hinge remains inside the standard floor",bounds.end.x<21 and bounds.position.x> -21)
	for band in exhibit(16,"angle-bands").bands:
		for cube in band.cubes:
			var world_bounds:AABB=cube.global_transform*mesh_bounds(cube)
			var top:float=world_bounds.end.y-y
			check(str(band.id)+" body headroom at "+str(cube.get_meta("row")),top+1.6<5.64)
	lens.global_position=Vector3(-6.4,y+4.65,.2);lens.look_at(Vector3(5,y+2.8,0))
	await frames(3);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("07-rotation-walking-clear.png"))
	FileAccess.open(out.path_join("access.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"observations":observations,"scope":"Targeted follow-up: actual capsule climb/descent, hinge perimeter, and headroom after the access joins changed. The unchanged main walkability/proximity trials are in native.json."},"  "))
	print("TRANSFORMATION_ACCESS ",failed)
	building.queue_free();await frames(2);quit(0 if failed.is_empty() else 1)
