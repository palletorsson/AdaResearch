extends "res://tools/probes/noise_types_trial_probe.gd"
## Reviewer captures: keep the player on the photographed floor so streaming is real.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	take_photos = true
	DirAccess.make_dir_recursive_absolute(out)
	check("review uses isolated saves", OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:
		quit(1)
		return
	await start(true)
	var level: float = game.building.spec.levels[1]
	game.place_player(game.spawn_for(1))
	await frames(45)
	check("photographed floor is active", game.floor_stream.focus == 1)
	var weather: Node3D = game.building.content.exhibits["1/weather"].get_node("Artifact")
	weather.toggle_run()
	await frames(840)
	weather.toggle_run()
	await frames(65)
	check("weather has recorded visible apertures", weather.records.size() >= 6)
	await photo("bench-arrival", Vector3(12.9,level+1.65,2.4), Vector3(17.2,level+1.0,-0.6))
	await photo("bench-close", Vector3(15.6,level+1.6,-0.3), Vector3(17.6,level+1.1,-0.3))
	await photo("galleries", Vector3(16.8,level+1.65,2.4), Vector3(17.2,level+0.9,5.5))
	await photo("weather-corridor", Vector3(6.2,level+1.65,3.8), Vector3(-4,level+1.2,-2))
	await photo("weather-lane", Vector3(-2.65,level+1.65,5.6), Vector3(-2.65,level+1.3,-5))
	await photo("weather-controls", Vector3(2.2,level+1.65,-4.1), Vector3(-1.5,level+1.3,-6.2))
	await photo("wide-view", Vector3(20.5,level+1.9,8.3), Vector3(-4,level+0.6,-2))
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"passed":failed.is_empty(),"checks":checks,"failed":failed,
		"scope":"Native Mobile render, active Noise floor, synthetic XR rig; not physical headset evidence."
	},"\t"))
	game.queue_free()
	await frames(5)
	for item in [head,left,right]: XRServer.remove_tracker(item)
	quit(0 if failed.is_empty() else 1)
