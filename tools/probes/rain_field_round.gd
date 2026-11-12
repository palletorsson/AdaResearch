extends SceneTree
## STAY DRY (rain_tile_field on floor Random_Game; Palle, 2026-11-12: "continue with the next real game with a lot
## more tiles")
## Two rounds with the Void's own walker. In the first it stands still on one tile. In the second it steps to a
## neighbouring tile whenever a drop is 0.7 s from landing where it stands. Read: the hits it takes each way, and
## after a round the tiles hit 0, 1, 2, 3 and more times beside what Poisson's law gives for as many drops.
##
##   godot --path <stage> --script res://tools/probes/rain_field_round.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## rain.json: checks with what was read. falling.png mid-round, after.png the hit map, arrival.png from the spawn.
var game: Node3D
var work: Node3D
var level := 0.0


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	cam.current = true
	for i in 3: await process_frame
	root.get_viewport().get_texture().get_image().save_png(path)
	cam.current = false


## One round. With `dodge` the body leaves a tile a drop is about to land on. Returns the hits it took.
func _round(body: CharacterBody3D, dodge: bool, cam: Camera3D, shot_path: String) -> int:
	var middle: Vector3 = work.to_global(Vector3(0.25, 0, 0.25))
	game.place_player(Vector3(middle.x, level + 0.3, middle.z))
	for i in 30: await physics_frame
	var nx: int = roundi(float(work.cells.x) / float(work.tile))
	var target := Vector3.INF
	var ticks := 0
	while work.running() and ticks < 4200:
		ticks += 1
		if shot_path != "" and ticks == 1500:
			await _shot(cam, work.global_position + Vector3(-6.2, 4.6, 5.2), work.global_position + Vector3(0.4, 0.3, -0.4), shot_path)
		var here: int = work.tile_at(work.to_local(body.global_position))
		if dodge and here >= 0:
			var due: float = work.coming(here)
			if due >= 0.0 and due < 0.7 and target == Vector3.INF:
				for step in [1, -1, nx, -nx, nx + 1, nx - 1, -nx + 1, -nx - 1]:
					var other: int = here + step
					if other < 0 or other >= work.tiles() or absi(other % nx - here % nx) > 1: continue
					if work.coming(other) < 0.0: target = work.to_global(work.tile_centre(other)); break
		if target != Vector3.INF:
			if Vector2(target.x - body.global_position.x, target.z - body.global_position.z).length() < 0.1:
				target = Vector3.INF
				body.drive = Vector2.ZERO
			else:
				body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
				body.drive = Vector2(0, -0.6)
		await physics_frame
	body.drive = Vector2.ZERO
	return int(work.score().wet)


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
		if str(a.artifact) == "rain_tile_field": item = a
	checks.append({"check": "the rain field lies on this floor", "ok": item != null})
	if item != null:
		var key := str(floor) + "/" + str(item.id)
		for i in 900:
			if game.building.content.exhibits.has(key): break
			await physics_frame
		var mount: Node3D = game.building.content.exhibits.get(key)
		for n in [mount] + mount.find_children("*", "Node3D", true, false):
			if n.has_method("coming"): work = n; break
		for i in 240: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		var battery: Node = get_first_node_in_group("void_health")
		for layer in root.find_children("*", "CanvasLayer", true, false):      # the game's overlays, not a work's own layers
			if layer.get_viewport() == root: layer.hide()
		game.place_player(Vector3(-3.6, level + 0.3, 8.6))
		for i in 30: await physics_frame
		var cam := Camera3D.new()
		root.add_child(cam)
		await _shot(cam, Vector3(0, level + 1.6, 7.8), Vector3(work.global_position.x * 0.6, level + 0.5, work.global_position.z), folder.path_join("arrival.png"))
		checks.append({"check": "many tiles", "ok": int(work.tiles()) >= 150, "tiles": int(work.tiles())})
		battery.set_charge(100.0)
		var still: int = await _round(body, false, cam, "")
		var first: Dictionary = work.tally()
		game.place_player(Vector3(-3.6, level + 0.3, 8.6))
		for i in 170: await physics_frame
		battery.set_charge(100.0)
		var dodged: int = await _round(body, true, cam, folder.path_join("falling.png"))
		var second: Dictionary = work.tally()
		game.place_player(Vector3(-3.6, level + 0.3, 8.6))
		for i in 20: await physics_frame
		await _shot(cam, work.global_position + Vector3(-6.2, 4.6, 5.2), work.global_position + Vector3(0.4, 0.3, -0.4), folder.path_join("after.png"))
		checks.append({"check": "a round runs its length and rains", "ok": int(first.drops) > 150 and int(second.drops) > 150, "drops": [first.drops, second.drops]})
		checks.append({"check": "seeing a drop come lets a body stay drier than standing still", "ok": dodged <= still and dodged <= 2, "hits_standing_still": still, "hits_stepping_aside": dodged})
		var drawn: Array = second.drawn
		var expected: Array = second.expected
		checks.append({"check": "even rain is not even ground: some tiles untouched, some hit three times and more, as Poisson gives",
			"ok": int(drawn[0]) > 0 and int(drawn[3]) > 0 and absf(float(drawn[0]) - float(expected[0])) < 22.0, "drawn": drawn, "poisson": expected, "mean_hits_a_tile": second.mean})
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("rain.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[rain_field_round] ", "PASSED" if result.passed else "FAILED")
	quit()
