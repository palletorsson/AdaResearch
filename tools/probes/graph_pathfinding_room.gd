extends "res://tools/probes/transformation_encounters.gd"
var completed := false
func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(1).timeout
	var stream = museum.get("_portal_stream")
	if stream != null:
		stream.set_process(false)
		stream.set_physics_process(false)
	var player = museum.get("_player")
	if player is Node3D:
		player.hide()
		player.process_mode = Node.PROCESS_MODE_DISABLED
		player.global_position = Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes := CameraAttributesPractical.new()
	attributes.exposure_multiplier = .35
	camera.attributes = attributes
	var artifact:=find_scene("/impatient_river.gd")
	observations.primary_present=artifact!=null
	observations.hall_position=xyz(hall.global_position)
	observations.placements=[]
	for node in hall.find_children("*","Node3D",true,false):
		if node.get_script()!=null and ("graph" in str(node.get_script().resource_path) or "river" in str(node.get_script().resource_path)):
			observations.placements.append({"script":str(node.get_script().resource_path),"position":xyz(node.global_position)})
	var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	if spec.get("baseline",false):
		await snapshot("above",hall.to_global(Vector3(6.5,25,20)),hall.to_global(Vector3(6.5,0,9)),60)
		await snapshot("entry",hall.to_global(Vector3(6.5,1.7,5.5)),hall.to_global(Vector3(6.5,1.3,12)),65)
		completed=true
		return
	check("Impatient River named by the text is installed",artifact!=null)
	if artifact==null:return
	artifact.set_process(false)
	var origin:Vector3=artifact.global_position-hall.global_basis*Vector3(9.5,0,8.5)
	observations.map_origin=xyz(origin)
	check("River contains two banks and eleven stones",artifact._stones.size()==13 and artifact._astar.get_point_count()==13)
	check("Initial seeded river offers a crossing",artifact._route.size()>2)
	var ids:PackedInt64Array=artifact._astar.get_id_path(0,1)
	observations.initial_river_route=Array(ids)
	var button:Node
	for node in artifact.get_children():
		if node.has_signal("pressed"):button=node;break
	check("River has its real connected press signal",button!=null)
	if button==null:return
	await snapshot("above",origin+hall.global_basis*Vector3(6.5,22,17),origin+hall.global_basis*Vector3(6.5,0,7),60)
	await snapshot("entry",origin+hall.global_basis*Vector3(6.5,1.7,1.5),origin+hall.global_basis*Vector3(7.5,1,9),65)
	await snapshot("river-before",artifact.to_global(Vector3(0,2.6,3.6)),artifact.to_global(Vector3(0,.2,0)),65)
	var spark_before:Vector3=artifact._spark.position
	button.emit_signal("pressed");await tick()
	check("Press disables a stone from the current route",artifact._sunk_queue.size()==1 and artifact._sunk_queue[0] in ids and artifact._astar.is_point_disabled(artifact._sunk_queue[0]))
	var expected:PackedVector3Array=artifact._astar.get_point_path(0,1)
	check("Button replans immediately and resets route indices",artifact._route==expected and artifact._leg==0 and artifact._t==0)
	check("Spark restarts at bank if a route exists, otherwise stays where it stopped",artifact._spark.position.is_equal_approx(spark_before if expected.is_empty() else expected[0]+Vector3(0,.16,0)))
	check("Returned river route avoids disabled stones",river_route_valid(artifact))
	observations.after_first_sink=Array(artifact._astar.get_id_path(0,1))
	await snapshot("river-after",artifact.to_global(Vector3(0,2.6,3.6)),artifact.to_global(Vector3(0,.2,0)),65)
	var first:int=artifact._sunk_queue[0]
	for unused in range(3):button.emit_signal("pressed");await tick()
	check("Fourth press restores first stone and keeps three disabled",artifact._sunk_queue.size()==3 and not artifact._astar.is_point_disabled(first) and not artifact._stones[first].sunk)
	check("Both banks remain available",not artifact._astar.is_point_disabled(0) and not artifact._astar.is_point_disabled(1))
	for id in range(2,13):artifact._astar.set_point_disabled(id,true)
	artifact._replan()
	check("No available stepping stones produces an empty route",artifact._route.is_empty())
	for id in range(2,13):artifact._astar.set_point_disabled(id,false)
	artifact._sunk_queue.clear()
	for id in range(2,13):
		artifact._stones[id].sunk=false
		artifact._stones[id].mesh.position=artifact._stones[id].pos
		artifact._stones[id].mat.albedo_color=Color(.55,.53,.5)
	artifact._replan()
	check("Restoring availability restores initial river path",artifact._astar.get_id_path(0,1)==ids)
	await learner_checks(origin,artifact)
	completed=true
func river_route_valid(artifact) -> bool:
	for position:Vector3 in artifact._route:
		var id:int=artifact._astar.get_closest_point(position,true)
		if artifact._astar.is_point_disabled(id):return false
	return true
func clear_at(p:Vector3) -> bool:
	var shape:=CapsuleShape3D.new();shape.radius=.24;shape.height=1.65
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform.origin=p+Vector3.UP*.9
	return hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
func learner_checks(origin:Vector3,river:Node3D) -> void:
	var study=load("res://doc/book/iterations/2026-10-10-pathfinding-a-route-kept/printed/study.tscn").instantiate();hall.add_child(study)
	study.global_transform=Transform3D(hall.global_basis*Basis(Vector3.UP,PI),origin+hall.global_basis*Vector3(3.5,-.25,5.5))
	await tick();study.set_process(false);study.replan()
	check("Exact printed learner creates the initial four-edge path",study.path==[3,1,0,2,6])
	var approach:Vector3=study.to_global(Vector3(0,.26,1.25))
	check("Learner bay has supported clear approach",not floor_at(approach).is_empty() and clear_at(approach))
	var front:Vector3=river.to_global(Vector3(0,.01,2.0))
	check("River button has a supported clear approach",not floor_at(front).is_empty() and clear_at(front))
	var good:=true;observations.blocked_samples=[];observations.route_samples=0
	for z in range(3,26):
		for x in [6.0,6.5,7.0]:
			var p:Vector3=origin+hall.global_basis*Vector3(x,.01,z*.5)
			var floor_ok:=not floor_at(p).is_empty();var clear:=clear_at(p)
			if not floor_ok or not clear:observations.blocked_samples.append({"at":xyz(p),"floor":floor_ok,"clear":clear})
			good=good and floor_ok and clear;observations.route_samples+=1
	check("Central route has continuous floor and body clearance",good)
	await snapshot("student-route",study.to_global(Vector3(0,2,2.9)),study.to_global(Vector3(0,1.9,0)),65)
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=study.point.global_position;study.point.pick_up(pickup);await tick()
	check("Museum PointBody attaches to synthetic XRTools hand",study.point.is_picked_up())
	study.point.action();await tick()
	check("Actual inherited trigger computes the detour in museum",study.path==[3,1,4,5,2,6])
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for unused in range(4):await tick()
	study._process(0.0);xr.hide()
	check("Release restores point to its route cursor",not study.point.held() and study.point.position.is_equal_approx(study.cursor))
	await snapshot("student-detour",study.to_global(Vector3(0,2,2.9)),study.to_global(Vector3(0,1.9,0)),65)
	study.change_availability()
	study.set_process(true)
	for unused in range(4):await tick()
	check("Blocked detour displays NO ROUTE and a reachable parked point",study.path.is_empty() and "NO ROUTE" in study.caption.text and study.point.position.is_equal_approx(study.PARK) and study.point.global_position.y>.4 and study.point.global_position.y<1.5)
	await snapshot("student-no-route",study.to_global(Vector3(0,2,2.9)),study.to_global(Vector3(0,1.9,0)),65)
	study.change_availability()
	await tick();study.set_process(false)
	check("Availability restores original route inside museum",study.path==[3,1,0,2,6])
	await snapshot("study-above",origin+hall.global_basis*Vector3(6.5,22,17),origin+hall.global_basis*Vector3(6.5,0,7),60)
	observations.learner_transform=str(study.global_transform);observations.learner_is_temporary=true
	study.queue_free();xr.queue_free();await tick()
func finish() -> void:
	check("All planned pathfinding room checks completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":completed and failures.is_empty(),"completed":completed,"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if completed and failures.is_empty() else 1)
