extends SceneTree
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label)
	print("[crossing] ","PASS " if ok else "FAIL ",label)
func bounds(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for body in node.find_children("*","PhysicsBody3D",true,false):
		for shape in body.find_children("*","CollisionShape3D",true,false):
			if shape.shape == null or shape.disabled: continue
			var b: AABB = shape.global_transform * shape.shape.get_debug_mesh().get_aabb()
			result=b if first else result.merge(b)
			first=false
	return result
func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	current_scene=world
	var grid: Node3D = load("res://commons/grid/grid_system.tscn").instantiate()
	grid.set("map_name","Trans_Introduction")
	grid.set("bare_world",true)
	grid.set("skip_player_spawn",true)
	grid.position.y=-0.5
	var done := [false]
	grid.connect("build_finished",func(): done[0]=true,CONNECT_ONE_SHOT)
	world.add_child(grid)
	for i in range(1800):
		if done[0]:break
		await process_frame
	for i in range(3):await process_frame
	check(done[0],"real introduction grid built")
	var crossings := {}
	for n in grid.find_children("*","Node3D",true,false):
		if n.get_script()==null:continue
		var path: String = n.get_script().resource_path
		if not path in ["res://commons/scenes/mapobjects/transport_cube.gd","res://commons/scenes/mapobjects/scale_cube.gd","res://commons/scenes/mapobjects/rotation_cube.gd"]:continue
		if "transport_cube.gd" in path:
			n.set_physics_process(false)
		else:
			n.set_process(false)
		crossings[path.get_file()]=n
		if "transport_cube.gd" in path:n.global_position=n.initial_position
		if "scale_cube.gd" in path:n.current_scale=n.max_scale;n.apply_scale()
		if "rotation_cube.gd" in path:
			n.mesh_instance.rotation_degrees=n.rotation_axis*90.0
			n.static_body.transform=n.mesh_instance.transform
		var box := bounds(n)
		print("[measure] ",path.get_file()," root=",n.global_position," collider=",box," top=",box.end.y)
		var deck_y := -0.05 if "rotation_cube.gd" in path else 0.0
		check(absf(box.end.y-deck_y)<0.002,path.get_file()+" top at authored deck height")
		if "rotation_cube.gd" in path:check(box.position.z<=15.21 and box.end.z>=18.79,"rotated bridge overlaps each bank by thirty centimetres")
	check(crossings.size()==3,"all three configured crossings present")
	var tc: Node3D = crossings["transport_cube.gd"]
	check(tc.initial_position.is_equal_approx(Vector3(5,-0.5,5)),"transport caches seated start before ready")
	check(tc.target_position.is_equal_approx(Vector3(5,-0.5,9)),"transport target keeps four-metre displacement")
	var rider := Node3D.new()
	world.add_child(rider)
	rider.global_position=Vector3(5,0,5)
	tc.carried_player=rider
	tc.waiting_to_start=false
	tc.is_returning=false
	tc.is_moving=true
	for i in range(120):tc._physics_process(1.0/60.0)
	check(rider.global_position.distance_to(Vector3(5,0,9))<0.002,"actual transport update carries rider to far bank without vertical jump")
	tc.carried_player=null
	rider.queue_free()
	var sc: Node3D = crossings["scale_cube.gd"]
	sc.current_scale=sc.min_scale
	sc.apply_scale()
	check(bounds(sc).end.y < -1.2,"small scale cube withdraws below deck")
	sc.is_scaling_up=true
	sc.pause_timer=0
	for i in range(151): sc._process(1.0/60.0)
	check(absf(bounds(sc).end.y)<0.002 and sc.pause_timer>3.9,"scale update reaches flush deck and holds for crossing")
	var rc: Node3D = crossings["rotation_cube.gd"]
	rc.current_angle=0
	rc.mesh_instance.rotation_degrees=Vector3.ZERO
	rc.static_body.transform=rc.mesh_instance.transform
	check(bounds(rc).position.z>15.5 and bounds(rc).end.z<18.5,"crosswise plank leaves forward gap open")
	rc.is_rotating=true
	rc.target_angle=90
	rc.pause_timer=0
	for i in range(120):rc._process(1.0/60.0)
	check(rc.current_angle==90 and rc.pause_timer==4,"rotation update reaches quarter-turn and holds")
	# Walk both held openings with a body under gravity, not just bounds checks.
	var walker := CharacterBody3D.new()
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius=0.22
	capsule.height=1.6
	collision.shape=capsule
	collision.position.y=0.8
	walker.add_child(collision)
	walker.floor_snap_length=0.15
	world.add_child(walker)
	for start_z in [10.0,15.0]:
		walker.position=Vector3(5,0.02,start_z)
		walker.velocity=Vector3.ZERO
		var lowest := 0.02
		for i in range(125):
			await physics_frame
			walker.velocity=Vector3(0,walker.velocity.y-9.8/60.0,2)
			walker.move_and_slide()
			lowest=minf(lowest,walker.position.y)
		check(walker.position.z>start_z+4 and lowest>-0.07 and absf(walker.position.y)<0.02,"capsule crosses opening and steps onto far bank at row "+str(start_z))
	walker.queue_free()
	# Shared seating preserves vertical/negative travel and raised source decks.
	for direction in [Vector3.UP,Vector3.FORWARD,Vector3.RIGHT]:
		var cube: Node3D = load("res://commons/scenes/mapobjects/transport_cube.tscn").instantiate()
		cube.move_direction=direction
		cube.move_distance=4
		UtilityRegistry.seat_crossing_before_ready(cube,"tc",2.5)
		world.add_child(cube)
		cube.set_physics_process(false)
		check(absf(bounds(cube).end.y-2.5)<0.002,"raised deck seated for "+str(direction))
		check((cube.target_position-cube.initial_position).is_equal_approx(direction*4),"travel vector preserved for "+str(direction))
		cube.queue_free()
	var f := FileAccess.open("res://ada_run/introduction_crossings_checks.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
	quit(0 if failures.is_empty() else 1)
