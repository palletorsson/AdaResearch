extends SceneTree
## DOES A BODY ENTER THE CHANNEL? (scent_trail_ground on floor Random_Pheromone; the Void, 2026-11-12)
## The floor's truth: "the environment itself becomes the communication channel". The ground keeps two records of
## every step, scent (fades, read by the blue walkers) and wear (stays). The Void's own walker crosses the ground on
## one line three times and steps off. Read: did its feet write scent where it walked; did the blue walkers that met
## the line turn onto it; is the wear still there after the body's scent has gone down; does the WIPE plate clear
## both records.
##
##   godot --path <stage> --script res://tools/probes/scent_ground_walk.gd -- --no-bridges --void-start-floor=89
##       --out=<dir>
##
## scent_walk.json: checks with what was read. arrival.png is taken before anything walks, from the spawn point;
## walked.png and high.png after the third crossing; kept.png 25 s after the body stepped off.
var game: Node3D
var work: Node3D


func _initialize() -> void:
	run.call_deferred()


func _near(a: Vector3, b: Vector3, within: float) -> float:
	var n := 0
	var ab := b - a
	for p: Vector3 in work.ant_places():
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0, 1)
		if p.distance_to(a + ab * t) <= within: n += 1
	return float(n) / int(work.ants)


func _go(body: CharacterBody3D, target: Vector3, trace: Array, ticks_max: int = 900) -> float:
	var best := INF
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		best = minf(best, d)
		if d < 0.3: break
		if i % 12 == 0: trace.append(work.to_local(body.global_position))
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -1)
		await physics_frame
	body.drive = Vector2.ZERO
	return best


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	cam.current = true
	for i in 4: await process_frame
	root.get_viewport().get_texture().get_image().save_png(path)
	cam.current = false


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
	var item = null
	for a in record.artifacts:
		if str(a.artifact) == "scent_trail_ground": item = a
	var checks := []
	var result := {"floor": floor, "map": str(record.map), "checks": checks, "passed": false}
	if item != null:
		var key := str(floor) + "/" + str(item.id)
		for i in 900:
			if game.building.content.exhibits.has(key): break
			await physics_frame
		var mount: Node3D = game.building.content.exhibits.get(key)
		for n in [mount] + mount.find_children("*", "Node3D", true, false):
			if n.has_method("ant_places"): work = n; break
		for i in 1200:
			if not work.warming(): break
			await physics_frame
		for i in 60: await physics_frame
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		result["ground_m"] = [float(work.width), float(work.depth)]
		result["walkers"] = int(work.ants)
		for layer in root.find_children("*", "CanvasLayer", true, false):      # the game's overlays, not a work's own layers
			if layer.get_viewport() == root: layer.hide()
		game.place_player(Vector3(-3.6, level + 0.3, 7.7))      # aside, off the ground, not in front of the lens
		for i in 30: await physics_frame
		var cam := Camera3D.new()
		root.add_child(cam)
		var middle: Vector3 = work.global_position
		await _shot(cam, Vector3(0, level + 1.6, 7.8), Vector3(middle.x, level + 0.3, middle.z), folder.path_join("arrival.png"))
		checks.append({"check": "the ground is found in use: the walkers have worn lines of their own", "ok": float(work.wear_share()) > 0.12,
			"wear_in_the_most_worn_twentieth": snappedf(work.wear_share(), .001)})
		checks.append({"check": "a body writes here", "ok": bool(work.body_writes)})
		# the line the body will walk, in the work's own metres
		var a := Vector3(-4.5, 0, 3.5)
		var b := Vector3(4.5, 0, -3.5)
		var base := 0.0
		for i in 20:
			base += _near(a, b, 0.45) / 20.0
			for k in 6: await physics_frame
		var scent_before: float = work.scent_at((a + b) / 2.0)
		# 1 across
		var trace := []
		var wa: Vector3 = work.to_global(a)
		var wb: Vector3 = work.to_global(b)
		game.place_player(Vector3(wa.x, level + 0.3, wa.z))
		for i in 30: await physics_frame
		var reach := await _go(body, wb, trace)
		var least := INF
		for p: Vector3 in trace:
			least = minf(least, float(work.scent_at(p)))
		checks.append({"check": "the body crossed the ground", "ok": reach < 0.4, "samples": trace.size()})
		checks.append({"check": "its feet wrote scent everywhere it walked", "ok": trace.size() > 8 and least > 0.9, "least_scent_on_its_path": snappedf(least, .01),
			"scent_there_before": snappedf(scent_before, .01)})
		# 2 back and across again: the walkers that meet the line
		var peak := 0.0
		var unused := []
		await _go(body, wa, unused)
		peak = maxf(peak, _near(a, b, 0.45))
		await _go(body, wb, unused)
		var gathered := 0.0
		for i in 10:
			gathered += _near(a, b, 0.45) / 10.0
			for k in 6: await physics_frame
		peak = maxf(peak, gathered)
		checks.append({"check": "the blue walkers that met the line turned onto it", "ok": gathered > 2.5 * base and gathered > 0.2,
			"share_on_the_line_before": snappedf(base, .01), "after_three_crossings": snappedf(gathered, .01)})
		await _shot(cam, Vector3(0, level + 1.6, 7.8), Vector3(middle.x, level + 0.3, middle.z), folder.path_join("walked.png"))
		await _shot(cam, Vector3(0, level + 5.2, 8.9), Vector3(middle.x, level, middle.z - 0.8), folder.path_join("high.png"))
		# 3 step off and wait: the two records part
		var left: float = work.scent_at((a + b) / 2.0)
		await _go(body, Vector3(6.6, level, wb.z - 0.4), unused, 300)
		for i in 1500: await physics_frame
		var scent_later: float = work.scent_at((a + b) / 2.0)
		var wear_later: float = work.wear_at((a + b) / 2.0)
		var kept := _near(a, b, 0.45)
		checks.append({"check": "25 s after the body left, its scent is down to what the walkers keep and the wear is still there",
			"ok": scent_later <= 1.05 and scent_later < left and wear_later > 0.25, "scent_when_it_left": snappedf(left, .01), "scent_25_s_later": snappedf(scent_later, .01),
			"wear_25_s_later": snappedf(wear_later, .01), "share_of_walkers_still_on_the_line": snappedf(kept, .01)})
		await _shot(cam, Vector3(0, level + 5.2, 8.9), Vector3(middle.x, level, middle.z - 0.8), folder.path_join("kept.png"))
		# 4 the plate
		var plate: Vector3 = work.to_global(Vector3(-float(work.width) / 2.0 + 3.6, 0, float(work.depth) / 2.0 + 0.55))
		game.place_player(Vector3(plate.x, level + 0.3, plate.z + 1.3))
		for i in 30: await physics_frame
		await _go(body, Vector3(plate.x, level, plate.z), unused, 200)
		for i in 20: await physics_frame
		var wear_wiped: float = work.wear_at((a + b) / 2.0)
		checks.append({"check": "stepping on WIPE clears both records", "ok": wear_wiped < 0.05 and float(work.scent_at((a + b) / 2.0)) < 0.25, "wear_after": snappedf(wear_wiped, .01)})
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "scent_trail_ground lies on this floor", "ok": false})
	var file := FileAccess.open(folder.path_join("scent_walk.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[scent_ground_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
