extends SceneTree
## Does the game sing this take? On the floor the game starts on, for each frame named in --takes, checks that
## the opera's score loaded, that the voice holds the take and that it is the frame's next line; then stands the
## visitor's own camera behind the frame, looks through it, and waits for the opera to start a line there. What
## the opera says it sang is the evidence (inner_opera.heard), with the picture at that moment. Where a floor's
## progression holds the line until the visitor has acted, the probe says so ("cue": "after an act") and reports
## the act the way the progression would, since it has no hands. A scripted run is
## quiet (the voice is at -80 dB), so this proves the line was made and started, not how it sounds.
##
##   python tools/run_floor_probe.py <Map> sings_the_take.gd sings_the_take.json <folder> --no-opening \
##       --takes=<frame>:<take>[,<frame>:<take>...]
##
## <out>/sings_the_take.json and one picture for each frame.

var game: Node
var folder := "res://ada_run/sings_the_take"
var wanted := {}
var result := {}


func _initialize() -> void:
	run.call_deferred()


func _check(checks: Array, what: String, ok: bool, more := {}) -> bool:
	var row := {"check": what, "ok": ok}
	row.merge(more)
	checks.append(row)
	return ok


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
		if arg.begins_with("--takes="):
			for pair in arg.trim_prefix("--takes=").split(",", false):
				wanted[pair.get_slice(":", 0)] = pair.get_slice(":", 1)
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var checks := []
	result = {"floor": int(game.checkpoint), "takes": [], "checks": checks, "passed": false}
	for i in 900: await physics_frame
	var opera: Node = game.get_meta("inner_opera", null) as Node
	if not _check(checks, "the opera is in the game", opera != null and is_instance_valid(opera)):
		_done(); return
	var error := str(opera.get("score_error"))
	_check(checks, "the score loaded with the edition as it stands", error.is_empty(), {"error": error})
	var voice: Node = opera.get("voice") as Node
	var phrases: Dictionary = voice.get("phrases")
	var eye := root.get_camera_3d()
	game.body.set_physics_process(false)
	game.body.set_process(false)
	for base: String in wanted:
		var take: String = wanted[base]
		var row := {"frame": base, "take": take}
		result.takes.append(row)
		if not _check(checks, "the voice holds " + take, phrases.has(take), {"text": str(phrases.get(take, {}).get("text", ""))}): continue
		var next := str(opera.call("_next_line", base))
		_check(checks, "it is the next line of " + base, next == take, {"next": next})
		var field: Node3D
		for node in get_nodes_in_group("song_fields"):
			if str(node.get("song_id")) == base and (field == null or node.has_node("OperaFrame")): field = node as Node3D
		if not _check(checks, "the floor has a framed field for " + base, field != null and field.has_node("OperaFrame")): continue
		var frame := field.get_node("OperaFrame") as Node3D
		# let the frame take its pose and wait out a line that is still sounding or resting
		for i in 60: await physics_frame
		var before: int = (opera.get("heard") as Array).size()
		# A frame on a floor with a progression waits for the visitor's act (lift, join, draw). The probe has no
		# hands: it reports that, then says the act happened the way the progression does.
		row["cue"] = "gaze" if bool(opera.call("field_available", base)) else "after an act"
		if row.cue != "gaze": opera.call("queue_encounter_song", base)
		eye.global_position = frame.to_global(Vector3(0, 0, 1.0))
		eye.look_at(frame.to_global(Vector3(0, 0, -4.0)), Vector3.UP)
		var sang := {}
		var waited := 0
		while waited < 2400 and sang.is_empty():
			await physics_frame
			waited += 1
			var heard: Array = opera.get("heard")
			for i in range(before, heard.size()):
				if str(heard[i].get("encounter", heard[i].get("object", ""))) == base or str(heard[i].get("object", "")) == take:
					sang = heard[i]
		row["frame_lit"] = bool(frame.get("lit"))
		row["waited_s"] = snappedf(waited / 60.0, 0.1)
		row["heard"] = sang
		row["cost"] = (voice.get("costs") as Dictionary).get(take, {})
		_check(checks, "looking through the frame, the opera sang " + take, str(sang.get("object", "")) == take and bool(sang.get("sung", false)),
			{"heard": str(sang.get("object", "")), "text": str(sang.get("text", "")), "on_display": sang.get("on_display", false), "after_s": row.waited_s, "cue": row.cue})
		for i in 20: await physics_frame
		for i in 4: await process_frame
		await RenderingServer.frame_post_draw
		var file := "sings_%s.png" % base
		root.get_texture().get_image().save_png(folder.path_join(file))
		row["picture"] = file
		# out of the frame, and let the line end before the next one
		eye.global_position += Vector3(0, 30, 0)
		var quiet := 0
		while quiet < 1500 and bool(voice.call("is_sounding")):
			await physics_frame
			quiet += 1
		for i in 240: await physics_frame
	_done()


func _done() -> void:
	result.passed = (result.checks as Array).all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("sings_the_take.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	quit()
