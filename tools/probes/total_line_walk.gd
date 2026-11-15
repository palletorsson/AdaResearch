extends SceneTree
## ONE NUMBER IS A LINE ON THIS FLOOR on its floor (QFEP_Introduction; the pass, 2026-11-15)
## A painted floor where east is F and north is E, banded by the hall console's total. Read in the running tower
## with its own walker:
##   the floor's total is the console's own for the same four values; nothing kept, the stand shows no number;
##   the walker stands still at F 0.70, E 0.50: the floor keeps the place, 0.45, with a flag;
##   along the line to F 0.50, E 0.10: the same number, 2.7 m from the flag, and the pair is on the board;
##   across the line to F 0.20, E 0.50: another number;
##   lambda 0: from E 0.2 to E 0.9 at F 0.45 the total does not move;
##   phi 1: the kept number is found at F 0.15;
##   AGAIN: nothing kept.
##
##   godot --path <stage> --script res://tools/probes/total_line_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## total.json: checks with what was read (written after every check). arrival.png, overview.png, line.png,
## stand.png, lam0.png.
const ID := "total-line"
const CONSOLE := "f1_qfep_balance_workbench_6_4"
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
	var file := FileAccess.open(folder.path_join("total.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()


func _shot(at: Vector3, target: Vector3, name: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(folder.path_join(name))


## To a place without stopping on the way; `sample` collects the work's total at every tick.
func _go(target: Vector3, sample: Array = []) -> void:
	for i in 900:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.07: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -(0.45 if d > 0.5 else 0.25))
		if work.state().on_floor: sample.append(float(work.state().total))
		await physics_frame
	body.drive = Vector2.ZERO


func _stand(ticks: int = 90) -> void:
	for i in ticks: await physics_frame


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
		if game.building.content.exhibits.has("%d/%s" % [floor, ID]) and game.building.content.exhibits.has("%d/%s" % [floor, CONSOLE]): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, ID])
	work = mount.get_node_or_null("Artifact") if mount != null else null
	if work != null and work.has_method("grid_point"):
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
		# the console's own arithmetic
		var console_mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, CONSOLE])
		var console: Node = console_mount.get_node_or_null("Artifact") if console_mount != null else null
		var agree := []
		if console != null and console.has_method("_compute_qfe"):
			var was := [console.get("_F"), console.get("_E"), console.get("_lambda"), console.get("_phi")]
			for t in [[0.7, 0.5, 0.5, 0.0], [0.2, 0.9, 1.0, 1.0], [0.45, 0.3, 0.0, 0.5]]:
				console.set("_F", t[0]); console.set("_E", t[1]); console.set("_lambda", t[2]); console.set("_phi", t[3])
				agree.append([snappedf(float(console.call("_compute_qfe")), 0.0001), snappedf(float(work.total(t[0], t[1], t[2], t[3])), 0.0001)])
			console.set("_F", was[0]); console.set("_E", was[1]); console.set("_lambda", was[2]); console.set("_phi", was[3])
		work.apply_grid_config({"weight": "half"})
		var s: Dictionary = work.state()
		checks.append({"check": "the floor's total is the console's own for the same four values; nothing kept, the stand shows no number", "ok": agree.size() == 3 and agree.all(func(p): return absf(float(p[0]) - float(p[1])) < 0.0001)
			and Array(s.kept).is_empty() and not bool(s.flag) and str(s.number) == "–" and Array(s.marks) == ["-0.2", "0", "0.2", "0.4", "0.6"], "console_and_floor": agree, "marks": s.marks, "build_ms": int(s.build_ms)})
		_save()
		# keep a place
		game.place_player(work.grid_point(0.7, -0.2) + Vector3(0, 0.3, 0))
		for i in 40: await physics_frame
		await _go(work.grid_point(0.7, 0.5))
		await _stand()
		var kept: Dictionary = work.state()
		checks.append({"check": "the walker stands still at F 0.70, E 0.50: the floor keeps the place, 0.45, with a flag", "ok": Array(kept.kept).size() == 5 and absf(float(kept.kept[4]) - 0.45) < 0.02 and bool(kept.flag) and not bool(kept.same)
			and absf(float(kept.F) - 0.7) < 0.03 and absf(float(kept.E) - 0.5) < 0.03, "kept": kept.kept, "number": str(kept.number)})
		_save()
		# along the line
		var along := []
		await _go(work.grid_point(0.5, 0.1), along)
		for i in 20: await physics_frame
		var same: Dictionary = work.state()
		await _shot(work.grid_point(0.02, -0.42) + Vector3(0, 3.3, 0), work.grid_point(0.62, 0.62) + Vector3(0, 0.3, 0), "line.png")
		await _shot(work.grid_point(0.5, 0.42) + Vector3(0, 1.65, 0), work.grid_point(0.5, 1.12) + Vector3(0, 1.6, 0), "stand.png")
		checks.append({"check": "along the line to F 0.50, E 0.10: the same number, 2.7 m from the flag, and the pair is on the board", "ok": bool(same.same) and absf(float(same.apart_m) - 2.68) < 0.2 and int(same.found) == 1
			and absf(float(same.total) - float(same.kept[4])) < 0.02 and (along.max() - along.min()) < 0.05 and str(same.board).contains("Found:") and str(same.status).begins_with("THE SAME NUMBER"),
			"total": float(same.total), "apart_m": float(same.apart_m), "totals_on_the_way": [snappedf(along.min(), 0.001), snappedf(along.max(), 0.001)], "status": str(same.status), "number": str(same.number)})
		_save()
		# across it
		await _go(work.grid_point(0.2, 0.5))
		for i in 10: await physics_frame
		var other: Dictionary = work.state()
		checks.append({"check": "across the line to F 0.20, E 0.50: another number", "ok": not bool(other.same) and absf(float(other.total) + 0.05) < 0.03 and str(other.status) == "", "total": float(other.total), "number": str(other.number)})
		_save()
		# lambda 0
		await _go(work.plate_point("lam0"))
		await _stand()
		var zero: Dictionary = work.state()
		await _go(work.grid_point(0.45, 0.2))
		var north := []
		await _go(work.grid_point(0.45, 0.9), north)
		for i in 10: await physics_frame
		var top: Dictionary = work.state()
		await _shot(work.grid_point(0.02, -0.42) + Vector3(0, 3.3, 0), work.grid_point(0.62, 0.62) + Vector3(0, 0.3, 0), "lam0.png")
		checks.append({"check": "lambda 0: from E 0.2 to E 0.9 at F 0.45 the total does not move", "ok": is_zero_approx(float(zero.lam)) and north.size() > 20 and (north.max() - north.min()) < 0.03 and absf(float(top.total) - 0.45) < 0.02 and bool(top.same)
			and str(top.status) == "THE SAME NUMBER, ANOTHER ARRANGEMENT", "lam": float(zero.lam), "totals_on_the_way": [snappedf(north.min(), 0.001), snappedf(north.max(), 0.001)], "E": float(top.E), "status": str(top.status), "marks": zero.marks})
		_save()
		# phi 1
		await _go(work.plate_point("phi1"))
		await _stand()
		var raised: Dictionary = work.state()
		await _go(work.grid_point(0.15, 0.5))
		for i in 10: await physics_frame
		var moved: Dictionary = work.state()
		checks.append({"check": "phi 1: the kept number is found at F 0.15", "ok": is_equal_approx(float(raised.phi), 1.0) and bool(moved.same) and absf(float(moved.total) - 0.45) < 0.02 and absf(float(moved.F) - 0.15) < 0.03,
			"phi": float(raised.phi), "F": float(moved.F), "total": float(moved.total), "found": int(moved.found)})
		_save()
		# again
		await _go(work.plate_point("again"))
		await _stand()
		var cleared: Dictionary = work.state()
		checks.append({"check": "AGAIN: nothing kept", "ok": Array(cleared.kept).is_empty() and not bool(cleared.flag), "kept": cleared.kept})
		_save()
		await _go(work.plate_point("phi0"))
		await _stand()
		await _go(work.grid_point(0.5, -0.12))
		await _go(work.plate_point("lamh"))
		await _stand()
		var back: Dictionary = work.state()
		result["left_as"] = {"lam": float(back.lam), "phi": float(back.phi)}
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok) and is_equal_approx(float(back.lam), 0.5) and is_zero_approx(float(back.phi))
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[total_line_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
