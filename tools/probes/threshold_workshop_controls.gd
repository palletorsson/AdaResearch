extends "res://tools/probes/reference_primary_controls.gd"
## Exercise new controls through the real desktop pointer and synthetic XR.
func run() -> void:
	trial = "matter_logic_reference";root.size = Vector2i(1440,900)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
		if arg.begins_with("--levels="):
			for value in arg.trim_prefix("--levels=").split(","):selected.append(int(value))
	for use_xr in [false,true]:
		level = 27;await start(use_xr)
		for index in range(27,33):
			if not selected.is_empty() and index not in selected:continue
			var work: Node3D = await visit_floor(index)
			if index==28:
				var h: float = work.release_height;await click(work,"RAISE");check(active_tag+"actual release height rises one millimetre",absf(work.release_height-h-.001)<.00001)
				await click(work,"LOWER");check(active_tag+"release height returns one millimetre",absf(work.release_height-h)<.00001)
			await click(work,"RELEASE");await frames(60)
			if index==29:
				check(active_tag+"manual mode waits for a human grain",not work.auto_feed and work.grain_ids.is_empty())
				await click(work,"Y")
				for n in 600:
					if work.grain_ids.size()>0:break
					await frames(1)
				check(active_tag+"one grain command creates one physical grain",work.grain_ids.size()==1)
				await click(work,"AUTO_FEED");check(active_tag+"source automatic feeding can be selected",work.auto_feed)
			else:
				await click(work,"Y");check(active_tag+"repeat restarts actual physics",work.running and work.elapsed<1)
			await click(work,"RESET");check(active_tag+"reset clears current take",not work.running and work.reading.is_empty())
			await input_aim_camera(work.get_node("Controls").to_global(Vector3(.5,.5,.1)),20);await frames(3);await RenderingServer.frame_post_draw
			if not use_xr:root.get_texture().get_image().save_png(out.path_join("threshold-controls-"+str(level)+".png"))
		game.queue_free();await frames(12)
		if xr:
			for tracker in [head,left,right]:XRServer.remove_tracker(tracker)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"floors":selected if not selected.is_empty() else [27,28,29,30,31,32],"scope":"New workshop controls on the listed registered study floors, actual rendered desktop mouse and synthetic XR triggers. No physical-headset acceptance."}
	FileAccess.open(out.path_join("threshold-workshop-controls"+("-focus" if not selected.is_empty() else "")+"-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
