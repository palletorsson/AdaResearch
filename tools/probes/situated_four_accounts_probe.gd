extends "res://tools/probes/void_game_probe.gd"
const VoidFloor = preload("res://tools/probes/void_floor.gd")

## Ghost Student Spine Stop #9 (F203 SpeculativeComputation_Situated_Computation · "Four Accounts")
## live desktop verification: inspects the four authored situated_readout panels (SUBJECT #4729),
## tests erasure (Overpaint) vs witness (symbolic eye mast) without adding evidence, verifies
## four-stations causal separation (own -> one_definition -> one_record -> both + unseen trace),
## confirms museum_witnesses, and renders Model B's live Dual Breadcrumb HUD inside Floor 203.

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")

	var at: Dictionary = VoidFloor.table()
	var f203_idx: int = int(at.get("SpeculativeComputation_Situated_Computation", 203))

	Engine.physics_ticks_per_second = 90
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = f203_idx
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

	game.place_player(game.spawn_for(f203_idx))
	await frames(50)
	var fl_root: Node3D = game.building.content.roots.get(f203_idx, null)
	check("F203 SpeculativeComputation_Situated_Computation loaded cleanly", fl_root != null)

	var sr_nw: Node3D = _find_with_prop(fl_root.find_child("f2_situated_readout_2_2", true, false), "address") if fl_root != null else null
	var sr_ne: Node3D = _find_with_prop(fl_root.find_child("f2_situated_readout_7_2", true, false), "address") if fl_root != null else null
	var sr_sw: Node3D = _find_with_prop(fl_root.find_child("f2_situated_readout_2_7", true, false), "address") if fl_root != null else null
	var sr_se: Node3D = _find_with_prop(fl_root.find_child("f2_situated_readout_7_7", true, false), "address") if fl_root != null else null
	var fs_mount: Node3D = fl_root.find_child("four-stations", true, false) if fl_root != null else null
	var fs: Node3D = _find_with_prop(fs_mount, "sharing")
	var mw_mount: Node3D = fl_root.find_child("f2_museum_witnesses_11_20", true, false) if fl_root != null else null
	var mw: Node3D = _find_with_prop(mw_mount, "delay_seconds")

	# Keep head_crab paused if present so it doesn't bite or interrupt framing
	var crab: Node = fl_root.find_child("f2_head_crab_7_5", true, false) if fl_root != null else null
	if crab != null:
		crab.process_mode = Node.PROCESS_MODE_DISABLED

	check("All four situated_readout panels (NW/NE/SW/SE), four-stations, and museum_witnesses spawned on F203",
		sr_nw != null and sr_ne != null and sr_sw != null and sr_se != null and fs != null and mw != null)

	var measurements := {}
	if sr_nw != null and sr_ne != null and sr_sw != null and sr_se != null and fs != null:
		# 1. Verify shared SUBJECT #4729 and four distinct authored verdicts
		var panels := {"NW": sr_nw, "NE": sr_ne, "SW": sr_sw, "SE": sr_se}
		var subjects := []
		var verdict_map := {}
		var conf_map := {}
		for k in ["NW", "NE", "SW", "SE"]:
			var p: Node3D = panels[k]
			var s_lbl: Label3D = p.get("_subject_label")
			var v_lbl: Label3D = p.get("_verdict_label")
			var c_lbl: Label3D = p.get("_confidence_label")
			subjects.append(s_lbl.text if s_lbl != null else "")
			verdict_map[k] = v_lbl.text if v_lbl != null else ""
			conf_map[k] = c_lbl.text if c_lbl != null else ""
		var same_subject: bool = (subjects[0] == "SUBJECT #4729" and subjects[1] == subjects[0] and subjects[2] == subjects[0] and subjects[3] == subjects[0])
		var distinct_verdicts: bool = (
			verdict_map["NW"] == "ORDERLY" and verdict_map["NE"] == "CREATIVE"
			and verdict_map["SW"] == "DANGEROUS" and verdict_map["SE"] == "IRRELEVANT"
		)
		check("All four situated_readout panels share SUBJECT #4729 with four distinct authored verdicts (%s / %s / %s / %s)" % [
			verdict_map["NW"], verdict_map["NE"], verdict_map["SW"], verdict_map["SE"]],
			same_subject and distinct_verdicts)

		# 2. Capture Shot 1: Four situated_readout panels in footnote mode from open SE courtyard
		var center_sr: Vector3 = (sr_nw.global_position + sr_ne.global_position + sr_sw.global_position + sr_se.global_position) * 0.25
		var cam := Camera3D.new()
		root.add_child(cam)
		cam.make_current()
		cam.fov = 58.0
		cam.global_position = center_sr + Vector3(4.6, 2.65, 3.8)
		cam.look_at(center_sr + Vector3(-0.3, 1.15, -0.3), Vector3.UP)
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("01-f203-readouts-four-verdicts.png"))
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("01-f203-readouts-four-verdicts.png")

		# 3. Verify erasure (Overpaint) and witness (symbolic eye mast) preserve DANGEROUS / 92% unchanged!
		var sw_v_before: String = (sr_sw.get("_verdict_label") as Label3D).text
		var sw_c_before: String = (sr_sw.get("_confidence_label") as Label3D).text
		sr_sw.call("apply_grid_config", {"address": "erasure"})
		await frames(4)
		var has_overpaint: bool = sr_sw.find_child("Overpaint", true, false) != null
		var sw_v_erasure: String = (sr_sw.get("_verdict_label") as Label3D).text
		var sw_c_erasure: String = (sr_sw.get("_confidence_label") as Label3D).text

		sr_sw.call("apply_grid_config", {"address": "witness"})
		sr_nw.call("apply_grid_config", {"address": "erasure"})
		await frames(6)
		var has_witness_eye: bool = sr_sw.find_child("Witness", true, false) != null
		var sw_v_witness: String = (sr_sw.get("_verdict_label") as Label3D).text
		var sw_c_witness: String = (sr_sw.get("_confidence_label") as Label3D).text
		check("Covering address (erasure) or adding Witness eye mast keeps DANGEROUS 92%% unchanged (erasure=%s, witness=%s)" % [
			str(has_overpaint), str(has_witness_eye)],
			has_overpaint and has_witness_eye and sw_v_before == sw_v_erasure and sw_v_erasure == sw_v_witness and sw_c_before == sw_c_erasure and sw_c_erasure == sw_c_witness)

		# Capture Shot 2: Close view of SW (witness eye mast on DANGEROUS 92%) & NW (Overpaint erasure)
		var sw_fwd: Vector3 = sr_sw.global_transform.basis.z.normalized()
		cam.fov = 52.0
		cam.global_position = sr_sw.global_position + sw_fwd * 2.55 + Vector3(0.45, 1.35, 0.0)
		cam.look_at(sr_sw.global_position + Vector3(0.0, 1.25, 0.0), Vector3.UP)
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("02-readout-witness-danger92.png"))
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("02-readout-witness-danger92.png")

		# Restore readouts to footnote
		sr_sw.call("apply_grid_config", {"address": "footnote"})
		sr_nw.call("apply_grid_config", {"address": "footnote"})

		# 4. Verify Four Stations causal separation (own -> one_definition -> one_record -> both) + unseen time
		fs.call("apply_grid_config", {"sharing": "own"})
		await frames(6)
		var v_own: Array = fs.call("verdicts", false, false)
		var v_def: Array = fs.call("verdicts", true, false)
		var v_rec: Array = fs.call("verdicts", false, true)
		var v_both: Array = fs.call("verdicts", true, true)
		var causes: Array = fs.call("causes")
		var unseen_s: float = float(fs.call("unseen"))

		var own_danger := 0
		for v in v_own:
			if str(v) == "DANGEROUS": own_danger += 1
		var def_danger := 0
		for v in v_def:
			if str(v) == "DANGEROUS": def_danger += 1
		var rec_danger := 0
		for v in v_rec:
			if str(v) == "DANGEROUS": rec_danger += 1
		var both_danger := 0
		for v in v_both:
			if str(v) == "DANGEROUS": both_danger += 1

		check("Four Stations (own): four stations disagree (%d DANGEROUS vs %d NOT) with %.2f s unseen by any corner" % [
			own_danger, 4 - own_danger, unseen_s],
			bool(causes[0]) and own_danger == 1 and unseen_s > 1.0)

		check("Four Stations separates causes: ONE DEFINITION alone splits %d vs %d (what each saw); ONE RECORD alone splits %d vs %d (what each means)" % [
			def_danger, 4 - def_danger, rec_danger, 4 - rec_danger],
			bool(causes[1]) and bool(causes[2]) and def_danger == 2 and rec_danger == 3)

		check("Four Stations (both): sharing ONE DEFINITION + ONE RECORD brings all four into agreement (%d/4 DANGEROUS)" % both_danger,
			both_danger == 4)

		# Capture Shot 3: Elevated view of Four Stations in sharing="own"
		var fs_pos: Vector3 = fs.global_position
		var fs_fwd: Vector3 = fs.global_transform.basis.z.normalized()
		cam.fov = 58.0
		cam.global_position = fs_pos + fs_fwd * 8.2 + Vector3(0.0, 4.3, 0.0)
		cam.look_at(fs_pos + Vector3(0.0, 1.35, -0.6), Vector3.UP)
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("03-four-stations-own.png"))
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("03-four-stations-own.png")

		# Flip Four Stations to sharing="both" + live Dual Breadcrumb HUD!
		fs.call("apply_grid_config", {"sharing": "both"})
		await frames(8)

		var opera_script = load("res://commons/void/inner_opera.gd")
		var opera_tmp = opera_script.new()
		var f203_plain: String = opera_tmp._plain_for("spine_bb456826fb63e94b53", "spine_bb456826fb63e94b53")
		opera_tmp.free()
		check("F203 Four Accounts plain breadcrumb resolved from tower_system_atlas.json", not f203_plain.is_empty())

		game.charge_display.show()
		game.charge_display.set_level("F203  Situated_Computation  ·  Four Accounts")
		game.charge_display.set_sung("A small event can make the next one possible.", f203_plain)
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("04-four-stations-both-dual-hud.png"))
		cam.queue_free()

		measurements = {
			"subject": subjects[0],
			"readout_verdicts": verdict_map,
			"readout_confidences": conf_map,
			"four_stations_own": v_own,
			"four_stations_one_definition": v_def,
			"four_stations_one_record": v_rec,
			"four_stations_both": v_both,
			"causes": causes,
			"unseen_seconds": snappedf(unseen_s, 0.001),
		}

	var failed := 0
	for c in checks:
		if not bool((c as Dictionary).get("passed", false)): failed += 1
	var report := {
		"passed": failed == 0,
		"failed": failed,
		"map": "SpeculativeComputation_Situated_Computation",
		"floor": f203_idx,
		"encounter": "spine_bb456826fb63e94b53",
		"measurements": measurements,
		"songs": [
			{
				"encounter": "spine_bb456826fb63e94b53",
				"object": "spine_bb456826fb63e94b53",
				"on_display": true,
				"sung": true,
				"text": "A small event can make the next one possible."
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
