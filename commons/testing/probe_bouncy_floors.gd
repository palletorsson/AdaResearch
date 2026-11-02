extends Node3D
## THE BOUNCY FLOORS (Palle, 2026-11-02: "the material should be bouncy ... do the bouncy version with the 4 m
## ceiling"). The mosaic field (Mosaic_Pompeii_Floors.json, boards "bounce": {1.2, 2 m/s, 4 m}) gives every floor's
## walk body an XR Tools GroundPhysics with bounciness 1.2 and threshold 2 m/s, a bounce_ceiling of 4 m and no jump of
## its own. Checks: (A) all 46 carry it, the XR rule the headset uses returns it, and the hall has a BounceCeiling;
## (B) the XR ceiling: a body thrown up at 12 m/s off a floor is capped at sqrt(2 g 4), off the plain ground it is
## not (negative); (C) the desktop walker on a mosaic floor jumps its ordinary metre and then climbs bounce by bounce
## to 4 m and no higher; (D) the same jump on the plain ground beside the field does not bounce (negative);
## (E) walking from the ground onto the field gets on and does not bounce. Writes ada_run/workstation/bouncy_floors.json.
## Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_bouncy_floors.tscn

const HALL = preload("res://commons/void/trials/playground_recipes/spec_hall.tscn")
const SPEC := "res://commons/data/playgrounds/maps/Mosaic_Pompeii_Floors.json"
const Walker = preload("res://commons/void/walker.gd")
const Ceiling = preload("res://commons/modular/places/bounce_ceiling.gd")
var report := {"checks": []}

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/workstation");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33");env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-50, 35, 0);add_child(sun)
	var ground := StaticBody3D.new();ground.name = "PlainGround";var gs := CollisionShape3D.new();var gb := BoxShape3D.new();gb.size = Vector3(80, .2, 60);gs.shape = gb;gs.position.y = -.1;ground.add_child(gs);add_child(ground)
	var hall: Node3D = HALL.instantiate();hall.set_meta("config_spec", SPEC);add_child(hall)
	for i in 8:
		await get_tree().physics_frame
	var g := float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8));var vmax := sqrt(2.0 * g * 4.0)
	# A - the material
	var defaults := XRToolsGroundPhysicsSettings.new();defaults.jump_velocity = 4.6
	var bodies := 0;var bouncy := 0;var sample: StaticBody3D = null
	for c in hall.get_children():
		if c is StaticBody3D and str(c.get_meta("walk_of", "")).begins_with("field_"):
			bodies += 1;sample = c
			var gp: Node = c.get_node_or_null("GroundPhysics")
			if gp == null:continue
			var b := XRToolsGroundPhysicsSettings.get_bounciness(gp.physics, defaults);var t := XRToolsGroundPhysicsSettings.get_bounce_threshold(gp.physics, defaults)
			var j := XRToolsGroundPhysicsSettings.get_jump_velocity(gp.physics, defaults)
			if is_equal_approx(b, 1.2) and is_equal_approx(t, 2.0) and is_equal_approx(j, 4.6) and is_equal_approx(float(c.get_meta("bounce_ceiling", 0.0)), 4.0):bouncy += 1
	_check("A material: %d of %d mosaic floors are bouncy (1.2, from 2 m/s, ceiling 4 m) with the ordinary jump; the hall has a BounceCeiling" % [bouncy, bodies], bodies == 46 and bouncy == 46 and hall.get_node_or_null("BounceCeiling") != null, {"bodies": bodies, "bouncy": bouncy})
	# B - the XR ceiling rule (the headset's body bounces in XR Tools; the cap is ours)
	var fake := CharacterBody3D.new();add_child(fake)
	fake.velocity = Vector3(0, 12, 0);Ceiling.cap(fake, sample);var capped := fake.velocity.y
	fake.velocity = Vector3(0, 12, 0);Ceiling.cap(fake, ground);var uncapped := fake.velocity.y
	fake.queue_free()
	_check("B XR ceiling: a rise of 12 m/s off a mosaic floor is capped at %.2f m/s (4 m); off the plain ground it stays 12" % capped, absf(capped - vmax) < .01 and is_equal_approx(uncapped, 12.0), {"capped": capped, "uncapped": uncapped, "vmax": vmax})
	# C, D - the desktop walker
	var walker: CharacterBody3D = Walker.new();walker.scripted_input = true;add_child(walker)
	var climb: Array = await _bounces(walker, Vector3(-21.3, .095, -3.3), 9.0)
	var flat: Array = await _bounces(walker, Vector3(0, .02, -7.0), 4.0)
	var rising: bool = climb.size() >= 4 and absf(float(climb[0]) - 1.0) < .25 and float(climb[1]) > float(climb[0]) + .4 and float(climb[2]) > float(climb[1]) + .4
	var top: float = climb.max() if not climb.is_empty() else 0.0
	_check("C climb: on a mosaic floor the walker's jump rises %s m - a metre, then higher bounce by bounce, to %.2f m and no higher" % [str(climb.slice(0, 6).map(func(v): return snappedf(v, .01))), top], rising and top > 3.7 and top < 4.2, {"apexes": climb})
	_check("D plain ground: the same jump beside the field rises %.2f m and does not bounce (%d apexes)" % [float(flat[0]) if not flat.is_empty() else 0.0, flat.size()], flat.size() == 1 and float(flat[0]) > .7 and float(flat[0]) < 1.5, {"apexes": flat})
	# E - walking on: from the ground across the field's edge, no jump pressed
	walker.velocity = Vector3.ZERO;walker.global_position = Vector3(2, .02, -7.5)
	for i in 30:
		await get_tree().physics_frame
	var y0 := walker.global_position.y;var highest := y0
	walker.drive = Vector2(0, 1)   # +z, onto the field
	for i in 150:
		await get_tree().physics_frame
		highest = maxf(highest, walker.global_position.y)
	walker.drive = Vector2.ZERO
	var on_field: bool = walker.global_position.z > -5.0 and absf(walker.global_position.y - .085) < .05
	_check("E walking on: from the ground onto the field the walker reaches z %.2f at height %.3f, rising at most %.2f m - no bounce" % [walker.global_position.z, walker.global_position.y, highest - y0], on_field and highest - y0 < .2, {"end": [walker.global_position.x, walker.global_position.y, walker.global_position.z], "rise": highest - y0})
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var f := FileAccess.open(out_dir.path_join("bouncy_floors.json"), FileAccess.WRITE);f.store_string(JSON.stringify(report, "  "));f.close()
	print("[probe_bouncy_floors] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

## Stand the walker at `at`, let it settle, jump once; return the height of each apex above the start, for `seconds`.
func _bounces(walker: CharacterBody3D, at: Vector3, seconds: float) -> Array:
	walker.velocity = Vector3.ZERO;walker.global_position = at
	for i in 30:
		await get_tree().physics_frame
	var start := walker.global_position.y;var apexes := [];var last_y := start;var rising := false
	walker.jump_queued = true
	for i in int(seconds * Engine.physics_ticks_per_second):
		await get_tree().physics_frame
		var y := walker.global_position.y
		if y > last_y + .0005:rising = true
		elif rising and y < last_y - .0005:
			if last_y - start > .1:apexes.append(last_y - start)
			rising = false
		last_y = y
	return apexes

func _check(what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_bouncy_floors] %s  %s" % ["ok  " if ok else "FAIL", what])
