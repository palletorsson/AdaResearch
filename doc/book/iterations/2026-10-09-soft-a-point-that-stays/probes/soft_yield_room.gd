extends "res://tools/probes/transformation_encounters.gd"
const DIR := "res://doc/book/iterations/2026-10-09-soft-a-point-that-stays/"
var map_origin:Vector3
func map_at(p:Vector3)->Vector3:return map_origin+hall.global_basis*p
func clear_body(at:Vector3)->bool:
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform.origin=at+Vector3.UP*.88;query.collision_mask=1|4
	return hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
func hit_names(at:Vector3)->Array:
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform.origin=at+Vector3.UP*.88;query.collision_mask=1|4
	var hits:Array=[]
	for hit in hall.get_world_3d().direct_space_state.intersect_shape(query):hits.append(str(hit.collider.get_path()))
	return hits
func landing_checks()->void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes:=CameraAttributesPractical.new();attributes.exposure_multiplier=.45;camera.attributes=attributes
	var desk=find_scene("/timing_machines/soft_workshop.gd")
	check("Deformation desk binds existing cube and mill",desk!=null and desk.ready_for_input and desk.chapter=="deformation" and desk.model!=null and desk.other!=null)
	if desk==null:return
	map_origin=desk.global_position-hall.global_basis*Vector3(11.5,0,5.5)
	observations.origin=xyz(map_origin)
	await snapshot("before-above",map_at(Vector3(15,48,7)),map_at(Vector3(15,0,21)),65)
	await snapshot("existing-cube",desk.model.to_global(Vector3(.35,.65,1.4)),desk.model.to_global(Vector3(0,.23,0)),48)
	await snapshot("existing-mill",desk.other.to_global(Vector3(3,3,5)),desk.other.to_global(Vector3(0,1,0)),60)
	var sb:SoftBody3D=desk.model._soft_body
	var index:int=desk.model._anchor_index
	check("Original cube has a crown pin and the opening solver settings",index>=0 and sb.is_point_pinned(index) and sb.simulation_precision==5)
	var anchor:Vector3=sb.get_point_transform(index);var rid:RID=sb.get_physics_rid()
	var approach:Vector3=desk.to_global(Vector3(0,.01,2.9))
	observations.approach={"clear":clear_body(approach),"supported":not floor_at(approach).is_empty()}
	check("Desk approach is clear and supported",observations.approach.clear and observations.approach.supported)
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	observations.buttons=[]
	for id in ["STIFFNESS","DAMPING","PRESSURE","RESET","MILL","RULE"]:
		var result:Dictionary=await driver.press(desk.buttons[id],approach);await create_timer(.3).timeout;var effect:=false
		match id:
			"STIFFNESS":effect=is_equal_approx(sb.linear_stiffness,.1)
			"DAMPING":effect=is_equal_approx(sb.damping_coefficient,.05)
			"PRESSURE":effect=is_zero_approx(sb.pressure_coefficient)
			"RESET":effect=is_equal_approx(sb.linear_stiffness,.5) and is_equal_approx(sb.damping_coefficient,.01) and is_equal_approx(sb.pressure_coefficient,1) and sb.get_physics_rid()==rid
			"MILL":effect=desk.drive_held
			"RULE":effect=desk.rule_card.visible
		check("Actual pointer reaches "+id,effect and str(result.get("hover","")) not in ["","none","null","nothing"])
		observations.buttons.append({"id":id,"effect":effect,"pointer":result})
	check("Installed pin retained after control comparisons",anchor.distance_to(sb.get_point_transform(index))<.001)
	await snapshot("desk-controls",desk.to_global(Vector3(0,1.6,3)),desk.to_global(Vector3(0,1.2,0)),52)
	await driver.teardown();driver.queue_free();await tick()
	var study=load(DIR+"printed/study.gd").new();study.transform=Transform3D(desk.global_basis,map_at(Vector3(11.5,0,8.5)));root.add_child(study);await tick();await tick()
	var stand:Vector3=map_at(Vector3(11.5,.01,6.5))
	check("Learner approach has floor and body clearance",clear_body(stand) and not floor_at(stand).is_empty())
	await snapshot("student-rest",study.to_global(Vector3(-.25,1.75,1.85)),study.to_global(Vector3(.12,1.4,0)),46)
	var learner_pin:Vector3=study.cube.get_point_transform(study.cube.anchor_index)
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.point.global_position
	study.point.pick_up(pickup);await tick();await tick()
	var from:Vector3=hand.global_position;var target:Vector3=study.to_global(Vector3(0,1.27,.06))
	for i in 70:hand.global_position=from.lerp(target,float(i+1)/70.0);await tick()
	check("Same supplied XRTools point is held inside the soft cube",study.point.is_picked_up() and study.point.global_position.distance_to(target)<.02)
	check("Learner pin stays at its world position under contact",learner_pin.distance_to(study.cube.get_point_transform(study.cube.anchor_index))<.001)
	await snapshot("student-press",study.to_global(Vector3(-.35,1.7,1.65)),study.to_global(Vector3(.05,1.4,0)),43)
	study.point.action();await tick();check("Held trigger lowers learner stiffness",is_equal_approx(study.cube.linear_stiffness,.1))
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick();check("Point returns clear of the cube",study.point.position.is_equal_approx(Vector3(.45,1.3,.25)))
	origin.queue_free();await tick()
	await snapshot("after-above",map_at(Vector3(15,48,7)),map_at(Vector3(15,0,21)),65)
	study.queue_free();await tick()
	var edited=load(DIR+"variation/study.gd").new();edited.transform=Transform3D(desk.global_basis,map_at(Vector3(11.5,0,8.5)));root.add_child(edited);await tick();await tick()
	check("Complete subdivision edit has 96 reference entries in museum",edited.cube.rest_points.size()==96)
	await snapshot("student-fewer-vertices",edited.to_global(Vector3(-.25,1.75,1.85)),edited.to_global(Vector3(.12,1.4,0)),46)
	edited.queue_free();await tick()
	var blocked:Array=[];var gaps:Array=[];var samples:=0
	var route:=[Vector3(15.5,0,.5),Vector3(15.5,0,5.5),Vector3(26,0,5.5),Vector3(26,0,43.5),Vector3(15.5,0,43.5),Vector3(15.5,0,46.5)]
	for j in range(route.size()-1):
		var a:Vector3=route[j];var b:Vector3=route[j+1];var steps:=ceili(a.distance_to(b)/.25)
		for k in steps+1:
			var p:Vector3=a.lerp(b,float(k)/steps);var at:Vector3=map_at(p+Vector3.UP*.01);samples+=1
			if not clear_body(at):blocked.append(xyz(p))
			if floor_at(at).is_empty():gaps.append(xyz(p))
	observations.route={"samples":samples,"blocked":blocked,"gaps":gaps,"scope":"Sampled centre entrance and right-side route, not full player traversal."}
	check("Centre entry and side route have capsule clearance",blocked.is_empty())
	check("Sampled route has continuous support",gaps.is_empty())
	if stream!=null:
		observations.entry=stream.get("_entry")
		check("Authored entry no longer needs the blocked-entry fallback",not observations.entry.get("invalid",false))
	observations.entry_colliders=hit_names(map_at(Vector3(15.5,.01,1.5)))
	await snapshot("entry-approach",map_at(Vector3(15.5,1.65,.2)),map_at(Vector3(15.5,1.2,4)),62)
	observations.scope="Actual museum pointer controls and learner reconstruction; native images from eye level and above. Supplied XRTools poses, no physical headset or independent student. Production artifacts unchanged."
