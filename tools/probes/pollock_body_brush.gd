extends SceneTree
## IS THE VISITOR'S BODY THE BRUSH? (pollock_painting_in_3d with body_paints; Palle, 2026-11-12)
## The work says a drip painting "is the trace of a body moving through a random field with intention". Where a room
## asks, a body walking on the floor canvas leaves the black line. The Void's own walker is driven straight across
## the canvas; the canvas image is read before and after along the band it walked.
##
##   godot --path <stage> --script res://tools/probes/pollock_body_brush.gd -- --no-bridges --void-start-floor=88
##       --out=<dir>
##
## body_brush.json: checks with what was read; from_above.png and from_spawn.png show the canvas afterwards.
var game: Node3D


func _initialize() -> void:
	run.call_deferred()


## Dark pixels (the body's colour) in a horizontal band of the canvas, sampled every third pixel; and their x extent.
func _dark(image: Image, row: int, half: int) -> Dictionary:
	var count := 0
	var lo := 99999
	var hi := -1
	for y in range(maxi(0, row - half), mini(image.get_height(), row + half), 3):
		for x in range(0, image.get_width(), 3):
			if image.get_pixel(x, y).get_luminance() < 0.12:
				count += 1
				lo = mini(lo, x); hi = maxi(hi, x)
	return {"count": count, "span_px": maxi(0, hi - lo)}


func _shot(cam: Camera3D, at: Vector3, target: Vector3, up: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, up)
	cam.current = true
	for i in 4: await process_frame
	root.get_viewport().get_texture().get_image().save_png(path)


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
		result["canvas_m"] = [snappedf(half_w * 2.0, .01), snappedf(float(image.get_height()) * float(work.pixel_size), .01)]
		checks.append({"check": "the room asked for it: body_paints is on", "ok": bool(work.body_paints)})
		var row := int(work.world_to_canvas_pixel(Vector3(middle.x, level, middle.z)).y)
		var before := _dark(image, row, 70)
		var body: CharacterBody3D = game.body
		game.place_player(Vector3(middle.x - half_w - 0.7, level + 0.3, middle.z))
		for i in 60: await physics_frame
		var target := Vector3(middle.x + half_w + 0.6, level, middle.z)
		var best := INF
		for i in 900:
			var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
			best = minf(best, d)
			if d < 0.35: break
			body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
			body.drive = Vector2(0, -1)
			await physics_frame
		body.drive = Vector2.ZERO
		for i in 30: await physics_frame
		var after := _dark(image, row, 70)
		checks.append({"check": "the body walked across the canvas", "ok": best < 0.4, "closest": snappedf(best, .01)})
		checks.append({"check": "its walk left paint along the band it walked", "ok": int(after.count) - int(before.count) > 150, "dark_before": before.count, "dark_after": after.count})
		checks.append({"check": "the line runs the width of the canvas", "ok": int(after.span_px) > int(image.get_width() * 0.8), "span_px": after.span_px, "canvas_px": image.get_width()})
		game.place_player(Vector3(middle.x + half_w + 3.0, level + 0.3, middle.z - 6.0))      # out of the picture
		for i in 20: await physics_frame
		var cam := Camera3D.new()
		root.add_child(cam)
		await _shot(cam, Vector3(middle.x, level + 5.2, middle.z + 0.01), Vector3(middle.x, level, middle.z), Vector3(0, 0, -1), folder.path_join("from_above.png"))
		await _shot(cam, Vector3(0, level + 1.6, 7.8), Vector3(0, level, 4.2), Vector3.UP, folder.path_join("from_spawn.png"))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "pollock_painting_in_3d stands on this floor", "ok": false})
	var file := FileAccess.open(folder.path_join("body_brush.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[pollock_body_brush] ", "PASSED" if result.passed else "FAILED")
	quit()
