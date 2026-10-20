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
		player.set_process(false)
		player.set_physics_process(false)
		player.global_position = Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes := CameraAttributesPractical.new()
	attributes.exposure_multiplier = .35
	camera.attributes = attributes
	var tree := find_scene("/two_travelers.gd")
	if tree == null:
		for node in root.find_children("*", "Node3D", true, false):
			if node.get_script() != null and str(node.get_script().resource_path).ends_with("/two_travelers.gd"):
				tree = node
	observations.graph_scripts = []
	for node in root.find_children("*", "Node3D", true, false):
		if node.get_script() != null and ("graph" in str(node.get_script().resource_path) or "travel" in str(node.get_script().resource_path)):
			observations.graph_scripts.append(str(node.get_path())+" : "+str(node.get_script().resource_path))
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	if spec.get("baseline",false):
		observations.primary_present = tree != null
		observations.hall_position = xyz(hall.global_position)
		await snapshot("above",hall.to_global(Vector3(6.5,21,19)),hall.to_global(Vector3(6.5,0,6)),62)
		await snapshot("entry",hall.to_global(Vector3(6.5,1.7,1)),hall.to_global(Vector3(6.5,1.4,9)),65)
		completed = true
		return
	check("Existing fifteen-lamp traveller artifact is present", tree != null)
	if tree == null: return
	var origin := tree.global_position - hall.global_basis * Vector3(9.5,0,7.5)
	observations.map_origin = xyz(origin)
	observations.tree_position = xyz(tree.global_position)
	observations.bfs = tree._bfs_order
	observations.dfs = tree._dfs_order
	check("Installed tree contains fifteen lamps",tree._nodes.size()==15)
	check("Installed orders cover the same fifteen identities",tree._bfs_order.size()==15 and tree._dfs_order.size()==15)
	await snapshot("above",origin+hall.global_basis*Vector3(6.5,20,15.5),origin+hall.global_basis*Vector3(6.5,0,5.5),62)
	await snapshot("encounter",tree.to_global(Vector3(0,2.5,5.2)),tree.to_global(Vector3(0,1.5,0)),58)
	await snapshot("entry",origin+hall.global_basis*Vector3(6.5,1.7,-1.0),origin+hall.global_basis*Vector3(6.5,1.3,8),60)
	await learner_checks(origin,tree)
	completed = true

func clear_at(p: Vector3) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = .24
	capsule.height = 1.65
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	query.transform.origin = p + Vector3.UP * .9
	return hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty()

func learner_checks(origin: Vector3, tree: Node3D) -> void:
	var study = load("res://doc/book/iterations/2026-10-10-graph-two-orders/printed/study.tscn").instantiate()
	hall.add_child(study)
	study.global_transform = Transform3D(hall.global_basis * Basis(Vector3.UP,PI),origin+hall.global_basis*Vector3(3.5,0,4.5))
	await tick()
	check("Printed study initializes in real museum",study.lamps.size()==7 and study.point.held()==false)
	var approach: Vector3 = study.to_global(Vector3(0,.01,1.25))
	check("Study has a supported clear approach",not floor_at(approach).is_empty() and clear_at(approach))
	var witness: Vector3 = tree.to_global(Vector3(0,.01,1.5))
	check("Installed travellers have a supported clear approach",not floor_at(witness).is_empty() and clear_at(witness))
	var route_ok := true
	var samples := 0
	observations.blocked_samples = []
	for z in range(2,21):
		for x in [6.0,6.5,7.0]:
			var at: Vector3 = origin+hall.global_basis*Vector3(x,.01,z*.5)
			var supported := not floor_at(at).is_empty()
			var clear := clear_at(at)
			if not supported or not clear:
				observations.blocked_samples.append({"at":xyz(at),"floor":supported,"clear":clear})
			route_ok = route_ok and supported and clear
			samples += 1
	observations.route_samples = samples
	check("Central aisle has continuous floor and capsule clearance",route_ok)
	var xr := XROrigin3D.new(); root.add_child(xr)
	var hand := XRController3D.new(); xr.add_child(hand)
	var pickup = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=study.point.global_position
	study.point.pick_up(pickup); await tick()
	check("Museum point attaches to simulated XRTools hand",study.point.is_picked_up())
	for unused in range(3): study.point.action();await tick()
	check("Hand action visits three queue lamps in museum",study.graph.visited==[0,1,2])
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for unused in range(4): await tick()
	check("Museum release retains visits and parks carried point",not study.point.held() and study.point.position.is_equal_approx(study.PARK) and study.graph.visited==[0,1,2])
	xr.hide()
	await snapshot("student-queue",study.to_global(Vector3(0,2,2.65)),study.to_global(Vector3(0,2,0)),68)
	study.restart(false)
	for unused in range(3):study.advance()
	check("Same geometry receives stack order",study.graph.visited==[0,1,3] and study.lamps.size()==7)
	await snapshot("student-stack",study.to_global(Vector3(0,2,2.65)),study.to_global(Vector3(0,2,0)),68)
	await snapshot("study-above",origin+hall.global_basis*Vector3(6.5,23,7),origin+hall.global_basis*Vector3(6.5,0,6),48)
	observations.learner_transform = str(study.global_transform)
	observations.student_bfs_prefix = [0,1,2]
	observations.student_dfs_prefix = study.graph.visited.duplicate()
	study.queue_free(); xr.queue_free(); await tick()
	observations.learner_is_temporary = true

func finish() -> void:
	check("All planned graph room checks completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":completed and failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if completed and failures.is_empty() else 1)
