extends SceneTree
## THE FIELD OF COVERED TILES (finding_out_field on floor Random_Game; Palle, 2026-11-12: "continue with the next
## real game with a lot more tiles")
## The Void's own walker takes the path that was written first, from the south end to the north. Read: is it
## uncovered green all the way with no shock; does the work's clock record the crossing; does one step onto a live
## cell take charge and show red; does COVER AGAIN hide everything and keep the assignment.
##
##   godot --path <stage> --script res://tools/probes/finding_out_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## finding_out.json: checks with what was read. covered.png before a step, walked.png after the crossing,
## arrival.png from the spawn point.
var game: Node3D
var work: Node3D
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


## At a third of the drive the walker stops where it is told (at full drive it coasts 0.6 m).
func _walk(body: CharacterBody3D, target: Vector3, ticks_max: int = 300) -> void:
	for i in ticks_max:
		if Vector2(target.x - body.global_position.x, target.z - body.global_position.z).length() < 0.08: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -0.34)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 6: await physics_frame


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
		if str(a.artifact) == "finding_out_field": item = a
	checks.append({"check": "the field of covered tiles lies on this floor", "ok": item != null})
	if item != null:
		var key := str(floor) + "/" + str(item.id)
		for i in 900:
			if game.building.content.exhibits.has(key): break
			await physics_frame
		var mount: Node3D = game.building.content.exhibits.get(key)
		for n in [mount] + mount.find_children("*", "Node3D", true, false):
			if n.has_method("safe_path"): work = n; break
		for i in 240: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		var battery: Node = get_first_node_in_group("void_health")
		var centre: Vector3 = work.global_position
		var half: float = float(work.cells.y) / 2.0
		for layer in root.find_children("*", "CanvasLayer", true, false):      # the game's overlays, not a work's own layers
			if layer.get_viewport() == root: layer.hide()
		game.place_player(Vector3(3.6, level + 0.3, 8.6))      # aside, not in front of the lens
		for i in 30: await physics_frame
		var cam := Camera3D.new()
		root.add_child(cam)
		var from_above := Vector3(centre.x + 5.6, level + 5.0, centre.z + half + 1.2)
		await _shot(cam, Vector3(0, level + 1.6, 7.8), Vector3(centre.x * 0.6, level + 0.5, centre.z), folder.path_join("arrival.png"))
		await _shot(cam, from_above, Vector3(centre.x - 0.5, level, centre.z - 0.3), folder.path_join("covered.png"))
		var first: Dictionary = work.score()
		checks.append({"check": "many tiles, and most cells live", "ok": int(first.tiles) >= 150 and int(first.live) > int(first.cells) / 3, "tiles": int(first.tiles), "cells": int(first.cells), "live": int(first.live)})
		# 1 the path that was written first
		battery.set_charge(100.0)
		var path: Array = work.safe_path()
		var start: Vector3 = work.to_global(work.cell_centre(path[0]) + Vector3(0, 0, 1.2))
		game.place_player(Vector3(start.x, level + 0.3, start.z))
		for i in 40: await physics_frame
		for c: Vector2i in path:
			await _walk(body, work.to_global(work.cell_centre(c)))
		await _walk(body, work.to_global(work.cell_centre(path[path.size() - 1]) + Vector3(0, 0, -1.2)))
		for i in 10: await physics_frame
		var after: Dictionary = work.score()
		var all_shown: bool = path.all(func(c: Vector2i) -> bool: return work.is_shown(c) and not work.is_live(c))
		checks.append({"check": "the written path crosses the field without a shock", "ok": all_shown and int(after.shocks) == 0 and battery.get_charge() > 95.0,
			"cells_on_the_path": path.size(), "shocks": int(after.shocks), "charge": snappedf(battery.get_charge(), .1)})
		checks.append({"check": "the work's clock recorded the crossing", "ok": int(after.crossed) >= 1 and float(after.last) > 0.0, "clock_s": snappedf(after.last, .1)})
		game.place_player(Vector3(3.6, level + 0.3, 8.6))
		for i in 20: await physics_frame
		await _shot(cam, from_above, Vector3(centre.x - 0.5, level, centre.z - 0.3), folder.path_join("walked.png"))
		# 2 one step onto a live cell
		var live := Vector2i(-1, -1)
		var beside := Vector2i(-1, -1)
		for c: Vector2i in path:
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0)]:
				var other: Vector2i = c + d
				if other.x >= 0 and other.x < int(work.cells.x) and work.is_live(other) and live.x < 0: live = other; beside = c
		var charge_before: float = battery.get_charge()
		var took := false
		if live.x >= 0:
			var stand: Vector3 = work.to_global(work.cell_centre(beside))
			game.place_player(Vector3(stand.x, level + 0.3, stand.z))
			for i in 30: await physics_frame
			charge_before = battery.get_charge()
			await _walk(body, work.to_global(work.cell_centre(live)))
			for i in 10: await physics_frame
			took = battery.get_charge() <= charge_before - 15.0 and work.is_shown(live)
		checks.append({"check": "one step onto a live cell takes charge and shows it red", "ok": took, "charge_before": snappedf(charge_before, .1), "charge_after": snappedf(battery.get_charge(), .1)})
		# 3 cover again: the same assignment, hidden
		var known: Array = path.map(func(c: Vector2i) -> bool: return work.is_live(c))
		work.cover()
		var covered: Dictionary = work.score()
		var same: bool = known == path.map(func(c: Vector2i) -> bool: return work.is_live(c)) and (live.x < 0 or work.is_live(live))
		checks.append({"check": "COVER AGAIN hides every cell and keeps the assignment", "ok": int(covered.uncovered) == 0 and same, "uncovered": int(covered.uncovered)})
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("finding_out.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[finding_out_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
