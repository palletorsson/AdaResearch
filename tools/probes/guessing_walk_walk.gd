extends SceneTree
## WHOSE EXPECTATION MEETS IT? on its floor (QFEP_F_Term; the pass, 2026-11-15)
## Twelve hidden bits in two lanes; the walker's lane is its guess. Read in the running tower with its own walker:
##   at rest: p 0.9, H as the hall workbench computes it, the row's draws the workbench's own first draws, all
##   twelve rows under card;
##   a walk in the south lane (EXPECT 0): as many misses as the row has ones, an amber bar for each;
##   AGAIN and a walk in the north lane: the same twelve bits, the other misses;
##   p 0.1: H is what it was at 0.9, and the north lane now misses where it did not;
##   CHANGE THE WORLD INSTEAD: no misses, every refusing bit rewritten and stamped, the row no longer the source's;
##   the changed row walked in the south lane: it refuses that walker in every row;
##   p 0.9 again: the row as the source gives it, nothing changed, under card.
##
##   godot --path <stage> --script res://tools/probes/guessing_walk_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## guessing.json: checks with what was read (written after every check). arrival.png, overview.png, evidence.png,
## misses.png, changed.png.
const ID := "guessing-walk"
const BENCH := "f2_shannon_workbench_4_4"
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
	var file := FileAccess.open(folder.path_join("guessing.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()


func _shot(at: Vector3, target: Vector3, name: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(folder.path_join(name))


func _go(target: Vector3) -> void:
	for i in 1400:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.07: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -(0.5 if d > 0.5 else 0.25))
		await physics_frame
	body.drive = Vector2.ZERO


func _stand(ticks: int = 90) -> void:
	for i in ticks: await physics_frame


func _local(x: float, z: float) -> Vector3:
	return work.to_global(Vector3(x, 0, z))


## Round the south of the plates to the west end, then along the whole row in one lane.
func _walk_lane(lane: int) -> void:
	await _go(_local(body_local().x, 3.3))
	await _go(_local(-5.6, 3.3))
	await _go(work.tile_point(-1, lane))
	await _go(work.tile_point(12, lane))
	for i in 10: await physics_frame


func body_local() -> Vector3:
	return work.to_local(body.global_position)


func _press(key: String) -> void:
	await _go(work.plate_point(key))
	await _stand()


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
		if game.building.content.exhibits.has("%d/%s" % [floor, ID]) and game.building.content.exhibits.has("%d/%s" % [floor, BENCH]): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, ID])
	work = mount.get_node_or_null("Artifact") if mount != null else null
	if work != null and work.has_method("tile_point"):
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
		await _shot(Vector3(8.5, level + 4.6, 7.5), Vector3(0, level + 0.6, -1.5), "overview.png")
		# the workbench's own arithmetic and draws
		var bench_mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, BENCH])
		var bench: Node = bench_mount.get_node_or_null("Artifact") if bench_mount != null else null
		var bench_h := -1.0
		var bench_draws := []
		if bench != null and bench.has_method("_binary_entropy"):
			bench_h = float(bench.call("_binary_entropy", 0.9))
			bench_draws = Array(bench.get("_draws")).slice(0, 4)
		work.apply_grid_config({"source": "nine_tenths"})
		var s: Dictionary = work.state()
		var ones: int = Array(s.given).count(1)
		checks.append({"check": "at rest: p 0.9, H as the hall workbench computes it, the row's draws the workbench's own first draws, all twelve rows under card",
			"ok": is_equal_approx(float(s.p), 0.9) and absf(float(s.H) - bench_h) < 0.0002 and Array(s.first_draws) == bench_draws and bench_draws.size() == 4 and int(s.stepped) == 0 and Array(s.bits) == Array(s.given),
			"H": float(s.H), "workbench_H": snappedf(bench_h, 0.0001), "row": s.given, "ones_in_the_row": ones, "evidence_ones_of_48": int(s.evidence_ones), "build_ms": int(s.build_ms)})
		_save()
		game.place_player(work.plate_point("p5") + Vector3(0, 0.3, 1.2))
		for i in 30: await physics_frame
		await _shot(body.global_position + Vector3(0.6, 1.62, 0), work.to_global(Vector3(0, 1.5, -2.1)), "evidence.png")
		# the south lane
		await _walk_lane(0)
		var south: Dictionary = work.state()
		await _shot(_local(-6.4, 3.6) + Vector3(0, 3.2, 0), _local(0.6, -0.4), "misses.png")
		checks.append({"check": "a walk in the south lane (EXPECT 0): as many misses as the row has ones, an amber bar for each", "ok": int(south.stepped) == 12 and int(south.misses) == ones and int(south.bars) == ones and Array(south.walks) == [ones]
			and Array(south.guess).count(0) == 12, "misses": int(south.misses), "bars": int(south.bars), "expected_by_p": south.expects})
		_save()
		# again, the north lane
		await _press("again")
		await _walk_lane(1)
		var north: Dictionary = work.state()
		checks.append({"check": "AGAIN and a walk in the north lane: the same twelve bits, the other misses", "ok": Array(north.bits) == Array(south.bits) and int(north.misses) == 12 - ones and Array(north.walks) == [ones, 12 - ones]
			and (str(north.status).contains("DID NOT GET EASIER") if 12 - ones < ones else true), "misses": int(north.misses), "walks": north.walks, "status": str(north.status)})
		_save()
		# the other end of the rail
		await _press("p1")
		var low: Dictionary = work.state()
		var ones_low: int = Array(low.given).count(1)
		await _walk_lane(1)
		var refused: Dictionary = work.state()
		checks.append({"check": "p 0.1: H is what it was at 0.9, and the north lane now misses where it did not", "ok": absf(float(low.H) - float(s.H)) < 0.0002 and Array(low.given) != Array(s.given) and Array(low.walks).is_empty()
			and int(refused.misses) == 12 - ones_low and int(refused.misses) > int(north.misses), "H": float(low.H), "row": low.given, "misses": int(refused.misses)})
		_save()
		# what the hall warns of
		await _press("change")
		var fitted: Dictionary = work.state()
		await _shot(_local(-6.4, 3.6) + Vector3(0, 3.2, 0), _local(0.6, -0.4), "changed.png")
		checks.append({"check": "CHANGE THE WORLD INSTEAD: no misses, every refusing bit rewritten and stamped, the row no longer the source's", "ok": int(fitted.misses) == 0 and int(fitted.changed) == int(refused.misses) and int(fitted.stamps) == int(fitted.changed)
			and Array(fitted.bits) != Array(fitted.given) and Array(fitted.bits).count(1) == 12 and str(fitted.status).contains("CHANGED TO FIT") and str(fitted.status).contains("NO LONGER A SAMPLE"),
			"changed": int(fitted.changed), "row_now": fitted.bits, "row_given": fitted.given, "status": str(fitted.status)})
		_save()
		await _press("again")
		await _walk_lane(0)
		var other: Dictionary = work.state()
		checks.append({"check": "the changed row walked in the south lane: it refuses that walker in every row", "ok": int(other.misses) == 12 and int(other.changed) == int(fitted.changed), "misses": int(other.misses)})
		_save()
		await _press("p9")
		var back: Dictionary = work.state()
		checks.append({"check": "p 0.9 again: the row as the source gives it, nothing changed, under card", "ok": is_equal_approx(float(back.p), 0.9) and int(back.changed) == 0 and Array(back.bits) == Array(s.given) and int(back.stepped) == 0})
		_save()
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[guessing_walk_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
