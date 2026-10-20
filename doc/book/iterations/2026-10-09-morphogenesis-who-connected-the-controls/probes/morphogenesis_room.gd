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
	check("Morphogenesis desk binds the existing surface",desk!=null and desk.ready_for_input and desk.chapter=="morphogenesis" and desk.model!=null)
	if desk==null:return
	var plan:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"plan.json"));var cell:=Vector2(15,3)
	for room in plan.plans:
		if room.map==map_id:
			for a in room.artifacts:
				if a.token=="soft_workshop_console":cell=Vector2(a.cell[0],a.cell[1])
	map_origin=desk.global_position-hall.global_basis*Vector3(cell.x+.5,0,cell.y+.5)
	observations.desk_cell=[cell.x,cell.y]
	observations.entry_colliders=hits(map_at(Vector3(15.5,.01,1.5)))
	await snapshot("above",map_at(Vector3(15,58,8)),map_at(Vector3(15,0,23)),62)
	await snapshot("entry",map_at(Vector3(15.5,1.65,.2)),map_at(Vector3(12,1.2,9)),65)
	await snapshot("encounter",desk.model.to_global(Vector3(8,5,10)),desk.model.to_global(Vector3.ZERO),58)
	var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	if spec.get("baseline",false):completed=true;return
	await full_checks(desk)
	completed=true
func mesh_vertices(g)->PackedVector3Array:return g.gyroid_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
func full_checks(desk:Node3D)->void:
	var model=desk.model
	observations.opening={"S":model.S,"frequency":model.current_frequency,"noise":model.current_noise_amp,"threshold":model.current_threshold,"box":xyz(model.box_size),"resolution":str(model.voxel_resolution),"mesh_bounds":str(model.gyroid_mesh.mesh.get_aabb()),"seed":model.gyroid_generator.noise.seed}
	check("Arrival has capsule clearance",observations.entry_colliders.is_empty())
	var approach:Vector3=desk.to_global(Vector3(0,.01,2.9))
	check("Relocated desk has a clear supported approach",hits(approach).is_empty() and not floor_at(approach).is_empty())
	check("Installed surface uses fixed seed and collision",model.gyroid_generator.noise.seed==1337 and model.collision_body!=null)
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	observations.buttons=[]
	for id in ["S","LEVEL","NOISE","RESOLUTION","RESET","RULE"]:
		var prior:int=model.gyroid_mesh.mesh.get_instance_id()
		var result:Dictionary=await driver.press(desk.buttons[id],approach);while desk.busy:await tick()
		var effect:=false
		match id:
			"S":effect=is_zero_approx(model.S) and is_equal_approx(model.current_frequency,.9) and is_equal_approx(model.current_noise_amp,.05) and is_equal_approx(model.current_threshold,-.15)
			"LEVEL":effect=model.level=="thickened" and is_equal_approx(model.current_threshold,-.75)
			"NOISE":effect=is_zero_approx(model.current_noise_amp) and is_equal_approx(model.current_threshold,-.75)
			"RESOLUTION":effect=model.voxel_resolution==Vector3i(16,16,16)
			"RESET":effect=is_equal_approx(model.S,.3) and is_equal_approx(model.current_frequency,1.11) and is_equal_approx(model.current_noise_amp,.095) and is_equal_approx(model.current_threshold,-.06) and model.voxel_resolution==Vector3i(24,24,24)
			"RULE":effect=desk.rule_card.visible
		check("Actual pointer operates "+id,effect and str(result.get("hover","")) not in ["","none","null","nothing"])
		if id!="RULE":check(id+" rebuilds mesh with current collision",prior!=model.gyroid_mesh.mesh.get_instance_id() and model.collision_body.get_child(0).shape.get_faces().size()>0)
		observations.buttons.append({"id":id,"effect":effect,"pointer":result})
	await driver.press(desk.buttons.RULE,approach)
	await snapshot("desk",desk.to_global(Vector3(0,1.8,3.3)),desk.to_global(Vector3(0,1.2,-1)),58)
	await driver.teardown();driver.queue_free();await tick()
	var kept:PackedVector3Array=mesh_vertices(model.gyroid_generator).duplicate()
	await create_timer(.4).timeout
	check("Waiting does not simulate surface growth",mesh_vertices(model.gyroid_generator)==kept)
	model.set_entropy(1);model.regenerate_now();await tick()
	check("Master endpoint gives declared parameter triple",is_equal_approx(model.current_frequency,1.6) and is_equal_approx(model.current_noise_amp,.2) and is_equal_approx(model.current_threshold,.15))
	await snapshot("large-at-one",model.to_global(Vector3(8,5,10)),model.to_global(Vector3.ZERO),58)
	model.set_entropy(.3);model.regenerate_now();await tick()
	check("Returning parameters restores exact sampled geometry",mesh_vertices(model.gyroid_generator)==kept)
	var study=load("res://doc/book/iterations/2026-10-09-morphogenesis-who-connected-the-controls/printed/recipe.gd").new()
	study.transform=Transform3D(desk.global_basis,map_at(Vector3(15,0,27)));root.add_child(study);await tick();await tick()
	check("Temporary learner has supported clear viewing position",hits(study.to_global(Vector3(0,.01,4))).is_empty() and not floor_at(study.to_global(Vector3(0,.01,4))).is_empty())
	var fixed:PackedVector3Array=mesh_vertices(study.generators[0]).duplicate()
	check("Printed comparison begins with identical meshes",fixed==mesh_vertices(study.generators[1]))
	await snapshot("student-matched",study.to_global(Vector3(0,2.7,5.7)),study.to_global(Vector3(0,1.9,0)),58)
	for mode in [1,2,3,0]:
		study.mode=mode;study.preview=1;study.apply_preview();await tick()
		check("Museum learner commits "+study.MODES[mode],study.committed==1 and study.built_mode==mode and mesh_vertices(study.generators[0])==fixed)
		await snapshot("student-"+study.MODES[mode].to_lower(),study.to_global(Vector3(0,2.7,5.7)),study.to_global(Vector3(0,1.9,0)),58)
	study.reset();await tick()
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.point.global_position
	study.point.pick_up(pickup);for i in 3:await tick()
	var previous:int=study.generators[1].gyroid_mesh.mesh.get_instance_id()
	hand.global_position=study.to_global(Vector3(0,1.6,1.35));for i in 5:await tick()
	check("Held sphere previews in actual hall without rebuilding",study.point.held() and is_equal_approx(study.preview,1) and previous==study.generators[1].gyroid_mesh.mesh.get_instance_id())
	study.point.action();await tick()
	check("XR trigger builds proposed recipe in museum",study.committed==1 and previous!=study.generators[1].gyroid_mesh.mesh.get_instance_id())
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);for i in 3:await tick()
	check("Release preserves committed recipe",not study.point.held() and study.committed==1)
	await snapshot("with-learner-above",map_at(Vector3(15,58,8)),map_at(Vector3(15,0,23)),62)
	study.queue_free();origin.queue_free();await tick()
	var edited=load("res://doc/book/iterations/2026-10-09-morphogenesis-who-connected-the-controls/variation/recipe.gd").new();edited.transform=Transform3D(desk.global_basis,map_at(Vector3(15,0,27)));root.add_child(edited);await tick()
	edited.preview=1;edited.mode=3;edited.apply_preview();await tick()
	check("Independent span edit runs in actual museum",is_equal_approx(edited.generators[0].threshold,-.12) and is_equal_approx(edited.generators[1].threshold,.3) and is_equal_approx(edited.generators[1].frequency,1.11))
	await snapshot("student-span-edit",edited.to_global(Vector3(0,2.7,5.7)),edited.to_global(Vector3(0,1.9,0)),58)
	edited.queue_free();await tick()
	var route:=[Vector3(15.5,0,.5),Vector3(15.5,0,4.5),Vector3(26,0,4.5),Vector3(26,0,45),Vector3(15.5,0,45),Vector3(15.5,0,46.5)]
	var blocked:Array=[];var gaps:Array=[];var samples:=0
	for j in range(route.size()-1):
		var a:Vector3=route[j];var b:Vector3=route[j+1];var steps:=ceili(a.distance_to(b)/.25)
		for k in steps+1:
			var p:Vector3=a.lerp(b,float(k)/steps);var at:=map_at(p+Vector3.UP*.01);samples+=1
			if not hits(at).is_empty():blocked.append({"at":xyz(p),"colliders":hits(at)})
			if floor_at(at).is_empty():gaps.append(xyz(p))
	observations.route={"samples":samples,"blocked":blocked,"gaps":gaps}
	check("Outer route retains capsule clearance",blocked.is_empty())
	check("Outer route retains continuous floor",gaps.is_empty())
	observations.scope="Real museum and actual pointer; exact printed learner and independent edit; synthetic XRTools. No headset/Quest/human understanding or passage through gyroid claim."
