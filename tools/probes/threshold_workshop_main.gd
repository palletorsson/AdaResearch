extends "res://tools/probes/reference_primary_controls.gd"
## Same native player as the tutorial, with an additive draft until publication.
func start(use_xr: bool) -> void:
	xr = use_xr;Source.use_main_tower = true
	if xr:
		head = tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0));left = tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4));right = tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO);right.set_input("trigger_click",false);right.set_input("grip",0.0)
	game = load("res://commons/void/void.tscn").instantiate();game.force_xr = xr;root.add_child(game);current_scene = game
	if not xr:game.body.scripted_input = true
	await frames(45);game.scene_loaded();game.scene_visible();await frames(30);game.atmosphere.animate_sky = false;game.atmosphere.set_sky_time(180)

func run() -> void:
	root.size = Vector2i(1440,900);level = 14
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	for use_xr in [false,true]:
		await start(use_xr);var tag := "XR / " if xr else "Desktop / "
		check(tag+"main floor and existing logic are retained",game.checkpoint==14 and game.building.spec.width==42 and game.building.spec.depth==18 and game.building.content.data.floors[14].artifacts.size()==10 and is_instance_valid(station("logic-spring-and")))
		var y: float = game.building.spec.levels[14]
		game.place_player(Vector3(-19.2,y+.06,-3.6));await frames(25)
		for x in [-17.25,-10.45,-4.45,1.3,8.5,15.35]:
			check(tag+"actual north aisle is walkable to "+str(x),await move_to(Vector3(x,y,-3.6)))
		for kind in ["again","almost","just","barely","still","descent"]:
			var work: Node3D = station("threshold-workshop-"+kind);var console: Node3D = work.get_node("Controls")
			var foot := console.to_global(Vector3(0,0,1.6));foot.y = y+.06;game.place_player(foot);await frames(20)
			active_tag = tag+kind+" / "
			check(active_tag+"console stands on the solid north slab",game.body.is_on_floor() and game.body.global_position.z< -3.3 and not game.recovering)
			if kind=="almost":
				var h: float = work.release_height;await click(work,"RAISE");check(active_tag+"fine height control works in the tutorial",absf(work.release_height-h-.001)<.00001)
			if kind=="just":
				await click(work,"RELEASE");await frames(180);check(active_tag+"waits for hand-fed grains",work.grain_ids.is_empty())
				for grain in 2:
					await click(work,"Y");await frames(3)
					for n in 1300:
						if work.feed_ready or not work.running:break
						await frames(1)
			else:await click(work,"RELEASE")
			for n in 2500:
				if not work.running:break
				await frames(1)
			check(active_tag+"native observation completes under the actual crossings",work.result>=0 and work.take_history.size()==1)
			if kind=="just":check(active_tag+"actual six-grain physical tip on floor 14",work.result==1 and work.reading.get("grains",0)==6)
			if not xr:
				await input_aim_camera(work.to_global(Vector3(.5,1.2,.2)),20);await frames(3);await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out.path_join("threshold-main-"+kind+".png"))
			await click(work,"RESET");check(active_tag+"reset preserves the measured comparison",work.take_history.size()==1 and work.reading.is_empty())
		game.queue_free();await frames(12)
		if xr:
			for tracker in [head,left,right]:XRServer.remove_tracker(tracker)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"scope":"Actual main-tutorial floor 14, existing mezzanine/logic/shafts retained. Desktop and synthetic XR walking along the north aisle, pointer/trigger controls, actual physical observations and six-grain Just result. Native player captures; no physical headset acceptance."}
	FileAccess.open(out.path_join("threshold-main-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
