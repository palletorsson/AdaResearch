extends "res://tools/probes/transformation_encounters.gd"
var map_origin:Vector3
var completed:=false
func finish()->void:
	check("All planned checks completed",completed)
	super.finish()
func map_at(p:Vector3)->Vector3:return map_origin+hall.global_basis*p
func hits(at:Vector3)->Array:
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7
	var q:=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.transform.origin=at+Vector3.UP*.88;q.collision_mask=1|4
	var walker=museum.get("_player")
	if walker is CollisionObject3D:q.exclude=[walker.get_rid()]
	var out:Array=[]
	for h in hall.get_world_3d().direct_space_state.intersect_shape(q):out.append(str(h.collider.get_path()))
	return out
func landing_checks()->void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes:=CameraAttributesPractical.new();attributes.exposure_multiplier=.28;camera.attributes=attributes
	var desk=find_scene("/timing_machines/soft_workshop.gd")
	check("Sampling desk binds existing body and frozen vessel",desk!=null and desk.ready_for_input and desk.chapter=="sampling" and desk.model!=null and desk.other!=null)
	if desk==null:return
	var plan:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"plan.json"));var cell:=Vector2(15,3)
	for room in plan.plans:
		if room.map==map_id:
			for a in room.artifacts:
				if a.token=="soft_workshop_console":cell=Vector2(a.cell[0],a.cell[1])
	map_origin=desk.global_position-hall.global_basis*Vector3(cell.x+.5,0,cell.y+.5)
	observations.desk_cell=[cell.x,cell.y]
	observations.entry_colliders=hits(map_at(Vector3(15.5,.01,1.5)))
	await snapshot("above",map_at(Vector3(15,54,8)),map_at(Vector3(15,0,18)),62)
	await snapshot("entry",map_at(Vector3(15.5,1.65,.2)),map_at(Vector3(15.5,1.3,9)),65)
	await snapshot("encounter",map_at(Vector3(15,4,5)),map_at(Vector3(15,1.3,12)),68)
	await snapshot("vessel",desk.other.to_global(Vector3(2.5,2.2,3)),desk.other.to_global(Vector3(0,1.2,0)),50)
	var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	if spec.get("baseline",false):completed=true;return
	check("Centre arrival is clear",observations.entry_colliders.is_empty())
	var approach:Vector3=desk.to_global(Vector3(0,.01,2.9))
	check("Desk approach has floor and capsule clearance",hits(approach).is_empty() and not floor_at(approach).is_empty())
	var model=desk.model;var vessel=desk.other
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	observations.buttons=[]
	for id in ["MEASURE","FEEDBACK","SQUEEZE","STIFFNESS","DURATION","GRAVITY","RULE"]:
		var mode:String=model.measure;var feedback:bool=model.volume_feedback;var old_mesh:int=vessel._mi.mesh.get_instance_id()
		var result:Dictionary=await driver.press(desk.buttons[id],approach);await create_timer(.1).timeout;var effect:=false
		match id:
			"MEASURE":effect=model.measure!=mode and model.volume_feedback==feedback
			"FEEDBACK":effect=model.volume_feedback!=feedback and model.measure==mode
			"SQUEEZE":effect=is_equal_approx(model._squeeze_strength,1.0)
			"STIFFNESS":effect=is_equal_approx(model._stiffness,.1)
			"DURATION":effect=vessel.sim_steps==40 and vessel._mi.mesh.get_instance_id()!=old_mesh
			"GRAVITY":effect=is_equal_approx(vessel.gravity_x,2.0) and vessel._mi.mesh.get_instance_id()!=old_mesh
			"RULE":effect=desk.rule_card.visible
		check("Actual desktop pointer operates "+id,effect and str(result.get("hover","")) not in ["","none","null","nothing"])
		observations.buttons.append({"id":id,"effect":effect,"pointer":result})
	await snapshot("desk",desk.to_global(Vector3(0,1.7,3)),desk.to_global(Vector3(0,1.2,0)),55)
	await driver.teardown();driver.queue_free();await tick()
	check("Installed glass rebuild retains one collision skin",vessel._mi.get_node_or_null("FrozenSkin/Surface")!=null and vessel.get_child_count()==2)
	model.set_volume_feedback(false);vessel.apply_grid_config({"sim_steps":200,"gravity_x":0.0})
	var study=load("res://doc/book/iterations/2026-10-09-sampling-a-shape-kept/printed/study.gd").new()
	study.transform=Transform3D(desk.global_basis,map_at(Vector3(15,0,14)));root.add_child(study)
	var stand:Vector3=study.to_global(Vector3(0,.01,3))
	check("Learner comparison has a clear supported approach",hits(stand).is_empty() and not floor_at(stand).is_empty())
	for i in 65:await tick()
	check("Printed snapshot runs inside the museum",study.saved_step==40 and study.kept.mesh!=null and study.step_count>40)
	var kept:PackedVector3Array=study.saved_positions.duplicate()
	await snapshot("student-comparison",study.to_global(Vector3(3.2,2.4,4.6)),study.to_global(Vector3(0,1.75,0)),53)
	check("Museum snapshot stays while live solver advances",study.saved_positions==kept and study.surface.sim.positions!=kept)
	observations.learner={"saved_step":study.saved_step,"live_step":study.step_count,"position":[15,0,14],"placement":"Temporary tutorial host in the actual hall; unit scale and yaw180."}
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.point.global_position
	study.point.pick_up(pickup);await tick();hand.global_position+=Vector3(.3,.3,0);await tick();study.point.action();await tick()
	check("Inherited PointBody captures through XRTools action",study.point.is_picked_up() and study.saved_step>40)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick()
	await snapshot("student-recapture",study.to_global(Vector3(3.2,2.4,4.6)),study.to_global(Vector3(0,1.75,0)),53)
	await snapshot("with-learner-above",map_at(Vector3(15,54,8)),map_at(Vector3(15,0,18)),62)
	study.queue_free();origin.queue_free();await tick()
	var edited=load("res://doc/book/iterations/2026-10-09-sampling-a-shape-kept/variation/study.gd").new()
	edited.transform=Transform3D(desk.global_basis,map_at(Vector3(15,0,14)));root.add_child(edited)
	for i in 215:await tick()
	check("Independent step-200 edit also runs in the museum",edited.saved_step==200 and edited.kept.mesh!=null)
	await snapshot("student-step200",edited.to_global(Vector3(3.2,2.4,4.6)),edited.to_global(Vector3(0,1.75,0)),53)
	edited.queue_free();await tick()
	var route:=[Vector3(15.5,0,.5),Vector3(15.5,0,4.5),Vector3(27,0,4.5),Vector3(27,0,46.5),Vector3(15.5,0,46.5),Vector3(15.5,0,47.5)]
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
	observations.scope="Actual museum and desktop pointer; synthetic XRTools. Temporary exact learner program; no physical headset or independent learner."
	completed=true
