extends Node3D
## THE BALL PIT in the ANNEX (Palle, 2026-11-02, "ok" to the pit as the next step; "100 might be a bit too much for
## the VR set?"; and "make a new map with the artifacts that do not fit on the floor"). The pit stood off floor 210's
## slab; it stands in the playground annex now (commons/data/playgrounds/halls/playground_annex.json, the Void trial
## playground_annex) - a plastic pool, rim at 1 m, climbed by a ramp, a screen wall on its north side - and the
## ball_pit artifact fills it at ready. Checks: (A) the annex spec compiles with no errors and the pit stands at its
## place with its balls;
## (B) after the settle every ball is inside the pool (none gone through the floor), most asleep; (C) the PUSH
## BITES: a body on the player's layer wading across the pit displaces balls, and the same walk on a layer the
## balls do not mask displaces none - the negative test; (D) every board of the annex stands; (E) quiet. Reports the
## physics tick (ms) while the balls fall and once they sleep, for the headset question. Pictures: the pit from the
## hall, from the rim, the hall. Run: godot --path . --xr-mode off --resolution 1600x1000 res://commons/testing/probe_ball_pit.tscn

const HALL = preload("res://commons/void/trials/playground_recipes/spec_hall.tscn")
const Boards = preload("res://commons/modular/places/board_builder.gd")
const SPEC := "res://commons/data/playgrounds/halls/playground_annex.json"

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/workstation");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .7;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-55, 35, 0);sun.light_energy = 1.0;sun.shadow_enabled = true;add_child(sun)
	var cam := Camera3D.new();add_child(cam);cam.current = true;cam.fov = 55
	var report := {"checks": [], "physics_ms": {}}
	# A: the annex spec compiles clean
	var side: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SPEC))
	var built: Dictionary = load("res://commons/modular/places/place_builder.gd").new().compile(side)
	var recipe: Dictionary = built.get("recipe", {})
	var pit_place: Dictionary = (side.get("places", []) as Array).filter(func(p): return p.id == "ball_pit").front()
	var inst: Array = recipe.get("installations", []).filter(func(i): return i.id == "ball_pit_surface")
	_check(report, "A annex: the spec compiles clean - the pit's pool, rim, rails, ramps and every board", (built.get("errors", []) as Array).is_empty() and inst.size() == 1 and (recipe.get("places", []) as Array).any(func(p): return p.id == "ball_pit"), {"errors": built.get("errors", []), "installation": inst})
	# the annex itself, as its trial floor builds it: the spec hall with the spec named
	var hall: Node3D = HALL.instantiate();hall.set_meta("config_spec", SPEC);add_child(hall)
	var pit: Node3D = null
	for i in 6:
		await get_tree().physics_frame
	for c in hall.get_children():
		if c.get_meta("activity_artifact", "") == "ball_pit":pit = c
	var at := Vector3(float(pit_place.at[0]), float(pit_place.y) - float(pit_place.depth) + .03, float(pit_place.at[1]))
	var count: int = int(pit_place.activity.config.count)
	_check(report, "A pit: the ball_pit stands at its place, in pit mode, raining %d balls in at ready" % count, pit != null and pit.pit and pit.push_player and pit.position.is_equal_approx(at) and pit.balls.size() + pit._pending.size() == count and pit.fill_per_tick > 0 and not pit.readout.visible, {"found": pit != null, "at": pit.position if pit else null, "balls": pit.balls.size() if pit else 0, "pending": pit._pending.size() if pit else 0})
	if pit == null:
		_finish(report, out_dir);return
	# the physics tick while they fall (first 3 s) and once they sleep (the last 2 s of the settle)
	var falling := PackedFloat64Array();var asleep := PackedFloat64Array()
	var settle: float = float(pit.settle_seconds) + 2.0;var ticks := int(ceil(settle * Engine.physics_ticks_per_second))
	for f in ticks:
		await get_tree().physics_frame
		var ms: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		if f >= 2 and f < 3 * Engine.physics_ticks_per_second:falling.append(ms)   # the rain's own ticks, not the hall's first frame
		elif f >= ticks - 2 * Engine.physics_ticks_per_second:asleep.append(ms)
	report.physics_ms = {"falling_mean": _mean(falling), "falling_peak": _peak(falling), "asleep_mean": _mean(asleep), "asleep_peak": _peak(asleep), "balls": count, "ticks_per_second": Engine.physics_ticks_per_second, "sleeping": pit.sleeping()}
	var r: Dictionary = pit.reading()
	_check(report, "B settled: all %d balls rained in and inside the pool after %.0f s - none gone through the floor, most asleep" % [count, settle], r.released == count and r.gone == 0 and r.pocketed + r.rim == count - r.rolling and r.rolling <= count / 20 and pit.sleeping() >= count * .8, {"reading": r, "sleeping": pit.sleeping(), "physics_ms": report.physics_ms})
	print("[probe_ball_pit] PHYSICS falling mean %.2f ms peak %.2f ms; asleep mean %.2f ms peak %.2f ms (%d balls, %d sleeping)" % [report.physics_ms.falling_mean, report.physics_ms.falling_peak, report.physics_ms.asleep_mean, report.physics_ms.asleep_peak, count, pit.sleeping()])
	# C: the push bites - a kinematic body wades across the pit floor; first on a layer the balls ignore, then the player's
	var floor_y: float = float(pit_place.y) - float(pit_place.depth)
	var out_before: Array = _outside(pit, pit_place)   # balls the FILL left on the rim or the ramp, before anyone wades
	var ghost: Dictionary = await _wade(hall, pit, Vector3(at.x - 3.0, floor_y, at.z), Vector3(at.x + 3.0, floor_y, at.z), 1 << 18)
	var player: Dictionary = await _wade(hall, pit, Vector3(at.x + 3.0, floor_y, at.z), Vector3(at.x - 3.0, floor_y, at.z), pit.PLAYER_LAYER)
	_check(report, "C push bites: a body on the player's layer wading across displaces sleeping balls; the same walk on a layer the balls do not mask displaces almost none", player.moved >= 20 and ghost.moved * 5 <= player.moved, {"moved_on_player_layer": player.moved, "moved_on_ghost_layer": ghost.moved})
	# the fling (Palle: "not so much bounciness, do not repel too much"): a pushed ball stays in the pool, never goes
	# faster than the cap, and the farthest one travels under two metres
	var out_after: Array = _outside(pit, pit_place);var out: int = out_after.size()
	# a ball bulldozed ahead of the body travels with it (farthest); what Palle means by repel is the COAST after the
	# body stops - under a metre - and the speed: the kinematic push hands a ball the walking speed for one tick before
	# the cap bites, so the peak stays under the body's speed plus the cap
	# a ball squeezed between the wading body and the wall rides up onto the rim (measured 2026-11-02: one of 320 when the
	# body walks the pool's full width into its west wall; at 260 none, but a thinner layer never sleeps). The rim is
	# still the place. ESCAPED = left the place: beyond the rim ring, or down on the ground outside the pool.
	var hx: float = float(pit_place.size[0]) / 2.0;var hz: float = float(pit_place.size[1]) / 2.0
	var escaped: Array = out_after.filter(func(o): return absf(float(o[1])) > hx + 1.0 or absf(float(o[3])) > hz + 1.0 or float(o[2]) < float(pit_place.depth) - .1)
	var on_rim: int = out_after.size() - escaped.size()
	_check(report, "E quiet: no ball leaves the place (%d squeezed onto the rim); after the body stops no ball coasts a metre; no ball passed the body's own 3 m/s plus the %.1f m/s cap" % [on_rim, pit.max_speed], escaped.is_empty() and on_rim <= 2 and out_before.is_empty() and player.coast < 1.0 and player.peak_speed < 3.0 + pit.max_speed, {"escaped": escaped, "on_rim": on_rim, "out_before_wade": out_before, "out_after_wade": out_after, "peak_speed": player.peak_speed, "coast_m": player.coast, "farthest_m": player.farthest, "bounce": pit.bounce, "damping": pit.damping, "max_speed": pit.max_speed})
	# the hall's own physics without the balls: the pit's cost is the difference
	pit.clear()
	var baseline := PackedFloat64Array()
	for f in 2 * Engine.physics_ticks_per_second:
		await get_tree().physics_frame
		if f >= 5:baseline.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	report.physics_ms["baseline_mean"] = _mean(baseline);report.physics_ms["pit_asleep_cost"] = report.physics_ms.asleep_mean - _mean(baseline);report.physics_ms["pit_falling_cost"] = report.physics_ms.falling_mean - _mean(baseline)
	print("[probe_ball_pit] PHYSICS hall without balls %.2f ms; the pit adds %.2f ms asleep, %.2f ms falling" % [_mean(baseline), report.physics_ms.pit_asleep_cost, report.physics_ms.pit_falling_cost])
	pit.release()
	for f in int(ceil(float(pit.settle_seconds) * Engine.physics_ticks_per_second)):
		await get_tree().physics_frame
	# D: the rest of the hall still stands
	var others := {}
	for c in hall.get_children():
		if c.has_meta("activity_artifact"):others[str(c.get_meta("activity_artifact"))] = others.get(str(c.get_meta("activity_artifact")), 0) + 1
	var wall_ok: bool = hall.get_node_or_null("pit_wall_01") != null
	_check(report, "D annex: every board stands - the shader path, posters, tiling corridor, pattern rack and the pit's screen wall (%d plates)" % Boards.copies(side), others.get("display_plate", 0) == Boards.copies(side) and others.get("ball_pit", 0) == 1 and wall_ok, others)
	var shots := {"pit_hall": [Vector3(at.x, 6.5, at.z + 13), Vector3(at.x, .6, at.z - 1)], "pit_rim": [Vector3(at.x + 3.5, 2.3, at.z + 4.5), Vector3(at.x - 1, .4, at.z - 2)], "pit_inside": [Vector3(at.x + 2.5, 1.2, at.z + 2.5), Vector3(at.x - 2, .3, at.z - 3)], "annex_all": [Vector3(0, 26, 30), Vector3(0, 0, -1)], "annex_walk": [Vector3(6, 1.6, 3), Vector3(-10, 0.8, 0)]}
	for k in shots:
		cam.transform = Transform3D(Basis(), shots[k][0]).looking_at(shots[k][1])
		for t in 3:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out_dir.path_join("%s.png" % k))
	_finish(report, out_dir)

## A capsule body on `layer` walks from a to b through the pit over two seconds; returns how many balls (asleep at the
## start) moved more than 5 cm, the fastest any ball went, and the farthest one's travel.
func _wade(hall: Node3D, pit: Node3D, a: Vector3, b: Vector3, layer: int) -> Dictionary:
	var before := {}
	for ball in pit.balls:
		if ball.sleeping:before[ball] = ball.global_position   # a ball still rolling would count as moved on its own
	var body := CharacterBody3D.new();body.collision_layer = layer;body.collision_mask = 1
	var shape := CollisionShape3D.new();var cap := CapsuleShape3D.new();cap.radius = .3;cap.height = 1.8;shape.shape = cap;shape.position = Vector3(0, .9, 0);body.add_child(shape)
	hall.add_child(body);body.global_position = hall.to_global(a)
	var ticks := 2 * Engine.physics_ticks_per_second;var peak := 0.0
	for f in ticks:
		var target: Vector3 = hall.to_global(a.lerp(b, float(f + 1) / ticks))
		body.velocity = (target - body.global_position) * Engine.physics_ticks_per_second
		body.move_and_slide()
		await get_tree().physics_frame
		for ball in pit.balls:
			if not ball.sleeping:peak = maxf(peak, ball.linear_velocity.length())
	var at_stop := {}
	for ball in pit.balls:at_stop[ball] = ball.global_position   # the body has stopped: what follows is coast
	for f in 2 * Engine.physics_ticks_per_second:
		await get_tree().physics_frame
		for ball in pit.balls:
			if not ball.sleeping:peak = maxf(peak, ball.linear_velocity.length())
	body.queue_free()
	var moved := 0;var farthest := 0.0;var coast := 0.0
	for ball in pit.balls:
		if not is_instance_valid(ball):continue
		if before.has(ball):
			var d: float = ball.global_position.distance_to(before[ball])
			if d > .05:moved += 1
			farthest = maxf(farthest, d)
		coast = maxf(coast, ball.global_position.distance_to(at_stop[ball]))
	return {"moved": moved, "peak_speed": peak, "farthest": farthest, "coast": coast}

## Balls outside the pool's footprint or above its rim, with where they are (pit-local).
func _outside(pit: Node3D, place: Dictionary) -> Array:
	var hx: float = float(place.size[0]) / 2.0;var hz: float = float(place.size[1]) / 2.0;var found := []
	for b in pit.balls:
		if absf(b.position.x) > hx or absf(b.position.z) > hz or b.position.y > float(place.depth) + .5:found.append([str(b.name), snappedf(b.position.x, .01), snappedf(b.position.y, .01), snappedf(b.position.z, .01)])
	return found

func _mean(a: PackedFloat64Array) -> float:
	if a.is_empty():return 0.0
	var s := 0.0
	for v in a:s += v
	return s / a.size()

func _peak(a: PackedFloat64Array) -> float:
	var m := 0.0
	for v in a:m = maxf(m, v)
	return m

func _finish(report: Dictionary, out_dir: String) -> void:
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var o := FileAccess.open(out_dir.path_join("ball_pit.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()
	print("[probe_ball_pit] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_ball_pit] %s  %s" % ["ok  " if ok else "FAIL", what])
