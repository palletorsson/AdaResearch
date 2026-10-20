extends "res://tools/probes/transformation_encounters.gd"
const DIR := "res://doc/book/iterations/2026-10-09-branching-record-and-place/"
var map_origin:Vector3
func map_at(p:Vector3)->Vector3:return map_origin+hall.global_basis*p
func clear_body(at:Vector3)->bool:
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform.origin=at+Vector3.UP*.88;query.collision_mask=1|4
	var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
	if not hits.is_empty():observations["hit_"+str(at)]=hits.map(func(h):return str(h.collider.get_path()))
	return hits.is_empty()
func unique(source)->int:
	var positions:Dictionary={}
	for b in source.branches:positions[b.position]=true
	return positions.size()
func landing_checks()->void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes:=CameraAttributesPractical.new();attributes.exposure_multiplier=.45;camera.attributes=attributes
	observations.capture_exposure=.45
	var desk=find_scene("/timing_machines/pg_workshop.gd")
	check("Branching desk bound",desk!=null and desk.ready_for_input and desk.chapter=="branching")
	if desk==null:return
	map_origin=desk.global_position-hall.global_basis*Vector3(13.5,0,3.5)
	desk.act("RESET")
	check("Actual opening has eight shared targets and variations off",desk.model.attractors.size()==8 and desk.model.jitter==0 and desk.model.pulse_strength==0)
	await snapshot("opening",desk.to_global(Vector3(5,5,-1)),desk.model.to_global(Vector3(0,2,0)),85)
	var approach:Vector3=desk.to_global(Vector3(0,.01,2.9))
	check("Desk approach is supported and clear",clear_body(approach) and not floor_at(approach).is_empty())
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	var held_id:=0;var held_bounds:=AABB();observations.buttons=[]
	for id in ["STEP","HOLD","TEN STEPS","VARIATION","RULE","RESET"]:
		var result:Dictionary=await driver.press(desk.buttons[id],approach);var effect:=false
		match id:
			"STEP":effect=desk.model.branches.size()==2 and desk.model.branches[1].position.is_equal_approx(Vector3(-.4,.3,0))
			"HOLD":
				effect=is_instance_valid(desk.held) and desk.held.mesh!=desk.model.immediate_mesh
				held_id=desk.held.get_instance_id();held_bounds=desk.held.mesh.get_aabb()
			"TEN STEPS":effect=desk.model.branches.size()==192 and unique(desk.model)==14
			"VARIATION":effect=desk.variant==1 and desk.model.jitter==.15 and desk.model.pulse_strength==.3 and desk.model.branches.size()==1
			"RULE":effect=desk.rule_card.visible
			"RESET":effect=desk.variant==0 and desk.model.branches.size()==1 and desk.held.get_instance_id()==held_id and desk.held.mesh.get_aabb()==held_bounds
		check("Actual pointer button "+id,effect and str(result.get("hover","")) not in ["","none","null","nothing"])
		observations.buttons.append({"id":id,"pointer":result,"effect":effect})
	await driver.teardown();driver.queue_free();await tick()
	desk.act("RESET");desk.act("STEP");desk.act("STEP")
	check("Actual second step has four records at three places",desk.model.branches.size()==4 and unique(desk.model)==3)
	await snapshot("two-steps",desk.model.to_global(Vector3(-3,2,4)),desk.model.to_global(Vector3(-.5,1,0)),65)
	desk.act("TEN STEPS")
	check("Installed record cap reached while distinct positions remain fourteen",desk.model.branches.size()==192 and unique(desk.model)==14)
	desk.act("HOLD")
	await snapshot("duplicates",desk.to_global(Vector3(3,3,2)),desk.model.to_global(Vector3(0,2,0)),85)
	desk.act("VARIATION");desk.act("TEN STEPS")
	check("Supplied jitter and pulse create distinct alternatives within budget",desk.model.branches.size()<=192 and unique(desk.model)>14)
	await snapshot("variation",desk.model.to_global(Vector3(-3,3,5)),desk.model.to_global(Vector3(0,2,0)),75)
	desk.act("RESET")
	var route_ok:=true;var samples:=0
	var route:=[Vector3(16,0,3.5),Vector3(24,0,3.5),Vector3(24,0,38.5),Vector3(13.5,0,38.5),Vector3(13.5,0,40.5)]
	for j in range(route.size()-1):
		var a:Vector3=route[j];var b:Vector3=route[j+1];var steps:=ceili(a.distance_to(b)/.25)
		for k in steps+1:
			var at:Vector3=map_at(a.lerp(b,float(k)/steps)+Vector3.UP*.01)
			route_ok=clear_body(at) and not floor_at(at).is_empty() and route_ok;samples+=1
	check("Eastern bypass from beside desk reaches exit approach",route_ok);observations.route_samples=samples
	var study=load(DIR+"printed/branches.gd").new();study.transform=Transform3D(desk.global_basis,map_at(Vector3(8.5,0,21)));root.add_child(study);await tick();await tick()
	var learner_approach:Vector3=map_at(Vector3(8.5,.01,19.4))
	check("Learner approach supported clear and point reachable",clear_body(learner_approach) and not floor_at(learner_approach).is_empty() and study.point.global_position.distance_to(learner_approach+Vector3.UP*1.1)<.9)
	check("Printed field matches installed target positions",study.model.points==desk.model.attractors.map(func(a):return a.position))
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=study.point.global_position;study.point.pick_up(pickup);await tick();await tick();controller.global_position+=Vector3(.2,.1,0);await tick();await tick()
	check("Moving held point does not add a record",study.point.is_picked_up() and study.model.nodes.size()==1)
	study.point.action();await tick();check("Held trigger creates first child with target recorded",study.model.nodes.size()==2 and study.model.nodes[1].target==0 and study.model.nodes[1].parent==0)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	check("Point parks after release",study.point.position.is_equal_approx(Vector3(0,1.1,.8)))
	origin.queue_free();await tick();study.act("STEP")
	await snapshot("student-two",study.to_global(Vector3(1.5,2.2,3.6)),study.to_global(Vector3(-.5,1.5,0)),65)
	study.act("HOLD");var saved:Array=study.held.duplicate(true);study.act("TEN")
	check("Printed model in museum reaches same192/14 while witness remains",study.model.nodes.size()==192 and study.model.distinct_count()==14 and study.held==saved)
	await snapshot("student-many",study.to_global(Vector3(1.5,2.2,3.6)),study.to_global(Vector3(-.5,1.5,0)),65)
	await snapshot("above",desk.to_global(Vector3(0,43,-13)),desk.to_global(Vector3(0,0,-17)),70)
	study.queue_free();await tick()
	var edited=load(DIR+"variation/branches.gd").new();edited.transform=Transform3D(desk.global_basis,map_at(Vector3(8.5,0,21)));root.add_child(edited);await tick();await tick();edited.act("TEN")
	check("Full student edit produces11 records at10 places in museum",edited.model.nodes.size()==11 and edited.model.distinct_count()==10)
	await snapshot("student-retired",edited.to_global(Vector3(1.5,2.2,3.6)),edited.to_global(Vector3(-.5,1.5,0)),65)
	edited.queue_free();await tick()
	var organic=find_scene("/organicspace/organic_space.gd")
	check("Organic Space remains present as separate construction",organic!=null)
	if organic!=null:await snapshot("organic",organic.to_global(Vector3(8,7,9)),organic.global_position,70)
	if stream!=null:
		observations.entry=stream.get("_entry");observations.exit=stream.get("_exit")
		check("Onward record valid",not observations.exit.is_empty() and not observations.exit.get("invalid",false))
	observations.scope="Actual museum controls and temporary exact learner code, full variant, sampled supported route; photographic camera exposure .45, scene lighting unchanged. Organic presence only. No physical headset, independent student or full portal traversal."
