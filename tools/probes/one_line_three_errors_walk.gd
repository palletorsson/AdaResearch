extends SceneTree
## ONE LINE, THREE ERRORS on its floor (ML_Gradient_Landscape; the pass, 2026-11-16)
## A floor of candidate lines; where a body stands is a plank among five posts; three arrows at the feet. Read in
## the running tower with its own walker:
##   at rest: the outlier off, the step short, the ball at the tutorial's start; squared 1.77 and Huber 0.68 as
##     the bench has them; the squared and the Huber short step land better;
##   the walker stands on the line the five observations lie on: squared and Huber read next to nothing and
##     their arrows are under ten centimetres; the wavy rule still sends it on; the plank passes through the
##     five balls;
##   OUTLIER: the fifth ball is lifted; at the same place the squared arrow is some eight times Huber's, the
##     same way;
##   following the squared arrow until it is gone, then Huber's from the same place: two resting places, about a
##     metre apart on the floor, where the bench has them;
##   OUTLIER again, then STEP: long; far out, the squared step lands worse and Huber's lands better, and the
##     stand says the two decisions are separate;
##   STEP again: short;
##   the axes: `outlier` on lifts the fifth; `step` long lengthens the arrows; both restore.
##
##   godot --path <stage> --script res://tools/probes/one_line_three_errors_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## errors.json: checks with what was read (written after every check). arrival.png, approach.png, clean.png,
## outlier.png, long.png, above.png.
const ID := "one-line-three-errors"
var game: Node3D
var body: CharacterBody3D
var work: Node3D
var eye: SubViewport
var cam: Camera3D
var folder := ""
var result := {}
var level := 0.0


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("errors.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()


func _shot(at: Vector3, target: Vector3, name: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 12: await physics_frame
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	eye.get_texture().get_image().save_png(folder.path_join(name))


func _go(target: Vector3, ticks: int = 1200) -> void:
	for i in ticks:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.07: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -(0.5 if d > 0.5 else 0.25))
		await physics_frame
	body.drive = Vector2.ZERO


func _at(x: float, z: float) -> Vector3:
	return work.local_point(x, z)


func _stand(slope: float, intercept: float) -> Dictionary:
	await _go(work.line_point(slope, intercept))
	for i in 20: await physics_frame
	return work.state()


func _press(key: String) -> Dictionary:
	await _go(_at(0.0, 3.2))
	await _go(work.plate_point(key))
	for i in 90: await physics_frame
	return work.state()


## Walk along one rule's arrow until it is gone; where the walker then stands, as a line.
func _follow(rule: String) -> Array:
	var st: Dictionary = work.state()
	for n in 90:
		st = work.state()
		var long: float = float(st.rules[rule].long_units)
		if long < 0.03: break
		var q := Vector2(float(st.q[0]), float(st.q[1]))
		var on: Vector2 = q + (Vector2(float(st.rules[rule].to[0]), float(st.rules[rule].to[1])) - q).normalized() * clampf(long, 0.08, 0.5)
		await _go(work.line_point(on.x, on.y))
		for i in 6: await physics_frame
	return [float(st.q[0]), float(st.q[1])]


func _near(a: float, b: float, by: float) -> bool:
	return absf(a - b) < by


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
	if work != null and work.has_method("line_point"):
		for i in 200: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		body = game.body
		eye = SubViewport.new()
		eye.size = Vector2i(1280, 800)
		eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(eye)
		cam = Camera3D.new()
		cam.fov = 80
		eye.add_child(cam)
		cam.current = true
		game.place_player(Vector3(13.5, level + 0.3, 7.6))
		for i in 30: await physics_frame
		await _shot(Vector3(0, level + 1.65, 7.8), Vector3(0, level + 1.5, 0), "arrival.png")
		await _shot(_at(0.0, 4.4) + Vector3(0, 1.65, 0), _at(0.0, -3.1) + Vector3(0, 1.9, 0), "approach.png")
		work.apply_grid_config({"outlier": "on", "step": "long"})
		work.apply_grid_config({"outlier": "off", "step": "short"})
		var s: Dictionary = work.state()
		checks.append({"check": "at rest: the outlier off, the step short, the ball at the tutorial's start; squared 1.77 and Huber 0.68 as the bench has them; the squared and the Huber short step land better",
			"ok": str(s.outlier) == "off" and str(s.step) == "short" and str(s.who) == "example" and _near(float(s.rules.squared.error), 1.765, 0.005) and _near(float(s.rules.huber.error), 0.683, 0.005)
			and bool(s.rules.squared.better) and bool(s.rules.huber.better),
			"errors": [snappedf(float(s.rules.squared.error), 0.001), snappedf(float(s.rules.huber.error), 0.001), snappedf(float(s.rules.wavy.error), 0.001)], "wavy_short_step_better": bool(s.rules.wavy.better), "build_ms": int(s.build_ms)})
		_save()
		game.place_player(_at(0.0, 3.0) + Vector3(0, 0.3, 0))
		for i in 30: await physics_frame
		var clean: Dictionary = await _stand(0.5, 0.2)
		await _shot(_at(-0.45, 3.9) + Vector3(0, 2.6, 0), _at(-0.2, -3.1) + Vector3(0, 1.6, 0), "clean.png")
		checks.append({"check": "the walker stands on the line the five observations lie on: squared and Huber read next to nothing and their arrows are under ten centimetres; the wavy rule still sends it on; the plank passes through the five balls",
			"ok": str(clean.who) == "visitor" and float(clean.rules.squared.error) < 0.02 and float(clean.rules.huber.error) < 0.01 and float(clean.rules.squared.long_units) < 0.06 and float(clean.rules.huber.long_units) < 0.06
			and float(clean.rules.wavy.long_units) > 0.5 and _near(float(clean.plank_tilt_deg), rad_to_deg(atan(0.6 * 0.5 / 2.0)), 1.2) and _near(float(clean.plank_high_m), 0.9 + 0.6 * 0.2, 0.05),
			"q": [snappedf(float(clean.q[0]), 0.01), snappedf(float(clean.q[1]), 0.01)], "squared": snappedf(float(clean.rules.squared.error), 0.0001), "wavy_arrow_units": snappedf(float(clean.rules.wavy.long_units), 0.01)})
		_save()
		var pressed: Dictionary = await _press("outlier")
		var pulled: Dictionary = await _stand(0.5, 0.2)
		var ratio: float = float(pulled.rules.squared.long_units) / maxf(float(pulled.rules.huber.long_units), 0.0001)
		checks.append({"check": "OUTLIER: the fifth ball is lifted; at the same place the squared arrow is some eight times Huber's, the same way", "ok": str(pressed.outlier) == "on" and _near(float(pressed.fifth_high_m), 0.9 + 0.6 * 4.7, 0.01)
			and ratio > 5.0 and ratio < 12.0 and absf(angle_difference(deg_to_rad(float(pulled.rules.squared.heading_deg)), deg_to_rad(float(pulled.rules.huber.heading_deg)))) < 0.2 and str(pulled.status).contains("NO RULE OF ERROR CAN ANSWER THAT"),
			"fifth_high_m": snappedf(float(pressed.fifth_high_m), 0.01), "squared_over_huber": snappedf(ratio, 0.1), "status": str(pulled.status)})
		_save()
		var squared_rest: Array = await _follow("squared")
		await _shot(_at(1.2, 3.9) + Vector3(0, 2.8, 0), _at(0.6, -3.1) + Vector3(0, 2.0, 0), "outlier.png")
		await _stand(0.5, 0.2)
		var huber_rest: Array = await _follow("huber")
		var apart: float = Vector2(squared_rest[0] - huber_rest[0], squared_rest[1] - huber_rest[1]).length() * 1.5
		checks.append({"check": "following the squared arrow until it is gone, then Huber's from the same place: two resting places, about a metre apart on the floor, where the bench has them",
			"ok": _near(squared_rest[0], 2.1, 0.2) and _near(squared_rest[1], 1.0, 0.15) and _near(huber_rest[0], 1.5, 0.25) and _near(huber_rest[1], 0.7, 0.2) and apart > 0.5 and apart < 1.5,
			"squared_rests_at": [snappedf(squared_rest[0], 0.01), snappedf(squared_rest[1], 0.01)], "huber_rests_at": [snappedf(huber_rest[0], 0.01), snappedf(huber_rest[1], 0.01)], "apart_m": snappedf(apart, 0.01)})
		_save()
		await _press("outlier")
		var long: Dictionary = await _press("step")
		var far: Dictionary = await _stand(2.6, 2.0)
		await _shot(_at(0.4, 4.1) + Vector3(0, 3.2, 0), _at(1.0, -2.6) + Vector3(0, 1.4, 0), "long.png")
		checks.append({"check": "OUTLIER again, then STEP: long; far out, the squared step lands worse and Huber's lands better, and the stand says the two decisions are separate",
			"ok": str(long.outlier) == "off" and str(long.step) == "long" and not bool(far.rules.squared.better) and bool(far.rules.huber.better) and str(far.status).contains("SEPARATE DECISIONS"),
			"squared": [snappedf(float(far.rules.squared.error), 0.01), snappedf(float(far.rules.squared.after), 0.01)], "huber": [snappedf(float(far.rules.huber.error), 0.01), snappedf(float(far.rules.huber.after), 0.01)], "status": str(far.status)})
		_save()
		var short: Dictionary = await _press("step")
		checks.append({"check": "STEP again: short", "ok": str(short.step) == "short" and str(short.outlier) == "off"})
		_save()
		game.place_player(Vector3(13.5, level + 0.3, 7.6))
		for i in 30: await physics_frame
		await _shot(_at(3.6, 4.6) + Vector3(0, 4.8, 0), _at(-0.4, -1.4) + Vector3(0, 0.8, 0), "above.png")
		var rest: Dictionary = work.state()
		work.apply_grid_config({"outlier": "on"})
		var a: Dictionary = work.state()
		work.apply_grid_config({"outlier": "off", "step": "long"})
		var b: Dictionary = work.state()
		work.apply_grid_config({"step": "short"})
		var c: Dictionary = work.state()
		checks.append({"check": "the axes: `outlier` on lifts the fifth; `step` long lengthens the arrows; both restore", "ok": float(a.fifth_high_m) > float(rest.fifth_high_m) + 2.0
			and _near(float(b.rules.squared.long_units), 2.4 * float(rest.rules.squared.long_units), 0.01) and _near(float(c.rules.squared.long_units), float(rest.rules.squared.long_units), 0.001) and _near(float(c.fifth_high_m), float(rest.fifth_high_m), 0.001)})
		_save()
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[one_line_three_errors_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
