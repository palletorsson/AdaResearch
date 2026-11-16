extends SceneTree
## THREE CORNERS ON ONE STRAIGHT LINE on its floor (Euclid_Parallel; the pass, gone back to on 2026-11-16)
## A and B on the floor, the visitor is C, a line through C and three wedges along it. Read in the running tower
## with its own walker:
##   at rest: the guide parallel, C the example ball; the corners add to 180 and the outer wedges are the
##     corners at A and B;
##   the walker stands at three places in the field: it is C each time, the corners differ from place to place,
##     add to 180 each time, and the outer wedges are the corners each time; three places counted;
##   nearly in a row with A and B: the reading is withheld, no wedge is drawn, and the stand says whose
##     threshold it is;
##   THE GUIDE, once: tilted; at a place in the field the three wedges along the line still add to 180, and the
##     outer two are eight degrees off the corners, one each way;
##   THE GUIDE, again: hidden; no line, three wedges at the three corners, a sum and a count;
##   THE GUIDE, a third time: parallel again;
##   the axis: `tilted` is found tilted; `parallel` restores.
##
##   godot --path <stage> --script res://tools/probes/three_wedges_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## wedges.json: checks with what was read (written after every check). arrival.png, approach.png, as_c.png,
## tilted.png, hidden.png, above.png.
const ID := "three-wedges"
var game: Node3D
var body: CharacterBody3D
var work: Node3D
var eye: SubViewport
var cam: Camera3D
var folder := ""
var result := {}
var level := 0.0


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("wedges.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()


func _shot(at: Vector3, target: Vector3, name: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 12: await physics_frame
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	eye.get_texture().get_image().save_png(folder.path_join(name))


func _go(target: Vector3, ticks: int = 1200) -> void:
	for i in ticks:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.07: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -(0.5 if d > 0.5 else 0.25))
		await physics_frame
	body.drive = Vector2.ZERO


func _at(x: float, z: float) -> Vector3:
	return work.local_point(x, z)


func _stand(x: float, z: float) -> Dictionary:
	await _go(_at(x, z))
	for i in 20: await physics_frame
	return work.state()


func _press() -> Dictionary:
	await _go(_at(3.65, -1.4))
	await _go(work.plate_point())
	for i in 90: await physics_frame
	return work.state()


func _near(a: float, b: float, by: float = 0.02) -> bool:
	return absf(a - b) < by


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
		if game.building.content.exhibits.has("%d/%s" % [floor, ID]): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, ID])
	work = mount.get_node_or_null("Artifact") if mount != null else null
	if work != null and work.has_method("plate_point"):
		for i in 200: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		body = game.body
		eye = SubViewport.new()
		eye.size = Vector2i(1280, 800)
		eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(eye)
		cam = Camera3D.new()
		cam.fov = 80
		eye.add_child(cam)
		cam.current = true
		game.place_player(Vector3(13.5, level + 0.3, 7.6))
		for i in 30: await physics_frame
		await _shot(Vector3(0, level + 1.65, 7.8), Vector3(0, level + 1.5, 0), "arrival.png")
		await _shot(_at(5.4, -1.6) + Vector3(0, 1.65, 0), _at(0.0, 0.8) + Vector3(0, 1.0, 0), "approach.png")
		work.apply_grid_config({"guide": "tilted"})
		work.apply_grid_config({"guide": "parallel"})
		var s: Dictionary = work.state()
		checks.append({"check": "at rest: the guide parallel, C the example ball; the corners add to 180 and the outer wedges are the corners at A and B", "ok": str(s.guide) == "parallel" and str(s.who) == "example"
			and _near(float(s.sum), 180.0, 0.001) and _near(float(s.along[0]), float(s.corners[0]), 0.001) and _near(float(s.along[2]), float(s.corners[1]), 0.001) and int(s.wedges_shown) == 5 and bool(s.line_shown),
			"corners": [snappedf(float(s.corners[0]), 0.1), snappedf(float(s.corners[1]), 0.1), snappedf(float(s.corners[2]), 0.1)], "build_ms": int(s.build_ms)})
		_save()
		game.place_player(_at(4.4, -1.4) + Vector3(0, 0.3, 0))
		for i in 30: await physics_frame
		var seen := []
		var all_ok := true
		for place in [[1.8, -1.6], [-0.4, -0.6], [-2.2, -2.0]]:
			var t: Dictionary = await _stand(place[0], place[1])
			seen.append([snappedf(float(t.corners[0]), 0.1), snappedf(float(t.corners[1]), 0.1), snappedf(float(t.corners[2]), 0.1)])
			all_ok = all_ok and str(t.who) == "visitor" and _near(float(t.sum), 180.0, 0.001) and _near(float(t.along[0]), float(t.corners[0]), 0.001) and _near(float(t.along[2]), float(t.corners[1]), 0.001) \
				and _near(float(t.c[0]), place[0], 0.12) and _near(float(t.c[1]), place[1], 0.12) and not bool(t.withheld)
			if place[0] < 0.0 and place[1] > -1.0: await _shot(_at(-0.4, -3.6) + Vector3(0, 3.2, 0), _at(-0.2, 1.6) + Vector3(0, 1.4, 0), "as_c.png")
		var counted: Dictionary = work.state()
		checks.append({"check": "the walker stands at three places in the field: it is C each time, the corners differ from place to place, add to 180 each time, and the outer wedges are the corners each time; three places counted",
			"ok": all_ok and seen[0] != seen[1] and seen[1] != seen[2] and int(counted.places) >= 3 and str(counted.status).contains("GRANTED, NOT MEASURED"), "corners_at_the_three": seen, "places": int(counted.places), "status": str(counted.status)})
		_save()
		var row: Dictionary = await _stand(0.0, 1.05)
		checks.append({"check": "nearly in a row with A and B: the reading is withheld, no wedge is drawn, and the stand says whose threshold it is", "ok": bool(row.withheld) and int(row.wedges_shown) == 0
			and str(row.status).contains("BELONGS TO THE INSTRUMENT"), "smallest_corner": snappedf(minf(float(row.corners[0]), float(row.corners[1])), 0.1), "status": str(row.status)})
		_save()
		var pressed: Dictionary = await _press()
		var tilted: Dictionary = await _stand(0.6, -1.2)
		await _shot(_at(0.6, -3.9) + Vector3(0, 3.4, 0), _at(0.2, 1.6) + Vector3(0, 1.4, 0), "tilted.png")
		checks.append({"check": "THE GUIDE, once: tilted; at a place in the field the three wedges along the line still add to 180, and the outer two are eight degrees off the corners, one each way",
			"ok": str(pressed.guide) == "tilted" and _near(float(tilted.along_sum), 180.0, 0.001) and _near(float(tilted.along[0]) - float(tilted.corners[0]), 8.0, 0.001)
			and _near(float(tilted.along[2]) - float(tilted.corners[1]), -8.0, 0.001) and str(tilted.status).contains("FILLING IT SHOWS NOTHING") and str(tilted.lines[2]).contains("IS NOT"),
			"along": [snappedf(float(tilted.along[0]), 0.1), snappedf(float(tilted.along[1]), 0.1), snappedf(float(tilted.along[2]), 0.1)], "corners": [snappedf(float(tilted.corners[0]), 0.1), snappedf(float(tilted.corners[1]), 0.1)],
			"line": str(tilted.lines[2])})
		_save()
		var hid: Dictionary = await _press()
		var hidden: Dictionary = await _stand(-1.0, -1.4)
		await _shot(_at(-1.0, -3.9) + Vector3(0, 3.4, 0), _at(-0.4, 1.6) + Vector3(0, 1.4, 0), "hidden.png")
		checks.append({"check": "THE GUIDE, again: hidden; no line, three wedges at the three corners, a sum and a count", "ok": str(hid.guide) == "hidden" and not bool(hidden.line_shown) and int(hidden.wedges_shown) == 3
			and str(hidden.lines[1]).contains("180") and str(hidden.status).contains("A PILE OF MEASUREMENTS IS NOT A PROOF"), "line": str(hidden.lines[1]), "status": str(hidden.status)})
		_save()
		var back: Dictionary = await _press()
		checks.append({"check": "THE GUIDE, a third time: parallel again", "ok": str(back.guide) == "parallel" and bool(back.line_shown)})
		_save()
		game.place_player(Vector3(13.5, level + 0.3, 7.6))
		for i in 30: await physics_frame
		await _shot(_at(3.4, -3.4) + Vector3(0, 4.6, 0), _at(-0.4, 0.4) + Vector3(0, 0.4, 0), "above.png")
		work.apply_grid_config({"guide": "tilted"})
		var a: Dictionary = work.state()
		work.apply_grid_config({"guide": "parallel"})
		var b: Dictionary = work.state()
		checks.append({"check": "the axis: `tilted` is found tilted; `parallel` restores", "ok": _near(float(a.along[0]) - float(a.corners[0]), 8.0, 0.001) and _near(float(b.along[0]), float(b.corners[0]), 0.001) and str(b.guide) == "parallel"})
		_save()
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[three_wedges_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
