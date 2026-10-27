extends "res://tools/probes/friction_studies_main.gd"
## Actual native mouse/trigger tap and an ungripped tracked-hand contact.
func is_standing(work: Node3D) -> bool:
	var state: Dictionary = work.observations()
	return state.angles.LeftPlank>45 and state.angles.RightPlank>45 and work.bodies.Cube.position.y>1.6

func is_down(work: Node3D) -> bool:
	var state: Dictionary = work.observations()
	return state.angles.LeftPlank<25 and state.angles.RightPlank<25 and work.bodies.Cube.position.y<1.3

func wait_down(work: Node3D) -> void:
	for n in 480:
		if is_down(work):break
		await frames(1)
	await frames(45)

func tap_surface(at: Vector3) -> void:
	if not xr:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;await input_aim_camera(at,25)
		for down in [true,false]:
			game.camera.look_at(at);var event := InputEventMouseButton.new();event.button_index = MOUSE_BUTTON_LEFT;event.pressed = down;Input.parse_input_event(event);await input_aim_camera(at,8)
		return
	var origin: Node3D = game.get_node("XROrigin3D");var pointer: Node3D = game.pointers[1]
	for n in 20:
		var position: Vector3 = game.camera.global_position+Vector3(.1,-.2,0);var aim := Basis.looking_at(at-position);position -= aim*Vector3(0,pointer.y_offset*XRServer.world_scale,0)
		right.set_pose("aim",Transform3D(origin.global_basis.inverse()*aim,origin.to_local(position)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH);await frames(1)
	right.set_input("trigger_click",true);await frames(8);right.set_input("trigger_click",false);await frames(8)

func player_photo(work: Node3D,name: String) -> void:
	if xr:return
	await input_aim_camera(work.to_global(Vector3(0,1.3,0)),20);await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out.path_join(name+".png"))

func run() -> void:
	root.size = Vector2i(1440,900);level = 46
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out=" ):out = arg.trim_prefix("--out=")
	var rows: Array = []
	for use_xr in [false,true]:
		await start(use_xr);var tag := "XR / " if xr else "Desktop / ";var y: float = game.building.spec.levels[46];var work: Node3D = station("matter-leaning-together")
		game.place_player(Vector3(-16.8,y+.06,3.8));await frames(300);active_tag = tag+"brittle / "
		check(active_tag+"precarious stack starts with all six parts under gravity",is_standing(work) and work.bodies.values().all(func(body):return not body.freeze and body.gravity_scale==1))
		await player_photo(work,"leaning-brittle-player-before")
		for id in ["LeftPlank","Cube","RightWedge"]:
			await click(work,"RESET");await frames(180);check(active_tag+id+" reset leaves it standing",is_standing(work))
			var body: Node3D = work.bodies[id];var impulses: Array = [];var note := func(value):impulses.append(value)
			body.tapped.connect(note)
			var at: Vector3 = body.global_position
			if "Wedge" in id:at += Vector3.UP*.08
			await tap_surface(at);await wait_down(work)
			check(active_tag+id+" gets one real input tap",impulses.size()==1)
			check(active_tag+id+" tap dismantles the live stack",is_down(work))
			rows.append({"mode":tag,"part":id,"impulses":impulses.size(),"state":work.observations()});body.tapped.disconnect(note)
			if id=="LeftPlank":await player_photo(work,"leaning-brittle-player-after")
		if xr:
			await click(work,"RESET");await frames(180);right.set_input("grip",0.0)
			var plank: Node3D = work.bodies.LeftPlank;var taps: Array = [];var note := func(value):taps.append(value)
			plank.tapped.connect(note)
			var surface: Vector3 = plank.global_position;var front: Vector3 = work.global_basis.z
			await input_palm_at(surface+front*.30);await frames(30);check(active_tag+"hand hover keeps the stack standing",is_standing(work))
			for step in 8:await input_palm_at(surface+front*(.25-step*.035))
			await wait_down(work);check(active_tag+"ungripped collision hand physically dismantles the stack",is_down(work) and taps.is_empty() and not plank.is_picked_up())
			rows.append({"mode":"physical synthetic XR palm","state":work.observations(),"pointer_taps":taps.size()});plank.tapped.disconnect(note)
		# Grabbing is still available, and held reset restores the new authored start.
		await click(work,"RESET");await frames(180)
		var ball: Node3D = work.bodies.Ball;var shape: CollisionShape3D = ball.get_children().filter(func(node):return node is CollisionShape3D)[0]
		if await input_grab(active_tag+"ball / ",ball,shape):
			check(active_tag+"ball remains freely grabbable",ball.is_picked_up());await click(work,"RESET");check(active_tag+"held reset restores live gravity",not ball.is_picked_up() and not ball.freeze)
			if xr:right.set_input("grip",0.0)
		await frames(300);check(active_tag+"reset returns to a supported precarious start",is_standing(work))
		game.queue_free();await frames(12)
		if xr:
			for tracker_node in [head,left,right]:XRServer.remove_tracker(tracker_node)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"rows":rows,"scope":"Actual floor 46, desktop mouse and synthetic XR trigger taps on plank/cube/chock, a physical ungripped XR collision-hand nudge, ball grab and held reset. This is not physical-headset acceptance or a claim that any infinitesimal contact always collapses it."}
	FileAccess.open(out.path_join("leaning-brittle-player-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
