extends SceneTree
## DOES THE CROSSING KEEP ITS PROMISES TO A BODY? (r_c with stand:chasm on floor Random_Game; the Void, 2026-11-12)
## The hall text says: approach the first stone by its ramp; it can leave while you stand on it; the pit has a
## recovery bed and a ramp out; the corridor beside the pit reaches the far lip too. The Void's own walker tries to
## cross on the stones, is set on the bed and takes the way out, and goes round the pit on both sides.
## The crossing is READ, not judged: whether a body gets over depends on the drawn waits.
##
##   godot --path <stage> --script res://tools/probes/random_game_crossing.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## crossing.json: checks with what was read. lip.png from the near lip, bed.png from the bed, far.png from the far lip.
var game: Node3D
var level := 0.0


func _initialize() -> void:
	run.call_deferred()


func _go(body: CharacterBody3D, target: Vector3, ticks_max: int = 480) -> Dictionary:
	var best := INF
	var lowest := INF
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		best = minf(best, d)
		lowest = minf(lowest, body.global_position.y - level)
		if d < 0.25: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -1)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 25: await physics_frame
	return {"reach": best, "lowest": lowest, "feet": body.global_position.y - level, "at": body.global_position}


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
	var checks := []
	var result := {"floor": floor, "map": str(record.map), "checks": checks, "passed": false}
	var item = null
	for a in record.artifacts:
		if str(a.artifact) == "r_c": item = a
	checks.append({"check": "the crossing stands on this floor", "ok": item != null})
	if item != null:
		var key := str(floor) + "/" + str(item.id)
		for i in 900:
			if game.building.content.exhibits.has(key): break
			await physics_frame
		var mount: Node3D = game.building.content.exhibits.get(key)
		var crossing: Node3D = null
		for i in 600:
			crossing = mount.find_child("Crossing", true, false)
			if crossing != null: break
			await physics_frame
		for i in 240: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		var bed: Node3D = crossing.find_child("Bed", true, false) if crossing != null else null
		var out: Node3D = crossing.find_child("WayOut", true, false) if crossing != null else null
		var near: Node3D = crossing.find_child("End_near", true, false) if crossing != null else null
		var far: Node3D = crossing.find_child("End_far", true, false) if crossing != null else null
		checks.append({"check": "the pit has a bed, a way out and two lips", "ok": bed != null and out != null and near != null and far != null})
		if bed != null and out != null and near != null and far != null:
			var mid: Vector3 = bed.global_position
			var toward := (far.global_position - near.global_position); toward.y = 0
			var half: float = toward.length() / 2.0
			toward = toward.normalized()
			var across := Vector3(toward.z, 0, -toward.x)
			var start := Vector3(mid.x, level, mid.z) - toward * (half + 1.5)
			var goal := Vector3(mid.x, level, mid.z) + toward * (half + 1.3)
			result["bed_below_floor_m"] = snappedf(mid.y - level, .01)
			for layer in root.find_children("*", "CanvasLayer", true, false):      # the game's overlays, not a work's own layers
				if layer.get_viewport() == root: layer.hide()
			game.place_player(Vector3(start.x, level + 0.3, start.z) + across * 3.4)
			for i in 30: await physics_frame
			var cam := Camera3D.new()
			root.add_child(cam)
			await _shot(cam, start + Vector3(0, 1.6, 0) - toward * 0.4, Vector3(goal.x, level + 0.4, goal.z), folder.path_join("lip.png"))
			await _shot(cam, Vector3(mid.x, mid.y + 1.5, mid.z) - toward * 0.9, Vector3(out.global_position.x, mid.y + 0.5, out.global_position.z), folder.path_join("bed.png"))
			await _shot(cam, goal + Vector3(0, 1.7, 0) + toward * 0.6, start + Vector3(0, 0.3, 0), folder.path_join("far.png"))
			# 1 read: across on the stones, three tries
			var tries := []
			for t in 3:
				game.place_player(Vector3(start.x, level + 0.3, start.z))
				for i in 40 + t * 140: await physics_frame
				var walked: Dictionary = await _go(body, goal)
				tries.append({"crossed": float(walked.reach) < 0.4 and float(walked.lowest) > -0.4, "lowest_m": snappedf(walked.lowest, .01), "ended_m": snappedf(walked.feet, .01)})
			result["crossing_on_the_stones"] = tries
			# 2 the bed and the way out
			game.place_player(Vector3(mid.x, mid.y + 0.5, mid.z) + across * 0.2 - toward * 0.3)
			for i in 60: await physics_frame
			var on_bed: float = body.global_position.y - level
			checks.append({"check": "a body that falls lands on the bed, not through the floor", "ok": absf(on_bed - (mid.y - level)) < 0.25 and int(game.checkpoint) == floor, "feet_m": snappedf(on_bed, .01)})
			var ramp_at: Vector3 = out.global_position
			var side := (Vector3(ramp_at.x, 0, ramp_at.z) - Vector3(mid.x, 0, mid.z)).dot(across)
			var lane := across * side
			var up: Dictionary = await _go(body, Vector3(mid.x, level, mid.z) + lane + toward * (half - 0.5))
			up = await _go(body, Vector3(mid.x, level, mid.z) + lane - toward * (half + 0.9))
			checks.append({"check": "the way out takes it from the bed back up to the floor", "ok": absf(float(up.feet)) < 0.2, "feet_m": snappedf(up.feet, .01),
				"ramp_side": "east" if lane.x > 0 else "west"})
			# 3 going round, on each side
			var round := {}
			for s in [-1.0, 1.0]:
				game.place_player(Vector3(start.x, level + 0.3, start.z) + across * s * 3.6)
				for i in 30: await physics_frame
				await _go(body, Vector3(goal.x, level, goal.z) + across * s * 3.6)
				var last: Dictionary = await _go(body, goal)
				round["east" if (across * s).x > 0 else "west"] = float(last.reach) < 0.5 and absf(float(last.feet)) < 0.3
			checks.append({"check": "going round the pit reaches the far lip", "ok": round.values().has(true), "by_side": round})
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("crossing.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[random_game_crossing] ", "PASSED" if result.passed else "FAILED")
	quit()
