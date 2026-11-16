extends SceneTree
## LAY THE MISSING PLANK on its floor (Godel_Incompleteness; the pass, gone back to on 2026-11-16)
## Four rising landings round the incompleteness tower; a plate lays the planks across each gap. Read in the
## running tower with its own walker:
##   at rest: no planks, one gap open, three bars across three gaps, one sentence shown; the rule's names;
##   the walker goes up the ramp to the first landing, half a metre up, on T; aimed at the next landing it is
##     held by the bar;
##   standing still on ADD IT: the planks are laid, G0 is an axiom, a second sentence shows; it walks up to the
##     second landing, a metre up, on T + G0, and one gap is still open;
##   twice more: the fourth landing, two metres up, three planks laid, one gap open; the stand says the tower
##     goes on and the floor does not; aimed east it is held by the tape;
##   it walks down the three ramps and the first one to the floor; the planks are still laid;
##   START AGAIN takes them up: three bars again;
##   the axis: `two` is found with two sets laid and one bar; `none` restores.
##
##   godot --path <stage> --script res://tools/probes/gap_moves_up_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## spiral.json: checks with what was read (written after every check). arrival.png, approach.png, gap.png,
## one.png, top.png, above.png, and four of the restaged floor: checking_row, plaque, machine, picture.
const ID := "gap-moves-up"
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
	var file := FileAccess.open(folder.path_join("spiral.json"), FileAccess.WRITE)
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


func _frame() -> Vector3:
	return work.in_frame(body.global_position)


func _wait(ticks: int) -> Dictionary:
	for i in ticks: await physics_frame
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
	if work != null and work.has_method("landing_point"):
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
		game.place_player(Vector3(-2.0, level + 0.3, 8.6))
		for i in 30: await physics_frame
		await _shot(Vector3(0, level + 1.65, 7.8), Vector3(0, level + 1.5, 0), "arrival.png")
		await _shot(_at(8.6, 2.4) + Vector3(0, 1.65, 0), _at(0.0, 0.0) + Vector3(0, 2.3, 0), "approach.png")
		await _shot(_at(2.05, 2.1) + Vector3(0, 2.1, 0), _at(1.65, 0.0) + Vector3(0, 1.75, 0), "gap.png")
		await _shot(Vector3(8.6, level + 1.65, -3.5), Vector3(9.9, level + 1.5, -7.8), "checking_row.png")
		await _shot(Vector3(10.6, level + 1.65, 6.6), Vector3(14.0, level + 1.5, 5.4), "plaque.png")
		await _shot(Vector3(3.9, level + 1.65, 2.9), Vector3(5.9, level + 1.7, 0.5), "machine.png")
		await _shot(Vector3(-10.4, level + 1.65, 7.6), Vector3(-10.4, level + 1.1, 4.6), "picture.png")
		work.apply_grid_config({"planks": "one"})
		work.apply_grid_config({"planks": "none"})
		var s: Dictionary = work.state()
		checks.append({"check": "at rest: no planks, one gap open, three bars across three gaps, one sentence shown; the rule's names", "ok": int(s.laid) == 0 and int(s.gaps_open) == 1 and Array(s.bars) == [true, true, true]
			and Array(s.ramps) == [false, false, false] and int(s.sentences_shown) == 1 and str(work.system(0)) == "T" and str(work.system(3)) == "T + G0 + G1 + G2" and int(work.gaps_open(3)) == 1,
			"system_3": str(work.system(3)), "build_ms": int(s.build_ms)})
		_save()
		game.place_player(_at(5.4, 1.65) + Vector3(0, 0.3, 0))
		for i in 40: await physics_frame
		var ground: float = body.global_position.y
		await _go(_at(2.08, 1.65))
		var first: Dictionary = await _wait(10)
		var up_first: float = body.global_position.y - ground
		await _go(_at(1.95, -1.65), 240)
		var held: Vector3 = _frame()
		checks.append({"check": "the walker goes up the ramp to the first landing, half a metre up, on T; aimed at the next landing it is held by the bar", "ok": int(first.on) == 0 and str(first.system) == "T" and absf(up_first - 0.5) < 0.12
			and held.z > 1.1 and int(work.state().laid) == 0 and str(first.status).contains("NO WAY TO IT FROM  T."), "up_m": snappedf(up_first, 0.01), "held_at_z_m": snappedf(held.z, 0.01), "status": str(first.status)})
		_save()
		await _go(work.landing_point(0))
		var laid: Dictionary = await _wait(90)
		await _shot(_at(8.6, 2.4) + Vector3(0, 1.65, 0), _at(0.0, 0.0) + Vector3(0, 2.3, 0), "one.png")
		await _go(work.landing_point(1))
		var second: Dictionary = work.state()
		var up_second: float = body.global_position.y - ground
		checks.append({"check": "standing still on ADD IT: the planks are laid, G0 is an axiom, a second sentence shows; it walks up to the second landing, a metre up, on T + G0, and one gap is still open",
			"ok": int(laid.laid) == 1 and Array(laid.bars) == [false, true, true] and Array(laid.ramps) == [true, false, false] and int(laid.axioms) == 1 and int(laid.sentences_shown) == 2
			and str(laid.status).contains("G0 IS AN AXIOM NOW") and int(second.on) == 1 and str(second.system) == "T + G0" and absf(up_second - 1.0) < 0.12 and int(second.gaps_open) == 1,
			"up_m": snappedf(up_second, 0.01), "system": str(second.system), "status_after_laying": str(laid.status)})
		_save()
		await _wait(90)
		await _go(work.landing_point(2))
		var third: Dictionary = await _wait(90)
		await _go(work.landing_point(3))
		var top: Dictionary = await _wait(20)
		var up_top: float = body.global_position.y - ground
		await _go(_at(0.0, 1.65), 240)
		var taped: Vector3 = _frame()
		checks.append({"check": "twice more: the fourth landing, two metres up, three planks laid, one gap open; the stand says the tower goes on and the floor does not; aimed east it is held by the tape",
			"ok": int(third.laid) == 3 and int(top.on) == 3 and str(top.system) == "T + G0 + G1 + G2" and absf(up_top - 2.0) < 0.12 and int(top.gaps_open) == 1 and int(top.sentences_shown) == 4 and int(top.axioms) == 3
			and str(top.status).contains("THE TOWER GOES ON. THE FLOOR DOES NOT.") and taped.x < -1.1 and absf(body.global_position.y - ground - 2.0) < 0.12,
			"up_m": snappedf(up_top, 0.01), "held_at_x_m": snappedf(taped.x, 0.01), "lines": top.lines, "status": str(top.status)})
		_save()
		for n in [3, 2, 1, 0]: await _go(work.landing_point(n))
		await _go(_at(5.2, 1.65))
		var down: Dictionary = await _wait(20)
		await _shot(_at(-1.75, 1.75) + Vector3(0, 3.6, 0), _at(1.65, 1.65) + Vector3(0, 2.7, 0), "top.png")
		await _shot(_at(5.2, 5.4) + Vector3(0, 4.9, 0), _at(0.0, 0.0) + Vector3(0, 1.2, 0), "above.png")
		checks.append({"check": "it walks down the three ramps and the first one to the floor; the planks are still laid", "ok": absf(body.global_position.y - ground) < 0.08 and int(down.on) == -1 and int(down.laid) == 3
			and str(down.status).contains("YOU CAME DOWN"), "above_the_floor_m": snappedf(body.global_position.y - ground, 0.01), "status": str(down.status)})
		_save()
		await _go(work.reset_point())
		var again: Dictionary = await _wait(90)
		checks.append({"check": "START AGAIN takes them up: three bars again", "ok": int(again.laid) == 0 and Array(again.bars) == [true, true, true] and str(again.planks) == "none"})
		_save()
		work.apply_grid_config({"planks": "two"})
		var a: Dictionary = work.state()
		work.apply_grid_config({"planks": "none"})
		var b: Dictionary = work.state()
		checks.append({"check": "the axis: `two` is found with two sets laid and one bar; `none` restores", "ok": int(a.laid) == 2 and Array(a.bars) == [false, false, true] and int(b.laid) == 0, "two": a.bars})
		_save()
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[gap_moves_up_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
