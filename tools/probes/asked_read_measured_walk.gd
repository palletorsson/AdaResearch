extends SceneTree
## ASKED, READ BACK, MEASURED on its floor (QFEP_Synthesis; the pass, 2026-11-15)
## A mast on a sprung foot, plates that ask, a stand that keeps what was asked, what is read back and what was
## measured apart. Read in the running tower with its own walker (the expected figures are a spring's own:
## a swing takes 2 pi / sqrt(k - c*c/4), and exp(-c * that / 2) of it is left after one):
##   at rest: stiffness 9 and damping 0.8 asked, read back and built; six rings; nothing measured;
##   PULSE: a swing measured at 2.11 s, 0.43 of it left after one;
##   STIFFNESS asked to 16: asked and read back 16, built still 9, a swing still 2.11 s, and the stand says so;
##   REBUILD: nine rings, and a swing takes 1.58 s;
##   DAMPING asked to 2.0: taken at once; 0.20 of a swing is left after one;
##   DRAG asked to 0.5: asked and read back, and the swing and what is left are as they were;
##   BREATHE then STEADY: steady, the mast is still moving, and the stand says steady is not still.
##
##   godot --path <stage> --script res://tools/probes/asked_read_measured_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## mast.json: checks with what was read (written after every check). arrival.png, overview.png, pulse.png,
## asked.png.
const ID := "asked-read-measured"
var game: Node3D
var body: CharacterBody3D
var work: Node3D
var eye: SubViewport
var cam: Camera3D
var folder := ""
var result := {}


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("mast.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()


func _shot(at: Vector3, target: Vector3, name: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(folder.path_join(name))


func _go(target: Vector3, ticks: int = 1200) -> void:
	for i in ticks:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.07: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -(0.5 if d > 0.5 else 0.25))
		await physics_frame
	body.drive = Vector2.ZERO


func _local(x: float, z: float) -> Vector3:
	return work.to_global(Vector3(x, 0, z))


## Off whatever is stood on, to a plate, and stood on it until it has fired.
func _press(key: String) -> void:
	await _go(_local(work.to_local(body.global_position).x, 3.7))
	await _go(_local(work.to_local(work.plate_point(key)).x, 3.7))
	await _go(work.plate_point(key))
	for i in 90: await physics_frame


## A pulse, and time enough for three swings to be measured.
func _pulse(seconds: float = 6.5) -> Dictionary:
	await _press("pulse")
	for i in int(seconds * 60.0): await physics_frame
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
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
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
		await _shot(Vector3(6.4, level + 4.4, 2.6), Vector3(-0.4, level + 1.2, -4.6), "overview.png")
		work.apply_grid_config({"built": "soft"})
		work.apply_grid_config({"built": "middle"})
		var s: Dictionary = work.state()
		checks.append({"check": "at rest: stiffness 9 and damping 0.8 asked, read back and built; six rings; nothing measured", "ok": Array(s.asked) == [9.0, 0.8, 0.0] and Array(s.read_back) == Array(s.asked) and is_equal_approx(float(s.built_k), 9.0)
			and int(s.rings) == 6 and float(s.period_s) < 0.0 and not bool(s.moving), "asked": s.asked, "build_ms": int(s.build_ms)})
		_save()
		game.place_player(_local(0.0, 3.7) + Vector3(0, 0.3, 0))
		for i in 30: await physics_frame
		var first: Dictionary = await _pulse()
		await _shot(_local(1.4, 5.4) + Vector3(0, 2.2, 0), _local(-0.8, -3.0) + Vector3(0, 1.7, 0), "pulse.png")
		checks.append({"check": "PULSE: a swing measured at 2.11 s, 0.43 of it left after one", "ok": absf(float(first.period_s) - 2.113) < 0.06 and absf(float(first.left) - 0.43) < 0.04 and float(first.trace_peak_m) > 0.3,
			"period_s": float(first.period_s), "left": float(first.left), "trace_peak_m": float(first.trace_peak_m)})
		_save()
		await _press("stiff")
		var asked: Dictionary = work.state()
		var same: Dictionary = await _pulse()
		await _shot(_local(1.4, 5.4) + Vector3(0, 2.2, 0), _local(-0.8, -3.0) + Vector3(0, 1.7, 0), "asked.png")
		checks.append({"check": "STIFFNESS asked to 16: asked and read back 16, built still 9, a swing still 2.11 s, and the stand says so", "ok": is_equal_approx(float(asked.asked[0]), 16.0) and is_equal_approx(float(asked.read_back[0]), 16.0)
			and is_equal_approx(float(asked.built_k), 9.0) and int(asked.rings) == 6 and absf(float(same.period_s) - 2.113) < 0.06 and str(asked.status).contains("NOTHING CHANGES UNTIL REBUILD"),
			"asked": asked.asked, "built_k": float(asked.built_k), "period_s": float(same.period_s), "status": str(asked.status)})
		_save()
		await _press("rebuild")
		var rebuilt: Dictionary = work.state()
		var stiff: Dictionary = await _pulse()
		checks.append({"check": "REBUILD: nine rings, and a swing takes 1.58 s", "ok": is_equal_approx(float(rebuilt.built_k), 16.0) and int(rebuilt.rings) == 9 and absf(float(stiff.period_s) - 1.579) < 0.05, "period_s": float(stiff.period_s), "left": float(stiff.left)})
		_save()
		await _press("damp")
		var damped: Dictionary = await _pulse()
		checks.append({"check": "DAMPING asked to 2.0: taken at once; 0.20 of a swing is left after one", "ok": is_equal_approx(float(damped.asked[1]), 2.0) and absf(float(damped.left) - 0.197) < 0.04 and absf(float(damped.period_s) - 1.622) < 0.06,
			"left": float(damped.left), "period_s": float(damped.period_s)})
		_save()
		await _press("drag")
		var dragged: Dictionary = work.state()
		var unused: Dictionary = await _pulse()
		checks.append({"check": "DRAG asked to 0.5: asked and read back, and the swing and what is left are as they were", "ok": is_equal_approx(float(dragged.asked[2]), 0.5) and is_equal_approx(float(dragged.read_back[2]), 0.5)
			and absf(float(unused.period_s) - float(damped.period_s)) < 0.03 and absf(float(unused.left) - float(damped.left)) < 0.03 and str(dragged.status).contains("NOTHING HERE USES IT"),
			"asked": dragged.asked, "period_s": float(unused.period_s), "left": float(unused.left)})
		_save()
		await _press("drag")
		await _press("drag")
		await _press("breathe")
		for i in 240: await physics_frame
		var breathing: Dictionary = work.state()
		await _press("breathe")
		var steady: Dictionary = work.state()
		checks.append({"check": "BREATHE then STEADY: steady, the mast is still moving, and the stand says steady is not still", "ok": bool(breathing.breathing) and bool(breathing.moving) and not bool(steady.breathing) and bool(steady.moving)
			and str(steady.status).begins_with("STEADY IS WHAT YOU GAVE IT"), "tip_m": [float(breathing.tip_m), float(steady.tip_m)], "status": str(steady.status)})
		_save()
		work.apply_grid_config({"built": "soft"})
		work.apply_grid_config({"built": "middle"})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[asked_read_measured_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
