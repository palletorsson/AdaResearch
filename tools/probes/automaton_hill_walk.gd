extends SceneTree
## A HILL LAID BY A CELLULAR AUTOMATON (the kit layer `automata` on floor CA_AgentsCircuits; Palle, 2026-11-12:
## "can we build a playground with cellular automata?")
## The ground plan is a seeded scatter of two-metre cells, smoothed; each storey is the storey below after one step
## of an erosion rule; a cell with a higher neighbour across an edge is the kit's wedge ramp, any other a flat tile.
## Read in the running tower, with its own walker:
##   the built hill obeys its storey rule (a cell stands at level n+1 only if every neighbour stands at level n);
##   every storey is smaller than the one below, and the hill has the storeys it was asked for;
##   it is made of the kit's parts only;
##   a body walks straight up every way the plan names, from the slab to the top, without a jump, and down again;
##   the top, over the shaft, carries a body.
##
##   godot --path <stage> --script res://tools/probes/automaton_hill_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## hill.json: checks with what was read. arrival.png, hill.png from the south-west, top.png from the top.
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


func _go(body: CharacterBody3D, target: Vector3, ticks_max: int = 700) -> float:
	var best := INF
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		best = minf(best, d)
		if d < 0.2: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -0.7)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 25: await physics_frame
	return best


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
		if str(a.artifact) == "playground_spec_hall" and a.config.has("place_spec") and a.config.place_spec.has("automata"): item = a
	checks.append({"check": "the floor holds a playground hall whose place specification has an automaton", "ok": item != null})
	if item != null:
		var key := str(floor) + "/" + str(item.id)
		for i in 1200:
			if game.building.content.exhibits.has(key): break
			await physics_frame
		var mount: Node3D = game.building.content.exhibits.get(key)
		var hall: Node3D = null
		for i in 900:
			for n in [mount] + mount.find_children("*", "Node3D", true, false):
				if n.get("recipe") is Dictionary and (n.recipe as Dictionary).has("automata"): hall = n; break
			if hall != null: break
			await physics_frame
		for i in 300: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		for layer in root.find_children("*", "CanvasLayer", true, false):      # the game's overlays, not a work's own layers
			if layer.get_viewport() == root: layer.hide()
		game.place_player(Vector3(-3.6, level + 0.3, 8.6))
		for i in 30: await physics_frame
		var cam := Camera3D.new()
		cam.fov = 80
		root.add_child(cam)
		var origin := Vector3(float(item.position[0]), level, float(item.position[1]))
		var hill: Dictionary = hall.recipe.automata[0]
		var middle := origin + Vector3(float(hill.at[0]), 0, float(hill.at[2]))
		await _shot(cam, Vector3(0, level + 1.6, 7.8), middle + Vector3(0, 1.0, 0), folder.path_join("arrival.png"))
		await _shot(cam, middle + Vector3(-8.5, 4.6, 8.0), middle + Vector3(0, 0.6, 0), folder.path_join("hill.png"))
		await _shot(cam, middle + Vector3(9.0, 4.6, -7.4), middle + Vector3(0, 0.6, 0), folder.path_join("hill_ne.png"))

		# 1 the storey rule, read off the built hill
		var at := {}
		for row in hill.levels: at[Vector2i(int(row[0]), int(row[1]))] = int(row[2])
		var around: Array = [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]
		if str(hill.rule) == "neumann": around = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
		var broken := 0
		var could := 0
		for c: Vector2i in at:
			var lowest := 99
			for d in around: lowest = mini(lowest, int(at.get(c + d, 0)))
			if int(at[c]) > lowest + 1: broken += 1                              # stands higher than its neighbours allow
			if int(at[c]) < mini(lowest + 1, int(hill.top)): could += 1          # could stand higher and does not
		checks.append({"check": "the built hill obeys its rule: a cell stands one storey up exactly when every neighbour stands below", "ok": broken == 0 and could == 0,
			"cells": at.size(), "too_high": broken, "too_low": could, "rule": hill.rule})
		var shrinking := true
		for i in range(1, hill.storeys.size()):
			if int(hill.storeys[i]) >= int(hill.storeys[i - 1]): shrinking = false
		checks.append({"check": "every storey is smaller than the one below, and the hill has three", "ok": shrinking and int(hill.top) == 3, "cells_in_each_storey": hill.storeys})
		var kinds := {}
		for part in hall.recipe.parts:
			var source := str(part.get("source", ""))
			kinds[source] = int(kinds.get(source, 0)) + 1
		var allowed := ["workshop_point", "workshop_rod", "workshop_rod_short", "workshop_quad", "workshop_wedge"]
		checks.append({"check": "it is made of the kit's parts only", "ok": kinds.keys().all(func(k): return k in allowed) and int(kinds.get("workshop_wedge", 0)) > 0, "parts": kinds})

		# 2 every way up, and down again
		var rows := []
		var climbed := 0
		var summit := Vector3.ZERO
		for way in hill.ways:
			var foot := origin + Vector3(float(way.foot[0]), float(way.foot[1]), float(way.foot[2]))
			var top := origin + Vector3(float(way.top[0]), float(way.top[1]), float(way.top[2]))
			game.place_player(foot + Vector3(0, 0.3, 0))
			for i in 45: await physics_frame
			var reach := await _go(body, top)
			var feet: float = body.global_position.y - level
			var up: bool = reach < 0.4 and absf(feet - float(way.top[1])) < 0.2
			if up: summit = body.global_position
			var back := await _go(body, foot)
			var feet_down: float = body.global_position.y - level
			var down: bool = back < 0.4 and absf(feet_down) < 0.2
			rows.append({"climbs": way.climbs, "top_feet_m": snappedf(feet, .01), "foot_feet_m": snappedf(feet_down, .01), "ok": up and down})
			if up and down: climbed += 1
		checks.append({"check": "a body walks straight up every way the plan names, from the slab to the top, and down again", "ok": hill.ways.size() >= 2 and climbed == hill.ways.size() and int(game.checkpoint) == floor,
			"ways": hill.ways.size(), "walked": climbed, "rows": rows})
		if summit != Vector3.ZERO:
			game.place_player(summit + Vector3(0, 0.2, 0))
			for i in 90: await physics_frame
			var held: float = body.global_position.y - level
			checks.append({"check": "the top carries a body", "ok": absf(held - float(int(hill.top) - 1)) < 0.2, "feet_m": snappedf(held, .01)})
			var eye := body.global_position + Vector3(0, 1.6, 0)
			game.place_player(Vector3(-3.6, level + 0.3, 8.6))
			for i in 20: await physics_frame
			await _shot(cam, eye, Vector3(-6, level + 0.8, 3), folder.path_join("top.png"))
		game.place_player(Vector3(-3.6, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("hill.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[automaton_hill_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
