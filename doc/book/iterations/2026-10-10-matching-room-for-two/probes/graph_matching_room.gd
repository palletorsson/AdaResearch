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
	await snapshot("above",origin+Vector3(7.5,27,27),origin+Vector3(7.5,0,8),55)
	await snapshot("entry",origin+Vector3(7.5,1.7,1.4),origin+Vector3(7.5,1.5,11),70)
	var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	if spec.get("baseline",false):completed=true
	else:await final_checks(origin)
func final_checks(origin:Vector3) -> void:
	var workshop:=find_scene("/GT_Matching/study.gd")
	var atlas:=find_scene("/ada_relations.gd")
	var old:=find_scene("/edmonds_algorithm.gd")
	check("Workshop, sourced atlas and original greedy comparison are installed",workshop!=null and atlas!=null and old!=null)
	if workshop==null or atlas==null or old==null:return
	var good:=true;observations.blocked_samples=[]
	for i in range(29):
		var p:Vector3=origin+hall.global_basis*Vector3(7.5,.012,1+i*.5)
		if floor_at(p).is_empty() or not clear_at(p):good=false;observations.blocked_samples.append(xyz(p))
	check("Central passage has29 supported clear body samples",good)
	for item in [workshop,atlas]:
		var approach:Vector3=item.to_global(Vector3(0,.012,2.3))
		check("Supported clear approach: "+str(item.name),not floor_at(approach).is_empty() and clear_at(approach))
	await workshop_photo(workshop,"workshop-empty")
	workshop.controls[0].pointer_event({"event_type":2});await tick()
	check("Permanent workshop first choice pairs one maker",workshop.model.mate==[2,-1,0,-1])
	await workshop_photo(workshop,"workshop-first")
	workshop.controls[0].pointer_event({"event_type":2});await tick()
	check("Permanent workshop revises the choice and pairs both makers",workshop.model.mate==[3,2,1,0] and workshop.cancelled.visible)
	await workshop_photo(workshop,"workshop-revised")
	old._lesson_reset()
	if old._spokes_first:old._lesson_order()
	for i in range(10):old._lesson_controls.get_node("STEP").pressed.emit()
	check("Original cycle-first greedy comparison stops at three pairs",old.matching_size==3)
	await snapshot("greedy-three",old.to_global(Vector3(0,5,-11)),old.to_global(Vector3(0,0,0)),58)
	old._lesson_controls.get_node("ORDER").pressed.emit()
	for i in range(10):old._lesson_controls.get_node("STEP").pressed.emit()
	check("Original order control yields five spoke-first pairs",old.matching_size==5)
	await snapshot("greedy-five",old.to_global(Vector3(0,5,-11)),old.to_global(Vector3(0,0,0)),58)
	observations.greedy={"cycle_first":3,"spokes_first":5,"general_graph_solver":false}
	observations.atlas=[]
	for i in range(5):
		check("Atlas selected relation: "+atlas.KINDS[i],atlas.mode==i)
		await snapshot("atlas-"+atlas.KINDS[i],atlas.to_global(Vector3(0,4.3,7)),atlas.to_global(Vector3(0,2.0,0)),58)
		observations.atlas.append(atlas.evidence.duplicate(true))
		atlas.controls[0].pointer_event({"event_type":2});await tick()
	atlas.controls[3].pointer_event({"event_type":2});await tick()
	check("Native hall view shows eight graph rooms in order",atlas.shown_nodes.size()==8 and atlas.shown_edges.size()==7)
	await snapshot("atlas-halls",atlas.to_global(Vector3(0,4.3,7)),atlas.to_global(Vector3(0,2.0,0)),58)
	atlas.controls[0].pointer_event({"event_type":2});await tick()
	check("Native prerequisite view has source evidence",not atlas.shown_edges.is_empty() and atlas.shown_edges.all(func(e):return e.kind=="dependency" and not e.evidence.is_empty()))
	await snapshot("atlas-hall-dependencies",atlas.to_global(Vector3(0,4.3,7)),atlas.to_global(Vector3(0,2.0,0)),58)
	atlas.mode=0;atlas.detail=false;atlas.redraw()
	var study=load("res://doc/book/iterations/2026-10-10-matching-room-for-two/printed/study.tscn").instantiate();hall.add_child(study)
	study.global_transform=Transform3D(hall.global_basis*Basis(Vector3.UP,PI),origin+hall.global_basis*Vector3(10,0,5));await tick()
	var approach:Vector3=study.to_global(Vector3(0,.012,2.3))
	check("Exact printed reconstruction has supported clear approach",not floor_at(approach).is_empty() and clear_at(approach))
	var identity:int=study.point.get_instance_id()
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=study.point.global_position;study.point.pick_up(pickup);await tick()
	check("Native XRTools pickup holds the carried point",study.point.held())
	hand.global_position=study.to_global(Vector3(-.3,1.8,.3))
	for i in range(5):await tick()
	study.point.action();await tick()
	check("Moving the maker then triggering pairs one without editing links",study.places[0].distance_to(study.INITIAL[0])>.2 and study.model.size()==1 and study.model.links==[[0,2],[0,3],[1,2]])
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for i in range(5):await tick()
	check("Release preserves point identity and displayed attachment",not study.point.held() and study.point.get_instance_id()==identity and study.point.position.is_equal_approx(study.places[0]+Vector3.UP*.6))
	study.controls[0].pointer_event({"event_type":2});await tick()
	check("Exact printed reconstruction completes its second pair in the museum",study.model.size()==2)
	await workshop_photo(study,"student-revised")
	xr.hide();await snapshot("study-above",origin+Vector3(7.5,27,27),origin+Vector3(7.5,0,8),55)
	await snapshot("study-entry",origin+Vector3(7.5,1.7,1.4),origin+Vector3(7.5,1.5,11),70)
	observations.student_temporary=true;observations.student_transform=str(study.global_transform)
	study.queue_free();xr.queue_free();await tick()
	completed=true
func workshop_photo(item:Node3D,name:String) -> void:
	await snapshot(name,item.to_global(Vector3(0,2.9,3.3)),item.to_global(Vector3(0,1.35,0)),65)
func clear_at(p:Vector3) -> bool:
	var shape:=CapsuleShape3D.new();shape.radius=.24;shape.height=1.65
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform.origin=p+Vector3.UP*.9
	return hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
func finish() -> void:
	check("All planned Matching room checks completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":completed and failures.is_empty(),"completed":completed,"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if completed and failures.is_empty() else 1)
