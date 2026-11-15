extends SceneTree
## EVERY DOOR, HALF AS FAR on its floor (NonEuclidean_Spaces; the pass, 2026-11-15)
## A plank over the north edge to a cardboard funnel; inside, the funnel is made larger round the walker by its
## steps. Read in the running tower with its own walker:
##   at rest the funnel is as built: doors at 6, 3, 1.5, 0.75 m from the tip, lettered IN, 1, 2, 3;
##   in through the mouth the walker is in, on its feet, the tip six metres ahead, no fall counted;
##   one door on (4.16 m) the door behind is 1, the next is three metres ahead at half its width;
##   ten doors on (41.6 m) every door was as far as the last, the tip is still six metres ahead, and on the
##   picture the walker is six millimetres from it;
##   straight on beside the axis, the wall comes nearer by the rule;
##   out again by the way it came: the funnel is as built, the walker on the plank, a flag at door 10;
##   with `ratio` two_thirds a door is passed every 2.43 m.
##
##   godot --path <stage> --script res://tools/probes/halving_door_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## halving.json: checks with what was read (written after every check). outside.png, looking_in.png, door_1.png,
## door_10.png, back.png, flag.png.
const ID := "halving-door"
var game: Node3D
var body: CharacterBody3D
var work: Node3D
var eye: SubViewport
var cam: Camera3D
var folder := ""
var result := {}
var north := Vector3.ZERO


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("halving.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()


func _shot(at: Vector3, target: Vector3, name: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(folder.path_join(name))


func _tip() -> Vector3:
	return (work.get_node("Funnel") as Node3D).global_position


## Toward the tip until `gone` metres past the mouth (the work's own count), or `doors` passed. Returns what the work
## read at that moment.
## Toward the tip until `gone` metres past the mouth (the work's own count), or `doors` passed.
func _in_to(gone: float, doors: float = -1.0) -> Dictionary:
	var read := {}
	for i in 9000:
		var s: Dictionary = work.state()
		read = s
		if bool(s["in"]) and ((doors >= 0.0 and float(s.doors) >= doors) or (doors < 0.0 and float(s.gone_m) >= gone)): break
		var tip := _tip()
		body.look_at(Vector3(tip.x, body.global_position.y, tip.z), Vector3.UP)
		body.drive = Vector2(0, -0.8)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 12: await physics_frame
	return read                 # as it was when the mark was passed, before the walker ran on


## Out by the way it came: through the middle of the door behind, again and again, until it is on the plank.
func _out() -> void:
	for i in 12000:
		if not bool(work.state()["in"]): break
		var door: Vector3 = (work.get_node("Funnel") as Node3D).to_global(Vector3(0, 0, 6.0)) - north * 0.6
		body.look_at(Vector3(door.x, body.global_position.y, door.z), Vector3.UP)
		body.drive = Vector2(0, -0.8)
		await physics_frame
	for i in 25:
		body.look_at(body.global_position - north, Vector3.UP)
		body.drive = Vector2(0, -0.5)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 20: await physics_frame


func _straight(dir: Vector3, metres: float) -> void:
	var from: Vector3 = body.global_position
	for i in 1500:
		if (body.global_position - from).length() >= metres: break
		body.look_at(body.global_position + dir, Vector3.UP)
		body.drive = Vector2(0, -0.5)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 12: await physics_frame


func _eyes(name: String, back: bool = false) -> void:
	var dir: Vector3 = -north if back else north
	await _shot(body.global_position + Vector3(0, 1.62, 0) - dir * 0.05, body.global_position + dir * 4.0 + Vector3(0, 1.0, 0), name)


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
	if work != null and work.has_method("mouth_point"):
		for i in 200: await physics_frame
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
		body = game.body
		eye = SubViewport.new()
		eye.size = Vector2i(1280, 800)
		eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(eye)
		cam = Camera3D.new()
		cam.fov = 80
		cam.far = 400.0
		eye.add_child(cam)
		cam.current = true
		north = -work.global_transform.basis.z.normalized()
		var east: Vector3 = work.global_transform.basis.x.normalized()
		work.apply_grid_config({"ratio": "half"})
		var s: Dictionary = work.state()
		checks.append({"check": "at rest the funnel is as built: doors at 6, 3, 1.5, 0.75 m from the tip, lettered IN, 1, 2, 3", "ok": not bool(s["in"]) and absf(float(s.scale) - 1.0) < 0.001 and Array(s.funnel_at) == Array(s.built_at)
			and Array(s.picture_doors_m).slice(0, 4) == [6.0, 3.0, 1.5, 0.75] and Array(s.labels) == ["IN", "1", "2", "3"] and absf(float(s.door_every_m) - 4.159) < 0.002,
			"picture_doors_m": s.picture_doors_m, "labels": s.labels, "doors_shown": int(s.doors_shown), "door_every_m": float(s.door_every_m), "build_ms": int(s.build_ms)})
		_save()
		await _shot(work.mouth_point(6.2) - east * 3.4 + Vector3(0, 2.3, 0), work.mouth_point(-2.5) + Vector3(0, 1.0, 0), "outside.png")
		await _shot(work.mouth_point(1.3) + Vector3(0, 1.62, 0), work.mouth_point(-6.0) + Vector3(0, 0.5, 0), "looking_in.png")
		# in through the mouth
		game.place_player(work.mouth_point(2.0) + Vector3(0, 0.3, 0))
		for i in 40: await physics_frame
		await _in_to(0.3)
		var on: Dictionary = work.state()
		checks.append({"check": "in through the mouth the walker is in, on its feet, the tip six metres ahead, no fall counted", "ok": bool(on["in"]) and absf(float(on.tip_ahead_m) - 6.0) < 0.02 and absf(body.global_position.y - level) < 0.3
			and not bool(game.recovering), "tip_ahead_m": float(on.tip_ahead_m), "gone_m": float(on.gone_m), "feet_above_floor_level_m": snappedf(body.global_position.y - level, .01), "recovering": bool(game.recovering)})
		_save()
		var one: Dictionary = await _in_to(0.0, 1.02)
		checks.append({"check": "one door on (4.16 m) the door behind is 1, the next is three metres ahead at half its width", "ok": int(one.door_behind) == 1 and absf(float(one.gone_m) - 4.24) < 0.12 and absf(float(one.next_door_ahead_m) - 3.0) < 0.15
			and absf(float(one.next_door_wide_m) - 0.55) < 0.04 and absf(float(one.tip_ahead_m) - 6.0) < 0.02 and Array(one.labels) == ["1", "2", "3", "4"] and str(one.paper).contains("door 1"),
			"gone_m": float(one.gone_m), "next_door_ahead_m": float(one.next_door_ahead_m), "next_door_wide_m": float(one.next_door_wide_m), "tip_ahead_m": float(one.tip_ahead_m), "labels": one.labels, "paper": str(one.paper)})
		_save()
		await _in_to(float(work.state().gone_m) + 0.8)
		await _eyes("door_1.png")
		var ahead := [snappedf(float(one.next_door_ahead_m), 0.01)]
		var tips := [snappedf(float(one.tip_ahead_m), 0.01)]
		var ten: Dictionary = one
		for door in range(2, 11):
			var at: Dictionary = await _in_to(0.0, float(door) + 0.02)
			ten = at
			ahead.append(snappedf(float(at.next_door_ahead_m), 0.01))
			tips.append(snappedf(float(at.tip_ahead_m), 0.01))
		var really: float = (body.global_position - work.mouth_point(0)).length()
		checks.append({"check": "ten doors on (41.6 m) every door was as far as the last, the tip is still six metres ahead, and on the picture the walker is six millimetres from it",
			"ok": int(ten.door_behind) == 10 and ahead.all(func(m): return absf(float(m) - 3.0) < 0.15) and tips.all(func(m): return absf(float(m) - 6.0) < 0.02) and absf(float(ten.picture_from_tip_m) - 0.00586) < 0.0006
				and absf(really - 42.0) < 1.0 and absf(body.global_position.y - level) < 0.3 and not bool(game.recovering) and float(ten.door_behind_high_m) >= 2.6 and float(ten.door_behind_high_m) < 5.3,
			"next_door_ahead_m_at_each": ahead, "tip_ahead_m_at_each": tips, "picture_from_tip_mm": snappedf(float(ten.picture_from_tip_m) * 1000.0, 0.01), "picture_tall_mm": snappedf(float(ten.picture_tall_m) * 1000.0, 0.01),
			"body_from_the_mouth_m": snappedf(really, 0.1), "labels": ten.labels, "paper": str(ten.paper), "recovering": bool(game.recovering)})
		_save()
		await _in_to(float(work.state().gone_m) + 0.6)
		await _eyes("door_10.png")
		await _eyes("back.png", true)
		# straight on beside the axis
		await _straight(-east, 0.6)
		var beside: Dictionary = work.state()
		var gone_before: float = float(beside.gone_m)
		await _straight(north, 2.4)
		var nearer: Dictionary = work.state()
		var rule: float = float(beside.beside_axis_m) * exp((float(nearer.gone_m) - gone_before) / 6.0)
		checks.append({"check": "straight on beside the axis, the wall comes nearer by the rule", "ok": absf(float(beside.beside_axis_m)) > 0.4 and absf(float(nearer.beside_axis_m)) > absf(float(beside.beside_axis_m)) + 0.1
			and absf(float(nearer.beside_axis_m) - rule) < 0.06 and absf(float(nearer.beside_axis_m)) <= 1.5, "beside_axis_m": [float(beside.beside_axis_m), float(nearer.beside_axis_m)], "by_the_rule_m": snappedf(rule, 0.01),
			"went_on_m": snappedf(float(nearer.gone_m) - gone_before, 0.01)})
		_save()
		# out again
		await _out()
		var out: Dictionary = work.state()
		var stands: Vector3 = work.to_local(body.global_position)
		checks.append({"check": "out again by the way it came: the funnel is as built, the walker on the plank, a flag at door 10", "ok": not bool(out["in"]) and absf(float(out.scale) - 1.0) < 0.001 and Array(out.funnel_at) == Array(out.built_at)
			and absf(stands.x) < 0.7 and stands.z > -3.0 and absf(body.global_position.y - level) < 0.3 and not bool(game.recovering) and bool(out.flag) and str(out.flag_words).begins_with("door 10") and str(out.board).contains("Last visit"),
			"walker_from_the_plank_line_m": snappedf(stands.x, 0.01), "set_sideways_times": int(out.shifts), "flag_words": str(out.flag_words), "labels": out.labels, "recovering": bool(game.recovering),
			"last_visit": str(out.board).get_slice("\n", 5)})
		_save()
		await _shot(work.mouth_point(2.5) + east * 6.5 + Vector3(0, 2.2, 0), work.mouth_point(-3.2) + Vector3(0, 0.9, 0), "flag.png")
		# another ratio
		work.apply_grid_config({"ratio": "two_thirds"})
		var other: Dictionary = work.state()
		game.place_player(work.mouth_point(2.0) + Vector3(0, 0.3, 0))
		for i in 40: await physics_frame
		var third: Dictionary = await _in_to(0.0, 1.02)
		checks.append({"check": "with `ratio` two_thirds a door is passed every 2.43 m", "ok": absf(float(other.door_every_m) - 2.433) < 0.002 and int(other.doors_shown) == 15 and int(third.door_behind) == 1 and absf(float(third.gone_m) - 2.48) < 0.12
			and absf(float(third.next_door_ahead_m) - 2.0) < 0.12, "door_every_m": float(other.door_every_m), "doors_shown": int(other.doors_shown), "gone_m": float(third.gone_m), "next_door_ahead_m": float(third.next_door_ahead_m)})
		_save()
		await _out()
		work.apply_grid_config({"ratio": "half"})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[halving_door_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
