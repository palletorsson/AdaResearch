extends "res://tools/probes/transformation_encounters.gd"
## Same native cameras before/after; the installed solver remains authoritative.
func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(.7).timeout
	var stream = museum.get("_portal_stream")
	if stream != null:
		stream.set_process(false); stream.set_physics_process(false)
	var walker = museum.get("_player")
	if walker is Node3D:
		walker.hide(); walker.set_process(false); walker.set_physics_process(false)
		walker.global_position=Vector3(0,-100,0)
	var previous = museum.get("_cam")
	if previous is Node3D: previous.hide()
	camera.set_cull_mask_value(19,false)
	var wardrobe= museum.get("_wardrobe")
	if wardrobe != null and is_instance_valid(wardrobe.get("costume")): wardrobe.get("costume").hide()
	for child in museum.get_children():
		if child is Node3D and child.has_meta("em_map") and child != hall: child.hide()
	var work := find_scene("/CellularAutomata3D_Flexible.gd")
	check("Installed volume exists",work!=null)
	if work==null: return
	var study: Node=work.get_node("StructureStudy")
	study.replay()
	var room: Node3D=study.neighbour_room
	check("Enlarged neighbourhood shares installed study",room!=null and room.study==study)
	observations["work_local"]=xyz(hall.to_local(work.global_position))
	observations["neighbour_local"]=xyz(hall.to_local(room.global_position))
	observations["hall_origin"]=xyz(hall.global_position)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=23
	camera.global_position=hall.to_global(Vector3(6.5,30,10.5))
	camera.look_at(hall.to_global(Vector3(6.5,0,10.5)),Vector3.FORWARD)
	camera.current=true
	await create_timer(.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"overhead.png"))
	camera.size=25
	await snapshot("raised-oblique",hall.to_global(Vector3(20,30,29)),hall.to_global(Vector3(6.5,0,10.5)),60)
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	await snapshot("entry",hall.to_global(Vector3(6.5,1.65,5)),hall.to_global(Vector3(4.5,1.4,9)),78)
	await snapshot("neighbours",hall.to_global(Vector3(4.15,1.65,5.9)),room.global_position,78)
	study.step_once()
	check("First step: fading centre beside seven active neighbours",room.states[13]==2 and room.active_neighbours==7)
	await snapshot("fading",hall.to_global(Vector3(4.15,1.65,5.9)),room.global_position,78)
	study.step_once()
	check("Second step: centre empty",room.states[13]==0)
	await snapshot("empty",hall.to_global(Vector3(4.15,1.65,5.9)),room.global_position,78)
	if not folder.contains("/before/"):
		await interaction_checks(work,study,room)
		check_routes()
		var learner=load("res://doc/book/iterations/2026-10-08-ca-a-state-that-lingers/printed/volume.gd").new()
		hall.add_child(learner);learner.position=Vector3(9,0,15);learner.rotation.y=PI/2
		await tick()
		await snapshot("printed-study",hall.to_global(Vector3(11.1,1.45,14.2)),learner.global_position+Vector3(0,1.05,0),62)
		learner.step()
		await snapshot("printed-fading",hall.to_global(Vector3(11.1,1.45,14.2)),learner.global_position+Vector3(0,1.05,0),62)
		learner.queue_free()
	observations["scope"]="Native installed CA_ElementaryRules. Same overhead, raised and visitor cameras; real seeded generations 0/1/2. Other halls/player hidden for capture. No physical headset test."

func interaction_checks(work: Node3D, study: Node, room: Node3D) -> void:
	study.replay()
	var reader: Node3D=study.get_node("StateHand")
	check("One hand point installed at reachable height",study.find_children("StateHand","Node3D",true,false).size()==1 and absf(reader.point.global_position.y-hall.global_position.y-1.12)<.01)
	var origin:=XROrigin3D.new();root.add_child(origin)
	var controller:=XRController3D.new();origin.add_child(controller)
	var hand=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(hand)
	controller.global_position=reader.point.global_position;reader.point.pick_up(hand)
	for i in 4: await tick()
	controller.global_position+=Vector3(-.7,.1,0)
	for i in 8: await tick()
	check("Moving held sphere keeps installed seed and clock",reader.point.held() and work.generation==0 and room.states[13]==1)
	var start:=Time.get_ticks_usec();reader.point.action();var update_usec:=Time.get_ticks_usec()-start
	for i in 3: await tick()
	check("Held trigger updates existing volume and enlarged witness together",work.generation==1 and room.states[13]==2 and room.active_neighbours==7)
	check("Live caption reports same state and count",room.caption.text.contains("FADING / 7 ACTIVE"))
	reader.point.let_go(hand,Vector3.ZERO,Vector3.ZERO)
	for i in 4: await tick()
	check("Installed release parks without changing generation",reader.point.position.is_equal_approx(Vector3(-1.65,1.12,-3.55)) and work.generation==1)
	var saved: PackedByteArray=work.current_state.duplicate()
	study.toggle_view()
	check("VIEW changes finish without touching state or clock",saved==work.current_state and work.generation==1 and not study.state_colours)
	study.toggle_view();study.step_once()
	check("Hand and console share one subsequent step",work.generation==2 and room.states[13]==0)
	study.replay()
	check("Replay restores witness and held clock",work.generation==0 and room.states[13]==1 and room.active_neighbours==11 and not study.running)
	observations["single_step_ms"]=update_usec/1000.0
	origin.queue_free()

func check_routes() -> void:
	var routes: Dictionary={
		"entry_to_hand_control":[Vector2(6.5,3.5),Vector2(6.5,6.3),Vector2(4.85,6.3)],
		"control_to_neighbourhood":[Vector2(4.85,6.3),Vector2(2.65,6.3),Vector2(2.65,8.7)],
		"left_rim_to_rear_gallery":[Vector2(2.65,8.7),Vector2(2.65,12.5),Vector2(9.5,12.5)],
		"rear_gallery_to_exit":[Vector2(9.5,12.5),Vector2(9.5,16.5),Vector2(6.5,16.5),Vector2(6.5,17.5)]}
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
				if not hits.is_empty(): blocked.append({"at":[p.x,p.y],"node":str(hits[0].collider.get_path())})
				var floor_hit:=floor_at(foot)
				if floor_hit.is_empty() or absf(floor_hit.position.y-foot.y)>.03: unsupported.append([p.x,p.y])
				samples+=1
		results[label]={"samples":samples,"blocked":blocked,"unsupported":unsupported}
		check(label+": capsule clearance",blocked.is_empty())
		check(label+": continuous level floor",unsupported.is_empty())
	observations["routes"]=results
	var stream= museum.get("_portal_stream")
	check("Entry frame has supported approach",not stream.get("_entry").is_empty() and not stream.get("_entry").get("invalid",false))
	check("Exit frame has supported approach",not stream.get("_exit").is_empty() and not stream.get("_exit").get("invalid",false))

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty()},"  "))
	print("CA STATES ROOM ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
