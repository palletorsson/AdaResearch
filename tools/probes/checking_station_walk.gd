extends SceneTree
## THE CHECKING STATION on its floor (Godel_Incompleteness; the pass, 2026-11-15)
## A robot brings candidates to a gate that checks them with the bench's own checker. Read in the running tower:
##   built from the tower's prefabs; asked for SSSSSSSS0, nothing has passed yet;
##   asked for SSS0 (a plate, stood on): the fourth candidate passes, three were refused before it;
##   asked for 0S: twelve candidates checked, none passed - and the station has not said that none will;
##   asked for SSSSSSSS0: eight refusals, then the ninth passes: slow, not impossible.
##
##   godot --path <stage> --script res://tools/probes/checking_station_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## station.json: checks with what was read. station.png, checking.png, passed.png, refusing.png.
const ID := "checking-station"
var game: Node3D
var body: CharacterBody3D
var work: Node3D
var eye: SubViewport


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 6: await process_frame
	eye.get_texture().get_image().save_png(path)


func _go(target: Vector3, ticks_max: int = 900, speed: float = 0.34) -> void:
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.1: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 14: await physics_frame


func _until(what: Callable, ticks_max: int) -> void:
	for i in ticks_max:
		if what.call(): break
		await physics_frame


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
	if work != null and work.has_method("plate_point"):
		for i in 120: await physics_frame
		var up := Vector3(0, 0.3, 0)
		body = game.body
		eye = SubViewport.new()
		eye.size = Vector2i(1280, 800)
		eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(eye)
		var cam := Camera3D.new()
		cam.fov = 80
		eye.add_child(cam)
		cam.current = true
		var at: Vector3 = work.global_position
		var view := at + Vector3(-3.4, 2.1, 2.9)
		var middle := at + Vector3(0.2, 0.75, 0.2)
		var s: Dictionary = work.state()
		var kinds := {}
		for n in work.find_children("*", "Node3D", true, false):
			if n.has_meta("prefab") and n.has_meta("source_scene"): kinds[str(n.get_meta("prefab"))] = int(kinds.get(str(n.get_meta("prefab")), 0)) + 1
		checks.append({"check": "built from the tower's prefabs; asked for SSSSSSSS0, nothing has passed yet", "ok": str(s.asks) == "SSSSSSSS0" and int(s.passed) == 0 and int(kinds.get("crate", 0)) >= 16
			and int(kinds.get("timber_panel_1x1", 0)) == 1 and int(kinds.get("construction_cube", 0)) == 1 and int(kinds.get("trace_point_ball", 0)) == 4, "kinds": kinds, "build_ms": int(s.build_ms)})
		await _shot(cam, view, middle, folder.path_join("station.png"))
		# a plate: ask for SSS0
		work.apply_grid_config({"pace": 5.0})
		game.place_player(work.plate_point("SSS0") + Vector3(0, 0.3, 1.2))
		for i in 30: await physics_frame
		await _go(work.plate_point("SSS0"))
		for i in 70: await physics_frame
		var asked: Dictionary = work.state()
		await _until(func(): return str(work.state().phase) == "check" and int(work.state().brought) >= 1, 900)
		for i in 12: await physics_frame
		await _shot(cam, view, middle, folder.path_join("checking.png"))
		await _until(func(): return int(work.state().passed) >= 1, 3000)
		var p: Dictionary = work.state()
		for i in 20: await physics_frame
		await _shot(cam, view, middle, folder.path_join("passed.png"))
		checks.append({"check": "asked for SSS0 on its plate: the fourth candidate passes, three were refused before it", "ok": str(asked.asks) == "SSS0" and int(p.first_pass) == 4 and int(p.checked) == 4 and int(p.short) + int(p.broken) == 3
			and int(p.broken) == 1, "first_pass": int(p.first_pass), "refused_short": int(p.short), "refused_broken": int(p.broken)})
		# 0S: nothing can pass, and the station does not say so
		work.apply_grid_config({"asks": "0S", "pace": 14.0})
		await _until(func(): return int(work.state().checked) >= 12, 6000)
		var z: Dictionary = work.state()
		await _shot(cam, view, middle, folder.path_join("refusing.png"))
		checks.append({"check": "asked for 0S: twelve candidates checked, none passed - and the station has not said that none will", "ok": int(z.checked) >= 12 and int(z.passed) == 0 and not bool(z.said_none_will_pass)
			and not bool(z.stopped), "checked": int(z.checked), "passed": int(z.passed)})
		# slow, not impossible
		work.apply_grid_config({"asks": "SSSSSSSS0"})
		await _until(func(): return int(work.state().passed) >= 1 or int(work.state().checked) >= 12, 6000)
		var slow: Dictionary = work.state()
		checks.append({"check": "asked for SSSSSSSS0: eight refusals, then the ninth passes: slow, not impossible", "ok": int(slow.first_pass) == 9 and int(slow.checked) == 9 and int(slow.passed) == 1,
			"first_pass": int(slow.first_pass), "checked": int(slow.checked)})
		work.apply_grid_config({"pace": 1.0})
		game.place_player(Vector3(0, body.global_position.y + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	var file := FileAccess.open(folder.path_join("station.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[checking_station_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
