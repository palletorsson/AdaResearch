extends SceneTree
## THE WALKED TRIANGLE on its floor (NonEuclidean_Spaces; the pass, 2026-11-15)
## A dome the body walks as the third corner of a triangle; the same record read as a plane beside it. Read in the
## running tower with its own walker:
##   a dome 6.4 m across and 0.9 m high with two cones and a plank through it; at rest its triangle has more than
##   180 degrees and the mat has 180;
##   the walker climbs the dome and stands on its top: it is corner C;
##   walking away from the cones the sum on the dome grows while the mat keeps 180;
##   standing between the two cones the triangle is nearly flat and C's angle close to a straight one (a body never
##   stands exactly in line: the withheld reading of the bench needs an exactness a walk does not have);
##   read as a plane only, the dome is gone and the sum is 180.
##
##   godot --path <stage> --script res://tools/probes/walked_triangle_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## dome.json: checks with what was read. arrival.png, dome.png, top.png, far.png.
const ID := "walked-triangle"
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
	if work != null and work.has_method("dome_point"):
		for i in 200: await physics_frame
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
		var s: Dictionary = work.state()
		var kinds := {}
		for n in work.find_children("*", "Node3D", true, false):
			if n.has_meta("prefab") and n.has_meta("source_scene"): kinds[str(n.get_meta("prefab"))] = int(kinds.get(str(n.get_meta("prefab")), 0)) + 1
		checks.append({"check": "a dome 6.4 m across and 0.9 m high with two cones and a plank through it; at rest its triangle has more than 180 degrees and the mat has 180",
			"ok": absf(float(s.rim) - 3.18) < 0.02 and absf(float(s.top) - 0.91) < 0.02 and float(s.sphere_sum) > 180.5 and absf(float(s.plane_sum) - 180.0) < 0.01
				and int(kinds.get("traffic_pyramid_5", 0)) == 2 and int(kinds.get("timber_plank_4m", 0)) == 1 and int(kinds.get("trace_point_ball", 0)) == 3,
			"sphere_sum": float(s.sphere_sum), "plane_sum": float(s.plane_sum), "kinds": kinds, "build_ms": int(s.build_ms)})
		await _shot(cam, Vector3(0, level + 1.6, 7.8), at + Vector3(0, 0.5, 0), folder.path_join("arrival.png"))
		await _shot(cam, at + Vector3(5.2, 3.4, 5.6), at + Vector3(-0.2, 0.3, -1.6), folder.path_join("dome.png"))
		# up onto the dome
		game.place_player(work.dome_point(0, 4.2) + up)
		for i in 40: await physics_frame
		await _go(work.dome_point(0, 0))
		var top: Dictionary = work.state()
		var height: float = body.global_position.y - at.y
		await _shot(cam, at + Vector3(4.4, 2.6, 3.4), at + Vector3(0, 1.0, -0.4), folder.path_join("top.png"))
		checks.append({"check": "the walker climbs the dome and stands on its top: it is corner C", "ok": bool(top.on_dome) and height > 0.6 and bool(top.sphere_valid), "feet_above_the_floor_m": snappedf(height, .01), "sum": float(top.sphere_sum)})
		# away from the cones
		await _go(work.dome_point(0, 2.3))
		var far: Dictionary = work.state()
		await _shot(cam, at + Vector3(4.4, 2.6, 3.4), at + Vector3(0, 0.8, -0.2), folder.path_join("far.png"))
		checks.append({"check": "walking away from the cones the sum on the dome grows while the mat keeps 180", "ok": float(far.sphere_sum) > float(top.sphere_sum) + 1.0 and absf(float(far.plane_sum) - 180.0) < 0.01
			and absf(float(top.plane_sum) - 180.0) < 0.01, "on_top": float(top.sphere_sum), "away": float(far.sphere_sum), "the_mat": float(far.plane_sum)})
		# in line with A and B
		await _go(work.dome_point(0, 0))
		await _go(work.dome_point(0, -1.176))
		var line: Dictionary = work.state()
		checks.append({"check": "standing between the two cones the triangle is nearly flat: C's angle is close to a straight one (a body never stands exactly in line, so the reading is not withheld)",
			"ok": bool(line.on_dome) and bool(line.sphere_valid) and float(line.angles[2]) > 150.0, "pair": line.pair, "angle_at_C": snappedf(float(line.angles[2]), .1), "sum": float(line.sphere_sum)})
		# the plane only
		await _go(work.dome_point(0, 0))
		await _go(work.dome_point(0, 4.2))
		work.apply_grid_config({"reading": "plane"})
		for i in 30: await physics_frame
		var plane: Dictionary = work.state()
		checks.append({"check": "read as a plane only, the dome is gone and the sum is 180", "ok": str(plane.reading) == "plane" and work.get_node_or_null("Dome") == null and absf(float(plane.plane_sum) - 180.0) < 0.01, "plane_sum": float(plane.plane_sum)})
		work.apply_grid_config({"reading": "both"})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	var file := FileAccess.open(folder.path_join("dome.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[walked_triangle_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
