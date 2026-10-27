extends "res://tools/probes/threshold_workshop_main.gd"
## Actual saved tower or additive draft, with real desktop input and tracked XR input.
var photo_mode := false
var input_mode := "both"

func start(use_xr: bool) -> void:
	xr = use_xr;Source.use_main_tower = true
	if xr:
		head = tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0));left = tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4));right = tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO);right.set_input("trigger_click",false);right.set_input("grip",0.0)
	game = load("res://commons/void/void.tscn").instantiate();game.force_xr = xr;root.add_child(game);current_scene = game
	# This receipt tests floor 3. Keep the neighbouring Trace hardware problem
	# outside this interaction run without changing its saved data or source.
	game.building.content.pending = game.building.content.pending.filter(func(job):return job.index==3)
	game.floor_stream.set_process(false)
	if not xr:game.body.scripted_input = true
	await frames(45);game.scene_loaded();game.scene_visible();await frames(30);game.atmosphere.animate_sky = false;game.atmosphere.set_sky_time(180)

func aim_tape(target: Vector3) -> void:
	if not xr:await input_aim_camera(target,16);return
	var origin: Node3D = game.get_node("XROrigin3D")
	var at: Vector3 = game.camera.global_position+Vector3(.15,-.20,-.12)
	var aim := Basis.looking_at(target-at)
	for n in 16:
		right.set_pose("aim",Transform3D(origin.global_basis.inverse()*aim,origin.to_local(at)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		await frames(1)

func tape_fire(target: Vector3) -> void:
	await aim_tape(target)
	for down in [true,false]:
		if xr:right.set_input("trigger_click",down)
		else:
			game.camera.look_at(target)
			var event := InputEventMouseButton.new();event.button_index = MOUSE_BUTTON_LEFT;event.pressed = down;Input.parse_input_event(event)
		await frames(8)

func held_trigger(down: bool) -> void:
	if xr:right.set_input("trigger_click",down)
	else:
		var event := InputEventMouseButton.new();event.button_index = MOUSE_BUTTON_LEFT;event.pressed = down;Input.parse_input_event(event)
	await frames(3)

func drop_tool() -> void:
	if xr:right.set_input("grip",0.0)
	else:
		for down in [true,false]:
			var event := InputEventMouseButton.new();event.button_index = MOUSE_BUTTON_RIGHT;event.pressed = down;Input.parse_input_event(event);await frames(5)
	await frames(8)

func press(button: Node3D) -> void:
	if not xr:await super.press(button);return
	var target: Vector3 = button.get_node("InteractableAreaButton/CollisionShape3D").global_position
	var origin: Node3D = game.get_node("XROrigin3D");var pointer: Node3D = game.pointers[1]
	# Point from an extended hand, outside the avatar/other-hand geometry.
	for n in 24:
		var at: Vector3 = game.camera.global_position+Vector3(.15,-.2,-.5)
		var aim := Basis.looking_at(target-at);at -= aim*Vector3(0,pointer.y_offset*XRServer.world_scale,0)
		right.set_pose("aim",Transform3D(origin.global_basis.inverse()*aim,origin.to_local(at)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		await frames(1)
	print("TAPE_BUTTON_RAY ",button.get_parent().name," -> ",pointer.get_node("RayCast").get_collider())
	right.set_input("trigger_click",true);await frames(8);right.set_input("trigger_click",false);await frames(8)

func photograph_tape(work: Node3D,name: String) -> void:
	if not photo_mode or xr:return
	var old_camera: Transform3D = game.camera.transform
	var care: Node3D = game.get_node("CareBody");var care_visible := care.visible;care.hide()
	var wardrobe := game.get_node_or_null("QueerCostume")
	var wardrobe_visuals: Array = []
	if wardrobe!=null:
		for mesh in wardrobe.find_children("*","GeometryInstance3D",true,false):
			wardrobe_visuals.append([mesh,mesh.visible]);mesh.hide()
	var avatar_meshes := game.get_node("XROrigin3D").find_children("*","GeometryInstance3D",true,false)
	var avatar_visible: Array[bool] = []
	for mesh in avatar_meshes:avatar_visible.append(mesh.visible);mesh.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for layer in game.find_children("*","CanvasLayer",true,false):layer.hide()
	game.status.hide();game.notice_time = -1
	game.body.set_process_unhandled_input(false)
	game.camera.global_position = work.to_global(Vector3(1.5,1.85,2.8));game.camera.look_at(work.to_global(Vector3(0,1.15,-.1)))
	await frames(5);await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out.path_join(name+".png"))
	game.camera.transform = old_camera
	care.visible = care_visible
	for row in wardrobe_visuals:row[0].visible = row[1]
	for i in avatar_meshes.size():avatar_meshes[i].visible = avatar_visible[i]
	game.body.set_process_unhandled_input(true);Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func run() -> void:
	root.size = Vector2i(1440,900);level = 3
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
		if arg=="--capture":photo_mode = true
		if arg.begins_with("--mode="):input_mode=arg.trim_prefix("--mode=")
	for use_xr in ([false] if input_mode=="desktop" else [true] if input_mode=="xr" else [false,true]):
		if photo_mode and use_xr and "--both-input" not in OS.get_cmdline_user_args():continue
		load("res://commons/void/game.gd").requested_floor = 3
		await start(use_xr)
		for n in 360:
			if game.building.content.exhibits.has("3/tape-supply"):break
			await frames(1)
		if not game.building.content.exhibits.has("3/tape-supply"):check("Tape station loads on Point Lines",false);quit(1);return
		var work: Node3D = station("tape-supply");var tag := "XR / " if xr else "Desktop / "
		check(tag+"same original Lines floor and open shafts",game.building.content.data.floors[3].map=="Point_Lines" and game.building.spec.width==42 and game.building.spec.depth==18)
		game.place_player(work.to_global(Vector3(0,.06,1.65)));await frames(35)
		check(tag+"supply crate has a standing approach",game.body.is_on_floor() and not game.recovering)
		check(tag+"both shaft holes remain open",ray(Vector3(-10,-17.8,0),Vector3(-10,-18.6,0)).is_empty() and ray(Vector3(10,-17.8,0),Vector3(10,-18.6,0)).is_empty())
		if not xr:
			for point in [Vector3(-1.5,0,1),Vector3(-1.5,0,-1),Vector3(1.5,0,-1),Vector3(1.5,0,1),Vector3(0,0,1)]:
				var reached := await move_to(work.to_global(point),false,550)
				if not reached:
					for i in game.body.get_slide_collision_count():print("TAPE_ROUTE_BLOCKER ",game.body.get_slide_collision(i).get_collider().get_path())
				check("Desktop / walk around supply crate "+str(point),reached)
		await photograph_tape(work,"tape-supply")
		game.place_player(work.to_global(Vector3(0,.06,1.65)));await frames(15)
		for i in 3:
			var roll: Node3D = work.rolls[i]
			var shape: CollisionShape3D = roll.get_children().filter(func(child):return child is CollisionShape3D)[0]
			if not await input_grab(tag+roll.kind+" / ",roll,shape,.4,.10):continue
			var a: Vector3 = work.to_global(Vector3(-.60,1.68-i*.08,-.33))
			var b: Vector3 = work.to_global(Vector3(.60,1.72-i*.08,-.33))
			await aim_tape(a);await held_trigger(true)
			await aim_tape(a.lerp(b,.35));await frames(24)
			await aim_tape(a.lerp(b,.70));await frames(24)
			await held_trigger(false)
			check(tag+roll.kind+" slow click and hand movement place no fragments",roll.segments.is_empty() and roll.drag_points.size()==1 and roll.remaining==30)
			check(tag+roll.kind+" real fire fixes A on the intended board",not roll.start_anchor.is_empty() and roll.start_anchor.body.get_ref()==work.get_node("SampleBoard"))
			await aim_tape(b);await frames(8)
			check(tag+roll.kind+" actual held tool displays stretched preview",roll.preview.visible and roll.segments.is_empty())
			await tape_fire(b)
			check(tag+roll.kind+" second real fire completes exactly one strip",roll.segments.size()==1 and roll.start_anchor.is_empty())
			await tape_fire(a)
			await input_tip_to(roll,work.to_global(work.home_poses[str(roll.name)].origin));await frames(8)
			await drop_tool()
			check(tag+roll.kind+" real grip release cancels unfinished draw",roll.start_anchor.is_empty() and not roll.preview.visible)
		await photograph_tape(work,"tape-on-board")
		game.place_player(work.to_global(Vector3(0,.06,1.65)));await frames(50)
		active_tag = tag+"station / ";await click(work,"UNDO");await frames(3)
		check(tag+"native undo button restores barrier roll budget",work.rolls[2].remaining==30)
		await click(work,"TIDY");await frames(3)
		check(tag+"native tidy button clears all roll records",work.rolls.all(func(roll):return roll.segments.is_empty()))
		var stripe_roll: Node3D = work.rolls[1]
		stripe_roll.freehand_draw=true # Optional freehand mode is now explicit.
		var stripe_shape: CollisionShape3D = stripe_roll.get_children().filter(func(child):return child is CollisionShape3D)[0]
		if await input_grab(tag+"drag stripe / ",stripe_roll,stripe_shape,.4,.10):
			await aim_tape(work.to_global(Vector3(-.65,1.55,-.33)));await held_trigger(true)
			for i in 17:await aim_tape(work.to_global(Vector3(-.65+.08*i,1.55+.08*sin(float(i)/16*TAU),-.33)))
			check(tag+"held native fire previews a continuous stripe",stripe_roll.drag_points.size()>10 and stripe_roll.segments.is_empty() and stripe_roll.preview.visible)
			await held_trigger(false)
			check(tag+"releasing native fire commits one sampled stripe",stripe_roll.segments.size()==1 and stripe_roll.segments[0].anchors.size()>10)
			await photograph_tape(work,"tape-stripes");await drop_tool()
		game.place_player(work.to_global(Vector3(0,.06,1.65)));await frames(40)
		await click(work,"UNDO");await frames(3)
		check(tag+"whole stripe is reversible through the real Undo control",stripe_roll.remaining==30)
		await click(work,"TIDY");await frames(3)
		# A strip between the board and the existing grabbable plank follows the
		# plank when the real player hand carries it, without driving its motion.
		var pink: Node3D = work.rolls[1]
		pink.freehand_draw=false
		var shape: CollisionShape3D = pink.get_children().filter(func(child):return child is CollisionShape3D)[0]
		if await input_grab(tag+"object link / ",pink,shape,.4,.10):
			await tape_fire(work.to_global(Vector3(-.65,1.60,-.33)))
			await tape_fire(work.get_node("LoosePlank").to_global(Vector3(.25,.03,.02)))
			check(tag+"tape attaches to the actual carryable plank",pink.segments.size()==1 and pink.segments[0].anchors[1].body.get_ref()==work.get_node("LoosePlank"))
			if pink.segments.size()==1:check(tag+"native two-object tape has a real physics binding",pink.segments[0].get_child_count()==1 and pink.segments[0].get_child(0).joint is Generic6DOFJoint3D)
			await drop_tool()
			if pink.segments.size()==1:
				var strip: Node3D = pink.segments[0];var plank: Node3D = work.get_node("LoosePlank")
				var plank_shape: CollisionShape3D = plank.get_children().filter(func(child):return child is CollisionShape3D)[0]
				if await input_grab(tag+"taped plank / ",plank,plank_shape,.4,.10):
					var before: Vector3 = plank.global_position
					if xr:await input_palm_at(game.pickups[1].global_position+Vector3(.2,.25,0))
					else:game.body.desktop_pointer._hold_distance += .35;await input_aim_camera(plank.global_position,12)
					await frames(15)
					check(tag+"tape survives the native grab-frame switch",is_instance_valid(strip))
					if is_instance_valid(strip):check(tag+"tape follows real hand movement of a different object",plank.global_position.distance_to(before)>.1 and strip.cached[2].distance_to(plank.to_global(strip.anchors[1].point))<.003)
					await frames(20)
					if is_instance_valid(strip):check(tag+"pulling a wall-bound plank peels its constraint",strip.get_child(0).torn and not plank.has_meta("tape_physics_lease"))
					await photograph_tape(work,"tape-to-plank");await drop_tool()
		# Leave no actual pickup driver holding an object during scene teardown.
		if xr and is_instance_valid(game.pickups[1].picked_up_object):await drop_tool()
		game.queue_free();await frames(12)
		if xr:
			for tracker_node in [head,left,right]:XRServer.remove_tracker(tracker_node)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"scope":"Actual Point Lines floor with adjacent asynchronous content excluded from this focused receipt. Native mouse pickup/fire and synthetic XR grip/trigger; all three rolls, previews, cancellation, undo/tidy and a taped plank carried by the real player hand. No physical headset acceptance."}
	FileAccess.open(out.path_join("tape-rolls-player-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
