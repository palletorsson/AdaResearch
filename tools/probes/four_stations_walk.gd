extends SceneTree
## FOUR STATIONS, ONE WALK on its floor (SpeculativeComputation_Situated_Computation; the pass, 2026-11-16)
## A field with a line, four stations at its corners that each see part of it and each mean something else by
## DANGEROUS. Read in the running tower with its own walker, against the bench
## (tools/probes/four_stations_bench.py). The hall's creature is told not to bite for the length of the test.
##   at rest, the builder's example walk: NW says DANGEROUS and three say NOT; they saw 4.05, 0.45, 0.52 and
##     0.52 s of 6.43 s; 1.87 s nobody saw; 386 dots on the floor;
##   ONE DEFINITION: NW and NE say NOT, SW and SE say DANGEROUS: what is left comes from what each saw;
##   ONE RECORD as well: all four say DANGEROUS, and the tally says they agree;
##   ONE RECORD alone: NW, NE and SE say DANGEROUS, SW says NOT: what is left comes from what each means;
##   the walker's own walk straight up the line: all four say NOT DANGEROUS, each having seen about a second;
##   a second walk that swings two metres west: NW says DANGEROUS (off the line), SW says NOT, and the two
##     eastern stations saw too little of it to say anything;
##   a third walk at a run: NE says DANGEROUS (speed); and the axis: `both` is found with the example and four
##     DANGEROUS; `own` restores.
##
##   godot --path <stage> --script res://tools/probes/four_stations_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## stations.json: checks with what was read (written after every check). arrival.png, wing.png, field.png,
## walked.png.
const ID := "four-stations"
const D := "DANGEROUS"
const N := "NOT DANGEROUS"
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
	var file := FileAccess.open(folder.path_join("stations.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()


func _shot(at: Vector3, target: Vector3, name: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(folder.path_join(name))


func _go(target: Vector3, fast: float = 0.5, ticks: int = 1200) -> void:
	for i in ticks:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.07: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -(fast if d > 0.5 else 0.25))
		await physics_frame
	body.drive = Vector2.ZERO


func _at(x: float, z: float) -> Vector3:
	return work.local_point(x, z)


func _put(x: float, z: float) -> void:
	game.place_player(_at(x, z) + Vector3(0, 0.3, 0))
	for i in 30: await physics_frame


func _press(key: String) -> Dictionary:
	var x: float = work.to_local(work.plate_point(key)).x
	await _put(x, 4.95)
	await _go(work.plate_point(key))
	for i in 90: await physics_frame
	return work.state()


## A walk from START to END by way of the places given, at a pace.
func _walk(by: Array, fast: float) -> Dictionary:
	await _put(0.0, 3.45)
	await _go(_at(0.0, 2.6))
	for i in 20: await physics_frame
	for place in by: await _go(_at(place[0], place[1]), fast)
	await _go(_at(0.0, -2.6), fast)
	for i in 30: await physics_frame
	return work.state()


func _seen(s: Dictionary) -> Array:
	return Array(s.stations).map(func(st): return float(st.seen_s))


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
	if work != null and work.has_method("causes"):
		for i in 200: await physics_frame
		var crab_mount: Node3D = game.building.content.exhibits.get("%d/f2_head_crab_7_5" % floor)
		var crab: Node = crab_mount.get_node_or_null("Artifact") if crab_mount != null else null
		if crab != null and "can_bite" in crab: crab.set("can_bite", false)
		result["creature_told_not_to_bite"] = crab != null
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
		await _shot(Vector3(0, level + 1.65, 7.8), Vector3(17, level + 1.6, 0.3), "wing.png")
		work.apply_grid_config({"sharing": "both"})
		work.apply_grid_config({"sharing": "own"})
		await _shot(_at(0.0, 7.0) + Vector3(0, 2.7, 0), _at(0.0, -2.5) + Vector3(0, 1.6, 0), "field.png")
		var s: Dictionary = work.state()
		var seen: Array = _seen(s)
		checks.append({"check": "at rest, the builder's example walk: NW says DANGEROUS and three say NOT; they saw 4.05, 0.45, 0.52 and 0.52 s of 6.43 s; 1.87 s nobody saw; 386 dots on the floor",
			"ok": bool(s.example) and Array(s.verdicts) == [D, N, N, N] and absf(seen[0] - 4.05) < 0.03 and absf(seen[1] - 0.45) < 0.03 and absf(seen[2] - 0.52) < 0.03 and absf(seen[3] - 0.52) < 0.03
			and absf(float(s.unseen_s) - 1.87) < 0.03 and int(s.dots) == 386 and Array(s.causes) == [true, true, true], "verdicts": s.verdicts, "seen_s": seen, "unseen_s": float(s.unseen_s), "tally": str(s.tally[1]), "build_ms": int(s.build_ms)})
		_save()
		var one_def: Dictionary = await _press("definition")
		checks.append({"check": "ONE DEFINITION: NW and NE say NOT, SW and SE say DANGEROUS: what is left comes from what each saw", "ok": Array(one_def.verdicts) == [N, N, D, D] and str(one_def.tally[1]).contains("WHAT EACH SAW"),
			"verdicts": one_def.verdicts, "tally": str(one_def.tally[1])})
		_save()
		var both: Dictionary = await _press("record")
		checks.append({"check": "ONE RECORD as well: all four say DANGEROUS, and the tally says they agree", "ok": Array(both.verdicts) == [D, D, D, D] and str(both.tally[1]).contains("THEY AGREE"), "verdicts": both.verdicts, "tally": str(both.tally[1])})
		_save()
		var one_rec: Dictionary = await _press("definition")
		checks.append({"check": "ONE RECORD alone: NW, NE and SE say DANGEROUS, SW says NOT: what is left comes from what each means", "ok": Array(one_rec.verdicts) == [D, D, N, D] and str(one_rec.tally[1]).contains("WHAT EACH MEANS"),
			"verdicts": one_rec.verdicts, "tally": str(one_rec.tally[1])})
		_save()
		await _press("record")
		var straight: Dictionary = await _walk([], 0.5)
		var saw: Array = _seen(straight)
		checks.append({"check": "the walker's own walk straight up the line: all four say NOT DANGEROUS, each having seen about a second", "ok": not bool(straight.example) and not bool(straight.recording) and Array(straight.verdicts) == [N, N, N, N]
			and saw.all(func(t): return t > 0.4 and t < 2.0) and Array(straight.stations).all(func(st): return float(st.off) < 0.2) and float(straight.unseen_s) > 0.5, "seen_s": saw, "unseen_s": float(straight.unseen_s),
			"samples": int(straight.samples), "fastest": Array(straight.stations).map(func(st): return float(st.top))})
		_save()
		var swung: Dictionary = await _walk([[-2.2, 0.0]], 0.5)
		await _shot(_at(3.4, 6.4) + Vector3(0, 4.4, 0), _at(-0.4, -0.6) + Vector3(0, 0.6, 0), "walked.png")
		checks.append({"check": "a second walk that swings two metres west: NW says DANGEROUS (off the line), SW says NOT, and the two eastern stations saw too little of it to say anything", "ok": Array(swung.verdicts) == [D, "NOT SEEN", N, "NOT SEEN"] and float(swung.stations[0].off) > 1.5 and bool(swung.causes[0]),
			"verdicts": swung.verdicts, "off_m": float(swung.stations[0].off), "seen_s": _seen(swung), "tally": str(swung.tally[1])})
		_save()
		var ran: Dictionary = await _walk([], 1.0)
		work.apply_grid_config({"sharing": "both"})
		var found: Dictionary = work.state()
		work.apply_grid_config({"sharing": "own"})
		var back: Dictionary = work.state()
		checks.append({"check": "a third walk at a run: NE says DANGEROUS (speed); and the axis: `both` is found with the example and four DANGEROUS; `own` restores", "ok": str(ran.verdicts[1]) == D and float(ran.stations[1].top) > 2.2
			and bool(found.example) and Array(found.verdicts) == [D, D, D, D] and Array(back.verdicts) == [D, N, N, N] and bool(back.example), "ran": ran.verdicts, "fastest_ne": float(ran.stations[1].top), "both": found.verdicts})
		_save()
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[four_stations_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
