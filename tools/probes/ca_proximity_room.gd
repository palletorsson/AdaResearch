extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(.7).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:
		player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	var old=museum.get("_cam")
	if old is Node3D:old.hide()
	camera.set_cull_mask_value(19,false)
	var wardrobe=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").hide()
	for child in museum.get_children():
		if child is Node3D and child.has_meta("em_map") and child!=hall:child.hide()
	var work:=find_scene("/decaying_bridge.gd")
	check("Installed proximity bridge found",work!=null)
	if work==null:return
	var study:Node3D=work.get_node("ProximityStudy");study.full_reset();study.source_mode=2;study._refresh()
	observations["work_local"]=xyz(hall.to_local(work.global_position))
	var inventory:Array=[]
	for item in hall.find_children("*","Node3D",true,false):
		if item.has_meta("artifact_lookup_name"):inventory.append({"key":item.get_meta("artifact_lookup_name"),"local":xyz(hall.to_local(item.global_position))})
	observations["inventory"]=inventory
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=38
	camera.global_position=hall.to_global(Vector3(7.5,45,18));camera.look_at(hall.to_global(Vector3(7.5,0,18)),Vector3.FORWARD);camera.current=true
	await create_timer(.4).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"overhead.png"))
	await snapshot("raised-oblique",hall.to_global(Vector3(30,42,43)),hall.to_global(Vector3(7.5,0,18)),60)
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	await snapshot("entry",hall.to_global(Vector3(6.5,1.65,4.2)),study.to_global(Vector3(0,.8,3.5)),80)
	study.source_mode=1;study.probe_near=true
	for i in 21:study.step_once()
	await tick()
	await snapshot("depleted",study.to_global(Vector3(-3.7,1.65,1.8)),study.to_global(Vector3(.7,.65,4.5)),83)
	check("Twenty-one near steps remove W support",work.grid[Vector2i(2,6)]<.2 and work.colliders[Vector2i(2,6)].disabled)
	await snapshot("rear-gallery",hall.to_global(Vector3(6.5,1.65,22.8)),hall.to_global(Vector3(7,1.3,28.5)),88)
	if not folder.contains("/before/"):
		await interaction_checks(work,study)
		check_routes()
		var learner=load("res://doc/book/iterations/2026-10-08-ca-the-surface-includes-you/printed/presence.gd").new()
		hall.add_child(learner);learner.position=Vector3(3,0,18);learner.rotation.y=PI/2
		for i in 21:learner.current=learner.evolve(learner.current,learner.cell_position(Vector2i(2,6)),true)
		learner.ticks=21;learner.redraw();await tick()
		await snapshot("printed-study",hall.to_global(Vector3(5.5,2.15,18.5)),hall.to_global(Vector3(3.6,1.13,18)),65)
		learner.queue_free()
	observations["scope"]="Native museum, overhead and eye level. Player/neighbouring halls hidden for capture. No physical headset."

func interaction_checks(work:Node3D,study:Node3D) -> void:
	var carried=study.get_node_or_null("ProximityHand")
	check("Installed carried PointBody available",carried!=null and carried.point!=null)
	var w:=Vector2i(2,6);study.full_reset();study.source_mode=0;study._refresh()
	var modes:Array=[]
	for i in 4:study.next_source();modes.append(study.source_mode)
	check("Source cycle preserves VISITOR PROBE NONE then adds HAND",modes==[1,2,3,0])
	study.source_mode=3;work.grid[w]=.3;study.step_once()
	check("Unheld HAND uses recovery with no origin fallback",not work.has_visitor and is_equal_approx(work.grid[w],.34) and study.source_label.text.contains("RELEASED"))
	study.full_reset();study.source_mode=1;study.probe_near=true;study.step_once();var probe_state:Dictionary=work.grid.duplicate()
	study.full_reset()
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=carried.point.global_position;carried.point.pick_up(pickup);await tick();await tick()
	controller.global_position=work.to_global(study.probe_position());await tick();await tick()
	carried.point.action();await tick()
	check("Actual XRTools held trigger selects HAND and steps once",carried.point.held() and study.source_mode==3 and study.ticks==1)
	check("Same nominated point produces PROBE and HAND field parity",equal_fields(work.grid,probe_state))
	for i in 20:carried.point.action()
	await tick()
	check("Held input depletes W and removes its collider",is_equal_approx(work.grid[w],.16) and work.colliders[w].disabled)
	await snapshot("carried-input",study.to_global(Vector3(-2,1.65,2.4)),study.to_global(Vector3(.6,.75,4)),88)
	controller.global_position=work.to_global(Vector3(0,2,3.6));await tick();await tick();study._refresh()
	check("Moving hand upward changes three-dimensional input distance",study.last_distance>2 and work.has_visitor)
	carried.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick();study._refresh()
	check("Release parks beside console and withdraws input",not work.has_visitor and carried.point.position.is_equal_approx(Vector3(-4.05,1.08,-1.6)))
	for i in 60:study.step_once()
	check("Released hand permits boundary-led repair",work.grid[w]>.5)
	origin.queue_free();await tick()
	var materials:=true
	for site in work.grid:
		var panel=study.get_node("HealthPanel_%d_%d"%[site.x,site.y])
		materials=materials and is_same(panel.material_override,work.materials[site])
	check("All eighty wall cells share corresponding floor material",materials)
	study.chain();study.step_once()
	check("Installed SYNC chain waits at third address",is_equal_approx(work.grid[w],.505) and work.grid[Vector2i(3,6)]==0)
	study.toggle_order();study.step_once()
	check("Installed SCAN propagates within the pass",is_equal_approx(work.grid[Vector2i(3,6)],.01))
	study.toggle_reverse();study.step_once()
	check("Installed reversed SCAN postpones that change",work.grid[Vector2i(3,6)]==0)
	work.synchronous_updates=true;work.reverse_scan=false;study.full_reset();study.source_mode=2
	study.toggle_run();study._process(.1);study.running=false
	check("RUN advances a tenth of a simulated second",study.ticks==1)
	for i in 310:study.step_once()
	check("Installed thirty-second capacity holds",study.ticks==300 and not study.running)
	await body_checks(work,study)
	study.full_reset();study.source_mode=2;study._refresh();await tick()
	observations["step_ms"]=study.last_step_usec/1000.0

func equal_fields(a:Dictionary,b:Dictionary) -> bool:
	for site in a:
		if absf(a[site]-b[site])>1e-8:return false
	return a.size()==b.size()

func body_checks(work:Node3D,study:Node3D) -> void:
	study.full_reset();study.source_mode=0
	var walker:=CharacterBody3D.new();hall.add_child(walker);walker.add_to_group("em_walker")
	var boundary:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=.28;capsule.height=1.7
	boundary.shape=capsule;boundary.position.y=.88;walker.add_child(boundary)
	var eye:=Camera3D.new();walker.add_child(eye);eye.position.y=1.65;eye.current=true
	walker.global_position=work.to_global(Vector3(0,0,3.6));await tick()
	check("VISITOR resolves supplied physical body rather than capture camera",work.resolve_visitor()==walker)
	for i in 21:study.step_once()
	for i in 90:
		await physics_frame;walker.velocity+=Vector3.DOWN*9.8/60;walker.move_and_slide()
	var at:Vector3=work.to_local(walker.global_position)
	check("A supplied body falls onto collecting basin after support loss",at.y<-.5 and at.y>-.68)
	observations["body_basin_y"]=at.y
	study.source_mode=2
	for site in work.grid:work.grid[site]=0.0
	work._update_visuals();await tick()
	walker.global_position=work.to_global(Vector3(-2.02,-.55,8.0));walker.velocity=Vector3.ZERO
	for i in 155:
		await physics_frame;walker.velocity.x=0;walker.velocity.z=1.0;walker.velocity.y-=9.8/60;walker.move_and_slide()
	at=work.to_local(walker.global_position)
	check("Supplied body climbs exit recovery ramp to level museum floor",at.z>9.55 and at.y>-.06 and at.y<.06)
	observations["ramp_exit_position"]=xyz(at)
	walker.queue_free();camera.current=true;await tick()

func check_routes() -> void:
	var routes:Dictionary={
		"entry_to_console":[Vector2(6.5,3.5),Vector2(6.5,5.7),Vector2(4.8,5.7)],
		"console_to_point":[Vector2(4.8,5.7),Vector2(3.45,5.7),Vector2(3.45,6.3)],
		"side_to_rear":[Vector2(3.45,6.3),Vector2(2.7,6.3),Vector2(2.7,8),Vector2(3.9,8),Vector2(3.9,20.4),Vector2(6.5,20.4),Vector2(6.5,27)],
		"rear_to_exit":[Vector2(6.5,27),Vector2(6.5,31.5)]}
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7;var results:Dictionary={}
	for label in routes:
		var points:Array=routes[label];var blocked:Array=[];var unsupported:Array=[];var samples:=0
		for i in range(1,points.size()):
			var a:Vector2=points[i-1];var b:Vector2=points[i];var count:=ceili(a.distance_to(b)/.15)
			for j in range(count+1):
				var p:=a.lerp(b,float(j)/count);var foot:=hall.to_global(Vector3(p.x,0,p.y))
				var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform=Transform3D(Basis.IDENTITY,foot+Vector3.UP*.88)
				var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query,8)
				if not hits.is_empty():blocked.append({"at":[p.x,p.y],"node":str(hits[0].collider.get_path())})
				var ground:=floor_at(foot)
				if ground.is_empty() or absf(ground.position.y-foot.y)>.03:unsupported.append([p.x,p.y])
				samples+=1
		results[label]={"samples":samples,"blocked":blocked,"unsupported":unsupported}
		check(label+": capsule clearance",blocked.is_empty());check(label+": continuous level floor",unsupported.is_empty())
	observations["routes"]=results
	var stream=museum.get("_portal_stream")
	check("Entry frame has supported approach",not stream.get("_entry").is_empty() and not stream.get("_entry").get("invalid",false))
	check("Exit frame has supported approach",not stream.get("_exit").is_empty() and not stream.get("_exit").get("invalid",false))
func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	print("CA PROXIMITY ROOM ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
