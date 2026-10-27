extends "res://tools/probes/friction_studies_main.gd"
## Real main-floor input, not direct calls to the scene's pickup callbacks.
func release_real() -> void:
	if xr:right.set_input("grip",0.0);await frames(12);return
	for down in [true,false]:
		var event := InputEventMouseButton.new();event.button_index = MOUSE_BUTTON_RIGHT;event.pressed = down;Input.parse_input_event(event);await frames(6)

func keypress(code: Key,shift := false) -> void:
	for down in [true,false]:
		var event := InputEventKey.new();event.keycode = code;event.physical_keycode = code;event.shift_pressed = shift;event.pressed = down;Input.parse_input_event(event);await frames(5)

func run() -> void:
	root.size = Vector2i(1440,900);level = 46
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	if "--photo-only" in OS.get_cmdline_user_args():
		await start(false);var work: Node3D = station("matter-leaning-together")
		game.place_player(Vector3(-16.8,game.building.spec.levels[46]+.06,3.8));await frames(80);active_tag = "Desktop / final photograph / "
		await click(work,"RESET");await frames(120);await input_aim_camera(work.to_global(Vector3(0,1.05,0)),20);await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out.path_join("leaning-player.png"))
		var receipt := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"scope":"Final actual player photograph after moving readout text onto the existing control strip. Reset clicked through the native mouse; the full input receipt is separate."}
		FileAccess.open(out.path_join("leaning-player-photo-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(receipt,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(receipt));quit(0 if failed.is_empty() else 1);return
	for use_xr in [false,true]:
		await start(use_xr);var tag := "XR / " if xr else "Desktop / ";var y: float = game.building.spec.levels[46]
		var work: Node3D = station("matter-leaning-together")
		check(tag+"main floor retains the existing eight installations and open shafts",game.building.content.data.floors[46].artifacts.size()==9 and game.building.spec.width==42 and ray(Vector3(-10,y+1,0),Vector3(-10,y-.5,0)).is_empty() and ray(Vector3(10,y+1,0),Vector3(10,y-.5,0)).is_empty())
		game.place_player(Vector3(-18,y+.06,3.2));await frames(20)
		for destination in [Vector3(-19.2,y,4),Vector3(-19.2,y,7.7),Vector3(-14.8,y,7.7),Vector3(-14.8,y,4),Vector3(-16.8,y,3.8)]:
			var reached := await move_to(destination,false,550);print("LEANING_WALK ",{"target":destination,"actual":game.body.global_position,"recovering":game.recovering});check(tag+"walk around the work area "+str(destination),reached)
		active_tag = tag+"Leaning Together / ";await frames(180)
		check(active_tag+"starts with a live leaning posture",work.observations().angles.LeftPlank>40 and work.observations().angles.RightPlank>40)
		if not xr:
			await input_aim_camera(work.to_global(Vector3(0,1.05,0)),20);await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out.path_join("leaning-player.png"))
		for id in ["LeftPlank","RightPlank","LeftWedge","RightWedge","Cube","Ball"]:
			await click(work,"RESET");await frames(120)
			var body: Node3D = work.bodies[id];var shape: CollisionShape3D = body.get_children().filter(func(node):return node is CollisionShape3D)[0]
			var label: String = active_tag+str(id)+" / "
			if not await input_grab(label,body,shape):
				# Clear an accidentally selected occluder before the next reset.
				await release_real();continue
			var before: Vector3 = body.global_position;var basis_before := body.global_basis
			if xr:
				var palm: Vector3 = game.pickups[1].global_position
				await input_palm_at(palm+Vector3.UP*.24+work.global_basis.x*.20)
			else:
				game.body.desktop_pointer._hold_distance += .30;await input_aim_camera(shape.global_position,8)
			await frames(20);check(label+"real hand moves the intended loose body",body.is_picked_up() and body.global_position.distance_to(before)>.12)
			if not xr:
				var hand: Node3D = body.get_picked_up_by();var hand_before := hand.basis
				await keypress(KEY_Q);check(label+"Q rotates the actual grab frame",hand.basis.get_rotation_quaternion().angle_to(hand_before.get_rotation_quaternion())>.07)
				var old: Basis = hand.basis;await keypress(KEY_Z);check(label+"Z provides the second rotation axis",hand.basis.get_rotation_quaternion().angle_to(old.get_rotation_quaternion())>.07)
				old = hand.basis;await keypress(KEY_Q,true);check(label+"Shift+Q provides yaw",hand.basis.get_rotation_quaternion().angle_to(old.get_rotation_quaternion())>.07)
				await frames(12);check(label+"rotated body follows its grab frame",body.global_basis.get_rotation_quaternion().angle_to(basis_before.get_rotation_quaternion())>.05)
			await release_real();check(label+"release restores a live three-dimensional body",not body.is_picked_up() and not body.freeze and body.collision_layer==5 and body.collision_mask&(1<<16)!=0)
		# A reset while holding must release this actual hand and keep gravity live.
		await click(work,"RESET");await frames(120)
		var held_body: Node3D = work.bodies.Cube
		if await input_grab(active_tag+"reset held cube / ",held_body,held_body.get_children().filter(func(node):return node is CollisionShape3D)[0]):
			await click(work,"RESET");check(active_tag+"reset releases the actual held cube",not held_body.is_picked_up() and not held_body.freeze and held_body.position.distance_to(work.homes.Cube.origin)<.02)
			if xr:right.set_input("grip",0.0)
		game.queue_free();await frames(12)
		if xr:
			for tracker_node in [head,left,right]:XRServer.remove_tracker(tracker_node)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"scope":"Actual main floor, desktop mouse and synthetic XR grip for all six loose parts. Real body movement/release, three desktop rotation axes, held reset and walking all sides. Physical headset testing remains."}
	FileAccess.open(out.path_join("leaning-player-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
