extends SceneTree
## A STAIR THAT ONLY GOES UP AND COMES BACK on its floor (Escher_Impossible; the pass, 2026-11-15)
## A stairwell round a block, four rising flights, that brings the climber back to its door. Read in the running
## tower with its own walker:
##   the stairwell stands under the slab above, with its door a flight above the floor;
##   the walker goes up the ramp and in by the door, onto flight 1;
##   four flights up, block on the left: the faces passed read 1, 2, 3, 4, 1; the feet climbed 2.4 m; the walker
##   is no higher than the door, where it stood after coming in; the wall counts 2.4 m taken back, in two halves;
##   four more: 4.8 m climbed, still at the door;
##   it leaves by the door, down the ramp, onto the slab;
##   with the agreement kept, three flights up end at a wall 1.8 m above the door and nothing was taken back.
##
##   godot --path <stage> --script res://tools/probes/endless_stair_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## stair.json: checks with what was read. outside.png, flight.png, door_again.png, kept_top.png.
const ID := "endless-stair"
var game: Node3D
var body: CharacterBody3D
var work: Node3D
var eye: SubViewport


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(path)


## Walk toward a place; stops there, or as soon as the work has turned the body.
func _go(target: Vector3, ticks_max: int = 800, speed: float = 0.3) -> bool:
	var turns: int = int(work.state().half_turns)
	for i in ticks_max:
		if int(work.state().half_turns) != turns:
			body.drive = Vector2.ZERO
			return true
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.1: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 12: await physics_frame
	return false


## One flight up, block on the left: to the corner, round it, to the middle of the next side as the building has
## it - or, when the body was turned on the way, of the side it now stands on.
func _flight_up() -> void:
	var side: int = int(work.state().side)
	await _go(work.ring_point(side, true))
	var turned: bool = await _go(work.ring_point(posmod(side + 1, 4)))
	if turned: await _go(work.ring_point(int(work.state().side)))


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
	for i in 1500:
		if game.building.content.exhibits.has("%d/%s" % [floor, ID]): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, ID])
	work = mount.get_node_or_null("Artifact") if mount != null else null
	if work != null and work.has_method("ring_point"):
		for i in 200: await physics_frame
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var up := Vector3(0, 0.3, 0)
		body = game.body
		eye = SubViewport.new()
		eye.size = Vector2i(1280, 800)
		eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(eye)
		var cam := Camera3D.new()
		cam.fov = 85
		eye.add_child(cam)
		cam.current = true
		var at: Vector3 = work.global_position
		work.apply_grid_config({"agreement": "moved"})
		var s: Dictionary = work.state()
		var under: float = float(game.building.spec.levels[floor - 1]) - float(game.building.spec.slab_thickness) - float(game.building.spec.levels[floor])
		checks.append({"check": "the stairwell stands under the slab above", "ok": float(s.top_m) < under - 0.05 and absf(at.y - level) < 0.05, "top_m": float(s.top_m), "room_under_the_slab_m": snappedf(under, .01), "build_ms": int(s.build_ms)})
		await _shot(cam, work.door_point(5.6) + Vector3(2.6, 1.7, 0), at + Vector3(-0.6, 1.6, 0), folder.path_join("outside.png"))
		# up the ramp and in
		game.place_player(work.door_point(3.4) + up)
		for i in 40: await physics_frame
		await _go(work.door_point(-0.6))
		await _go(work.ring_point(0))
		var entered: Dictionary = work.state()
		var stood: Vector3 = body.global_position
		await _shot(cam, work.ring_point(0) + Vector3(-1.5, float(entered.feet_m) + 1.5, 0.2), work.ring_point(0) + Vector3(1.4, float(entered.feet_m) + 1.3, -0.4), folder.path_join("flight.png"))
		checks.append({"check": "the walker goes up the ramp and in by the door, onto flight 1", "ok": bool(entered.inside) and int(entered.label) == 1 and float(entered.feet_m) > 0.5, "label": int(entered.label), "feet_above_the_floor_m": float(entered.feet_m)})
		var read := [int(entered.label)]
		var before: float = float(entered.climbed_m)
		for k in 4:
			await _flight_up()
			read.append(int(work.state().label))
		var round: Dictionary = work.state()
		var off: float = body.global_position.distance_to(stood)
		await _shot(cam, work.ring_point(0) + Vector3(-1.5, float(round.feet_m) + 1.5, 0.2), work.ring_point(0) + Vector3(1.4, float(round.feet_m) + 1.3, -0.4), folder.path_join("door_again.png"))
		checks.append({"check": "four flights up, block on the left: the faces read 1, 2, 3, 4, 1; the feet climbed 2.4 m; the walker stands where it stood after coming in; 2.4 m were taken back in two halves",
			"ok": read == [1, 2, 3, 4, 1] and absf(float(round.climbed_m) - before - 2.4) < 0.15 and off < 0.45 and absf(float(round.taken_m) - 2.4) < 0.01 and absi(int(round.half_turns)) == 2 and not bool(round.door_plugged),
			"read": read, "climbed_m": snappedf(float(round.climbed_m) - before, .01), "from_where_it_stood_m": snappedf(off, .01), "taken_back_m": float(round.taken_m), "half_turns": int(round.half_turns)})
		for k in 4: await _flight_up()
		var twice: Dictionary = work.state()
		checks.append({"check": "four more: 4.8 m climbed, still at the door", "ok": absf(float(twice.climbed_m) - before - 4.8) < 0.2 and absf(float(twice.above_door_m) - float(entered.above_door_m)) < 0.25 and int(twice.label) == 1,
			"climbed_m": snappedf(float(twice.climbed_m) - before, .01), "above_the_door_m": float(twice.above_door_m)})
		# out by the door, down the ramp
		await _go(work.door_point(-0.6))
		await _go(work.door_point(3.4))
		var outside: Dictionary = work.state()
		checks.append({"check": "it leaves by the door, down the ramp, onto the slab", "ok": not bool(outside.inside) and absf(body.global_position.y - level) < 0.4 and str(outside.board).contains("Last walk"), "feet_above_the_slab_m": snappedf(body.global_position.y - level, .01)})
		# the agreement kept: an honest stair that stops
		work.apply_grid_config({"agreement": "kept"})
		for i in 10: await physics_frame
		await _go(work.door_point(-0.6))
		await _go(work.ring_point(0))
		var from: float = float(work.state().feet_m)
		for k in 2: await _flight_up()
		await _go(work.ring_point(2, true))
		await _go(work.ring_point(3), 240)
		var top: Dictionary = work.state()
		await _shot(cam, work.ring_point(2) + Vector3(0.6, float(top.feet_m) + 1.5, 0), work.ring_point(2, true) + Vector3(0, float(top.feet_m) + 1.2, 0.9), folder.path_join("kept_top.png"))
		checks.append({"check": "with the agreement kept, three flights up end at a wall 1.8 m above the door and nothing was taken back", "ok": int(top.half_turns) == int(twice.half_turns) and absf(float(top.taken_m)) < 0.001
			and absf(float(top.above_door_m) - 1.8) < 0.25 and work.to_local(body.global_position).z < -0.8, "above_the_door_m": float(top.above_door_m), "taken_back_m": float(top.taken_m)})
		work.apply_grid_config({"agreement": "moved"})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		for i in 20: await physics_frame
		work.apply_grid_config({"agreement": "moved"})
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	var file := FileAccess.open(folder.path_join("stair.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[endless_stair_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
