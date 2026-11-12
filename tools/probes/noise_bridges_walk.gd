extends SceneTree
## THROUGH THE TWO NOISE GALLERIES (floor Random_Noise_Types; the Void, 2026-11-12)
## White Noise Gallery fills shaft A and Noise Colors 3D shaft B. A bridge of the playground kit runs through each,
## rim to rim. The Void's own walker crosses both. Read: does each bridge carry it level from the south rim to the
## north one, through the needles and across the five rows, without leaving this floor.
##
##   godot --path <stage> --script res://tools/probes/noise_bridges_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## bridges.json: checks with what was read. inside_a.png and inside_b.png are taken from the middle of each bridge at
## eye height; arrival.png from the spawn point.
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
	var bridges := []
	for a in record.artifacts:
		if str(a.artifact) != "playground_spec_hall" or not a.config.has("place_spec"): continue
		for d in a.config.place_spec.get("decks", []):
			if str(d.id) == "through": bridges.append({"item": a, "deck": d})
	checks.append({"check": "a bridge of the kit runs through each gallery", "ok": bridges.size() == 2, "bridges": bridges.size()})
	if bridges.size() == 2:
		for b in bridges:
			for i in 900:
				if game.building.content.exhibits.has(str(floor) + "/" + str(b.item.id)): break
				await physics_frame
		for i in 420: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		for layer in root.find_children("*", "CanvasLayer", true, false):      # the game's overlays, not a work's own layers
			if layer.get_viewport() == root: layer.hide()
		game.place_player(Vector3(-3.6, level + 0.3, 8.6))
		for i in 30: await physics_frame
		var cam := Camera3D.new()
		root.add_child(cam)
		await _shot(cam, Vector3(0, level + 1.6, 7.8), Vector3(0, level + 1.0, 0), folder.path_join("arrival.png"))
		for b in bridges:
			var x: float = float(b.item.position[0]) + float(b.deck.at[0])
			var z: float = float(b.item.position[1]) + float(b.deck.at[2])
			var half: float = float(b.deck.size[1]) / 2.0
			var side := "a" if x < 0 else "b"
			await _shot(cam, Vector3(x, level + 1.6, z + 0.6), Vector3(x + (0.6 if x < 0 else -0.6), level + 1.1, z - half - 3.0), folder.path_join("inside_%s.png" % side))
			game.place_player(Vector3(x, level + 0.3, z + half + 0.9))
			for i in 40: await physics_frame
			var worst := 0.0
			var reach := INF
			var target := Vector3(x, level, z - half - 0.9)
			for i in 480:
				var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
				reach = minf(reach, d)
				if d < 0.25: break
				worst = maxf(worst, absf(body.global_position.y - level))
				body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
				body.drive = Vector2(0, -1)
				await physics_frame
			body.drive = Vector2.ZERO
			for i in 20: await physics_frame
			checks.append({"check": "the bridge through shaft %s carries a body level from rim to rim" % side.to_upper(),
				"ok": reach < 0.4 and worst < 0.1 and int(game.checkpoint) == floor, "came_within_m": snappedf(reach, .01), "furthest_from_level_m": snappedf(worst, .01)})
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("bridges.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[noise_bridges_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
