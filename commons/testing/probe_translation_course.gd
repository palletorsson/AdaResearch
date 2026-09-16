extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[course] ", "PASS " if ok else "FAIL ", message)
func v(a: Array) -> Vector3: return Vector3(a[0],a[1],a[2])
func top(node: Node3D) -> float:
	# The ferry contains a nested scene; only the physical box defines its deck.
	for n in node.static_body.find_children("*","CollisionShape3D",true,false):
		if n.get_parent() is PhysicsBody3D:
			var box: AABB=n.global_transform*n.shape.get_debug_mesh().get_aabb()
			return box.end.y
	return -999
func run() -> void:
	var only_ride := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ride="): only_ride=arg.trim_prefix("--ride=")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/Trans_Translation/map_data.json"))
	var world:=Node3D.new()
	root.add_child(world)
	current_scene=world
	var grid: Node3D=load("res://commons/grid/grid_system.tscn").instantiate()
	grid.map_name="Trans_Translation"
	grid.bare_world=true
	grid.skip_player_spawn=true
	grid.position.y=-0.5
	var done:=[false]
	grid.build_finished.connect(func():done[0]=true,CONNECT_ONE_SHOT)
	world.add_child(grid)
	for i in range(2400):
		if done[0]:break
		await process_frame
	check(done[0],"merged grid builds")
	var ferries:={}
	var pickups: Array[Node3D]=[]
	for n in grid.find_children("*","Node3D",true,false):
		if n.get_script()==load("res://commons/scenes/mapobjects/transport_cube.gd"):
			n.set_physics_process(false)
			ferries[Vector2i(roundi(n.initial_position.x),roundi(n.initial_position.z))]=n
			UtilityRegistry.make_carriable(n)
		if n.get_script()==load("res://commons/scenes/mapobjects/pick_up_cube.gd"):
			pickups.append(n)
	check(ferries.size()==7,"seven transport cubes")
	if only_ride.is_empty(): check(pickups.size()==13,"thirteen pickups along the rides")
	var walker:=CharacterBody3D.new()
	walker.name="CoursePlayer"
	walker.add_to_group("em_walker")
	var collision:=CollisionShape3D.new()
	var capsule:=CapsuleShape3D.new()
	capsule.radius=0.22
	capsule.height=1.6
	collision.shape=capsule
	collision.position.y=0.8
	walker.add_child(collision)
	world.add_child(walker)
	for ride: Dictionary in data.translation_course.rides:
		if not only_ride.is_empty() and ride.id!=only_ride: continue
		var start:=v(ride.start)
		var end:=v(ride.end)
		var cube: Node3D=ferries[Vector2i(start.x,start.z)]
		var label: String=ride.id
		for point: Array in ride.pickups:
			var present:=false
			for pickup in pickups:
				if is_instance_valid(pickup) and pickup.global_position.distance_to(v(point))<0.01: present=true
			check(present,label+" pickup is at the authored world position "+str(point))
		check(cube.initial_position.distance_to(start-Vector3.UP*0.5)<0.002,label+" centre seated half a metre below starting deck")
		check(cube.target_position.distance_to(end-Vector3.UP*0.5)<0.002,label+" target deck matches landing")
		check(absf(top(cube)-start.y)<0.002,label+" physical standing surface at start height")
		check(is_zero_approx(cube.ride_rotation_degrees) and is_equal_approx(cube.ride_scale,1),label+" translates without rotation or scale")
		walker.global_position=start+Vector3.UP*0.01
		for i in range(3):await physics_frame
		check(cube.carried_player==walker,label+" detects the museum walker")
		# Run the real movement/carry code at a fixed step; pickup collection is
		# still driven by actual Area3D body contacts on physics frames.
		cube.waiting_to_start=false
		cube.is_returning=false
		cube.is_moving=true
		for i in range(ceili(cube.move_distance/cube.move_speed*60)+2):
			cube._physics_process(1.0/60.0)
			await physics_frame
		check(walker.global_position.distance_to(end+Vector3.UP*0.01)<0.03,label+" rider arrives without height jump")
		check(absf(top(cube)-end.y)<0.002,label+" arrival surface at destination height")
		for point: Array in ride.pickups:
			var uncollected:=false
			for pickup in pickups:
				if is_instance_valid(pickup) and pickup.global_position.distance_to(v(point))<0.01 and not pickup.has_been_collected:uncollected=true
			check(not uncollected,label+" collects pickup at "+str(point))
		cube.carried_player=null
		cube.player_on_cube=false
		# Walk forward off each stopped ferry onto its island. This exercises
		# the landing lip, including the top and bottom of both lift sockets.
		var landing_start:=walker.global_position
		var lowest:=landing_start.y
		walker.velocity=Vector3.ZERO
		walker.floor_snap_length=0.15
		for i in range(48):
			await physics_frame
			walker.velocity=Vector3(0,walker.velocity.y-9.8/60.0,2)
			walker.move_and_slide()
			lowest=minf(lowest,walker.position.y)
		check(walker.position.z>landing_start.z+1.4 and lowest>end.y-0.05 and absf(walker.position.y-end.y)<0.03,label+" steps off onto the landing")
		walker.position=Vector3(-10,10,-10)
		for i in range(2):await physics_frame
	var report_path := "res://ada_run/translation_course_checks.json" if only_ride.is_empty() else "res://ada_run/translation_"+only_ride+"_checks.json"
	var f:=FileAccess.open(report_path,FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
	print("[course] ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
