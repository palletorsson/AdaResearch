extends "res://tools/probes/void_game_probe.gd"
const VoidFloor = preload("res://tools/probes/void_floor.gd")

## F13 Trans_Pre same-family controlled comparison (Round 3 decision, forum 261120-oznge).
## Measures strict orthogonal transform isolation across all 5 monochrome Coin specimens
## (STATIC -> TRANSLATE -> ROTATE -> SCALE -> ARCHETYPE) over 3 timestamps (t=0.0s, 0.6s, 1.2s)
## from one fixed camera, plus captures Model B's live Dual Breadcrumb HUD inside Floor 13.

func _sample_coin(n: Node3D) -> Dictionary:
	var cm: Node3D = n.get("coin_model") as Node3D
	var sx: float = cm.scale.x if cm != null else n.scale.x
	return {
		"y": snappedf(n.global_position.y, 0.0001),
		"rot_deg": snappedf(rad_to_deg(n.rotation.y), 0.01),
		"scale": snappedf(sx, 0.0001),
	}

func _max_delta(samples: Array, key: String) -> float:
	var mn := INF
	var mx := -INF
	for s in samples:
		var v: float = float((s as Dictionary).get(key, 0.0))
		mn = minf(mn, v)
		mx = maxf(mx, v)
	return mx - mn

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")

	var at: Dictionary = VoidFloor.table()
	var pre_idx: int = int(at.get("Trans_Pre", 13))

	Engine.physics_ticks_per_second = 90
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = pre_idx
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

	game.place_player(game.spawn_for(pre_idx))
	await frames(50)
	var lvl: float = float(game.building.spec.levels[pre_idx])
	var fl_root: Node3D = game.building.content.roots.get(pre_idx, null)
	check("F13 Trans_Pre loaded cleanly", fl_root != null)

	var stages := ["static", "translate", "rotate", "scale", "archetype"]
	var coins: Array = []
	for st in stages:
		coins.append(_find_with_prop(fl_root.find_child("matrix-coin-" + st, true, false), "motion_curve"))
	check("All 5 same-family Coin specimens spawned on South Scaffold", not coins.has(null))

	var measurements := {}
	if not coins.has(null):
		# Verify Order 01 constraints: monochrome + linear lerp across all 5 specimens
		var all_mono := true
		var all_lerp := true
		for c in coins:
			if not bool(c.get_meta("config_monochrome", false)): all_mono = false
			if str(c.get("motion_curve")) != "lerp": all_lerp = false
		check("Order 01 monochrome enforced on all 5 Coin specimens (pre-Color F28)", all_mono)
		check("Order 01 linear lerp enforced on all 5 Coin specimens (pre-WaveFunctions F62)", all_lerp)

		# Fixed comparison camera framing all 5 Coin specimens side-by-side on the South Coin Scaffold
		var c_first: Node3D = coins[0]
		var c_last: Node3D = coins[4]
		var mid: Vector3 = (c_first.global_position + c_last.global_position) * 0.5
		var cam := Camera3D.new()
		root.add_child(cam)
		cam.fov = 56.0
		cam.global_position = Vector3(mid.x, lvl + 2.35, mid.z + 5.6)
		cam.look_at(Vector3(mid.x, lvl + 1.25, mid.z), Vector3.UP)
		cam.make_current()
		await frames(6)

		# Sample across 3 timestamps: t=0.0s, t=0.6s, t=1.2s (54 physics frames = 0.6s at 90Hz)
		var traces: Dictionary = {}
		for st in stages:
			traces[st] = []

		var shot_names := ["01-coin-family-t00.png", "02-coin-family-t06.png", "03-coin-family-t12.png"]
		for step_i in 3:
			if step_i > 0:
				await frames(54)
			for idx in stages.size():
				(traces[stages[idx]] as Array).append(_sample_coin(coins[idx]))
			await frames(2)
			var shot_path := out.path_join(shot_names[step_i])
			root.get_texture().get_image().save_png(shot_path)
			FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string(shot_names[step_i])

		for st in stages:
			var arr: Array = traces[st]
			measurements[st] = {
				"dy_m": snappedf(_max_delta(arr, "y"), 0.0001),
				"drot_deg": snappedf(_max_delta(arr, "rot_deg"), 0.01),
				"dscale": snappedf(_max_delta(arr, "scale"), 0.0001),
				"samples": arr,
			}

		var m_st: Dictionary = measurements["static"]
		var m_tr: Dictionary = measurements["translate"]
		var m_ro: Dictionary = measurements["rotate"]
		var m_sc: Dictionary = measurements["scale"]
		var m_ar: Dictionary = measurements["archetype"]

		check("01 STATIC invariant across t0->t0.6->t1.2 (dy=%.4f, drot=%.2f, dscale=%.4f)" % [m_st.dy_m, m_st.drot_deg, m_st.dscale],
			m_st.dy_m < 0.002 and m_st.drot_deg < 0.5 and m_st.dscale < 0.002)
		check("02 TRANSLATE isolates Y motion only (dy=%.4f, drot=%.2f, dscale=%.4f)" % [m_tr.dy_m, m_tr.drot_deg, m_tr.dscale],
			m_tr.dy_m > 0.05 and m_tr.drot_deg < 0.5 and m_tr.dscale < 0.002)
		check("03 ROTATE isolates Y spin only (dy=%.4f, drot=%.2f, dscale=%.4f)" % [m_ro.dy_m, m_ro.drot_deg, m_ro.dscale],
			m_ro.drot_deg > 15.0 and m_ro.dy_m < 0.002 and m_ro.dscale < 0.002)
		check("04 SCALE isolates uniform scale pulse only (dy=%.4f, drot=%.2f, dscale=%.4f)" % [m_sc.dy_m, m_sc.drot_deg, m_sc.dscale],
			m_sc.dscale > 0.03 and m_sc.dy_m < 0.002 and m_sc.drot_deg < 0.5)
		check("05 ARCHETYPE combines Translate Y + Rotate Y (dy=%.4f, drot=%.2f, dscale=%.4f)" % [m_ar.dy_m, m_ar.drot_deg, m_ar.dscale],
			m_ar.dy_m > 0.05 and m_ar.drot_deg > 15.0)

		# Live Dual Breadcrumb HUD render inside Floor 13 using inner_opera._plain_for()
		var opera_script = load("res://commons/void/inner_opera.gd")
		var opera_tmp = opera_script.new()
		var f13_plain: String = opera_tmp._plain_for("chapter_13_pick_up_cube", "chapter_13_pick_up_cube")
		opera_tmp.free()
		check("F13 plain breadcrumb resolved from tower_system_atlas.json", not f13_plain.is_empty())

		game.charge_display.show()
		game.charge_display.set_level("F13  Trans_Pre  ·  Motion Vocabulary Arena")
		game.charge_display.set_sung("What stays while this body moves?", f13_plain)
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("04-f13-dual-breadcrumb-hud.png"))
		cam.queue_free()

	# Save checks.json in Atlas v2 auto-scanned receipt format (with map + songs + measurements!)
	var failed := 0
	for c in checks:
		if not bool((c as Dictionary).get("passed", false)): failed += 1
	var report := {
		"passed": failed == 0,
		"failed": failed,
		"map": "Trans_Pre",
		"floor": pre_idx,
		"comparison": "same-family monochrome Coin (STATIC vs TRANSLATE vs ROTATE vs SCALE vs ARCHETYPE) across t=0.0s, 0.6s, 1.2s",
		"measurements": measurements,
		"songs": [
			{
				"encounter": "chapter_13_pick_up_cube",
				"object": "chapter_13_pick_up_cube",
				"on_display": true,
				"sung": true,
				"text": "What stays while this body moves?"
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
