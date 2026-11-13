extends SceneTree
## THE CARRIED POINT on its floor (GT_Layout; the pass, 2026-11-13)
## The hall's blue graph on the floor, and the black point is the body. Read in the running tower with its own
## walker, against the bench (tools/probes/carried_point_bench.py):
##   eight trace balls and the hall artifact's twelve connections, every point three cords, at rest inside the
##   bounds the traffic pyramids mark;
##   the body walks to the black point: it becomes the body (the ball is put away, a disc lies under the feet);
##   carried four metres across the floor: the cords are the same cords, the three follow, most points have moved;
##   a point without a cord keeps its distance, but nearness is only that;
##   the body walks out past the cones: the black point is let go and the drawing comes to rest without it;
##   star: the black point is the hub, and all seven follow.
##
##   godot --path <stage> --script res://tools/probes/carried_point_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## drawing.json: checks with what was read. arrival.png, free.png, carried.png, star.png.
const ID := "carried-point"
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


func _moved(before: Array, after: Array) -> int:
	var count := 0
	for v in range(1, before.size()):
		if Vector2(float(before[v][0]) - float(after[v][0]), float(before[v][1]) - float(after[v][1])).length() > 0.5: count += 1
	return count


func _inside(places: Array) -> bool:
	for p in places:
		if absf(float(p[0])) > 5.61 or absf(float(p[1])) > 5.01: return false
	return true


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
	if work != null and work.has_method("black_point"):
		for i in 300: await physics_frame
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
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
		var over := at + Vector3(0.4, 4.9, 9.2)
		var middle := at + Vector3(0.0, 0.0, -1.0)
		game.place_player(work.point_at(Vector3(-1.2, 0.3, 8.0)))
		for i in 60: await physics_frame
		var s: Dictionary = work.state()
		var kinds := {}
		for n in work.find_children("*", "Node3D", true, false):
			if n.has_meta("prefab") and n.has_meta("source_scene"): kinds[str(n.get_meta("prefab"))] = int(kinds.get(str(n.get_meta("prefab")), 0)) + 1
		checks.append({"check": "eight trace balls and the hall artifact's twelve connections, every point three cords, at rest inside the bounds the traffic pyramids mark",
			"ok": str(s.graph) == "cube" and (s.cords as Array).size() == 12 and Array(s.degree) == [3, 3, 3, 3, 3, 3, 3, 3] and float(s.speed) < 0.05 and _inside(s.places)
				and int(kinds.get("trace_point_ball", 0)) == 8 and int(kinds.get("traffic_pyramid_5", 0)) == 10 and not bool(s.carried),
			"cords": s.cords, "degree": s.degree, "speed": float(s.speed), "lengths": s.lengths, "kinds": kinds, "build_ms": int(s.build_ms)})
		await _shot(cam, Vector3(0, level + 1.6, 7.8), at + Vector3(0, 0.2, 0), folder.path_join("arrival.png"))
		await _shot(cam, over, middle, folder.path_join("free.png"))
		# the black point becomes the body
		await _go(work.point_at(Vector3(-1.2, 0, 4.4)))
		await _go(work.black_point())
		var t: Dictionary = work.state()
		checks.append({"check": "the body walks to the black point: it becomes the body", "ok": bool(t.carried) and not bool(t.black_ball_shown) and int(t.takes) == 1, "carried": bool(t.carried), "takes": int(t.takes)})
		# carried across the floor
		var here: Vector3 = work.to_local(body.global_position)
		await _go(work.point_at(Vector3(here.x + (-4.0 if here.x > 0.0 else 4.0), 0, here.z)))
		for i in 40: await physics_frame
		var c: Dictionary = work.state()
		await _shot(cam, over, middle, folder.path_join("carried.png"))
		checks.append({"check": "carried four metres across the floor: the cords are the same cords, the three follow, most points have moved", "ok": Array(c.cords) == Array(s.cords) and Array(c.yours) == Array(s.yours)
			and float(c.longest_own) < 4.6 and _moved(s.places, c.places) >= 5 and _inside(c.places), "moved": _moved(s.places, c.places), "the_three_trailed_at_most_m": float(c.longest_own), "yours": c.yours})
		checks.append({"check": "a point without a cord keeps its distance from the body, but nearness is only that", "ok": float(c.closest_stranger) > 0.6 and float(c.closest_stranger) < 90.0, "nearest_point_without_a_cord_m": float(c.closest_stranger)})
		# out past the cones
		await _go(work.point_at(Vector3(-1.2, 0, 4.2)))
		await _go(work.point_at(Vector3(-1.2, 0, 7.0)))
		var gone: Dictionary = work.state()
		for i in 900: await physics_frame
		var rest: Dictionary = work.state()
		checks.append({"check": "the body walks out past the cones: the black point is let go and the drawing comes to rest without it", "ok": not bool(gone.carried) and bool(gone.black_ball_shown) and int(gone.lets_go) == 1
			and float(rest.speed) < 0.05 and _inside(rest.places) and Array(rest.cords) == Array(s.cords), "lets_go": int(gone.lets_go), "speed_after_15_s": float(rest.speed)})
		# star: the black point is the hub
		work.apply_grid_config({"graph": "star"})
		for i in 30: await physics_frame
		var star: Dictionary = work.state()
		await _go(work.point_at(Vector3(-1.2, 0, 4.2)))
		await _go(work.black_point())
		var hub: Vector3 = work.to_local(body.global_position)
		await _go(work.point_at(Vector3(hub.x - 3.0, 0, hub.z)))
		for i in 40: await physics_frame
		var led: Dictionary = work.state()
		await _shot(cam, over, middle, folder.path_join("star.png"))
		checks.append({"check": "star: the black point is the hub, and all seven follow", "ok": (star.cords as Array).size() == 7 and int(star.degree[0]) == 7 and bool(led.carried) and float(led.longest_own) < 4.6
			and _moved(star.places, led.places) == 7, "degree": star.degree, "moved": _moved(star.places, led.places), "trailed_at_most_m": float(led.longest_own)})
		work.apply_grid_config({"graph": "cube"})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c2): return c2.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	var file := FileAccess.open(folder.path_join("drawing.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[carried_point_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
