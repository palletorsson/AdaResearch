extends SceneTree
## DOES THE PIPE WALK MAKE A PLAYGROUND? (pipe_dream with playground; Palle, 2026-11-12: "an automatic playground
## maker in pink and bleu add floor quads if all four corners are created")
## The walk is left to run out. Read: how many floor quads it laid and on how many levels. Then the Void's own walker
## is dropped onto one of the lowest quads (does it carry a body?), and walked onto the MAKE ANOTHER plate (does the
## playground begin again?).
##
##   godot --path <stage> --script res://tools/probes/pipe_playground.gd -- --no-bridges --void-start-floor=88
##       --out=<dir>
##
## playground.json: checks with what was read; front.png and side.png show the finished frame.
var game: Node3D


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	cam.current = true
	for i in 4: await process_frame
	root.get_viewport().get_texture().get_image().save_png(path)
	cam.current = false


func run() -> void:
	var folder := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var floor: int = game.checkpoint
	var record: Dictionary = game.building.content.data.floors[floor]
	var item = null
	for a in record.artifacts:
		if str(a.artifact) == "pipe_dream": item = a
	var checks := []
	var result := {"floor": floor, "map": str(record.map), "checks": checks, "passed": false}
	if item != null:
		var key := str(floor) + "/" + str(item.id)
		for i in 900:
			if game.building.content.exhibits.has(key): break
			await physics_frame
		var mount: Node3D = game.building.content.exhibits.get(key)
		var work: Node3D = null
		for n in [mount] + mount.find_children("*", "Node3D", true, false):
			if n.has_method("playground_state"): work = n; break
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
		checks.append({"check": "the room asked for it: playground is on", "ok": bool(work.playground)})
		var waited := 0
		while waited < 4800 and int(work.segment_count) < int(work.max_segments):
			await physics_frame
			waited += 1
		var state: Dictionary = work.playground_state()
		result["state"] = {"quads": state.quads, "levels": state.levels, "segments": state.segments, "seconds": snappedf(waited / 60.0, .1)}
		checks.append({"check": "the walk ran out", "ok": int(state.segments) >= int(state.of), "segments": state.segments})
		checks.append({"check": "it laid floor quads where four corners existed", "ok": int(state.quads) >= 30, "quads": state.quads})
		checks.append({"check": "on three levels or more", "ok": (state.levels as Dictionary).size() >= 3, "levels": (state.levels as Dictionary).size()})
		for layer in root.find_children("*", "CanvasLayer", true, false):      # the game's overlays, not a work's own layers
			if layer.get_viewport() == root: layer.hide()
		var cam := Camera3D.new()
		root.add_child(cam)
		var middle: Vector3 = work.global_position
		await _shot(cam, Vector3(middle.x, level + 1.7, middle.z + 6.5), Vector3(middle.x, level + 1.9, middle.z), folder.path_join("front.png"))
		await _shot(cam, Vector3(middle.x + 9.5, level + 3.4, middle.z + 5.0), Vector3(middle.x, level + 1.6, middle.z), folder.path_join("side.png"))
		var body: CharacterBody3D = game.body
		if state.a_low_quad != null:
			var quad: Vector3 = state.a_low_quad
			game.place_player(quad + Vector3(0, 1.0, 0))
			for i in 120: await physics_frame
			var feet: float = body.global_position.y - level
			var top: float = quad.y - level + 0.025
			checks.append({"check": "a floor quad carries a body", "ok": absf(feet - top) < 0.12, "feet_m": snappedf(feet, .01), "quad_top_m": snappedf(top, .01)})
		# the plate in front makes another
		var plate: Vector3 = work.to_global(Vector3(0, 0, float(work.bounds_extent.z) + 1.4))
		game.place_player(Vector3(plate.x, level + 0.3, plate.z + 1.2))
		for i in 40: await physics_frame
		for i in 300:
			if int(work.segment_count) < int(state.segments) / 2: break
			body.look_at(Vector3(plate.x, body.global_position.y, plate.z), Vector3.UP)
			body.drive = Vector2(0, -1)
			await physics_frame
		body.drive = Vector2.ZERO
		checks.append({"check": "stepping on MAKE ANOTHER begins a new playground", "ok": int(work.segment_count) < int(state.segments) / 2, "segments_now": int(work.segment_count)})
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "pipe_dream stands on this floor", "ok": false})
	var file := FileAccess.open(folder.path_join("playground.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[pipe_playground] ", "PASSED" if result.passed else "FAILED")
	quit()
