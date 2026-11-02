extends Node3D
## THE SUPER JUMP (Palle, 2026-11-02: "when we jump on these surfaces we should super jump, like 4 metres up in the
## air"). The mosaic field (commons/data/playgrounds/maps/Mosaic_Pompeii_Floors.json, boards "jump": 4) gives every
## mosaic floor's walk body an XR Tools GroundPhysics whose jump velocity throws 4 m. Checks: (A) every field walk
## body carries it, and the XR Tools rule the headset uses (XRToolsGroundPhysicsSettings.get_jump_velocity) returns
## sqrt(2 g 4); (B) the desktop walker, standing on a mosaic floor, jumps 4 m (within 0.3); (C) the same walker on
## the plain ground beside the field jumps its ordinary metre (negative). Writes ada_run/workstation/super_jump.json.
## Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_super_jump.tscn

const HALL = preload("res://commons/void/trials/playground_recipes/spec_hall.tscn")
const SPEC := "res://commons/data/playgrounds/maps/Mosaic_Pompeii_Floors.json"
const Walker = preload("res://commons/void/walker.gd")
var report := {"checks": []}

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/workstation");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33");env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-50, 35, 0);add_child(sun)
	var ground := StaticBody3D.new();var gs := CollisionShape3D.new();var gb := BoxShape3D.new();gb.size = Vector3(80, .2, 60);gs.shape = gb;gs.position.y = -.1;ground.add_child(gs);add_child(ground)
	var hall: Node3D = HALL.instantiate();hall.set_meta("config_spec", SPEC);add_child(hall)
	for i in 8:
		await get_tree().physics_frame
	# A - the surfaces carry the jump, and the headset's rule reads it
	var g := float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8));var want := sqrt(2.0 * g * 4.0)
	var bodies := 0;var carrying := 0;var xr_v := 0.0
	var default_settings := XRToolsGroundPhysicsSettings.new();default_settings.jump_velocity = 4.6
	for c in hall.get_children():
		if c is StaticBody3D and c.has_meta("walk_of") and str(c.get_meta("walk_of")).begins_with("field_"):
			bodies += 1
			var gp: Node = c.get_node_or_null("GroundPhysics")
			if gp != null:
				var v := XRToolsGroundPhysicsSettings.get_jump_velocity(gp.physics, default_settings)
				if absf(v - want) < .01:carrying += 1
				xr_v = v
	_check("A surfaces: %d of %d mosaic floors carry a GroundPhysics jump of %.2f m/s, which the XR body's rule returns (sqrt(2 g 4) = %.2f)" % [carrying, bodies, xr_v, want], bodies == 46 and carrying == 46, {"bodies": bodies, "carrying": carrying, "xr_velocity": xr_v, "want": want})
	# B, C - the desktop walker
	var walker: CharacterBody3D = Walker.new();walker.scripted_input = true;add_child(walker)
	var on_mosaic: float = await _jump(walker, Vector3(-21.3, .4, -3.3))
	var on_ground: float = await _jump(walker, Vector3(0, .4, -7.0))
	_check("B super jump: the walker standing on a mosaic floor rises %.2f m" % on_mosaic, absf(on_mosaic - 4.0) < .3, {"apex": on_mosaic})
	_check("C plain ground: the same walker beside the field rises %.2f m - the jump is the surface's" % on_ground, on_ground > .7 and on_ground < 1.5, {"apex": on_ground})
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var f := FileAccess.open(out_dir.path_join("super_jump.json"), FileAccess.WRITE);f.store_string(JSON.stringify(report, "  "));f.close()
	print("[probe_super_jump] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

## Stand the walker at `at`, let it settle on what is under it, jump once, return how far its feet rose.
func _jump(walker: CharacterBody3D, at: Vector3) -> float:
	walker.velocity = Vector3.ZERO;walker.global_position = at
	for i in 40:
		await get_tree().physics_frame
	var start := walker.global_position.y;var top := start
	walker.jump_queued = true
	for i in 150:
		await get_tree().physics_frame
		top = maxf(top, walker.global_position.y)
	return top - start

func _check(what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_super_jump] %s  %s" % ["ok  " if ok else "FAIL", what])
