extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var wall: Node3D=load("res://commons/artifacts/rotation_studies/wall_crossings.tscn").instantiate()
	root.add_child(wall)
	wall.set_physics_process(false)
	wall.set_crossing_pose()
	var centres: Array[Vector3]=[]
	var ends: Array[Vector3]=[]
	var bounds: Array[AABB]=[]
	for station: Dictionary in wall.stations:
		centres.append(station.panel.global_position)
		var end:=Vector3(0,0,4.2) if station.id=="X" else Vector3(4.2,0,0)
		ends.append(station.panel.to_global(end))
		var shape: CollisionShape3D=station.panel.get_node("Body").get_child(0)
		bounds.append(shape.global_transform*shape.shape.get_debug_mesh().get_aabb())
	wall.start_rides()
	wall._physics_process(wall.crossing_hold+1.0)
	var failures: Array[String]=[]
	var checks:=0
	for i in range(wall.stations.size()):
		var station: Dictionary=wall.stations[i]
		var end:=Vector3(0,0,4.2) if station.id=="X" else Vector3(4.2,0,0)
		var now: Vector3=station.panel.to_global(end)
		checks+=1
		if not station.panel.global_position.is_equal_approx(centres[i]):failures.append(str(station.id)+" moved its centre")
		checks+=1
		if station.id=="Y":
			if now.x<=ends[i].x:failures.append("Y did not reverse its swing")
		elif now.y>=ends[i].y:failures.append(str(station.id)+" raised end should descend in reversed turn")
	wall._physics_process(180.0/wall.turn_speed-1.0)
	for i in range(wall.stations.size()):
		var shape: CollisionShape3D=wall.stations[i].panel.get_node("Body").get_child(0)
		var after: AABB=shape.global_transform*shape.shape.get_debug_mesh().get_aabb()
		checks+=1
		if not after.is_equal_approx(bounds[i]):failures.append("Half-turn did not return matching physical crossing bounds")
	var f:=FileAccess.open("res://ada_run/rotation_turn_direction_checks.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
	print("[turn-direction] ",checks," checks; failures: ",failures)
	quit(0 if failures.is_empty() else 1)
