extends "res://tools/probes/void_game_probe.gd"
const VoidFloor = preload("res://tools/probes/void_floor.gd")

## Ghost Student Spine Stop #8 (F177 ML_Gradient_Landscape · "Three Meanings of Error")
## live desktop verification: tests one_line_three_errors on the live Floor 177 hall —
## compares squared, Huber, and wavy loss on the exact same fixed candidate line, flips OUTLIER
## (lifting the 5th observation from 0.7 to 4.7) to prove squared error reacts far more sharply
## than Huber, tests STEP=long overshoot, verifies companion ML artifacts, and captures Model B's
## live Dual Breadcrumb HUD inside Floor 177.

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")

	var at: Dictionary = VoidFloor.table()
	var f177_idx: int = int(at.get("ML_Gradient_Landscape", 177))

	Engine.physics_ticks_per_second = 90
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = f177_idx
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

	game.place_player(game.spawn_for(f177_idx))
	await frames(50)
	var fl_root: Node3D = game.building.content.roots.get(f177_idx, null)
	check("F177 ML_Gradient_Landscape loaded cleanly", fl_root != null)

	var o3_mount: Node3D = fl_root.find_child("one-line-three-errors", true, false) if fl_root != null else null
	var o3: Node3D = _find_with_prop(o3_mount, "outlier")
	var lfc: Node3D = fl_root.find_child("f2_loss_function_comparator_6_8", true, false) if fl_root != null else null
	var gd_viz: Node3D = fl_root.find_child("f2_gradient_descent_visualization_3_3", true, false) if fl_root != null else null
	var plateau: Node3D = fl_root.find_child("dna-gradient-plateau", true, false) if fl_root != null else null
	var pca: Node3D = fl_root.find_child("f2_pca_visualization_5_5", true, false) if fl_root != null else null
	check("One Line Three Errors, Loss Comparator, Gradient Descent (basin + plateau), and PCA spawned on F177",
		o3 != null and lfc != null and gd_viz != null and plateau != null and pca != null)

	var measurements := {}
	if o3 != null:
		var q_start := Vector2(-1.0, 1.0)
		var q_fit := Vector2(0.5, 0.2) # exact fit to clean DATA (y = 0.5*x + 0.2)

		# 1. Fixed candidate line & fixed clean observations: compare 3 error rules!
		var e_sq_clean: float = float(o3.call("error_of", "squared", q_start, false))
		var e_hu_clean: float = float(o3.call("error_of", "huber", q_start, false))
		var e_wa_clean: float = float(o3.call("error_of", "wavy", q_start, false))
		check("Same fixed line q=(-1.0,1.0) gets three distinct errors (squared=%.3f, huber=%.3f, wavy=%.3f)" % [e_sq_clean, e_hu_clean, e_wa_clean],
			absf(e_sq_clean - e_hu_clean) > 0.05 and absf(e_sq_clean - e_wa_clean) > 0.05)

		# 2. Lift 5th observation to outlier (0.7 -> 4.7) on the EXACT same fitted line q=(0.5, 0.2)!
		var fit_sq_off: float = float(o3.call("error_of", "squared", q_fit, false))
		var fit_sq_on: float = float(o3.call("error_of", "squared", q_fit, true))
		var fit_hu_on: float = float(o3.call("error_of", "huber", q_fit, true))
		var grad_sq_on: Vector2 = o3.call("gradient", "squared", q_fit, true)
		var grad_hu_on: Vector2 = o3.call("gradient", "huber", q_fit, true)
		check("Single outlier (0.7->4.7) pulls squared loss far harder than Huber (sq=%.3f vs huber=%.3f; |grad_sq|=%.3f vs |grad_hu|=%.3f)" % [fit_sq_on, fit_hu_on, grad_sq_on.length(), grad_hu_on.length()],
			fit_sq_off < 0.001 and fit_sq_on > fit_hu_on * 2.0 and grad_sq_on.length() > grad_hu_on.length() * 2.0)

		# 3. Compare step size (short=0.5 vs long=1.2) on squared error with outlier at q_over=(0.0,-0.6) -> long step overshoots worse!
		var q_over := Vector2(0.0, -0.6)
		var next_short: Vector2 = o3.call("step_from", "squared", q_over, true, 0.5)
		var next_long: Vector2 = o3.call("step_from", "squared", q_over, true, 1.2)
		var e_before: float = float(o3.call("error_of", "squared", q_over, true))
		var e_after_short: float = float(o3.call("error_of", "squared", next_short, true))
		var e_after_long: float = float(o3.call("error_of", "squared", next_long, true))
		check("Step length separates score from following at q=(0.0,-0.6): short improves (%.3f->%.3f) while long overshoots worse (%.3f)" % [e_before, e_after_short, e_after_long],
			e_after_short < e_before and e_after_long > e_before)

		# Stage visual states & capture 4 clean screenshots
		var cam := Camera3D.new()
		root.add_child(cam)
		var o_pos: Vector3 = o3.global_position
		var o_fwd: Vector3 = o3.global_transform.basis.z.normalized()

		# Wide overview of Floor 177 around one_line_three_errors + SCORE/FOLLOW wall
		o3.call("apply_grid_config", {"outlier": "off", "step": "short"})
		await frames(6)
		cam.fov = 58.0
		cam.global_position = o_pos + o_fwd * 6.8 + Vector3(2.2, 3.2, 0.0)
		cam.look_at(o_pos + Vector3(0.0, 1.35, -1.2), Vector3.UP)
		cam.make_current()
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("01-f177-overview.png"))
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("01-f177-overview.png")

		# Close view facing the observation plank, 3 error bars, and floor arrows (OUTLIER OFF)
		cam.fov = 54.0
		cam.global_position = o_pos + o_fwd * 5.0 + Vector3(0.0, 2.75, 0.0)
		cam.look_at(o_pos + Vector3(0.0, 1.45, -1.6), Vector3.UP)
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("02-outlier-off-short.png"))
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("02-outlier-off-short.png")

		# Flip OUTLIER ON (5th post leaps to 4.7; squared bar shoots skyward!)
		o3.call("apply_grid_config", {"outlier": "on", "step": "short"})
		await frames(8)
		root.get_texture().get_image().save_png(out.path_join("03-outlier-on-short.png"))
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("03-outlier-on-short.png")

		# Step visitor body onto q_over=(0.0,-0.6) with OUTLIER ON + STEP LONG so live red WORSE overshoot tips light up!
		var p_over: Vector2 = o3.call("place", q_over)
		var world_over: Vector3 = o3.to_global(Vector3(p_over.x, 0.05, p_over.y))
		game.place_player(world_over)
		o3.call("apply_grid_config", {"outlier": "on", "step": "long"})
		await frames(10)
		var reads_live: Dictionary = o3.get("_reads")
		var sq_live_better: bool = bool((reads_live.get("squared", {}) as Dictionary).get("better", true))
		check("Stepping onto q=(0.0,-0.6) with OUTLIER=on and STEP=long triggers live red WORSE overshoot on floor",
			bool(o3.get("_visitor_is_it")) and not sq_live_better)

		var opera_script = load("res://commons/void/inner_opera.gd")
		var opera_tmp = opera_script.new()
		var f177_plain: String = opera_tmp._plain_for("spine_3b5bbaf63cf7d38ca2", "spine_3b5bbaf63cf7d38ca2")
		opera_tmp.free()
		check("F177 Three Meanings of Error plain breadcrumb resolved from tower_system_atlas.json", not f177_plain.is_empty())

		game.charge_display.show()
		game.charge_display.set_level("F177  ML_Gradient_Landscape  ·  Three Meanings of Error")
		game.charge_display.set_sung("A small mistake can change my next attempt.", f177_plain)
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("04-outlier-long-dual-hud.png"))
		cam.queue_free()

		measurements = {
			"clean_start_squared": snappedf(e_sq_clean, 0.001),
			"clean_start_huber": snappedf(e_hu_clean, 0.001),
			"clean_start_wavy": snappedf(e_wa_clean, 0.001),
			"fit_outlier_squared": snappedf(fit_sq_on, 0.001),
			"fit_outlier_huber": snappedf(fit_hu_on, 0.001),
			"grad_outlier_squared_mag": snappedf(grad_sq_on.length(), 0.001),
			"grad_outlier_huber_mag": snappedf(grad_hu_on.length(), 0.001),
			"step_before": snappedf(e_before, 0.001),
			"step_after_short": snappedf(e_after_short, 0.001),
			"step_after_long": snappedf(e_after_long, 0.001),
		}

	var failed := 0
	for c in checks:
		if not bool((c as Dictionary).get("passed", false)): failed += 1
	var report := {
		"passed": failed == 0,
		"failed": failed,
		"map": "ML_Gradient_Landscape",
		"floor": f177_idx,
		"encounter": "spine_3b5bbaf63cf7d38ca2",
		"measurements": measurements,
		"songs": [
			{
				"encounter": "spine_3b5bbaf63cf7d38ca2",
				"object": "spine_3b5bbaf63cf7d38ca2",
				"on_display": true,
				"sung": true,
				"text": "A small mistake can change my next attempt."
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
