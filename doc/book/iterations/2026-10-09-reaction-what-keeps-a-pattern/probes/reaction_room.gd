extends "res://tools/probes/sampling_room.gd"
func landing_checks()->void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes:=CameraAttributesPractical.new();attributes.exposure_multiplier=.28;camera.attributes=attributes
	var desk=find_scene("/timing_machines/soft_workshop.gd")
	check("Reaction desk binds the existing field",desk!=null and desk.ready_for_input and desk.chapter=="reaction" and desk.model!=null)
	if desk==null:return
	var plan:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"plan.json"));var cell:=Vector2(15,3)
	for room in plan.plans:
		if room.map==map_id:
			for a in room.artifacts:
				if a.token=="soft_workshop_console":cell=Vector2(a.cell[0],a.cell[1])
	map_origin=desk.global_position-hall.global_basis*Vector3(cell.x+.5,0,cell.y+.5)
	observations.desk_cell=[cell.x,cell.y]
	observations.entry_colliders=hits(map_at(Vector3(15.5,.01,1.5)))
	await snapshot("above",map_at(Vector3(15,70,8)),map_at(Vector3(15,0,27)),62)
	await snapshot("entry",map_at(Vector3(15.5,1.65,.2)),map_at(Vector3(12,1.2,9)),65)
	await snapshot("encounter",desk.model.to_global(Vector3(0,2.2,3)),desk.model.to_global(Vector3.ZERO),60)
	var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	if spec.get("baseline",false):completed=true;return
	await full_checks(desk)
	completed=true
func full_checks(desk:Node3D)->void:
	var model=desk.model
	check("Centre arrival is clear",observations.entry_colliders.is_empty())
	var approach:Vector3=desk.to_global(Vector3(0,.01,2.9))
	check("Nearby desk approach has floor and clearance",hits(approach).is_empty() and not floor_at(approach).is_empty())
	check("Installed numerical field is held at 32 square cells",model.resolution==32 and not model.auto_run and not model.is_processing() and model._image.get_width()==32 and model._U.size()==32)
	var seeded:=0
	for row in model._V:
		for v in row:if v==.25:seeded+=1
	check("Actual centre seed is 36 cells, not twelve",seeded==36)
	var screen:MeshInstance3D=model.get_node("ReactionWall/LiveField")
	check("Large wall and original display share the actual live texture",screen.material_override.albedo_texture==model._texture and model._material.albedo_texture==model._texture and screen.mesh.size==Vector2(3.7,3.7))
	var start:Array=model._V.duplicate(true)
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	observations.buttons=[]
	for id in ["STEP","100 STEPS","REGIME","SEEDING","RESET","RULE"]:
		var before:int=desk.step_count
		var result:Dictionary=await driver.press(desk.buttons[id],approach)
		while desk.busy:await tick()
		var effect:=false
		match id:
			"STEP":effect=desk.step_count==before+1 and model._V!=start
			"100 STEPS":effect=desk.step_count==before+100
			"REGIME":effect=model.pattern_type==1 and desk.step_count==0 and is_equal_approx(model.feed,.042) and is_equal_approx(model.kill,.059)
			"SEEDING":effect=model.seeding=="lattice" and desk.step_count==0
			"RESET":effect=desk.step_count==0 and model.seeding=="lattice"
			"RULE":effect=desk.rule_card.visible
		check("Actual pointer operates "+id,effect and str(result.get("hover","")) not in ["","none","null","nothing"])
		observations.buttons.append({"id":id,"effect":effect,"pointer":result})
	await driver.press(desk.buttons.RULE,approach)
	check("Rule annotation can close without changing the field",not desk.rule_card.visible and desk.step_count==0)
	model.apply_grid_config({"seeding":"centre"});await driver.press(desk.buttons.RESET,approach)
	for i in 10:
		await driver.press(desk.buttons["100 STEPS"],approach)
		while desk.busy:await tick()
	check("Ten actual batches reach 1000 displayed steps",desk.step_count==1000 and model._V!=start)
	await snapshot("wall-1000",model.to_global(Vector3(0,2,6)),model.to_global(Vector3(0,1.7,-1.5)),57)
	await snapshot("desk",desk.to_global(Vector3(0,1.7,3)),desk.to_global(Vector3(0,1.2,0)),55)
	observations.wall_state={"steps":desk.step_count,"regime":model.pattern_type,"feed":model.feed,"kill":model.kill,"seeding":model.seeding}
	var kept:Array=model._V.duplicate(true);await create_timer(.4).timeout
	check("Idle museum time does not advance a held field",model._V==kept and desk.step_count==1000)
	check("Wall texture remains connected after all controls",screen.material_override.albedo_texture==model._texture)
	await driver.teardown();driver.queue_free();await tick()
	var study=load("res://doc/book/iterations/2026-10-09-reaction-what-keeps-a-pattern/printed/reaction.gd").new()
	study.transform=Transform3D(desk.global_basis,map_at(Vector3(15,0,18)));root.add_child(study);await tick();await tick()
	var stand:Vector3=study.to_global(Vector3(0,.01,2.5))
	check("Learner comparison has a clear supported approach",hits(stand).is_empty() and not floor_at(stand).is_empty())
	study.advance(1);var w:int=study.left.index(15,15)
	check("Exact printed model produces local prediction inside museum",is_equal_approx(study.left.u[w],.48725) and is_equal_approx(study.left.v[w],.257) and study.right.v[w]==.25)
	await snapshot("student-one-step",study.to_global(Vector3(0,2.25,3.7)),study.to_global(Vector3(0,1.85,0)),58)
	study.advance(999)
	check("Equal-step comparison separates complete rule and exchange alone",study.left.ticks==1000 and study.right.ticks==1000 and study.left.v!=study.right.v)
	await snapshot("student-1000",study.to_global(Vector3(0,2.25,3.7)),study.to_global(Vector3(0,1.85,0)),58)
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.point.global_position
	study.point.pick_up(pickup);for i in 3:await tick()
	hand.global_position=study.to_global(Vector3(-.85+(5.5-16)*.04,1.06,.5+(7.5-16)*.04));for i in 5:await tick()
	check("Carried point selects an address in the real hall",study.point.held() and study.target_site()==Vector2i(5,7))
	study.point.action();await tick()
	check("Museum XR trigger seeds both fields at unchanged time",study.injections==1 and study.left.v[study.left.index(5,7)]==.25 and study.right.v[study.right.index(5,7)]==.25 and study.left.ticks==1000)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);for i in 3:await tick()
	check("Released point parks without another seed",not study.point.held() and study.injections==1 and study.point.position.is_equal_approx(Vector3(0,1.12,-.35)))
	study.change_local_terms();study.advance(1000)
	check("Matching rules restore identical 1000-step fields",study.left.v==study.right.v and study.left.u==study.right.u)
	await snapshot("student-matched",study.to_global(Vector3(0,2.25,3.7)),study.to_global(Vector3(0,1.85,0)),58)
	await snapshot("with-learner-above",map_at(Vector3(15,70,8)),map_at(Vector3(15,0,27)),62)
	study.queue_free();origin.queue_free();await tick()
	var edited=load("res://doc/book/iterations/2026-10-09-reaction-what-keeps-a-pattern/variation/reaction.gd").new()
	edited.transform=Transform3D(desk.global_basis,map_at(Vector3(15,0,18)));root.add_child(edited);await tick();edited.advance(1);w=edited.left.index(15,15)
	check("Complete feed edit produces predicted first step in museum",is_equal_approx(edited.left.u[w],.49375) and is_equal_approx(edited.left.v[w],.25375) and edited.right.v[w]==.25)
	edited.advance(999);await snapshot("student-feed-edit",edited.to_global(Vector3(0,2.25,3.7)),edited.to_global(Vector3(0,1.85,0)),58)
	edited.queue_free();await tick()
	var route:=[Vector3(15.5,0,.5),Vector3(15.5,0,4.5),Vector3(27,0,4.5),Vector3(27,0,60),Vector3(15.5,0,60),Vector3(15.5,0,62.5)]
	var blocked:Array=[];var gaps:Array=[];var samples:=0
	for j in range(route.size()-1):
		var a:Vector3=route[j];var b:Vector3=route[j+1];var steps:=ceili(a.distance_to(b)/.25)
		for k in steps+1:
			var p:Vector3=a.lerp(b,float(k)/steps);var at:=map_at(p+Vector3.UP*.01);samples+=1
			if not hits(at).is_empty():blocked.append({"at":xyz(p),"colliders":hits(at)})
			if floor_at(at).is_empty():gaps.append(xyz(p))
	observations.route={"samples":samples,"blocked":blocked,"gaps":gaps}
	check("Outer route has capsule clearance",blocked.is_empty())
	check("Outer route has continuous support",gaps.is_empty())
	observations.learner={"placement":[15,0,18],"yaw":180,"temporary":true,"headset":false}
	observations.scope="Actual museum and pointer; synthetic XRTools. Exact printed learner, independent feed edit. No headset, Quest performance or independent student claim."
