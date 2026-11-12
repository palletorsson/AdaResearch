extends SceneTree
## THE STONE CROSS OVER SHAFT A (stone_cross_crossing on floor Random_Game; Palle, 2026-11-12: "a 4 3-stone crossing,
## cross and in the middle health cross but a basin in the shaft that is electric grid")
## The Void's own walker is set on the live grid below (does it carry a body, does it take charge), waits on a
## stone that is down (does the stone carry it back up), then crosses west to east over the middle (does the health
## cross give charge back, how long does the crossing take, did the work's clock record it).
##
##   godot --path <stage> --script res://tools/probes/stone_cross_game.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## stone_cross.json: checks with what was read. above.png from over the south rim, below.png standing on the grid,
## arrival.png from the spawn point.
var game: Node3D
var work: Node3D
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


## Walk to a place and stop there. At full drive the walker coasts about 0.6 m, a stone's length; at a third of
## the drive it stops where it is told.
func _walk(body: CharacterBody3D, target: Vector3, ticks_max: int = 300) -> void:
	for i in ticks_max:
		if Vector2(target.x - body.global_position.x, target.z - body.global_position.z).length() < 0.08: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -0.34)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 6: await physics_frame


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
	var item = null
	for a in record.artifacts:
		if str(a.artifact) == "stone_cross_crossing": item = a
	checks.append({"check": "the stone cross lies on this floor", "ok": item != null})
	if item != null:
		var key := str(floor) + "/" + str(item.id)
		for i in 900:
			if game.building.content.exhibits.has(key): break
			await physics_frame
		var mount: Node3D = game.building.content.exhibits.get(key)
		for n in [mount] + mount.find_children("*", "Node3D", true, false):
			if n.has_method("returns_in"): work = n; break
		for i in 300: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		var battery: Node = get_first_node_in_group("void_health")
		var centre: Vector3 = work.global_position
		var reach: float = float(work.reach)
		var drop: float = float(work.drop)
		for layer in root.find_children("*", "CanvasLayer", true, false):      # the game's overlays, not a work's own layers
			if layer.get_viewport() == root: layer.hide()
		game.place_player(Vector3(3.6, level + 0.3, 8.6))      # aside, not in front of the lens
		for i in 30: await physics_frame
		var cam := Camera3D.new()
		root.add_child(cam)
		await _shot(cam, Vector3(0, level + 1.6, 7.8), Vector3(centre.x * 0.6, level + 0.5, 0), folder.path_join("arrival.png"))
		await _shot(cam, Vector3(centre.x, level + 5.0, centre.z + 6.4), Vector3(centre.x, level - 0.4, centre.z - 0.3), folder.path_join("above.png"))
		await _shot(cam, Vector3(centre.x + 2.3, level - drop + 1.5, centre.z + 2.3), Vector3(centre.x - 1.2, level - 0.2, centre.z - 1.2), folder.path_join("below.png"))
		# 1 a stone that is down carries a body back up
		var rode := false
		var ride := -1
		for i in 1200:
			for index in 12:
				var back: float = work.returns_in(index)
				if back > 0.4 and back < 2.5: ride = index; break
			if ride >= 0: break
			await physics_frame
		var highest := -9.0
		if ride >= 0:
			var at: Vector3 = work.to_global(work.stone_place(ride))
			game.place_player(Vector3(at.x, level - drop + 0.35, at.z))
			for i in 420:
				highest = maxf(highest, body.global_position.y - level)
				if body.global_position.y - level > -0.12: rode = true; break
				await physics_frame
		checks.append({"check": "a stone that is down carries a body back up", "ok": rode, "highest_feet_m": snappedf(highest, .01), "stone": ride})
		# 2 the grid below: it carries a body and it takes charge
		battery.set_charge(100.0)
		game.place_player(Vector3(centre.x + 2.0, level - drop + 0.5, centre.z + 2.0))
		for i in 40: await physics_frame
		var feet: float = body.global_position.y - level
		var charge_before: float = battery.get_charge()
		for i in 200: await physics_frame
		var charge_after: float = battery.get_charge()
		checks.append({"check": "the grid a metre below carries a body", "ok": absf(feet + drop) < 0.15 and int(game.checkpoint) == floor, "feet_m": snappedf(feet, .01)})
		checks.append({"check": "the grid is live: three seconds on it take charge", "ok": charge_after <= charge_before - 20.0, "charge_before": snappedf(charge_before, .1), "charge_after": snappedf(charge_after, .1)})
		# 3 across, west to east, over the middle. The rule: step onto the next stone only if it will stand 0.9 s more;
		# if the stone underfoot is about to go and the next will not hold, step back.
		var seq := [-2]                       # -2 a rim, -1 the middle, else a stone
		for index in work.arm("west"): seq.append(index)
		seq.append(-1)
		var east: Array = work.arm("east")
		east.reverse()
		for index in east: seq.append(index)
		seq.append(-2)
		var spot := func(k: int) -> Vector3:
			var code: int = seq[k]
			if code == -1: return centre
			if code == -2: return work.to_global(Vector3((-reach - 0.6) if k == 0 else (reach + 0.6), 0, 0))
			return work.to_global(work.stone_place(code))
		var safe := func(k: int, margin: float) -> bool:
			return int(seq[k]) < 0 or work.holds(int(seq[k]), margin)
		var first: Vector3 = spot.call(0)
		game.place_player(Vector3(first.x, level + 0.3, first.z))
		for i in 40: await physics_frame
		var went_down := false
		var before_middle := -1.0
		var after_middle := -1.0
		var pos := 0
		var steps_back := 0
		for tick in 3600:
			if body.global_position.y - level < -0.5: went_down = true; break
			if pos == seq.size() - 1: break
			if safe.call(pos + 1, 0.9):
				pos += 1
				if int(seq[pos]) == -1: before_middle = battery.get_charge()      # read on the last stone, before the platform
				await _walk(body, spot.call(pos))
				if int(seq[pos]) == -1:
					for i in 60: await physics_frame
					after_middle = battery.get_charge()
			elif not safe.call(pos, 0.45) and pos > 0 and safe.call(pos - 1, 0.45):
				pos -= 1
				steps_back += 1
				await _walk(body, spot.call(pos))
			else:
				await physics_frame
		var score: Dictionary = work.score()
		checks.append({"check": "the walker crosses the stone cross from west to east over the middle", "ok": not went_down and pos == seq.size() - 1 and int(score.crossed) >= 1,
			"clock_s": snappedf(score.last, .1), "went_down": went_down, "steps_back": steps_back, "got_to_place": pos, "of": seq.size() - 1,
			"ended_at": [snappedf(work.to_local(body.global_position).x, .01), snappedf(work.to_local(body.global_position).y, .01), snappedf(work.to_local(body.global_position).z, .01)]})
		checks.append({"check": "the health cross in the middle gives charge back", "ok": after_middle > before_middle, "charge_before": snappedf(before_middle, .1), "charge_after": snappedf(after_middle, .1)})
		result["score"] = {"last_s": snappedf(score.last, .1), "best_s": snappedf(score.best, .1), "crossed": int(score.crossed), "went_down": int(score.went_down), "shocks": int(score.shocks)}
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("stone_cross.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[stone_cross_game] ", "PASSED" if result.passed else "FAILED")
	quit()
