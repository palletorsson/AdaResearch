extends SceneTree
## THE ROOF WHERE EVERYONE CLIMBS from its floor (Escher_Impossible; the pass, 2026-11-15)
## A door on the floor onto a roof drawn like a print: wide steps round a tower, four rising flights that bring
## the climber back to the door's pavilion, robed walkers going up and down. Read in the running tower with its
## own walker:
##   the door stands on the floor and the roof hangs 160 m from it, twelve walkers on its stair, its sky not drawn;
##   through the door the walker stands in a pavilion on the roof, and no fall is counted;
##   four flights up, tower on the left: the tablets read 1, 2, 3, 4, 1; the feet climbed 2.4 m; the walker
##   stands where it stood after coming in; 2.4 m were taken back in two halves;
##   walkers are in sight all the way, and never all twelve (some are behind the tower);
##   out by the door: back on the floor in front of the door;
##   with no walkers, none are seen.
##
##   godot --path <stage> --script res://tools/probes/roof_stair_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## roof.json: checks with what was read (written after every check). floor_door.png, pavilion.png, flight.png,
## corner.png, round.png, above.png.
const ID := "roof-stair"
var game: Node3D
var body: CharacterBody3D
var work: Node3D
var eye: SubViewport
var folder := ""
var result := {}


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("roof.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, name: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(folder.path_join(name))


func _go(target: Vector3, ticks_max: int = 800, speed: float = 0.4) -> bool:
	var turns: int = int(work.state().half_turns)
	var on: bool = bool(work.state().on_roof)
	for i in ticks_max:
		var s: Dictionary = work.state()
		if int(s.half_turns) != turns or bool(s.on_roof) != on:
			body.drive = Vector2.ZERO
			return true
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.12: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 12: await physics_frame
	return false


func _flight_up() -> void:
	var side: int = int(work.state().side)
	await _go(work.ring_point(side, true))
	var turned: bool = await _go(work.ring_point(posmod(side + 1, 4)))
	if turned: await _go(work.ring_point(int(work.state().side)))


func _eye_behind() -> Vector3:
	return body.global_position - body.global_transform.basis.z * -2.6 + Vector3(0, 2.0, 0)


func run() -> void:
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
	result = {"floor": floor, "map": str(record.map), "checks": checks, "passed": false}
	for i in 1500:
		if game.building.content.exhibits.has("%d/%s" % [floor, ID]): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, ID])
	work = mount.get_node_or_null("Artifact") if mount != null else null
	if work != null and work.has_method("roof_door_point"):
		for i in 200: await physics_frame
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
		body = game.body
		eye = SubViewport.new()
		eye.size = Vector2i(1280, 800)
		eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(eye)
		var cam := Camera3D.new()
		cam.fov = 85
		cam.far = 400.0
		eye.add_child(cam)
		cam.current = true
		work.apply_grid_config({"walkers": "both"})
		var s: Dictionary = work.state()
		checks.append({"check": "the door stands on the floor and the roof hangs 160 m from it, twelve walkers on its stair, its sky not drawn", "ok": absf(float(s.roof_from_door_m) - 160.0) < 1.0 and int(s.walkers_in_all) == 12
			and not bool(s.sky) and not bool(s.on_roof), "roof_from_door_m": float(s.roof_from_door_m), "build_ms": int(s.build_ms)})
		_save()
		await _shot(cam, work.door_point(5.0) + Vector3(1.6, 1.7, 0), work.door_point(0) + Vector3(0, 1.3, 0), "floor_door.png")
		# through the door
		game.place_player(work.door_point(2.2) + Vector3(0, 0.3, 0))
		for i in 40: await physics_frame
		await _go(work.door_point(-0.4), 500)
		for i in 20: await physics_frame
		var on: Dictionary = work.state()
		checks.append({"check": "through the door the walker stands in a pavilion on the roof, and no fall is counted", "ok": bool(on.on_roof) and (body.global_position - work.door_point(0)).length() > 150.0 and not bool(game.recovering)
			and bool(on.sky) and absf(float(on.feet_m) - 0.6) < 0.2, "feet_on_the_roof_m": float(on.feet_m), "recovering": bool(game.recovering)})
		_save()
		await _shot(cam, work.roof_door_point(0.3) + Vector3(0, 1.6, 0), work.ring_point(0) + Vector3(0, 1.6, 0), "pavilion.png")
		await _go(work.ring_point(0))
		var entered: Dictionary = work.state()
		var stood: Vector3 = body.global_position
		await _shot(cam, work.ring_point(0, false) + Vector3(-2.6, float(entered.feet_m) + 1.5, 0.6), work.ring_point(0, true) + Vector3(0, float(entered.feet_m) + 1.4, 0), "flight.png")
		var read := [int(entered.label)]
		var before: float = float(entered.climbed_m)
		var fewest := 99
		var most := 0
		for k in 4:
			await _flight_up()
			var here: Dictionary = work.state()
			read.append(int(here.label))
			fewest = mini(fewest, int(here.walkers_seen))
			most = maxi(most, int(here.walkers_seen))
			if k == 0: await _shot(cam, body.global_position + Vector3(1.4, 1.9, 2.4), body.global_position + Vector3(-0.4, 1.2, -2.0), "corner.png")
		var round: Dictionary = work.state()
		var off: float = body.global_position.distance_to(stood)
		await _shot(cam, work.ring_point(0, false) + Vector3(-2.6, float(round.feet_m) + 1.5, 0.6), work.ring_point(0, true) + Vector3(0, float(round.feet_m) + 1.4, 0), "round.png")
		checks.append({"check": "four flights up, tower on the left: the tablets read 1, 2, 3, 4, 1; the feet climbed 2.4 m; the walker stands where it stood after coming in; 2.4 m were taken back in two halves",
			"ok": read == [1, 2, 3, 4, 1] and absf(float(round.climbed_m) - before - 2.4) < 0.15 and off < 0.5 and absf(float(round.taken_m) - 2.4) < 0.01 and absi(int(round.half_turns)) == 2 and not bool(round.door_away),
			"read": read, "climbed_m": snappedf(float(round.climbed_m) - before, .01), "from_where_it_stood_m": snappedf(off, .01), "taken_back_m": float(round.taken_m)})
		checks.append({"check": "walkers are in sight all the way, and never all twelve", "ok": fewest >= 4 and most < 12, "fewest": fewest, "most": most})
		_save()
		await _shot(cam, work.ring_point(1, true) + Vector3(7.0, 9.0, 6.0), work.ring_point(0) + Vector3(0, 1.0, -2.0), "above.png")
		# out by the door
		await _go(work.roof_door_point(0.5))
		await _go(work.roof_door_point(-0.8), 400)
		for i in 30: await physics_frame
		var out: Dictionary = work.state()
		var from_door: float = (body.global_position - work.door_point(0)).length()
		checks.append({"check": "out by the door: back on the floor in front of the door", "ok": not bool(out.on_roof) and from_door < 2.5 and absf(body.global_position.y - level) < 0.4 and not bool(game.recovering)
			and str(out.board).contains("Last climb"), "from_the_floor_door_m": snappedf(from_door, .01)})
		work.apply_grid_config({"walkers": "none"})
		for i in 10: await physics_frame
		checks.append({"check": "with no walkers, none are seen", "ok": int(work.state().walkers_seen) == 0})
		work.apply_grid_config({"walkers": "both"})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[roof_stair_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
