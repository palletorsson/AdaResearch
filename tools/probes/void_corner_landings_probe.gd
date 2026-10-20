extends "res://tools/probes/void_game_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	for use_xr in [false,true]:
		await start(use_xr)
		var label := "XRTools / " if use_xr else "Desktop / "
		check(label+"two planks per lower floor", game.building.landing_pads.size()==26)
		check(label+"old suspended timber assembly absent", game.building.find_children("TimberDescent","",true,false).is_empty())
		for source in [0,1]:
			var destination: int=source+1
			var z := 1.9 if destination%2==1 else -1.9
			game.checkpoint=source
			game.place_player(Vector3(13.4,-6.0*source+0.06,z))
			game.health.reset()
			await frames(35)
			var before: int=game.cushioned_landings
			press_jump()
			axes(Vector2(-1,0))
			for i in range(100):
				await frames(1)
				if i==1: release_jump()
				if game.body.global_position.x<11.8: break
			axes(Vector2.ZERO)
			await frames(110)
			check(label+"jump onto floor %d pad survives"%destination,not game.recovering and game.deaths==0 and game.body.is_on_floor())
			check(label+"floor %d pad absorbs damage"%destination,game.health.get_health()==100 and game.cushioned_landings==before+1)
			check(label+"floor %d pad saves checkpoint"%destination,game.checkpoint==destination and absf(game.body.global_position.y+6.0*destination)<.16)
			if "--capture" in OS.get_cmdline_user_args() and not use_xr:
				game.camera.global_position=Vector3(13.7,-6.0*source+1.65,z)
				game.camera.look_at(Vector3(11.7,-6.0*destination,z))
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(out.path_join("landing-%d.png"%destination))
		game.queue_free();await frames(10)
		if use_xr:
			for t in [head,left,right]: XRServer.remove_tracker(t)
	FileAccess.open(out.path_join("landing-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"scope":"Real desktop and XRTools physics with synthetic tracking; no physical headset."},"\t"))
	quit(0 if failed.is_empty() else 1)
