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
	check("Affect desk binds radiolaria",desk!=null and desk.ready_for_input and desk.chapter=="affect" and desk.model!=null)
	if desk==null:return
	var plan:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"plan.json"));var cell:=Vector2(15,3)
	for room in plan.plans:
		if room.map==map_id:
			for a in room.artifacts:
				if a.token=="soft_workshop_console":cell=Vector2(a.cell[0],a.cell[1])
	map_origin=desk.global_position-hall.global_basis*Vector3(cell.x+.5,0,cell.y+.5)
	observations.desk_cell=[cell.x,cell.y]
	observations.entry_colliders=hits(map_at(Vector3(15.5,.01,1.5)))
	var model=desk.model
	observations.forms=model.get_node("BiologicalForms").get_child_count()
	await snapshot("above",map_at(Vector3(15,50,7)),map_at(Vector3(15,0,18)),62)
	await snapshot("entry",map_at(Vector3(15.5,1.65,.2)),map_at(Vector3(11,1.2,11)),65)
	await snapshot("encounter",model.to_global(Vector3(7,4,7)),model.to_global(Vector3(0,1,0)),65)
	var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	if spec.get("baseline",false):completed=true;return
	await full_checks(desk)
	completed=true
func construction(node:Node,root_form:bool=false)->Array:
	var out:Array=[node.get_class()]
	if node is Node3D:
		out.append(node.position if root_form else node.transform)
	for p in node.get_property_list():
		if p.name in ["radius","height","inner_radius","outer_radius","sides","rings","ring_sides","radial_segments","size","operation","cone","smooth_faces","use_collision"]:out.append([p.name,node.get(p.name)])
	for child in node.get_children():out.append(construction(child,node.name=="BiologicalForms"))
	return out
func full_checks(desk:Node3D)->void:
	var model=desk.model
	check("Centre arrival is clear",observations.entry_colliders.is_empty())
	var approach:Vector3=desk.to_global(Vector3(0,.01,2.9))
	check("Desk approach has floor and capsule clearance",hits(approach).is_empty() and not floor_at(approach).is_empty())
	check("Court starts with nine forms and a fixed seed",observations.forms==9 and model.generation_seed==1337 and is_equal_approx(model.spacing,4.0))
	var stage:Node3D=model.get_node("SpecimenCourt")
	check("Nine solid plinths support the display court",stage.find_children("*","StaticBody3D",true,false).size()==9)
	var forms:Node3D=model.get_node("BiologicalForms")
	var all_above:=true;var contact_free:=true
	for form:Node3D in forms.get_children():
		all_above=all_above and form.global_position.y>map_origin.y+2.0
	for n in forms.find_children("*","CSGShape3D",true,false):contact_free=contact_free and not n.use_collision
	check("Specimen centres are raised above the floor",all_above)
	check("Generated visible skins retain their non-contact character",contact_free)
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	observations.buttons=[]
	for id in ["ROTATION","COLOUR","EFFECTS","SEED","SPIKES","RULE"]:
		var turning:bool=model.enable_rotation;var palette:bool=model.use_realistic_colors;var effects:bool=model.show_particle_effects
		var old_construction:Array=construction(model.get_node("BiologicalForms"))
		var result:Dictionary=await driver.press(desk.buttons[id],approach);await create_timer(.3).timeout;var effect:=false
		match id:
			"ROTATION":effect=model.enable_rotation!=turning
			"COLOUR":effect=model.use_realistic_colors!=palette
			"EFFECTS":effect=model.show_particle_effects!=effects
			"SEED":effect=model.generation_seed==1338 and construction(model.get_node("BiologicalForms"))!=old_construction
			"SPIKES":effect=is_zero_approx(model.spikiness_probability)
			"RULE":effect=desk.rule_card.visible
		check("Actual desktop pointer operates "+id,effect and str(result.get("hover","")) not in ["","none","null","nothing"])
		if id=="ROTATION":
			var pose:Basis=model.get_node("BiologicalForms").get_child(0).basis
			await create_timer(.3).timeout
			check("ROTATION off stops actual specimen motion",pose.is_equal_approx(model.get_node("BiologicalForms").get_child(0).basis))
		if id=="COLOUR":check("Fixed-seed palette comparison preserves construction properties",old_construction==construction(model.get_node("BiologicalForms")))
		observations.buttons.append({"id":id,"effect":effect,"pointer":result})
	await snapshot("desk",desk.to_global(Vector3(0,1.7,3)),desk.to_global(Vector3(0,1.2,0)),55)
	await driver.press(desk.buttons.ROTATION,approach);await create_timer(.1).timeout
	var pose:Basis=model.get_node("BiologicalForms").get_child(0).basis
	await create_timer(.3).timeout
	check("ROTATION on turns a specimen seen by the museum camera",model.enable_rotation and not pose.is_equal_approx(model.get_node("BiologicalForms").get_child(0).basis))
	await driver.teardown();driver.queue_free();await tick()
	model.generation_seed=1337;model.spikiness_probability=.7;model.use_realistic_colors=true;model.enable_rotation=false
	model.create_enhanced_materials();model.regenerate_forms();await create_timer(.5).timeout
	await snapshot("court",map_at(Vector3(23,3.7,10)),model.global_position,62)
	var study=load("res://doc/book/iterations/2026-10-09-affect-one-cue/printed/study.gd").new()
	study.transform=Transform3D(desk.global_basis,map_at(Vector3(18,0,33)));root.add_child(study)
	var stand:Vector3=study.to_global(Vector3(0,.01,3))
	check("Learner comparison has a clear supported approach",hits(stand).is_empty() and not floor_at(stand).is_empty())
	await tick();study.set_process(false)
	var kept:PackedVector3Array=study.saved_positions.duplicate()
	check("Exact printed host initializes inside the museum",kept.size()==330 and study.left.mesh==study.right.mesh and study.condition==0)
	await snapshot("student-baseline",study.to_global(Vector3(0,2.6,5.8)),study.to_global(Vector3(0,2,0)),52)
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.point.global_position
	study.point.pick_up(pickup);await tick();study.point.action();await tick();study._process(1)
	check("Inherited XRTools point selects motion while shape stays saved",study.point.held() and study.condition==1 and is_equal_approx(study.right.rotation.z,.7) and study.surface.sim.positions==kept)
	await snapshot("student-turn",study.to_global(Vector3(0,2.6,5.8)),study.to_global(Vector3(0,2,0)),52)
	study.point.action();await tick()
	check("Second trigger isolates colour and clears rotation",study.condition==2 and study.right.rotation==Vector3.ZERO and study.left.material_override.albedo_color!=study.right.material_override.albedo_color)
	await snapshot("student-colour",study.to_global(Vector3(0,2.6,5.8)),study.to_global(Vector3(0,2,0)),52)
	study.point.action();await tick();study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick()
	check("Third trigger and release restore a fixed baseline",study.condition==0 and not study.point.held() and study.surface.sim.positions==kept)
	await snapshot("with-learner-above",map_at(Vector3(15,50,7)),map_at(Vector3(15,0,18)),62)
	study.queue_free();origin.queue_free();await tick()
	var edited=load("res://doc/book/iterations/2026-10-09-affect-one-cue/variation/study.gd").new()
	edited.transform=Transform3D(desk.global_basis,map_at(Vector3(18,0,33)));root.add_child(edited);edited.set_process(false);edited.set_condition(1);edited._process(1)
	check("Independent half-speed edit runs in the museum",is_equal_approx(edited.right.rotation.z,.35) and edited.saved_positions==kept)
	await snapshot("student-half-speed",edited.to_global(Vector3(0,2.6,5.8)),edited.to_global(Vector3(0,2,0)),52)
	edited.queue_free();await tick()
	var route:=[Vector3(15.5,0,.5),Vector3(15.5,0,4.5),Vector3(27,0,4.5),Vector3(27,0,41),Vector3(15.5,0,41),Vector3(15.5,0,43.5)]
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
	observations.learner={"placement":[18,0,33],"yaw":180,"temporary":true,"headset":false}
	observations.scope="Native museum, desktop pointer, synthetic XRTools. Exact printed learner program, independent edit. No physical headset or claim about felt aliveness."
