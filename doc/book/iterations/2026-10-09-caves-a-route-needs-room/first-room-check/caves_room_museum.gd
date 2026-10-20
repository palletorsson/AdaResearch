extends "res://tools/probes/transformation_encounters.gd"
const DIR := "res://doc/book/iterations/2026-10-09-caves-a-route-needs-room/"
var map_origin:Vector3
func map_at(p:Vector3)->Vector3:return map_origin+hall.global_basis*p
func clear_body(at:Vector3)->bool:
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform.origin=at+Vector3.UP*.88;query.collision_mask=1|4
	var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
	if not hits.is_empty():observations["hit_"+str(at)]=hits.map(func(h):return str(h.collider.get_path()))
	return hits.is_empty()
func maze_route(maze:Array)->bool:
	var queue:Array=[Vector2i(1,0)];var seen:Dictionary={Vector2i(1,0):true}
	while not queue.is_empty():
		var p:Vector2i=queue.pop_front()
		for d in [Vector2i.RIGHT,Vector2i.LEFT,Vector2i.UP,Vector2i.DOWN]:
			var n:Vector2i=p+d
			if n.x<0 or n.y<0 or n.x>=9 or n.y>=9 or seen.has(n) or maze[n.y][n.x]:continue
			seen[n]=true;queue.append(n)
	return seen.has(Vector2i(7,8))
func landing_checks()->void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes:=CameraAttributesPractical.new();attributes.exposure_multiplier=.45;camera.attributes=attributes
	var desk=find_scene("/timing_machines/pg_workshop.gd")
	check("Cave and maze desk bound",desk!=null and desk.ready_for_input and desk.chapter=="caves")
	if desk==null:return
	map_origin=desk.global_position-hall.global_basis*Vector3(19.5,0,3.5)
	observations.cave_origin=xyz(desk.model.global_position);observations.maze_origin=xyz(desk.other.global_position)
	observations.initial_seed=desk.model.seed
	var approach:Vector3=desk.to_global(Vector3(0,.01,2.9))
	check("Desk hand approach supported clear",clear_body(approach) and not floor_at(approach).is_empty())
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	observations.buttons=[]
	for id in ["CAVE SEED","TRACE","MAZE STEP","FINISH","RESET","RULE"]:
		var result:Dictionary=await driver.press(desk.buttons[id],approach);await create_timer(.3).timeout;var effect:=false
		match id:
			"CAVE SEED":effect=desk.model.seed==observations.initial_seed+1
			"TRACE":effect=desk.trace.visible and desk.trace.multimesh.instance_count==desk.model.carve_history.size()
			"MAZE STEP":effect=desk.step_count==1 and desk.other.generation_stack.size()==1
			"FINISH":effect=desk.other.generation_complete and maze_route(desk.other.maze)
			"RESET":effect=desk.step_count==0 and desk.other.generating and desk.other.generation_stack.is_empty()
			"RULE":effect=desk.rule_card.visible
		check("Actual pointer button "+id,effect and str(result.get("hover","")) not in ["","none","null","nothing"])
		observations.buttons.append({"id":id,"pointer":result,"effect":effect})
	await driver.teardown();driver.queue_free();await tick()
	# Replay exactly the actual installed carving record, not a newly generated route.
	var source=load("res://algorithms/proceduralgeneration/growth_systems/caverandomwalk/caverandomwalk.gd").new()
	source.grid_size=desk.model.grid_size;source._init_grid()
	for p in desk.model.carve_history:source._carve_ball(p)
	check("Retained centres reproduce installed cave volume exactly",source._solid==desk.model._solid and source.carve_history==desk.model.carve_history)
	observations.carve_centres=source.carve_history.size();observations.cave_air=source._solid.count(0);source.free()
	var distinct:Dictionary={}
	for p in desk.model.carve_history:distinct[p]=true
	check("Cave history retains repeated visits",distinct.size()<desk.model.carve_history.size())
	observations.distinct_centres=distinct.size()
	var mouth_clear:=true
	for z in [5.5,5.0,4.5,4.0,3.5]:
		var at:Vector3=desk.model.to_global(Vector3(.5,-.49,z))
		mouth_clear=clear_body(at) and not floor_at(at).is_empty() and mouth_clear
	check("Five front-mouth standing capsules have floor and headroom",mouth_clear)
	await snapshot("cave-outside",desk.model.to_global(Vector3(-8,5,10)),desk.model.to_global(Vector3(0,2.5,0)),65)
	await snapshot("cave-inside",desk.model.to_global(Vector3(.5,1.05,4.6)),desk.model.to_global(Vector3(.5,1.05,1.5)),76)
	await snapshot("cave-trace",desk.model.to_global(Vector3(6,13,7)),desk.model.to_global(Vector3(0,3,0)),60)
	desk.act("FINISH");await tick()
	var vis:=0;var walls_clear:=true
	for y in 9:
		for x in 9:
			if desk.other.visited[y][x]:vis+=1
			if not desk.other.maze[y][x]:walls_clear=walls_clear and not is_instance_valid(desk.other.wall_colliders[y][x])
	check("Maze visits all sixteen rooms and opens entrance-to-exit array route",vis==16 and maze_route(desk.other.maze))
	check("Open maze addresses have removed wall colliders",walls_clear)
	await snapshot("maze",desk.other.to_global(Vector3(-3,17,17)),desk.other.to_global(Vector3(6,0,6)),68)
	var route_ok:=true;var samples:=0
	var route:=[Vector3(22,0,3.5),Vector3(35,0,3.5),Vector3(35,0,44.5),Vector3(19.5,0,44.5),Vector3(19.5,0,46.5)]
	for j in range(route.size()-1):
		var a:Vector3=route[j];var b:Vector3=route[j+1];var steps:=ceili(a.distance_to(b)/.25)
		for k in steps+1:
			var at:Vector3=map_at(a.lerp(b,float(k)/steps)+Vector3.UP*.01)
			route_ok=clear_body(at) and not floor_at(at).is_empty() and route_ok;samples+=1
	check("Side bypass has support and body clearance",route_ok);observations.route_samples=samples
	var study=load(DIR+"printed/cave.gd").new();study.transform=Transform3D(desk.global_basis,map_at(Vector3(10.5,0,10)));root.add_child(study);await tick();await tick()
	var learner_approach:Vector3=map_at(Vector3(10.5,.01,8))
	check("Learner bay has supported clear point approach",clear_body(learner_approach) and not floor_at(learner_approach).is_empty() and study.point.global_position.distance_to(learner_approach+Vector3.UP*1.1)<.9)
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.point.global_position;study.point.pick_up(pickup);await tick();await tick();hand.global_position+=Vector3(.2,.1,0);await tick()
	check("Hand movement alone leaves solid untouched",study.point.is_picked_up() and study.cursor==0)
	study.point.action();await tick();check("Held action clears first eight cells",study.cursor==1 and study.model.air_count()==8)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	check("Release parks inherited point",study.point.position.is_equal_approx(Vector3(0,1.1,1.45)))
	origin.queue_free();await tick()
	study.act("FINISH");await tick()
	check("Printed full route clears forty-four cells in museum",study.model.air_count()==44 and study.model.history.size()==9)
	await snapshot("student-two",study.to_global(Vector3(0,1.25,3.7)),study.to_global(Vector3(0,1.25,0)),54)
	study.act("CUT");await tick();var kept:PackedByteArray=study.model.solid.duplicate()
	check("Cutaway leaves solid data intact",kept.count(0)==44 and study.cutaway)
	await snapshot("student-cut",study.to_global(Vector3(2.7,3.7,3.4)),study.to_global(Vector3(0,1.3,0)),58)
	await snapshot("above",desk.to_global(Vector3(0,51,-17)),desk.to_global(Vector3(0,0,-21)),70)
	study.queue_free();await tick()
	var edited=load(DIR+"variation/cave.gd").new();edited.transform=Transform3D(desk.global_basis,map_at(Vector3(10.5,0,10)));root.add_child(edited);await tick();edited.act("FINISH");await tick()
	check("Complete edited program clears sixty-six cells with same nine centres",edited.model.air_count()==66 and edited.model.history==Array(edited.ROUTE))
	await snapshot("student-three",edited.to_global(Vector3(0,1.25,3.7)),edited.to_global(Vector3(0,1.25,0)),54)
	edited.queue_free();await tick()
	if stream!=null:
		observations.entry=stream.get("_entry");observations.exit=stream.get("_exit")
		check("Onward record valid",not observations.exit.is_empty() and not observations.exit.get("invalid",false))
	observations.scope="Actual pointer controls, retained cave replay, five mouth capsules, maze array route and removed colliders, complete learner and headroom edit, supplied XRTools poses, side bypass. Camera exposure .45. No headset, full cave/maze traversal or independent student acceptance."
