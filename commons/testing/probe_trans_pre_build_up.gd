extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
	print("[build-up] ","PASS " if ok else "FAIL ",label)
func floor_y(world: Node3D, x: float, z: float) -> float:
	var hit := world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x,3,z),Vector3(x,-1,z)))
	return hit.position.y if not hit.is_empty() else -999.0
func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var grid: Node3D = load("res://commons/grid/grid_system.tscn").instantiate()
	grid.set("map_name","Trans_Pre")
	grid.set("bare_world",true)
	grid.set("skip_player_spawn",true)
	grid.position.y = -0.5
	var done := [false]
	grid.connect("build_finished",func(): done[0]=true,CONNECT_ONE_SHOT)
	world.add_child(grid)
	for i in range(1800):
		if done[0]: break
		await process_frame
	check(done[0],"real grid built")
	for i in range(4): await process_frame
	var cubes := {}
	for n in grid.find_children("*","Node3D",true,false):
		if n.get_script() == load("res://commons/scenes/mapobjects/pick_up_cube.gd"):
			n.set_process(false)
			var p: Vector3 = grid.to_local(n.global_position)
			cubes[Vector2i(roundi(p.x),roundi(p.z))]=n
	check(cubes.size()==9,"four demonstrations and five pickups")
	for i in range(4):
		var cube: Node3D = cubes.get(Vector2i(4 if i == 0 else 2,2+i*3))
		if cube == null:
			check(false,"demonstration present " + str(i)); continue
		var mesh: Node3D = cube.get_node("CubeBaseMesh")
		cube.time_passed = 0.0
		cube._process(0.0)
		var p := cube.global_position
		var b := cube.basis
		var s := mesh.scale
		cube._process(0.4)
		check((not cube.global_position.is_equal_approx(p)) == (i>=1),"vertical oscillation stage " + str(i+1))
		check((not cube.basis.is_equal_approx(b)) == (i>=2),"rotation stage " + str(i+1))
		check((not mesh.scale.is_equal_approx(s)) == (i>=3),"scale stage " + str(i+1))
		cube.collect()
		check(not cube.has_been_collected and not cube.get_node("DetectionArea").monitoring,"demonstration survives contact " + str(i+1))
	for x in range(2,7):
		var cube: Node3D = cubes.get(Vector2i(x,18))
		check(cube != null and cube.hold == "collect" and cube.motion == "all","completed pickup on platform " + str(x))
	var marker_scripts := {
		"res://commons/artifacts/axis_translation_cube/axis_translation_cube.gd":5,
		"res://commons/artifacts/rotation_oscillation_cube/rotation_oscillation_cube.gd":8,
		"res://commons/artifacts/uniform_scale_marker/uniform_scale_marker.gd":11,
	}
	for path: String in marker_scripts:
		var marker: Node3D
		for n in grid.find_children("*","Node3D",true,false):
			if n.get_script() == load(path): marker=n; break
		check(marker != null,"principle marker loads: " + path.get_file())
		if marker == null: continue
		var p := grid.to_local(marker.global_position)
		check(is_equal_approx(p.x,4) and is_equal_approx(p.z,float(marker_scripts[path])),"marker beside its demonstration")
		if marker.has_node("FixedReference"):
			marker.set_process(false)
			var reference: Node3D = marker.get_node("FixedReference")
			var before := reference.transform
			marker.elapsed=0
			marker._process(PI/4)
			check(marker.body.scale.is_equal_approx(Vector3.ONE*1.3),"scale marker shows maximum factor")
			marker._process(PI/2)
			check(marker.body.scale.is_equal_approx(Vector3.ONE*0.7),"scale marker shows minimum factor")
			check(reference.transform.is_equal_approx(before),"scale reference remains fixed")
	await physics_frame
	for x in range(3,6):
		print("[ramp heights] ",x," ",[floor_y(world,x,14.6),floor_y(world,x,16.4),floor_y(world,x,19.6),floor_y(world,x,21.4)])
		check(is_equal_approx(floor_y(world,x,14.6),0.05),"ramp low end " + str(x))
		check(is_equal_approx(floor_y(world,x,16.4),0.95),"ramp high end " + str(x))
		check(is_equal_approx(floor_y(world,x,18),1.0),"platform top " + str(x))
		check(is_equal_approx(floor_y(world,x,19.6),0.95),"descent high end " + str(x))
		check(is_equal_approx(floor_y(world,x,21.4),0.05),"descent low end " + str(x))
	var walker := CharacterBody3D.new()
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius=0.22
	capsule.height=1.6
	collision.shape=capsule
	collision.position.y=0.8
	walker.add_child(collision)
	walker.floor_snap_length=0.15
	walker.floor_max_angle=deg_to_rad(45)
	world.add_child(walker)
	walker.position=Vector3(4,0.05,14)
	var highest := 0.0
	for i in range(290):
		await physics_frame
		walker.velocity=Vector3(0,walker.velocity.y-9.8/60.0,2)
		walker.move_and_slide()
		highest=maxf(highest,walker.position.y)
	check(walker.position.z>21.7 and highest>0.98,"capsule walks up, across and down without teleporting")
	print("[walk result] ",walker.position," highest ",highest)
	check(absf(walker.position.y)<0.1,"walker returns to floor height")
	# Exercise the plan scene directly; museum placement is checked in a separate capture.
	var plan: Node3D = load("res://commons/artifacts/simulation_grid/simulation_grid.tscn").instantiate()
	world.add_child(plan)
	plan.position=Vector3(20,0,0)
	await physics_frame
	var count := 0
	for child in plan.get_children():
		if child is MeshInstance3D: count+=1
	check(count==25,"plan has twenty-five visible cells")
	for x in range(5):
		for z in range(5): check(is_zero_approx(floor_y(world,18+x,-2+z)),"walkable plan cell %d,%d"%[x,z])
	check(floor_y(world,22.6,0)<-900,"plan collision ends at its five-metre edge")
	var f := FileAccess.open("res://ada_run/trans_pre_build_up_checks.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
	print("[build-up] ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
