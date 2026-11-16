extends SceneTree
## THE SEAT YOU TAKE on its floor (CriticalAlgorithms_Applied_Ethics; the pass, 2026-11-16)
## A long table with a head and a ring of six at full size; tapes at eye height between seats that face each other.
## Read in the running tower with its own walker, against the bench (tools/probes/seat_you_take_bench.py):
##   at rest (a neck turns 60): 11 of 21 pairs at the long table face each other, 15 of 15 in the ring; the head
##     faces 6 and is faced by 2; 56 half tapes; no seat taken;
##   the walker takes the head: faces 6 of 6, 2 of 6 face it; walks the lane to side 2: faces 3, faced by 4; and
##     is held by the table when it aims across;
##   the walker enters the ring between two backs and takes ring 1: faces 5 of 5, 5 face it;
##   NECK to 90: 21 of 21; NECK to 30: 7 of 21 and 9 of 15; the head faces 4 and is faced by none; a ring seat
##     faces 3 of 5; the stand says the circle did not solve that;
##   ANGLE THE CHAIRS (at 30): 4 of 6 face the head; 2 of 21 pairs face each other; the ring is as it was;
##   ANGLE THE CHAIRS again, NECK to 60: as at rest;
##   the axis: `thirty` is found with 7 of 21 and 9 of 15; `sixty` restores.
##
##   godot --path <stage> --script res://tools/probes/seat_you_take_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## seats.json: checks with what was read (written after every check). arrival.png, overview.png, head.png,
## ring.png, angled.png.
const ID := "seat-you-take"
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
	var file := FileAccess.open(folder.path_join("seats.json"), FileAccess.WRITE)
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
	await _put(x, 3.5)
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
	if work != null and work.has_method("seat_point"):
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
		await _shot(Vector3(6.6, level + 4.6, 2.0), Vector3(-0.6, level + 0.9, -4.0), "overview.png")
		work.apply_grid_config({"neck": "thirty"})
		work.apply_grid_config({"neck": "sixty"})
		var s: Dictionary = work.state()
		checks.append({"check": "at rest (a neck turns 60): 11 of 21 pairs at the long table face each other, 15 of 15 in the ring; the head faces 6 and is faced by 2; 56 half tapes; no seat taken",
			"ok": int(s.neck) == 60 and not bool(s.angled) and Array(s.table_pairs) == [11, 21] and Array(s.ring_pairs) == [15, 15] and Array(s.head) == [6, 2, 6] and int(s.half_tapes) == 56 and str(s.seat) == "",
			"table_pairs": s.table_pairs, "ring_pairs": s.ring_pairs, "head": s.head, "half_tapes": int(s.half_tapes), "build_ms": int(s.build_ms)})
		_save()
		# the head, then a side seat along the lane
		await _put(-4.25, 1.8)
		await _go(work.seat_point("the head"))
		for i in 20: await physics_frame
		var head: Dictionary = work.state()
		await _shot(_at(-5.9, 0.9) + Vector3(0, 2.0, 0), _at(-1.6, 0.0) + Vector3(0, 0.9, 0), "head.png")
		await _go(_at(-4.02, -0.84))
		await _go(work.seat_point("side 2"))
		for i in 20: await physics_frame
		var side: Dictionary = work.state()
		await _go(work.seat_point("side 5"), 240)
		var across: float = _apart(body.global_position, work.seat_point("side 5"))
		checks.append({"check": "the walker takes the head: faces 6 of 6, 2 of 6 face it; walks the lane to side 2: faces 3, faced by 4; and is held by the table when it aims across",
			"ok": str(head.seat) == "the head" and Array(head.mine) == [6, 2, 6] and str(side.seat) == "side 2" and Array(side.mine) == [3, 4, 6] and across > 1.0,
			"head": head.mine, "side_2": side.mine, "side_seat": str(side.seat), "short_of_side_5_m": snappedf(across, 0.01), "line": str(head.lines[4])})
		_save()
		# the ring
		await _put(3.6, 1.75)
		await _go(_at(3.2, 1.04))
		await _go(work.seat_point("ring 1"))
		for i in 20: await physics_frame
		var ring: Dictionary = work.state()
		await _shot(_at(5.8, 2.8) + Vector3(0, 2.3, 0), _at(2.4, -0.2) + Vector3(0, 0.9, 0), "ring.png")
		checks.append({"check": "the walker enters the ring between two backs and takes ring 1: faces 5 of 5, 5 face it", "ok": str(ring.seat) == "ring 1" and Array(ring.mine) == [5, 5, 5], "ring_1": ring.mine, "line": str(ring.lines[4])})
		_save()
		# the neck
		var wide: Dictionary = await _press("neck")
		var short: Dictionary = await _press("neck")
		checks.append({"check": "NECK to 90: 21 of 21; NECK to 30: 7 of 21 and 9 of 15; the head faces 4 and is faced by none; a ring seat faces 3 of 5; the stand says the circle did not solve that",
			"ok": int(wide.neck) == 90 and Array(wide.table_pairs) == [21, 21] and int(wide.half_tapes) == 72 and int(short.neck) == 30 and Array(short.table_pairs) == [7, 21] and Array(short.ring_pairs) == [9, 15]
			and Array(short.head) == [4, 0, 6] and Array(short.ring_1) == [3, 3, 5] and int(short.half_tapes) == 36 and str(short.status).contains("THE CIRCLE DID NOT SOLVE THAT"),
			"at_90": wide.table_pairs, "at_30": [short.table_pairs, short.ring_pairs], "head": short.head, "ring_1": short.ring_1, "status": str(short.status)})
		_save()
		# the chairs angled
		var angled: Dictionary = await _press("angle")
		await _shot(_at(0.0, 5.6) + Vector3(0, 3.4, 0), _at(0.0, -1.2) + Vector3(0, 0.7, 0), "angled.png")
		checks.append({"check": "ANGLE THE CHAIRS (at 30): 4 of 6 face the head; 2 of 21 pairs face each other; the ring is as it was", "ok": bool(angled.angled) and Array(angled.head) == [4, 4, 6] and Array(angled.table_pairs) == [2, 21]
			and Array(angled.ring_pairs) == [9, 15] and int(angled.half_tapes) == 32 and str(angled.status).begins_with("THE CHAIRS ARE TURNED TO THE HEAD: 4 OF 6"), "head": angled.head, "table_pairs": angled.table_pairs, "status": str(angled.status)})
		_save()
		var straight: Dictionary = await _press("angle")
		var back: Dictionary = await _press("neck")
		checks.append({"check": "ANGLE THE CHAIRS again, NECK to 60: as at rest", "ok": not bool(straight.angled) and int(back.neck) == 60 and Array(back.table_pairs) == [11, 21] and Array(back.ring_pairs) == [15, 15] and int(back.half_tapes) == 56,
			"table_pairs": back.table_pairs, "ring_pairs": back.ring_pairs})
		_save()
		work.apply_grid_config({"neck": "thirty"})
		var thirty: Dictionary = work.state()
		work.apply_grid_config({"neck": "sixty"})
		var sixty: Dictionary = work.state()
		checks.append({"check": "the axis: `thirty` is found with 7 of 21 and 9 of 15; `sixty` restores", "ok": Array(thirty.table_pairs) == [7, 21] and Array(thirty.ring_pairs) == [9, 15] and Array(sixty.table_pairs) == [11, 21],
			"thirty": [thirty.table_pairs, thirty.ring_pairs], "sixty": [sixty.table_pairs, sixty.ring_pairs]})
		_save()
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[seat_you_take_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
