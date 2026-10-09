extends SceneTree
## WaveFunctions_Sine_Space, batch W1 (doc/research/waves-chance-noise, 2026-09-10):
## is the corridor a passage a body can enter, walk and leave, do AMP and PHASE
## change one thing each, and is the visible wall honest about not colliding?
##
## Stands up the ACTUAL museum hall with its artifacts (probe_wcn_intro.gd's
## pattern), hands the museum the REAL necklace hand file (the stamp under
## wavefunctions|sine space is keyed to an old pearl name; the map opts into
## artifact_placement=map besides), finds the SineWallCorridor and drives its
## panel by EMITTING the sliders' and buttons' own signals — no tracked hand.
##
##   godot --rendering-method gl_compatibility --path . --xr-mode off --script res://commons/testing/probe_wcn_sine_space.gd -- --capture
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_wcn_sine_space.gd
##
## Writes res://ada_run/waves_chance_noise/WaveFunctions_Sine_Space/probe_sine_space.json
## (and probe_sine_space_approach.png / probe_sine_space_inside.png under --capture).
var checks := 0
var failures: Array[String] = []
var measurements: Dictionary = {}
const MAP := "WaveFunctions_Sine_Space"
const OUT := "res://ada_run/waves_chance_noise/WaveFunctions_Sine_Space/"
const MAP_CELL := Vector2i(6, 4)

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[wcn-sine] ", "PASS " if ok else "FAIL ", message)

func run() -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() == "headless":
		check(false, "PNG capture requires a rendered window; omit --headless, or omit --capture for logic only")
		_finish(); return
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl := "res://ada_run/waves_chance_noise/wcn-probe-control.json"
	em.set("EM_CONTROL", ctl); em.set("_overrides_path", ctl + ".unused")
	em.set("_hand_path", "res://ada_run/necklace_hand.json")   # the REAL hand, on purpose
	em.set("start_chapter", "wavefunctions"); em.set("start_map", MAP)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/em_layout.json"))
	layout.get_or_add("stream", {})["bodies"] = 1
	em.set("_layout", layout)
	var f := FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "wavefunctions", "dollhouse": 0, "grid_pack": 1})); f.close()
	root.add_child(em); current_scene = em
	await create_timer(1.0).timeout
	em.set_process(false); em.call("flush_stamps")
	var player: Node = em.get("_player")
	if player != null: player.set_process(false); player.set_physics_process(false)
	var seg: Node3D
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map", "") == MAP: seg = rec.node; break
	check(seg != null, "the hall exists in the active museum")
	if seg == null:
		_finish(); return
	for i in range(30): await process_frame
	var vest: int = int(em.get("VESTIBULE_H"))

	# ── 1. built where the map put it, turned along the antechamber ──────────
	var cor: Node3D
	var cells: Dictionary = {}
	for record: Dictionary in em.get("_edit_records"):
		var node: Node = record.get("node")
		if node == null or node.get_script() == null: continue
		var sp: String = str(node.get_script().resource_path)
		if sp.ends_with("SineWallCorridor.gd"): cor = node; cells["corridor"] = record.get("tile_cell", [])
		elif sp.ends_with("sine_wall_explanation.gd"): cells["sine_wall_explanation"] = record.get("tile_cell", [])
		elif sp.ends_with("sine_space_explanation.gd"): cells["sine_space_explanation"] = record.get("tile_cell", [])
		elif sp.ends_with("SineSpace.gd"): cells["sine_space"] = record.get("tile_cell", []); measurements["sine_space_y"] = seg.to_local((node as Node3D).global_position).y
	if cor == null:
		for n in seg.find_children("*", "Node3D", true, false):
			if n.get_script() != null and str(n.get_script().resource_path).ends_with("SineWallCorridor.gd"): cor = n; break
	check(cor != null, "sine_wall_corridor is built in the hall")
	if cor == null:
		_finish(); return
	measurements["cells"] = cells
	var cc: Array = cells.get("corridor", [])
	if cc.size() >= 2:
		check(int(cc[0]) == MAP_CELL.x and int(cc[1]) - vest == MAP_CELL.y, "built at the map's cell (6,4), not a bench bead (got %s)" % str(cc))
	for pair in [["sine_wall_explanation", Vector2i(1, 2)], ["sine_space_explanation", Vector2i(11, 2)]]:
		var c: Array = cells.get(pair[0], [])
		check(c.size() >= 2 and int(c[0]) == (pair[1] as Vector2i).x and int(c[1]) - vest == (pair[1] as Vector2i).y, "%s stands in its corner %s (got %s)" % [pair[0], str(pair[1]), str(c)])
	var axis: Vector3 = cor.to_global(Vector3(0, 0, 1)) - cor.global_position
	measurements["axis_world"] = [axis.x, axis.y, axis.z]
	check(absf(axis.x - 1.0) < 0.05 and absf(axis.z) < 0.05, "rotation 90 honoured: the passage runs along world +x (east)")
	var ct: Dictionary = cor.call("contract")
	measurements["contract"] = ct
	check(is_equal_approx(float(ct.amplitude), 0.2) and is_equal_approx(float(ct.phase_offset), 0.6) and is_equal_approx(float(ct.frequency), 5.2),
		"the placed scene's declared values reached the script (amp 0.2, offset 0.6, 5.2 cycles)")
	check(is_equal_approx(float(ct.length), 8.0) and is_equal_approx(float(ct.width), 2.0) and int(ct.layers) == 3, "8 m by 2 m, three layers")
	check(bool(ct.animate), "the phase animation runs as placed")
	check(not bool(ct.collision) and not bool(cor.call("has_wall_collision")), "the walls carry NO collision shape: visible surfaces only, as the final says")
	check(str(ct.cut) == "skin", "the shipped skin fabric")
	# where the mouths are: the wall meshes' extent in the hall
	var box: AABB = _mesh_extent(cor)
	var lo: Vector3 = seg.to_local(box.position); var hi: Vector3 = seg.to_local(box.position + box.size)
	measurements["extent_local"] = [[lo.x, lo.y, lo.z - vest], [hi.x, hi.y, hi.z - vest]]
	check(absf(lo.x - 2.5) < 0.3 and absf(hi.x - 10.5) < 0.3, "the west mouth is at x 2.5 and the east mouth at x 10.5 (%.1f..%.1f)" % [lo.x, hi.x])
	check(lo.z - vest > 3.0 and hi.z - vest < 6.0, "the walls stay inside rows 3–5 of the antechamber (z %.1f..%.1f)" % [lo.z - vest, hi.z - vest])
	check(lo.y > -0.05 and lo.y < 0.1, "the passage floor sits on the deck (%.2f m)" % lo.y)
	check(hi.y > 3.5, "the walls stand about 4 m tall (%.1f m)" % hi.y)

	# ── 2. the panel at the west mouth, reachable ─────────────────────────────
	var panel: Node = cor.get_node_or_null("Panel")
	check(panel != null, "the entrance panel exists")
	check(panel != null and panel.get_meta("em_local_instrument", false), "the panel is marked a local instrument")
	var amp: Node = panel.find_child("Param_0", true, false) if panel != null else null
	var pha: Node = panel.find_child("Param_1", true, false) if panel != null else null
	check(amp != null and pha != null, "AMP and PHASE sliders exist")
	if amp != null:
		var pl: Vector3 = seg.to_local(amp.global_position)
		measurements["panel_local"] = [pl.x, pl.y, pl.z - vest]
		check(pl.y > 0.8 and pl.y < 1.4, "the sliders are at hand height (%.2f m)" % pl.y)
		check(pl.x < 3.0, "beside the WEST mouth, where a body arrives (x %.1f)" % pl.x)
		check(pl.z - vest > 5.0, "on the south side of the mouth, out of the approach (z %.1f)" % (pl.z - vest))
	var readout: Label3D = cor.get_node_or_null("Readout")
	check(readout != null and readout.text.begins_with("amp 0.20 m"), "the readout prints the amplitude in force")
	check(readout != null and readout.text.contains("gap "), "and the gap range the walls make")

	# ── 3. one variable at a time ────────────────────────────────────────────
	var gr0: Array = cor.call("gap_range")
	measurements["gap_declared"] = gr0
	# PHASE to half a turn: the walls copy each other, the gap is the width everywhere
	if pha != null:
		pha.set_normalized_value(1.0); pha.emit_signal("slider_moved", 1.0)
		await process_frame
		var c1: Dictionary = cor.call("contract")
		check(absf(float(c1.phase_offset) - PI) < 0.01, "PHASE at the top of its travel is half a turn (%.3f rad)" % float(c1.phase_offset))
		check(is_equal_approx(float(c1.amplitude), 0.2) and is_equal_approx(float(c1.frequency), 5.2), "and left amplitude and frequency alone — one variable")
		var gr1: Array = cor.call("gap_range")
		measurements["gap_half_turn"] = gr1
		check(absf(float(gr1[0]) - 2.0) < 0.01 and absf(float(gr1[1]) - 2.0) < 0.01, "at half a turn the gap is 2.00 m everywhere: a snake of constant width (%.2f–%.2f)" % [float(gr1[0]), float(gr1[1])])
		for zr in [0.13, 0.5, 0.77]:
			var d: Array = cor.call("wall_displacements", zr)
			check(absf(float(d[0]) + float(d[1])) < 0.001, "at z %.2f the right wall's displacement is the left's negated (%+.3f, %+.3f)" % [zr, float(d[0]), float(d[1])])
		# PHASE to zero: the walls agree and the passage breathes
		pha.set_normalized_value(0.0); pha.emit_signal("slider_moved", 0.0)
		await process_frame
		var gr2: Array = cor.call("gap_range")
		measurements["gap_in_step"] = gr2
		check(float(gr2[0]) < 1.5 and float(gr2[1]) > 2.5 and absf(float(gr2[0]) + float(gr2[1]) - 4.0) < 0.05, "at zero offset the gap breathes about the width (%.2f–%.2f m)" % [float(gr2[0]), float(gr2[1])])
	# AMP to the top: both walls come in, and even then a body fits
	if amp != null:
		amp.set_normalized_value(1.0); amp.emit_signal("slider_moved", 1.0)
		await process_frame
		var c2: Dictionary = cor.call("contract")
		check(absf(float(c2.amplitude) - 0.45) < 0.01, "AMP at the top is the exported maximum, 0.45 m (%.3f)" % float(c2.amplitude))
		check(absf(float(c2.phase_offset)) < 0.01, "and did not move the phase offset")
		var gr3: Array = cor.call("gap_range")
		measurements["gap_amp_max_in_step"] = gr3
		check(float(gr3[0]) > 0.55, "the narrowest gap the sliders can make still passes a body (%.2f m)" % float(gr3[0]))
	# ── 4. FREEZE stops the phase; RESET returns the declared values and the handles ──
	var ph_a: float = float((cor.call("contract") as Dictionary).phase)
	for i in range(20): await process_frame
	var ph_b: float = float((cor.call("contract") as Dictionary).phase)
	check(ph_b > ph_a, "while running, the phase advances over 20 frames (%.3f -> %.3f rad)" % [ph_a, ph_b])
	check(_press(panel, "Btn_0"), "FREEZE pressed by emitting the push button's signal (programmatic, no hand)")
	await process_frame
	check(not bool(cor.call("is_animating")), "the animation stopped")
	var ph_c: float = float((cor.call("contract") as Dictionary).phase)
	for i in range(20): await process_frame
	var ph_d: float = float((cor.call("contract") as Dictionary).phase)
	check(is_equal_approx(ph_c, ph_d), "and the phase holds while frozen")
	check(_press(panel, "Btn_1"), "RESET pressed through its signal")
	await process_frame
	var c3: Dictionary = cor.call("contract")
	check(is_equal_approx(float(c3.amplitude), 0.2) and is_equal_approx(float(c3.phase_offset), 0.6) and bool(c3.animate), "RESET returns the declared amplitude, offset and running state")
	if amp != null and pha != null:
		check(absf(float(amp.get_normalized_value()) - 0.2 / 0.45) < 0.02 and absf(float(pha.get_normalized_value()) - 0.6 / PI) < 0.02, "and the two handles go back where the placement put them")
	# animation direction: crests travel toward the entrance (-z local, west)
	var zr_probe: float = 0.5
	var d_before: float = float((cor.call("wall_displacements", zr_probe) as Array)[0])
	var zr_west: float = zr_probe - 0.02
	var d_west_before: float = float((cor.call("wall_displacements", zr_west) as Array)[0])
	for i in range(30): await process_frame
	var d_after: float = float((cor.call("wall_displacements", zr_probe) as Array)[0])
	measurements["drift"] = {"at_z": d_before, "at_z_after": d_after, "just_west_before": d_west_before}
	check(absf(d_after - d_before) > 0.0005, "running again, the wall at one place changes over 30 frames")

	# ── 5. the passage and the museum's route: a body's capsule ───────────────
	var space := seg.get_world_3d().direct_space_state
	var cap := CapsuleShape3D.new(); cap.radius = 0.22; cap.height = 1.6
	var q := PhysicsShapeQueryParameters3D.new(); q.shape = cap
	for route in [["passage, west mouth to east mouth", Vector3(1.5, 0.81, 4.5), Vector3(10.0, 0, 0)],
			["door to the antechamber", Vector3(7.5, 0.81, 0.5), Vector3(0, 0, 2.0)],
			["antechamber east to the bridge head", Vector3(7.5, 0.81, 2.5), Vector3(3.0, 0, 0)],
			["bridge head south onto the bridge", Vector3(10.5, 0.81, 2.5), Vector3(0, 0, 5.0)],
			["from the east mouth to the bridge head", Vector3(10.5, 0.81, 4.5), Vector3(0, 0, 2.0)]]:
		q.transform = Transform3D(Basis.IDENTITY, seg.to_global(Vector3(route[1].x, route[1].y, route[1].z + vest)))
		q.motion = route[2]
		var frac: float = space.cast_motion(q)[0]
		measurements["walk_" + str(route[0]).replace(" ", "_").replace(",", "")] = frac
		check(frac > 0.99, "a body walks the %s (%.2f of the way)" % [route[0], frac])
	# and through a crest: the visible wall does not stop a body
	q.transform = Transform3D(Basis.IDENTITY, seg.to_global(Vector3(6.5, 0.81, 2.6 + vest)))
	q.motion = Vector3(0, 0, 3.6)
	var through: float = space.cast_motion(q)[0]
	measurements["walk_through_both_walls"] = through
	check(through > 0.99, "a body walks straight through both walls, north to south (%.2f): the surfaces are visible, not colliding" % through)
	check(cor.scale.is_equal_approx(Vector3.ONE), "the subject's scale is what the map asked (1)")

	if "--capture" in OS.get_cmdline_user_args():
		var cam := Camera3D.new(); em.add_child(cam); cam.fov = 70
		cam.global_position = seg.to_global(Vector3(0.9, 1.6, 4.5 + vest)); cam.look_at(seg.to_global(Vector3(6.5, 1.2, 4.5 + vest)))
		for i in range(30): cam.make_current(); await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + "probe_sine_space_approach.png")
		cam.global_position = seg.to_global(Vector3(5.0, 1.6, 4.6 + vest)); cam.look_at(seg.to_global(Vector3(9.5, 1.3, 4.2 + vest)))
		for i in range(20): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + "probe_sine_space_inside.png")
	_finish()

func _press(panel: Node, btn_name: String) -> bool:
	if panel == null: return false
	var btn: Node = panel.find_child(btn_name, true, false)
	var area: Node = btn.get_node_or_null("InteractableAreaButton") if btn != null else null
	if area == null or not area.has_signal("button_pressed"): return false
	area.emit_signal("button_pressed", area)
	return true

func _mesh_extent(node: Node) -> AABB:
	var merged := AABB(); var first := true
	for name in ["LeftWall", "RightWall", "Floor"]:
		var mi: MeshInstance3D = node.get_node_or_null(name)
		if mi == null or mi.mesh == null: continue
		var box: AABB = mi.global_transform * mi.get_aabb()
		merged = box if first else merged.merge(box); first = false
	return merged

func _finish() -> void:
	var report := {"map": MAP, "checks": checks, "failures": failures, "measurements": measurements,
		"control_path": "slider_moved and button_pressed emitted programmatically on the panel's own controls; no tracked hand",
		"hand_file": "ada_run/necklace_hand.json (real)", "headset_verified": false,
		"engine": Engine.get_version_info().string, "physics_fps": Engine.physics_ticks_per_second}
	var f := FileAccess.open(OUT + "probe_sine_space.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  ")); f.close()
	print("[wcn-sine] ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
