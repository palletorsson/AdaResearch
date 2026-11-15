extends SceneTree
## WHERE DO THEY MEET? on its floor (Euclid_Parallel; the pass, 2026-11-15)
## The fifth postulate laid out the length of the slab: a first line, a point P off it, the gold line through P with
## no shortfall, four lines that fall short, and a pink line from P through the body. Read in the running tower
## with its own walker:
##   each of the four lines has its cone where the rule says it meets the first line, on the slab;
##   standing on the first line, the stake is within two steps of the body, where the rule puts it;
##   a third of the way toward the gold line the meeting is where similar triangles put it, still on the floor;
##   halfway, the stake has left the building;
##   on the gold line there is nothing to walk to (withheld, or more than 200 m out);
##   beyond the gold line the line leans away and the meeting is behind P, to the west;
##   leaving the lane, the pink line returns to rest; with no shortfall at rest there is no stake.
##
##   godot --path <stage> --script res://tools/probes/meeting_point_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## lane.json: checks with what was read. arrival.png, above.png, lane.png, feet.png, gone.png, gold.png.
const ID := "meeting-point"
const EAST_OF_P := 22.0
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
		if d < 0.06: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 20: await physics_frame


## Where the rule puts the meeting for the body's own place: metres east of P.
func _expected(s: Dictionary) -> float:
	var p: Vector3 = work.to_local(body.global_position)
	var east: float = p.x - float(s.p[0])
	var toward: float = float(s.p[1]) - p.z
	return float(s.gap) * east / toward if absf(toward) > 0.0001 else INF


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
	if work != null and work.has_method("lane_point"):
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
		var placed := true
		var read := []
		for row in s.fixed:
			var want: float = float(s.gap) / tan(deg_to_rad(float(row.degrees)))
			var x: float = float(s.p[0]) + want
			placed = placed and absf(float(row.cone_x) - x) < 0.01 and absf(x) < 20.5 and absf(float(row.cone_z) - float(s.base_z)) < 0.4
			read.append("%d deg: %.2f m" % [int(row.degrees), want])
		checks.append({"check": "each of the four lines has its cone where the rule says it meets the first line, on the slab", "ok": placed and (s.fixed as Array).size() == 4 and int(kinds.get("traffic_pyramid_5", 0)) == 4,
			"met_after": read, "kinds": kinds, "at_rest": {"degrees": float(s.degrees), "meets_m": float(s.meets_m)}, "build_ms": int(s.build_ms)})
		await _shot(cam, Vector3(0, level + 1.6, 7.8), at + Vector3(0, 0.6, 0), folder.path_join("arrival.png"))
		await _shot(cam, at + Vector3(-6.0, 5.0, 8.5), at + Vector3(-9.0, 0, -0.6), folder.path_join("above.png"))
		await _shot(cam, work.lane_point(-1.6, -1.2) + Vector3(0, 1.7, 0), work.lane_point(9.0, 0.8) + Vector3(0, 0.2, 0), folder.path_join("lane.png"))
		# onto the first line
		game.place_player(work.lane_point(EAST_OF_P, -2.3) + up)
		for i in 40: await physics_frame
		await _go(work.lane_point(EAST_OF_P, float(s.gap)))
		var feet: Dictionary = work.state()
		var stake_x: float = work.to_global(Vector3(float(feet.stake_x), 0, 0)).x
		await _shot(cam, work.lane_point(EAST_OF_P - 3.4, -1.4) + Vector3(0, 1.8, 0), work.lane_point(EAST_OF_P, 1.2) + Vector3(0, 0.9, 0), folder.path_join("feet.png"))
		# a body stops a hand's width off the line it walked to, and so far from P a hand's width moves the meeting a step or two
		checks.append({"check": "standing on the first line, the stake is within two steps of the body, where the rule puts it", "ok": bool(feet.in_lane) and bool(feet.stake_shown) and absf(stake_x - body.global_position.x) < 2.0
			and absf(float(feet.meets_m) - _expected(feet)) < 0.02 * _expected(feet) and bool(feet.on_floor), "off_the_line_m": snappedf(absf(work.to_local(body.global_position).z - float(feet.base_z)), .01),
			"stake_from_the_body_m": snappedf(absf(stake_x - body.global_position.x), .01), "degrees_short": float(feet.degrees), "meets_m": float(feet.meets_m)})
		# a third of the way toward the gold line
		await _go(work.lane_point(EAST_OF_P, float(s.gap) * 2.0 / 3.0))
		var third: Dictionary = work.state()
		var want_third: float = _expected(third)
		checks.append({"check": "a third of the way toward the gold line the meeting is where similar triangles put it, still on the floor", "ok": absf(float(third.meets_m) - want_third) < 0.02 * want_third
			and float(third.meets_m) > float(feet.meets_m) * 1.3 and bool(third.on_floor), "meets_m": float(third.meets_m), "similar_triangles_m": snappedf(want_third, .01)})
		# halfway: the stake leaves the building
		await _go(work.lane_point(EAST_OF_P, float(s.gap) * 0.5))
		var half: Dictionary = work.state()
		await _shot(cam, body.global_position + Vector3(-2.2, 1.5, 1.6), work.lane_point(EAST_OF_P + 22.0, 1.5) + Vector3(0, 0.6, 0), folder.path_join("gone.png"))
		checks.append({"check": "halfway, the stake has left the building", "ok": bool(half.stake_shown) and not bool(half.on_floor) and absf(float(half.meets_m) - _expected(half)) < 0.02 * _expected(half)
			and str(half.board).contains("past the east edge"), "meets_m": float(half.meets_m), "degrees_short": float(half.degrees)})
		# on the gold line
		await _go(work.lane_point(EAST_OF_P, 0.0))
		var gold: Dictionary = work.state()
		await _shot(cam, body.global_position + Vector3(-2.6, 1.7, 1.8), work.lane_point(EAST_OF_P + 12.0, 0.6) + Vector3(0, 0.3, 0), folder.path_join("gold.png"))
		checks.append({"check": "on the gold line there is nothing to walk to: the reading is withheld, or the meeting is more than 200 m out", "ok": bool(gold.in_lane) and (bool(gold.withheld) or absf(float(gold.meets_m)) > 200.0),
			"withheld": bool(gold.withheld), "meets_m": float(gold.meets_m), "degrees_short": float(gold.degrees)})
		# beyond the gold line
		await _go(work.lane_point(EAST_OF_P, -0.7))
		var beyond: Dictionary = work.state()
		checks.append({"check": "beyond the gold line the line leans away and the meeting is behind P, to the west", "ok": bool(beyond.in_lane) and float(beyond.degrees) < 0.0 and float(beyond.meets_m) < 0.0
			and str(beyond.board).contains("west of P"), "meets_m": float(beyond.meets_m), "degrees": float(beyond.degrees)})
		# out of the lane
		await _go(work.lane_point(EAST_OF_P, -2.4))
		var out: Dictionary = work.state()
		work.apply_grid_config({"shortfall": "none"})
		for i in 10: await physics_frame
		var none: Dictionary = work.state()
		work.apply_grid_config({"shortfall": "narrow"})
		for i in 10: await physics_frame
		var back: Dictionary = work.state()
		checks.append({"check": "leaving the lane, the pink line returns to rest; with no shortfall at rest there is no stake", "ok": not bool(out.in_lane) and absf(float(out.degrees) - 2.5) < 0.001
			and bool(none.withheld) and not bool(none.stake_shown) and bool(back.stake_shown) and absf(float(back.meets_m) - float(s.meets_m)) < 0.01, "rest_meets_m": float(back.meets_m)})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	var file := FileAccess.open(folder.path_join("lane.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[meeting_point_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
