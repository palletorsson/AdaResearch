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
	var artifact := find_scene("/ForceDirectedLayout.gd")
	observations.primary_present = artifact != null
	observations.hall_position = xyz(hall.global_position)
	observations.placements = []
	for node in hall.find_children("*","Node3D",true,false):
		if node.get_script() != null and "graph" in str(node.get_script().resource_path):
			observations.placements.append({"script":str(node.get_script().resource_path),"position":xyz(node.global_position),"scale":xyz(node.scale)})
	var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	if spec.get("baseline",false):
		await snapshot("above",hall.to_global(Vector3(7.5,24,19)),hall.to_global(Vector3(7.5,0,8)),60)
		await snapshot("entry",hall.to_global(Vector3(7.5,1.7,4.5)),hall.to_global(Vector3(7.5,1.4,12)),65)
		completed=true
		return
	check("Existing eight-vertex layout is installed",artifact!=null)
	if artifact==null:return
	observations.primary_position=xyz(artifact.global_position)
	observations.primary_scale=xyz(artifact.scale)
	var origin:Vector3=artifact.global_position-hall.global_basis*Vector3(10.5,2.4,7.5)
	observations.map_origin=xyz(origin)
	check("Primary exhibit is elevated above floor at intended scale",is_equal_approx(artifact.global_position.y,2.4) and is_equal_approx(artifact.scale.x,.3))
	check("Installed graph has eight vertices and twelve fixed edges",artifact.nodes.size()==8 and artifact.edges.size()==12)
	var degree:Array[int]=[];degree.resize(8);degree.fill(0)
	for edge in artifact.edges:degree[edge.from_id]+=1;degree[edge.to_id]+=1
	check("Every installed vertex has the three neighbours named by reflection",degree==[3,3,3,3,3,3,3,3])
	var old:Array=[]
	for node in artifact.nodes:old.append(node.position)
	await create_timer(.5).timeout
	var moving:=false
	for i in range(old.size()):moving=moving or not old[i].is_equal_approx(artifact.nodes[i].position)
	check("Existing force simulation runs in museum",moving)
	await snapshot("above",origin+hall.global_basis*Vector3(7.5,22,16),origin+hall.global_basis*Vector3(7.5,0,6),60)
	await snapshot("entry",origin+hall.global_basis*Vector3(7.5,1.7,1.5),origin+hall.global_basis*Vector3(8.5,1.8,8),68)
	await snapshot("installed-layout",origin+hall.global_basis*Vector3(10.5,2.6,2.7),origin+hall.global_basis*Vector3(10.5,2.4,7.5),65)
	var study=load("res://doc/book/iterations/2026-10-10-layout-the-same-connections/printed/study.tscn").instantiate()
	hall.add_child(study)
	study.global_transform=Transform3D(hall.global_basis*Basis(Vector3.UP,PI),origin+hall.global_basis*Vector3(4.5,-.45,4.5))
	await tick()
	check("Exact printed learner initializes in existing museum",study.numbers.size()==7 and study.rods.size()==6)
	check("Learner point begins at a reachable height",study.point.global_position.y>1.2 and study.point.global_position.y<1.9)
	var approach:Vector3=study.to_global(Vector3(0,.46,1.2))
	check("Learner bay has supported clear approach",not floor_at(approach).is_empty() and clear_at(approach))
	var primary_approach:Vector3=origin+hall.global_basis*Vector3(10.5,.01,5.5)
	check("Primary exhibit has supported clear approach",not floor_at(primary_approach).is_empty() and clear_at(primary_approach))
	var good:=true;observations.blocked_samples=[];observations.route_samples=0
	for z in range(2,24):
		for x in [7.0,7.5,8.0]:
			var p:Vector3=origin+hall.global_basis*Vector3(x,.01,z*.5)
			var supported:=not floor_at(p).is_empty();var clear:=clear_at(p)
			if not supported or not clear:observations.blocked_samples.append({"at":xyz(p),"floor":supported,"clear":clear})
			good=good and supported and clear;observations.route_samples+=1
	check("Central aisle has continuous floor and capsule clearance",good)
	study.running=false
	study.refresh_caption()
	await snapshot("student-before",study.to_global(Vector3(0,2.05,2.6)),study.to_global(Vector3(0,2,0)),68)
	var xr:=XROrigin3D.new();root.add_child(xr)
	var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=study.point.global_position;study.point.pick_up(pickup);await tick()
	hand.global_position=study.to_global(Vector3(.65,1.7,.3))
	for unused in range(4):await tick()
	var local:Vector3=study.to_local(study.point.global_position)
	check("Museum XRTools hand pins zero in the local drawing plane",study.point.held() and study.drawing.positions[0].is_equal_approx(Vector3(local.x,local.y,0)))
	study.point.action();await tick()
	check("Held trigger resumes the museum learner simulation",study.running)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	await create_timer(1).timeout
	check("Released point follows its graph vertex",not study.point.held() and study.point.position.distance_to(study.drawing.positions[0])<.01)
	check("Museum movement retains both visit orders",study.visit_order(true)==[0,1,2,3,4,5,6] and study.visit_order(false)==[0,1,3,4,2,5,6])
	xr.hide();study.running=false
	study.refresh_caption()
	await snapshot("student-after",study.to_global(Vector3(0,2.05,2.6)),study.to_global(Vector3(0,2,0)),68)
	await snapshot("study-above",origin+hall.global_basis*Vector3(7.5,22,14),origin+hall.global_basis*Vector3(7.5,0,6),58)
	observations.learner_transform=str(study.global_transform)
	observations.learner_is_temporary=true
	study.queue_free();xr.queue_free();await tick()
	completed = true
func clear_at(p:Vector3) -> bool:
	var shape:=CapsuleShape3D.new();shape.radius=.24;shape.height=1.65
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform.origin=p+Vector3.UP*.9
	return hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
func finish() -> void:
	check("All planned layout room checks completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":completed and failures.is_empty(),"completed":completed,"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if completed and failures.is_empty() else 1)
