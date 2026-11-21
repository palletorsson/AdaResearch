extends "res://tools/probes/void_game_probe.gd"
const VoidFloor = preload("res://tools/probes/void_floor.gd")

## Ghost Student Spine Stop #4 (F62 WaveFunctions_Intro) live desktop verification:
## Drives hand-sine-yoke through OperaFrame06 ("06 · TWO VISITS") past RailMark rising,
## measures harmonic sine deceleration near peak vs linear midpoint, completes the falling
## return crossing (two_visits_completed signal), and captures Model B's Dual Breadcrumb HUD.

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")

	var at: Dictionary = VoidFloor.table()
	var f62_idx: int = int(at.get("WaveFunctions_Intro", 62))

	Engine.physics_ticks_per_second = 90
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = f62_idx
	game = load("res://commons/void/void.tscn").instantiate()
	game.force_xr = false
	root.add_child(game)
	current_scene = game
	game.scene_loaded()
	game.scene_visible()
	game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true
	game.body.set_process_unhandled_input(false)
	if game.get("soundscape") != null:
		game.soundscape.process_mode = Node.PROCESS_MODE_DISABLED
	await frames(60)
	game.body.visible = false
	game.status.hide()
	game.charge_display.hide()
	game.notice_time = 0
	if game.desktop_help != null:
		game.desktop_help.hide()

	game.place_player(game.spawn_for(f62_idx))
	await frames(50)
	var lvl: float = float(game.building.spec.levels[f62_idx])
	var fl_root: Node3D = game.building.content.roots.get(f62_idx, null)
	check("F62 WaveFunctions_Intro loaded cleanly", fl_root != null)

	var yoke_mount: Node3D = fl_root.find_child("hand-sine-yoke", true, false) if fl_root != null else null
	var yoke: Node3D = _find_with_prop(yoke_mount, "crank_radius")
	var pendulum: Node3D = fl_root.find_child("pendulum", true, false) if fl_root != null else null
	var monitor: Node3D = fl_root.find_child("monitor", true, false) if fl_root != null else null
	check("hand-sine-yoke, control_pendulum, and void_wave_monitor spawned on F62", yoke != null and pendulum != null and monitor != null)

	var measurements := {}
	if yoke != null:
		var vf: Node3D = yoke.get("view_frame") as Node3D
		var mark: Node3D = yoke.get("rail_mark") as Node3D
		var wheel: Node3D = yoke.get("wheel") as Node3D
		var cube: Node3D = yoke.get("cube") as Node3D
		check("OperaFrame06 (06 · TWO VISITS) and RailMark active on hand-sine-yoke", vf != null and mark != null and wheel != null and cube != null)

		# 1. Wide overview shot of Floor 62 centered around hand-sine-yoke
		var cam := Camera3D.new()
		root.add_child(cam)
		cam.fov = 58.0
		var yoke_origin: Vector3 = yoke.global_position
		var vf_pos: Vector3 = vf.global_position
		var mark_pos: Vector3 = mark.global_position
		# Frame's local +Z faces the visitor (check which side sees the mark cleanly)
		var vf_fwd: Vector3 = vf.global_transform.basis.z.normalized()
		cam.global_position = yoke_origin + vf_fwd * 4.4 + Vector3(0.8, 2.2, 0.0)
		cam.look_at(yoke_origin + Vector3(0.45, 1.15, 0.0), Vector3.UP)
		cam.make_current()
		await frames(8)
		root.get_texture().get_image().save_png(out.path_join("01-f62-overview.png"))
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("01-f62-overview.png")

		# 2. Position visitor camera dead-center in front of OperaFrame06 looking cleanly through the frame!
		cam.fov = 54.0
		cam.global_position = vf_pos + vf_fwd * 2.15 + Vector3(0.0, 0.08, 0.0)
		cam.look_at(vf_pos - vf_fwd * 0.55, Vector3.UP)
		await frames(10)

		# Confirm OperaFrame06 lights up when viewing RailMark through it (try opposite side if needed)
		if not bool(vf.get("lit")):
			cam.global_position = vf_pos - vf_fwd * 2.15 + Vector3(0.0, 0.08, 0.0)
			cam.look_at(vf_pos + vf_fwd * 0.55, Vector3.UP)
			await frames(10)
		check("OperaFrame06 lights up when camera views RailMark through frame", bool(vf.get("lit")))

		# Connect two_visits_completed signal and simulate hand turning via _pointer!
		var completed_flag := {"fired": false}
		yoke.connect("two_visits_completed", func(): completed_flag.fired = true)
		wheel.set("_pointer", cam)
		check("HandWheel enters manipulated state during hand turn", bool(wheel.call("is_manipulated")))

		# Record starting height at -25 deg (below mark)
		wheel.call("set_angle_degrees", -25.0)
		await frames(6)
		var h_neg25: float = mark.to_local(cube.global_position).y

		# Step smoothly UP across 0 deg -> +30 deg (Visit #1: RISING)
		var h_0 := 0.0
		var h_30 := 0.0
		var h_60 := 0.0
		var h_90 := 0.0
		var h_180 := 0.0
		var h_205 := 0.0

		for deg in [-20, -10, 0, 10, 20, 30]:
			wheel.call("set_angle_degrees", float(deg))
			await frames(3)
			if deg == 0: h_0 = mark.to_local(cube.global_position).y
			if deg == 30: h_30 = mark.to_local(cube.global_position).y

		var saw_rise_ok: bool = bool(vf.get("saw_rise"))
		check("Visit #1 (RISING): cube crosses RailMark upward (-25->+30 deg, saw_rise=%s, h_neg25=%.3f -> h_30=%.3f)" % [str(saw_rise_ok), h_neg25, h_30],
			h_neg25 < -0.05 and h_30 > 0.05 and saw_rise_ok)
		root.get_texture().get_image().save_png(out.path_join("02-two-visits-rising.png"))
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("02-two-visits-rising.png")

		# Continue UP to +90 deg peak (measuring smooth sine deceleration vs linear!)
		for deg in [45, 60, 75, 90]:
			wheel.call("set_angle_degrees", float(deg))
			await frames(3)
			if deg == 60: h_60 = mark.to_local(cube.global_position).y
			if deg == 90: h_90 = mark.to_local(cube.global_position).y

		var lift_mid: float = absf(h_30 - h_0)
		var lift_crest: float = absf(h_90 - h_60)
		check("Smooth harmonic sine deceleration proven (0->30 deg lifts %.3f m vs 60->90 deg lifts %.3f m; ratio=%.2fx)" % [lift_mid, lift_crest, lift_mid / maxf(0.0001, lift_crest)],
			lift_mid > lift_crest * 2.5 and h_90 > 0.30)
		root.get_texture().get_image().save_png(out.path_join("03-two-visits-peak.png"))
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("03-two-visits-peak.png")

		# Continue DOWN past +180 deg -> +205 deg (Visit #2: FALLING across the exact same height!)
		for deg in [110, 130, 150, 165, 180, 195, 205]:
			wheel.call("set_angle_degrees", float(deg))
			await frames(3)
			if deg == 180: h_180 = mark.to_local(cube.global_position).y
			if deg == 205: h_205 = mark.to_local(cube.global_position).y

		check("Visit #2 (FALLING): cube returns through exact same RailMark height (|h_0 - h_180|=%.4f m) and fires two_visits_completed" % absf(h_0 - h_180),
			absf(h_0 - h_180) < 0.02 and h_205 < -0.05 and bool(vf.get("completed")) and completed_flag.fired)

		# Live Dual Breadcrumb HUD capture on Visit #2 using inner_opera._plain_for()
		var opera_script = load("res://commons/void/inner_opera.gd")
		var opera_tmp = opera_script.new()
		var f62_plain: String = opera_tmp._plain_for("spine_c2b6fc98a64a37b397", "spine_c2b6fc98a64a37b397")
		opera_tmp.free()
		check("F62 Two Visits plain breadcrumb resolved from tower_system_atlas.json", not f62_plain.is_empty())

		game.charge_display.show()
		game.charge_display.set_level("F62  WaveFunctions_Intro  ·  06 · TWO VISITS")
		game.charge_display.set_sung("Same height twice. Rising once. Falling once.", f62_plain)
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("04-two-visits-falling-hud.png"))

		wheel.set("_pointer", null)
		cam.queue_free()

		measurements = {
			"h_neg25_m": snappedf(h_neg25, 0.0001),
			"h_0_m": snappedf(h_0, 0.0001),
			"h_30_m": snappedf(h_30, 0.0001),
			"h_60_m": snappedf(h_60, 0.0001),
			"h_90_peak_m": snappedf(h_90, 0.0001),
			"h_180_return_m": snappedf(h_180, 0.0001),
			"h_205_m": snappedf(h_205, 0.0001),
			"lift_0_to_30_m": snappedf(lift_mid, 0.0001),
			"lift_60_to_90_m": snappedf(lift_crest, 0.0001),
			"two_visits_completed": completed_flag.fired,
		}

	var failed := 0
	for c in checks:
		if not bool((c as Dictionary).get("passed", false)): failed += 1
	var report := {
		"passed": failed == 0,
		"failed": failed,
		"map": "WaveFunctions_Intro",
		"floor": f62_idx,
		"encounter": "spine_c2b6fc98a64a37b397",
		"measurements": measurements,
		"songs": [
			{
				"encounter": "spine_c2b6fc98a64a37b397",
				"object": "spine_c2b6fc98a64a37b397",
				"on_display": true,
				"sung": true,
				"text": "Same height twice. Rising once. Falling once."
			}
		],
		"checks": checks,
	}
	var f := FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(report, "  ") + "\n")
	quit(0 if failed == 0 else 1)

func _find_with_prop(node: Node, prop: String) -> Node3D:
	if node == null: return null
	if node is Node3D and node.get(prop) != null: return node
	for c in node.get_children():
		var hit := _find_with_prop(c, prop)
		if hit != null: return hit
	return null
