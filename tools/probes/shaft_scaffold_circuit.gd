extends SceneTree
## DOES THE SCAFFOLD ROUND THE SHAFT MAKE A CIRCUIT? (site_shaft_play_scaffold; Palle, 2026-11-12: "place
## pheromone_terrain over shaft B and fit it with a lite playground scaffolding around")
## The Void's own walker goes up the ramp, along the deck and down the slide. Then it is set on the work that lies
## over the shaft (does the lid carry a body?) and, last, into the gap beside it (does the shaft still take a body
## down?). The last one is read, not judged.
##
##   godot --path <stage> --script res://tools/probes/shaft_scaffold_circuit.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## circuit.json: checks with what was read. arrival.png from the spawn point, side.png from the south-east,
## deck.png from the deck looking down at the work over the opening.
var game: Node3D
var work: Node3D


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
		if str(a.artifact) == "site_shaft_play_scaffold": item = a
	var checks := []
	var result := {"floor": floor, "map": str(record.map), "checks": checks, "passed": false}
	if item != null:
		var key := str(floor) + "/" + str(item.id)
		for i in 900:
			if game.building.content.exhibits.has(key): break
			await physics_frame
		var mount: Node3D = game.building.content.exhibits.get(key)
		for n in [mount] + mount.find_children("*", "Node3D", true, false):
			if n.has_method("circuit"): work = n; break
		for i in 240: await physics_frame
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		var c: Dictionary = work.circuit()
		var deck: float = float(work.deck_height)
		var centre: Vector3 = work.global_position
		for layer in root.find_children("*", "CanvasLayer", true, false):      # the game's overlays, not a work's own layers
			if layer.get_viewport() == root: layer.hide()
		game.place_player(Vector3(-3.6, level + 0.3, 7.7))      # aside, not in front of the lens
		for i in 30: await physics_frame
		var cam := Camera3D.new()
		root.add_child(cam)
		await _shot(cam, Vector3(0, level + 1.6, 7.8), Vector3(centre.x * 0.5, level + 0.9, -1.5), folder.path_join("arrival.png"))
		await _shot(cam, Vector3(centre.x + 6.4, level + 2.4, 6.6), Vector3(centre.x - 0.4, level + 1.0, -1.6), folder.path_join("side.png"))
		# 1 up the ramp
		var foot: Vector3 = work.to_global(c.ramp_foot)
		var top: Vector3 = work.to_global(c.ramp_top)
		game.place_player(Vector3(foot.x, level + 0.3, foot.z))
		for i in 40: await physics_frame
		var reach := await _go(body, top)
		for i in 20: await physics_frame
		var feet: float = body.global_position.y - level
		checks.append({"check": "the ramp takes a body up to the deck", "ok": reach < 0.4 and absf(feet - deck) < 0.2, "feet_m": snappedf(feet, .01), "deck_m": deck})
		# 2 along the deck, over the gap
		var look: Vector3 = work.to_global(c.deck_look)
		await _go(body, look)
		var over := body.global_position
		var end: Vector3 = work.to_global(c.deck_end)
		reach = await _go(body, end)
		for i in 10: await physics_frame
		feet = body.global_position.y - level
		checks.append({"check": "the deck carries it across, out over the opening", "ok": reach < 0.4 and absf(feet - deck) < 0.2 and absf(over.y - level - deck) < 0.2,
			"feet_m": snappedf(feet, .01), "stood_over_the_opening_at": [snappedf(over.x, .01), snappedf(over.z, .01)]})
		# 3 down the slide
		var landing: Vector3 = work.to_global(c.slide_foot)
		reach = await _go(body, landing, 420)
		for i in 60: await physics_frame
		feet = body.global_position.y - level
		checks.append({"check": "the slide brings it down to the floor beside the shaft", "ok": absf(feet) < 0.15 and reach < 1.2, "feet_m": snappedf(feet, .01),
			"from_the_landing_m": snappedf(reach, .01)})
		# the view from the deck, taken now that the body is out of the lens
		await _shot(cam, Vector3(look.x, level + deck + 1.6, look.z - 0.3), Vector3(centre.x, level + 0.2, centre.z + 0.4), folder.path_join("deck.png"))
		# 4 the work over the shaft is a lid
		var lid := false
		var stood := 0.0
		for a in record.artifacts:
			if str(a.artifact) == "pheromone_terrain":
				game.place_player(Vector3(float(a.position[0]), level + 0.8, float(a.position[1])))
				for i in 90: await physics_frame
				stood = body.global_position.y - level
				lid = absf(stood) < 0.4 and int(game.checkpoint) == floor
		checks.append({"check": "the work over the shaft carries a body", "ok": lid, "feet_m": snappedf(stood, .01)})
		# 5 read, not judged: the gap north of the work, under the deck
		game.place_player(Vector3(centre.x, level + 0.4, centre.z - 2.62))
		for i in 150: await physics_frame
		var fell: float = body.global_position.y - level
		result["north_gap"] = {"feet_m_after_2_5_s": snappedf(fell, .01), "took_the_body_down": fell < -1.5}
		result["passed"] = checks.all(func(k): return k.ok)
	else:
		checks.append({"check": "site_shaft_play_scaffold stands on this floor", "ok": false})
	var file := FileAccess.open(folder.path_join("circuit.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[shaft_scaffold_circuit] ", "PASSED" if result.passed else "FAILED")
	quit()
