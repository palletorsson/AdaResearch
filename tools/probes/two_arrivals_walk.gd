extends SceneTree
## TWO ARRIVALS on its floor (PostCrisis_Synthesis; the pass, 2026-11-16)
## A line from START to END; the last two walks kept; a stand that reads them as a destination and as a path.
## Read in the running tower with its own walker, against the bench (tools/probes/two_arrivals_bench.py):
##   at rest, the two example walks: the earlier 6.00 m in 4.0 s with no pause and on the line; the latest 7.21 m
##     in 9.0 s with a pause of 3.0 s and 2.00 m off the line; both end at END, and the stand calls the
##     destinations the same;
##   the walker walks straight: that walk is the latest, on the line, and the example with the pause is now the
##     earlier;
##   it walks again by way of a place two metres south and stands there two seconds: the latest is longer, has a
##     pause and is 2 m off the line; both arrived within 0.45 m of END;
##   it stands on WITH DELIGHT: the latest walk carries that note, and the stand says somebody else wrote the word;
##   ONLY THE DESTINATION, and a third walk: the latest has no path and no dots; KEEP THE PATH again does not
##     give it one;
##   the axis: `destination` is found with neither path, `note` with RELUCTANTLY on the latest; `path` restores.
##
##   godot --path <stage> --script res://tools/probes/two_arrivals_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## arrivals.json: checks with what was read (written after every check). arrival.png, overview.png, walked.png.
const ID := "two-arrivals"
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
	var file := FileAccess.open(folder.path_join("arrivals.json"), FileAccess.WRITE)
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


## A walk from START to END by way of the places given, standing `wait` ticks at each.
func _walk(by: Array, wait: int = 0) -> Dictionary:
	game.place_player(_at(-3.0, 1.2) + Vector3(0, 0.3, 0))
	for i in 30: await physics_frame
	await _go(_at(-3.0, 0.0))
	for i in 15: await physics_frame
	for place in by:
		await _go(_at(place[0], place[1]))
		for i in wait: await physics_frame
	await _go(_at(3.0, 0.0))
	for i in 20: await physics_frame
	return work.state()


func _press(key: String) -> Dictionary:
	await _go(work.plate_point(key))
	for i in 90: await physics_frame
	return work.state()


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
		game.place_player(Vector3(13.5, level + 0.3, 7.6))        # out of its own arrival picture
		for i in 30: await physics_frame
		await _shot(Vector3(0, level + 1.65, 7.8), Vector3(0, level + 1.5, 0), "arrival.png")
		await _shot(Vector3(6.6, level + 4.8, 1.0), Vector3(-0.6, level + 0.6, -4.6), "overview.png")
		work.apply_grid_config({"keeps": "note"})
		work.apply_grid_config({"keeps": "path"})
		var s: Dictionary = work.state()
		var e: Dictionary = s.earlier
		var l: Dictionary = s.latest
		checks.append({"check": "at rest, the two example walks: the earlier 6.00 m in 4.0 s with no pause and on the line; the latest 7.21 m in 9.0 s with a pause of 3.0 s and 2.00 m off the line; both end at END, and the stand calls the destinations the same",
			"ok": absf(float(e.length) - 6.0) < 0.02 and absf(float(e.seconds) - 4.0) < 0.05 and float(e.pause) < 0.05 and float(e.off) < 0.01 and absf(float(l.length) - 7.21) < 0.02 and absf(float(l.seconds) - 9.0) < 0.05
			and absf(float(l.pause) - 3.0) < 0.05 and absf(float(l.off) - 2.0) < 0.01 and float(e.end_from_END) < 0.01 and float(l.end_from_END) < 0.01 and int(e.dots) == 241 and int(l.dots) == 541 and str(s.lines[0]).contains("THE SAME"),
			"earlier": e, "latest": l, "build_ms": int(s.build_ms)})
		_save()
		var straight: Dictionary = await _walk([])
		checks.append({"check": "the walker walks straight: that walk is the latest, on the line, and the example with the pause is now the earlier", "ok": float(straight.latest.off) < 0.15 and float(straight.latest.length) > 4.8
			and float(straight.latest.length) < 5.8 and absf(float(straight.earlier.length) - 7.21) < 0.02 and float(straight.latest.end_from_END) < 0.45, "latest": straight.latest, "earlier_length": float(straight.earlier.length)})
		_save()
		var round_way: Dictionary = await _walk([[0.0, 2.0]], 120)
		await _shot(_at(0.0, 6.6) + Vector3(0, 4.2, 0), _at(0.0, -0.6) + Vector3(0, 0.2, 0), "walked.png")
		checks.append({"check": "it walks again by way of a place two metres south and stands there two seconds: the latest is longer, has a pause and is 2 m off the line; both arrived within 0.45 m of END",
			"ok": float(round_way.latest.length) > float(round_way.earlier.length) + 1.0 and float(round_way.latest.pause) > 1.7 and absf(float(round_way.latest.off) - 2.0) < 0.15 and float(round_way.earlier.off) < 0.15
			and float(round_way.latest.end_from_END) < 0.45 and float(round_way.earlier.end_from_END) < 0.45, "latest": round_way.latest, "earlier": round_way.earlier})
		_save()
		var noted: Dictionary = await _press("WITH DELIGHT")
		checks.append({"check": "it stands on WITH DELIGHT: the latest walk carries that note, and the stand says somebody else wrote the word", "ok": str(noted.latest.note) == "WITH DELIGHT" and str(noted.earlier.note) == ""
			and str(noted.lines[4]).contains("somebody else wrote"), "line": str(noted.lines[4])})
		_save()
		var only: Dictionary = await _press("keep")
		var bare: Dictionary = await _walk([])
		var again: Dictionary = await _press("keep")
		checks.append({"check": "ONLY THE DESTINATION, and a third walk: the latest has no path and no dots; KEEP THE PATH again does not give it one", "ok": not bool(only.keep_path) and not bool(bare.latest.kept_path) and int(bare.latest.dots) == 0
			and bool(bare.earlier.kept_path) and float(bare.latest.end_from_END) < 0.45 and bool(again.keep_path) and not bool(again.latest.kept_path) and str(again.status).contains("DOES NOT GET ONE BACK")
			and str(again.lines[3]).contains("its path was not kept"), "line": str(again.lines[3]), "status": str(again.status)})
		_save()
		work.apply_grid_config({"keeps": "destination"})
		var d: Dictionary = work.state()
		work.apply_grid_config({"keeps": "note"})
		var n: Dictionary = work.state()
		work.apply_grid_config({"keeps": "path"})
		var p: Dictionary = work.state()
		checks.append({"check": "the axis: `destination` is found with neither path, `note` with RELUCTANTLY on the latest; `path` restores", "ok": not bool(d.earlier.kept_path) and not bool(d.latest.kept_path) and int(d.latest.dots) == 0
			and str(n.latest.note) == "RELUCTANTLY" and bool(n.latest.kept_path) and bool(p.latest.kept_path) and str(p.latest.note) == "" and int(p.latest.dots) == 541, "destination_dots": [int(d.earlier.dots), int(d.latest.dots)], "note": str(n.latest.note)})
		_save()
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[two_arrivals_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
