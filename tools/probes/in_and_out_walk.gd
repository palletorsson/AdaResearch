extends SceneTree
## IN AND OUT, WALKED on its floor (Russell_Paradox; the pass, gone back to on 2026-11-16)
## A railed corridor round an island, a gate IN and a gate OUT across it. Read in the running tower with its own
## walker:
##   at rest: the unrestricted rule, no answer, the way beside OUT closed;
##   the walker goes in and through IN: the answer is 'in', the rule says it is not, and sends it to OUT; through
##     OUT: the answer is 'out', the rule sends it to IN; two answers, none settled;
##   a second lap: four answers, none settled; aimed at the way beside OUT, it is held by the rail;
##   it walks out the way it came: the stand says a body has somewhere to go;
##   WITHIN U: the rule has a second line, the way beside OUT is open, the count starts again;
##   through IN: the rule says no, U is not one of its members; through OUT: it holds, one answer settled, and
##     the walker leaves by the way beside OUT;
##   the axis: `within_u` is found with the way open; `unrestricted` closes it.
##
##   godot --path <stage> --script res://tools/probes/in_and_out_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## loop.json: checks with what was read (written after every check). arrival.png, overview.png, lap.png,
## within.png.
const ID := "in-and-out"
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
	var file := FileAccess.open(folder.path_join("loop.json"), FileAccess.WRITE)
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


func _by(places: Array) -> Dictionary:
	for place in places: await _go(_at(place[0], place[1]))
	for i in 15: await physics_frame
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
	if work != null and work.has_method("plate_point"):
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
		await _shot(Vector3(0.0, level + 5.0, 1.0), Vector3(0.0, level + 0.4, -2.2), "overview.png")
		work.apply_grid_config({"rule": "within_u"})
		work.apply_grid_config({"rule": "unrestricted"})
		var s: Dictionary = work.state()
		checks.append({"check": "at rest: the unrestricted rule, no answer, the way beside OUT closed", "ok": str(s.rule) == "unrestricted" and int(s.answers) == 0 and not bool(s.way_out_open) and str(s.last) == "", "build_ms": int(s.build_ms)})
		_save()
		game.place_player(_at(0.0, 2.6) + Vector3(0, 0.3, 0))
		for i in 30: await physics_frame
		var went_in: Dictionary = await _by([[0.0, 0.9], [-1.5, 0.9], [-1.5, -0.9]])
		var went_out: Dictionary = await _by([[1.5, -0.9], [1.5, 0.9]])
		checks.append({"check": "the walker goes in and through IN: the answer is 'in', the rule says it is not, and sends it to OUT; through OUT: the answer is 'out', the rule sends it to IN; two answers, none settled",
			"ok": str(went_in.last) == "in" and str(went_in.sends) == "out" and str(went_in.lines[2]).contains("IT IS NOT IN R") and str(went_out.last) == "out" and str(went_out.sends) == "in"
			and int(went_out.answers) == 2 and int(went_out.settled) == 0, "after_in": str(went_in.lines[2]), "after_out": str(went_out.lines[2]), "answers": int(went_out.answers)})
		_save()
		var lap: Dictionary = await _by([[-1.5, 0.9], [-1.5, -0.9], [1.5, -0.9], [1.5, 0.9]])
		await _shot(_at(1.2, 4.6) + Vector3(0, 3.0, 0), _at(0.0, -1.2) + Vector3(0, 1.6, 0), "lap.png")
		var beyond: Vector3 = _at(3.2, 1.0)
		await _go(beyond, 240)
		var held: float = _apart(body.global_position, beyond)
		checks.append({"check": "a second lap: four answers, none settled; aimed at the way beside OUT, it is held by the rail", "ok": int(lap.answers) == 4 and int(lap.settled) == 0 and held > 0.9, "answers": int(lap.answers), "short_of_outside_m": snappedf(held, 0.01)})
		_save()
		var left: Dictionary = await _by([[1.5, 0.9], [0.0, 0.9], [0.0, 2.6]])
		checks.append({"check": "it walks out the way it came: the stand says a body has somewhere to go", "ok": bool(left.left) and str(left.status).contains("A BODY HAS SOMEWHERE TO GO"), "status": str(left.status)})
		_save()
		await _go(work.plate_point())
		for i in 90: await physics_frame
		var within: Dictionary = work.state()
		checks.append({"check": "WITHIN U: the rule has a second line, the way beside OUT is open, the count starts again", "ok": str(within.rule) == "within_u" and bool(within.way_out_open) and int(within.answers) == 0
			and str(within.lines[0]).contains("U  =  { 0, 1, 2, 3 }"), "rule": str(within.lines[0])})
		_save()
		var no: Dictionary = await _by([[0.0, 2.6], [0.0, 0.9], [-1.5, 0.9], [-1.5, -0.9]])
		var holds: Dictionary = await _by([[1.5, -0.9], [1.5, 0.9]])
		await _shot(_at(4.6, 4.2) + Vector3(0, 2.6, 0), _at(0.6, -0.6) + Vector3(0, 1.2, 0), "within.png")
		await _go(beyond, 400)
		var out: float = _apart(body.global_position, beyond)
		for i in 15: await physics_frame
		var gone: Dictionary = work.state()
		checks.append({"check": "through IN: the rule says no, U is not one of its members; through OUT: it holds, one answer settled, and the walker leaves by the way beside OUT", "ok": str(no.lines[2]).contains("U IS NOT ONE OF")
			and int(holds.settled) == 1 and str(holds.sends) == "" and str(holds.lines[2]).contains("IT HOLDS") and out < 0.15 and bool(gone.left) and str(gone.status).contains("AN ANSWER THAT HELD"),
			"after_in": str(no.lines[2]), "after_out": str(holds.lines[2]), "from_outside_place_m": snappedf(out, 0.01), "status": str(gone.status)})
		_save()
		work.apply_grid_config({"rule": "unrestricted"})
		var a: Dictionary = work.state()
		work.apply_grid_config({"rule": "within_u"})
		var b: Dictionary = work.state()
		work.apply_grid_config({"rule": "unrestricted"})
		checks.append({"check": "the axis: `within_u` is found with the way open; `unrestricted` closes it", "ok": not bool(a.way_out_open) and bool(b.way_out_open) and not bool(work.state().way_out_open), "open": [bool(a.way_out_open), bool(b.way_out_open)]})
		_save()
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[in_and_out_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
