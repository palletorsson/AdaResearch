extends "res://tools/probes/void_game_probe.gd"
const VoidFloor = preload("res://tools/probes/void_floor.gd")

## F71 Wavefunctions_Sky_Stairs live desktop walk verification:
## Inspects f2_sine_cylinder_staircase_7_16 (ShaftFlight: 51 sine-modulated ceramic treads
## dropping 6.0 m from IvoryUpperLanding to JadeLowerLanding through Shaft B), sweeps
## downward physics raycasts across the entire 1.25-turn spiral to prove continuous
## walkability with zero gaps, tests live Model B body support at top / mid / bottom,
## verifies sine radial breathing (WAVE_AMPLITUDE = 0.17), and captures 4 renders + HUD.

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")

	var at: Dictionary = VoidFloor.table()
	var f71_idx: int = int(at.get("Wavefunctions_Sky_Stairs", 71))

	Engine.physics_ticks_per_second = 90
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = f71_idx
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

	game.place_player(game.spawn_for(f71_idx))
	await frames(50)
	var fl_root: Node3D = game.building.content.roots.get(f71_idx, null)
	check("F71 Wavefunctions_Sky_Stairs loaded cleanly", fl_root != null)

	var stair_mount: Node3D = fl_root.find_child("f2_sine_cylinder_staircase_7_16", true, false) if fl_root != null else null
	var stair: Node3D = _find_with_prop(stair_mount, "STEP_COUNT")
	var flight: Node3D = stair.find_child("ShaftFlight", true, false) if stair != null else null
	var walk_col: Node = flight.find_child("WalkableSpiral", true, false) if flight != null else null
	var guard_col: Node = flight.find_child("Guardrails", true, false) if flight != null else null
	var upper_land: Node = flight.find_child("IvoryUpperLanding", true, false) if flight != null else null
	var lower_land: Node = flight.find_child("JadeLowerLanding", true, false) if flight != null else null

	check("Sky Stairs ShaftFlight built with CeramicTreads, WalkableSpiral, Guardrails, IvoryUpperLanding, and JadeLowerLanding",
		stair != null and flight != null and walk_col != null and guard_col != null and upper_land != null and lower_land != null)

	var measurements := {}
	if stair != null and flight != null:
		var step_count: int = int(stair.get("STEP_COUNT"))
		var drop: float = float(stair.get("shaft_drop"))
		var core: float = float(stair.get("BASE_RADIUS"))
		var width: float = float(stair.get("STEP_WIDTH"))
		var amp: float = float(stair.get("WAVE_AMPLITUDE"))
		var sweep: float = TAU * 1.25

		# 1. Verify sine radial modulation along the spiral
		var r_min := 999.0
		var r_max := -999.0
		for i in 25:
			var ang: float = float(i) / 24.0 * sweep
			var rad: float = float(stair.call("_radius_at", ang))
			r_min = minf(r_min, rad)
			r_max = maxf(r_max, rad)
		var r_span: float = r_max - r_min
		check("Spiral radius breathes sinusoidally (WAVE_AMPLITUDE=%.2f -> r_min=%.3f m, r_max=%.3f m, span=%.3f m)" % [amp, r_min, r_max, r_span],
			amp > 0.1 and r_span > 0.25)

		# 2. Sweep physics downward raycasts at 21 points along the spiral midline from top (step 50) to bottom (step 0)
		var space := game.get_world_3d().direct_space_state
		var hits := 0
		var heights: Array[float] = []
		var max_step_jump := 0.0
		var prev_y := NAN
		var sample_n := 21
		var world_pts: Array[Vector3] = []
		for k in sample_n:
			# step index from top (step_count-1) down to 0
			var frac: float = 1.0 - float(k) / float(sample_n - 1)
			var ang: float = frac * sweep
			var outer: float = float(stair.call("_radius_at", ang)) + width * 0.5
			var mid_r: float = (core + outer) * 0.5
			var expected_local_y: float = frac * drop
			var local_probe := Vector3(cos(ang) * mid_r, expected_local_y + 1.2, sin(ang) * mid_r)
			var local_end := Vector3(cos(ang) * mid_r, expected_local_y - 1.5, sin(ang) * mid_r)
			var wp_from: Vector3 = flight.to_global(local_probe)
			var wp_to: Vector3 = flight.to_global(local_end)
			var q := PhysicsRayQueryParameters3D.create(wp_from, wp_to)
			var hit: Dictionary = space.intersect_ray(q)
			if not hit.is_empty():
				hits += 1
				var hy: float = (hit.position as Vector3).y
				heights.append(hy)
				world_pts.append(hit.position as Vector3)
				if not is_nan(prev_y):
					max_step_jump = maxf(max_step_jump, absf(hy - prev_y))
				prev_y = hy
			else:
				world_pts.append(flight.to_global(Vector3(cos(ang) * mid_r, expected_local_y, sin(ang) * mid_r)))

		var total_drop_measured: float = (heights[0] - heights[heights.size() - 1]) if heights.size() >= 2 else 0.0
		check("Continuous walkable collision across all %d spiral stations (%d/%d solid hits, total drop=%.2f m, max sample delta=%.2f m)" % [
			sample_n, hits, sample_n, total_drop_measured, max_step_jump],
			hits == sample_n and absf(total_drop_measured - drop) < 0.45 and max_step_jump < 0.65)

		# 3. Physically place Model B at upper landing, spiral midpoint, and lower jade landing and settle 25 physics frames each!
		var upper_world: Vector3 = flight.to_global(Vector3(-1.5, drop + 0.08, (core + 2.4) * 0.5))
		var mid_world: Vector3 = world_pts[sample_n / 2] + Vector3(0.0, 0.08, 0.0)
		var lower_world: Vector3 = flight.to_global(Vector3((core + 2.6) * 0.5, 0.08, -0.45))

		var settle_deltas := []
		for test_pt in [upper_world, mid_world, lower_world]:
			game.place_player(test_pt)
			await frames(25)
			var after_y: float = game.body.global_position.y
			settle_deltas.append(snappedf(absf(after_y - test_pt.y), 0.001))
		var all_supported: bool = float(settle_deltas[0]) < 0.35 and float(settle_deltas[1]) < 0.45 and float(settle_deltas[2]) < 0.35
		check("Model B body stands supported at upper landing, spiral midpoint, and lower jade landing (|dy|=%s m)" % str(settle_deltas),
			all_supported)

		# 4. Capture 4 clean screenshots
		var cam := Camera3D.new()
		root.add_child(cam)
		cam.make_current()
		var s_pos: Vector3 = stair.global_position

		# Shot 1: Overview of Floor 71 around Sky Stairs opening + slides
		cam.fov = 60.0
		cam.global_position = s_pos + Vector3(-8.5, 3.6, 5.2)
		cam.look_at(s_pos + Vector3(0.0, 0.6, 0.0), Vector3.UP)
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("01-f71-overview.png"))
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("01-f71-overview.png")

		# Shot 2: Looking straight down into the ivory spiral shaft from upper landing
		cam.fov = 62.0
		cam.global_position = s_pos + Vector3(-2.6, 2.3, 2.6)
		cam.look_at(s_pos + Vector3(0.5, -3.2, -0.4), Vector3.UP)
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("02-sky-stairs-entry.png"))
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("02-sky-stairs-entry.png")

		# Shot 3: Mid-flight standing view inside Shaft B showing Model B + treads + jade landing below
		game.body.visible = true
		game.place_player(mid_world)
		await frames(10)
		cam.fov = 60.0
		cam.global_position = s_pos + Vector3(0.0, -1.3, 3.6)
		cam.look_at(mid_world + Vector3(0.0, 0.4, 0.0), Vector3.UP)
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("03-sky-stairs-mid-walk.png"))
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("03-sky-stairs-mid-walk.png")

		# Shot 4: Lower Jade landing looking up the full 6 m ivory spiral + live Dual Breadcrumb HUD!
		game.place_player(lower_world)
		await frames(10)
		var opera_script = load("res://commons/void/inner_opera.gd")
		var opera_tmp = opera_script.new()
		var f71_plain: String = opera_tmp._plain_for("spine_6647a3086c36f99d8f", "spine_6647a3086c36f99d8f")
		opera_tmp.free()
		check("F71 Sky Stairs plain breadcrumb resolved from tower_system_atlas.json", not f71_plain.is_empty())

		cam.fov = 62.0
		cam.global_position = s_pos + Vector3(2.8, -4.4, -3.2)
		cam.look_at(s_pos + Vector3(-0.3, -2.1, 0.4), Vector3.UP)
		game.charge_display.show()
		game.charge_display.set_level("F71  Wavefunctions_Sky_Stairs  ·  Eyes Before Feet")
		game.charge_display.set_sung("A turning rhythm moves through where I stand.", f71_plain)
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("04-sky-stairs-dual-hud.png"))
		cam.queue_free()

		measurements = {
			"step_count": step_count,
			"shaft_drop_m": drop,
			"wave_amplitude_m": amp,
			"radius_min_m": snappedf(r_min, 0.001),
			"radius_max_m": snappedf(r_max, 0.001),
			"raycast_hits": "%d/%d" % [hits, sample_n],
			"measured_drop_m": snappedf(total_drop_measured, 0.001),
			"max_sample_delta_m": snappedf(max_step_jump, 0.001),
			"body_settle_deltas_m": settle_deltas,
		}

	var failed := 0
	for c in checks:
		if not bool((c as Dictionary).get("passed", false)): failed += 1
	var report := {
		"passed": failed == 0,
		"failed": failed,
		"map": "Wavefunctions_Sky_Stairs",
		"floor": f71_idx,
		"encounter": "spine_6647a3086c36f99d8f",
		"measurements": measurements,
		"songs": [
			{
				"encounter": "spine_6647a3086c36f99d8f",
				"object": "spine_6647a3086c36f99d8f",
				"on_display": true,
				"sung": true,
				"text": "A turning rhythm moves through where I stand."
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
