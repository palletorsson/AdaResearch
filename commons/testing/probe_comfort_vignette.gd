extends Node3D
## THE COMFORT VIGNETTE on the real museum rig (commons/player/museum_rig.tscn - the museum's and the Void's), with
## the XR Tools player body doing the moving, on the mosaic field and the plain ground beside it. Palle, 2026-11-02:
## "a dynamic vignette ... on jump it should be instant ... a general feature". Checks:
##   A rest     - the rig carries XRCamera3D/ComfortVignette, it found the body, and standing still it is open.
##   B jump     - a jump closes it within two physics frames, it stays closed through the apex, holds after the
##                landing and is open again within a second.
##   C bounce   - on a mosaic floor the XR body, standing still, bounces up toward the 4 m ceiling (XR Tools' rule,
##                completed by BounceCeiling - XR Tools alone lands dead unless the stick is held), and the
##                vignette stays closed through every touchdown - no flicker between bounces.
##   D walk     - stick walking at 3 m/s eases in (nearly open after 0.1 s), settles gently, never as far as a jump,
##                and opens after the stop; with walk_delay 2 (Palle's version) nothing shows before 2 s.
##   E turn     - a snap turn does not close it (negative); a smooth turn closes it at once.
##   F head     - moving the head (the camera) by hand, 0.6 m sideways and a crouch, does not close it (negative).
##   G teleport - a teleport with a quarter turn does not close it (negative).
##   H off      - strength 0 keeps it open through a jump.
## Pictures from the headset camera: at rest, walking, mid-jump. ada_run/workstation/comfort_vignette.json.
## Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_comfort_vignette.tscn

const Rig = preload("res://commons/player/museum_rig.tscn")
const HALL = preload("res://commons/void/trials/playground_recipes/spec_hall.tscn")
const SPEC := "res://commons/data/playgrounds/maps/Mosaic_Pompeii_Floors.json"
const Ground = preload("res://addons/godot-xr-tools/overrides/ground_physics_settings.gd")

## A scripted thumbstick: walking speed forward, and a jump request on the next physics step.
class Stick extends XRToolsMovementProvider:
	var forward := 0.0
	var jump := false
	func physics_movement(_delta: float, player_body: XRToolsPlayerBody, _disabled: bool):
		player_body.ground_control_velocity = Vector2(0, forward)
		if jump:
			jump = false
			player_body.request_jump()

var report := {"checks": []}
var out_dir := ""
var rig: XROrigin3D
var body: XRToolsPlayerBody
var cam: XRCamera3D
var vig: Node3D
var stick: Stick

func _ready() -> void:
	out_dir = ProjectSettings.globalize_path("res://ada_run/workstation");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("8a9099")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .8;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-50, 35, 0);add_child(sun)
	var ground := StaticBody3D.new();ground.name = "PlainGround";var gs := CollisionShape3D.new();var gb := BoxShape3D.new();gb.size = Vector3(80, .2, 60);gs.shape = gb;gs.position.y = -.1;ground.add_child(gs)
	var gm := MeshInstance3D.new();var pm := PlaneMesh.new();pm.size = Vector2(80, 60);gm.mesh = pm;var gmat := StandardMaterial3D.new();gmat.albedo_color = Color("6d7178");gm.material_override = gmat;ground.add_child(gm);add_child(ground)
	var hall: Node3D = HALL.instantiate();hall.set_meta("config_spec", SPEC);add_child(hall)
	rig = Rig.instantiate();add_child(rig);rig.current = true
	body = rig.get_node("PlayerBody");cam = rig.get_node("XRCamera3D");cam.current = true
	var physics := Ground.new();physics.jump_velocity = 4.6;physics.move_traction = 30.0;physics.move_drag = 5.0;body.physics = physics
	body.add_to_group("player_body")   # the hall's BounceCeiling caps the XR bounce at 4 m
	stick = Stick.new();stick.name = "ProbeStick";rig.add_child(stick)
	body._movement_providers = [stick]
	vig = cam.get_node_or_null("ComfortVignette")
	await _place(Vector3(0, 0, -7.5), 0.0)
	await _seconds(1.0)
	# A - rest
	var found: bool = vig != null and vig.body == body and vig.origin == rig
	var rest_ok: bool = found and vig.closure == 0.0 and not vig.get_node("Ring").visible
	await _shoot("vignette_rest")
	_check("A rest: the rig carries XRCamera3D/ComfortVignette, bound to its PlayerBody, and standing still it is open", rest_ok, {"found": found, "closure": vig.closure if vig else -1.0})
	if vig == null:
		_finish();return
	# B - jump on the plain ground
	var jump := await _jump_trace(4.0)
	var b_ok: bool = jump.frames_to_close <= 2 and jump.air_min >= .5 and jump.hold_s >= .15 and jump.open_s > 0.0 and jump.open_s <= 1.0 and jump.apexes.size() == 1
	_check("B jump: closes %d physics frame(s) after the press, stays at least %.2f through the apex, holds %.2f s after landing and is open %.2f s after it" % [jump.frames_to_close, jump.air_min, jump.hold_s, jump.open_s], b_ok, jump)
	# C - bounce on a mosaic floor
	await _place(Vector3(-21.3, .1, -3.3), 0.0)
	await _seconds(1.0)
	var bounce := await _jump_trace(7.0, "vignette_jump", 4.0)
	var top: float = bounce.apexes.max() if not bounce.apexes.is_empty() else 0.0
	var c_ok: bool = bounce.apexes.size() >= 4 and float(bounce.apexes[1]) > float(bounce.apexes[0]) + .3 and top > 3.0 and top < 4.3 and bounce.touchdowns >= 3 and bounce.between_min >= .5
	_check("C bounce: the XR body bounces %s m (top %.2f) and through %d touchdowns the vignette never opens past %.2f" % [str(bounce.apexes.slice(0, 6)), top, bounce.touchdowns, bounce.between_min], c_ok, bounce)
	# G - from rest on the plain ground, a teleport with a quarter turn
	await _place(Vector3(-10, 0, -7.5), 0.0)
	await _seconds(1.5)
	var g_rest: float = vig.closure
	var g_max := await _teleport_trace(Vector3(-4, 0, -7.5), PI / 2)
	_check("G teleport: from rest (%.3f) a teleport with a quarter turn leaves it open (max closure %.3f)" % [g_rest, g_max], g_rest == 0.0 and g_max < .01, {"rest": g_rest, "max": g_max})
	await _place(Vector3(-10, 0, -7.5), -PI / 2)   # face +x along the clear strip at z -7.5
	await _seconds(1.5)
	# D - walk
	var walk := await _walk_trace(3.0, 3.0)
	var d_ok: bool = walk.at_0_1 < .1 and walk.at_1_5 > .15 and walk.peak <= vig.walk_max + .01 and walk.open_after_stop_s > 0.0 and walk.open_after_stop_s < 2.0 and walk.speed > 2.5
	await _place(Vector3(-10, 0, -7.5), -PI / 2)
	await _seconds(1.5)
	vig.walk_delay = 2.0
	var late := await _walk_trace(3.0, 3.0)
	vig.walk_delay = 0.0
	var late_ok: bool = late.at_1_9 < .01 and late.peak > .15
	_check("D walk: at 3 m/s it eases in (%.2f after 0.1 s, %.2f after 1.5 s, at most %.2f) and is open %.2f s after the stop; with walk_delay 2 it is %.3f at 1.9 s, then %.2f" % [walk.at_0_1, walk.at_1_5, walk.peak, walk.open_after_stop_s, late.at_1_9, late.peak], d_ok and late_ok, {"walk": walk, "delayed": late})
	# E - turns
	await _seconds(1.0)
	var snap_max := 0.0
	body.rotate_player(deg_to_rad(20.0))
	for i in 20:
		await get_tree().process_frame
		snap_max = maxf(snap_max, vig.closure)
	await _seconds(1.0)
	var smooth_max := 0.0;var smooth_frames := -1
	for i in 60:
		await get_tree().physics_frame
		body.rotate_player(2.0 / Engine.physics_ticks_per_second)
		await get_tree().process_frame
		smooth_max = maxf(smooth_max, vig.closure)
		if smooth_frames < 0 and vig.closure >= .5:smooth_frames = i + 1
	_check("E turn: a 20 degree snap turn leaves it at %.3f; a smooth turn at 2 rad/s closes it to %.2f within %d frame(s)" % [snap_max, smooth_max, smooth_frames], snap_max < .01 and smooth_max >= .6 and smooth_frames >= 1 and smooth_frames <= 3, {"snap": snap_max, "smooth": smooth_max, "frames": smooth_frames})
	await _seconds(1.5)
	# F - the head moves, the body does not
	var head_max := 0.0;var home := cam.position
	for i in 45:
		var t := float(i + 1) / 45.0
		cam.position = home + Vector3(0.6 * t, -0.5 * sin(t * PI), 0)
		await get_tree().physics_frame
		await get_tree().process_frame
		head_max = maxf(head_max, vig.closure)
	cam.position = home
	_check("F head: moving the head 0.6 m sideways and crouching 0.5 m leaves it at %.3f - only the game's moving counts" % head_max, head_max < .01, {"max": head_max})
	await _seconds(1.0)
	# H - off
	vig.strength = 0.0
	var off := await _jump_trace(2.5)
	vig.strength = 1.0
	_check("H off: with strength 0 a jump leaves it at %.3f" % off.peak, off.peak == 0.0 and off.apexes.size() == 1, {"peak": off.peak})
	_finish()

func _finish() -> void:
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var f := FileAccess.open(out_dir.path_join("comfort_vignette.json"), FileAccess.WRITE);f.store_string(JSON.stringify(report, "  "));f.close()
	print("[probe_comfort_vignette] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

## Put the body at `at` facing `yaw` (0 looks along -z) and let it settle.
func _place(at: Vector3, yaw: float) -> void:
	body.teleport(Transform3D(Basis(Vector3.UP, yaw), at))
	body.velocity = Vector3.ZERO
	await _seconds(0.6)

func _seconds(s: float) -> void:
	var until := Time.get_ticks_msec() + int(s * 1000.0)
	var ticks := int(s * Engine.physics_ticks_per_second)
	for i in ticks:
		await get_tree().physics_frame
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame

## Press jump once; record closure, height and ground contact every physics step for `seconds`, then measure.
func _jump_trace(seconds: float, shot := "", shot_at := 0.0) -> Dictionary:
	var start_y := body.global_position.y
	stick.jump = true
	var samples := []
	var dt := 1.0 / Engine.physics_ticks_per_second
	for i in int(seconds * Engine.physics_ticks_per_second):
		await get_tree().physics_frame
		await get_tree().process_frame
		samples.append({"t": (i + 1) * dt, "c": float(vig.closure), "y": body.global_position.y - start_y, "g": bool(body.on_ground)})
		if shot != "" and absf((i + 1) * dt - shot_at) < dt * .5:
			await _shoot(shot)
	var r := {"frames_to_close": -1, "air_min": 0.0, "between_min": 0.0, "peak": 0.0, "apexes": [], "touchdowns": 0, "hold_s": -1.0, "open_s": -1.0}
	var first_close := -1;var last_land := -1;var left := false;var air_min := 1.0;var rising := false;var top := -INF
	for i in samples.size():
		var sm: Dictionary = samples[i]
		r.peak = maxf(r.peak, sm.c)
		if first_close < 0 and sm.c >= .5:
			first_close = i;r.frames_to_close = i + 1
		if not sm.g:
			left = true
			if i > 2:air_min = minf(air_min, sm.c)
		if i > 0 and sm.g and not samples[i - 1].g and left:
			r.touchdowns += 1;last_land = i
		if i > 0 and sm.y > samples[i - 1].y + 1e-4:
			rising = true;top = maxf(top, sm.y)
		elif rising and i > 0 and sm.y < samples[i - 1].y - 1e-4:
			r.apexes.append(snappedf(top, .001));rising = false;top = -INF
	r.air_min = air_min if left else 0.0
	if first_close >= 0:
		var until := last_land if last_land >= 0 else samples.size() - 1
		var m := 1.0
		for i in range(first_close, until + 1):
			m = minf(m, samples[i].c)
		r.between_min = m
	if last_land >= 0:
		var landed_c: float = samples[last_land].c
		for i in range(last_land, samples.size()):
			if r.hold_s < 0.0 and samples[i].c < landed_c - .01:r.hold_s = samples[i].t - samples[last_land].t
			if r.open_s < 0.0 and samples[i].c <= 0.001:r.open_s = samples[i].t - samples[last_land].t
	return r

## Walk forward at `speed` for `seconds`, then stop and watch it open.
func _walk_trace(seconds: float, speed: float) -> Dictionary:
	var from := body.global_position
	stick.forward = speed   # the walk's speed is measured below, not assumed
	var r := {"at_0_1": -1.0, "at_1_5": -1.0, "at_1_9": -1.0, "peak": 0.0, "open_after_stop_s": -1.0, "speed": 0.0}
	var t := 0.0;var dt := 1.0 / Engine.physics_ticks_per_second;var shot := false
	for i in int(seconds * Engine.physics_ticks_per_second):
		await get_tree().physics_frame
		await get_tree().process_frame
		t += dt
		var c: float = vig.closure;r.peak = maxf(r.peak, c)
		if r.at_0_1 < 0.0 and t >= .1:r.at_0_1 = c
		if r.at_1_5 < 0.0 and t >= 1.5:r.at_1_5 = c
		if r.at_1_9 < 0.0 and t >= 1.9:r.at_1_9 = c
		if not shot and t >= 2.5 and vig.walk_delay == 0.0:
			shot = true;await _shoot("vignette_walk")
	r.speed = (body.global_position - from).length() / maxf(t, .001)
	stick.forward = 0.0
	var s := 0.0
	for i in int(3.0 * Engine.physics_ticks_per_second):
		await get_tree().physics_frame
		await get_tree().process_frame
		s += dt
		if vig.closure <= 0.001:
			r.open_after_stop_s = s;break
	return r

func _teleport_trace(at: Vector3, yaw: float) -> float:
	var m := 0.0
	body.teleport(Transform3D(Basis(Vector3.UP, yaw), at))
	body.velocity = Vector3.ZERO
	for i in 30:
		await get_tree().physics_frame
		await get_tree().process_frame
		m = maxf(m, vig.closure)
	return m

func _shoot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("%s.png" % name))

func _check(what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_comfort_vignette] %s  %s" % ["ok  " if ok else "FAIL", what])
	var f := FileAccess.open(out_dir.path_join("comfort_vignette.json"), FileAccess.WRITE);f.store_string(JSON.stringify(report, "  "));f.close()   # progress for the watchdog
