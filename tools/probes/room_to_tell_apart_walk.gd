extends SceneTree
## ROOM TO TELL APART on its floor (CriticalAlgorithms_Algorithmic_Bias_Visualization; the pass, 2026-11-16)
## Twenty-four posts, a rail that presses the warm twelve together, a stand that counts present, room round it and
## hidden from where you stand. Read in the running tower with its own walker, against the bench
## (tools/probes/room_to_tell_apart_bench.py):
##   at rest: open; twelve and twelve present, all twenty-four with room round them, nothing kept;
##   the rail walked to PRESSED: still twelve and twelve present; none of the warm twelve has room, all the grey
##     have; the walker aimed at the middle of the warm twelve is held off;
##   the rail left alone, the walker at two places: what is hidden changes, room and present do not;
##   the rail walked a quarter back from open: some of the warm twelve have room, not all;
##   open, standing still between 5 and 8: kept, a tape; pressed, they are still 0.91 m apart, two have room, and
##     the walker stands between them;
##   LET GO: none of the warm twelve has room; OTHER GROUPING: twelve others are warm, and the stand says someone
##     chose this one too;
##   the axis: `half` is found with one warm post with room; `open` restores.
##
##   godot --path <stage> --script res://tools/probes/room_to_tell_apart_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## posts.json: checks with what was read (written after every check). arrival.png, overview.png, pressed.png,
## kept.png, grouping.png.
const ID := "room-to-tell-apart"
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
	var file := FileAccess.open(folder.path_join("posts.json"), FileAccess.WRITE)
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


func _settle() -> Dictionary:
	for i in 400:
		await physics_frame
		if bool(work.state().settled) and i > 20: break
	for i in 20: await physics_frame
	return work.state()


## Along the rail from one value's end to another: on at the south side, off past the far end.
func _rail(from_x: float, to_x: float) -> Dictionary:
	await _put(from_x, 3.7)
	await _go(_at(from_x, 2.8))
	await _go(_at(to_x, 2.8))
	return await _settle()


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
	if work != null and work.has_method("pair_point"):
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
		await _shot(Vector3(6.6, level + 4.6, 1.6), Vector3(-0.6, level + 1.0, -4.4), "overview.png")
		work.apply_grid_config({"pressed": "half"})
		work.apply_grid_config({"pressed": "open"})
		var s: Dictionary = work.state()
		checks.append({"check": "at rest: open; twelve and twelve present, all twenty-four with room round them, nothing kept", "ok": is_zero_approx(float(s.pressed)) and Array(s.present) == [12, 12] and Array(s.room) == [12, 12]
			and Array(s.kept).is_empty() and str(s.grouping) == "A", "room": s.room, "nearest_warm_m": float(s.nearest_warm_m), "build_ms": int(s.build_ms)})
		_save()
		# pressed
		var pressed: Dictionary = await _rail(-2.75, 2.75)
		await _shot(_at(1.6, 6.0) + Vector3(0, 2.3, 0), _at(-0.6, -2.4) + Vector3(0, 1.5, 0), "pressed.png")
		await _put(-0.5, 3.8)
		await _go(_at(-0.5, 1.5))
		var middle: Vector3 = _at(float(pressed.warm_middle[0]), float(pressed.warm_middle[1]))
		await _go(middle, 300)
		var short: float = _apart(body.global_position, middle)
		checks.append({"check": "the rail walked to PRESSED: still twelve and twelve present; none of the warm twelve has room, all the grey have; the walker aimed at the middle of the warm twelve is held off",
			"ok": float(pressed.pressed) > 0.985 and Array(pressed.present) == [12, 12] and Array(pressed.room) == [0, 12] and absf(float(pressed.nearest_warm_m) - 0.17) < 0.02 and short > 0.4
			and str(pressed.status).begins_with("ALL TWELVE ARE STILL PRESENT"), "pressed": float(pressed.pressed), "room": pressed.room, "nearest_warm_m": float(pressed.nearest_warm_m), "held_off_m": snappedf(short, 0.01), "status": str(pressed.status)})
		_save()
		# the view, with the rail left alone
		await _go(_at(-0.5, 1.2))
		await _go(_at(-3.0, 1.2))
		for i in 40: await physics_frame
		var first: Dictionary = work.state()
		await _go(_at(-0.5, -2.8))
		for i in 40: await physics_frame
		var second: Dictionary = work.state()
		checks.append({"check": "the rail left alone, the walker at two places: what is hidden changes, room and present do not", "ok": Array(first.hidden) != Array(second.hidden) and absi(int(first.hidden[1]) - int(second.hidden[1])) >= 3
			and Array(first.room) == Array(second.room) and is_equal_approx(float(first.pressed), float(second.pressed)), "hidden_from_the_south_west": first.hidden, "hidden_from_the_north": second.hidden, "room": second.room})
		_save()
		# partway
		var part: Dictionary = await _rail(-2.75, -1.25)
		checks.append({"check": "the rail walked a quarter of the way from open: some of the warm twelve have room, not all", "ok": float(part.pressed) > 0.2 and float(part.pressed) < 0.3 and int(part.room[0]) > 0 and int(part.room[0]) < 12 and int(part.room[1]) == 12,
			"pressed": float(part.pressed), "room": part.room})
		_save()
		# keep a pair
		await _rail(-1.25, -2.75)
		await _put(-4.3, -0.35)
		await _go(work.pair_point(5, 8))
		for i in 90: await physics_frame
		var kept: Dictionary = work.state()
		var held: Dictionary = await _rail(-2.75, 2.75)
		await _put(-4.3, -0.35)
		await _go(work.pair_point(5, 8), 600)
		var between: float = _apart(body.global_position, work.pair_point(5, 8))
		await _shot(_at(-3.6, 4.6) + Vector3(0, 2.2, 0), _at(-1.4, -1.0) + Vector3(0, 1.0, 0), "kept.png")
		checks.append({"check": "open, standing still between 5 and 8: kept, a tape; pressed, they are still 0.91 m apart, two have room, and the walker stands between them", "ok": Array(kept.kept) == [5, 8] and bool(kept.tape)
			and absf(float(held.kept_apart_m) - 0.91) < 0.02 and Array(held.room) == [2, 12] and between < 0.1 and str(held.status).begins_with("YOU KEPT 5 AND 8"), "kept": kept.kept, "kept_apart_m": float(held.kept_apart_m),
			"room": held.room, "walker_from_their_middle_m": snappedf(between, 0.01), "status": str(held.status)})
		_save()
		# let go; another grouping
		await _put(-3.6, 3.75)
		await _go(work.plate_point("letgo"))
		for i in 90: await physics_frame
		var loose: Dictionary = await _settle()
		await _put(3.6, 3.75)
		await _go(work.plate_point("grouping"))
		for i in 90: await physics_frame
		var other: Dictionary = await _settle()
		await _shot(_at(1.6, 6.0) + Vector3(0, 2.3, 0), _at(-0.2, -2.4) + Vector3(0, 1.5, 0), "grouping.png")
		checks.append({"check": "LET GO: none of the warm twelve has room; OTHER GROUPING: twelve others are warm, and the stand says someone chose this one too", "ok": Array(loose.kept).is_empty() and Array(loose.room) == [0, 12]
			and str(other.grouping) == "B" and Array(other.warm) == [7, 8, 9, 10, 11, 12, 19, 20, 21, 22, 23, 24] and Array(other.room) == [0, 12] and Array(other.present) == [12, 12]
			and str(other.status).contains("SOMEONE CHOSE THIS ONE TOO"), "room_let_go": loose.room, "warm": other.warm, "room": other.room, "status": str(other.status)})
		_save()
		work.apply_grid_config({"pressed": "half"})
		var half: Dictionary = work.state()
		work.apply_grid_config({"pressed": "open"})
		var open: Dictionary = work.state()
		checks.append({"check": "the axis: `half` is found with one warm post with room; `open` restores", "ok": is_equal_approx(float(half.pressed), 0.5) and Array(half.room) == [1, 12] and str(half.grouping) == "A"
			and Array(open.room) == [12, 12] and is_zero_approx(float(open.pressed)), "half_room": half.room, "open_room": open.room})
		_save()
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[room_to_tell_apart_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
