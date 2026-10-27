extends "res://tools/probes/void_transfer_probe.gd"
## Close views from the actual desktop player, not an editor mockup.
func run() -> void:
	trial = "matter_logic_reference";root.size = Vector2i(1440,900)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	level = 1;await start(false);game.camera.fov = 65
	for index in [1,7,14,15,19,23,28,33,34,35,36]:
		level = index;game.place_player(game.spawn_for(level));await frames(25)
		var entry: Dictionary = game.building.content.data.floors[level].artifacts[0];var work: Node3D = station(entry.id);var console: Node3D = work.get_node("Controls")
		var foot: Vector3 = console.to_global(Vector3(0,0,1.65));foot.y = game.building.spec.levels[level]+.06;game.place_player(foot);await frames(20)
		var target := console.to_global(Vector3(0,.35,.12))
		if work.has_node("RuleSelector"):target = work.get_node("RuleSelector").to_global(Vector3(0,-.2,.12))
		await input_aim_camera(target,20);await frames(3);await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("controls-floor-"+str(level).pad_zeros(2)+"-desktop.png"))
		check("desktop console "+str(level)+" captured",game.checkpoint==level and not game.recovering)
	game.queue_free();await frames(12)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"scope":"Close views of actual desktop-player control panels. Controls are in their fresh-take state; these images are not physical-headset reach acceptance."}
	FileAccess.open(out.path_join("controls-capture-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
