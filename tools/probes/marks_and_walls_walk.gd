extends SceneTree
## MARKS AND WALLS on its floor (SpeculativeComputation_Collective_Knowledge; the pass, 2026-11-16)
## A field of cells with walls that cannot be seen, and six sources' marks on the floor. Read in the running tower
## with its own walker, against the bench (tools/probes/marks_and_walls_bench.py):
##   at rest: 11 marks from 6 sources, 5 felt and 6 told; no edge tested; the marks are wrong about 5 of 31;
##   SIGN EVERYTHING: 18 marks from 7 sources, and still wrong about 5; signed off again: 11;
##   the walker walks in at the south and north into a marked wall: it is held, the mark is checked
##     and a felt mark of the visitor's lies beside it; still wrong about 5;
##   east, then north into a wall nobody marked: held; one mark added; wrong about 4;
##   round and through an edge two sources marked as a wall: both marks struck and kept; wrong about 3;
##   the last wrong mark walked through and the last two unmarked walls met: wrong about 0, with 15 marks where
##     there were 11;
##   the axis: `signed` is found with 18 marks, `checked` with 14 of which 3 are struck and nothing wrong;
##     `found` restores.
##
##   godot --path <stage> --script res://tools/probes/marks_and_walls_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## marks.json: checks with what was read (written after every check). arrival.png, overview.png, stopped.png,
## checked.png.
const ID := "marks-and-walls"
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
	var file := FileAccess.open(folder.path_join("marks.json"), FileAccess.WRITE)
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


## Through the cells given, one after another.
func _through(cells: Array) -> void:
	for cell in cells: await _go(work.cell_point(cell[0], cell[1]))


## Toward a cell a wall stands in front of: pressed against it for two and a half seconds.
func _into(c: int, r: int) -> Dictionary:
	await _go(work.cell_point(c, r), 150)
	for i in 20: await physics_frame
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
	if work != null and work.has_method("cell_point"):
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
		await _shot(Vector3(5.6, level + 4.8, 3.4), Vector3(-0.4, level + 0.4, -1.4), "overview.png")
		work.apply_grid_config({"record": "signed"})
		work.apply_grid_config({"record": "found"})
		var s: Dictionary = work.state()
		checks.append({"check": "at rest: 11 marks from 6 sources, 5 felt and 6 told; no edge tested; the marks are wrong about 5 of 31", "ok": int(s.marks) == 11 and int(s.sources) == 6 and int(s.felt) == 5 and int(s.told) == 6
			and int(s.tested) == 0 and int(s.wrong_about) == 5 and int(s.struck) == 0, "marks": int(s.marks), "wrong_about": int(s.wrong_about), "build_ms": int(s.build_ms)})
		_save()
		await _put(2.4, 4.3)
		await _go(work.plate_point())
		for i in 90: await physics_frame
		var signed: Dictionary = work.state()
		await _go(_at(2.4, 4.3))
		await _go(work.plate_point())
		for i in 90: await physics_frame
		var unsigned: Dictionary = work.state()
		checks.append({"check": "SIGN EVERYTHING: 18 marks from 7 sources, and still wrong about 5; signed off again: 11", "ok": int(signed.marks) == 18 and int(signed.sources) == 7 and int(signed.told) == 13 and int(signed.wrong_about) == 5
			and str(signed.status).contains("NOTHING WAS CHECKED") and int(unsigned.marks) == 11 and int(unsigned.sources) == 6, "signed": [int(signed.marks), int(signed.sources), int(signed.wrong_about)], "status": str(signed.status)})
		_save()
		# in at the south, north into a marked wall
		await _put(0.0, 3.3)
		await _go(work.cell_point(2, 3))
		var first: Dictionary = await _into(2, 2)
		var short: float = _apart(body.global_position, work.cell_point(2, 2))
		await _shot(_at(2.6, 4.4) + Vector3(0, 2.4, 0), _at(-0.2, 0.4) + Vector3(0, 0.7, 0), "stopped.png")
		checks.append({"check": "the walker walks in at the south and north into a marked wall: it is held, the mark is checked and a felt mark of the visitor's lies beside it; still wrong about 5",
			"ok": short > 0.6 and Array(first.visitor_marks) == ["H:2:2 felt"] and int(first.marks) == 12 and int(first.wrong_about) == 5 and str(first.last_event) == "confirmed" and int(first.tested) >= 1,
			"held_short_m": snappedf(short, 0.01), "visitor_marks": first.visitor_marks, "status": str(first.status)})
		_save()
		# east, then north into a wall nobody marked
		await _through([[2, 3], [3, 3]])
		var second: Dictionary = await _into(3, 2)
		checks.append({"check": "east, then north into a wall nobody marked: held; one mark added; wrong about 4", "ok": Array(second.visitor_marks).has("H:3:2 felt") and int(second.marks) == 13 and int(second.wrong_about) == 4
			and str(second.last_event) == "added", "visitor_marks": second.visitor_marks, "wrong_about": int(second.wrong_about), "status": str(second.status)})
		_save()
		# round, and through an edge two sources marked as a wall
		await _through([[3, 3], [2, 3], [1, 3], [1, 2], [2, 2]])
		for i in 20: await physics_frame
		var third: Dictionary = work.state()
		checks.append({"check": "round and through an edge two sources marked as a wall: both marks struck and kept; wrong about 3", "ok": int(third.struck) == 2 and int(third.marks) == 13 and int(third.wrong_about) == 3
			and Array(third.struck_marks).all(func(m): return str(m).contains("V:1:2") and str(m).contains("VISITOR walked through")) and str(third.last_event) == "struck:2", "struck": third.struck_marks, "status": str(third.status)})
		_save()
		# the last wrong mark, and the last two walls nobody marked
		await _through([[2, 1], [3, 1], [3, 2]])
		await _through([[3, 1], [3, 0]])
		await _into(4, 0)
		await _through([[3, 0], [3, 1], [4, 1]])
		var last: Dictionary = await _into(4, 2)
		await _shot(Vector3(5.6, level + 4.8, 3.4), Vector3(-0.4, level + 0.4, -1.4), "checked.png")
		checks.append({"check": "the last wrong mark walked through and the last two unmarked walls met: wrong about 0, with 15 marks where there were 11", "ok": int(last.wrong_about) == 0 and int(last.marks) == 15 and int(last.struck) == 3
			and int(last.sources) == 7 and int(last.felt) == 9 and str(last.status).begins_with("THE MARKS NOW AGREE WITH THE WALLS"), "marks": int(last.marks), "struck": int(last.struck), "felt": int(last.felt), "tested": int(last.tested),
			"visitor_marks": last.visitor_marks, "status": str(last.status)})
		_save()
		work.apply_grid_config({"record": "signed"})
		var a: Dictionary = work.state()
		work.apply_grid_config({"record": "checked"})
		var b: Dictionary = work.state()
		work.apply_grid_config({"record": "found"})
		var c: Dictionary = work.state()
		checks.append({"check": "the axis: `signed` is found with 18 marks, `checked` with 14 of which 3 are struck and nothing wrong; `found` restores", "ok": int(a.marks) == 18 and int(a.wrong_about) == 5 and int(b.marks) == 14
			and int(b.struck) == 3 and int(b.wrong_about) == 0 and int(b.felt) == 8 and int(c.marks) == 11 and int(c.wrong_about) == 5, "signed": int(a.marks), "checked": [int(b.marks), int(b.struck), int(b.wrong_about)]})
		_save()
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c2): return c2.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[marks_and_walls_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
