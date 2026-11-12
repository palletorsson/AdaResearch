extends SceneTree
## THE ATRIUM'S MOUTH FACES THE ARRIVAL (floors Noise_Cellular and Noise_Box; the Void, 2026-11-12)
## A cellular atrium (cells or boxes) is entered through one rounded mouth, 3.2 m wide, on its own south side, and its own code
## puts a visitor 6.4 m south of its middle. In the tower it stood turned half round: the mouth opened north into a
## 1.2 m slot against the womb, and the arrival met a closed wall 1.5 m away. Read in the running tower, with its
## own walker: from the arrival point a body walks straight north into the clearing in the middle of the atrium.
##
##   godot --path <stage> --script res://tools/probes/atrium_entrance_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## atrium.json: checks with what was read. arrival.png from the spawn, inside.png from the clearing looking back.
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
	var item = null
	for a in record.artifacts:
		if str(a.artifact) in ["cellular_atrium_space", "box_atrium_space"]: item = a
	checks.append({"check": "an atrium of the cellular spaces is on this floor", "ok": item != null, "artifact": str(item.artifact) if item != null else ""})
	if item != null:
		var key := str(floor) + "/" + str(item.id)
		for i in 1200:
			if game.building.content.exhibits.has(key): break
			await physics_frame
		for i in 480: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		for layer in root.find_children("*", "CanvasLayer", true, false):      # the game's overlays, not a work's own layers
			if layer.get_viewport() == root: layer.hide()
		var middle := Vector3(float(item.position[0]), level, float(item.position[1]))
		game.place_player(Vector3(-3.6, level + 0.3, 8.6))
		for i in 30: await physics_frame
		var cam := Camera3D.new()
		cam.fov = 80
		root.add_child(cam)
		await _shot(cam, Vector3(0, level + 1.6, 7.8), middle + Vector3(0, 1.5, 0), folder.path_join("arrival.png"))
		await _shot(cam, middle + Vector3(0, 1.9, -0.6), Vector3(0, level + 1.5, 7.8), folder.path_join("inside.png"))
		checks.append({"check": "the atrium's mouth is turned to the arrival", "ok": is_equal_approx(fposmod(float(item.facing), 360.0), 0.0), "facing": item.facing})
		game.place_player(Vector3(0, level + 0.3, 7.8))
		for i in 40: await physics_frame
		var best := INF
		var high := 0.0
		var stuck := 0
		var last := body.global_position
		for i in 700:
			var d := Vector2(body.global_position.x - middle.x, body.global_position.z - middle.z).length()
			best = minf(best, d)
			high = maxf(high, body.global_position.y - level)
			if d < 0.4 or (d < 2.0 and i > 420): break
			body.look_at(Vector3(middle.x, body.global_position.y, middle.z), Vector3.UP)
			body.drive = Vector2(0, -1)
			await physics_frame
			if i % 20 == 19:
				stuck = stuck + 1 if body.global_position.distance_to(last) < 0.15 else 0
				last = body.global_position
				if stuck >= 2: body.jump_queued = true; stuck = 0
		body.drive = Vector2.ZERO
		for i in 20: await physics_frame
		checks.append({"check": "from the arrival a body walks straight north through the mouth into the clearing in the middle", "ok": best < 2.2 and int(game.checkpoint) == floor,
			"came_within_m": snappedf(best, .01), "highest_feet_m": snappedf(high, .01)})
		game.place_player(Vector3(-3.6, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("atrium.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[atrium_entrance_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
