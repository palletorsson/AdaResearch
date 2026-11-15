extends SceneTree
## FIVE SQUARES AT EVERY CORNER on its floor (NonEuclidean_Spaces; the pass, 2026-11-15)
## A deck that shows a floor of square tiles, five, four or three at every corner, drawn round the one who walks
## it; a pink square painted on the deck. Read in the running tower with its own walker, once per floor:
##   standing still on START sets home under the walker's feet;
##   the painted square is walked - forward, left, forward, left, forward, left, forward - back to START;
##   five at a corner: home is about 2.4 m away and turned about 159 degrees (the bench: 2.444 m, 158.9);
##   four: home is under the feet;
##   three: home is about 1.2 m away and turned about 73 degrees the other way (the bench: 1.233 m, -73.1).
## The walker stops a hand's width from each corner, so the readings are held to the bench within 0.45 m and
## 25 degrees; the flat floor is held to 0.2 m.
##
##   godot --path <stage> --script res://tools/probes/walked_tiling_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## deck.json: checks with what was read. rest.png, <corner>_home.png, <corner>_back.png, walker.png.
const ID := "walked-tiling"
const BENCH := {"five": [2.444, 158.9], "four": [0.0, 0.0], "three": [1.233, -73.1]}
var game: Node3D
var body: CharacterBody3D
var work: Node3D
var eye: SubViewport


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(path)


func _go(target: Vector3, ticks_max: int = 700, speed: float = 0.3) -> void:
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.06: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 12: await physics_frame


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
	var checks := []
	var result := {"floor": floor, "map": str(record.map), "checks": checks, "passed": false}
	for i in 1500:
		if game.building.content.exhibits.has("%d/%s" % [floor, ID]): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, ID])
	work = mount.get_node_or_null("Artifact") if mount != null else null
	if work != null and work.has_method("square_point"):
		for i in 200: await physics_frame
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var up := Vector3(0, 0.3, 0)
		body = game.body
		eye = SubViewport.new()
		eye.size = Vector2i(1280, 800)
		eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(eye)
		var cam := Camera3D.new()
		cam.fov = 80
		eye.add_child(cam)
		cam.current = true
		var at: Vector3 = work.global_position
		var above: Vector3 = at + Vector3(-0.4, 4.6, 2.6)
		work.apply_grid_config({"corner": "five"})
		for i in 6: await physics_frame
		var rest: Dictionary = work.state()
		checks.append({"check": "the deck stands at rest, nobody on it, no home set", "ok": not bool(rest.on_deck) and not bool(rest.home_set) and absf(float(rest.inradius) - 0.5306) < 0.001, "inradius_m": float(rest.inradius),
			"build_ms": int(rest.build_ms)})
		await _shot(cam, above, at, folder.path_join("rest.png"))
		for corner in ["five", "four", "three"]:
			game.place_player(work.off_deck_point() + up)
			for i in 30: await physics_frame
			work.apply_grid_config({"corner": corner})
			for i in 10: await physics_frame
			await _go(work.square_point(0))
			for i in 90: await physics_frame
			var set: Dictionary = work.state()
			await _shot(cam, above, at, folder.path_join("%s_home.png" % corner))
			for leg in [1, 2, 3, 0]: await _go(work.square_point(leg))
			for i in 60: await physics_frame
			var back: Dictionary = work.state()
			await _shot(cam, above, at, folder.path_join("%s_back.png" % corner))
			if corner == "five": await _shot(cam, body.global_position + Vector3(-1.6, 1.7, 1.2), body.global_position + Vector3(1.4, 0.0, -1.2), folder.path_join("walker.png"))
			var want: Array = BENCH[corner]
			var near: bool = absf(float(back.home_m) - float(want[0])) < (0.2 if corner == "four" else 0.45)
			var turn: bool = corner == "four" or absf(wrapf(float(back.turned_deg) - float(want[1]), -180.0, 180.0)) < 25.0
			checks.append({"check": "%s at a corner: home is set on START, the square is walked back to START, and home is where the bench puts it" % corner, "ok": bool(set.home_set) and float(set.home_m) < 0.05
				and bool(back.back) and near and turn and float(back.walked_m) > 5.0, "home_m": float(back.home_m), "bench_m": float(want[0]), "turned_deg": float(back.turned_deg), "bench_deg": float(want[1]),
				"walked_m": float(back.walked_m), "tiles_crossed": int(back.tiles_crossed), "pointer": bool(back.pointer)})
		game.place_player(work.off_deck_point() + up)
		for i in 30: await physics_frame
		work.apply_grid_config({"corner": "five"})
		var left: Dictionary = work.state()
		checks.append({"check": "stepping off the deck clears home", "ok": not bool(left.on_deck) and not bool(left.home_set), "on_deck": bool(left.on_deck)})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	var file := FileAccess.open(folder.path_join("deck.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[walked_tiling_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
