extends "res://tools/probes/threshold_workshop_main.gd"
## Targeted correction: keep the ramp clear and expose Eventually's whole front.
func run() -> void:
	root.size = Vector2i(1440,900);level = 14
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	for use_xr in [false,true]:
		await start(use_xr);var tag := "XR / " if xr else "Desktop / ";var y: float = game.building.spec.levels[14]
		game.place_player(Vector3(8.5,y+.06,-3.6));await frames(20)
		for destination in [Vector3(13.1,y,-3.6),Vector3(13.1,y,4.25),Vector3(15.2,y,4.25)]:check(tag+"actual east-aisle approach "+str(destination),await move_to(destination))
		var work: Node3D = station("threshold-workshop-descent");active_tag = tag+"Eventually / "
		check(active_tag+"rotated placement keeps original scale",absf(work.global_rotation_degrees.y+90)<.01 and work.scale.is_equal_approx(Vector3.ONE))
		await click(work,"RELEASE")
		for n in 2500:
			if not work.running:break
			await frames(1)
		check(active_tag+"rotated native ball settles in a measured valley",work.result==1 and work.take_history.size()==1 and work.reading.outcome in ["shallow","middle","deep"])
		await click(work,"Y");check(active_tag+"repeat is reachable from east aisle",work.running)
		await click(work,"RESET");check(active_tag+"reset restores authored home",not work.running and work.local_position(work.graph.refs.ball).distance_to(work.v(work.graph.bodies.filter(func(b):return b.id==work.graph.refs.ball)[0].position))<.001)
		if not xr:
			await input_aim_camera(work.to_global(Vector3(.2,1.1,0)),20);await frames(3);await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out.path_join("threshold-main-descent.png"))
		game.queue_free();await frames(12)
		if xr:
			for tracker in [head,left,right]:XRServer.remove_tracker(tracker)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"scope":"Targeted actual main floor-14 east-bay correction after the original ramp occluded the view. Desktop/synthetic XR walk around shaft B, reach all three controls, rotate the unchanged native mechanism and record an actual settled valley. No physical-headset acceptance."}
	FileAccess.open(out.path_join("threshold-main-east-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
