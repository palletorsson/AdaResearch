extends "res://tools/probes/transformation_encounters.gd"
var completed:=false
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.process_mode=Node.PROCESS_MODE_DISABLED;player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes:=CameraAttributesPractical.new();attributes.exposure_multiplier=.35;camera.attributes=attributes
	var origin:Vector3=hall.to_global(Vector3(0,0,4))
	await snapshot("above",origin+Vector3(6.5,24,23),origin+Vector3(6.5,0,6),55)
	await snapshot("entry",origin+Vector3(6.5,1.7,1.4),origin+Vector3(6.5,1.5,8),70)
	var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	if not spec.get("baseline",false):await final_checks(origin)
	completed=true
func final_checks(origin:Vector3) -> void:
	var gallery:=find_scene("/graph_worlds.gd")
	var old:=find_scene("/push_relabel.gd")
	check("Permanent context gallery and original forward-only comparison are installed",gallery!=null and old!=null)
	if gallery==null or old==null:return
	check("Gallery starts with Flow harbour and all eleven contexts",gallery.cases.size()==11 and gallery.cases[gallery.selected].id=="harbour")
	old.algorithm_running=false;old._run_gen+=1;old.initialize_preflow()
	var balance:=0
	for amount in old.excess.values():balance+=int(amount)
	check("Original preflow preserves signed excess balance",balance==0 and old.excess[old.source]<0)
	old.step_by_step=false;old.start_algorithm()
	for i in range(300):
		await tick()
		if not old.algorithm_running:break
	check("Forward-only comparison terminates and reports its limited result",not old.algorithm_running and ("BLOCKED" in old.operation_label.text or "maximum not established" in old.operation_label.text))
	observations.forward_only={"operation":old.operation_label.text,"sink_receipt":old.max_flow,"excess":old.excess.duplicate(),"maximum_claimed":false}
	await snapshot("forward-only",origin+Vector3(8,3.4,6.5),old.global_position,55)
	var good:=true;observations.blocked_samples=[]
	for n in range(19):
		var p:Vector3=origin+hall.global_basis*Vector3(6.5,.012,1+n*.5)
		if floor_at(p).is_empty() or not clear_at(p):good=false;observations.blocked_samples.append(xyz(p))
	check("Central route has19 supported clear body samples",good)
	var approach:Vector3=gallery.to_global(Vector3(0,.012,2.1))
	check("Context controls have a supported clear approach",not floor_at(approach).is_empty() and clear_at(approach))
	observations.gallery_transform=str(gallery.global_transform);observations.contexts=[]
	for i in range(gallery.cases.size()):
		gallery.select_case(i);await tick()
		var id:String=gallery.cases[i].id
		await snapshot("context-"+id+"-before",gallery.to_global(Vector3(0,3.5,5.5)),gallery.to_global(Vector3(0,1.5,0)),58)
		var repeats:=10 if id=="pipes" else (8 if id=="contact" else (2 if id in ["harbour","future"] else 1))
		for j in range(repeats):gallery.controls[1].pointer_event({"event_type":2})
		await tick()
		check("Actual Try It advances concrete context: "+id,gallery.phase==repeats and gallery.evidence.case_id==id)
		observations.contexts.append(gallery.evidence.duplicate(true))
		await snapshot("context-"+id+"-after",gallery.to_global(Vector3(0,3.5,5.5)),gallery.to_global(Vector3(0,1.5,0)),58)
	gallery.select_case(6);gallery.controls[2].pointer_event({"event_type":2});check("NEXT selects workshop",gallery.selected==7)
	gallery.controls[0].pointer_event({"event_type":2});check("PREVIOUS returns to harbour",gallery.selected==6)
	gallery.act();gallery.controls[3].pointer_event({"event_type":2});check("RESET restores empty harbour",gallery.phase==0 and gallery.evidence.total==0)
	var study=load("res://doc/book/iterations/2026-10-10-flow-room-for-another/printed/study.tscn").instantiate();hall.add_child(study)
	study.global_transform=Transform3D(hall.global_basis*Basis(Vector3.UP,PI),origin+hall.global_basis*Vector3(9,0,3.8))
	await tick();approach=study.to_global(Vector3(0,.012,1.7))
	check("Printed learner has supported clear approach",not floor_at(approach).is_empty() and clear_at(approach))
	await student_photo(study,"student-empty")
	study.controls[0].pointer_event({"event_type":2});await tick()
	check("Native printed harbour first allocation is one",study.model.total==1 and study.model.flow[1][3]==1)
	await student_photo(study,"student-first")
	study.controls[0].pointer_event({"event_type":2});await tick()
	check("Native second allocation cancels1-3 and reaches two",study.model.total==2 and study.model.flow[1][3]==0 and study.cancelled.visible)
	await student_photo(study,"student-revised")
	study.reset();await tick();var identity:int=study.point.get_instance_id()
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=study.point.global_position;study.point.pick_up(pickup);await tick()
	check("Existing XRTools pickup holds carried point",study.point.is_picked_up())
	hand.global_position=study.to_global(Vector3(.25,1.5,.9))
	for i in range(5):await tick()
	study.point.action();await tick()
	check("Hand moves yard and trigger allocates without changing capacity",study.places[4].distance_to(study.INITIAL[4])>.2 and study.model.total==1 and study.model.capacity[5][6]==2)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for i in range(5):await tick()
	check("Release keeps same point on the harbour plan",not study.point.held() and study.point.get_instance_id()==identity and study.point.position.is_equal_approx(study.places[4]+Vector3.UP*.24))
	xr.hide();study.reset();study.advance();study.advance();await tick()
	gallery.act();gallery.act()
	await snapshot("study-above",origin+Vector3(6.5,24,23),origin+Vector3(6.5,0,6),55)
	await snapshot("study-entry",origin+Vector3(6.5,1.7,1.4),origin+Vector3(6.5,1.5,8),70)
	observations.student_temporary=true;observations.student_transform=str(study.global_transform)
	study.queue_free();xr.queue_free();await tick()
func student_photo(study:Node3D,name:String) -> void:
	await snapshot(name,study.to_global(Vector3(0,2.6,2.65)),study.to_global(Vector3(0,1.35,0)),75)
func clear_at(p:Vector3) -> bool:
	var shape:=CapsuleShape3D.new();shape.radius=.24;shape.height=1.65
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform.origin=p+Vector3.UP*.9
	return hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
func finish() -> void:
	check("All planned flow room checks completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":completed and failures.is_empty(),"completed":completed,"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if completed and failures.is_empty() else 1)
