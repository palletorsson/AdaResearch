extends SceneTree
## THE CANTOR STAIRCASE (floor Fractal_CantorSet; the pass, 2026-11-12)
## The Cantor function as a stair: lay a ramp, make its middle third level at half its height, steepen the two ends,
## and do the same to every ramp that is left. Read in the running tower, with its own walker:
##   THE FUNCTION   for every cut 0..5 the surface a ray meets is the Cantor function of that depth (the probe's own
##                  recursion on x, not the work's list of stretches), to a centimetre, at 240 places along the stair;
##   WHAT RISES     2^n ramps, (2/3)^n of the length, each (3/2)^n times as steep as the first ramp;
##   A LANDING NEVER MOVES   a body standing on the middle landing keeps its height through every cut;
##   THE BODY       the walker climbs the stair from the floor to the landing, over shaft B, after 0, 1, 2, 3 and 4
##                  cuts, and is stopped after the fifth, where the ramps stand at 48 degrees;
##   the kit landing takes it on and its ramp brings it down to the floor; a plate cuts again.
##
##   godot --path <stage> --script res://tools/probes/cantor_staircase_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## staircase.json: checks with what was read. arrival.png, elevation.png, from_the_landing.png, cut_<n>.png.
const ID := "cantor-staircase"
const LANDING := "cantor-landing"
var game: Node3D
var level := 0.0


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	cam.current = true
	for i in 4: await process_frame
	root.get_viewport().get_texture().get_image().save_png(path)
	cam.current = false


func _go(body: CharacterBody3D, target: Vector3, ticks_max: int = 700, speed: float = 0.6) -> float:
	var best := INF
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		best = minf(best, d)
		if d < 0.15: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 25: await physics_frame
	return best


## The Cantor function after `depth` cuts, on [0, 1]: the probe's own reading of the rule.
func _cantor(x: float, depth: int) -> float:
	if depth == 0: return x
	if x < 1.0 / 3.0: return 0.5 * _cantor(3.0 * x, depth - 1)
	if x > 2.0 / 3.0: return 0.5 + 0.5 * _cantor(3.0 * x - 2.0, depth - 1)
	return 0.5


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
		if game.building.content.exhibits.has(str(floor) + "/" + ID) and game.building.content.exhibits.has(str(floor) + "/" + LANDING): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get(str(floor) + "/" + ID)
	var stair: Node3D = mount.get_node_or_null("Artifact") if mount != null else null
	checks.append({"check": "the floor holds the Cantor staircase and its kit landing", "ok": stair != null and stair.has_method("stretches_now") and game.building.content.exhibits.has(str(floor) + "/" + LANDING)})
	if stair != null and stair.has_method("stretches_now"):
		for i in 300: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		for layer in root.find_children("*", "CanvasLayer", true, false):
			if layer.get_viewport() == root: layer.hide()
		var cam := Camera3D.new()
		cam.fov = 80
		root.add_child(cam)
		var foot: Vector3 = stair.foot_point()
		var top: Vector3 = stair.top_point()
		var run_m: float = float(stair.length)
		var rise_m: float = float(stair.rise)
		var space := root.get_world_3d().direct_space_state
		game.place_player(Vector3(-4.0, level + 0.3, 8.6))
		for i in 30: await physics_frame
		await _shot(cam, Vector3(0, level + 1.6, 7.8), Vector3(7.0, level + 1.0, 1.5), folder.path_join("arrival.png"))
		await _shot(cam, Vector3(7.5, level + 1.9, 8.6), Vector3(7.5, level + 0.9, 1.5), folder.path_join("elevation.png"))
		await _shot(cam, Vector3(2.2, level + 1.6, 7.4), Vector3(3.4, level + 1.2, 4.2), folder.path_join("board.png"))

		# 1 the function, and what rises, for every cut
		var function_ok := true
		var rises_ok := true
		var rows := []
		var misses := []
		for n in 6:
			stair.set_cut(n)
			for i in 6: await physics_frame
			var worst := 0.0
			for i in 240:
				var x: float = (float(i) + 0.37) / 240.0 * run_m
				var from: Vector3 = stair.to_global(Vector3(x, rise_m + 1.0, 0.0))
				var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * (rise_m + 2.0), 1)
				var hit: Dictionary = space.intersect_ray(query)
				var read: float = (hit.position.y - foot.y) if not hit.is_empty() else -9.0
				var gap: float = absf(read - rise_m * _cantor(x / run_m, n))
				if gap > 0.012 and misses.size() < 5: misses.append({"cuts": n, "x_m": snappedf(x, .001), "function_m": snappedf(rise_m * _cantor(x / run_m, n), .001), "read_m": snappedf(read, .001), "met": str((hit.collider as Node).get_path()) if not hit.is_empty() else ""})
				worst = maxf(worst, gap)
			var ramps := 0
			var rising := 0.0
			var steepest := 0.0
			var gentlest := INF
			for part in stair.stretches_now():
				if float(part[3]) > float(part[2]):
					ramps += 1
					rising += float(part[1]) - float(part[0])
					var grade: float = (float(part[3]) - float(part[2])) / (float(part[1]) - float(part[0]))
					steepest = maxf(steepest, grade); gentlest = minf(gentlest, grade)
			var want_grade: float = rise_m / run_m * pow(1.5, float(n))
			if worst > 0.012: function_ok = false
			if ramps != int(pow(2.0, float(n))) or absf(rising - run_m * pow(2.0 / 3.0, float(n))) > 0.001 or absf(steepest - want_grade) > 0.001 or absf(gentlest - want_grade) > 0.001: rises_ok = false
			rows.append({"cuts": n, "ramps": ramps, "rising_m": snappedf(rising, .001), "degrees": snappedf(rad_to_deg(atan(steepest)), .1), "worst_gap_to_the_function_cm": snappedf(worst * 100.0, .01)})
			await _shot(cam, Vector3(7.5, level + 1.9, 8.6), Vector3(7.5, level + 0.9, 1.5), folder.path_join("cut_%d.png" % n))
		checks.append({"check": "for every cut the surface a ray meets is the Cantor function of that depth, to a centimetre, at 240 places", "ok": function_ok, "cuts": rows, "misses": misses})
		checks.append({"check": "what rises is the Cantor set: 2^n ramps, (2/3)^n of the length, each (3/2)^n times as steep", "ok": rises_ok})

		# 2 a landing never moves
		var kept := true
		var heights := []
		stair.set_cut(1)
		game.place_player(stair.to_global(Vector3(run_m * 0.5, rise_m * 0.5 + 0.3, 0)))
		for i in 60: await physics_frame
		for n in [1, 2, 3, 4, 5]:
			stair.set_cut(n)
			for i in 40: await physics_frame
			heights.append(snappedf(body.global_position.y - foot.y, .001))
			if absf(body.global_position.y - foot.y - rise_m * 0.5) > 0.03: kept = false
		checks.append({"check": "a body on the middle landing keeps its height, half the rise, through every cut", "ok": kept, "feet_above_the_foot_m": heights})

		# 3 the body climbs it after 0..4 cuts and not after the fifth
		var climbs := []
		var climbed_ok := true
		var deck_feet := 0.0
		for n in 6:
			stair.set_cut(n)
			game.place_player(foot + Vector3(-0.9, 0.3, 0))
			for i in 40: await physics_frame
			var started := Time.get_ticks_msec()
			var near := await _go(body, top + Vector3(0.9, 0, 0), 4000 if n < 5 else 900, 0.7)
			var feet: float = body.global_position.y - foot.y
			var arrived: bool = near < 0.4 and absf(feet - rise_m) < 0.2
			if arrived: deck_feet = feet
			climbs.append({"cuts": n, "arrived": arrived, "feet_m": snappedf(feet, .01), "got_within_m": snappedf(near, .01), "seconds": snappedf(float(Time.get_ticks_msec() - started) / 1000.0, .1), "stood_at_m": snappedf(stair.to_local(body.global_position).x, .01)})
			if arrived != (n <= 4): climbed_ok = false
			if n == 3 and arrived: await _shot(cam, body.global_position + Vector3(-0.3, 1.6, 0.2), foot + Vector3(2.0, 0.2, 0), folder.path_join("from_the_landing.png"))
		checks.append({"check": "the walker climbs from the floor to the landing after 0, 1, 2, 3 and 4 cuts, and is stopped after the fifth", "ok": climbed_ok and int(game.checkpoint) == floor, "climbs": climbs, "feet_on_the_landing_m": snappedf(deck_feet, .01)})

		# 4 the landing's ramp brings a body down; back up it and down the stair
		stair.set_cut(3)
		game.place_player(top + Vector3(0.9, 0.3, 0))
		for i in 40: await physics_frame
		var down := await _go(body, top + Vector3(0.9, 0, 5.4), 900, 0.6)
		var floor_feet: float = body.global_position.y - foot.y
		checks.append({"check": "the kit landing's ramp brings the body down to the floor on the south side", "ok": down < 0.5 and absf(floor_feet) < 0.2, "feet_m": snappedf(floor_feet, .01), "got_within_m": snappedf(down, .01)})
		game.place_player(top + Vector3(0.9, 0.3, 0))
		for i in 40: await physics_frame
		var back := await _go(body, foot + Vector3(-0.9, 0, 0), 1500, 0.6)
		var back_feet: float = body.global_position.y - foot.y
		checks.append({"check": "from the landing the body walks the stair down to its foot", "ok": back < 0.5 and absf(back_feet) < 0.2, "feet_m": snappedf(back_feet, .01), "got_within_m": snappedf(back, .01)})

		# 5 a plate cuts again
		var plate: Vector3 = stair.plate_centre(0)
		game.place_player(plate + Vector3(0, 0.3, 1.2))
		for i in 80: await physics_frame
		var was: String = str(stair.cut)
		await _go(body, plate, 300, 0.34)
		checks.append({"check": "a body steps on CUT AGAIN and the stair is cut once more", "ok": was == "thrice" and str(stair.cut) == "four_times", "was": was, "now": str(stair.cut)})
		checks.append({"check": "a cut is rebuilt in under 3 ms", "ok": float(stair.rebuild_ms()) < 3.0, "rebuild_ms": snappedf(float(stair.rebuild_ms()), .01)})
		stair.set_cut(3)
		game.place_player(Vector3(-4.0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("staircase.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[cantor_staircase_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
