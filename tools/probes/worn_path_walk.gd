extends SceneTree
## THE LIGHT RECOMMENDS, THE FEET DECIDE on its floor (QFEP_Lambda_Spectrum; the pass, 2026-11-15)
## A field of tiles that darken where feet go, three rows of posts with gaps in line, a lit strip that plates move.
## Read in the running tower with its own walker:
##   at rest: the light lies through the gaps, nothing is worn;
##   a crossing along the light: one crossing, every step on the lit strip, the worn path under the light;
##   LIGHT EAST: the strip moves 3 m east; following it, the walker is held by the posts;
##   it goes round through the gap and across: few steps on the strip, the worn path still through the gaps,
##   3 m from the light, and the stand says so;
##   LIGHT WHAT WAS WORN: the strip lies on the worn path;
##   SWEEP: nothing is worn, the light stays.
##
##   godot --path <stage> --script res://tools/probes/worn_path_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## worn.json: checks with what was read (written after every check). arrival.png, overview.png, field.png,
## east.png, worn.png.
const ID := "worn-path"
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
	var file := FileAccess.open(folder.path_join("worn.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()


func _shot(at: Vector3, target: Vector3, name: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(folder.path_join(name))


func _go(target: Vector3, ticks: int = 1200) -> void:
	for i in ticks:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.07: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -(0.5 if d > 0.5 else 0.25))
		await physics_frame
	body.drive = Vector2.ZERO


func _stand(ticks: int = 90) -> void:
	for i in ticks: await physics_frame


func _press(key: String) -> void:
	await _go(work.plate_point(key))
	await _stand()


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
	if work != null and work.has_method("field_point"):
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
		game.place_player(Vector3(13.5, level + 0.3, 7.6))        # out of its own arrival picture
		for i in 30: await physics_frame
		await _shot(Vector3(0, level + 1.65, 7.8), Vector3(0, level + 1.5, 0), "arrival.png")
		await _shot(Vector3(-9.5, level + 4.8, 8.4), Vector3(-17.0, level + 0.4, -1.0), "overview.png")
		work.apply_grid_config({"lit": "gap"})
		var s: Dictionary = work.state()
		checks.append({"check": "at rest: the light lies through the gaps, nothing is worn", "ok": str(s.lit) == "gap" and is_equal_approx(float(s.lit_x), float(s.gap_x)) and int(s.wear_total) == 0 and int(s.crossings) == 0
			and str(s.says) == "nothing is worn yet", "lit_x": float(s.lit_x), "build_ms": int(s.build_ms)})
		_save()
		# along the light
		game.place_player(work.field_point(-1.25, -6.6) + Vector3(0, 0.3, 0))
		for i in 30: await physics_frame
		await _go(work.field_point(-1.25, 5.6))
		for i in 10: await physics_frame
		var along: Dictionary = work.state()
		await _shot(work.field_point(1.4, -8.4) + Vector3(0, 3.4, 0), work.field_point(-0.8, 0.8), "field.png")
		checks.append({"check": "a crossing along the light: one crossing, every step on the lit strip, the worn path under the light", "ok": int(along.crossings) == 1 and int(along.steps) >= 19 and int(along.on_lit) == int(along.steps)
			and is_equal_approx(float(along.worn_x), -1.25) and float(along.apart_m) < 0.01 and str(along.status) == "", "steps": int(along.steps), "on_lit": int(along.on_lit), "says": str(along.says)})
		_save()
		# the light moved east
		await _go(work.field_point(3.6, 5.6))
		await _go(work.field_point(3.6, -6.4))
		await _press("east")
		var east: Dictionary = work.state()
		await _go(work.field_point(1.75, -4.6))
		await _go(work.field_point(1.75, 0.0), 400)
		var held: float = work.to_local(body.global_position).z
		checks.append({"check": "LIGHT EAST: the strip moves 3 m east; following it, the walker is held by the posts", "ok": str(east.lit) == "east" and is_equal_approx(float(east.strip_x), 1.75) and int(east.steps) == 0 and held > 2.5,
			"strip_x": float(east.strip_x), "stopped_m_south_of_the_first_posts": snappedf(held - 2.5, 0.01)})
		_save()
		await _go(work.field_point(-1.25, -3.2))
		await _go(work.field_point(-1.25, 5.6))
		for i in 10: await physics_frame
		var round: Dictionary = work.state()
		await _shot(work.field_point(1.4, -8.4) + Vector3(0, 3.4, 0), work.field_point(-0.8, 0.8), "east.png")
		checks.append({"check": "it goes round through the gap and across: few steps on the strip, the worn path still through the gaps, 3 m from the light, and the stand says so", "ok": int(round.crossings) == 2
			and int(round.on_lit) * 3 < int(round.steps) and is_equal_approx(float(round.worn_x), -1.25) and absf(float(round.apart_m) - 3.0) < 0.01 and str(round.status).begins_with("THE LIGHT POINTED ONE WAY"),
			"steps": int(round.steps), "on_lit": int(round.on_lit), "apart_m": float(round.apart_m), "status": str(round.status), "says": str(round.says)})
		_save()
		# the light follows the feet
		await _go(work.field_point(3.6, 5.6))
		await _go(work.field_point(3.6, -6.4))
		await _press("worn")
		var follows: Dictionary = work.state()
		await _shot(work.field_point(0.4, -8.2) + Vector3(0, 2.6, 0), work.field_point(-0.6, 1.0), "worn.png")
		checks.append({"check": "LIGHT WHAT WAS WORN: the strip lies on the worn path", "ok": str(follows.lit) == "worn" and is_equal_approx(float(follows.strip_x), -1.25) and int(follows.wear_total) > 0, "strip_x": float(follows.strip_x)})
		_save()
		await _press("sweep")
		var swept: Dictionary = work.state()
		checks.append({"check": "SWEEP: nothing is worn, the light stays", "ok": int(swept.wear_total) == 0 and int(swept.crossings) == 0 and is_equal_approx(float(swept.strip_x), -1.25) and str(swept.says) == "nothing is worn yet"})
		_save()
		await _press("gap")
		result["left_as"] = str(work.state().lit)
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok) and str(result["left_as"]) == "gap"
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[worn_path_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
