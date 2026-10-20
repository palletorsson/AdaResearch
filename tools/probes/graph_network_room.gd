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
	var exhibit:=find_scene("/evidence_network.gd")
	observations.primary_present=exhibit!=null
	observations.hall_position=xyz(hall.global_position)
	await snapshot("above",origin+Vector3(11.5,43,43),origin+Vector3(11.5,0,17),58)
	await snapshot("entry",origin+Vector3(6.5,1.7,1.5),origin+Vector3(8,1.4,12),65)
	if spec.get("baseline",false):completed=true;return
	check("Authored record wall is present",exhibit!=null)
	if exhibit==null:return
	await final_checks(origin,exhibit)
	completed=true
func final_checks(origin:Vector3,exhibit:Node3D) -> void:
	var station:Node3D=exhibit.get_parent()
	check("Museum wall has eight named institutions and twelve source records",exhibit.NAMES.size()==8 and exhibit.RECORDS.size()==12)
	var before:Array=wall_counts(exhibit)
	check("Builder has two incoming payment records in the full ledger",exhibit.degree(4)==Vector2i(2,1))
	await snapshot("record-wall",station.to_global(Vector3(0,3.4,7.5)),station.to_global(Vector3(0,3.2,-4)),68)
	station.controls[0].pointer_event({"event_type":2});await tick()
	check("Actual museum LAYOUT button moves drawing without changing counts",exhibit.arrangement==1 and wall_counts(exhibit)==before)
	station.controls[1].pointer_event({"event_type":2});station.controls[1].pointer_event({"event_type":2});await tick()
	check("Actual FILTER button selects four payment records",exhibit.filter_index==2 and exhibit.visible_edges()==[2,3,4,11])
	check("Builder payment count excludes its outgoing report",exhibit.degree(4)==Vector2i(2,0))
	station.controls[2].pointer_event({"event_type":2});await tick()
	check("RECORD button exposes a source belonging to the selected relation",str(exhibit.RECORDS[exhibit.selected][4]) in exhibit.record_label.text)
	station.controls[3].pointer_event({"event_type":2});await tick()
	check("NODE button changes the measured institution",exhibit.selected_node==1 and "Studio" in exhibit.measure_label.text)
	await snapshot("record-wall-filter",station.to_global(Vector3(0,3.4,7.5)),station.to_global(Vector3(0,3.2,-4)),68)
	station.controls[-1].pointer_event({"event_type":2});await tick()
	check("Museum RESET restores all source records and arrangement",exhibit.filter_index==0 and exhibit.arrangement==0 and exhibit.selected==0 and exhibit.selected_node==0 and wall_counts(exhibit)==before)
	var approach:Vector3=station.to_global(Vector3(0,.012,6.2))
	check("Record-wall console has supported clear approach",not floor_at(approach).is_empty() and clear_at(approach))
	var good:=true;observations.blocked_samples=[];observations.route_samples=0
	for z in range(3,63):
		var p:Vector3=origin+hall.global_basis*Vector3(6.5,.012,z*.5)
		if floor_at(p).is_empty() or not clear_at(p):observations.blocked_samples.append(xyz(p));good=false
		observations.route_samples+=1
	for x in range(13,24):
		var p:Vector3=origin+hall.global_basis*Vector3(x*.5,.012,31.5)
		if floor_at(p).is_empty() or not clear_at(p):observations.blocked_samples.append(xyz(p));good=false
		observations.route_samples+=1
	check("Left aisle and turn to existing rear exit have continuous supported clearance",good)
	var study=load("res://doc/book/iterations/2026-10-10-network-a-record-counted/printed/study.tscn").instantiate();hall.add_child(study)
	study.global_transform=Transform3D(hall.global_basis*Basis(Vector3.UP,PI),origin+hall.global_basis*Vector3(4.5,-.25,6.5))
	await tick()
	approach=study.to_global(Vector3(0,.262,1.3))
	check("Learner point and controls have a clear supported approach",not floor_at(approach).is_empty() and clear_at(approach))
	check("Exact printed learner starts with expected counts",study.ledger.counts(4)==Vector2i(1,1) and study.ledger.counts(5)==Vector2i(2,0))
	await snapshot("student-before",study.to_global(Vector3(0,1.85,3.1)),study.to_global(Vector3(0,1.8,0)),60)
	study.controls[1].pointer_event({"event_type":2});await tick()
	check("Learner pointer button omits P04 without destroying it",study.ledger.counts(4)==Vector2i(1,0) and study.ledger.counts(5)==Vector2i(1,0) and study.ledger.records.size()==7 and not study.rods[6].visible)
	await snapshot("student-omitted",study.to_global(Vector3(0,1.85,3.1)),study.to_global(Vector3(0,1.8,0)),60)
	study.reset();await tick()
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=study.point.global_position;study.point.pick_up(pickup);await tick()
	check("Carried point attaches to actual XRTools pickup function",study.point.is_picked_up())
	var saved:Array=learner_counts(study)
	hand.global_position=study.to_global(Vector3(-.2,2.4,.4))
	for unused in range(5):await tick()
	check("Moving the held point changes drawing but preserves counts",study.places[4].distance_to(study.INITIAL[4])>.2 and learner_counts(study)==saved)
	study.point.action();await tick()
	check("Inherited point trigger switches to payments in museum",study.ledger.filter_kind=="payment" and study.ledger.counts(5)==Vector2i(1,0))
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for unused in range(5):await tick()
	xr.hide()
	check("Release leaves same point on the diagram plane",not study.point.held() and study.point.position.is_equal_approx(study.places[4]+study.FRONT))
	await snapshot("student-moved",study.to_global(Vector3(0,1.85,3.1)),study.to_global(Vector3(0,1.8,0)),60)
	study.reset();await tick()
	await snapshot("study-above",origin+Vector3(11.5,43,43),origin+Vector3(11.5,0,17),58)
	observations.learner_is_temporary=true;observations.learner_transform=str(study.global_transform);observations.wall_transform=str(station.global_transform)
	study.queue_free();xr.queue_free();await tick()
func wall_counts(exhibit) -> Array:
	var out:Array=[]
	for id in range(exhibit.NAMES.size()):out.append(exhibit.degree(id))
	return out
func learner_counts(study) -> Array:
	var out:Array=[]
	for id in range(7):out.append(study.ledger.counts(id))
	return out
func clear_at(p:Vector3) -> bool:
	var shape:=CapsuleShape3D.new();shape.radius=.24;shape.height=1.65
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform.origin=p+Vector3.UP*.9
	return hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
func finish() -> void:
	check("All planned network room checks completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":completed and failures.is_empty(),"completed":completed,"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if completed and failures.is_empty() else 1)
