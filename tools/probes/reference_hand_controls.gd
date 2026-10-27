extends "res://tools/probes/void_transfer_probe.gd"
var snap := false
var focus_mode := "both"
var levels: Array[int] = [1,2]

func raw_photo(name: String) -> void:
	if not snap:return
	game.camera.make_current();await frames(3);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name+".png"))

func release_grip() -> void:
	if xr:right.set_input("grip",0.0)
	else:
		for down in [true,false]:
			var event := InputEventMouseButton.new();event.button_index = MOUSE_BUTTON_RIGHT;event.pressed = down;Input.parse_input_event(event);await frames(3)
	await frames(8)

func cube_press(cube: Node3D) -> void:
	var observed: Array = [];var note := func():observed.append(true)
	cube.pressed.connect(note)
	await press(cube.get_node("PushButton"))
	if not xr:print("HAND_BUTTON ",cube.name," events=",observed.size()," hit=",game.body.desktop_pointer._last_target.get_path() if is_instance_valid(game.body.desktop_pointer._last_target) else "none"," active=",game.body.desktop_pointer._active())
	cube.pressed.disconnect(note)

func run() -> void:
	trial = "matter_logic_reference";root.size = Vector2i(1440,900)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
		if arg=="--capture":snap = true
		if arg.begins_with("--mode="):focus_mode = arg.trim_prefix("--mode=")
		if arg.begins_with("--levels="):
			levels.clear()
			for value in arg.trim_prefix("--levels=").split(","):levels.append(int(value))
	for use_xr in [false,true]:
		if focus_mode=="desktop" and use_xr or focus_mode=="xr" and not use_xr:continue
		level = 1;await start(use_xr)
		var tag := "XR / " if xr else "Desktop / "
		for index in levels:
			level = index;game.place_player(game.spawn_for(level));await frames(30)
			var entry: Dictionary = game.building.content.data.floors[level].artifacts[0]
			var work: Node3D = station(entry.id)
			var id := ""
			for key in work.bodies:
				if work.records[key].role=="mover":id = key;break
			var mover: Node3D = work.bodies[id];var home: Vector3 = work.to_global(work.homes[id].origin)
			game.place_player(Vector3(home.x,game.building.spec.levels[level]+.06,2.5));await frames(15)
			var shape := mover.get_children().filter(func(c):return c is CollisionShape3D)[0] as CollisionShape3D
			if not await input_grab(tag+work.kind+" / ",mover,shape):continue
			check(tag+work.kind+" uses held collision state",mover.freeze and mover.collision_mask==0)
			await cube_press(work.buttons.RELEASE)
			check(tag+work.kind+" release leaves the carried mover frozen",work.running and mover.freeze and mover.is_picked_up())
			var elapsed_before: float = work.elapsed;await frames(1000)
			check(tag+work.kind+" holding does not time out the take",work.result<0 and is_equal_approx(work.elapsed,elapsed_before))
			if level==1:await raw_photo("hand-gate-"+("xr" if xr else "desktop"))
			await cube_press(work.buttons.RESET);await frames(5)
			check(tag+work.kind+" reset releases the actual hand",not mover.is_picked_up())
			check(tag+work.kind+" reset restores home and standby",mover.position.distance_to(work.homes[id].origin)<.002 and not work.running and work.result<0 and work.hand_placed.is_empty())
			if xr:right.set_input("grip",0.0);await frames(5)
			# Re-grab and release at the source start through actual player input.
			if not await input_grab(tag+work.kind+" second / ",mover,shape):continue
			await input_tip_to(mover,home);await frames(30)
			check(tag+work.kind+" hand returns mover to its source start",mover.global_position.distance_to(home)<.09)
			await release_grip()
			check(tag+work.kind+" hand drop starts real physics",work.running and not mover.freeze and not mover.is_picked_up())
			for frame in 1100:
				if work.result>=0:break
				await frames(1)
			check(tag+work.kind+" hand-started default take reaches physical Z",work.result==1)
			await cube_press(work.buttons.RESET)
		game.queue_free();await frames(12)
		if xr:
			for item in [head,left,right]:XRServer.remove_tracker(item)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"scope":"Real desktop right-click and synthetic XR grip pickup/drop, pointer RELEASE/RESET while held, hold timeout, source-start hand release and physical AND/OR result. No physical-headset acceptance."}
	FileAccess.open(out.path_join("hand-control-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
