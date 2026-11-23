extends SceneTree
## THE FALL RULE (commons/void/game.gd, Palle 2026-11-23: "If we go to the edge of the floor and start to fall and fall
## more than one floor, bring us back to the closest and deal some damage to the player.").
## With the game's own body and its own gravity, on the floor of the map it is started on (f) and the one below (f + 1):
##   a drop shorter than a floor costs nothing and leaves the body on its floor;
##   one floor down - the tower's own way - costs nothing and leaves the body on f + 1;
##   a body that falls past f + 1 is set down on f + 1 (the closest floor) at its arrival, and the charge pays;
##   under the last floor of the tower the fall costs the same and the body is back on its checkpoint.
##
##   python tools/run_floor_probe.py Primitives_Portals fall_past_a_floor.gd fall.json <folder> --no-opening --opera-quiet

var game: Node
var folder := "res://ada_run/fall_past_a_floor"
var result := {}


func _initialize() -> void:
	run.call_deferred()


func _check(what: String, ok: bool, more := {}) -> bool:
	var entry := {"check": what, "ok": ok}
	entry.merge(more)
	(result.checks as Array).append(entry)
	return ok


func _done() -> void:
	result.passed = (result.checks as Array).all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("fall.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	quit()


## Wait until the body stands, or `seconds` have passed; true when it stands.
func _lands(seconds: float) -> bool:
	for i in int(seconds * 60.0):
		await physics_frame
		if i > 20 and game.body.is_on_floor(): return true
	return game.body.is_on_floor()


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	if game.body.get("scripted_input") != null:
		game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var f := int(game.checkpoint)
	result = {"floor": f, "checks": [], "passed": false}
	for i in 900: await physics_frame
	var levels: Array = game.building.spec.levels
	var here := float(levels[f])
	var below := float(levels[f + 1])
	var cost := float(game.MISSED_FLOOR_DAMAGE)
	var body: Node3D = game.body
	var start: Vector3 = game.spawn_for(f)
	var landing: Vector3 = game.spawn_for(f + 1)
	result["levels"] = {"this": here, "below": below, "storey_m": here - below, "miss_depth_m": game.FALL_MISS_DEPTH, "cost": cost}

	# ---- a drop shorter than a floor: free
	var charge_0 := float(game.charge.get_charge())
	game.place_player(start + Vector3.UP * 3.5)
	var stood := await _lands(4.0)
	for i in 30: await physics_frame
	_check("a drop of 3.5 m costs nothing and the body stands on its floor", stood and absf(body.global_position.y - here) < 0.4 and absf(float(game.charge.get_charge()) - charge_0) < 0.5,
		{"stands": stood, "over_the_floor_m": snappedf(body.global_position.y - here, 0.01), "charge": [charge_0, float(game.charge.get_charge())]})

	# ---- one floor down, the tower's own way: free. The body is let go under the slab of f, over the arrival of f + 1,
	#      and the fall is counted from f's level, as if it had stepped into a shaft there.
	var charge_1 := float(game.charge.get_charge())
	game.place_player(Vector3(landing.x, below + 4.6, landing.z))
	game.fall_start_y = here
	stood = await _lands(5.0)
	for i in 40: await physics_frame
	_check("one floor down costs nothing and the body stands on the floor below", stood and body.global_position.y - below > -0.4 and body.global_position.y - below < 1.5 and absf(float(game.charge.get_charge()) - charge_1) < 0.5,
		{"stands": stood, "over_the_floor_below_m": snappedf(body.global_position.y - below, 0.01), "charge": [charge_1, float(game.charge.get_charge())], "checkpoint": int(game.checkpoint)})

	# ---- past a floor: over the east edge of f, 1.3 m out, nothing under it
	game.place_player(start)
	for i in 30: await physics_frame
	var charge_2 := float(game.charge.get_charge())
	var edge := float(game.building.spec.width) * 0.5 + 1.3
	game.place_player(Vector3(edge, here + 0.4, -5.0))
	game.fall_start_y = here
	var lowest := body.global_position.y
	var caught_at := -1
	for i in 60 * 8:
		await physics_frame
		lowest = minf(lowest, body.global_position.y)
		if absf(float(game.charge.get_charge()) - (charge_2 - cost)) < 0.6:
			caught_at = i
			break
	for i in 12: await physics_frame
	var away := Vector2(body.global_position.x - landing.x, body.global_position.z - landing.z).length()
	_check("a body that falls past the next floor is set down on that floor, at its arrival", caught_at >= 0 and away < 1.2 and absf(body.global_position.y - below) < 1.2,
		{"frames_until_caught": caught_at, "lowest_under_the_missed_floor_m": snappedf(below - lowest, 0.01), "from_the_arrival_m": snappedf(away, 0.01), "over_that_floor_m": snappedf(body.global_position.y - below, 0.01)})
	_check("the fall costs the charge its price, once", absf(float(game.charge.get_charge()) - (charge_2 - cost)) < 0.6, {"charge": [charge_2, float(game.charge.get_charge())], "price": cost})
	_check("it was caught three metres under the missed floor, not at the bottom of the tower", below - lowest < float(game.FALL_MISS_DEPTH) + 1.5, {"lowest_under_the_missed_floor_m": snappedf(below - lowest, 0.01)})
	var said := str(game.status.text) if game.get("status") != null else ""
	_check("the notice says what happened", said.contains("FELL PAST A FLOOR"), {"notice": said})
	stood = await _lands(3.0)
	for i in 40: await physics_frame
	_check("the missed floor becomes the checkpoint once the body stands on it", int(game.checkpoint) == f + 1, {"checkpoint": int(game.checkpoint), "expected": f + 1})
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join("1_back_on_the_missed_floor.png"))

	# ---- under the last floor: the same price, and back on the checkpoint
	var charge_3 := float(game.charge.get_charge())
	var kept := int(game.checkpoint)
	var home: Vector3 = game.spawn_for(kept)
	game.place_player(Vector3(0, float(levels.back()) - 6.5, 0))
	for i in 20: await physics_frame
	away = Vector2(body.global_position.x - home.x, body.global_position.z - home.z).length()
	_check("under the last floor the fall costs the same and the body is back on its checkpoint", absf(float(game.charge.get_charge()) - (charge_3 - cost)) < 0.6 and away < 1.2 and absf(body.global_position.y - float(levels[kept])) < 1.2,
		{"charge": [charge_3, float(game.charge.get_charge())], "from_the_arrival_m": snappedf(away, 0.01), "checkpoint": int(game.checkpoint)})
	_done()
