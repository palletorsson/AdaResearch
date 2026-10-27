extends "res://tools/probes/void_transfer_probe.gd"
## Actual player/streaming startup only. Mechanism evidence is in separate probes.
func run() -> void:
	trial = "matter_logic_reference"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	check("isolated test saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if failed.size()>0:quit(1);return
	for use_xr in [false,true]:
		level = 1;await start(use_xr)
		var tag := "Synthetic XR / " if xr else "Desktop / "
		for index in range(1,37):
			level = index;game.place_player(game.spawn_for(level));await frames(45)
			check(tag+"floor "+str(level)+" starts",game.checkpoint==level and not game.recovering)
			var entry: Dictionary = game.building.content.data.floors[level].artifacts[0]
			var mount: Node3D = game.building.content.exhibits.get(str(level)+"/"+str(entry.id))
			check(tag+"editable artifact loads "+str(level),mount!=null and mount.has_node("Artifact") and mount.get_node("Artifact").part_defaults.size()>0)
		game.queue_free();await frames(12)
		if xr:
			for item in [head,left,right]:XRServer.remove_tracker(item)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"scope":"All 36 study floors load with the actual desktop player and synthetic XR trackers. No physical-headset, reach, walkthrough or arbitrary assembly-edit mechanics acceptance."}
	FileAccess.open(out.path_join("player-load-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
