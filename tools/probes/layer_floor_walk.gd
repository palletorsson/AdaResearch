extends SceneTree
## THE LAYER AT THE YELLOW LINE, AS A FLOOR (threshold_layer_floor on floor Noise_Voxel; the Void, 2026-11-12)
## Read in the running tower, with its own walker:
##   the floor hears the bench, and its cells are exactly the voxel block's cells on the held layer;
##   at each of the bench's five lines they stay equal, and a higher line only takes cells away;
##   a body crosses the shaft on a way two cells wide that the line admits (the first line that has one);
##   a body set over a gap falls;
##   the plate at the rim moves the bench's line; what a frame costs.
##
##   godot --path <stage> --script res://tools/probes/layer_floor_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## layer_floor.json: checks with what was read. arrival.png, rim.png, above.png, block.png.
var game: Node3D
var level := 0.0
var work: Node3D
var block: Node3D


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	cam.current = true
	for i in 4: await process_frame
	root.get_viewport().get_texture().get_image().save_png(path)
	cam.current = false


func _find(mount: Node3D, method: String) -> Node3D:
	for n in [mount] + mount.find_children("*", "Node3D", true, false):
		if n.has_method(method): return n
	return null


## The block's cells on the floor's layer, as a dictionary of (x, z).
func _block_layer() -> Dictionary:
	var out := {}
	var cells: Dictionary = block.get("_occupied_cells")
	for c in cells:
		if (c as Vector3i).y == int(work.layer): out[Vector2i(c.x, c.z)] = true
	return out


func _same() -> Dictionary:
	var mine := {}
	for c in work.cells(): mine[c] = true
	var theirs := _block_layer()
	var differ := 0
	for c in mine: if not theirs.has(c): differ += 1
	for c in theirs: if not mine.has(c): differ += 1
	return {"cells": mine.size(), "differ": differ}


## A way from the west rim to the east rim over cells that are there, two cells wide. Nodes are 2 x 2 blocks.
func _way() -> Array:
	var n: int = int(work.grid) - 1
	var ok := func(x: int, z: int) -> bool:
		return x >= 0 and z >= 0 and x < n and z < n and work.is_there(x, z) and work.is_there(x + 1, z) and work.is_there(x, z + 1) and work.is_there(x + 1, z + 1)
	var came := {}
	var queue := []
	for z in n:
		if ok.call(0, z): came[Vector2i(0, z)] = Vector2i(-1, -1); queue.append(Vector2i(0, z))
	var end := Vector2i(-1, -1)
	while not queue.is_empty():
		var at: Vector2i = queue.pop_front()
		if at.x == n - 1: end = at; break
		for step in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(-1, 0)]:
			var to: Vector2i = at + step
			if came.has(to) or not ok.call(to.x, to.y): continue
			came[to] = at
			queue.append(to)
	var path := []
	while end.x >= 0:
		path.push_front(end)
		end = came[end]
	return path


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
	var rows := {}
	for a in record.artifacts:
		if str(a.artifact) == "threshold_layer_floor": rows["floor"] = a
		if str(a.artifact) == "voxelnoise": rows["block"] = a
	checks.append({"check": "the layer floor and the voxel block are on this floor", "ok": rows.size() == 2})
	if rows.size() == 2:
		var mounts := {}
		for k in rows:
			var key := str(floor) + "/" + str(rows[k].id)
			for i in 900:
				if game.building.content.exhibits.has(key): break
				await physics_frame
			mounts[k] = game.building.content.exhibits.get(key)
		work = _find(mounts.floor, "cell_at")
		block = _find(mounts.block, "apply_perlin_cell_selection")
		for i in 900:
			if work.following(): break
			await physics_frame
		for i in 300: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		var bench: Node = work.bench()
		for layer in root.find_children("*", "CanvasLayer", true, false):      # the game's overlays, not a work's own layers
			if layer.get_viewport() == root: layer.hide()
		game.place_player(Vector3(-3.6, level + 0.3, 8.6))
		for i in 30: await physics_frame
		var cam := Camera3D.new()
		cam.fov = 80
		root.add_child(cam)
		var hub: Vector3 = work.global_position
		await _shot(cam, Vector3(0, level + 1.6, 7.8), Vector3(2.5, level + 1.2, 0), folder.path_join("arrival.png"))
		await _shot(cam, hub + Vector3(-4.7, 1.6, 0.9), hub + Vector3(0.6, -0.4, -0.2), folder.path_join("rim.png"))
		await _shot(cam, hub + Vector3(-2.6, 4.9, 5.2), hub + Vector3(0.2, 0, -0.3), folder.path_join("above.png"))
		await _shot(cam, hub + Vector3(4.6, 1.7, 1.6), Vector3(0, level + 2.2, -2.45), folder.path_join("block.png"))

		checks.append({"check": "the floor hears the bench", "ok": work.following() and bench != null, "layer": int(work.layer), "line": snappedf(float(work.line), .01)})
		var first: Dictionary = _same()
		checks.append({"check": "its cells are exactly the block's cells on the held layer", "ok": int(first.differ) == 0 and int(first.cells) > 0, "cells": first.cells, "differ": first.differ})

		# the bench's five lines
		var seen := []
		var equal := true
		for step in 5:
			bench.next_threshold()
			for i in 60: await physics_frame
			var now: Dictionary = _same()
			if int(now.differ) != 0: equal = false
			seen.append([snappedf(float(bench.threshold), .01), int(now.cells)])
		seen.sort_custom(func(a, b): return a[0] < b[0])
		var falling := true
		for i in range(1, seen.size()):
			if int(seen[i][1]) > int(seen[i - 1][1]): falling = false
		checks.append({"check": "at each of the bench's five lines the floor is the block's layer, and a higher line only takes cells away", "ok": equal and falling, "line_and_cells": seen})

		# a way across, at the first line that has one
		var path: Array = _way()
		var tried := 0
		while path.is_empty() and tried < 5:
			bench.next_threshold()
			for i in 60: await physics_frame
			path = _way()
			tried += 1
		var crossed := false
		var lowest := INF
		if not path.is_empty():
			var half := Vector3(float(work.cell) * 0.5, 0, float(work.cell) * 0.5)
			var start: Vector3 = work.cell_centre(path[0].x, path[0].y) + half
			game.place_player(start + Vector3(0, 0.3, 0))
			for i in 40: await physics_frame
			for p in path:
				var goal: Vector3 = work.cell_centre(p.x, p.y) + half
				for i in 200:
					if Vector2(goal.x - body.global_position.x, goal.z - body.global_position.z).length() < 0.07: break
					body.look_at(Vector3(goal.x, body.global_position.y, goal.z), Vector3.UP)
					body.drive = Vector2(0, -0.34)
					lowest = minf(lowest, body.global_position.y - level)
					await physics_frame
			body.drive = Vector2.ZERO
			for i in 20: await physics_frame
			var end: Vector3 = work.cell_centre(path[-1].x, path[-1].y) + half
			crossed = Vector2(end.x - body.global_position.x, end.z - body.global_position.z).length() < 0.2 and lowest > -0.12
		checks.append({"check": "a body crosses the shaft on a way two cells wide that the line admits", "ok": crossed and int(game.checkpoint) == floor,
			"line": snappedf(float(work.line), .01), "blocks_on_the_way": path.size(), "lowest_feet_m": snappedf(lowest, .01) if lowest < INF else null})

		# a gap drops a body
		var gap := Vector2i(-1, -1)
		for z in range(1, int(work.grid) - 1):
			for x in range(1, int(work.grid) - 1):
				var empty := true
				for dz in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						if work.is_there(x + dx, z + dz): empty = false
				if empty and gap.x < 0: gap = Vector2i(x, z)
		var fell := false
		if gap.x >= 0:
			game.place_player(work.cell_centre(gap.x, gap.y) + Vector3(0, 0.4, 0))
			for i in 45: await physics_frame
			fell = body.global_position.y < level - 1.0
			game.place_player(Vector3(-3.6, level + 0.3, 8.6))
			for i in 40: await physics_frame
		checks.append({"check": "a body set over a gap three cells wide falls", "ok": fell and int(game.checkpoint) == floor, "gap_at": [gap.x, gap.y]})

		# the plate at the rim presses the bench's button
		var before_i: int = int(bench.get("_threshold_i"))
		game.place_player(work.to_global(Vector3(-float(work.grid) * float(work.cell) * 0.5 - 0.75, 0.3, -0.9)))
		for i in 60: await physics_frame
		var after_i: int = int(bench.get("_threshold_i"))
		var agree: bool = is_equal_approx(float(work.line), float(bench.threshold))
		checks.append({"check": "the plate at the rim moves the bench's line, and the floor follows", "ok": after_i != before_i and agree, "bench_line": snappedf(float(bench.threshold), .01), "floor_line": snappedf(float(work.line), .01)})
		game.place_player(Vector3(-3.6, level + 0.3, 8.6))
		for i in 80: await physics_frame
		while absf(float(bench.threshold)) > 0.001:          # leave the line where the room had it
			bench.next_threshold()
			for i in 50: await physics_frame
		work.frame_ms()
		for i in 240: await process_frame
		var ms: float = work.frame_ms()
		checks.append({"check": "a standing floor costs next to nothing a frame", "ok": ms < 0.05, "ms_a_frame": snappedf(ms, .001)})
		await _shot(cam, hub + Vector3(-2.6, 4.9, 5.2), hub + Vector3(0.2, 0, -0.3), folder.path_join("above.png"))
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("layer_floor.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[layer_floor_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
