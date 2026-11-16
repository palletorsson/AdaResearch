extends SceneTree
## YOU ARE THE FOURTH CENTRE on its floor (ML_Classification; the pass, 2026-11-16)
## The tutorial's observations as things that do not move; three posts and the visitor are the centres. Read in
## the running tower with its own walker:
##   at rest: the heaps, twelve things, assigned with the gold post as the fourth centre: 4, 4, 1, 3 as the
##     bench has it, the sum of squares 4.72;
##   the walker steps onto the field: the colours are cleared and no line is drawn;
##   it stands still on the third heap: assigned again, 4, 0, 4, 4; seven things changed group and none moved;
##     its own four are all of one kind;
##   MEANS: the three posts go to the mean of their things, the second, with nothing, stays; the colours are
##     cleared; a gold disc lies at the mean of the walker's four;
##   it walks to the gold disc and stands: nothing changes, and the sum of squares has fallen to 0.2;
##   DATASET: rings, twenty-four things, the gold post back at its start; DATASET: block, twenty-five, four
##     groups where none were planted; DATASET: the heaps return as they were;
##   the axis: `rings` is found with twenty-four things; `blobs` restores.
##
##   godot --path <stage> --script res://tools/probes/fourth_centre_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## centre.json: checks with what was read (written after every check). arrival.png, approach.png, asked.png,
## rings.png, above.png.
const ID := "fourth-centre"
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
	var file := FileAccess.open(folder.path_join("centre.json"), FileAccess.WRITE)
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
	await _go(work.unit_point(x, z))
	for i in 80: await physics_frame
	return work.state()


func _press(key: String) -> Dictionary:
	await _go(_at(4.0, 3.6))
	await _go(work.plate_point(key))
	for i in 90: await physics_frame
	return work.state()


func _near(a: float, b: float, by: float) -> bool:
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
	if work != null and work.has_method("unit_point"):
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
		await _shot(_at(2.2, 4.6) + Vector3(0, 1.65, 0), _at(-0.4, -3.0) + Vector3(0, 1.6, 0), "approach.png")
		work.apply_grid_config({"cohort": "rings"})
		work.apply_grid_config({"cohort": "blobs"})
		var s: Dictionary = work.state()
		var first_centres: Array = s.centres
		checks.append({"check": "at rest: the heaps, twelve things, assigned with the gold post as the fourth centre: 4, 4, 1, 3 as the bench has it, the sum of squares 4.72",
			"ok": str(s.cohort) == "blobs" and int(s.things) == 12 and bool(s.assigned) and Array(s.sizes) == [4, 4, 1, 3] and _near(float(s.squares), 4.715, 0.01) and str(s.who) == "post" and int(s.ties_shown) == 12,
			"sizes": s.sizes, "squares": snappedf(float(s.squares), 0.001), "build_ms": int(s.build_ms)})
		_save()
		game.place_player(_at(3.6, 3.6) + Vector3(0, 0.3, 0))
		for i in 30: await physics_frame
		await _go(_at(2.0, 2.6))
		for i in 6: await physics_frame
		var cleared: Dictionary = work.state()
		checks.append({"check": "the walker steps onto the field: the colours are cleared and no line is drawn", "ok": str(cleared.who) == "visitor" and not bool(cleared.assigned) and int(cleared.ties_shown) == 0
			and str(cleared.status).contains("INTERRUPTED"), "status": str(cleared.status)})
		_save()
		var asked: Dictionary = await _stand(0.0, 0.7)
		await _shot(_at(2.6, 4.4) + Vector3(0, 3.0, 0), _at(-0.4, -1.6) + Vector3(0, 1.2, 0), "asked.png")
		checks.append({"check": "it stands still on the third heap: assigned again, 4, 0, 4, 4; seven things changed group and none moved; its own four are all of one kind",
			"ok": bool(asked.assigned) and Array(asked.sizes) == [4, 0, 4, 4] and int(asked.changed) == 7 and Array(asked.yours_by_kind) == [0, 0, 4] and str(asked.status).contains("NONE OF THEM MOVED"),
			"sizes": asked.sizes, "changed": int(asked.changed), "yours_by_kind": asked.yours_by_kind, "squares": snappedf(float(asked.squares), 0.001), "status": str(asked.status)})
		_save()
		var meant: Dictionary = await _press("means")
		var c: Array = meant.centres
		checks.append({"check": "MEANS: the three posts go to the mean of their things, the second, with nothing, stays; the colours are cleared; a gold disc lies at the mean of the walker's four",
			"ok": not bool(meant.assigned) and _near(float(c[0][0]), -0.8, 0.001) and _near(float(c[0][1]), -0.6, 0.001) and _near(float(c[1][0]), float(first_centres[1][0]), 0.001) and _near(float(c[1][1]), float(first_centres[1][1]), 0.001)
			and _near(float(c[2][0]), 0.8, 0.001) and _near(float(c[2][1]), -0.6, 0.001) and bool(meant.mean_shown) and _near(float(meant.mean_of_yours[0]), 0.0, 0.001) and _near(float(meant.mean_of_yours[1]), 0.7, 0.001)
			and str(meant.status).contains("YOURS TO WALK"), "posts": [c[0], c[1], c[2]], "mean_of_yours": meant.mean_of_yours})
		_save()
		var settled: Dictionary = await _stand(float(meant.mean_of_yours[0]), float(meant.mean_of_yours[1]))
		checks.append({"check": "it walks to the gold disc and stands: nothing changes, and the sum of squares has fallen to 0.2", "ok": bool(settled.assigned) and int(settled.changed) == 0 and Array(settled.sizes) == [4, 0, 4, 4]
			and float(settled.squares) < 0.3, "squares": snappedf(float(settled.squares), 0.001), "sizes": settled.sizes})
		_save()
		var rings: Dictionary = await _press("dataset")
		await _shot(_at(2.6, 4.4) + Vector3(0, 3.4, 0), _at(-0.2, -1.2) + Vector3(0, 0.8, 0), "rings.png")
		var block: Dictionary = await _press("dataset")
		var again: Dictionary = await _press("dataset")
		var sizes_block: Array = block.sizes
		checks.append({"check": "DATASET: rings, twenty-four things, the gold post back at its start; DATASET: block, twenty-five, four groups where none were planted; DATASET: the heaps return as they were",
			"ok": str(rings.cohort) == "rings" and int(rings.things) == 24 and bool(rings.assigned) and _near(float(rings.centres[3][1]), -0.8, 0.001) and str(block.cohort) == "block" and int(block.things) == 25
			and sizes_block.min() > 0 and str(block.status).contains("NO GROUPS WERE PLANTED") and str(again.cohort) == "blobs" and Array(again.sizes) == [4, 4, 1, 3] and _near(float(again.squares), 4.715, 0.01),
			"rings": rings.sizes, "block": block.sizes, "heaps": again.sizes})
		_save()
		game.place_player(Vector3(13.5, level + 0.3, 7.6))
		for i in 30: await physics_frame
		await _shot(_at(4.6, 5.2) + Vector3(0, 4.8, 0), _at(-0.4, -0.6) + Vector3(0, 0.6, 0), "above.png")
		work.apply_grid_config({"cohort": "rings"})
		var a: Dictionary = work.state()
		work.apply_grid_config({"cohort": "blobs"})
		var b: Dictionary = work.state()
		checks.append({"check": "the axis: `rings` is found with twenty-four things; `blobs` restores", "ok": int(a.things) == 24 and int(b.things) == 12 and Array(b.sizes) == [4, 4, 1, 3]})
		_save()
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[fourth_centre_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
