extends "res://tools/probes/void_transfer_probe.gd"
## Real floor15 integration: original construction, contact and source geometry.
var building:Node3D
var lens:Camera3D
var observations:Dictionary={}

func piece(id:String) -> Node3D:return building.content.exhibits["15/machine-"+id].get_node("Artifact")

func photo_machine(name:String,at:Vector3,target:Vector3) -> void:
	var y:float=building.spec.levels[15]
	lens.global_position=at+Vector3.UP*y;lens.look_at(target+Vector3.UP*y)
	await frames(3);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name+".png"))

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	Source.use_main_tower=true
	var scene:=Node3D.new();root.add_child(scene);current_scene=scene
	building=load("res://commons/void/architecture.gd").new();building.stream_content=true;scene.add_child(building)
	building.content.load_floor(15)
	var shown:Array[int]=[15];building.show_floor_window(shown)
	root.size=Vector2i(1440,900)
	var env:=WorldEnvironment.new();env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("242b33")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("d9e1ef");env.environment.ambient_light_energy=.5;env.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC;scene.add_child(env)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-40,-25,0);light.light_energy=1.1;light.shadow_enabled=true;scene.add_child(light)
	lens=Camera3D.new();lens.fov=75;lens.far=100;lens.current=true;scene.add_child(lens)
	await frames(60)
	check("original 348 painted construction cells remain",building.content.data.floors[15].construction.size()==348)
	check("both original and mirrored moving carriers remain",building.content.roots[15].get_node("Construction").carriers.size()==2)
	for id in ["crank","lever","suspended","sorter"]:
		var node:Node3D=piece(id);var boxes:Array=[];geometry(node,boxes)
		var bounds:AABB=boxes[0]
		for box in boxes:bounds=bounds.merge(box)
		check(id+" has real native geometry",not boxes.is_empty())
		check(id+" fits the ceiling brackets",bounds.end.y-building.spec.levels[15]<5.65)
		check(id+" occupies the central bay away from both shafts",bounds.position.x> -6.8 and bounds.end.x<6.8)
		observations[id]={"min":[bounds.position.x,bounds.position.y-building.spec.levels[15],bounds.position.z],"max":[bounds.end.x,bounds.end.y-building.spec.levels[15],bounds.end.z]}
	var crank:Node3D=piece("crank");var sorter:Node3D=piece("sorter")
	await photo_machine("01-suspended-workshop",Vector3(0,1.7,-8.3),Vector3(0,2.4,-2.8))
	await photo_machine("02-crank-and-piston",Vector3(-3.4,2.05,-7.1),Vector3(-3.6,2.65,-4.5))
	await photo_machine("03-rope-and-cube",Vector3(2.2,1.7,-2.2),Vector3(0,2.8,-.5))
	crank.action("MOTOR / PAUSE");sorter.action("RELEASE")
	var low:=INF;var high:=-INF
	for i in range(540):
		await frames(1)
		low=minf(low,crank.members.piston.position.x);high=maxf(high,crank.members.piston.position.x)
	check("crank has its physical stroke in the real tower",high-low>1)
	check("crank contact delivers the ball in the real tower",crank.outputs.get("delivered",false))
	check("all three gravity exits work in the real tower",sorter.drops.size()==3)
	observations.gravity_exits=sorter.drops.duplicate(true)
	await photo_machine("04-size-gravity-sorter",Vector3(3.4,1.7,-8),Vector3(3.5,2.6,-4.2))
	await photo_machine("05-working-lever",Vector3(2.2,1.7,.6),Vector3(0,1.3,2.2))
	FileAccess.open(out.path_join("floor.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"observations":observations,"scope":"Actual main floor15: preserved construction/carriers, machine bounds and natural contact/gravity effects. Native inspection lighting; physical headset and complete player-input playthrough not tested."},"  "))
	print("TRANSFORMATION_MACHINES_FLOOR ",failed)
	building.queue_free();await frames(2);quit(0 if failed.is_empty() else 1)
