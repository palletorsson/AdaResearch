extends SceneTree
## CAN A BODY STAND ON EACH TERM OF THE SUM? (layer_sum_islands on floor Random_Space; the Void, 2026-11-12)
## Five islands from one seed: four hold one layer of the noise mixer's sum each, the fifth holds the sum. The
## Void's own walker is stood at the same three spots on every island (does each ground carry a body at the height
## that was drawn, and do the four heights add up to the fifth?), crosses the sum from its shore to its cut face on
## three lines, and walks the corridor between two cut faces. Last, read and not judged: the weight is set to
## `lingering` in the running game and the sum is crossed again.
##
##   godot --path <stage> --script res://tools/probes/layer_islands_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## islands.json: checks with what was read. row.png along the shore, high.png from above, corridor.png between the
## last layer and the sum, sum.png the last island from above.
var game: Node3D
var work: Node3D
var level := 0.0


func _initialize() -> void:
	run.call_deferred()


func _go(body: CharacterBody3D, target: Vector3, ticks_max: int = 600) -> float:
	var best := INF
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		best = minf(best, d)
		if d < 0.25: break
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


## Cross the last island from its shore to beyond its cut face on three lines; how near the far side each came.
func _cross_sum(body: CharacterBody3D) -> Array:
	var out := []
	var last: int = int(work.layers)
	for v in [0.25, 0.5, 0.75]:
		var east: Vector3 = work.to_global(work.spot(last, 1.0, v) + Vector3(0.5, 0, 0))
		var west: Vector3 = work.to_global(work.spot(last, 0.0, v) + Vector3(-0.7, 0, 0))
		game.place_player(Vector3(east.x, level + 0.3, east.z))
		for i in 30: await physics_frame
		var reach := await _go(body, west, 420)
		out.append(snappedf(reach, .01))
	return out


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
		if str(a.artifact) == "layer_sum_islands": item = a
	var checks := []
	var result := {"floor": floor, "map": str(record.map), "checks": checks, "passed": false}
	if item != null:
		var key := str(floor) + "/" + str(item.id)
		for i in 900:
			if game.building.content.exhibits.has(key): break
			await physics_frame
		var mount: Node3D = game.building.content.exhibits.get(key)
		for n in [mount] + mount.find_children("*", "Node3D", true, false):
			if n.has_method("spot"): work = n; break
		for i in 240: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		var last: int = int(work.layers)
		var centre: Vector3 = work.global_position
		var half: float = (last + 1) * float(work.island.y) / 2.0 + last * float(work.gap) / 2.0
		for layer in root.find_children("*", "CanvasLayer", true, false):      # the game's overlays, not a work's own layers
			if layer.get_viewport() == root: layer.hide()
		game.place_player(Vector3(3.6, level + 0.3, 7.7))      # aside, not in front of the lens
		for i in 30: await physics_frame
		var cam := Camera3D.new()
		root.add_child(cam)
		await _shot(cam, Vector3(centre.x + 4.3, level + 1.7, centre.z + 4.6), Vector3(centre.x - 0.6, level + 0.2, centre.z - 4.0), folder.path_join("row.png"))
		await _shot(cam, Vector3(centre.x + 8.2, level + 5.2, centre.z + 0.4), Vector3(centre.x + 0.4, level, centre.z), folder.path_join("high.png"))
		var sum_at: Vector3 = work.to_global(work.spot(last, 0.5, 0.5))
		await _shot(cam, Vector3(sum_at.x + 2.9, level + 3.6, sum_at.z + 2.6), Vector3(sum_at.x - 0.3, level + 0.2, sum_at.z), folder.path_join("sum.png"))
		var mouth: Vector3 = work.to_global(work.spot(last, 1.0, 1.0) + Vector3(0.9, 0, float(work.gap) / 2.0))
		await _shot(cam, Vector3(mouth.x - 1.6, level + 1.25, mouth.z), Vector3(mouth.x - 5.0, level + 0.25, mouth.z), folder.path_join("corridor.png"))
		# 1 the same three spots on every island
		var worst := 0.0
		var rows := []
		var adds := 0.0
		for uv in [Vector2(0.3, 0.5), Vector2(0.5, 0.3), Vector2(0.6, 0.7)]:
			var feet := []
			var drawn := []
			for which in last + 1:
				var local: Vector3 = work.spot(which, uv.x, uv.y)
				var at: Vector3 = work.to_global(local)
				game.place_player(Vector3(at.x, at.y + 0.5, at.z))
				for i in 50: await physics_frame
				var stood: float = body.global_position.y - level
				feet.append(snappedf(stood, .01))
				drawn.append(snappedf(local.y, .01))
				worst = maxf(worst, absf(stood - local.y))
			var total := 0.0
			for which in last: total += float(drawn[which])
			adds = maxf(adds, absf(total - float(drawn[last])))
			rows.append({"spot": [uv.x, uv.y], "drawn_m": drawn, "feet_m": feet})
		checks.append({"check": "every island carries a body at the height that was drawn", "ok": worst < 0.09, "worst_gap_m": snappedf(worst, .01), "spots": rows})
		checks.append({"check": "at each spot the four layers' heights add up to the fifth island's", "ok": adds < 0.011, "worst_difference_m": snappedf(adds, .001)})
		# 2 across the sum, shore to cut face
		var reaches: Array = await _cross_sum(body)
		var crossed := reaches.filter(func(r): return float(r) < 0.4).size()
		checks.append({"check": "the sum can be crossed from its shore to its cut face", "ok": crossed >= 2, "lines_crossed_of_3": crossed, "came_within_m": reaches,
			"steepest_rise_over_run": snappedf(work.steepest(last), .01), "weigh": str(work.weigh)})
		# 3 the corridor between the last layer and the sum
		var from: Vector3 = work.to_global(work.spot(last, 1.0, 1.0) + Vector3(0.6, 0, float(work.gap) / 2.0))
		var to: Vector3 = work.to_global(work.spot(last, 0.0, 1.0) + Vector3(-0.6, 0, float(work.gap) / 2.0))
		game.place_player(Vector3(from.x, level + 0.3, from.z))
		for i in 30: await physics_frame
		var through := await _go(body, to, 420)
		checks.append({"check": "a body walks the corridor between two cut faces", "ok": through < 0.4, "came_within_m": snappedf(through, .01)})
		result["passed"] = checks.all(func(c): return c.ok)
		# 4 read, not judged: each finer layer weighs 0.7
		game.place_player(Vector3(3.6, level + 0.3, 7.7))
		for i in 10: await physics_frame
		work.weigh = "lingering"
		work.rebuild()
		for i in 30: await physics_frame
		var rough: Array = await _cross_sum(body)
		result["lingering"] = {"steepest_rise_over_run": snappedf(work.steepest(last), .01), "came_within_m": rough,
			"lines_crossed_of_3": rough.filter(func(r): return float(r) < 0.4).size()}
		game.place_player(Vector3(3.6, level + 0.3, 7.7))
		for i in 20: await physics_frame
		await _shot(cam, Vector3(sum_at.x + 2.9, level + 3.6, sum_at.z + 2.6), Vector3(sum_at.x - 0.3, level + 0.2, sum_at.z), folder.path_join("sum_lingering.png"))
	else:
		checks.append({"check": "layer_sum_islands stands on this floor", "ok": false})
	var file := FileAccess.open(folder.path_join("islands.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[layer_islands_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
