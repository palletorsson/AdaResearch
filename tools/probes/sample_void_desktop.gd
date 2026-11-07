extends SceneTree
## One floor of the main tower as desktop play opens it (tools/launch_void_desktop.py), played by script
## (2026-11-07, Palle: "test one map in each sequence in desktop"). Opens the floor, waits for its works, stands 3 s,
## walks forward 2.5 s, photographs both, writes <out>/sample.json. Runner: tools/test_sequence_sample_desktop.py.
var game: Node3D
var folder := ""
var deaths: Array = []

func _initialize() -> void:
	open_game.call_deferred()

func open_game() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--play-output="):folder=arg.trim_prefix("--play-output=")
	load("res://commons/void/room_source.gd").use_main_tower=true
	game=load("res://commons/void/void.tscn").instantiate()
	root.add_child(game);current_scene=game
	game.died.connect(func(reason):deaths.append(reason))
	game.body.scripted_input=true;game.body.set_process_unhandled_input(false)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	game.scene_loaded();game.scene_visible()
	var floor: int=game.checkpoint
	var record: Dictionary=game.building.content.data.floors[floor]
	var t0 := Time.get_ticks_msec()
	var built := false
	for i in 600:
		if record.artifacts.all(func(a):return game.building.content.exhibits.has(str(floor)+"/"+a.id)):
			built=true;break
		await physics_frame
	var build_ms := Time.get_ticks_msec()-t0
	var missing: Array=record.artifacts.filter(func(a):return not game.building.content.exhibits.has(str(floor)+"/"+a.id)).map(func(a):return a.id)
	for i in 30:await physics_frame
	var level: float=game.building.spec.levels[floor]
	var start: Vector3=game.body.global_position
	await _wait_s(3.0)
	var fps_stand := Engine.get_frames_per_second()
	var stand_shot: String = await _shot("stand.png")
	var stood: Vector3=game.body.global_position
	game.body.drive=Vector2(0,-1)
	await _wait_s(2.5)
	game.body.drive=Vector2.ZERO
	await _wait_s(.5)
	var walked: Vector3=game.body.global_position
	var walk_shot: String = await _shot("walk.png")
	# blocked straight ahead (a work in front of the arrival)? try the other three ways: boxed in, or only blocked
	var other_ways := {}
	if Vector2(walked.x-stood.x,walked.z-stood.z).length() < .5:
		var ways := {"left":Vector2(-1,0),"right":Vector2(1,0),"back":Vector2(0,1)}
		for way in ways:
			var from: Vector3=game.body.global_position
			game.body.drive=ways[way]
			await _wait_s(1.5)
			game.body.drive=Vector2.ZERO
			await _wait_s(.3)
			other_ways[way]=Vector2(game.body.global_position.x-from.x,game.body.global_position.z-from.z).length()
	var report := {"floor":floor,"title":record.get("title",""),"map":record.get("map",""),
		"ready":game.ready_for_play,"built":built,"build_ms":build_ms,"artifacts":record.artifacts.size(),"missing":missing,
		"start":[start.x,start.y-level,start.z],"stood":[stood.x,stood.y-level,stood.z],"walked":[walked.x,walked.y-level,walked.z],
		"walk_m":Vector2(walked.x-stood.x,walked.z-stood.z).length(),"fell_m":stood.y-walked.y,
		"other_ways":other_ways,"grounded":game.body.is_on_floor(),"fps_stand":fps_stand,"fps_walk":Engine.get_frames_per_second(),
		"deaths":deaths,"current_floor":game.floor_stream.summary(),"shots":[stand_shot,walk_shot]}
	FileAccess.open(folder.path_join("sample.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("VOID_SAMPLE ",JSON.stringify(report))
	quit(0)

func _wait_s(seconds: float) -> void:
	var end := Time.get_ticks_msec()+int(seconds*1000.0)
	while Time.get_ticks_msec()<end:await physics_frame

func _shot(name: String) -> String:
	await process_frame
	await RenderingServer.frame_post_draw
	var path := folder.path_join(name)
	root.get_texture().get_image().save_png(path)
	return path
