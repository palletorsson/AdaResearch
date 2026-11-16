extends SceneTree
## EVERY FENCE HAS SOMETHING BEYOND IT on its floor (Russell_Paradox; the pass, gone back to on 2026-11-16)
## A plank-rail yard of four things, the one thing outside it, and fences that take that thing in. Read in the
## running tower with its own walker:
##   at rest: one fence; four inside, one outside: { 0, 1, 2, 3 }; the second fence is not there to hold a body;
##   the walker walks in through the gate and stands in the yard: inside fence 1 of 1;
##   FENCE IT IN: five inside, one outside: { 0, 1, 2, 3, 4 }; the thing that was outside is member 4; the second
##     fence holds a body that walks at its east side, and lets it through its gate;
##   twice more: six inside, then seven with the tape; always one outside; the stand says the floor ends before
##     the argument does;
##   from the yard out through the three gates: the walker stands outside every fence, and the stand says so
##     does { 0, ..., 6 };
##   once more: one fence again;
##   the axis: `three` is found with six inside and both wider fences standing; `one` restores.
##
##   godot --path <stage> --script res://tools/probes/fence_beyond_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## yard.json: checks with what was read (written after every check). approach.png, two.png, tape.png.
const ID := "fence-beyond"
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
	var file := FileAccess.open(folder.path_join("yard.json"), FileAccess.WRITE)
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


func _put(x: float, z: float) -> void:
	game.place_player(_at(x, z) + Vector3(0, 0.3, 0))
	for i in 30: await physics_frame


func _press() -> Dictionary:
	await _put(-1.9, 4.3)
	await _go(work.plate_point())
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
	if work != null and work.has_method("fence_round"):
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
		game.place_player(Vector3(13.5, level + 0.3, 7.6))
		for i in 30: await physics_frame
		await _shot(_at(-0.45, 4.9) + Vector3(0, 1.65, 0), _at(0.2, -2.0) + Vector3(0, 2.2, 0), "approach.png")
		work.apply_grid_config({"fences": "two"})
		work.apply_grid_config({"fences": "one"})
		var s: Dictionary = work.state()
		checks.append({"check": "at rest: one fence; four inside, one outside: { 0, 1, 2, 3 }; the second fence is not there to hold a body", "ok": int(s.stage) == 1 and int(s.inside) == 4 and int(s.outside) == 1
			and str(s.outside_thing) == "{ 0, 1, 2, 3 }" and not bool(s.fence_2_solid) and not bool(s.fence_3_solid), "outside": str(s.outside_thing), "build_ms": int(s.build_ms)})
		_save()
		await _put(-0.45, 3.2)
		await _go(_at(-0.45, 0.3))
		for i in 20: await physics_frame
		var yard: Dictionary = work.state()
		checks.append({"check": "the walker walks in through the gate and stands in the yard: inside fence 1 of 1", "ok": int(yard.visitor_within) == 1 and str(yard.lines[3]) == "you stand inside fence 1 of 1"
			and _apart(body.global_position, _at(-0.45, 0.3)) < 0.1, "line": str(yard.lines[3])})
		_save()
		var two: Dictionary = await _press()
		await _put(3.0, 0.0)
		await _go(_at(0.0, 0.0), 300)
		var held: float = work.to_local(body.global_position).x
		await _put(-0.45, 3.2)
		await _go(_at(-0.45, 1.15))
		var through: float = _apart(body.global_position, _at(-0.45, 1.15))
		await _shot(_at(-0.45, 4.6) + Vector3(0, 1.65, 0), _at(0.2, -2.0) + Vector3(0, 2.0, 0), "two.png")
		checks.append({"check": "FENCE IT IN: five inside, one outside: { 0, 1, 2, 3, 4 }; the thing that was outside is member 4; the second fence holds a body that walks at its east side, and lets it through its gate",
			"ok": int(two.stage) == 2 and int(two.inside) == 5 and str(two.outside_thing) == "{ 0, 1, 2, 3, 4 }" and Array(two.member_numbers) == ["4"] and bool(two.fence_2_solid) and held > 1.5 and through < 0.1,
			"outside": str(two.outside_thing), "members": two.member_numbers, "held_at_x_m": snappedf(held, 0.01), "status": str(two.status)})
		_save()
		var three: Dictionary = await _press()
		var tape: Dictionary = await _press()
		await _shot(_at(-1.2, 4.4) + Vector3(0, 4.4, 0), _at(0.0, -0.6) + Vector3(0, 1.0, 0), "tape.png")
		checks.append({"check": "twice more: six inside, then seven with the tape; always one outside; the stand says the floor ends before the argument does", "ok": int(three.inside) == 6 and bool(three.fence_3_solid) and int(tape.stage) == 4
			and int(tape.inside) == 7 and int(tape.outside) == 1 and bool(tape.tape_shown) and Array(tape.member_numbers) == ["4", "5", "6"] and str(tape.status).contains("THE FLOOR ENDS BEFORE THE ARGUMENT DOES"),
			"inside": [int(three.inside), int(tape.inside)], "outside": str(tape.outside_thing), "status": str(tape.status)})
		_save()
		await _put(-0.45, 3.2)
		await _go(_at(-0.45, 0.3))
		for i in 15: await physics_frame
		var deep: Dictionary = work.state()
		await _go(_at(-0.45, 3.1))
		for i in 15: await physics_frame
		var outside: Dictionary = work.state()
		checks.append({"check": "from the yard out through the three gates: the walker stands outside every fence, and the stand says so does { 0, ..., 6 }", "ok": int(deep.visitor_within) == 1 and int(outside.visitor_within) == 0
			and str(outside.lines[3]).begins_with("YOU STAND OUTSIDE EVERY FENCE HERE.") and str(outside.lines[3]).contains("{ 0, 1, 2, 3, 4, 5, 6 }"), "inside_line": str(deep.lines[3]), "outside_line": str(outside.lines[3])})
		_save()
		var again: Dictionary = await _press()
		checks.append({"check": "once more: one fence again", "ok": int(again.stage) == 1 and int(again.inside) == 4 and not bool(again.fence_2_solid)})
		_save()
		work.apply_grid_config({"fences": "three"})
		var a: Dictionary = work.state()
		work.apply_grid_config({"fences": "one"})
		var b: Dictionary = work.state()
		checks.append({"check": "the axis: `three` is found with six inside and both wider fences standing; `one` restores", "ok": int(a.inside) == 6 and bool(a.fence_2_solid) and bool(a.fence_3_solid) and int(b.inside) == 4 and not bool(b.fence_2_solid),
			"three": int(a.inside)})
		_save()
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[fence_beyond_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
