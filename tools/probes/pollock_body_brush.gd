extends SceneTree
## DOES THE PLAYER PAINT WITH AN OPEN BUCKET? (pollock_painting_in_3d with body_paints and buckets; Palle, 2026-11-12)
## The work says a drip painting "is the trace of a body moving through a random field with intention". Open buckets
## stand in a row on the floor canvas; a body takes one by walking up to it and pours that colour as it walks.
## The Void's own walker crosses the canvas without a bucket, takes one, and crosses again; the canvas image is read
## along both walks. With no buckets configured the first crossing alone is the test (the body itself is the brush).
##
##   godot --path <stage> --script res://tools/probes/pollock_body_brush.gd -- --no-bridges --void-start-floor=88
##       --out=<dir>
##
## body_brush.json: checks with what was read. arrival.png is taken BEFORE anything walks (the canvas as a visitor
## finds it), painted.png afterwards, both from the spawn point.
var game: Node3D


func _initialize() -> void:
	run.call_deferred()


func _band(image: Image, row: int) -> PackedByteArray:
	return image.get_region(Rect2i(0, clampi(row - 14, 0, image.get_height() - 28), image.get_width(), 28)).get_data()


func _changed(a: PackedByteArray, b: PackedByteArray) -> int:
	var n := 0
	for i in range(0, a.size(), 4):
		if a[i] != b[i] or a[i + 1] != b[i + 1] or a[i + 2] != b[i + 2]: n += 1
	return n


func _go(body: CharacterBody3D, target: Vector3, ticks_max: int = 900) -> float:
	var best := INF
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		best = minf(best, d)
		if d < 0.3: break
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
		if str(a.artifact) == "pollock_painting_in_3d": item = a
	var checks := []
	var result := {"floor": floor, "map": str(record.map), "checks": checks, "passed": false}
	if item != null:
		var key := str(floor) + "/" + str(item.id)
		for i in 900:
			if game.building.content.exhibits.has(key): break
			await physics_frame
		var mount: Node3D = game.building.content.exhibits.get(key)
		var work: Node3D = null
		for n in [mount] + mount.find_children("*", "Node3D", true, false):
			if n.has_method("world_to_canvas_pixel"): work = n; break
		for i in 600:
			if bool(work.get("_built")): break
			await physics_frame
		for i in 120: await physics_frame
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var painter: Node = work.get("_paint_2d")
		var image: Image = painter.canvas
		var middle: Vector3 = work.global_position
		var half_w: float = float(image.get_width()) * float(work.pixel_size) / 2.0
		var half_d: float = float(image.get_height()) * float(work.pixel_size) / 2.0
		var buckets: int = int(work.buckets)
		result["canvas_m"] = [snappedf(half_w * 2.0, .01), snappedf(half_d * 2.0, .01)]
		result["buckets"] = buckets
		for layer in root.find_children("*", "CanvasLayer", true, false):      # the game's overlays, not a work's own layers
			if layer.get_viewport() == root: layer.hide()
		game.place_player(Vector3(middle.x + half_w - 1.2, level + 0.3, middle.z + half_d - 0.4))      # aside: not in front of the lens
		for i in 30: await physics_frame
		var cam := Camera3D.new()
		root.add_child(cam)
		await _shot(cam, Vector3(0, level + 1.6, 7.8), Vector3(0, level + 0.2, middle.z + half_d * 0.2), folder.path_join("arrival.png"))
		var body: CharacterBody3D = game.body
		checks.append({"check": "the room asked for it: body_paints is on", "ok": bool(work.body_paints)})
		# 1 across the canvas with empty hands
		var z1: float = middle.z - half_d * 0.45
		var row1 := int(work.world_to_canvas_pixel(Vector3(middle.x, level, z1)).y)
		var before1 := _band(image, row1)
		game.place_player(Vector3(middle.x - half_w + 0.6, level + 0.3, z1))
		for i in 40: await physics_frame
		var reach1 := await _go(body, Vector3(middle.x + half_w - 0.6, level, z1))
		for i in 20: await physics_frame
		var bare := _changed(before1, _band(image, row1))
		if buckets == 0:
			checks.append({"check": "the body walked across the canvas", "ok": reach1 < 0.4})
			checks.append({"check": "its walk left paint along the band it walked", "ok": bare > 1500, "pixels_changed": bare})
		else:
			checks.append({"check": "with empty hands a walk across the canvas pours nothing", "ok": reach1 < 0.4 and bare < 400, "pixels_changed": bare})
			# 2 take a bucket by walking up to it
			var states: Array = work.bucket_state()
			var pick: int = mini(buckets - 1, buckets / 2 + 1)
			var home: Vector3 = states[pick].home
			game.place_player(Vector3(home.x, level + 0.3, home.z + 1.3))
			for i in 40: await physics_frame
			await _go(body, Vector3(home.x, level, home.z + 0.15), 300)
			for i in 20: await physics_frame
			states = work.bucket_state()
			var away: float = (states[pick].at as Vector3).distance_to(home)
			checks.append({"check": "walking up to an open bucket takes it", "ok": bool(states[pick].held), "bucket": pick})
			# 3 across the canvas with the bucket
			var z2: float = middle.z - half_d * 0.1
			var row2 := int(work.world_to_canvas_pixel(Vector3(middle.x, level, z2)).y)
			await _go(body, Vector3(middle.x + half_w - 0.8, level, z2))
			var before2 := _band(image, row2 - 30)      # the bucket rides beside the hip: its line runs a little off the feet
			var wide_before := image.get_region(Rect2i(0, clampi(row2 - 60, 0, image.get_height() - 120), image.get_width(), 120)).get_data()
			var reach2 := await _go(body, Vector3(middle.x - half_w + 0.8, level, z2))
			for i in 20: await physics_frame
			var poured := _changed(wide_before, image.get_region(Rect2i(0, clampi(row2 - 60, 0, image.get_height() - 120), image.get_width(), 120)).get_data())
			states = work.bucket_state()
			checks.append({"check": "the bucket travels with its bearer", "ok": (states[pick].at as Vector3).distance_to(home) > 2.0, "from_home_m": snappedf((states[pick].at as Vector3).distance_to(home), .01)})
			checks.append({"check": "carrying it, the walk pours a line across the canvas", "ok": reach2 < 0.4 and poured > 1500 and poured > 5 * maxi(bare, 60), "pixels_changed": poured})
		game.place_player(Vector3(middle.x + half_w - 1.2, level + 0.3, middle.z + half_d - 0.4))      # aside, still on this floor
		for i in 20: await physics_frame
		await _shot(cam, Vector3(0, level + 1.6, 7.8), Vector3(0, level + 0.2, middle.z + half_d * 0.2), folder.path_join("painted.png"))
		await _shot(cam, Vector3(middle.x - half_w - 1.5, level + 3.6, middle.z + half_d + 0.5), Vector3(middle.x, level, middle.z), folder.path_join("canvas.png"))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "pollock_painting_in_3d stands on this floor", "ok": false})
	var file := FileAccess.open(folder.path_join("body_brush.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[pollock_body_brush] ", "PASSED" if result.passed else "FAILED")
	quit()
