extends SceneTree
## THREE CORNERS AND YOU ARE HOME on its floor (NonEuclidean_Spaces; the pass, 2026-11-15)
## A block with a closed corridor round it whose inside has three quarter-sectors where the building has four.
## Read in the running tower with its own walker:
##   the block stands with one door: 1 on the door's side, 2 on the next, 3 on the side before, the fourth out of sight;
##   the walker goes in by the door and stands on side 1;
##   block on the left, three corners: the faces passed read 1, 2, 3, 1; the walker is turned once by a quarter and
##   stands where it stood after coming in, with the door beside it;
##   it leaves by the door it came in by, onto the slab south of the block;
##   the other way round, the first corner leads to 3;
##   with five corners, five corners lead home and the walker is turned back once by a quarter.
##
##   godot --path <stage> --script res://tools/probes/cornered_block_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir> [--row=<row id>]
##
## block.json: checks with what was read. outside.png, side_1.png, corner.png, home.png, five.png.
var id := "three-corners"
var game: Node3D
var body: CharacterBody3D
var work: Node3D
var eye: SubViewport


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(path)


## Walk toward a place; stops there, or as soon as the work has turned the body.
func _go(target: Vector3, ticks_max: int = 700, speed: float = 0.3) -> bool:
	var turns: int = int(work.state().quarter_turns)
	for i in ticks_max:
		if int(work.state().quarter_turns) != turns:
			body.drive = Vector2.ZERO
			return true
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.1: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 12: await physics_frame
	return false


## One side on, with the block on the left (or the right): to the corner, round it, to the middle of the next side
## as the building has it - or, when the body was turned on the way, of the side it now stands on.
func _next_side(forward: bool = true) -> void:
	var side: int = int(work.state().side)
	var on: int = posmod(side + (1 if forward else -1), 4)
	await _go(work.ring_point(side if forward else on, true))
	var turned: bool = await _go(work.ring_point(on))
	if turned: await _go(work.ring_point(int(work.state().side)))


func run() -> void:
	var folder := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
		if arg.begins_with("--row="): id = arg.trim_prefix("--row=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var floor: int = game.checkpoint
	var record: Dictionary = game.building.content.data.floors[floor]
	var checks := []
	var result := {"floor": floor, "map": str(record.map), "row": id, "checks": checks, "passed": false}
	for i in 1500:
		if game.building.content.exhibits.has("%d/%s" % [floor, id]): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, id])
	work = mount.get_node_or_null("Artifact") if mount != null else null
	if work != null and work.has_method("ring_point"):
		for i in 200: await physics_frame
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var up := Vector3(0, 0.3, 0)
		body = game.body
		eye = SubViewport.new()
		eye.size = Vector2i(1280, 800)
		eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(eye)
		var cam := Camera3D.new()
		cam.fov = 85
		eye.add_child(cam)
		cam.current = true
		var at: Vector3 = work.global_position
		work.apply_grid_config({"corners": "three"})
		var s: Dictionary = work.state()
		checks.append({"check": "the block stands with one door: 1 on the door's side, 2 on the next, 3 on the side before; the side behind the block is out of sight", "ok": int(s.n) == 3 and int(s.faces[0]) == 1 and int(s.faces[1]) == 2
			and int(s.faces[3]) == 3 and not bool(s.door_looks[0]) and not bool(s.door_looks[1]) and not bool(s.door_looks[3]), "faces_south_east_north_west": s.faces, "build_ms": int(s.build_ms)})
		await _shot(cam, work.door_point(5.0) + Vector3(2.2, 1.7, 0), at + Vector3(0, 1.2, 0), folder.path_join("outside.png"))
		# in by the door
		game.place_player(work.door_point(1.6) + up)
		for i in 40: await physics_frame
		await _go(work.ring_point(0))
		var entered: Dictionary = work.state()
		var stood: Vector3 = body.global_position
		await _shot(cam, work.ring_point(0) + Vector3(-1.0, 1.6, 0.25), work.ring_point(0) + Vector3(1.2, 1.4, -0.5), folder.path_join("side_1.png"))
		checks.append({"check": "the walker goes in by the door and stands on side 1", "ok": bool(entered.inside) and int(entered.label) == 1 and int(entered.count) == 0, "label": int(entered.label)})
		# three corners with the block on the left
		var read := [int(entered.label)]
		for k in 3:
			await _next_side(true)
			read.append(int(work.state().label))
			if k == 0: await _shot(cam, work.ring_point(0, true) + Vector3(0.3, 1.6, 0.3), work.ring_point(1) + Vector3(-0.3, 1.4, 0), folder.path_join("corner.png"))
		var home: Dictionary = work.state()
		var off: float = Vector2(body.global_position.x - stood.x, body.global_position.z - stood.z).length()
		await _shot(cam, work.ring_point(0) + Vector3(-1.0, 1.6, 0.25), work.ring_point(0) + Vector3(1.2, 1.4, -0.5), folder.path_join("home.png"))
		checks.append({"check": "block on the left, three corners: the faces passed read 1, 2, 3, 1; the walker was turned once by a quarter and stands where it stood after coming in", "ok": read == [1, 2, 3, 1]
			and int(home.quarter_turns) == 1 and int(home.side) == 0 and bool(home.home) and off < 0.4, "read": read, "quarter_turns": int(home.quarter_turns), "from_where_it_stood_m": snappedf(off, .01), "corners": int(home.count)})
		# out by the door it came in by
		await _go(work.door_point(1.4))
		var outside: Dictionary = work.state()
		var south: float = work.to_local(body.global_position).z
		checks.append({"check": "it leaves by the door it came in by, onto the slab south of the block", "ok": not bool(outside.inside) and south > float(outside.half) + 0.8 and str(outside.board).contains("Last walk: 3 corners"),
			"south_of_the_middle_m": snappedf(south, .01)})
		# the other way round
		await _go(work.ring_point(0))
		await _next_side(false)
		var back: Dictionary = work.state()
		checks.append({"check": "the other way round, the first corner leads to 3", "ok": int(back.label) == 3 and int(back.side) == 2 and int(back.count) == -1, "label": int(back.label), "side": int(back.side)})
		await _next_side(true)
		await _go(work.door_point(1.4))
		# five corners
		work.apply_grid_config({"corners": "five"})
		for i in 10: await physics_frame
		var before: int = int(work.state().quarter_turns)
		await _go(work.ring_point(0))
		var five := [int(work.state().label)]
		for k in 5:
			await _next_side(true)
			five.append(int(work.state().label))
			if k == 3: await _shot(cam, body.global_position + Vector3(0, 1.3, 0) - body.global_transform.basis.z * -0.9, body.global_position + Vector3(0, 1.3, 0) + body.global_transform.basis.z * -1.5, folder.path_join("five.png"))
		var fifth: Dictionary = work.state()
		checks.append({"check": "with five corners, five corners lead home and the walker is turned back once by a quarter", "ok": five == [1, 2, 3, 4, 5, 1] and int(fifth.quarter_turns) - before == -1 and int(fifth.side) == 0 and bool(fifth.home),
			"read": five, "quarter_turns": int(fifth.quarter_turns) - before})
		await _go(work.door_point(1.4))
		work.apply_grid_config({"corners": "three"})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	var file := FileAccess.open(folder.path_join("block.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[cornered_block_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
