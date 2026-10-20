extends "res://tools/probes/void_trial_probe.gd"
## The complete source lesson, carried construction and both real shaft drops.

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
		if arg=="--capture": take_photos=true
	check("isolated save data",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	check_default_pad()
	var museum_score: int=root.get_node("GameManager").player_score
	for mode in ([true] if take_photos else [false,true]):
		await visit(mode,museum_score)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Godot, actual physics and desktop/synthetic XR movement. Mobile screenshots. Physical headset not tested."},"\t"))
	quit(0 if failed.is_empty() else 1)

func visit(mode: bool,museum_score: int) -> void:
	await start(mode)
	var tag := "XR: " if mode else "Desktop: "
	var content: Node3D=game.building.content
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)
	check(tag+"all 13 original objects and one carried walkway",content.exhibits.keys().filter(func(key): return str(key).begins_with("1/")).size()==14 and content.data.floors[1].artifacts.size()==14)
	check(tag+"fixed frame and both shafts retained",game.building.spec.width==42 and game.building.spec.shafts.size()==2)
	for floor_index in [0,1]:
		var expected: String = "Shaft A /" if floor_index==0 else "Shaft B /"
		var found := false
		for label in game.building.detail_root(floor_index).find_children("*","Label3D",true,false):
			if label.text.contains(expected):found=true
		check(tag+"floor instructions name the correct landing "+str(floor_index),found)
	for x in [-10,10]:
		for z in [-1,0,1]:
			check(tag+"shaft centre stays open "+str(x)+","+str(z),ray(Vector3(x,-5.8,z),Vector3(x,-6.5,z)).is_empty())
	var walk: Node3D=content.exhibits["1/raised-route"].get_node("Artifact")
	check(tag+"walkway uses the original cube factory",walk.Cube.resource_path=="res://commons/artifacts/primitive_encounters/platform_block.tscn")
	check(tag+"walkway uses the original wedge factory",walk.Wedge.resource_path=="res://commons/artifacts/primitive_encounters/wedge_blocker.tscn")
	check(tag+"24 unit cubes and six ramps remain separate editor parts",walk.recipe.members.size()==30 and walk.part_defaults.size()==33)
	for title in ["EntryWedge2","ExitWedge2"]:
		var ramp: Node3D=walk.get_node(title)
		check(tag+title+" carries original wp collision",ramp.has_node("OriginalWP") and ramp.get_node("OriginalWP").scene_file_path=="res://commons/scenes/mapobjects/walkableprism.tscn")
		for z in [-.8,0,.8]:
			var hit:=ray(ramp.to_global(Vector3(0,2,z)),ramp.to_global(Vector3(0,-.1,z)))
			check(tag+title+" supports its true slope at "+str(z),not hit.is_empty() and absf(ramp.to_local(hit.position).y-(z+1)*.5)<.015)
	var still:Node3D=content.exhibits["1/still"].get_node("Artifact")
	var rise:Node3D=content.exhibits["1/rise"].get_node("Artifact")
	var turn:Node3D=content.exhibits["1/turn"].get_node("Artifact")
	var swell:Node3D=content.exhibits["1/swell"].get_node("Artifact")
	var skin:MeshInstance3D=swell.find_child("CubeBaseMesh",true,false)
	var fixed:Transform3D=still.transform
	var rise_before:Transform3D=rise.transform
	var turn_before:Basis=turn.basis
	var scale_before:Vector3=skin.scale
	await frames(25)
	check(tag+"still stays still",still.transform.is_equal_approx(fixed))
	check(tag+"translation changes only height",absf(rise.position.y-rise_before.origin.y)>.01 and is_equal_approx(rise.position.x,rise_before.origin.x) and is_equal_approx(rise.position.z,rise_before.origin.z) and rise.basis.is_equal_approx(rise_before.basis))
	check(tag+"turn adds orientation without scaling the body",not turn.basis.is_equal_approx(turn_before) and turn.scale.is_equal_approx(Vector3.ONE))
	check(tag+"pulse changes size while keeping equal axis ratios",not skin.scale.is_equal_approx(scale_before) and is_equal_approx(skin.scale.x/scale_before.x,skin.scale.y/scale_before.y) and is_equal_approx(skin.scale.y/scale_before.y,skin.scale.z/scale_before.z))
	check(tag+"same lerp curve and demonstration distinction",rise.motion_curve=="lerp" and swell.motion_curve=="lerp" and still.hold=="collect" and rise.hold=="demo" and turn.hold=="demo" and swell.hold=="demo")
	await photo("motion-comparisons",Vector3(.3,-4.0,6.2),Vector3(.3,-4.8,-2))
	await photo("carried-building",Vector3(17.3,-3.65,8.5),Vector3(16,-4.7,0))
	await photo("two-open-shafts",Vector3(1,-1.4,7.9),Vector3(1,-6.1,0))
	# Fall through A onto the actual marked boards, then walk out onto the slab.
	game.checkpoint=0
	var cushions:int=game.cushioned_landings
	game.place_player(Vector3(-8.3,.06,1.9));await frames(140)
	check(tag+"arrival drop A lands on floor 1 without injury",game.checkpoint==1 and game.deaths==0 and game.cushioned_landings==cushions+1 and game.health.get_health()==100)
	check(tag+"step from A onto the floor",await move_to(Vector3(-6.5,-6,1.9)))
	check(tag+"walk to first cube",await move_to(Vector3(-5,-6,-2)))
	await frames(35)
	check(tag+"real body collects the still cube once",game.trial_session.score==1 and not is_instance_valid(still))
	check(tag+"comparison remains after body contact",await move_to(Vector3(-1.5,-6,-2)) and not rise.has_been_collected)
	for at in [Vector3(2,-6,-.65),Vector3(5.5,-6,-.65),Vector3(6,-6,4.2),Vector3(12.9,-6,4.2),Vector3(12.9,-6,8),Vector3(16,-6,8),Vector3(16,-6,6.6)]:
		check(tag+"walk the bank route "+str(at),await move_to(at))
	for at in [Vector3(16,-5,3),Vector3(16,-5,1),Vector3(16,-5,-1),Vector3(16,-5,-3),Vector3(16,-6,-6.6)]:
		check(tag+"walk both wp joins and the cube platform "+str(at),await move_to(at))
	await frames(30)
	check(tag+"four moving pickups collected; three demonstrations remain",game.trial_session.score==5 and is_instance_valid(rise) and is_instance_valid(turn) and is_instance_valid(swell))
	check(tag+"trial never changes museum score",root.get_node("GameManager").player_score==museum_score)
	await photo("toward-departure",Vector3(16,-3.6,-4.4),Vector3(10,-7,-1))
	game.health.set_health(50)
	game.place_player(Vector3(18.4,-5.94,-4.8));await frames(30)
	check(tag+"original health cross uses shared Void health",game.health.get_health()>50)
	game.health.set_health(100)
	for at in [Vector3(18.4,-6,-8),Vector3(12.9,-6,-8),Vector3(12.9,-6,-3.6),Vector3(11.7,-6,-3.6)]:
		check(tag+"reach B from the finished path "+str(at),await move_to(at))
	cushions=game.cushioned_landings
	check(tag+"walk off B onto the next floor's landing",await move_to(Vector3(11.7,-12,-1.9)))
	check(tag+"departure drop B saves catch floor without injury",game.checkpoint==2 and game.deaths==0 and game.cushioned_landings==cushions+1 and game.health.get_health()==100)
	game.place_player(game.spawn_for(1));await frames(35)
	check(tag+"return keeps collected state",not content.exhibits["1/still"].has_node("Artifact"))
	game.die("Retry trial");await frames(110)
	check(tag+"retry restores the 13 objects and resets trial score",game.checkpoint==1 and game.trial_session.score==0 and content.exhibits.keys().filter(func(key): return str(key).begins_with("1/")).size()==14 and content.exhibits["1/still"].has_node("Artifact") and not game.recovering)
	await photo("arrival-shaft",Vector3(-6.1,-3.8,5),Vector3(-8.7,-6.1,1.6))
	game.queue_free();await frames(15)
	if mode:
		for tracker in [head,left,right]:XRServer.remove_tracker(tracker)

func check_default_pad() -> void:
	# Exercise the shared builder with the unchanged tower spec, without loading
	# fourteen floors of artifacts. The detached construction owns every node.
	var maker:Node3D=load("res://commons/void/architecture.gd").new()
	maker.spec=Source.read_layout()
	maker.timber=StandardMaterial3D.new();maker.pink=StandardMaterial3D.new()
	for i in range(2):
		var floor_node:=Node3D.new();maker.add_child(floor_node);maker.floors.append(floor_node)
	maker._build_corner_pad(1)
	check("normal tower keeps its two B-shaft landing boards",maker.landing_pads.size()==2 and is_equal_approx(maker.landing_pads[0].position.x,11.31) and is_equal_approx(maker.landing_pads[1].position.x,12.09) and is_equal_approx(maker.landing_pads[0].position.z,1.9))
	maker.free()

func photo(filename:String,at:Vector3,target:Vector3) -> void:
	if not take_photos:return
	for layer in game.find_children("*","CanvasLayer",true,false):
		if layer.get_viewport()==game.get_viewport():layer.hide()
	game.status.hide();game.notice_time=-1
	var origin:Node3D=game.get_node("XROrigin3D");origin.hide()
	root.msaa_3d=Viewport.MSAA_4X
	await photograph(filename,at,target)
	origin.show()
