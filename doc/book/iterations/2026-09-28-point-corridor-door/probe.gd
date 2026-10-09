extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.flush_stamps()
	if map_id=="Point_Zero":
		var origin := find_scene("/origin.gd")
		check("restored origin remains at world zero",origin!=null and origin.global_position.distance_to(Vector3.ZERO)<0.001)
		camera.global_position=Vector3(7,1.65,2)
		camera.current=true
		museum._build_segment()
		museum.flush_stamps()
		await create_timer(2.0).timeout
		for child in museum.get_children():
			if child is Node3D and str(child.get_meta("em_map",""))=="Point_One":hall=child;break
	check("Point One loaded in continuous museum",str(hall.get_meta("em_map",""))=="Point_One")
	var door := find_scene("/point_corridor_door.gd")
	check("corridor door is present",door!=null)
	if door==null:return
	check("door spans four-metre corridor",is_equal_approx(door.visual.door_width,4.0) and is_equal_approx(door.global_position.x,8.0))
	var blocked := false
	for cause in museum.get("_walk_erased").values():
		if str(cause)=="seal:point_corridor_door":blocked=true
	check("door does not permanently seal route-planner cells",not blocked)
	check("door floor is flush",absf(door.global_position.y-hall.global_position.y)<0.01)
	var held := find_scene("/point_condition.gd")
	var stations:=0
	for n in hall.find_children("*","Node3D",true,false):
		if n.get_script()!=null and str(n.get_script().resource_path).ends_with("/point_condition.gd"):stations+=1
	check("all five point stations remain",stations==5)
	var world := hall.get_world_3d().direct_space_state
	var start: Vector3=door.global_position+Vector3(0.45,1.1,-0.8)
	var end: Vector3=start+Vector3(0,0,1.6)
	await physics_frame
	check("door initially closed before approach",not door.opening and is_zero_approx(door.progress))
	var hit:=world.intersect_ray(PhysicsRayQueryParameters3D.create(start,end,1))
	check("closed leaf blocks actual passage",not hit.is_empty() and door.is_ancestor_of(hit.collider))
	await snapshot("closed",door.global_position+Vector3(0,1.65,-4),door.global_position+Vector3(0,1.45,0),64)
	camera.global_position=door.global_position+Vector3(0,1.65,-2.5)
	await create_timer(0.4).timeout
	check("approach opens door gradually",door.progress>0.1 and door.progress<0.95)
	await snapshot("opening",door.global_position+Vector3(0,1.65,-2.5),door.global_position+Vector3(0,1.3,2),68)
	await create_timer(1.2).timeout
	check("door fully retracts",is_equal_approx(door.progress,1.0))
	check("open passage clears the moving colliders",world.intersect_ray(PhysicsRayQueryParameters3D.create(start,end,1)).is_empty())
	var walker: CharacterBody3D=museum.get("_player")
	walker.global_position=door.global_position+Vector3(0.5,0.025,-1.0);walker.velocity=Vector3.ZERO
	await physics_frame
	check("actual walker can enter point corridor",walker.move_and_collide(Vector3(0,0,2.1))==null)
	check("first station approach is supported",not floor_at(walker.global_position).is_empty())
	check("actual walker can return through door",walker.move_and_collide(Vector3(0,0,-2.1))==null)
	camera.global_position=door.global_position+Vector3(0,1.65,5)
	await create_timer(1).timeout
	check("door stays open after departure",is_equal_approx(door.progress,1.0) and not door.is_physics_processing())
	await snapshot("open",door.global_position+Vector3(0,1.65,-3),door.global_position+Vector3(0,1.2,7),66)
	observations["door_world"]=xyz(door.global_position)
	observations["hall_world"]=xyz(hall.global_position)

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Continuous native museum from Point Zero into Point One, current-camera approach, leaf collision and real desktop walker. Headset not tested."},"  "))
	print("POINT CORRIDOR DOOR ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
