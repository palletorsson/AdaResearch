extends SceneTree
## SIX STEPS OF ONE FIELD (a corridor of kit boards on floor Noise_6_Wall; the Void, 2026-11-12)
## The room on this floor is lined with a sum of six terms. In the east bay the sum is laid out as a corridor of 24
## framed plates from the playground kit, wearing the room's own wall shader: the west wall shows what each step
## adds (the term alone, below made visible, above at its weight), the east wall what you have (the sum so far,
## below bare, above dressed as the room's skin). Read in the running tower:
##   36 plates stand (24 in the corridor, 12 as a mural on the back of the west wall, toward the floor), each with
##     the settings its place in the sum asks for;
##   both walls face into the corridor and the mural faces the floor;
##   the Void's walker walks the corridor end to end over its kit floor plate, and a wall stops it.
##
##   godot --path <stage> --script res://tools/probes/six_steps_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## six_steps.json: checks with what was read. arrival.png, mural.png, mouth.png, adds.png, have.png, grain.png.
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


func _go(body: CharacterBody3D, target: Vector3, ticks_max: int = 700) -> Dictionary:
	var best := INF
	var west := INF
	var off := 0.0
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		best = minf(best, d)
		west = minf(west, body.global_position.x)
		off = maxf(off, absf(body.global_position.y - level))
		if d < 0.25: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -1)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 20: await physics_frame
	return {"came_within_m": snappedf(best, .01), "least_x": snappedf(west, .01), "furthest_from_level_m": snappedf(off, .01)}


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
		if str(a.artifact) == "playground_spec_hall" and a.config.has("place_spec") and a.config.place_spec.has("boards"): item = a
	checks.append({"check": "the floor holds a playground hall whose place specification has boards", "ok": item != null})
	if item != null:
		var key := str(floor) + "/" + str(item.id)
		for i in 900:
			if game.building.content.exhibits.has(key): break
			await physics_frame
		var mount: Node3D = game.building.content.exhibits.get(key)
		var plates := {}
		for i in 900:
			plates.clear()
			for n in mount.find_children("*", "Node3D", true, false):
				if n.has_method("wear_material"): plates[str(n.name)] = n
			if plates.size() >= 36: break
			await physics_frame
		for i in 240: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		for layer in root.find_children("*", "CanvasLayer", true, false):      # the game's overlays, not a work's own layers
			if layer.get_viewport() == root: layer.hide()
		game.place_player(Vector3(-3.6, level + 0.3, 8.6))
		for i in 30: await physics_frame
		var hub := Vector3(float(item.position[0]), level, float(item.position[1]))
		var cam := Camera3D.new()
		cam.fov = 80
		root.add_child(cam)
		await _shot(cam, Vector3(0, level + 1.6, 7.8), hub + Vector3(-2, 2.0, 0), folder.path_join("arrival.png"))
		await _shot(cam, hub + Vector3(-9.5, 1.6, 4.6), hub + Vector3(-2, 2.0, -0.5), folder.path_join("mural.png"))
		await _shot(cam, hub + Vector3(0, 1.6, 8.4), hub + Vector3(0, 2.0, -6), folder.path_join("mouth.png"))
		await _shot(cam, hub + Vector3(1.7, 1.6, 1.4), hub + Vector3(-2, 2.0, -0.6), folder.path_join("adds.png"))
		await _shot(cam, hub + Vector3(-1.7, 1.6, 1.4), hub + Vector3(2, 2.0, -0.6), folder.path_join("have.png"))
		await _shot(cam, hub + Vector3(-1.0, 1.5, -4.4), hub + Vector3(-2, 1.1, -5.2), folder.path_join("grain.png"))

		# every plate has the settings its place in the sum asks for
		var wrong := []
		var facing_wrong := []
		for board in ["adds", "have", "mural"]:
			for i in 12:
				var id := "%s_%02d" % [board, i + 1]
				if not plates.has(id): wrong.append(id + " missing"); continue
				var plate: Node3D = plates[id]
				var face: MeshInstance3D = plate.get("face")
				var mat := face.material_override as ShaderMaterial
				if mat == null: wrong.append(id + " no shader material"); continue
				var k: int = i % 6 + 1
				var upper: bool = i >= 6
				var layers := int(mat.get_shader_parameter("layers"))
				var first := int(mat.get_shader_parameter("first_layer"))
				var bare := int(mat.get_shader_parameter("show_term"))
				var gain := float(mat.get_shader_parameter("term_gain")) if mat.get_shader_parameter("term_gain") != null else 2.0
				var alone: bool = board == "adds" or (board == "mural" and upper)
				var want_first: int = k - 1 if alone else 0
				var want_bare: int = 0 if (board == "have" and upper) else 1
				var want_gain: float = 2.0 * pow(2.0, k - 1) if ((board == "adds" and not upper) or (board == "mural" and upper)) else 2.0
				if layers != k or first != want_first or bare != want_bare or (want_bare == 1 and not is_equal_approx(gain, want_gain)):
					wrong.append("%s layers %d first %d bare %d gain %s" % [id, layers, first, bare, str(gain)])
				var out: Vector3 = face.global_transform.basis.z.normalized()
				if (board == "adds" and out.x < 0.9) or (board != "adds" and out.x > -0.9): facing_wrong.append(id)
		checks.append({"check": "36 plates stand, each with the terms, the first term and the gain its place in the sum asks for", "ok": plates.size() == 36 and wrong.is_empty(), "plates": plates.size(), "wrong": wrong})
		checks.append({"check": "both walls face into the corridor, and the mural on the back of the west wall faces the floor", "ok": facing_wrong.is_empty(), "wrong": facing_wrong})

		# a body in the corridor
		game.place_player(hub + Vector3(0, 0.3, 7.2))
		for i in 40: await physics_frame
		var through: Dictionary = await _go(body, hub + Vector3(0, 0, -7.2))
		checks.append({"check": "the walker walks the corridor end to end, onto its floor plate and off it", "ok": float(through.came_within_m) < 0.35 and float(through.furthest_from_level_m) < 0.10 and int(game.checkpoint) == floor, "walk": through})
		game.place_player(hub + Vector3(0, 0.3, 0))
		for i in 40: await physics_frame
		var stopped: Dictionary = await _go(body, hub + Vector3(-3.6, 0, 0), 240)
		checks.append({"check": "a wall of plates stops a body that walks at it", "ok": float(stopped.least_x) > hub.x - 2.0, "walk": stopped})
		game.place_player(Vector3(-3.6, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("six_steps.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[six_steps_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
