extends SceneTree
## A SENTENCE, ITS SCOPE, ITS EVIDENCE on its floor (Crisis_Synthesis; the pass, 2026-11-15)
## Six cards behind the wall of the large sentence; five run a check when stood before, the sixth has none. Read in
## the running tower with its own walker:
##   six cards stand, none run, the sixth lettered as large as the others;
##   the walker stands before each of the first five and its check is run: refuted / a search stopped at its
##   budget / measured to zero / a witness or none in the row / a countermodel;
##   standing before the second again, the larger budget finds the derivation;
##   before the sixth nothing is run, and the card says so;
##   with `sixth` small its letters are smaller and its record is the same nothing.
##
##   godel --path <stage> --script res://tools/probes/six_cards_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## cards.json: checks with what was read (written after every check). cards.png, record.png, sixth.png.
var game: Node3D
var body: CharacterBody3D
var work: Node3D
var eye: SubViewport
var folder := ""
var result := {}


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("cards.json"), FileAccess.WRITE)
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


## Stand before a card until its check has been run once more (or two seconds have gone), then step back.
func _stand(i: int) -> String:
	var before: int = int(work.state().runs[i])
	await _go(work.plate_point(i))
	for k in 150:
		if int(work.state().runs[i]) != before: break
		await physics_frame
	var record: String = str(work.state().records[i])
	await _go(work.plate_point(i) + Vector3(0, 0, 0.75))
	return record


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
	for i in 1500:
		if game.building.content.exhibits.has("%d/six-cards" % floor): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get("%d/six-cards" % floor)
	work = mount.get_node_or_null("Artifact") if mount != null else null
	if work != null and work.has_method("plate_point"):
		for i in 200: await physics_frame
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
		body = game.body
		eye = SubViewport.new()
		eye.size = Vector2i(1280, 800)
		eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(eye)
		var cam := Camera3D.new()
		cam.fov = 80
		eye.add_child(cam)
		cam.current = true
		work.apply_grid_config({"sixth": "large"})
		var s: Dictionary = work.state()
		checks.append({"check": "six cards stand, none run, the sixth lettered as large as the others", "ok": Array(s.runs) == [0, 0, 0, 0, 0, 0] and int(s.sixth_letters) == int(s.other_letters), "letters": [int(s.other_letters), int(s.sixth_letters)],
			"build_ms": int(s.build_ms)})
		_save()
		await _shot(cam, work.plate_point(2) + Vector3(4.6, 2.0, 1.9), work.plate_point(2) + Vector3(0.6, 1.0, -1.2), "cards.png")
		game.place_player(work.plate_point(0) + Vector3(0, 0.3, 0.8))
		for i in 40: await physics_frame
		var records := []
		for i in 5: records.append(await _stand(i))
		await _shot(cam, work.plate_point(1) + Vector3(0.1, 1.5, 0.3), work.plate_point(1) + Vector3(0, 1.1, -1.25), "record.png")
		checks.append({"check": "the walker stands before each of the first five and its check is run: refuted / a search stopped at its budget / measured to zero / a witness or none in the row / a countermodel",
			"ok": str(records[0]).begins_with("REFUTED") and str(records[0]).contains("row 3 at place 3") and str(records[1]).begins_with("NOT FOUND within budget 4") and str(records[2]).begins_with("MEASURED") and str(records[2]).ends_with("= 0.0.")
				and (str(records[3]).begins_with("EXHIBITED") or str(records[3]).begins_with("NOT HERE")) and str(records[4]).begins_with("COUNTERMODEL") and str(records[4]).contains("the alarm is told true: no") and str(records[4]).contains("classically it follows: yes"),
			"records": records})
		_save()
		var again: String = await _stand(1)
		checks.append({"check": "standing before the second again, the larger budget finds the derivation", "ok": again.begins_with("FOUND and checked, budget 8"), "record": again})
		_save()
		var none: String = await _stand(5)
		await _shot(cam, work.plate_point(5) + Vector3(-0.2, 1.5, 0.3), work.plate_point(5) + Vector3(0, 1.1, -1.25), "sixth.png")
		checks.append({"check": "before the sixth nothing is run, and the card says so", "ok": none.begins_with("NOTHING WAS RUN") and none.contains("as large as"), "record": none})
		_save()
		work.apply_grid_config({"sixth": "small"})
		var small: String = await _stand(5)
		var after: Dictionary = work.state()
		checks.append({"check": "with `sixth` small its letters are smaller and its record is the same nothing", "ok": int(after.sixth_letters) < int(after.other_letters) and small.begins_with("NOTHING WAS RUN") and small.contains("smaller than"),
			"letters": [int(after.other_letters), int(after.sixth_letters)]})
		work.apply_grid_config({"sixth": "large"})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[six_cards_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
