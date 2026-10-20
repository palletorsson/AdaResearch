extends SceneTree

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var launcher: Node3D = load("res://commons/artifacts/cellular_spaces/museum.tscn").instantiate()
	root.add_child(launcher)
	current_scene=launcher
	var began := Time.get_ticks_msec()
	while not bool(launcher.museum.get("_museum_core_ready")) and Time.get_ticks_msec()-began<60000:
		await process_frame
	await create_timer(1).timeout
	launcher.museum.flush_stamps()
	var expected := "Noise_Cellular_Commons" if OS.get_cmdline_user_args().has("--cellular-form=commons") else "Noise_Cellular_Womb"
	var found := false
	for child in launcher.museum.get_children():
		if str(child.get_meta("em_map",""))==expected:
			for node in child.find_children("*","Node3D",true,false):
				if node.get_script()!=null and str(node.get_script().resource_path).ends_with("/cellular_space.gd"):
					found=not node.data.is_empty()
	var isolated := str(launcher.museum.get("EM_CONTROL")).begins_with("user://cellular-spaces/")
	var player: Node=launcher.museum.get("_player")
	var passed := found and isolated and player!=null
	var report := {"map":expected,"artifact_loaded":found,"isolated_control":isolated,"museum_player_present":player!=null,"passed":passed}
	FileAccess.open("res://doc/book/iterations/2026-10-13-cellular-spaces/launch-"+launcher.first_space+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("CELLULAR LAUNCH ",report)
	quit(0 if passed else 1)
