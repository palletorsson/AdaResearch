extends "res://tools/probes/transformation_encounters.gd"
var completed:=false
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream= museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.process_mode=Node.PROCESS_MODE_DISABLED;player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes:=CameraAttributesPractical.new();attributes.exposure_multiplier=.35;camera.attributes=attributes
	var origin:Vector3=hall.to_global(Vector3(0,0,4))
	var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	var exhibit:=find_scene("/mst_visualization.gd")
	observations.primary_present=exhibit!=null
	observations.hall_position=xyz(hall.global_position)
	await snapshot("above",origin+Vector3(7.5,30,29),origin+Vector3(7.5,0,8),58)
	await snapshot("entry",origin+Vector3(7.5,1.7,1.5),origin+Vector3(7.5,2.5,10),65)
	if spec.get("baseline",false):completed=true;return
	check("Existing MST exhibit present",exhibit!=null)
	if exhibit==null:return
	await final_checks(origin,exhibit)
	completed=true
func minimum_cost(exhibit) -> float:
	# Independent Prim cut search; production uses Kruskal/union-find.
	var visited:Array[int]=[0]
	var total:=0.0
	while visited.size()<exhibit.vertices.size():
		var best:=INF
		var next:=-1
		for edge:Dictionary in exhibit.edges:
			if (edge.from in visited)==(edge.to in visited):continue
			if float(edge.weight)<best:
				best=edge.weight;next=edge.to if edge.from in visited else edge.from
		if next<0:return INF
		visited.append(next);total+=best
	return total
func final_checks(origin:Vector3,exhibit:Node3D) -> void:
	check("Existing comparison uses ten vertices, Kruskal and distance weights",exhibit.vertices.size()==10 and exhibit.algorithm_type=="kruskal" and exhibit.use_euclidean_weights)
	check("Production desktop overlay remains disabled",not exhibit._desktop_ui)
	exhibit.is_computing=false;exhibit.start_mst_computation();exhibit.computation_timer.stop()
	var steps:=0
	while not exhibit.computation_complete and steps<exhibit.edges.size()+2:
		exhibit.step_kruskal();steps+=1
	var expected:=minimum_cost(exhibit)
	check("Real comparison finishes with nine selected edges",exhibit.computation_complete and exhibit.mst_edges.size()==9)
	check("Real Kruskal cost agrees with independent Prim cut search",is_equal_approx(exhibit.mst_cost,expected))
	var distances:=true
	for edge:Dictionary in exhibit.edges:
		var a:Vector3=exhibit.vertices[edge.from].position
		var b:Vector3=exhibit.vertices[edge.to].position
		distances=distances and is_equal_approx(edge.weight,a.distance_to(b))
	check("Displayed production weights are source-coordinate distances",distances)
	observations.comparison={"steps":steps,"selected":exhibit.mst_edges.size(),"rejected":exhibit.rejected_edges.size(),"cost":exhibit.mst_cost,"independent_cost":expected,"transform":str(exhibit.global_transform)}
	await snapshot("museum-tree",origin+Vector3(10.7,2.8,4.7),exhibit.global_position,60)
	var good:=true;observations.blocked_samples=[];observations.route_samples=0
	for n in range(29):
		var p:Vector3=origin+hall.global_basis*Vector3(7.5,.012,1.5+n*.5)
		if floor_at(p).is_empty() or not clear_at(p):observations.blocked_samples.append(xyz(p));good=false
		observations.route_samples+=1
	check("Central passage has continuous supported body clearance",good)
	var approach:Vector3=origin+hall.global_basis*Vector3(11.5,.012,7.8)
	check("MST comparison has supported clear approach",not floor_at(approach).is_empty() and clear_at(approach))
	var study=load("res://doc/book/iterations/2026-10-10-spanning-the-cost-of-a-spare/printed/study.tscn").instantiate();hall.add_child(study)
	study.global_transform=Transform3D(hall.global_basis*Basis(Vector3.UP,PI),origin+hall.global_basis*Vector3(4,-.25,6))
	await tick()
	approach=study.to_global(Vector3(0,.262,1.3))
	check("Learner point and controls have supported clear approach",not floor_at(approach).is_empty() and clear_at(approach))
	check("Exact printed learner begins with seven IDs and eight unselected links",study.lamps.size()==7 and study.model.links.size()==8 and study.model.chosen.is_empty())
	await study_photo(study,"student-before")
	for i in range(8):study.controls[0].pointer_event({"event_type":2})
	await tick()
	check("Actual STEP presses build cost21 tree and refuse two cycles",study.model.spans() and is_equal_approx(study.model.cost(study.model.chosen),21.0) and study.model.refused==[6,7])
	await study_photo(study,"student-tree")
	study.controls[1].pointer_event({"event_type":2});await tick()
	var reached:Array[int]=study.model.reachable(study.active_links(),0);reached.sort()
	check("BREAK hides0-1 and strands exactly1,3,4",not study.rods[0].visible and reached==[0,2,5,6])
	await study_photo(study,"student-break")
	study.controls[2].pointer_event({"event_type":2});await tick()
	check("SPARE restores all seven without changing chosen tree",study.model.reachable(study.active_links(),0).size()==7 and study.model.chosen==[2,1,3,0,5,4] and "spare" in study.weights[6].text)
	await study_photo(study,"student-spare")
	study.reset();await tick()
	var identity:int=study.point.get_instance_id()
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=study.point.global_position;study.point.pick_up(pickup);await tick()
	check("Carried point attaches to actual XRTools pickup",study.point.is_picked_up())
	hand.global_position=study.to_global(Vector3(-.25,2.2,.4))
	for i in range(5):await tick()
	check("Held point changes drawing without changing build costs",study.places[4].distance_to(study.INITIAL[4])>.2 and is_equal_approx(study.model.links[6].cost,7.0) and study.model.chosen.is_empty())
	study.point.action();await tick()
	check("Held trigger considers next cost-ordered edge",study.model.chosen==[2] and study.model.cursor==1)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for i in range(5):await tick()
	xr.hide()
	check("Release parks the same point in the drawing plane",not study.point.held() and study.point.get_instance_id()==identity and study.point.position.is_equal_approx(study.places[4]+study.FRONT))
	while not study.model.complete():study.advance()
	check("Moving the drawing leaves the selected tree unchanged",study.model.chosen==[2,1,3,0,5,4])
	await study_photo(study,"student-moved")
	study.reset()
	while not study.model.complete():study.advance()
	study.toggle_break();study.toggle_spare();await tick()
	await snapshot("study-above",origin+Vector3(7.5,30,29),origin+Vector3(7.5,0,8),58)
	await snapshot("study-entry",origin+Vector3(7.5,1.7,1.5),origin+Vector3(7.5,2.2,9),65)
	observations.learner_is_temporary=true;observations.learner_transform=str(study.global_transform)
	study.queue_free();xr.queue_free();await tick()
func study_photo(study:Node3D,name:String) -> void:
	await snapshot(name,study.to_global(Vector3(0,1.9,3.25)),study.to_global(Vector3(0,1.8,0)),63)
func clear_at(p:Vector3) -> bool:
	var shape:=CapsuleShape3D.new();shape.radius=.24;shape.height=1.65
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform.origin=p+Vector3.UP*.9
	return hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
func finish() -> void:
	check("All planned spanning room checks completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":completed and failures.is_empty(),"completed":completed,"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if completed and failures.is_empty() else 1)
