extends SceneTree
## A SMALL PLANET from its floor (NonEuclidean_Spaces; the pass, 2026-11-15)
## A door on the floor that leads onto a world ten metres across, which turns under the walker's steps. Read in
## the running tower with its own walker:
##   the door stands on the floor and the planet hangs 160 m north of it, five beetles on it, its sky not drawn;
##   through the door the walker stands on the planet, on its feet, and no fall is counted;
##   six metres straight on, the door it came by is 3.2 m below the horizon's top behind it;
##   31.4 m straight on, the door is in front of it again; through it, the walker is back on the floor;
##   a quarter round, left, a quarter, left, a quarter: at the door after three right angles, the door turned by
##   a quarter; through it, back on the floor;
##   six metres across: a smaller world.
##
##   godot --path <stage> --script res://tools/probes/small_planet_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## planet.json: checks with what was read (written after every check). floor_door.png, arrival.png, six_m.png,
## coming_back.png, quarter.png.
const ID := "small-planet"
var game: Node3D
var body: CharacterBody3D
var work: Node3D
var eye: SubViewport
var folder := ""
var result := {}


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("planet.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, name: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(folder.path_join(name))


## Straight on in one direction for so many metres of the planet's own count; or until the walker is off the planet.
func _walk(dir: Vector3, metres: float, until_off: bool = false) -> void:
	var start: float = float(work.state().walked_m)
	for i in (900 if until_off else 7000):
		var s: Dictionary = work.state()
		if until_off and not bool(s.on_planet): break
		if not until_off and float(s.walked_m) - start >= metres: break
		body.look_at(body.global_position + dir, Vector3.UP)
		body.drive = Vector2(0, -0.6)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 15: await physics_frame


## Out by the door on the planet, whichever way it has turned: to a place a metre off it on the walker's side,
## then straight through it.
func _out_by_the_door() -> void:
	var door: Node3D = work.get_node("Rig/Planet/PlanetDoor")
	var across := Vector3(door.global_basis.z.x, 0, door.global_basis.z.z).normalized()
	var to: Vector3 = door.global_position - body.global_position
	to.y = 0
	var side: float = -signf(to.dot(across))
	if side == 0.0: side = 1.0
	var stand: Vector3 = to + across * side * 1.1
	await _walk(stand.normalized(), stand.length())
	await _walk(-across * side, 0.0, true)


func _through_the_door(north: Vector3) -> void:
	game.place_player(work.door_point(2.2) + Vector3(0, 0.3, 0))
	for i in 40: await physics_frame
	for i in 600:
		if bool(work.state().on_planet): break
		body.look_at(body.global_position + north, Vector3.UP)
		body.drive = Vector2(0, -0.4)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 20: await physics_frame


func _behind(dir: Vector3) -> Vector3:
	return body.global_position - dir * 3.4 + dir.cross(Vector3.UP) * 1.4 + Vector3(0, 2.3, 0)


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
	if work != null and work.has_method("door_point"):
		for i in 200: await physics_frame
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
		body = game.body
		eye = SubViewport.new()
		eye.size = Vector2i(1280, 800)
		eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(eye)
		var cam := Camera3D.new()
		cam.fov = 80
		cam.far = 400.0
		eye.add_child(cam)
		cam.current = true
		var north: Vector3 = -work.global_transform.basis.z.normalized()
		var west: Vector3 = -work.global_transform.basis.x.normalized()
		work.apply_grid_config({"across": "ten"})
		var s: Dictionary = work.state()
		checks.append({"check": "the door stands on the floor and the planet hangs 160 m north of it, five beetles on it, its sky not drawn", "ok": absf(float(s.planet_from_door_m) - 160.0) < 1.0 and int(s.beetles) == 5
			and not bool(s.sky) and not bool(s.on_planet) and absf(float(s.radius) - 5.0) < 0.001, "planet_from_door_m": float(s.planet_from_door_m), "round_m": float(s.round_m), "build_ms": int(s.build_ms)})
		_save()
		await _shot(cam, work.door_point(5.5) + Vector3(1.8, 1.7, 0), work.door_point(0) + Vector3(0, 2.0, 0) + north * 30.0, "floor_door.png")
		# through the door
		await _through_the_door(north)
		var on: Dictionary = work.state()
		var away: float = (body.global_position - work.door_point(0)).length()
		checks.append({"check": "through the door the walker stands on the planet, on its feet, and no fall is counted", "ok": bool(on.on_planet) and away > 150.0 and absf(body.global_position.y - level) < 0.4 and not bool(game.recovering)
			and bool(on.sky), "from_the_floor_door_m": snappedf(away, .1), "feet_above_floor_level_m": snappedf(body.global_position.y - level, .01), "recovering": bool(game.recovering)})
		_save()
		await _shot(cam, _behind(north), body.global_position + north * 2.5 + Vector3(0, 0.8, 0), "arrival.png")
		await _walk(north, 6.0 - float(on.walked_m))
		var six: Dictionary = work.state()
		await _shot(cam, _behind(north), body.global_position + north * 2.5 + Vector3(0, 0.8, 0), "six_m.png")
		checks.append({"check": "six metres straight on, the door it came by is 3.2 m below the top, behind it", "ok": absf(float(six.walked_m) - 6.0) < 0.3 and absf(float(six.door_below_m) - 3.19) < 0.4 and bool(six.on_planet),
			"walked_m": float(six.walked_m), "door_below_m": float(six.door_below_m)})
		_save()
		await _walk(north, float(six.round_m) - 1.2 - float(six.walked_m))
		var near: Dictionary = work.state()
		await _shot(cam, _behind(north), body.global_position + north * 2.5 + Vector3(0, 0.8, 0), "coming_back.png")
		await _walk(north, 0.0, true)
		for i in 30: await physics_frame
		var home: Dictionary = work.state()
		var from_door: float = (body.global_position - work.door_point(0)).length()
		checks.append({"check": "31.4 m straight on, the door is in front of the walker again; through it, the walker is back on the floor", "ok": float(near.door_away_m) < 1.6 and float(near.door_below_m) < 0.4 and not bool(home.on_planet)
			and from_door < 2.5 and absf(body.global_position.y - level) < 0.4 and not bool(game.recovering) and str(home.board).contains("Last visit: 3"), "door_ahead_m": float(near.door_away_m), "walked_m": float(near.walked_m),
			"from_the_floor_door_m": snappedf(from_door, .01)})
		_save()
		# three right angles
		await _through_the_door(north)
		var quarter: float = float(work.state().round_m) * 0.25
		await _walk(north, quarter - float(work.state().walked_m))
		await _walk(west, quarter)
		await _walk(-north, quarter - 0.9)
		var tri: Dictionary = work.state()
		await _shot(cam, _behind(-north), body.global_position - north * 2.5 + Vector3(0, 0.8, 0), "quarter.png")
		await _out_by_the_door()
		for i in 30: await physics_frame
		var out: Dictionary = work.state()
		var turn: float = absf(wrapf(float(tri.door_turn_deg), -180.0, 180.0))
		checks.append({"check": "a quarter round, left, a quarter, left, a quarter: at the door after three right angles, the door turned by a quarter; through it, back on the floor", "ok": float(tri.door_away_m) < 1.6
			and absf(turn - 90.0) < 12.0 and not bool(out.on_planet) and (body.global_position - work.door_point(0)).length() < 2.5 and not bool(game.recovering), "door_ahead_m": float(tri.door_away_m), "door_turned_deg": snappedf(turn, .1),
			"walked_m": float(tri.walked_m)})
		_save()
		work.apply_grid_config({"across": "six"})
		for i in 10: await physics_frame
		var small: Dictionary = work.state()
		checks.append({"check": "six metres across: a smaller world", "ok": absf(float(small.radius) - 3.0) < 0.001 and absf(float(small.round_m) - 18.85) < 0.01, "round_m": float(small.round_m)})
		work.apply_grid_config({"across": "ten"})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[small_planet_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
