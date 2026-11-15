extends SceneTree
## ONLY WHAT YOU HAVE MADE on its floor (Brouwer_Intuitionism; the pass, 2026-11-15)
## A walkway out over the slab's edge that grows only by the walker's own choices; beside it one that a clock
## lays. Read in the running tower with its own walker:
##   at rest the row is empty: a deck at the edge, two plates on it, a question mark ahead;
##   the walker waits on the deck: nothing is laid;
##   standing on 0 lays one plank ahead to the left, beyond the slab's edge; the walker walks out onto it and no
##   fall is counted;
##   1, then 1: the row is 011, the planks lie left, middle, right, and the witness is plank 2;
##   back on the deck, RESET clears the row;
##   1 then 0 is another walkway than 0 then 1: its first plank lies to the right;
##   the clock's walkway lays planks with nobody on it.
##
##   godot --path <stage> --script res://tools/probes/made_walk_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## walk.json: checks with what was read (written after every check). deck.png, out.png, row.png, clock.png.
var game: Node3D
var body: CharacterBody3D
var work: Node3D
var eye: SubViewport
var folder := ""
var result := {}


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("walk.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, name: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(folder.path_join(name))


func _go(target: Vector3, ticks_max: int = 500, speed: float = 0.3) -> void:
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.07: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 10: await physics_frame


## Stand on a plate until the row changes (or two seconds have gone).
func _stand(bit: int) -> void:
	var before: String = str(work.state().row)
	await _go(work.plate_point(bit))
	for i in 150:
		if str(work.state().row) != before: break
		await physics_frame
	for i in 10: await physics_frame


func _work(floor: int, id: String) -> Node3D:
	for i in 1500:
		if game.building.content.exhibits.has("%d/%s" % [floor, id]): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, id])
	return mount.get_node_or_null("Artifact") if mount != null else null


func run() -> void:
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
	result = {"floor": floor, "map": str(record.map), "checks": checks, "passed": false}
	work = await _work(floor, "made-walk")
	var timed: Node3D = await _work(floor, "clock-walk")
	if work != null and work.has_method("plate_point"):
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
		work.apply_grid_config({"author": "hand"})
		var s: Dictionary = work.state()
		checks.append({"check": "at rest the row is empty: a deck at the edge, two plates on it, a question mark ahead", "ok": int(s.count) == 0 and bool(s.plates) and str(s.ahead) == "?", "slots": int(s.slots), "build_ms": int(s.build_ms)})
		_save()
		game.place_player(work.plank_point(0) + Vector3(0, 0.3, 2.2))
		for i in 40: await physics_frame
		await _go(work.plank_point(0) + Vector3(0, 0, 0.3))
		await _shot(cam, work.plank_point(0) + Vector3(2.2, 1.9, 3.6), work.plank_point(0) + Vector3(0, 0.6, -2.0), "deck.png")
		for i in 200: await physics_frame
		checks.append({"check": "the walker waits on the deck: nothing is laid", "ok": int(work.state().count) == 0})
		_save()
		await _stand(0)
		var one: Dictionary = work.state()
		await _go(work.plank_point(1))
		for i in 30: await physics_frame
		var beyond: float = work.to_local(body.global_position).z
		await _shot(cam, work.plank_point(0) + Vector3(2.4, 1.8, 2.8), work.plank_point(1) + Vector3(0, 0.8, 0), "out.png")
		checks.append({"check": "standing on 0 lays one plank ahead to the left, beyond the slab's edge; the walker walks out onto it and no fall is counted", "ok": str(one.row) == "0" and float(one.plank_x[0]) < -0.4 and beyond < -0.9
			and absf(body.global_position.y - level) < 0.3 and not bool(game.recovering), "row": str(one.row), "plank_x": one.plank_x, "walker_z": snappedf(beyond, .01), "recovering": bool(game.recovering)})
		_save()
		await _stand(1)
		await _go(work.plank_point(2))
		await _stand(1)
		await _go(work.plank_point(3))
		var three: Dictionary = work.state()
		await _shot(cam, work.plank_point(0) + Vector3(2.6, 2.2, 2.6), work.plank_point(2) + Vector3(0, 0.6, 0), "row.png")
		checks.append({"check": "1, then 1: the row is 011, the planks lie left, middle, right, and the witness is plank 2", "ok": str(three.row) == "011" and int(three.witness) == 2 and float(three.plank_x[0]) < float(three.plank_x[1])
			and float(three.plank_x[1]) < float(three.plank_x[2]) and str(three.board).contains("plank 2") and not bool(game.recovering), "row": str(three.row), "plank_x": three.plank_x, "witness": int(three.witness)})
		_save()
		for k in [2, 1, 0]: await _go(work.plank_point(k))
		await _stand(2)
		var cleared: Dictionary = work.state()
		checks.append({"check": "back on the deck, RESET clears the row", "ok": int(cleared.count) == 0 and str(cleared.ahead) == "?", "count": int(cleared.count)})
		_save()
		await _go(work.plank_point(0) + Vector3(0, 0, 0.35))
		await _stand(1)
		await _go(work.plank_point(1))
		await _stand(0)
		var other: Dictionary = work.state()
		checks.append({"check": "1 then 0 is another walkway than 0 then 1: its first plank lies to the right", "ok": str(other.row) == "10" and float(other.plank_x[0]) > 0.4, "row": str(other.row), "plank_x": other.plank_x})
		_save()
		for k in [0]: await _go(work.plank_point(k))
		await _stand(2)
		if timed != null:
			var before: int = int(timed.state().count)
			for i in 330: await physics_frame
			var after: Dictionary = timed.state()
			await _shot(cam, timed.plank_point(0) + Vector3(2.6, 2.2, 3.2), timed.plank_point(0) + Vector3(0, 0.4, -3.0), "clock.png")
			checks.append({"check": "the clock's walkway lays planks with nobody on it", "ok": str(after.author) == "clock" and int(after.count) != before and not bool(after.plates), "row": str(after.row), "before": before})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[made_walk_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
