extends SceneTree
## A BASIN FROM THE PLAYGROUND KIT, AN ARTIFACT FITTED IN IT (floor Random_Pheromone; Palle, 2026-11-12: "the
## playground you should use the playground maker and make a basin and fit the artifact, place in the shaft b at
## level 0")
## The floor holds a playground_spec_hall whose place specification has one pool with an activity. The Void's own
## walker takes the kit's own way: up the outer ramp to the rim, down the descent into the pool. Read: does the
## pool's floor lie at level 0 and carry a body; is the activity fitted to the slot with its console inside; does
## the console still step it; does the walk in and out work without a jump.
##
##   godot --path <stage> --script res://tools/probes/basin_place_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## basin_place.json: checks with what was read. arrival.png from the spawn point, side.png from the south-east,
## rim.png from the landing looking down into the pool, inside.png standing in the pool.
var game: Node3D
var level := 0.0


func _initialize() -> void:
	run.call_deferred()


func _go(body: CharacterBody3D, target: Vector3, ticks_max: int = 600) -> float:
	var best := INF
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		best = minf(best, d)
		if d < 0.2: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -1)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 20: await physics_frame
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
	var checks := []
	var result := {"floor": floor, "map": str(record.map), "checks": checks, "passed": false}
	var item = null
	var place = null
	for a in record.artifacts:
		if str(a.artifact) != "playground_spec_hall" or not a.config.has("place_spec"): continue
		for p in a.config.place_spec.get("places", []):
			if float(p.get("depth", 0)) > 0 and p.has("activity"): item = a; place = p
	checks.append({"check": "the floor has a pool place with an activity, made by the playground kit", "ok": item != null})
	if item != null:
		var key := str(floor) + "/" + str(item.id)
		for i in 900:
			if game.building.content.exhibits.has(key): break
			await physics_frame
		var mount: Node3D = game.building.content.exhibits.get(key)
		var work: Node3D = null
		for i in 900:
			for n in mount.find_children("*", "Node3D", true, false):
				if n.has_method("advance_comparison"): work = n; break
			if work != null: break
			await physics_frame
		for i in 240: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		var y: float = float(place.y)
		var depth: float = float(place.depth)
		var hx: float = float(place.size[0]) / 2.0
		var hz: float = float(place.size[1]) / 2.0
		var centre := Vector3(float(item.position[0]) + float(place.at[0]), level + float(item.get("height", 0)), float(item.position[1]) + float(place.at[1]))
		var entry := centre + Vector3(-2.0 * y - 2.5, 0, hz + 2.0)
		var landing := centre + Vector3(0, y, hz + 2.0)
		var inside := centre + Vector3(0, y - depth, 0.4)
		for layer in root.find_children("*", "CanvasLayer", true, false):      # the game's overlays, not a work's own layers
			if layer.get_viewport() == root: layer.hide()
		game.place_player(Vector3(-3.6, level + 0.3, 7.7))      # aside, not in front of the lens
		for i in 30: await physics_frame
		var cam := Camera3D.new()
		root.add_child(cam)
		await _shot(cam, Vector3(0, level + 1.6, 7.8), Vector3(centre.x * 0.5, level + 0.9, -1.5), folder.path_join("arrival.png"))
		await _shot(cam, Vector3(centre.x + 6.8, level + 2.8, centre.z + 7.2), Vector3(centre.x - 0.3, level + 0.7, centre.z + 0.4), folder.path_join("side.png"))
		await _shot(cam, landing + Vector3(0, 1.6, 0.6), centre + Vector3(0, 0.2, -1.0), folder.path_join("rim.png"))
		await _shot(cam, centre + Vector3(0.4, y - depth + 1.6, 1.7), centre + Vector3(-0.2, y - depth + 0.5, -2.6), folder.path_join("inside.png"))
		# 1 the pool's floor
		game.place_player(centre + Vector3(0.9, y - depth + 0.6, 0.9))
		for i in 80: await physics_frame
		var stood: float = body.global_position.y - centre.y
		checks.append({"check": "the pool's floor lies at level %s over the shaft and carries a body" % str(snappedf(y - depth, .01)),
			"ok": absf(stood - (y - depth)) < 0.14 and int(game.checkpoint) == floor, "feet_m": snappedf(stood, .01)})
		# 2 the activity in the slot
		var fitted := false
		var display := 0.0
		var console_at := Vector3.ZERO
		var stepped := false
		if work != null:
			var plane: Node3D = work.get_node("Plane")
			display = 20.0 * plane.global_transform.basis.get_scale().x
			var console: Node3D = work.get_node_or_null("StepComparison/ConsoleBody")
			if console != null:
				console_at = console.global_position - centre
				var before: int = int(work.get("_comparison_steps"))
				work.advance_comparison(20)
				stepped = int(work.get("_comparison_steps")) == before + 20
			var bed_ok: bool = absf(plane.global_position.y - centre.y - (y - depth)) < 0.12
			fitted = display <= float(place.size[0]) - 0.2 and display >= float(place.size[0]) - 1.0 and bed_ok and absf(console_at.x) < hx and absf(console_at.z) < hz
		checks.append({"check": "the artifact is fitted to the slot: its display fills the pool floor, its console stands inside", "ok": fitted,
			"display_m": snappedf(display, .01), "slot_m": place.size, "console_from_the_middle_m": [snappedf(console_at.x, .01), snappedf(console_at.z, .01)]})
		checks.append({"check": "the console still steps the model", "ok": stepped})
		# 3 the kit's own way in: up the outer ramp, down the descent
		game.place_player(Vector3(entry.x, entry.y + 0.3, entry.z))
		for i in 40: await physics_frame
		var reach := await _go(body, landing)
		var up: float = body.global_position.y - centre.y
		checks.append({"check": "a body walks up the outer ramp to the rim", "ok": reach < 0.35 and absf(up - y) < 0.2, "feet_m": snappedf(up, .01), "rim_m": y})
		reach = await _go(body, inside)
		var down: float = body.global_position.y - centre.y
		checks.append({"check": "and down the descent into the pool, onto the model", "ok": reach < 0.35 and absf(down - (y - depth)) < 0.16, "feet_m": snappedf(down, .01)})
		reach = await _go(body, landing)
		var back: float = body.global_position.y - centre.y
		checks.append({"check": "and out again", "ok": reach < 0.35 and absf(back - y) < 0.2, "feet_m": snappedf(back, .01)})
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("basin_place.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[basin_place_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
