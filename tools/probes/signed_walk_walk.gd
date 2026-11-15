extends SceneTree
## A WEIGHT, A CHANGE, A PRODUCT on its floor (QFEP_Phi_Term; the pass, 2026-11-15)
## A track read once a second; plates set the weight; a stand keeps weight, change and product apart. Read in the
## running tower with its own walker:
##   at rest: the weight is 0, the words hidden, the looks kept, nothing looked at yet;
##   weight 0: the reading changes along the track and the product stays 0;
##   weight +1, walking east: every change is positive and the product equals it, the arrow up;
##   weight +1, walking back: the change and the product are negative, the arrow down;
##   weight -1, walking back: the change is negative and the product positive, and the stand does not call it good;
##   the same stretch slowly, then fast: the same difference in more looks;
##   SNAPSHOT: one dot, no change, no product, at any weight;
##   EARLIER LABELS: two words on the floor and one on the stand; the weight, the looks and the product as before.
##
##   godot --path <stage> --script res://tools/probes/signed_walk_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## signed.json: checks with what was read (written after every check). arrival.png, overview.png, rising.png,
## negative.png, labels.png.
const ID := "signed-walk"
var game: Node3D
var body: CharacterBody3D
var work: Node3D
var eye: SubViewport
var cam: Camera3D
var folder := ""
var result := {}


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("signed.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()


func _shot(at: Vector3, target: Vector3, name: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(folder.path_join(name))


func _go(target: Vector3, drive: float = 0.5, ticks: int = 2400) -> void:
	for i in ticks:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.07: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -(drive if d > 0.5 else minf(drive, 0.25)))
		await physics_frame
	body.drive = Vector2.ZERO


## Along the track to a reading; returns what the work showed at each new look on the way.
func _along(to: float, drive: float = 0.4) -> Array:
	var seen := []
	var n: int = int(work.state().look_n)
	var target: Vector3 = work.track_point(to)
	for i in 3000:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.07: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -drive)
		await physics_frame
		var s: Dictionary = work.state()
		if int(s.look_n) != n:
			n = int(s.look_n)
			seen.append(s)
	body.drive = Vector2.ZERO
	for i in 8: await physics_frame
	return seen


func _stand(ticks: int = 90) -> void:
	for i in ticks: await physics_frame


## To a plate by the south of the plates' row, and stood on.
func _press(key: String) -> void:
	var here: Vector3 = work.to_local(body.global_position)
	if here.z < 1.2: await _go(work.to_global(Vector3(clampf(here.x, -3.2, 3.2), 0, 0.95)))
	else: await _go(work.to_global(Vector3(here.x, 0, 2.7)))      # off a plate before standing on one: the same plate twice is two visits
	await _go(work.plate_point(key))
	await _stand()


## Onto the track's end at a reading, from the south.
func _to_end(reading: float) -> void:
	await _go(work.to_global(Vector3(work.to_local(work.track_point(reading)).x, 0, 1.0)))
	await _go(work.track_point(reading))
	for i in 6: await physics_frame


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
	if work != null and work.has_method("track_point"):
		for i in 200: await physics_frame
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
		body = game.body
		eye = SubViewport.new()
		eye.size = Vector2i(1280, 800)
		eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(eye)
		cam = Camera3D.new()
		cam.fov = 80
		eye.add_child(cam)
		cam.current = true
		game.place_player(Vector3(-12.0, level + 0.3, 7.6))        # out of its own arrival picture
		for i in 30: await physics_frame
		await _shot(Vector3(0, level + 1.65, 7.8), Vector3(0, level + 1.5, 0), "arrival.png")
		await _shot(Vector3(4.6, level + 4.4, 8.7), Vector3(10.0, level + 0.8, 5.0), "overview.png")
		work.apply_grid_config({"labels": "hidden"})
		var s: Dictionary = work.state()
		checks.append({"check": "at rest: the weight is 0, the words hidden, the looks kept, nothing looked at yet", "ok": is_zero_approx(float(s.phi)) and str(s.labels) == "hidden" and bool(s.history) and Array(s.looks).is_empty()
			and int(s.floor_words) == 0 and Array(s.shown) == ["0", "—", "—"], "shown": s.shown, "build_ms": int(s.build_ms)})
		_save()
		# weight 0
		game.place_player(work.to_global(Vector3(-2.3, 0.3, 1.0)))
		for i in 30: await physics_frame
		await _go(work.track_point(0.06))
		var none: Array = await _along(0.94)
		checks.append({"check": "weight 0: the reading changes along the track and the product stays 0", "ok": none.size() >= 3 and none.slice(1).all(func(o): return float(o.change) > 0.01 and is_zero_approx(float(o.product)) and str(o.arrow) == "none"),
			"looks": none.size(), "changes": none.slice(1).map(func(o): return float(o.change)), "says": str(none[-1].status) if not none.is_empty() else ""})
		_save()
		# weight +1
		await _press("plus")
		await _to_end(0.06)
		var rising: Array = await _along(0.94)
		await _shot(work.to_global(Vector3(-0.6, 2.6, 3.9)), work.to_global(Vector3(0.2, 1.3, -2.0)), "rising.png")
		checks.append({"check": "weight +1, walking east: every change is positive and the product equals it, the arrow up", "ok": rising.size() >= 3 and rising.slice(1).all(func(o): return float(o.change) > 0.01 and is_equal_approx(float(o.product), float(o.change)) and str(o.arrow) == "up"),
			"changes": rising.slice(1).map(func(o): return float(o.change)), "says": str(rising[-1].status)})
		_save()
		var falling: Array = await _along(0.06)
		await _shot(work.to_global(Vector3(-0.6, 2.6, 3.9)), work.to_global(Vector3(0.2, 1.3, -2.0)), "negative.png")
		checks.append({"check": "weight +1, walking back: the change and the product are negative, the arrow down", "ok": falling.size() >= 3 and falling.slice(1).all(func(o): return float(o.change) < -0.01 and float(o.product) < -0.01 and str(o.arrow) == "down")
			and str(falling[-1].status).contains("FALLING READING"), "changes": falling.slice(1).map(func(o): return float(o.change)), "says": str(falling[-1].status)})
		_save()
		# weight -1
		await _press("minus")
		await _to_end(0.94)
		var both: Array = await _along(0.06)
		checks.append({"check": "weight -1, walking back: the change is negative and the product positive, and the stand does not call it good", "ok": both.size() >= 3
			and both.slice(1).all(func(o): return float(o.change) < -0.01 and float(o.product) > 0.01 and str(o.arrow) == "up") and str(both[-1].status).contains("THE ARITHMETIC DOES NOT SAY"),
			"products": both.slice(1).map(func(o): return float(o.product)), "says": str(both[-1].status)})
		_save()
		# slowly, then fast
		var slow: Array = await _along(0.94, 0.2)
		var fast: Array = await _along(0.06, 0.8)
		checks.append({"check": "the same stretch slowly, then fast: the same difference in more looks", "ok": slow.size() > fast.size() + 1 and fast.size() >= 1, "looks_slow": slow.size(), "looks_fast": fast.size(),
			"a_change_slow": float(slow[-1].change) if not slow.is_empty() else 0.0, "a_change_fast": float(fast[-1].change) if not fast.is_empty() else 0.0})
		_save()
		# a snapshot
		await _press("history")
		await _to_end(0.06)
		var snap: Array = await _along(0.94)
		checks.append({"check": "SNAPSHOT: one dot, no change, no product, at any weight", "ok": snap.size() >= 3 and snap.all(func(o): return int(o.dots) == 1 and is_equal_approx(float(o.change), -99.0) and Array(o.shown).slice(1) == ["—", "—"] and str(o.arrow) == "none")
			and str(snap[-1].status) == "ONE LOOK HAS NO CHANGE IN IT.", "dots": int(snap[-1].dots), "shown": snap[-1].shown})
		_save()
		await _press("history")
		# the earlier labels
		var before: Dictionary = work.state()
		await _press("labels")
		var named: Dictionary = work.state()
		await _shot(work.to_global(Vector3(-0.6, 2.6, 3.9)), work.to_global(Vector3(0.2, 1.3, -2.0)), "labels.png")
		checks.append({"check": "EARLIER LABELS: two words on the floor and one on the stand; the weight, the looks and the product as before", "ok": str(named.labels) == "shown" and int(named.floor_words) == 2 and str(named.weight_word) == "RESIST"
			and is_equal_approx(float(named.phi), float(before.phi)) and Array(named.looks) == Array(before.looks) and Array(named.shown) == Array(before.shown) and str(named.status) == str(before.status),
			"weight_word": str(named.weight_word), "shown": named.shown})
		_save()
		await _press("labels")
		await _press("zero")
		var left: Dictionary = work.state()
		result["left_as"] = {"phi": float(left.phi), "labels": str(left.labels), "history": bool(left.history)}
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok) and is_zero_approx(float(left.phi)) and str(left.labels) == "hidden" and bool(left.history)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[signed_walk_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
