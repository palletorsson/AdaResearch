extends "res://tools/probes/transformation_encounters.gd"
const DIR := "res://doc/book/iterations/2026-10-09-colonization-who-can-answer/"
var map_origin: Vector3
func map_at(p:Vector3)->Vector3:return map_origin+hall.global_basis*p
func clear_body(at:Vector3)->bool:
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7
	var q:=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.transform.origin=at+Vector3.UP*.88;q.collision_mask=1|4
	var hits:=hall.get_world_3d().direct_space_state.intersect_shape(q)
	if not hits.is_empty():observations["hit_"+str(at)]=hits.map(func(h):return str(h.collider.get_path()))
	return hits.is_empty()
func forks(rows:Array)->int:
	var result:=0
	for i in rows.size():
		if rows.filter(func(n):return n.parent==i).size()>1:result+=1
	return result
func landing_checks()->void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var desk=find_scene("/space_colonization_algorithm/colonization_lesson.gd")
	check("Installed colonization lesson loaded",desk!=null)
	if desk==null:return
	map_origin=desk.global_position-hall.global_basis*Vector3(9.5,0,5.5)
	desk.act("RESET")
	await snapshot("opening",desk.to_global(Vector3(4,4,2)),desk.to_global(Vector3(0,2,-6)),78)
	var approach:Vector3=desk.to_global(Vector3(0,.01,2.9))
	check("Desk approach clear and supported",clear_body(approach) and not floor_at(approach).is_empty())
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	var held:Array=[];observations.buttons=[]
	for id in ["STEP","FIELD","HOLD","POLICY","RULE","RESET"]:
		var result:Dictionary=await driver.press(desk.buttons[id],approach);var effect:=false
		match id:
			"STEP":effect=desk.model.all_nodes.size()==2 and desk.model.all_nodes[1].position.is_equal_approx(Vector3(0,.5,0))
			"FIELD":effect=desk.field_index==1 and desk.model.all_nodes.size()==1 and desk.model.attraction_points.size()==8
			"HOLD":effect=not desk.held_record.is_empty();held=desk.held_record.duplicate(true)
			"POLICY":effect=desk.model.growth_policy=="network" and desk.model.current_iteration==0 and desk.model.attraction_points.size()==8
			"RULE":effect=desk.rule_card.visible
			"RESET":effect=desk.model.growth_policy=="tips" and desk.field_index==0 and desk.held_record==held
		check("Actual pointer button "+id,effect and str(result.get("hover","")) not in ["","none","null","nothing"])
		observations.buttons.append({"id":id,"result":result,"effect":effect})
	await driver.teardown();driver.queue_free();await tick()
	desk.act("FIELD")
	for i in 15:desk.act("STEP")
	check("Installed tips yields strand after fifteen steps",desk.forks()==0 and desk.model.all_nodes.size()>2)
	desk.act("HOLD");held=desk.held_record.duplicate(true)
	await snapshot("strand",desk.to_global(Vector3(4,4,2)),desk.to_global(Vector3(0,2,-6)),78)
	desk.act("POLICY")
	for i in 15:desk.act("STEP")
	check("Installed network forks while held strand stays",desk.forks()>0 and desk.held_record==held)
	await snapshot("forks",desk.to_global(Vector3(4,4,2)),desk.to_global(Vector3(0,2,-6)),78)
	desk.act("FIELD")
	for i in 35:desk.act("STEP")
	check("Canopy has ninety-six authored requests and remains bounded",desk.model.attraction_points.size()==96 and desk.model.all_nodes.size()<=192 and desk.model.current_iteration<=60)
	await snapshot("canopy",desk.to_global(Vector3(4,5,1)),desk.to_global(Vector3(0,2.8,-6)),78)
	desk.act("RESET")
	var ramp=hall.find_child("ObservationRampSupport",true,false);var supported:=ramp!=null
	for i in 13:
		var x:float=1.15+float(i)*.25;var y:float=minf((x-1)/3*2,2)
		supported=supported and not floor_at(map_at(Vector3(x,y+.05,24))).is_empty()
	check("Thirteen side-ramp samples have support",supported)
	var route_ok:=true;var samples:=0
	var route:=[Vector3(9.5,0,1.5),Vector3(17,0,3.5),Vector3(17,0,33.5),Vector3(9.5,0,33.5),Vector3(9.5,0,35.5)]
	for j in range(route.size()-1):
		var a:Vector3=route[j];var b:Vector3=route[j+1];var steps:=ceili(a.distance_to(b)/.25)
		for k in steps+1:
			var at:Vector3=map_at(a.lerp(b,float(k)/steps)+Vector3.UP*.01)
			route_ok=clear_body(at) and not floor_at(at).is_empty() and route_ok;samples+=1
	check("Eastern floor route supported and clear to exit approach",route_ok);observations.route_samples=samples
	var study=load(DIR+"printed/colony.gd").new();study.transform=Transform3D(desk.global_basis,map_at(Vector3(9.5,0,17)));root.add_child(study);await tick();await tick()
	var learner_approach:Vector3=map_at(Vector3(9.5,.01,15.4))
	check("Learner approach supported clear and point within reach",clear_body(learner_approach) and not floor_at(learner_approach).is_empty() and study.point.global_position.distance_to(learner_approach+Vector3.UP*1.1)<.9)
	check("Learner field matches installed opening",study.model.points==Array(desk.model.attraction_points))
	await snapshot("student-opening",study.to_global(Vector3(2.5,2.6,3.5)),study.to_global(Vector3(-.4,1.5,0)),68)
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=study.point.global_position;study.point.pick_up(pickup);await tick();await tick();controller.global_position+=Vector3(.2,.1,0);await tick();await tick()
	check("Learner hand movement does not advance",study.point.is_picked_up() and study.model.generation==0)
	study.point.action();await tick();check("Learner trigger produces predicted first child",study.model.nodes.size()==2 and study.model.nodes[1].position.is_equal_approx(Vector3(0,.5,0)))
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	check("Learner release returns carried point",study.point.position.is_equal_approx(Vector3(0,1.1,.8)))
	origin.queue_free();await tick();study.act("FIELD")
	for i in 15:study.act("STEP")
	study.act("HOLD");var saved:Array=study.held.duplicate(true);study.act("POLICY")
	for i in 15:study.act("STEP")
	check("Printed museum study forks and preserves independent witness",forks(study.model.nodes)>0 and study.held==saved and forks(study.held)==0)
	await snapshot("student-forks",study.to_global(Vector3(2.5,2.6,3.5)),study.to_global(Vector3(-.4,1.5,0)),68)
	await snapshot("above",desk.to_global(Vector3(0,35,-8)),desk.to_global(Vector3(0,0,-12)),70)
	study.queue_free();await tick()
	var edited=load(DIR+"variation/colony.gd").new();edited.transform=Transform3D(desk.global_basis,map_at(Vector3(9.5,0,17)));root.add_child(edited);await tick();await tick();edited.act("FIELD");edited.act("STEP")
	check("Complete weighted-vote variation works in museum",edited.model.nodes[1].position.is_equal_approx(Vector3(-1.5,29.5,.9).normalized()*.5))
	await snapshot("student-weighted",edited.to_global(Vector3(2.5,2.6,3.5)),edited.to_global(Vector3(-.4,1.5,0)),68)
	edited.queue_free();await tick()
	await snapshot("deck",desk.to_global(Vector3(-5,6,-19)),desk.to_global(Vector3(0,1,-22)),70)
	if stream!=null:check("Entry and onward records exist",not stream.get("_entry").is_empty() and not stream.get("_exit").is_empty() and not stream.get("_exit").get("invalid",false))
	observations.scope="Real hall and six pointer controls; temporary exact printed model plus full variation; supplied XRTools poses and sampled support. No physical headset, independent student or complete portal traversal."
