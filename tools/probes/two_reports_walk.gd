extends SceneTree
## TWO REPORTS on its floor (SpeculativeComputation_Paraconsistent_Engineering; the pass, 2026-11-16)
## Two report slips, two reasoners with seven questions each, two real doors, a lamp nobody reported on. Read in
## the running tower with its own walker, against the bench (tools/probes/two_reports_bench.py):
##   at rest: nothing told, nothing follows, the lamp dark; the walker goes through the west door and is held by
##     the east one;
##   TELL A: the same two rows follow for both reasoners;
##   TELL B as well: the classical reasoner lights all seven and the lamp; the paraconsistent one four, the lamp
##     rows not among them;
##   A taken back: with B alone the classical reasoner still has the last row; the paraconsistent one does not,
##     and says that is the price;
##   both told, WHERE FROM?: the doors and the slips are named; four follow classically, three paraconsistently,
##     no contradiction row, the lamp dark;
##   WHERE FROM? again: the explosion returns; both taken back: nothing follows;
##   the axis: `both` is found with seven and four; `nothing` restores.
##
##   godot --path <stage> --script res://tools/probes/two_reports_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## reports.json: checks with what was read (written after every check). arrival.png, wing.png, approach.png,
## exploded.png, sourced.png.
const ID := "two-reports"
const Y := true
const N := false
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
	var file := FileAccess.open(folder.path_join("reports.json"), FileAccess.WRITE)
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


func _at(x: float, z: float) -> Vector3:
	return work.local_point(x, z)


func _put(x: float, z: float) -> void:
	game.place_player(_at(x, z) + Vector3(0, 0.3, 0))
	for i in 30: await physics_frame


func _press(key: String) -> Dictionary:
	var x: float = work.to_local(work.plate_point(key)).x
	await _put(x, 4.5)
	await _go(work.plate_point(key))
	for i in 90: await physics_frame
	return work.state()


func _apart(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


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
	if work != null and work.has_method("door_point"):
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
		game.place_player(Vector3(-13.5, level + 0.3, 7.6))        # out of its own arrival picture
		for i in 30: await physics_frame
		await _shot(Vector3(0, level + 1.65, 7.8), Vector3(0, level + 1.5, 0), "arrival.png")
		await _shot(Vector3(0, level + 1.65, 7.8), Vector3(17, level + 1.6, 0.4), "wing.png")
		await _shot(_at(-3.7, 6.4) + Vector3(0, 1.65, 0), _at(0.6, -2.0) + Vector3(0, 1.6, 0), "approach.png")
		work.apply_grid_config({"told": "one"})
		work.apply_grid_config({"told": "nothing"})
		var s: Dictionary = work.state()
		await _put(-2.7, 2.6)
		await _go(work.door_point(true, -1.0))
		var through: float = _apart(body.global_position, work.door_point(true, -1.0))
		await _put(2.7, 2.6)
		await _go(work.door_point(false, -1.0), 300)
		var held: float = _apart(body.global_position, work.door_point(false, -1.0))
		checks.append({"check": "at rest: nothing told, nothing follows, the lamp dark; the walker goes through the west door and is held by the east one", "ok": Array(s.told) == [N, N] and int(s.classical_count) == 0
			and int(s.paraconsistent_count) == 0 and not bool(s.lamp_lit) and through < 0.1 and held > 0.8, "through_west_m": snappedf(through, 0.01), "short_of_beyond_east_m": snappedf(held, 0.01), "build_ms": int(s.build_ms)})
		_save()
		var a: Dictionary = await _press("a")
		checks.append({"check": "TELL A: the same two rows follow for both reasoners", "ok": Array(a.told) == [Y, N] and Array(a.classical) == [Y, N, N, Y, N, N, N] and Array(a.paraconsistent) == Array(a.classical), "classical": a.classical, "paraconsistent": a.paraconsistent})
		_save()
		var both: Dictionary = await _press("b")
		await _shot(_at(0.0, 6.6) + Vector3(0, 2.5, 0), _at(0.0, -4.0) + Vector3(0, 1.9, 0), "exploded.png")
		checks.append({"check": "TELL B as well: the classical reasoner lights all seven and the lamp; the paraconsistent one four, the lamp rows not among them", "ok": Array(both.classical) == [Y, Y, Y, Y, Y, Y, Y] and bool(both.lamp_lit)
			and Array(both.paraconsistent) == [Y, Y, Y, Y, N, N, N] and str(both.feet[0]).begins_with("EXPLOSION") and str(both.feet[1]).contains("THE LAMP IS NOT AMONG THEM"),
			"classical": int(both.classical_count), "paraconsistent": both.paraconsistent, "feet": both.feet})
		_save()
		var only_b: Dictionary = await _press("a")
		checks.append({"check": "A taken back: with B alone the classical reasoner still has the last row; the paraconsistent one does not, and says that is the price", "ok": Array(only_b.told) == [N, Y]
			and Array(only_b.classical) == [N, Y, N, N, N, N, Y] and Array(only_b.paraconsistent) == [N, Y, N, N, N, N, N] and str(only_b.feet[1]).contains("THE PRICE"), "classical": only_b.classical, "paraconsistent": only_b.paraconsistent, "foot": str(only_b.feet[1])})
		_save()
		await _press("a")
		var sourced: Dictionary = await _press("from")
		await _shot(_at(0.0, 6.6) + Vector3(0, 2.5, 0), _at(0.0, -4.0) + Vector3(0, 1.9, 0), "sourced.png")
		checks.append({"check": "both told, WHERE FROM?: the doors and the slips are named; four follow classically, three paraconsistently, no contradiction row, the lamp dark", "ok": bool(sourced.sourced)
			and Array(sourced.classical) == [Y, Y, N, Y, N, N, Y] and Array(sourced.paraconsistent) == [Y, Y, N, Y, N, N, N] and not bool(sourced.lamp_lit) and Array(sourced.door_names) == ["THE WEST DOOR", "THE EAST DOOR"]
			and str(sourced.slips[0]).contains("WEST") and str(sourced.slips[1]).contains("EAST") and str(sourced.feet[0]).begins_with("TWO REPORTS ABOUT TWO DOORS"), "classical": sourced.classical, "paraconsistent": sourced.paraconsistent,
			"slips": sourced.slips, "foot": str(sourced.feet[0])})
		_save()
		var bare: Dictionary = await _press("from")
		await _press("b")
		var none: Dictionary = await _press("a")
		checks.append({"check": "WHERE FROM? again: the explosion returns; both taken back: nothing follows", "ok": int(bare.classical_count) == 7 and bool(bare.lamp_lit) and Array(none.told) == [N, N] and int(none.classical_count) == 0
			and int(none.paraconsistent_count) == 0, "bare": int(bare.classical_count), "none": [int(none.classical_count), int(none.paraconsistent_count)]})
		_save()
		work.apply_grid_config({"told": "both"})
		var found: Dictionary = work.state()
		work.apply_grid_config({"told": "nothing"})
		var back: Dictionary = work.state()
		checks.append({"check": "the axis: `both` is found with seven and four; `nothing` restores", "ok": int(found.classical_count) == 7 and int(found.paraconsistent_count) == 4 and int(back.classical_count) == 0,
			"both": [int(found.classical_count), int(found.paraconsistent_count)]})
		_save()
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[two_reports_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
