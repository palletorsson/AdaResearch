extends SceneTree
## AN ARGUMENT STOOD ON ITS FLOOR, and the grid (Russell_Paradox; the pass, 2026-11-14)
## The authored cardboard of a hall (commons/data/arguments/<hall>.json) standing in the tower, and the first of its
## visual arguments. Read in the running tower with its own walker:
##   every plate, sticker and thread that is written stands (and nothing else), on crates and poles from the lab;
##   a body can walk up to a plate and is held off by it;
##   the grid shows the workbench's four sets, and the opposite of the diagonal is not one of its rows;
##   standing on a diagonal place, the board says where the new row disagrees with that row;
##   standing still on EVERYTHING, the row is carried in and its own place cannot be filled.
##
##   godot --path <stage> --script res://tools/probes/argument_floor_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## argument.json: checks with what was read. Pictures from inside the Void: arrival.png, hero.png, plate.png,
## plate_back.png, threads.png, overview.png, grid.png, everything.png.
var game: Node3D
var body: CharacterBody3D
var eye: SubViewport


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 6: await process_frame
	eye.get_texture().get_image().save_png(path)


func _go(target: Vector3, ticks_max: int = 900, speed: float = 0.34) -> void:
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.1: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 14: await physics_frame


func _work(floor: int, id: String) -> Node3D:
	for i in 1500:
		if game.building.content.exhibits.has("%d/%s" % [floor, id]): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, id])
	return mount.get_node_or_null("Artifact") if mount != null else null


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
	var argument: Node3D = await _work(floor, "argument")
	var grid: Node3D = await _work(floor, "diagonal-grid")
	if argument != null and argument.has_method("plate_point"):
		for i in 300: await physics_frame
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var up := Vector3(0, 0.3, 0)
		var base := Vector3(0, level, 0)
		body = game.body
		eye = SubViewport.new()
		eye.size = Vector2i(1280, 800)
		eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(eye)
		var cam := Camera3D.new()
		cam.fov = 80
		eye.add_child(cam)
		cam.current = true
		var s: Dictionary = argument.state()
		var kinds := {}
		for n in argument.find_children("*", "Node3D", true, false):
			if n.has_meta("prefab") and n.has_meta("source_scene"): kinds[str(n.get_meta("prefab"))] = int(kinds.get(str(n.get_meta("prefab")), 0)) + 1
		checks.append({"check": "every plate, sticker and thread that is written stands, on crates and poles from the lab", "ok": int(s.plates) == int(s.written) and int(s.plates) >= 6 and int(s.stickers) == int(s.stickers_written)
			and int(s.threads) == int(s.threads_written) and int(kinds.get("crate", 0)) == int(s.plates) * 2 and int(kinds.get("timber_plank_2m", 0)) == int(s.plates),
			"hall": str(s.hall), "plates": int(s.plates), "notes": int(s.notes), "stickers": int(s.stickers), "threads": int(s.threads), "kinds": kinds, "build_ms": int(s.build_ms)})
		await _shot(cam, base + Vector3(0, 1.6, 8.6), base + Vector3(0, 1.0, 2.0), folder.path_join("arrival.png"))
		var hero_at: Array = s.get("hero_at", [])
		var hero := base + (Vector3(float(hero_at[0]), 0, float(hero_at[1])) if hero_at.size() >= 2 else Vector3(0, 0, 7.0))
		await _shot(cam, hero + Vector3(0.0, 2.3, -3.4), hero + Vector3(0, 1.0, 0), folder.path_join("hero.png"))
		await _shot(cam, hero + Vector3(5.5, 3.4, -1.0), hero + Vector3(0, 0.4, 0), folder.path_join("hero_side.png"))
		# up to the first plate, and held off by it
		var first: String = str((s.tops as Dictionary).keys()[0])
		var front: Vector3 = argument.plate_point(first, 1.5)
		game.place_player(argument.plate_point(first, 2.6) + up)
		for i in 40: await physics_frame
		await _go(front)
		var reached: bool = Vector2(body.global_position.x - front.x, body.global_position.z - front.z).length() < 0.2
		await _shot(cam, argument.plate_point(first, 1.45) + Vector3(0, 1.25, 0), argument.plate_point(first, 0.0) + Vector3(0, 1.1, 0), folder.path_join("plate.png"))
		await _shot(cam, argument.plate_point(first, -1.5) + Vector3(0, 1.25, 0), argument.plate_point(first, 0.0) + Vector3(0, 1.1, 0), folder.path_join("plate_back.png"))
		await _go(argument.plate_point(first, -1.0), 240, 0.5)
		var stopped: float = Vector2(body.global_position.x - argument.plate_point(first, 0.0).x, body.global_position.z - argument.plate_point(first, 0.0).z).length()
		checks.append({"check": "a body can walk up to a plate and is held off by it", "ok": reached and stopped > 0.25 and stopped < 1.2, "plate": first, "stopped_m_from_the_plate": snappedf(stopped, .01)})
		await _shot(cam, base + Vector3(-1.2, 1.7, 4.4), base + Vector3(1.5, 2.9, -1.5), folder.path_join("threads.png"))
		await _shot(cam, base + Vector3(-9.5, 5.0, 8.4), base + Vector3(1.0, 0.6, 0.5), folder.path_join("overview.png"))
		var stickers: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, "argument-stickers"])
		if stickers != null:
			await _shot(cam, stickers.global_position + Vector3(0.6, 1.5, 3.4), stickers.global_position + Vector3(0, 1.35, 0), folder.path_join("stickers.png"))
			await _shot(cam, stickers.global_position + Vector3(-2.6, 1.6, 1.5), stickers.global_position + Vector3(0.6, 1.3, 0.3), folder.path_join("stickers_side.png"))
		checks.append({"check": "the thread words lie on text tape along the floor, one strip a thread", "ok": int(s.tapes) == int(s.threads), "tapes": int(s.tapes)})
		await _shot(cam, base + Vector3(-1.0, 1.65, 5.2), base + Vector3(-0.6, 0.0, 3.2), folder.path_join("tape.png"))
		if grid != null and grid.has_method("cell_point"):
			var g: Dictionary = grid.state()
			checks.append({"check": "the grid shows the workbench's four sets, and the opposite of the diagonal is not one of its rows", "ok": Array(g.rows) == ["0000", "1000", "1100", "1110"] and str(g.new_row) == "1111"
				and not bool(g.on_the_list) and bool(g.outside_shown) and not bool(g.fifth_shown), "rows": g.rows, "new_row": str(g.new_row), "stage": str(g.stage)})
			game.place_player(grid.cell_point(3, 0) + up)
			for i in 40: await physics_frame
			await _go(grid.cell_point(2, 2))
			for i in 20: await physics_frame
			var on: Dictionary = grid.state()
			await _shot(cam, grid.global_position + Vector3(-0.6, 4.8, 6.2), grid.global_position + Vector3(0.2, 0, 0.6), folder.path_join("grid.png"))
			checks.append({"check": "standing on a diagonal place, the board says where the new row disagrees with that row", "ok": int(on.standing_on) == 2 and str(on.board).contains("the new row is not row 2"), "standing_on": int(on.standing_on)})
			await _go(grid.cell_point(3, 3))
			await _go(grid.everything_plate())
			for i in 90: await physics_frame
			var all: Dictionary = grid.state()
			await _shot(cam, grid.global_position + Vector3(-0.6, 4.8, 6.2), grid.global_position + Vector3(0.6, 0, 0.8), folder.path_join("everything.png"))
			checks.append({"check": "standing still on EVERYTHING, the row is carried in and its own place cannot be filled", "ok": str(all.stage) == "everything" and bool(all.fifth_shown) and not bool(all.outside_shown)
				and str(all.board).contains("exactly when it does not"), "stage": str(all.stage)})
			grid.apply_grid_config({"stage": "new_row"})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the argument", "ok": false})
	var file := FileAccess.open(folder.path_join("argument.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[argument_floor_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
