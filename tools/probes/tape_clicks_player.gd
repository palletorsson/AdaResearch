extends "res://tools/probes/tape_rolls_main.gd"
## Focus on the user's click contract in the currently curated station layout.
func run() -> void:
	level=3
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg.begins_with("--mode="):input_mode=arg.trim_prefix("--mode=")
	load("res://commons/void/game.gd").requested_floor=3
	await start(input_mode=="xr")
	for n in 360:
		if game.building.content.exhibits.has("3/tape-supply"):break
		await frames(1)
	var work: Node3D=station("tape-supply")
	var tag := "XR / " if xr else "Desktop / "
	game.place_player(work.to_global(Vector3(0,.06,1.65)));await frames(20)
	check(tag+"live station on Point Lines",game.ready_for_play and not game.recovering and game.building.content.data.floors[3].map=="Point_Lines")
	if xr:check("XR / tower installs two-metre force-pull adapters",game.pickups.all(func(p):return p.ranged_distance==2 and p.get_script().resource_path.ends_with("force_pickup.gd")))
	for i in 3:
		var roll: Node3D=work.rolls[i]
		var shape: CollisionShape3D=roll.get_children().filter(func(child):return child is CollisionShape3D)[0]
		if not xr:
			Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;game.camera.make_current()
			print("TAPE_INPUT enabled=",game.body.desktop_pointer.enabled," active=",game.body.desktop_pointer._active()," recovering=",game.recovering)
		if not await input_grab(tag+roll.kind+" / ",roll,shape,.4,.10):continue
		var a: Vector3=work.to_global(Vector3(-.60,1.68-i*.08,-.33))
		var b: Vector3=work.to_global(Vector3(.60,1.72-i*.08,-.33))
		await aim_tape(a);await held_trigger(true)
		await aim_tape(a.lerp(b,.35));await frames(24)
		await aim_tape(a.lerp(b,.7));await frames(24)
		await held_trigger(false)
		check(tag+roll.kind+" first click survives slow release and hand motion",not roll.start_anchor.is_empty() and roll.segments.is_empty() and roll.drag_points.size()==1 and roll.remaining==30)
		await aim_tape(b);await frames(6)
		check(tag+roll.kind+" preview connects start to current aim",roll.preview.visible and roll.preview.mesh!=null)
		await tape_fire(b)
		check(tag+roll.kind+" second click commits one continuous strip",roll.segments.size()==1 and roll.start_anchor.is_empty() and roll.segments[0].anchors.size()==2 and not roll.segments[0].anchors.any(func(a):return a.get("break_before",false)))
		await tape_fire(a);await drop_tool()
		check(tag+roll.kind+" drop cancels next unfinished line",roll.start_anchor.is_empty() and roll.segments.size()==1)
		# Put the finished tool back before testing the next roll. A closer hand
		# hold otherwise leaves that dropped collider across the next aiming ray.
		roll.transform=work.home_poses[str(roll.name)];await frames(4)
	var count_before: int=work.history.size()
	active_tag=tag+"station / ";await click(work,"UNDO");await frames(3)
	check(tag+"real Undo removes latest line",work.history.size()<count_before and work.rolls[2].remaining==30)
	await click(work,"TIDY");await frames(3)
	check(tag+"real Tidy resets all lines",work.rolls.all(func(r):return r.segments.is_empty() and r.remaining==30))
	game.queue_free();await frames(12)
	if xr:
		for t in [head,left,right]:XRServer.remove_tracker(t)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"scope":"Current Point Lines station; actual desktop mouse and synthetic XR grip/trigger inputs. Slow first clicks, moving preview, second-click commitment, cancellation and native Undo/Tidy. Adjacent asynchronous floors excluded; no route or physical headset assessment."}
	FileAccess.open(out.path_join("tape-rolls-player-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("TAPE_CLICK_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
