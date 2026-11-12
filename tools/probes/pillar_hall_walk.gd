extends SceneTree
## NINE PILLARS, THREE CLOCKS (melting_pillar_hall on floor Noise_Columns; Palle, 2026-11-12: "we need more (9) of
## the pillars larger, more space between and up to the ceiling")
## Read in the running tower: nine pillars, three to a clock; every shaft reaches from its plinth to its capital at
## the ceiling while it changes; the three on one clock move as one; the small stand's console holds and names
## them; the Void's own walker passes between them and is stopped by one; what a frame of the work costs.
##
##   godot --path <stage> --script res://tools/probes/pillar_hall_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## pillars.json: checks with what was read. arrival.png from the spawn, hall.png from the south-west corner,
## close.png under one pillar, named.png with the plates revealed.
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


func _levels(kind: String) -> Array:
	var out := []
	for p in work.pillars():
		if str(p.driver) == kind: out.append(int(p.level))
	return out


## Walk toward a point at full drive for at most `ticks`; returns the least z the body reached.
func _walk(body: CharacterBody3D, from: Vector3, to: Vector3, ticks: int) -> Dictionary:
	game.place_player(from)
	for i in 40: await physics_frame
	var north := INF
	var reach := INF
	for i in ticks:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(to.x, to.z))
		reach = minf(reach, d)
		north = minf(north, body.global_position.z)
		if d < 0.25: break
		body.look_at(Vector3(to.x, body.global_position.y, to.z), Vector3.UP)
		body.drive = Vector2(0, -1)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 20: await physics_frame
	return {"came_within_m": snappedf(reach, .01), "least_z": snappedf(north, .01)}


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
		if str(a.artifact) == "melting_pillar_hall": item = a
	checks.append({"check": "the hall of pillars is on this floor", "ok": item != null})
	if item != null:
		var key := str(floor) + "/" + str(item.id)
		for i in 900:
			if game.building.content.exhibits.has(key): break
			await physics_frame
		var mount: Node3D = game.building.content.exhibits.get(key)
		for n in [mount] + mount.find_children("*", "Node3D", true, false):
			if n.has_method("pillars"): work = n; break
		for i in 600:
			if int(work.ready_levels()) >= int(work.levels) and work.following(): break
			await physics_frame
		for i in 120: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		for layer in root.find_children("*", "CanvasLayer", true, false):      # the game's overlays, not a work's own layers
			if layer.get_viewport() == root: layer.hide()
		game.place_player(Vector3(-3.6, level + 0.3, 8.6))
		for i in 30: await physics_frame
		var cam := Camera3D.new()
		cam.fov = 80
		root.add_child(cam)
		await _shot(cam, Vector3(0, level + 1.6, 7.8), Vector3(0, level + 2.3, 0), folder.path_join("arrival.png"))
		await _shot(cam, Vector3(-19.6, level + 4.4, 8.4), Vector3(3, level + 2.0, -2.5), folder.path_join("hall.png"))
		await _shot(cam, Vector3(6.4, level + 1.6, 6.0), Vector3(4.25, level + 3.3, 3.4), folder.path_join("close.png"))

		var all: Array = work.pillars()
		var count := {}
		for p in all: count[p.driver] = int(count.get(p.driver, 0)) + 1
		checks.append({"check": "nine pillars, three to a clock", "ok": all.size() == 9 and count.get("baseline", 0) == 3 and count.get("periodic", 0) == 3 and count.get("field", 0) == 3, "count": count})
		var gap := INF
		for i in all.size():
			for j in range(i + 1, all.size()):
				gap = minf(gap, Vector2(all[i].at.x - all[j].at.x, all[i].at.z - all[j].at.z).length())
		checks.append({"check": "more space between: no two pillars nearer than eight metres", "ok": gap >= 8.0, "nearest_pair_m": snappedf(gap, .01)})

		# eight seconds of the running hall
		var foot_low := INF
		var foot_high := -INF
		var head_off := 0.0
		var together := true
		var base_seen := {}
		var sine_seen := {}
		var field_seen := {}
		var ceiling: float = float(work.ceiling)
		for tick in 480:
			await physics_frame
			if tick % 6 != 0: continue
			for p in work.pillars():
				foot_low = minf(foot_low, float(p.foot) - (level + 0.4))
				foot_high = maxf(foot_high, float(p.foot) - (level + 0.4))
				head_off = maxf(head_off, absf(float(p.head) - (level + ceiling - 0.3)))
			var sine := _levels("periodic")
			var field := _levels("field")
			if sine.min() != sine.max() or field.min() != field.max(): together = false
			for v in _levels("baseline"): base_seen[v] = true
			sine_seen[sine[0]] = true
			field_seen[field[0]] = true
		checks.append({"check": "up to the ceiling: every shaft spans plinth to capital while it changes", "ok": head_off < 0.03 and foot_high < 0.02 and foot_low > -0.2,
			"head_from_capital_m": snappedf(head_off, .001), "foot_from_plinth_top_m": [snappedf(foot_low, .001), snappedf(foot_high, .001)], "ceiling_m": ceiling})
		checks.append({"check": "the three on one clock move as one; the fixed three do not move", "ok": together and base_seen.size() == 1 and sine_seen.size() >= 8 and field_seen.size() >= 3,
			"phases_seen": {"baseline": base_seen.size(), "periodic": sine_seen.size(), "field": field_seen.size()}})

		# the small stand's console runs the hall
		var console: Node = work.console()
		checks.append({"check": "the hall takes its clock from the stand of three on this floor", "ok": console != null})
		if console != null:
			console.toggle_freeze()
			for i in 30: await physics_frame
			var held_a: Array = _levels("periodic") + _levels("field")
			for i in 150: await physics_frame
			var held_b: Array = _levels("periodic") + _levels("field")
			console.toggle_freeze()
			checks.append({"check": "FREEZE on the console holds all nine", "ok": held_a == held_b, "levels": held_b})
			console.reveal_drivers()
			for i in 20: await physics_frame
			var named := {}
			for p in work.pillars(): named[p.plate] = int(named.get(p.plate, 0)) + 1
			await _shot(cam, Vector3(1.2, level + 1.6, 7.2), Vector3(4.25, level + 1.6, 3.4), folder.path_join("named.png"))
			console.reveal_drivers()
			for i in 20: await physics_frame
			var hidden: Array = []
			for p in work.pillars(): hidden.append(p.plate)
			checks.append({"check": "REVEAL names every plinth, and hides them again", "ok": named.get("BASELINE", 0) == 3 and named.get("PERIODIC", 0) == 3 and named.get("FIELD", 0) == 3 and hidden.count("?") == 9, "named": named})

		# a body among them
		var gate: Dictionary = await _walk(body, Vector3(0, level + 0.3, 7.8), Vector3(0, level, 2.4), 420)
		checks.append({"check": "the walker passes between the two pillars in front of the arrival", "ok": float(gate.came_within_m) < 0.4 and int(game.checkpoint) == floor, "walk": gate})
		var stop: Dictionary = await _walk(body, Vector3(4.25, level + 0.3, 7.0), Vector3(4.25, level, 0.5), 300)
		checks.append({"check": "a pillar stops a body that walks at it", "ok": float(stop.least_z) > 3.4 + 0.6, "walk": stop})
		game.place_player(Vector3(-3.6, level + 0.3, 8.6))
		work.frame_ms()
		for i in 300: await process_frame
		var ms: float = work.frame_ms()
		checks.append({"check": "the running hall costs little a frame", "ok": ms < 0.5, "mean_ms_a_frame": snappedf(ms, .001)})
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("pillars.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[pillar_hall_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
