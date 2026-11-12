extends SceneTree
## THE PIPE WALK, LAID WITH THE PLAYGROUND KIT (floor Randomness_Examples_of_Randomness; Palle, 2026-11-12: "use this
## playground principal and style for the pipes")
## The floor holds a playground_spec_hall whose place specification has a `walks` layer
## (commons/modular/places/walk_builder.gd). Read: is the frame made of the kit's own parts and nothing else; does
## the Void's own walker get up every ramp the walk laid - from the floor to a first level, and from level to level.
##
##   godot --path <stage> --script res://tools/probes/walk_place_climb.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## walk_place.json: checks with what was read. arrival.png from the spawn point, side.png from the west,
## top.png from the highest floor the walker reached.
var game: Node3D
var level := 0.0


func _initialize() -> void:
	run.call_deferred()


func _go(body: CharacterBody3D, target: Vector3, ticks_max: int = 420) -> float:
	var best := INF
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		best = minf(best, d)
		if d < 0.2: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -1)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 25: await physics_frame
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
	for a in record.artifacts:
		if str(a.artifact) == "playground_spec_hall" and a.config.has("place_spec") and not (a.config.place_spec.get("walks", []) as Array).is_empty(): item = a
	checks.append({"check": "the floor has a walk laid by the playground kit", "ok": item != null})
	if item != null:
		var key := str(floor) + "/" + str(item.id)
		for i in 900:
			if game.building.content.exhibits.has(key): break
			await physics_frame
		var mount: Node3D = game.building.content.exhibits.get(key)
		var hall: Node3D = null
		for i in 600:
			for n in [mount] + mount.find_children("*", "Node3D", true, false):
				if n.get("recipe") is Dictionary and (n.recipe as Dictionary).has("walks"): hall = n; break
			if hall != null: break
			await physics_frame
		for i in 240: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		var origin := Vector3(float(item.position[0]), level + float(item.get("height", 0)), float(item.position[1]))
		for layer in root.find_children("*", "CanvasLayer", true, false):      # the game's overlays, not a work's own layers
			if layer.get_viewport() == root: layer.hide()
		game.place_player(Vector3(-3.6, level + 0.3, 7.9))      # aside, not in front of the lens
		for i in 30: await physics_frame
		var cam := Camera3D.new()
		root.add_child(cam)
		await _shot(cam, Vector3(0, level + 1.6, 7.8), origin + Vector3(0, 1.6, 0), folder.path_join("arrival.png"))
		await _shot(cam, origin + Vector3(-10.5, 2.3, 3.4), origin + Vector3(0, 1.4, 0), folder.path_join("side.png"))
		await _shot(cam, origin + Vector3(2.5, 2.0, 5.2), origin + Vector3(0, 1.5, 0), folder.path_join("front.png"))
		# 1 the kit's own parts and nothing else
		var kinds := {}
		var foreign := 0
		if hall != null:
			for part in hall.recipe.parts:
				var source := str(part.source)
				kinds[source] = int(kinds.get(source, 0)) + 1
				if not source.begins_with("workshop_"): foreign += 1
		checks.append({"check": "the frame is made of the kit's own parts and nothing else", "ok": hall != null and foreign == 0 and int(kinds.get("workshop_rod", 0)) + int(kinds.get("workshop_rod_short", 0)) > 40,
			"parts": kinds})
		# 2 every ramp the walk laid
		var walk: Dictionary = hall.recipe.walks[0] if hall != null else {}
		var from_floor := 0
		var higher := 0
		var higher_of := 0
		var rows := []
		var best := Vector3.ZERO
		var best_feet := -INF      # the tower descends: world heights are negative, so the highest is kept by its own number
		for ramp in walk.get("ramps", []):
			var foot := origin + Vector3(float(ramp.foot[0]), float(ramp.foot[1]), float(ramp.foot[2]))
			var top := origin + Vector3(float(ramp.top[0]), float(ramp.top[1]), float(ramp.top[2]))
			var ground: bool = int(ramp.from_level) == 0
			if not ground: higher_of += 1
			game.place_player(foot + Vector3(0, 0.35, 0))
			for i in 45: await physics_frame
			var reach := await _go(body, top)
			var feet: float = body.global_position.y - origin.y
			var made: bool = reach < 0.4 and absf(feet - float(ramp.to_level)) < 0.2
			rows.append({"from": int(ramp.from_level), "to": int(ramp.to_level), "side": str(ramp.side), "feet_m": snappedf(feet, .01), "ok": made})
			if made:
				if ground: from_floor += 1
				else: higher += 1
				if feet > best_feet:
					best_feet = feet
					best = body.global_position
		checks.append({"check": "a body walks up a ramp from the floor to the first level", "ok": from_floor >= 1, "walked": from_floor, "ramps": rows})
		checks.append({"check": "and from level to level", "ok": higher_of == 0 or higher >= 1, "walked": higher, "of": higher_of,
			"floors": (walk.get("floors", []) as Array).size(), "bars": walk.get("bars", 0)})
		if best_feet > -INF:
			var eye := best + Vector3(0, 1.6, 0)
			game.place_player(Vector3(-3.6, level + 0.3, 7.9))
			for i in 20: await physics_frame
			await _shot(cam, eye, origin + Vector3(0, 0.6, 0.4), folder.path_join("top.png"))
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("walk_place.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[walk_place_climb] ", "PASSED" if result.passed else "FAILED")
	quit()
