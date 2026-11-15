extends SceneTree
## THE SAME RULE IN LARGER STEPS on its floor (QFEP_Edge_Of_Chaos; the pass, 2026-11-15)
## One rule, one start, one turn of model time, two step sizes on the floor. Read in the running tower with its own
## walker (the figures are the bench's, tools/probes/step_spiral_bench.py):
##   at rest: 24 steps end 3.54 m from the pole and 48 steps 2.41 m; the rule says 1.60 m; the ends 1.18 m apart;
##   the walker follows the 24 steps stone by stone and stands 3.5 m from the pole; following the 48, 2.4 m;
##   the finer pair: 2.41 m and 1.96 m, 0.44 m apart;
##   the coarser pair with the wall: both ends on the wall, 0.20 m apart, 18 of the coarse path's 25 places on it;
##   RUN FASTER: the ball three times as fast, every figure on the stand as before.
##
##   godot --path <stage> --script res://tools/probes/step_spiral_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## spiral.json: checks with what was read (written after every check). arrival.png, overview.png, spiral.png,
## wall.png.
const ID := "step-spiral"
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
	var file := FileAccess.open(folder.path_join("spiral.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()


func _shot(at: Vector3, target: Vector3, name: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(folder.path_join(name))


func _go(target: Vector3, near: float = 0.07, ticks: int = 1200) -> void:
	for i in ticks:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < near: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -(0.5 if d > 0.5 else 0.25))
		await physics_frame
	body.drive = Vector2.ZERO


func _stand(ticks: int = 90) -> void:
	for i in ticks: await physics_frame


func _press(key: String) -> void:
	await _go(work.to_global(Vector3(work.to_local(work.plate_point(key)).x, 0, 4.9)))
	await _go(work.plate_point(key))
	await _stand()


## Along one computation, stone by stone, from START; returns how far from the pole the walker ends.
func _follow(which: int, places: int) -> float:
	await _go(work.stone_point(which, 0))
	for i in range(1, places): await _go(work.stone_point(which, i), 0.12)
	await _go(work.stone_point(which, places - 1))
	for i in 10: await physics_frame
	var pole: Vector3 = work.pole_point()
	return Vector2(body.global_position.x - pole.x, body.global_position.z - pole.z).length()


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
	if work != null and work.has_method("stone_point"):
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
		await _shot(Vector3(6.2, level + 5.2, 4.6), Vector3(-0.6, level + 0.2, -4.4), "overview.png")
		work.apply_grid_config({"pair": "coarse"})
		var s: Dictionary = work.state()
		checks.append({"check": "at rest: 24 steps end 3.54 m from the pole and 48 steps 2.41 m; the rule says 1.60 m; the ends 1.18 m apart", "ok": Array(s.steps) == [24, 48] and absf(float(s.ends_m[0]) - 3.54) < 0.01 and absf(float(s.ends_m[1]) - 2.41) < 0.01
			and is_equal_approx(float(s.rule_m), 1.6) and absf(float(s.difference_m) - 1.18) < 0.01 and not bool(s.wall) and Array(s.places) == [25, 49], "ends_m": s.ends_m, "difference_m": float(s.difference_m), "build_ms": int(s.build_ms)})
		_save()
		# on foot
		game.place_player(work.stone_point(0, 0) + Vector3(0.9, 0.3, 0.6))
		for i in 30: await physics_frame
		var far: float = await _follow(0, 25)
		await _shot(work.pole_point() + Vector3(-1.6, 4.9, 5.2), work.pole_point() + Vector3(0.6, 0, -0.3), "spiral.png")
		var near: float = await _follow(1, 49)
		checks.append({"check": "the walker follows the 24 steps stone by stone and stands 3.5 m from the pole; following the 48, 2.4 m", "ok": absf(far - 3.54) < 0.15 and absf(near - 2.41) < 0.15 and not bool(game.recovering),
			"walker_from_the_pole_m": [snappedf(far, 0.01), snappedf(near, 0.01)]})
		_save()
		# the finer pair
		await _press("fine")
		var fine: Dictionary = work.state()
		checks.append({"check": "the finer pair: 2.41 m and 1.96 m, 0.44 m apart", "ok": Array(fine.steps) == [48, 96] and absf(float(fine.ends_m[0]) - 2.41) < 0.01 and absf(float(fine.ends_m[1]) - 1.96) < 0.01 and absf(float(fine.difference_m) - 0.44) < 0.01
			and str(fine.status).begins_with("SMALLER STEPS"), "ends_m": fine.ends_m, "difference_m": float(fine.difference_m)})
		_save()
		# the wall
		await _press("coarse")
		await _press("wall")
		var wall: Dictionary = work.state()
		await _shot(work.pole_point() + Vector3(-1.6, 4.9, 5.2), work.pole_point() + Vector3(0.6, 0, -0.3), "wall.png")
		checks.append({"check": "the coarser pair with the wall: both ends on the wall, 0.20 m apart, 18 of the coarse path's 25 places on it", "ok": bool(wall.wall) and is_equal_approx(float(wall.ends_m[0]), 2.0) and is_equal_approx(float(wall.ends_m[1]), 2.0)
			and absf(float(wall.difference_m) - 0.20) < 0.01 and int(wall.on_wall) == 18 and str(wall.status).contains("NEITHER IS WHERE THE RULE ENDS"), "ends_m": wall.ends_m, "difference_m": float(wall.difference_m), "on_wall": int(wall.on_wall)})
		_save()
		await _press("wall")
		# faster is not finer
		var before: Dictionary = work.state()
		await _press("fast")
		var fast: Dictionary = work.state()
		checks.append({"check": "RUN FASTER: the ball three times as fast, every figure on the stand as before", "ok": int(fast.speed) == 3 and Array(fast.ends_m) == Array(before.ends_m) and is_equal_approx(float(fast.difference_m), float(before.difference_m))
			and Array(fast.places) == Array(before.places) and Array(fast.lines).slice(0, 4) == Array(before.lines).slice(0, 4), "speed": int(fast.speed), "last_line": str(fast.lines[4])})
		_save()
		await _press("fast")
		var left: Dictionary = work.state()
		result["left_as"] = {"pair": str(left.pair), "wall": bool(left.wall), "fast": bool(left.fast)}
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok) and str(left.pair) == "coarse" and not bool(left.wall) and not bool(left.fast)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[step_spiral_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
