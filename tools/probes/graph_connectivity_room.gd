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
	var exhibit:=find_scene("/tarjan_algorithm.gd")
	observations.primary_present=exhibit!=null
	observations.hall_position=xyz(hall.global_position)
	await snapshot("above",origin+Vector3(7,22,18),origin+Vector3(7,0,5),58)
	await snapshot("entry",origin+Vector3(6,1.7,1.5),origin+Vector3(7,1.4,7),65)
	if spec.get("baseline",false):completed=true;return
	check("Existing Tarjan exhibit present",exhibit!=null)
	if exhibit==null:return
	await final_checks(origin,exhibit)
	completed=true
func final_checks(origin:Vector3,exhibit:Node3D) -> void:
	check("Tarjan uses twelve vertices arranged as two directed rings",exhibit.mutuality=="split" and exhibit.vertices.size()==12)
	exhibit.set_process(false);exhibit.algorithm_running=false;exhibit.start_algorithm()
	var steps:=0
	while exhibit.algorithm_running and steps<2000:
		exhibit.process_tarjan_step();steps+=1
	var components:Array=[]
	for members:Array in exhibit.sccs:
		var group:=members.duplicate();group.sort();components.append(group)
	var left:=["v0","v1","v2","v3","v4","v5"]
	var right:=["v10","v11","v6","v7","v8","v9"]
	check("Real Tarjan traversal completes with two independently expected groups",not exhibit.algorithm_running and components.size()==2 and left in components and right in components)
	check("Museum rings have one-way crossing and no invented return",exhibit.has_edge("v0","v6") and not exhibit.has_edge("v6","v0"))
	check("Completed traversal empties unresolved stack",exhibit.stack.is_empty() and exhibit.scc_count==2)
	observations.tarjan_steps=steps;observations.components=components;observations.exhibit_transform=str(exhibit.global_transform)
	await snapshot("tarjan-rings",origin+Vector3(10.5,4.8,2.7),exhibit.global_position,60)
	var good:=true;observations.blocked_samples=[];observations.route_samples=0
	for z in range(3,18):
		var p:Vector3=origin+hall.global_basis*Vector3(6.5,.012,z*.5)
		if floor_at(p).is_empty() or not clear_at(p):observations.blocked_samples.append(xyz(p));good=false
		observations.route_samples+=1
	check("Central passage has continuous supported body clearance",good)
	var approach:Vector3=origin+hall.global_basis*Vector3(10.5,.012,4.8)
	check("Tarjan comparison has supported clear approach",not floor_at(approach).is_empty() and clear_at(approach))
	var study=load("res://doc/book/iterations/2026-10-10-connectivity-a-way-back/printed/study.tscn").instantiate();hall.add_child(study)
	study.global_transform=Transform3D(hall.global_basis*Basis(Vector3.UP,PI),origin+hall.global_basis*Vector3(3.5,-.25,5.5))
	await tick()
	approach=study.to_global(Vector3(0,.262,1.3))
	check("Learner point and controls have a supported clear approach",not floor_at(approach).is_empty() and clear_at(approach))
	check("Exact printed learner starts with singleton4",study.ledger.component(4)==[4] and study.point.held()==false)
	await snapshot("student-before",study.to_global(Vector3(0,1.9,3.25)),study.to_global(Vector3(0,1.8,0)),63)
	study.controls[1].pointer_event({"event_type":2});await tick()
	check("Actual RETURN pointer press joins1,4,5 and reveals new arrow",study.ledger.component(4)==[1,4,5] and study.rods[7].visible and "included" in study.source_label.text)
	await snapshot("student-return",study.to_global(Vector3(0,1.9,3.25)),study.to_global(Vector3(0,1.8,0)),63)
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=study.point.global_position;study.point.pick_up(pickup);await tick()
	check("Carried point attaches to actual XRTools pickup",study.point.is_picked_up())
	hand.global_position=study.to_global(Vector3(-.2,2.2,.4))
	for i in range(5):await tick()
	check("Held point moves drawing while preserving mutual reachability",study.places[4].distance_to(study.INITIAL[4])>.2 and study.ledger.component(4)==[1,4,5])
	study.point.action();await tick()
	check("Held trigger omits return and restores singleton",study.ledger.component(4)==[4] and not study.rods[7].visible)
	study.point.action();await tick()
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for i in range(5):await tick()
	xr.hide()
	check("Release returns same point to selected drawing plane",not study.point.held() and study.point.position.is_equal_approx(study.places[4]+study.FRONT))
	await snapshot("student-moved",study.to_global(Vector3(0,1.9,3.25)),study.to_global(Vector3(0,1.8,0)),63)
	study.controls[0].pointer_event({"event_type":2})
	for i in range(5):await tick()
	check("START selects5 and preserves shared component",study.start==5 and study.ledger.component(5)==[1,4,5] and study.point.position.is_equal_approx(study.places[5]+study.FRONT))
	study.controls[0].pointer_event({"event_type":2});await tick()
	check("START6 stays outside the component",study.start==6 and study.ledger.component(6)==[6])
	study.reset();study.toggle_record();await tick()
	await snapshot("study-above",origin+Vector3(7,24,17),origin+Vector3(7,0,5),55)
	observations.learner_is_temporary=true;observations.learner_transform=str(study.global_transform)
	study.queue_free();xr.queue_free();await tick()
func clear_at(p:Vector3) -> bool:
	var shape:=CapsuleShape3D.new();shape.radius=.24;shape.height=1.65
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform.origin=p+Vector3.UP*.9
	return hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
func finish() -> void:
	check("All planned connectivity room checks completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":completed and failures.is_empty(),"completed":completed,"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if completed and failures.is_empty() else 1)
