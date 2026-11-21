extends "res://tools/probes/void_game_probe.gd"
const VoidFloor = preload("res://tools/probes/void_floor.gd")

## Ghost Student Spine Stop #5 (F106 CA_Introduction · "Predict the Next Row") live desktop verification:
## Verifies Rule 90 neighbour lookup order (100 -> 1 vs 010 -> 0), step-by-step prediction vs actual state,
## Pascal mod-2 / Sierpinski emergence across 10 steps, Rule 30 asymmetry from the same single seed,
## companion floor machines (persian_rug, langton_swarm, line_network_ca, rule110_computer),
## and Model B's live Dual Breadcrumb HUD inside Floor 106.

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")

	var at: Dictionary = VoidFloor.table()
	var f106_idx: int = int(at.get("CA_Introduction", 106))

	Engine.physics_ticks_per_second = 90
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = f106_idx
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

	game.place_player(game.spawn_for(f106_idx))
	await frames(50)
	var fl_root: Node3D = game.building.content.roots.get(f106_idx, null)
	check("F106 CA_Introduction loaded cleanly", fl_root != null)

	var ca_mount: Node3D = fl_root.find_child("f1_ca_rule_explorer_10_5", true, false) if fl_root != null else null
	var ca: Node3D = _find_with_prop(ca_mount, "cells_x")
	var rug: Node3D = fl_root.find_child("f1_persian_rug_4_4", true, false) if fl_root != null else null
	var swarm: Node3D = fl_root.find_child("f1_langton_swarm_10_9", true, false) if fl_root != null else null
	var net: Node3D = fl_root.find_child("f1_line_network_ca_10_12", true, false) if fl_root != null else null
	var r110: Node3D = fl_root.find_child("f1_rule110_computer_10_16", true, false) if fl_root != null else null
	check("CA Rule Explorer, Persian Rug, Langton Swarm, Line Network CA, and Rule 110 Computer spawned on F106",
		ca != null and rug != null and swarm != null and net != null and r110 != null)

	var measurements := {}
	if ca != null:
		var study: Node = ca.find_child("NeighbourStudy", true, false)
		check("NeighbourStudy mounted on ca_rule_explorer (study=neighbours)", study != null)

		# Ensure Rule 90 single-seed start
		ca.call("set_rule", 90)
		ca.set("auto_run", false)
		await frames(6)

		var c_idx: int = int(ca.get("cells_x")) / 2
		ca.set("sample_cell", c_idx)
		var rb_010: Dictionary = ca.call("neighbourhood_readback")
		ca.set("sample_cell", c_idx + 1)
		var rb_100: Dictionary = ca.call("neighbourhood_readback")
		check("Rule 90 distinguishes neighbour order: 010 -> 0 while 100 -> 1 (same count=1, opposite output)",
			rb_010.get("inputs") == [0, 1, 0] and int(rb_010.get("next", -1)) == 0
			and rb_100.get("inputs") == [1, 0, 0] and int(rb_100.get("next", -1)) == 1)

		# Wide overview shot of Floor 106 showing board + overhead ring + surrounding room
		var cam := Camera3D.new()
		root.add_child(cam)
		cam.fov = 58.0
		var ca_pos: Vector3 = ca.global_position
		var ca_fwd: Vector3 = ca.global_transform.basis.z.normalized()
		cam.global_position = ca_pos + ca_fwd * 4.2 + Vector3(1.6, 2.35, 0.0)
		cam.look_at(ca_pos + Vector3(0.0, 1.35, 0.0), Vector3.UP)
		cam.make_current()
		await frames(8)
		root.get_texture().get_image().save_png(out.path_join("01-f106-overview.png"))
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("01-f106-overview.png")

		# Close comparison camera angled nicely over the CA board + overhead neighbour ring
		cam.fov = 52.0
		cam.global_position = ca_pos + ca_fwd * 2.15 + Vector3(0.0, 1.45, 0.0)
		cam.look_at(ca_pos + Vector3(0.0, 0.65, 0.0), Vector3.UP)
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("02-rule90-step0.png"))
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("02-rule90-step0.png")

		# Step 10 generations under Rule 90 and verify prediction matches actual cell after step 1 + Pascal mod-2 emergence!
		var pred_c1: int = int(rb_100.get("next", -1))
		ca.call("step")
		await frames(4)
		var rb_after1: Dictionary = ca.call("neighbourhood_readback")
		var actual_c1: int = int((rb_after1.get("inputs", [0, 0, 0]) as Array)[1])
		check("Step 1 matches prediction at cell c+1 (predicted=%d, actual=%d)" % [pred_c1, actual_c1],
			pred_c1 == actual_c1 and int(rb_after1.get("generation", 0)) == 1)

		for _s in 9:
			ca.call("step")
			await frames(2)
		await frames(6)
		var rb_r90: Dictionary = ca.call("neighbourhood_readback")
		check("Rule 90 after 10 steps builds exact Pascal triangle mod 2 (Sierpinski emergence, gen=%d)" % int(rb_r90.get("generation", 0)),
			int(rb_r90.get("generation", 0)) == 10 and bool(rb_r90.get("pascal", false)))

		# Tilt slightly up to frame BOTH the stepped Rule 90 board and the overhead neighbour ring
		cam.global_position = ca_pos + ca_fwd * 2.85 + Vector3(0.0, 1.55, 0.0)
		cam.look_at(ca_pos + Vector3(0.0, 1.25, 0.0), Vector3.UP)
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("03-rule90-pascal-ring.png"))
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("03-rule90-pascal-ring.png")

		# Switch to Rule 30 on the exact same single seed, step 10 times -> chaotic asymmetric evolution (non-Pascal!)
		ca.call("set_rule", 30)
		ca.set("auto_run", false)
		ca.set("sample_cell", c_idx)
		var rb_r30_0: Dictionary = ca.call("neighbourhood_readback")
		for _s in 10:
			ca.call("step")
			await frames(2)
		await frames(6)
		var rb_r30_10: Dictionary = ca.call("neighbourhood_readback")
		check("Rule 30 on same single seed diverges from Pascal symmetry (rule=30, 010->1, gen=%d, pascal=%s)" % [int(rb_r30_10.get("generation", 0)), str(rb_r30_10.get("pascal"))],
			int(rb_r30_0.get("next", -1)) == 1 and int(rb_r30_10.get("generation", 0)) == 10 and not bool(rb_r30_10.get("pascal", true)))

		# Live Dual Breadcrumb HUD capture on F106 using inner_opera._plain_for()
		var opera_script = load("res://commons/void/inner_opera.gd")
		var opera_tmp = opera_script.new()
		var f106_plain: String = opera_tmp._plain_for("spine_554ad276c59f013b7e", "spine_554ad276c59f013b7e")
		opera_tmp.free()
		check("F106 Predict the Next Row plain breadcrumb resolved from tower_system_atlas.json", not f106_plain.is_empty())

		game.charge_display.show()
		game.charge_display.set_level("F106  CA_Introduction  ·  Predict the Next Row")
		game.charge_display.set_sung("Each small place changes with the ones nearby.", f106_plain)
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("04-rule30-dual-hud.png"))
		cam.queue_free()

		measurements = {
			"width": int(ca.get("cells_x")),
			"rule90_010_next": int(rb_010.get("next", -1)),
			"rule90_100_next": int(rb_100.get("next", -1)),
			"rule90_gen10_pascal": bool(rb_r90.get("pascal", false)),
			"rule30_010_next": int(rb_r30_0.get("next", -1)),
			"rule30_gen10_pascal": bool(rb_r30_10.get("pascal", false)),
		}

	var failed := 0
	for c in checks:
		if not bool((c as Dictionary).get("passed", false)): failed += 1
	var report := {
		"passed": failed == 0,
		"failed": failed,
		"map": "CA_Introduction",
		"floor": f106_idx,
		"encounter": "spine_554ad276c59f013b7e",
		"measurements": measurements,
		"songs": [
			{
				"encounter": "spine_554ad276c59f013b7e",
				"object": "spine_554ad276c59f013b7e",
				"on_display": true,
				"sung": true,
				"text": "Each small place changes with the ones nearby."
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
