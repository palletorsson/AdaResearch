extends SceneTree
## DOES THE RANGE ASSEMBLE WHILE A BODY STANDS ON THE PLAIN? (random_walk_128 in the Void; Palle, 2026-11-12)
## The work wants a visitor to "stand on a plain and watch a mountain range assemble itself". Read as code it walked
## its steps in the seconds after its floor was built and then stopped, so a visitor found a finished mound.
## The Void's own walker is driven from the spawn point through the doorway and stopped on the plain, a step inside.
##
##   godot --path <stage> --script res://tools/probes/walk_room_enter.gd -- --no-bridges --void-start-floor=84
##       --out=<dir>
##
## walk_room.json: checks with what was read; assembling.png and assembled.png are the walker's own view.
## Measured on the way here (2026-11-12): with the body ON the lattice, a range drawn 2x taller boxed the walker in
## between columns and one drawn 4x taller grew up round its legs. A growing lattice is not ground for a body.
var game: Node3D


func _initialize() -> void:
	run.call_deferred()


func _go(body: CharacterBody3D, target: Vector3, ticks_max: int) -> float:
	var best := INF
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		best = minf(best, d)
		if d < 0.35: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -1)
		await physics_frame
	body.drive = Vector2.ZERO
	return best


func _shot(path: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(path)


## The top of the tallest column, in metres over the floor.
func _range_top(work: Node3D) -> float:
	var most := 0.0
	for row in work.grid:
		for v in row: most = maxf(most, float(v))
	if most <= 0.0: return 0.0
	return (most / 2.0 * float(work.height_scale) - float(work.sink) + float(work.CUBE_SIZE) / 2.0) * work.global_transform.basis.get_scale().y


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
		if str(a.artifact) == "random_walk_128": item = a
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
			if n.has_method("restart_walk"): work = n; break
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		var half: float = float(work.GRID_AREA_SIZE) / 2.0 * work.global_transform.basis.get_scale().x
		result["lattice_m"] = snappedf(half * 2.0, .01)
		# 1 the walk as the floor was built: it runs out with nobody in the room
		var waited := 0
		while waited < 3600 and (bool(work.is_running) or int(work.current_step) < int(work.total_steps)):
			await physics_frame
			waited += 1
		checks.append({"check": "left alone, the walk runs out and stops", "ok": not bool(work.is_running) and int(work.current_step) >= int(work.total_steps),
			"steps": int(work.current_step), "seconds": snappedf(waited / 60.0, .1)})
		# 2 a body comes from the spawn point through the doorway and stops on the plain, short of the lattice
		var middle: Vector3 = work.global_position
		var stand := middle + Vector3(0, 0, half + 1.0)
		game.place_player(Vector3(0, level + 0.3, 7.8))
		for i in 60: await physics_frame
		var reached := await _go(body, stand, 900)
		for i in 30: await physics_frame
		checks.append({"check": "the doorway lets a body onto the plain", "ok": reached < 0.4, "closest": snappedf(reached, .01)})
		checks.append({"check": "the walk begins again as the body comes in", "ok": bool(work.is_running) and int(work.current_step) < int(work.total_steps) / 2, "step": int(work.current_step)})
		body.look_at(Vector3(middle.x, body.global_position.y, middle.z), Vector3.UP)
		for i in 600: await physics_frame
		await _shot(folder.path_join("assembling.png"))
		var stood := 0
		while stood < 3600 and bool(work.is_running):
			await physics_frame
			stood += 1
		for i in 60: await physics_frame
		var feet: float = body.global_position.y - level
		var moved := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(stand.x, stand.z))
		var top := _range_top(work)
		checks.append({"check": "the body stands on the plain the whole time: nothing grows under it", "ok": feet < 0.08 and moved < 0.5, "feet_m": snappedf(feet, .01), "moved_m": snappedf(moved, .01)})
		checks.append({"check": "a range has assembled in front of it", "ok": top > 0.8, "tallest_m": snappedf(top, .01)})
		await _shot(folder.path_join("assembled.png"))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "random_walk_128 stands on this floor", "ok": false})
	var file := FileAccess.open(folder.path_join("walk_room.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[walk_room_enter] ", "PASSED" if result.passed else "FAILED")
	quit()
