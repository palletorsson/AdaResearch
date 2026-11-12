extends SceneTree
## THE KOCH COAST WALK (floor Fractal_KochSierpinski; the pass, 2026-11-12)
## A Koch island to walk round. Every generation makes the coast a third longer; a body is a ruler 0.4 m wide and
## cannot enter what is narrower than itself. Read in the running tower, with its own walker's body:
##   THE COAST    after n generations the wall has 3 x 4^n pieces and is 3 x side x (4/3)^n long;
##   THE LAP      the walker's body is taken round the island by the left-hand rule (turn toward the coast as far
##                as the body's own collision test lets it, 3 cm at a time). Its lap is what the bench predicted
##                before the work was built (tools/probes/koch_coast_bench.py 4.5 0.2): it grows with the coast
##                for two generations, then gets SHORTER, and stops changing;
##   THE COUNT    the work's own count of that lap agrees with the probe's;
##   a finished lap makes the island grow one generation; a plate does the same by foot.
##
##   godot --path <stage> --script res://tools/probes/koch_coast_lap.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## coast.json: checks with what was read. arrival.png, island.png, generation_<n>.png, on_the_lap.png.
const ID := "koch-coast"
## generation -> [the coast's length, the lap of a disc of radius 0.2 m], metres, side 4.5
const BENCH := {0: [13.5, 14.77], 1: [18.0, 19.14], 2: [24.0, 24.56], 3: [32.0, 22.05], 4: [42.667, 21.36], 5: [56.889, 21.31]}
const STEP := 0.03
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


func _go(body: CharacterBody3D, target: Vector3, ticks_max: int = 700, speed: float = 0.34) -> float:
	var best := INF
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		best = minf(best, d)
		if d < 0.12: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 25: await physics_frame
	return best


## How far the body can go from `at` along `way` before it meets something.
func _free(body: CharacterBody3D, at: Vector3, way: Vector3) -> float:
	var met := KinematicCollision3D.new()
	var from := Transform3D(body.global_transform.basis, at + Vector3(0, 0.04, 0))
	if not body.test_move(from, way, met): return way.length()
	return met.get_travel().length()


## One lap by the left-hand rule, the island on the left. Returns {lap, steps, done}.
func _lap(body: CharacterBody3D, centre: Vector3, reach: float, shoot: Callable) -> Dictionary:
	var at := Vector3(centre.x, body.global_position.y, centre.z + reach + 0.7)
	game.place_player(at + Vector3(0, 0.05, 0))
	for i in 20: await physics_frame
	at = body.global_position
	# up to the coast
	for i in 200:
		var went := _free(body, at, Vector3(0, 0, -STEP))
		at += Vector3(0, 0, -went)
		if went < STEP * 0.9: break
	var heading := Vector3(1, 0, 0)
	var lap := 0.0
	var wound := 0.0
	var steps := 0
	var before := Vector2(at.x - centre.x, at.z - centre.z)
	while absf(wound) < TAU and steps < 4000:
		var moved := false
		for k in 36:
			var way: Vector3 = heading.rotated(Vector3.UP, deg_to_rad(72.0 - 6.0 * float(k)))
			if _free(body, at, way * STEP) >= STEP * 0.9:
				at += way * STEP
				heading = way
				moved = true
				break
		if not moved: break
		lap += STEP
		steps += 1
		var here := Vector2(at.x - centre.x, at.z - centre.z)
		wound += before.angle_to(here)
		before = here
		body.global_position = at
		body.velocity = Vector3.ZERO
		await physics_frame
		at.y = body.global_position.y
		if steps == 220 and shoot.is_valid(): await shoot.call()
	return {"lap": lap, "steps": steps, "done": absf(wound) >= TAU}


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
		if game.building.content.exhibits.has(str(floor) + "/" + ID): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get(str(floor) + "/" + ID)
	var work: Node3D = mount.get_node_or_null("Artifact") if mount != null else null
	checks.append({"check": "the floor holds the Koch coast walk", "ok": work != null and work.has_method("coast_points")})
	if work != null and work.has_method("coast_points"):
		for i in 300: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		for layer in root.find_children("*", "CanvasLayer", true, false):
			if layer.get_viewport() == root: layer.hide()
		var cam := Camera3D.new()
		cam.fov = 80
		root.add_child(cam)
		var centre: Vector3 = work.global_position
		var side_m: float = float(work.side)
		var reach: float = side_m / sqrt(3.0)
		work.apply_grid_config({"grows_on_lap": "false"})
		game.place_player(Vector3(3.0, level + 0.3, 8.6))
		for i in 30: await physics_frame
		await _shot(cam, Vector3(0, level + 1.6, 7.8), centre + Vector3(0, 0.8, 0), folder.path_join("arrival.png"))
		await _shot(cam, centre + Vector3(4.6, 2.1, 4.4), centre + Vector3(0, 0.6, 0), folder.path_join("island.png"))

		# 1 the coast, every generation
		var coast_ok := true
		var coasts := []
		for n in 6:
			work.set_generation(n)
			for i in 6: await physics_frame
			var points: PackedVector3Array = work.coast_points()
			var long := 0.0
			var furthest := 0.0
			for i in points.size():
				long += points[i].distance_to(points[(i + 1) % points.size()])
				furthest = maxf(furthest, Vector2(points[i].x - centre.x, points[i].z - centre.z).length())
			var want: float = 3.0 * side_m * pow(4.0 / 3.0, float(n))
			if points.size() != 3 * int(pow(4.0, float(n))) or absf(long - want) > 0.002 or furthest > reach + 0.001: coast_ok = false
			coasts.append({"generation": n, "pieces": points.size(), "coast_m": snappedf(long, .001), "rebuild_ms": snappedf(float(work.rebuild_ms()), .01)})
			await _shot(cam, centre + Vector3(0, 5.1, 2.2), centre + Vector3(0, 0.3, -0.2), folder.path_join("generation_%d.png" % n))
		checks.append({"check": "after n generations the wall has 3 x 4^n pieces, is 3 x side x (4/3)^n long, and lies inside the seed's circle", "ok": coast_ok, "coasts": coasts})

		# 2 the lap, every generation, with the walker's own body
		var laps := []
		var all_done := true
		var near_bench := true
		var counted := true
		for n in 6:
			work.set_generation(n)
			for i in 6: await physics_frame
			var shoot := Callable()
			if n == 3: shoot = func() -> void: await _shot(cam, body.global_position + Vector3(1.8, 2.3, 2.0), body.global_position + Vector3(-0.8, 0.2, -0.8), folder.path_join("on_the_lap.png"))
			var before_count: int = work.lap_count()
			var made: Dictionary = await _lap(body, centre, reach, shoot)
			# a visitor does not stop on the line: walk on until the work has counted the round
			var past := 0
			while work.lap_count() == before_count and past < 12:
				past += 1
				body.global_position += Vector3(0.03, 0, 0)
				await physics_frame
			var own: float = float(work.laps().get(n, 0.0))
			var bench: float = float(BENCH[n][1])
			laps.append({"generation": n, "coast_m": snappedf(float(BENCH[n][0]), .1), "lap_m": snappedf(float(made.lap), .01), "bench_m": bench, "the_works_count_m": snappedf(own, .01), "steps": int(made.steps), "the_work_sees": work.walking()})
			if not bool(made.done): all_done = false
			if absf(float(made.lap) - bench) > bench * 0.06: near_bench = false
			if work.lap_count() != before_count + 1 or absf(own - float(made.lap)) > float(made.lap) * 0.03: counted = false
		checks.append({"check": "the walker's body goes all the way round at every generation, and its lap is within 6 % of the bench", "ok": all_done and near_bench, "laps": laps})
		var grows: bool = float(laps[0].lap_m) < float(laps[1].lap_m) and float(laps[1].lap_m) < float(laps[2].lap_m)
		var shorter: bool = float(laps[3].lap_m) < float(laps[2].lap_m) * 0.95
		var settles: bool = absf(float(laps[5].lap_m) - float(laps[4].lap_m)) < float(laps[4].lap_m) * 0.03
		var little: bool = float(laps[5].lap_m) < float(laps[5].coast_m) * 0.45
		checks.append({"check": "the lap grows with the coast for two generations, is shorter at the third, stops changing, and at the fifth is under 45 % of the coast", "ok": grows and shorter and settles and little,
			"grows": grows, "shorter_at_the_third": shorter, "settles": settles, "under_45_percent": little})
		checks.append({"check": "the work's own count of each lap agrees with the probe's to 3 %", "ok": counted})

		# 3 a lap makes the island grow; a plate does it by foot
		work.set_generation(0)
		work.apply_grid_config({"grows_on_lap": "true"})
		for i in 6: await physics_frame
		await _lap(body, centre, reach, Callable())
		for i in 12:
			if str(work.generation) != "seed": break
			body.global_position += Vector3(0.03, 0, 0)
			await physics_frame
		checks.append({"check": "a finished lap round the seed puts the first generation on the island", "ok": str(work.generation) == "first", "generation": str(work.generation)})
		work.apply_grid_config({"grows_on_lap": "false"})
		var plate: Vector3 = work.plate_centre(0)
		game.place_player(plate + Vector3(0, 0.3, 1.0))
		for i in 80: await physics_frame
		await _go(body, plate, 300)
		checks.append({"check": "a body steps on NEXT GENERATION and the island is at the second", "ok": str(work.generation) == "second", "generation": str(work.generation)})
		work.apply_grid_config({"grows_on_lap": "true"})
		game.place_player(Vector3(3.0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("coast.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[koch_coast_lap] ", "PASSED" if result.passed else "FAILED")
	quit()
