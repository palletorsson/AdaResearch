extends "res://tools/probes/transformation_encounters.gd"

func clear_body(at: Vector3, height: float = 1.6) -> bool:
	var capsule := CapsuleShape3D.new();capsule.radius=0.28;capsule.height=height
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule
	query.transform.origin=at+Vector3.UP*(height*0.5+0.04);query.collision_mask=1|4
	var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
	if not hits.is_empty():observations["hits_"+str(at)]=hits.map(func(h):return str(h.collider.get_path()))
	return hits.is_empty()

func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(0.5).timeout
	# Explicit probe poses are not an attempt to cross to a different hall.
	var stream= museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var walker= museum.get("_player")
	if walker is Node3D:
		walker.hide();walker.set_process(false);walker.set_physics_process(false);walker.global_position=Vector3(0,-100,0)
	var old_cam=museum.get("_cam")
	if old_cam is Node3D:old_cam.hide()
	camera.set_cull_mask_value(19,false)
	var wardrobe=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").hide()
	var source=find_scene("/mengersponge/menger_sponge.gd")
	var film=find_scene("/concept_monitor.gd")
	check("Original sponge and film remain installed",source!=null and film!=null)
	if source==null:return
	var desk=source.get_node("MengerLesson");var reader=desk.cell_reader;var zone=source.get_node("FlightBox")
	observations.source=xyz(hall.to_local(source.global_position));observations.desk=xyz(hall.to_local(desk.global_position))
	check("One hand reader and six original controls",reader!=null and desk.buttons.size()==6 and reader.buttons.size()==3)
	reader.hide()
	var film_at:Vector3=film.global_position
	film.global_position.x+=7.0
	await snapshot("before",source.to_global(Vector3(-1.8,2.6,-8.0)),source.to_global(Vector3(1.0,3.1,-1.8)),79)
	film.global_position=film_at
	reader.show()
	await snapshot("arrival",source.to_global(Vector3(-1.8,2.6,-8.0)),source.to_global(Vector3(1.0,3.1,-1.8)),79)
	var approach:Vector3=reader.to_global(Vector3(0,0.005,1.08))
	check("Hand desk is outside the flight enclosure",not zone.contains_point(approach) and not zone.contains_point(reader.global_position))
	check("Standing approach has floor and capsule clearance",not floor_at(approach).is_empty() and clear_body(approach))
	check("Point waits at reachable height",reader.grip.global_position.y-hall.global_position.y<1.6 and reader.grip.global_position.y-hall.global_position.y>1.0)
	await snapshot("hand-seed",reader.to_global(Vector3(1.35,1.85,1.8)),reader.to_global(Vector3(0,1.5,0)),56)
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum)
	await create_timer(0.2).timeout
	for id in ["NEXT","NEXT"]:
		var result:Dictionary=await driver.press(reader.buttons[id],approach)
		check("Ray reaches hand NEXT at cut "+str(source.current_iteration),str(result.get("hover","")) not in ["","none","null","nothing"])
	check("Two nearby presses reach 400 cubes with 147 removed cells",source.current_iteration==2 and source.find_all_cube_scenes().size()==400 and reader.miniature.get_child_count()==400 and reader.ghosts.get_child_count()==147)
	await snapshot("hand-second",reader.to_global(Vector3(1.35,1.85,1.8)),reader.to_global(Vector3(0,1.5,0)),56)
	for id in ["BACK","RESET"]:
		var result:Dictionary=await driver.press(reader.buttons[id],approach)
		check("Ray reaches hand "+id,str(result.get("hover","")) not in ["","none","null","nothing"])
	check("Hand RESET restores a single cube",source.current_iteration==0)
	var origin:=XROrigin3D.new();root.add_child(origin)
	var controller:=XRController3D.new();origin.add_child(controller)
	var hand=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(hand)
	controller.global_position=reader.grip.global_position;reader.grip.pick_up(hand);await create_timer(0.2).timeout
	controller.global_position=reader.to_global(reader.model_position(Vector3(0,4.5,-3)));await create_timer(0.2).timeout
	check("Held sphere selects the front removed cell",reader.selected==Vector3i(1,1,0) and not reader.kept)
	reader.grip.action();await create_timer(0.2).timeout
	check("Held trigger applies one cut through original desk",source.current_iteration==1 and reader.miniature.get_child_count()==20)
	reader.grip.let_go(hand,Vector3.ZERO,Vector3.ZERO);origin.hide();await create_timer(0.2).timeout
	await snapshot("cell-and-room",reader.to_global(Vector3(1.4,2.0,1.6)),source.to_global(Vector3(2.0,3.1,-2.8)),86)
	await snapshot("hand-first",reader.to_global(Vector3(1.35,1.85,1.8)),reader.to_global(Vector3(0,1.5,0)),56)
	desk.act("NEXT");await create_timer(0.2).timeout
	await snapshot("second-cut",source.to_global(Vector3(-1.8,2.6,-8.0)),source.to_global(Vector3(1,3.1,-1.8)),79)
	desk.act("GHOST");desk.act("FRAME")
	await snapshot("ghosts",source.to_global(Vector3(-5,3.6,-8.5)),source.to_global(Vector3(0,4.5,0)),85)
	check("Ghost and frame views add no colliders",reader.ghosts.visible and reader.ghosts.find_children("*","CollisionObject3D",true,false).is_empty() and desk.frame.find_children("*","CollisionObject3D",true,false).is_empty())
	desk.act("GHOST")
	var ids:Array=source.find_all_cube_scenes().map(func(c):return c.get_instance_id())
	walker.global_position=source.to_global(Vector3(0,0.05,-5.2))
	for id in ["NEXT","BACK","RESET"]:
		var result:Dictionary=await driver.press(reader.buttons[id],approach)
		check("Hand "+id+" refuses a solid change around a visitor",not desk.notice.is_empty() and source.current_iteration==2 and ids==source.find_all_cube_scenes().map(func(c):return c.get_instance_id()))
	reader.grip.action()
	check("Held-point action has the same occupant interlock",source.current_iteration==2 and not desk.notice.is_empty())
	walker.global_position=Vector3(0,-100,0);await create_timer(0.2).timeout
	check("Leaving does not execute any pending change",source.current_iteration==2)
	await driver.press(reader.buttons.BACK,approach)
	check("New request works after the visitor leaves",source.current_iteration==1 and desk.notice.is_empty())
	desk.act("NEXT")
	await physics_frame;await physics_frame
	var zone_id:int=zone.get_instance_id()
	check("Flight enclosure survives desk rebuilds",source.get_node("FlightBox").get_instance_id()==zone_id)
	check("Central passage admits standing capsule",clear_body(source.to_global(Vector3(0,3.05,-3))))
	check("Small axial entrance excludes standing capsule",not clear_body(source.to_global(Vector3(-3,1.03,-4))))
	var ray:=PhysicsRayQueryParameters3D.create(source.to_global(Vector3(-3,1.5,-4.8)),source.to_global(Vector3(-3,1.5,4.8)),1)
	check("Same small axial opening transmits a ray",hall.get_world_3d().direct_space_state.intersect_ray(ray).is_empty())
	await snapshot("small-opening",source.to_global(Vector3(-3,1.5,-5.3)),source.to_global(Vector3(-3,1.5,0)),72)
	await snapshot("inside",source.to_global(Vector3(0,4.5,-2.2)),source.to_global(Vector3(0,4.5,5)),78)
	await snapshot("above",source.to_global(Vector3(-5.4,10.6,-5.4)),source.to_global(Vector3(0,4.0,0)),86)
	for p in [Vector3(0,0.005,-6.7),Vector3(0,0.005,6.7)]:
		check("Ground doorway remains supported and clear "+str(p),not floor_at(source.to_global(p)).is_empty() and clear_body(source.to_global(p)))
	driver.teardown();await process_frame
	# Exercise the shipped walker input, rather than assigning the flight result.
	museum.set_physics_process(false)
	walker.global_position=source.to_global(Vector3(0,0.05,-5.2));walker.velocity=Vector3.ZERO;museum.set("_vy",0.0)
	var start_y:float=walker.global_position.y
	key(KEY_SPACE,true)
	for i in 30:await physics_frame;museum.call("_physics_process",museum.get_physics_process_delta_time())
	key(KEY_SPACE,false)
	check("Shipped museum walker rises in flight volume",walker.global_position.y>start_y+0.7)
	var held:Vector3=walker.global_position
	for i in 15:await physics_frame;museum.call("_physics_process",museum.get_physics_process_delta_time())
	check("Neutral input holds position inside",walker.global_position.distance_to(held)<0.03)
	walker.global_position=source.to_global(Vector3(0,0.6,-6.8));walker.velocity=Vector3.ZERO;museum.set("_vy",0.0)
	for i in 40:await physics_frame;museum.call("_physics_process",museum.get_physics_process_delta_time())
	check("Gravity resumes beyond ground exit",walker.global_position.y<source.global_position.y+0.1 and walker.is_on_floor())
	if stream!=null:
		var exit_data:Dictionary=stream.get("_exit");var entry_data:Dictionary=stream.get("_entry")
		check("Authored entry and exit validate without fallback",not entry_data.get("invalid",false) and not exit_data.get("invalid",false) and entry_data.get("cell")==Vector2i(7,1) and exit_data.get("cell")==Vector2i(7,17))
		var door:Vector3=exit_data.get("door",Vector3.ZERO)
		check("Next-hall portal is beyond the rear flight doorway",door.z>source.global_position.z+6.5 and not zone.contains_point(door))
		observations.exit=exit_data;observations.entry=entry_data
	walker.global_position=Vector3(0,-100,0)
	var study=load("res://ada_run/menger_student/menger.gd").new()
	study.transform=reader.global_transform;root.add_child(study);reader.hide();study.advance();study.advance()
	await snapshot("student",study.to_global(Vector3(1.35,1.85,1.8)),study.to_global(Vector3(0,1.5,0)),56)
	check("Exact printed example runs in existing museum",study.generation==2 and study.drawing.get_child_count()==400)
	study.queue_free();reader.show();origin.queue_free()
	await process_frame
	# Resume portal handling only for an intentional journey to the next hall.
	if stream!=null:
		walker.global_position=source.to_global(Vector3(0,0.05,6.55))
		walker.rotation=Vector3(0,PI,0);museum.set("_yaw",PI);museum.set("_pitch",0.0);museum.set("_vy",0.0)
		old_cam.rotation=Vector3.ZERO
		stream.set("_have_previous_eye",false);stream.set("_armed",true);stream.set_process(true)
		await create_timer(0.2).timeout
		check("Leaving flight at rear does not immediately change halls",not bool(stream.get("busy")))
		museum.set_process(true) # Allow destination stamp queues to finish during the crossing.
		key(KEY_W,true)
		for i in 80:
			await physics_frame
			if bool(stream.get("busy")):break
			museum.call("_physics_process",museum.get_physics_process_delta_time())
		key(KEY_W,false)
		check("Walking to authored exit requests next hall",bool(stream.get("busy")))
		var started:=Time.get_ticks_msec()
		while bool(stream.get("busy")) and Time.get_ticks_msec()-started<45000:await process_frame
		var next:Dictionary=stream.get("_current")
		observations.portal_end={"map":next.get("map",""),"phase":stream.get("phase"),"failure":stream.get("failure")}
		check("Portal completes arrival in Golden Spiral",not bool(stream.get("busy")) and str(next.get("map",""))=="Fractal_GoldenSpiral")
	observations.scope="Current museum, actual desktop ray controls and XRTools supplied poses. Before hides only the new reader. Printed study temporarily occupies its workspace. Flight ascent/hover/exit tested with museum keyboard controller. No physical headset claim."

func key(code: int, down: bool) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down
	Input.parse_input_event(event);Input.flush_buffered_events()
