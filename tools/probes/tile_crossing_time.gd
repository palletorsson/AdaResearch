extends SceneTree
## HOW FAST CAN A BODY CROSS SHAFT B? (vanishing_tile_crossing on floor Random_Game; Palle, 2026-11-12: "start with
## a structure like this and add tiles instead and see how fast you can cross shaft B")
## The Void's own walker crosses the field of tiles over the shaft, there and back, with one rule: step only onto a
## tile that will still stand for 0.7 s, forward first, then diagonally, then sideways; wait if none does; leave a
## tile that is about to go. Read: the times, and whether the work's own clock recorded them. A fall ends the run.
##
##   godot --path <stage> --script res://tools/probes/tile_crossing_time.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## crossing_time.json: checks with what was read. arrival.png from the spawn point, field.png from above the south
## rim, rim.png from the west rim at eye height.
var game: Node3D
var work: Node3D
var level := 0.0


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	cam.current = true
	for i in 4: await process_frame
	root.get_viewport().get_texture().get_image().save_png(path)
	cam.current = false


## One crossing in direction `dir` (+1 east, -1 west). Returns {crossed, fell, seconds, waited}.
func _cross(body: CharacterBody3D, dir: int) -> Dictionary:
	var half: float = float(work.size.x) / 2.0
	var across: Vector2i = work.tiles_across()
	var start: Vector3 = work.to_global(Vector3(-dir * (half + 0.7), 0, 0.25))
	game.place_player(Vector3(start.x, level + 0.3, start.z))
	for i in 40: await physics_frame
	var began := -1
	var waited := 0
	for tick in 2400:
		var local: Vector3 = work.to_local(body.global_position)
		if local.y < -1.0:
			body.drive = Vector2.ZERO
			return {"crossed": false, "fell": true, "seconds": snappedf((tick - maxi(began, 0)) / 60.0, .1), "waited": snappedf(waited / 60.0, .1)}
		var on_field: bool = absf(local.x) < half and absf(local.z) < float(work.size.y) / 2.0
		if on_field and began < 0: began = tick
		if local.x * dir > half + 0.35:
			body.drive = Vector2.ZERO
			return {"crossed": true, "fell": false, "seconds": snappedf((tick - maxi(began, 0)) / 60.0, .1), "waited": snappedf(waited / 60.0, .1)}
		var here: Vector2i = work.tile_at(local)
		var target := Vector3.INF
		var options: Array[Vector2i] = []
		if not on_field and local.x * dir < 0:
			var column := 0 if dir > 0 else across.x - 1
			for dj in [0, 1, -1, 2, -2]: options.append(Vector2i(column, clampi(here.y + dj, 0, across.y - 1)))
		else:
			for step in [Vector2i(dir, 0), Vector2i(dir, 1), Vector2i(dir, -1), Vector2i(0, 1), Vector2i(0, -1)]: options.append(here + step)
		var last_column: bool = on_field and here.x == (across.x - 1 if dir > 0 else 0)
		if last_column:
			target = work.to_global(Vector3(dir * (half + 0.6), 0, local.z))
		else:
			for option in options:
				if work.holds(option.x, option.y, 0.7):
					target = work.to_global(work.tile_centre(option.x, option.y)); break
			if target == Vector3.INF and on_field and not work.holds(here.x, here.y, 0.35):
				for step in [Vector2i(-dir, 0), Vector2i(-dir, 1), Vector2i(-dir, -1)]:      # the tile underfoot is going: back off
					var back: Vector2i = here + step
					if work.holds(back.x, back.y, 0.5): target = work.to_global(work.tile_centre(back.x, back.y)); break
		if target == Vector3.INF:
			body.drive = Vector2.ZERO
			waited += 1
		else:
			body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
			body.drive = Vector2(0, -1)
		await physics_frame
	body.drive = Vector2.ZERO
	return {"crossed": false, "fell": false, "seconds": 40.0, "waited": snappedf(waited / 60.0, .1)}


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
	var item = null
	for a in record.artifacts:
		if str(a.artifact) == "vanishing_tile_crossing": item = a
	checks.append({"check": "the tile crossing lies on this floor", "ok": item != null})
	if item != null:
		var key := str(floor) + "/" + str(item.id)
		for i in 900:
			if game.building.content.exhibits.has(key): break
			await physics_frame
		var mount: Node3D = game.building.content.exhibits.get(key)
		for n in [mount] + mount.find_children("*", "Node3D", true, false):
			if n.has_method("holds"): work = n; break
		for i in 240: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		var centre: Vector3 = work.global_position
		for layer in root.find_children("*", "CanvasLayer", true, false):      # the game's overlays, not a work's own layers
			if layer.get_viewport() == root: layer.hide()
		game.place_player(Vector3(-3.6, level + 0.3, 8.6))      # aside, not in front of the lens
		for i in 30: await physics_frame
		var cam := Camera3D.new()
		root.add_child(cam)
		await _shot(cam, Vector3(0, level + 1.6, 7.8), Vector3(centre.x * 0.6, level + 0.6, 0), folder.path_join("arrival.png"))
		await _shot(cam, Vector3(centre.x, level + 5.0, centre.z + 6.2), Vector3(centre.x, level, centre.z - 0.4), folder.path_join("field.png"))
		await _shot(cam, Vector3(centre.x - 4.4, level + 1.6, centre.z + 0.3), Vector3(centre.x + 1.0, level, centre.z), folder.path_join("rim.png"))
		var first: Dictionary = work.score()
		checks.append({"check": "many tiles, most of them standing at any moment", "ok": int(first.tiles) >= 100 and int(first.standing) > int(first.tiles) / 3,
			"tiles": int(first.tiles), "standing": int(first.standing)})
		var runs := []
		var dir := 1
		for attempt in 4:
			var one: Dictionary = await _cross(body, dir)
			one["toward"] = "east" if dir > 0 else "west"
			runs.append(one)
			if one.fell: break
			dir = -dir
			for i in 30: await physics_frame
		var made := runs.filter(func(r): return r.crossed)
		var score: Dictionary = work.score()
		checks.append({"check": "the walker crosses shaft B on the tiles", "ok": made.size() >= 1, "runs": runs})
		checks.append({"check": "the work's own clock recorded the crossings", "ok": int(score.crossed) == made.size() and (made.is_empty() or float(score.best) > 0.0),
			"clock": {"last_s": snappedf(score.last, .1), "best_s": snappedf(score.best, .1), "crossed": int(score.crossed), "fell": int(score.fell)}})
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("crossing_time.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[tile_crossing_time] ", "PASSED" if result.passed else "FAILED")
	quit()
