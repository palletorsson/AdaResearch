extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(.7).timeout
	var stream= museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var walker=museum.get("_player")
	if walker is Node3D:
		walker.hide();walker.set_process(false);walker.set_physics_process(false);walker.global_position=Vector3(0,-100,0)
	var old=museum.get("_cam")
	if old is Node3D:old.hide()
	camera.set_cull_mask_value(19,false)
	var wardrobe=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").hide()
	for child in museum.get_children():
		if child is Node3D and child.has_meta("em_map") and child!=hall:child.hide()
	var work:=find_scene("/ca_bridge.gd")
	check("Installed history bridge found",work!=null)
	if work==null:return
	var study:Node3D=work.get_node("HistoryStudy")
	study.replay()
	for i in 11:study.step_once()
	observations["study_local"]=xyz(hall.to_local(study.global_position))
	var inventory:Array=[]
	for item in hall.find_children("*","Node3D",true,false):
		if item.has_meta("artifact_lookup_name"):
			inventory.append({"key":item.get_meta("artifact_lookup_name"),"local":xyz(hall.to_local(item.global_position)),"path":str(item.get_path())})
	observations["inventory"]=inventory
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=47
	camera.global_position=hall.to_global(Vector3(7.5,50,22.5));camera.look_at(hall.to_global(Vector3(7.5,0,22.5)),Vector3.FORWARD);camera.current=true
	await create_timer(.4).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"overhead.png"))
	camera.size=47
	await snapshot("raised-oblique",hall.to_global(Vector3(31,48,54)),hall.to_global(Vector3(7.5,0,22)),60)
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	await snapshot("entry",hall.to_global(Vector3(6.5,1.65,4.6)),study.to_global(Vector3(0,.55,3.5)),78)
	await snapshot("history-margin",study.to_global(Vector3(-4,1.65,3.2)),study.to_global(Vector3(2,1.2,4)),85)
	await snapshot("rear-gallery",hall.to_global(Vector3(11.5,1.65,35)),hall.to_global(Vector3(5.5,1.1,32)),82)
	check("Arrival record has twelve rows and original rule",study.history.size()==12 and work.rule==30)
	if not folder.contains("/before/"):
		await interaction_checks(study)
		check_routes()
		var learner=load("res://doc/book/iterations/2026-10-08-ca-history-three-bodies/printed/history.gd").new()
		hall.add_child(learner);learner.position=Vector3(3,0,34.5);learner.rotation.y=PI/2
		for i in 11:learner.step()
		learner.select_row(3);await tick()
		await snapshot("printed-study",hall.to_global(Vector3(6.2,2.2,34.6)),hall.to_global(Vector3(3.8,1.35,34.5)),65)
		learner.queue_free()
	observations["scope"]="Actual museum overhead, raised and visitor-height views. Player and neighbouring halls hidden for capture. No physical headset test."

func interaction_checks(study: Node3D) -> void:
	var walker:=CharacterBody3D.new();root.add_child(walker);walker.add_to_group("em_walker")
	var original: Array=study.history.duplicate(true);var flags: Array=[]
	for shape in study.shapes:flags.append(shape.disabled)
	var stable:=true;var witness:=true
	for g in [0,3,10,5]:
		walker.global_position=study.to_global(Vector3(-4,0,g*.4));await tick();await tick()
		stable=stable and study.history==original
		for i in study.shapes.size():stable=stable and study.shapes[i].disabled==flags[i]
		witness=witness and study.selected==g and is_equal_approx(study.deck_cursor.position.z,g*.4) and is_equal_approx(study.screen_cursor.position.z,g*.4) and is_equal_approx(study.record_cursor.position.y,-.54+g*.048)
	check("Body walking forward and back selects the same row across three views",witness)
	check("Walking leaves all saved rows and support shapes unchanged",stable)
	await snapshot("walking-history",study.to_global(Vector3(-4,1.65,3.2)),study.to_global(Vector3(2,1.2,4)),85)
	walker.global_position=study.to_global(Vector3(-4,0,8));await tick()
	check("Walking into unrecorded depth cannot select a future row",study.selected==5 and not study.walking_row)
	walker.global_position=study.to_global(Vector3(-6,0,1.2));await tick()
	check("Outside the bay cannot change selection",study.selected==5)
	walker.remove_from_group("em_walker");walker.add_to_group("player_body")
	walker.global_position=study.to_global(Vector3(-4,0,1.2));await tick()
	check("XR player-body group reads existing generation",study.selected==3)
	study.toggle_run();await tick()
	check("Walking keeps RUN active",study.running)
	study.previous_row();check("Manual ROW pauses RUN",not study.running)
	walker.queue_free();await tick()
	study.seed_mode=0;study.flipped=false;study.replay()
	check("Replay keeps one seed row and only its tile active",study.history.size()==1 and study.history[0].count(1)==1 and study.deck.multimesh.visible_instance_count==1)
	study.step_once();await tick()
	check("Installed first step produces three cells",study.history.size()==2 and study.history[1].count(1)==3 and study.deck.multimesh.visible_instance_count==4)
	var support_ok:=true
	for g in 24:
		for x in 15:
			var active: bool=g<study.history.size() and study.history[g][x]==1
			support_ok=support_ok and study.shapes[g*15+x].disabled==not active
	check("Every installed support slot matches occupied recorded state",support_ok)
	var space=hall.get_world_3d().direct_space_state
	var foot=study.to_global(Vector3(0,0,0))
	var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(foot+Vector3.UP*.3,foot+Vector3.DOWN,1))
	check("Occupied installed tile provides surface at museum floor level",not hit.is_empty() and absf(hit.position.y-foot.y)<.015)
	foot=study.to_global(Vector3(-2.4,0,1.2));hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(foot+Vector3.UP*.3,foot+Vector3.DOWN,1))
	check("Gap has a lower collecting floor",not hit.is_empty() and absf(hit.position.y-foot.y+.6)<.02)
	for i in 30:study.step_once()
	check("Installed history stops at 24 generations",study.history.size()==24)
	study.flip_seed();await tick()
	check("Changing beginning discards all descendants",study.history.size()==1 and study.history[0][7]==1 and study.history[0][9]==1)
	study.flipped=false;study.replay()
	for i in 11:study.step_once()
	observations["single_step_ms"]=study.last_step_usec/1000.0

func check_routes() -> void:
	var routes: Dictionary={
		"entry_to_desk":[Vector2(6.5,3.5),Vector2(6.5,5.7)],
		"desk_to_left_history_margin":[Vector2(6.5,5.7),Vector2(2.5,5.7),Vector2(2.5,18.9)],
		"margin_to_east_lab_door":[Vector2(2.5,18.9),Vector2(2.5,21.5),Vector2(11.5,21.5),Vector2(11.5,26.5)],
		"lab_to_rear_gallery":[Vector2(11.5,26.5),Vector2(11.5,34.5),Vector2(6.5,34.5)],
		"rear_gallery_to_exit":[Vector2(6.5,34.5),Vector2(11.5,34.5),Vector2(11.5,39.3),Vector2(6.5,39.3),Vector2(6.5,40.5)]}
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7
	var results: Dictionary={}
	for label in routes:
		var points: Array=routes[label];var blocked: Array=[];var unsupported: Array=[];var samples:=0
		for i in range(1,points.size()):
			var a: Vector2=points[i-1];var b: Vector2=points[i];var count:=ceili(a.distance_to(b)/.15)
			for j in range(count+1):
				var p:=a.lerp(b,float(j)/count);var foot:=hall.to_global(Vector3(p.x,0,p.y))
				var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1
				query.transform=Transform3D(Basis.IDENTITY,foot+Vector3.UP*.88)
				var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query,8)
				if not hits.is_empty():blocked.append({"at":[p.x,p.y],"node":str(hits[0].collider.get_path())})
				var ground:=floor_at(foot)
				if ground.is_empty() or absf(ground.position.y-foot.y)>.03:unsupported.append([p.x,p.y])
				samples+=1
		results[label]={"samples":samples,"blocked":blocked,"unsupported":unsupported}
		check(label+": capsule clearance",blocked.is_empty())
		check(label+": continuous level floor",unsupported.is_empty())
	observations["routes"]=results
	var stream=museum.get("_portal_stream")
	check("Entry frame has supported approach",not stream.get("_entry").is_empty() and not stream.get("_entry").get("invalid",false))
	check("Exit frame has supported approach",not stream.get("_exit").is_empty() and not stream.get("_exit").get("invalid",false))

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	print("CA HISTORY ROOM ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
