extends SceneTree
## ONE LAP AND YOUR LEFT IS YOUR RIGHT on its floor (NonEuclidean_Spaces; the pass, 2026-11-15)
## A corridor joined to itself the other way up. Read in the running tower with its own walker:
##   at rest the shared stretch is plain: the word on its north wall, its east end open north, its west end south;
##   the walker goes in by the door: the word stands on its left;
##   one lap of left turns round the north block: the stretch is turned over - the word on the walker's right,
##   the east end open south - and the door is shut;
##   turned over, the way north from the east end is walled;
##   a second lap, of right turns round the south block: everything as it was, and the walker leaves by the door;
##   with `lap` second the door opens onto the turned-over sheet.
##
##   godot --path <stage> --script res://tools/probes/mirror_lap_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## lap.json: checks with what was read. outside.png, lap_0.png, lap_1.png, door_shut.png, lap_2.png.
const ID := "mirror-lap"
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


func _go(target: Vector3, ticks_max: int = 700, speed: float = 0.3) -> void:
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.1: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 12: await physics_frame


func _walk(names: Array) -> void:
	for name in names: await _go(work.place(str(name)))


## Which hand of a body heading east along the stretch the word is on.
func _hand(s: Dictionary) -> String:
	return "left" if float(s.word_z) < 0.0 else "right"


func run() -> void:
	var folder := ""
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
	var result := {"floor": floor, "map": str(record.map), "checks": checks, "passed": false}
	for i in 1500:
		if game.building.content.exhibits.has("%d/%s" % [floor, ID]): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, ID])
	work = mount.get_node_or_null("Artifact") if mount != null else null
	if work != null and work.has_method("place"):
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
		work.apply_grid_config({"lap": "first"})
		var s: Dictionary = work.state()
		checks.append({"check": "at rest the shared stretch is plain: the word on its north wall, its east end open north, its west end south", "ok": int(s.sheet) == 0 and not bool(s.turned_over) and float(s.word_z) < 0.0
			and str(s.east_opens) == "north" and str(s.west_opens) == "south" and not bool(s.door_shut), "word_z": float(s.word_z), "east_opens": str(s.east_opens), "west_opens": str(s.west_opens), "build_ms": int(s.build_ms)})
		await _shot(cam, work.place("out") + Vector3(-3.6, 1.7, 2.4), at + Vector3(0, 1.2, 0), folder.path_join("outside.png"))
		var view_from: Vector3 = work.place("w") + Vector3(0.1, 1.6, 0)
		var view_to: Vector3 = work.place("s") + Vector3(0.3, 1.35, 0)
		# in by the door
		game.place_player(work.place("out") + up)
		for i in 40: await physics_frame
		await _walk(["w", "s"])
		var entered: Dictionary = work.state()
		await _shot(cam, view_from, view_to, folder.path_join("lap_0.png"))
		checks.append({"check": "the walker goes in by the door: the word stands on its left", "ok": bool(entered.inside) and int(entered.laps) == 0 and _hand(entered) == "left", "hand": _hand(entered)})
		# one lap of left turns, round the north block
		await _walk(["e", "e_n", "ne", "n", "nw", "w_n", "w", "s"])
		var one: Dictionary = work.state()
		await _shot(cam, view_from, view_to, folder.path_join("lap_1.png"))
		checks.append({"check": "one lap of left turns round the north block: the stretch is turned over - the word on the walker's right, the east end open south - and the door is shut", "ok": int(one.laps) == 1 and bool(one.turned_over)
			and _hand(one) == "right" and str(one.east_opens) == "south" and str(one.west_opens) == "north" and bool(one.door_shut), "laps": int(one.laps), "hand": _hand(one), "east_opens": str(one.east_opens)})
		# the door holds, and the way north from the east end is walled
		await _go(work.place("out"), 260)
		var held: float = work.to_local(body.global_position).x
		await _shot(cam, work.place("s") + Vector3(0.4, 1.6, 0), work.place("w") + Vector3(-0.6, 1.1, 0), folder.path_join("door_shut.png"))
		await _walk(["s", "e"])
		await _go(work.place("e_n"), 200)
		var north: float = work.to_local(body.global_position).z
		checks.append({"check": "turned over, the door holds the walker in and the way north from the east end is walled", "ok": held > -float(one.x_out) + 0.1 and north > -0.75 and bool(work.state().inside),
			"at_the_door_x": snappedf(held, .01), "at_the_east_end_z": snappedf(north, .01)})
		# a second lap, of right turns, round the south block
		await _walk(["e", "e_s", "se", "s_far", "sw", "w_s", "w", "s"])
		var two: Dictionary = work.state()
		await _shot(cam, view_from, view_to, folder.path_join("lap_2.png"))
		await _walk(["w", "out"])
		var out: Dictionary = work.state()
		checks.append({"check": "a second lap, of right turns round the south block: everything as it was, and the walker leaves by the door", "ok": int(two.laps) == 2 and not bool(two.turned_over) and _hand(two) == "left"
			and str(two.east_opens) == "north" and not bool(two.door_shut) and not bool(out.inside) and str(out.board).contains("Last walk: 2 laps"), "laps": int(two.laps), "hand": _hand(two), "outside": not bool(out.inside)})
		work.apply_grid_config({"lap": "second"})
		for i in 10: await physics_frame
		var second: Dictionary = work.state()
		checks.append({"check": "with `lap` second the door opens onto the turned-over sheet", "ok": int(second.sheet) == 1 and bool(second.turned_over) and not bool(second.door_shut) and str(second.east_opens) == "south", "sheet": int(second.sheet)})
		work.apply_grid_config({"lap": "first"})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	var file := FileAccess.open(folder.path_join("lap.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[mirror_lap_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
