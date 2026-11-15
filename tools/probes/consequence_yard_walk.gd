extends SceneTree
## WHAT FOLLOWS? on its floor (Florensky_Paraconsistent; the pass, 2026-11-15)
## Seven doors with a sentence over each, two report plates, a rule plate. Read in the running tower with its own
## walker, against the sets worked out by hand:
##   no reports, four values: nothing opens, not even "P or not-P";
##   the walker stands on P: P, "P or not-P" and "P, or the alarm rang" open;
##   and on not-P too: five doors open, the alarm's and "it did not ring" stay shut, and the walker is held
##   out of the alarm's bay;
##   the walker stands on RULE: read classically the two reports open all seven; it walks in and rings the alarm;
##   classically with no reports only "P or not-P" is open.
##
##   godot --path <stage> --script res://tools/probes/consequence_yard_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## yard.json: checks with what was read (written after every check). yard.png, both.png, explosion.png.
var game: Node3D
var body: CharacterBody3D
var work: Node3D
var eye: SubViewport
var folder := ""
var result := {}


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("yard.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, name: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 40: await process_frame
	eye.get_texture().get_image().save_png(folder.path_join(name))


func _go(target: Vector3, ticks_max: int = 500, speed: float = 0.3) -> void:
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.07: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 10: await physics_frame


## Stand on a plate until the yard's state changes (or two seconds have gone), then step off it.
func _stand(key: String) -> void:
	var before: String = JSON.stringify([work.state().p, work.state().not_p, work.state().rule])
	await _go(work.plate_point(key))
	for i in 150:
		if JSON.stringify([work.state().p, work.state().not_p, work.state().rule]) != before: break
		await physics_frame
	await _go(work.plate_point(key) + Vector3(0, 0, 0.9))


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
		if game.building.content.exhibits.has("%d/consequence-yard" % floor): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get("%d/consequence-yard" % floor)
	work = mount.get_node_or_null("Artifact") if mount != null else null
	if work != null and work.has_method("plate_point"):
		for i in 200: await physics_frame
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
		body = game.body
		eye = SubViewport.new()
		eye.size = Vector2i(1280, 800)
		eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(eye)
		var cam := Camera3D.new()
		cam.fov = 80
		eye.add_child(cam)
		cam.current = true
		var view_from: Vector3 = work.door_point(3, 6.4) + Vector3(0.6, 2.6, 0)
		var view_to: Vector3 = work.door_point(3, 0) + Vector3(0, 1.1, 0)
		work.apply_grid_config({"rule": "four"})
		work.press("clear")
		var s: Dictionary = work.state()
		checks.append({"check": "no reports, four values: nothing opens, not even 'P or not-P'", "ok": Array(s.open).is_empty() and int(s.doors) == 7, "open": s.open, "build_ms": int(s.build_ms)})
		_save()
		await _shot(cam, view_from, view_to, "yard.png")
		game.place_player(work.plate_point("p") + Vector3(0, 0.3, 1.6))
		for i in 40: await physics_frame
		await _stand("p")
		var one: Dictionary = work.state()
		checks.append({"check": "the walker stands on P: P, 'P or not-P' and 'P, or the alarm rang' open", "ok": bool(one.p) and Array(one.open) == ["p", "either", "p_or_q"], "open": one.open})
		_save()
		await _stand("np")
		var both: Dictionary = work.state()
		await _go(work.door_point(5, 0.9))
		await _go(work.door_point(5, -0.7), 200)
		var held: float = work.to_local(body.global_position).z
		await _shot(cam, view_from, view_to, "both.png")
		checks.append({"check": "and on not-P too: five doors open, the alarm's and 'it did not ring' stay shut, and the walker is held out of the alarm's bay", "ok": bool(both.p) and bool(both.not_p)
			and Array(both.open) == ["p", "np", "both", "either", "p_or_q"] and held > 0.1 and int(work.state().rung) == 0, "open": both.open, "walker_before_the_door_m": snappedf(held, .01)})
		_save()
		await _go(work.door_point(5, 1.2))
		await _stand("rule")
		var boom: Dictionary = work.state()
		await _go(work.door_point(5, 0.9))
		await _go(work.door_point(5, -0.8), 300)
		for i in 20: await physics_frame
		var rung: Dictionary = work.state()
		await _shot(cam, view_from, view_to, "explosion.png")
		checks.append({"check": "the walker stands on RULE: read classically the two reports open all seven; it walks in and rings the alarm", "ok": str(boom.rule) == "classical" and Array(boom.open).size() == 7 and int(rung.rung) == 1
			and str(rung.board).contains("explosion"), "open": boom.open, "rung": int(rung.rung)})
		_save()
		await _go(work.door_point(5, 1.2))
		work.press("clear")
		var bare: Dictionary = work.state()
		checks.append({"check": "classically with no reports only 'P or not-P' is open", "ok": Array(bare.open) == ["either"], "open": bare.open})
		work.apply_grid_config({"rule": "four"})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[consequence_yard_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
