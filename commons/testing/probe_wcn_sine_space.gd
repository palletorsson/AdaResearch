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
## Screenshots and audio go to the evidence root, ada_encyclopedia/captures/ada-run/ (2026-09-14);
## the JSON record stays in OUT, where it is committed.
var _evidence: String = preload("res://commons/testing/evidence_root.gd").dir("waves_chance_noise/WaveFunctions_Sine_Space") + "/"
const MAP_CELL := Vector2i(6, 10)

func _initialize() -> void: run.call_deferred()

## True under the live harness (probe_live.tscn, project startup with autoloads);
## false under --script, where the desktop rig cannot compile.
func _live() -> bool:
	return str(get_script().resource_path).ends_with("_live.gd")

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
	var vest: int = int(em.get("VESTIBULE_H")) + 6 # preserved corridor coordinates, after new forecourt + 6 # preserved corridor coordinates, after new forecourt

	# ── 1. built where the map put it, turned along the antechamber ──────────
	var cor: Node3D
	var cells: Dictionary = {}
	for record: Dictionary in em.get("_edit_records"):
		var node: Node = record.get("node")
		if node == null or not seg.is_ancestor_of(node) or node.get_script() == null: continue
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
	# _edit_records keeps MAP cells (observed 2026-09-10: [6, 4]); the vestibule offset lives in world z only
	if cc.size() >= 2:
		check(int(cc[0]) == MAP_CELL.x and int(cc[1]) == MAP_CELL.y, "built at the map's cell (6,10), not a bench bead (got %s)" % str(cc))
	# the one remaining case stands in the row-1 nook, off every route (2026-09-10: at (1,2) it cut the
	# west approach into a pocket; sine_space_explanation left the hall, its display 4 m off its origin)
	var case_cell: Array = cells.get("sine_wall_explanation", [])
	check(case_cell.size() >= 2 and int(case_cell[0]) == 1 and int(case_cell[1]) == 7, "sine_wall_explanation stands in the north-west nook (1,7) (got %s)" % str(case_cell))
	check(not cells.has("sine_space_explanation"), "sine_space_explanation is no longer placed in this hall")
	for record: Dictionary in em.get("_edit_records"):
		var node: Node = record.get("node")
		if node == null or not seg.is_ancestor_of(node) or node.get_script() == null: continue
		var sp2: String = str(node.get_script().resource_path)
		if sp2.ends_with("sine_wall_explanation.gd"):
			var ab: AABB = _all_mesh_extent(node)
			var alo: Vector3 = seg.to_local(ab.position); var ahi: Vector3 = seg.to_local(ab.position + ab.size)
			measurements["sine_wall_explanation_extent_local"] = [[alo.x, alo.y, alo.z - vest], [ahi.x, ahi.y, ahi.z - vest]]
			measurements["sine_wall_explanation_origin_y"] = seg.to_local((node as Node3D).global_position).y
			# the museum lane does not apply the token's -0.4; the case's own base is 0.2 below its origin
			check(ahi.y > 0.6, "sine_wall_explanation's top is above 0.6 m (bottom %.2f, top %.2f)" % [alo.y, ahi.y])
			check(alo.x >= 0.9 and ahi.x <= 3.0 and alo.z - vest >= 0.9 and ahi.z - vest <= 2.1, "and its body stays inside the nook cells (1..2, 1)")
	var axis: Vector3 = cor.to_global(Vector3(0, 0, 1)) - cor.global_position
	measurements["axis_world"] = [axis.x, axis.y, axis.z]
	check(absf(axis.x - 1.0) < 0.05 and absf(axis.z) < 0.05, "rotation 90 honoured: the passage runs along world +x (east)")
	var ct: Dictionary = cor.call("contract")
	measurements["contract"] = ct
	# 7 m / 4.5 cycles since the first museum run (the 8 m corridor's east mouth stood in the bridge head's cell)
	check(is_equal_approx(float(ct.amplitude), 0.2) and is_equal_approx(float(ct.phase_offset), 0.6) and is_equal_approx(float(ct.frequency), 4.5),
		"the placed scene's declared values reached the script (amp 0.2, offset 0.6, 4.5 cycles)")
	check(is_equal_approx(float(ct.length), 7.0) and is_equal_approx(float(ct.width), 2.0) and int(ct.layers) == 3, "7 m by 2 m, three layers")
	check(bool(ct.animate), "the phase animation runs as placed")
	check(not bool(ct.collision) and not bool(cor.call("has_wall_collision")), "the walls carry NO collision shape: visible surfaces only, as the final says")
	check(str(ct.cut) == "skin", "the shipped skin fabric")
	# where the mouths are: the wall meshes' extent in the hall
	var box: AABB = _mesh_extent(cor)
	var lo: Vector3 = seg.to_local(box.position); var hi: Vector3 = seg.to_local(box.position + box.size)
	measurements["extent_local"] = [[lo.x, lo.y, lo.z - vest], [hi.x, hi.y, hi.z - vest]]
	check(absf(lo.x - 3.0) < 0.3 and absf(hi.x - 10.0) < 0.3, "the west mouth is at x 3.0 and the east mouth at x 10.0, clear of the bridge head's cell (%.1f..%.1f)" % [lo.x, hi.x])
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
	# the visual pass of 12 September: the readout fits its casing (four lines, none long) and
	# the passage's two thresholds are marked on the floor
	if readout != null:
		var rl: PackedStringArray = readout.text.split("\n")
		var longest: int = 0
		for l in rl: longest = maxi(longest, l.length())
		measurements["readout_lines"] = Array(rl)
		check(rl.size() == 4 and longest <= 36, "the readout is four lines of at most 36 characters inside its plate (%d lines, longest %d)" % [rl.size(), longest])
		var pl2: MeshInstance3D = cor.get_node_or_null("ReadoutPlate")
		check(pl2 != null and (pl2.mesh as BoxMesh).size.y >= 0.34, "the plate is tall enough for them (%.2f m)" % ((pl2.mesh as BoxMesh).size.y if pl2 != null else 0.0))
	check(cor.get_node_or_null("Threshold_in") != null and cor.get_node_or_null("Threshold_out") != null, "the entrance and the exit of the passage are marked on the floor")

	# ── 3. one variable at a time ────────────────────────────────────────────
	var gr0: Array = cor.call("gap_range")
	measurements["gap_declared"] = gr0
	# PHASE to half a turn: the walls copy each other, the gap is the width everywhere
	if pha != null:
		pha.set_normalized_value(1.0); pha.emit_signal("slider_moved", 1.0)
		await process_frame
		var c1: Dictionary = cor.call("contract")
		check(absf(float(c1.phase_offset) - PI) < 0.01, "PHASE at the top of its travel is half a turn (%.3f rad)" % float(c1.phase_offset))
		check(is_equal_approx(float(c1.amplitude), 0.2) and is_equal_approx(float(c1.frequency), float(ct.frequency)), "and left amplitude and frequency alone — one variable")
		var gr1: Array = cor.call("gap_range")
		measurements["gap_half_turn"] = gr1
		check(absf(float(gr1[0]) - 2.0) < 0.01 and absf(float(gr1[1]) - 2.0) < 0.01, "at half a turn the local-X gap is 2.00 m at every sampled column (%.2f–%.2f)" % [float(gr1[0]), float(gr1[1])])
		for zr in [0.13, 0.5, 0.77]:
			var d: Array = cor.call("wall_displacements", zr)
			check(absf(float(d[0]) + float(d[1])) < 0.001, "at z %.2f the right wall's displacement is the left's negated (%+.3f, %+.3f)" % [zr, float(d[0]), float(d[1])])
		# PHASE to zero: the walls agree and the passage breathes
		pha.set_normalized_value(0.0); pha.emit_signal("slider_moved", 0.0)
		await process_frame
		var gr2: Array = cor.call("gap_range")
		measurements["gap_in_step"] = gr2
		check(float(gr2[0]) < 1.5 and float(gr2[1]) > 2.5 and absf(float(gr2[0]) + float(gr2[1]) - 4.0) < 0.05, "at zero offset the gap breathes about the width (%.2f–%.2f m)" % [float(gr2[0]), float(gr2[1])])
	# AMP to the top: check local-X separation; capsule clearance is a separate test
	if amp != null:
		amp.set_normalized_value(1.0); amp.emit_signal("slider_moved", 1.0)
		await process_frame
		var c2: Dictionary = cor.call("contract")
		check(absf(float(c2.amplitude) - 0.45) < 0.01, "AMP at the top is the exported maximum, 0.45 m (%.3f)" % float(c2.amplitude))
		check(absf(float(c2.phase_offset)) < 0.01, "and did not move the phase offset")
		var gr3: Array = cor.call("gap_range")
		measurements["gap_amp_max_in_step"] = gr3
		check(float(gr3[0]) > 0.55, "the sampled local-X gap at maximum AMP remains above 0.55 m (%.2f m)" % float(gr3[0]))
		amp.set_normalized_value(0.0); amp.emit_signal("slider_moved", 0.0)
		await process_frame
		var flat_gap: Array = cor.call("gap_range")
		var flat_colour: Color = cor.call("_evaluate_color", 0.0)
		check(is_equal_approx(float(flat_gap[0]), 2.0) and is_equal_approx(float(flat_gap[1]), 2.0), "AMP zero produces two flat walls")
		check(is_finite(flat_colour.r) and is_finite(flat_colour.g) and is_finite(flat_colour.b), "AMP zero keeps finite vertex colours")
	# Check a time-bearing phase against an independent layer sum. At phase 0
	# the former double-phase bug was invisible to all gap-range assertions.
	var test_phase := 0.73
	cor.set("phase", test_phase)
	if amp != null:
		amp.set_normalized_value(0.2 / 0.45); amp.emit_signal("slider_moved", 0.2 / 0.45)
	var expected_left := 0.0
	var zr := 0.37
	var bf: float = float(cor.get("base_frequency"))
	for layer: Dictionary in cor.get("wave_layers"):
		expected_left += 0.2 * float(layer.amp_mul) * sin(TAU * bf * float(layer.freq_mul) * (zr - 0.5) + test_phase + float(layer.phase_shift))
	var actual_left: float = float((cor.call("wall_displacements", zr) as Array)[0])
	check(absf(actual_left - expected_left) < 0.000001, "animation phase contributes exactly once to the displacement")
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

	# ── 3b. MINIMUM CLEARANCE ACROSS EVERYTHING THE PANEL CAN REACH ───────────────────
	# AMP 0..amplitude_max, PHASE offset 0..pi, and the running phase through a full turn,
	# swept on the script's own displacement function with no rebuild in between (one frame,
	# no await, so _process cannot run on a half-set state). Two numbers per state: the
	# local-X gap the readout prints, and the true shortest distance between the two wall
	# curves, which is smaller wherever the walls slope.
	var keep := {"a": float(cor.get("base_amplitude")), "o": float(cor.get("phase_offset_between_walls")), "p": float(cor.get("phase"))}
	var W_: float = float(cor.get("corridor_width"))
	var Lc: float = float(cor.get("corridor_length"))
	var cols: int = int(cor.get("columns"))
	var amax: float = float(cor.get("amplitude_max"))
	var dz: float = Lc / float(cols - 1)
	var win: int = 20
	var sweep_min_x := {"gap": INF}
	var sweep_min_n := {"gap": INF}
	var states := 0
	for ai in range(5):
		var a: float = amax * float(ai) / 4.0
		for oi in range(9):
			var o: float = PI * float(oi) / 8.0
			for pi_ in range(16):
				var ph: float = TAU * float(pi_) / 16.0
				cor.set("base_amplitude", a); cor.set("phase_offset_between_walls", o); cor.set("phase", ph)
				var xl := PackedFloat32Array(); var xr := PackedFloat32Array()
				xl.resize(cols); xr.resize(cols)
				var gx := INF
				for c in range(cols):
					var d: Array = cor.call("wall_displacements", c / float(cols - 1))
					xl[c] = -W_ * 0.5 + float(d[0]); xr[c] = W_ * 0.5 - float(d[1])
					gx = minf(gx, xr[c] - xl[c])
				# EXACT BY CONSTRUCTION: the same-z pair already gives gx, so no pair further
				# apart along the passage than gx can be nearer. The window is sized per state.
				var gn := gx
				win = mini(cols, int(ceil(gx / dz)) + 1)
				if a <= 0.0:
					win = 0   # flat walls: the gap is the width everywhere and gx is exact
				for i in range(cols):
					for j in range(maxi(0, i - win), mini(cols, i + win + 1)):
						var ddx: float = xr[j] - xl[i]
						var ddz: float = float(j - i) * dz
						gn = minf(gn, sqrt(ddx * ddx + ddz * ddz))
				states += 1
				if gx < float(sweep_min_x["gap"]): sweep_min_x = {"gap": gx, "amp": a, "offset": o, "phase": ph}
				if gn < float(sweep_min_n["gap"]): sweep_min_n = {"gap": gn, "amp": a, "offset": o, "phase": ph}
			# keep the runner's 16 s output watchdog fed: the sweep is millions of steps
			note("clearance sweep: AMP %.3f offset %.3f" % [a, o])
	cor.set("base_amplitude", keep["a"]); cor.set("phase_offset_between_walls", keep["o"]); cor.set("phase", keep["p"])
	measurements["clearance_sweep"] = {"states": states, "columns": cols, "window": "per state, ceil(local-X gap / column spacing) + 1 columns: exact",
		"min_x_gap": sweep_min_x, "min_true_clearance": sweep_min_n, "body_diameter_m": 0.44}
	note("clearance " + JSON.stringify(measurements["clearance_sweep"]))
	check(states == 720, "every reachable state swept: 5 amplitudes, 9 offsets, 16 running phases (%d)" % states)
	check(float(sweep_min_n["gap"]) <= float(sweep_min_x["gap"]) + 0.0001, "the true clearance is never larger than the local-X gap (%.3f vs %.3f m)" % [float(sweep_min_n["gap"]), float(sweep_min_x["gap"])])
	check(is_equal_approx(float(sweep_min_x["amp"]), amax) and absf(float(sweep_min_x["offset"])) < 0.001, "the passage is narrowest at full AMP with the walls in step (offset %.2f rad)" % float(sweep_min_x["offset"]))
	check(float(sweep_min_n["gap"]) > 0.44, "even there a 0.44 m body fits between the surfaces it sees (%.3f m)" % float(sweep_min_n["gap"]))

	# ── 3c. THE RUNNING ANIMATION'S BUDGET ──────────────────────────────────────────
	# While running, _process rebuilds both wall meshes every frame. Timed here on a
	# forced rebuild; collision is off in this placement, so no collider is rebuilt with it.
	var times: Array = []
	for k in range(10):
		cor.set("_last_signature", "")
		var t0 := Time.get_ticks_usec()
		cor.call("_build_corridor")
		times.append(float(Time.get_ticks_usec() - t0) / 1000.0)
	var tsum := 0.0
	var tmax := 0.0
	for t in times:
		tsum += float(t); tmax = maxf(tmax, float(t))
	measurements["rebuild_ms"] = {"mean": snappedf(tsum / times.size(), 0.01), "max": snappedf(tmax, 0.01)}
	note("rebuild " + JSON.stringify(measurements["rebuild_ms"]))
	# A FINDING, NOT A PASS: both walls are rebuilt through SurfaceTool every running frame
	# (about 8,400 vertices each). The check holds it to one desktop frame; what that costs
	# on a headset's mobile CPU is not measurable here and is reported as a risk.
	measurements["rebuild_ms"]["share_of_60hz_frame"] = snappedf((tsum / times.size()) / 16.667, 0.01)
	check(tsum / times.size() < 16.667, "a running frame's rebuild of both walls costs %.2f ms on average (max %.2f): %d%% of a 60 Hz frame on this desktop" % [tsum / times.size(), tmax, int(round(100.0 * (tsum / times.size()) / 16.667))])

	# ── 5. the passage and the museum's route: a body's capsule ───────────────
	var space := seg.get_world_3d().direct_space_state
	var cap := CapsuleShape3D.new(); cap.radius = 0.22; cap.height = 1.6
	var q := PhysicsShapeQueryParameters3D.new(); q.shape = cap
	# capsule bottom at 0.10 m: the passage floor is a 24 mm slab on the deck, a step a body takes
	# without noticing; the door route starts INSIDE the hall (the museum's gate stands in the doorway)
	for route in [["passage, west mouth to east mouth", Vector3(1.8, 0.9, 4.5), Vector3(9.0, 0, 0)],
			["door row into the antechamber", Vector3(7.5, 0.9, 1.5), Vector3(0, 0, 1.0)],
			["antechamber east to the bridge head", Vector3(7.5, 0.9, 2.5), Vector3(3.0, 0, 0)],
			["bridge head south onto the bridge", Vector3(10.5, 0.9, 2.5), Vector3(0, 0, 5.0)],
			["from the east mouth to the bridge head", Vector3(10.5, 0.9, 4.5), Vector3(0, 0, 2.0)],
			["west approach, door row down to the mouth", Vector3(1.5, 0.9, 2.5), Vector3(0, 0, 2.0)]]:
		q.transform = Transform3D(Basis.IDENTITY, seg.to_global(Vector3(route[1].x, route[1].y, route[1].z + vest)))
		q.motion = route[2]
		var frac: float = space.cast_motion(q)[0]
		measurements["walk_" + str(route[0]).replace(" ", "_").replace(",", "")] = frac
		if frac <= 0.99:
			measurements["blocked_" + str(route[0]).replace(" ", "_").replace(",", "")] = _what_blocks(seg, q, frac)
		check(frac > 0.99, "a body walks the %s (%.2f of the way)" % [route[0], frac])
	# and through a crest: the visible wall does not stop a body
	q.transform = Transform3D(Basis.IDENTITY, seg.to_global(Vector3(6.5, 0.9, 2.6 + vest)))
	q.motion = Vector3(0, 0, 3.0)   # to z 5.6: through both walls (3.24..5.78), short of the row-6 wall
	var through: float = space.cast_motion(q)[0]
	measurements["walk_through_both_walls"] = through
	if through <= 0.99:
		measurements["blocked_through_both_walls"] = _what_blocks(seg, q, through)
	check(through > 0.99, "a body walks straight through both walls, north to south (%.2f): the surfaces are visible, not colliding" % through)
	# the museum's own record of this hall as built: walk grid, seals, severance, bodies
	_dump_built_row(em)
	check(cor.scale.is_equal_approx(Vector3.ONE), "the subject's scale is what the map asked (1)")

	# ── ACTUAL DESKTOP INPUT (live harness only: the desktop rig names autoloads) ──
	# The rig stands at the west mouth, looks at FREEZE and left-clicks through the
	# input pipeline; then walks the passage west to east on ui_up, on the floor slab.
	if _live():
		var drv: Node = load("res://commons/testing/wcn_desktop_driver.gd").new()
		root.add_child(drv)   # a SceneTree has no add_child; the port maps root. to get_tree().root.
		var btn_freeze: Node = panel.find_child("Btn_0", true, false) if panel != null else null
		var stand: Vector3 = seg.to_global(Vector3(2.0, 0.0, 4.6 + vest))
		drv.call("spawn", stand, em)
		await create_timer(0.5).timeout
		var was_running: bool = bool(cor.call("is_animating"))
		var rec: Dictionary = await drv.call("press", btn_freeze, stand) if btn_freeze != null else {}
		await process_frame
		measurements["desktop_input"] = {"press": rec, "running_before": was_running, "running_after": bool(cor.call("is_animating"))}
		check(str(rec.get("hover", "")).contains("Btn_0") or str(rec.get("hover", "")).contains("InteractableAreaButton"), "the desktop pointer had FREEZE under the crosshair (%s)" % str(rec.get("hover", "")))
		check(was_running and not bool(cor.call("is_animating")), "a left click through the input pipeline froze the walls: actual desktop input, not an emitted signal")
		drv.get("rig").global_position = seg.to_global(Vector3(3.3, 0.05, 4.5 + vest))
		await physics_frame
		drv.call("aim_at", seg.to_global(Vector3(10.5, 1.2, 4.5 + vest)))
		var moved: Vector3 = await drv.call("walk", "ui_up", 40)
		if "--capture" in OS.get_cmdline_user_args():
			# mid-passage, as a visitor sees it walking east: walls either side, the east mouth ahead
			for i in range(15): await process_frame
			await create_timer(0.3, true, false, true).timeout
			root.get_texture().get_image().save_png(_evidence + "probe_sine_space_desktop_mid.png")
			measurements["desktop_input"]["mid_capture_pose"] = drv.call("pose")
		moved += await drv.call("walk", "ui_up", 40)
		var moved_local: Vector3 = seg.global_transform.basis.inverse() * moved
		measurements["desktop_input"]["walk_passage"] = [snappedf(moved_local.x, 0.01), snappedf(moved_local.z, 0.01)]
		check(moved_local.x > 5.5, "the rig walked the passage west to east on ui_up (%.2f m in 1.3 s), on the slab, through no wall" % moved_local.x)
		if "--capture" in OS.get_cmdline_user_args():
			# at the east mouth, turned toward the exit: the bridge head and the bridge south of it
			drv.call("aim_at", seg.to_global(Vector3(10.5, 1.0, 7.5 + vest)))
			for i in range(15): await process_frame
			await create_timer(0.3, true, false, true).timeout
			root.get_texture().get_image().save_png(_evidence + "probe_sine_space_desktop_exit.png")
			measurements["desktop_input"]["exit_capture_pose"] = drv.call("pose")
		# FREEZE once more from the same spot: the toggle sets the walls moving again, so the
		# later captures show the corridor as a visitor leaves it
		var rec2: Dictionary = await drv.call("press", btn_freeze, stand) if btn_freeze != null else {}
		await process_frame
		measurements["desktop_input"]["press_again"] = rec2
		measurements["desktop_input"]["running_after_second_click"] = bool(cor.call("is_animating"))
		check(bool(cor.call("is_animating")), "a second left click on FREEZE runs the walls again: the toggle, through the input pipeline")
		# ── MESH, COLLIDERS AND THE BODY, THROUGH THE POINTER ───────────────────────
		var census0: Array = _colliders(cor)
		measurements["desktop_input"]["colliders_before"] = census0
		# FREEZE first, through the pointer, so the mesh changes below are the controls' alone
		var frz: Dictionary = await drv.call("press", btn_freeze, stand)
		await process_frame
		check(not bool(cor.call("is_animating")), "FREEZE through the pointer again: frozen for the comparisons")
		var hl0: float = _mesh_hash(cor.get_node_or_null("LeftWall"))
		var hr0: float = _mesh_hash(cor.get_node_or_null("RightWall"))
		for i in range(20): await process_frame
		check(is_equal_approx(hl0, _mesh_hash(cor.get_node_or_null("LeftWall"))) and is_equal_approx(hr0, _mesh_hash(cor.get_node_or_null("RightWall"))),
			"frozen, the displayed walls do not change over 20 frames")
		# AMP, dragged
		var c_before: Dictionary = cor.call("contract")
		var dr_amp: Dictionary = await _drag_slider(drv, amp, stand)
		await process_frame
		var c_amp: Dictionary = cor.call("contract")
		var hl1: float = _mesh_hash(cor.get_node_or_null("LeftWall"))
		var hr1: float = _mesh_hash(cor.get_node_or_null("RightWall"))
		measurements["desktop_input"]["drag_amp"] = {"record": dr_amp, "amp_was": c_before.amplitude, "amp_now": c_amp.amplitude, "readout": cor.call("readout_text")}
		check(not is_equal_approx(float(c_amp.amplitude), float(c_before.amplitude)), "AMP dragged through the pointer changes the amplitude (%.3f -> %.3f m)" % [float(c_before.amplitude), float(c_amp.amplitude)])
		check(not is_equal_approx(hl1, hl0) and not is_equal_approx(hr1, hr0), "and it reaches BOTH displayed wall meshes")
		check(str(cor.call("readout_text")).begins_with("amp %.2f m" % float(c_amp.amplitude)), "and the readout prints the new amplitude")
		# PHASE, dragged
		var dr_ph: Dictionary = await _drag_slider(drv, pha, stand)
		await process_frame
		var c_ph: Dictionary = cor.call("contract")
		var hl2: float = _mesh_hash(cor.get_node_or_null("LeftWall"))
		var hr2: float = _mesh_hash(cor.get_node_or_null("RightWall"))
		measurements["desktop_input"]["drag_phase"] = {"record": dr_ph, "offset_was": c_amp.phase_offset, "offset_now": c_ph.phase_offset}
		check(not is_equal_approx(float(c_ph.phase_offset), float(c_amp.phase_offset)), "PHASE dragged through the pointer changes the offset (%.3f -> %.3f rad)" % [float(c_amp.phase_offset), float(c_ph.phase_offset)])
		check(not is_equal_approx(hr2, hr1) and is_equal_approx(hl2, hl1), "and moves the RIGHT wall's mesh while the left wall's stays exactly as it was: the offset belongs to one wall")
		var census1: Array = _colliders(cor)
		measurements["desktop_input"]["colliders_after_changes"] = census1
		check(census1 == census0, "no collider appeared, vanished or was left behind by the changes (%s)" % str(census1))
		check(not str(census1).contains("Wall"), "and none of them is a wall")
		# THE BODY, at the narrowest setting the panel can reach (set by method: this tests the
		# collider, not the control), walking the passage west to east with every contact kept
		cor.call("set_amplitude", float(cor.get("amplitude_max")))
		cor.call("set_phase_offset", 0.0)
		await process_frame
		var gr_walk: Array = cor.call("gap_range")
		var rig: CharacterBody3D = drv.get("rig")
		rig.global_position = seg.to_global(Vector3(3.3, 0.05, 4.5 + vest))
		rig.velocity = Vector3.ZERO
		await physics_frame
		drv.call("aim_at", seg.to_global(Vector3(10.5, 1.2, 4.5 + vest)))
		var start_w: Vector3 = rig.global_position
		var touched := {}
		var side_hits := 0
		Input.action_press("ui_up")
		for fr in range(90):
			await physics_frame
			for k in range(rig.get_slide_collision_count()):
				var col: KinematicCollision3D = rig.get_slide_collision(k)
				var who: Object = col.get_collider()
				var nm: String = str((who as Node).name) if who is Node else "?"
				var up: bool = col.get_normal().y > 0.7
				touched[nm + (" (floor)" if up else " (side)")] = int(touched.get(nm + (" (floor)" if up else " (side)"), 0)) + 1
				if not up and who is Node and cor.is_ancestor_of(who as Node):
					side_hits += 1
		Input.action_release("ui_up")
		for i in range(3): await physics_frame
		var moved_w: Vector3 = seg.global_transform.basis.inverse() * (rig.global_position - start_w)
		measurements["desktop_input"]["body_walk_narrowest"] = {"gap_range": gr_walk, "moved": [snappedf(moved_w.x, 0.01), snappedf(moved_w.z, 0.01)], "contacts": touched}
		note("body walk " + JSON.stringify(measurements["desktop_input"]["body_walk_narrowest"]))
		check(moved_w.x > 5.5, "at the narrowest setting the player's own body walks the passage (%.2f m east)" % moved_w.x)
		check(side_hits == 0, "and nothing of the corridor ever pushed it sideways: its contacts were %s" % str(touched))
		# RESET, pressed
		var rst_btn: Node = panel.find_child("Btn_1", true, false)
		var rst: Dictionary = await drv.call("press", rst_btn, stand) if rst_btn != null else {}
		await process_frame
		var c_r: Dictionary = cor.call("contract")
		var decl: Dictionary = cor.call("declared")
		measurements["desktop_input"]["press_reset"] = {"hover": str(rst.get("hover", "")).right(40), "contract": c_r}
		check(str(rst.get("hover", "")).contains("Btn_1"), "RESET: the crosshair was on Btn_1 itself (%s)" % str(rst.get("hover", "")).right(40))
		check(is_equal_approx(float(c_r.amplitude), float(decl.get("amplitude", -1.0))) and is_equal_approx(float(c_r.phase_offset), float(decl.get("phase_offset", -1.0))) and bool(c_r.animate) == bool(decl.get("animate", false)),
			"RESET through the pointer returns the declared amplitude, offset and running state (%.2f m, %.2f rad, %s)" % [float(c_r.amplitude), float(c_r.phase_offset), str(c_r.animate)])
		var hr3: float = _mesh_hash(cor.get_node_or_null("RightWall"))
		for i in range(20): await process_frame
		check(not is_equal_approx(hr3, _mesh_hash(cor.get_node_or_null("RightWall"))), "running again, the displayed wall changes over 20 frames")
		check(_colliders(cor) == census0, "and the collider census is still what it was before anything was touched")
		await drv.call("teardown")
		measurements["desktop_input"]["log"] = drv.get("log")
		measurements["desktop_input"]["walker_cam_guard_stopped"] = drv.get("walker_cam_guard_stopped")
		await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		var cam := Camera3D.new(); em.add_child(cam); cam.fov = 70
		cam.global_position = seg.to_global(Vector3(0.9, 1.6, 4.5 + vest)); cam.look_at(seg.to_global(Vector3(6.5, 1.2, 4.5 + vest)))
		for i in range(30): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(_evidence + "probe_sine_space_approach.png")
		# inside: from just within the west mouth, looking down the passage to the east mouth
		cam.global_position = seg.to_global(Vector3(3.4, 1.55, 4.5 + vest)); cam.look_at(seg.to_global(Vector3(10.0, 1.1, 4.5 + vest)))
		for i in range(20): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(_evidence + "probe_sine_space_inside.png")
		# the entrance panel and readout from where a body stands at the west mouth
		# (every capture re-asserts the camera: another node made its own current between shots)
		if panel != null:
			var pp: Vector3 = (panel as Node3D).global_position
			cam.global_position = seg.to_global(Vector3(2.0, 1.5, 4.4 + vest))
			cam.look_at(pp + seg.global_transform.basis * Vector3(0.0, 0.2, 0.0))
			for i in range(20): cam.make_current(); await process_frame
			await create_timer(0.3, true, false, true).timeout
			root.get_texture().get_image().save_png(_evidence + "probe_sine_space_panel.png")
		# the basin from the bridge head: what stands below and beside the museum's route
		cam.global_position = seg.to_global(Vector3(10.5, 1.7, 6.2 + vest)); cam.look_at(seg.to_global(Vector3(9.0, 0.3, 16.0 + vest)))
		for i in range(20): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(_evidence + "probe_sine_space_bridge.png")
		# the whole antechamber from above the door: passage, mouths, nook, panel, route
		cam.global_position = seg.to_global(Vector3(6.5, 7.5, 0.2 + vest)); cam.look_at(seg.to_global(Vector3(6.5, 0.0, 4.6 + vest)))
		for i in range(20): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(_evidence + "probe_sine_space_overview.png")
	# the museum's own verdict on this body: a venue, sealing nothing, severing nothing
	var severed: Array = em.get("_seg_severed") if em.get("_seg_severed") != null else []
	var sev_tokens: Array = []
	for s in severed: sev_tokens.append(str((s as Dictionary).get("token", "")))
	var walk_inside: Dictionary = em.get("_walk_inside") if em.get("_walk_inside") != null else {}
	measurements["museum_severed_tokens"] = sev_tokens
	measurements["museum_severed"] = severed
	measurements["museum_walk_inside"] = walk_inside.keys()
	check(not sev_tokens.has("sine_wall_corridor"), "the museum did not report the corridor as severing the hall")
	# the floor slab is a collider, so the passage is this body's ground in the walk map (not a venue):
	# nothing else is dealt into it, and the route beside it survives
	check(not walk_inside.has("sine_wall_corridor"), "the museum sealed the passage's cells as the corridor's own ground (not WALK-INSIDE)")
	check(sev_tokens.is_empty(), "no body in this hall severs the museum's route (severed: %s)" % str(sev_tokens))
	_finish()

## Which colliders stop a capsule at the point where its cast stopped.
func _what_blocks(seg: Node3D, q: PhysicsShapeQueryParameters3D, frac: float) -> Array:
	var stop := PhysicsShapeQueryParameters3D.new()
	stop.shape = q.shape
	stop.transform = Transform3D(Basis.IDENTITY, q.transform.origin + q.motion * minf(frac + 0.03, 1.0))
	var out: Array = []
	for h in seg.get_world_3d().direct_space_state.intersect_shape(stop, 8):
		var c: Node = h.collider
		var owner_path: String = str(c.get_path()) if c != null else "?"
		var p: Vector3 = seg.to_local((c as Node3D).global_position) if c is Node3D else Vector3.ZERO
		out.append({"collider": owner_path.get_slice("/", owner_path.get_slice_count("/") - 1), "path": owner_path.right(90), "at": [snappedf(p.x, 0.01), snappedf(p.y, 0.01), snappedf(p.z, 0.01)]})
	return out

func _dump_built_row(em: Node) -> void:
	var rows: Array = em.get("_built") if em.get("_built") != null else []
	var mine: Dictionary = {}
	for r in rows:
		if str((r as Dictionary).get("map", "")) == MAP: mine = r
	if mine.is_empty() and not rows.is_empty(): mine = rows[rows.size() - 1]
	if mine.is_empty(): return
	measurements["built_cells"] = mine.get("cells", [])
	measurements["built_seals"] = mine.get("seals", [])
	measurements["built_severed"] = mine.get("severed", [])
	measurements["built_refused"] = mine.get("refused", [])
	var toks: Array = []
	for b in mine.get("bodies", []):
		toks.append([str((b as Dictionary).get("token", "")), (b as Dictionary).get("world", []), (b as Dictionary).get("tile_cell", [])])
	measurements["built_bodies"] = toks

func note(message: String) -> void:
	print("[wcn-sine] note: ", message)

## A fingerprint of a displayed wall: a weighted sum over every seventh vertex.
func _mesh_hash(mi: MeshInstance3D) -> float:
	if mi == null or mi.mesh == null or mi.mesh.get_surface_count() == 0:
		return -1.0
	var v: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var h := 0.0
	for i in range(0, v.size(), 7):
		h += v[i].x * 1.3 + v[i].y * 2.1 + v[i].z * 3.7
	return snappedf(h, 0.000001)

## Every live collision shape under the corridor, by its body's name — the panel's own
## push buttons excluded, since they are the hand's targets, not the passage.
func _colliders(cor: Node) -> Array:
	var out: Array = []
	var pnl: Node = cor.get_node_or_null("Panel")
	for n in cor.find_children("*", "CollisionShape3D", true, false):
		var cs: CollisionShape3D = n
		if cs.shape == null or cs.disabled:
			continue
		if pnl != null and pnl.is_ancestor_of(cs):
			continue
		out.append("%s/%s:%s" % [str(cs.get_parent().name), str(cs.name), cs.shape.get_class()])
	out.sort()
	return out

## Drag a panel slider through the pointer, from the stand the panel's buttons are pressed
## from. The grabbable part is the HANDLE, a body of its own that rides along the track at the
## slider's current value — not the slider's root. (A first run aimed at the root and met
## nothing; the Perlin/Simplex drag had worked only because its handle sat mid-track.)
func _drag_slider(drv: Node, slider: Node3D, stand_at: Vector3) -> Dictionary:
	if slider == null:
		return {"skipped": "no slider"}
	var handle: Node3D = slider.get_node_or_null("SliderOrigin/InteractableSlider/HandleOrigin/InteractableHandle")
	var from: Vector3 = handle.global_position if handle != null else slider.global_position
	var to: Vector3 = from + (slider.global_transform.basis * Vector3(0.10, 0.0, 0.0))
	var rig: CharacterBody3D = drv.get("rig")
	rig.global_position = stand_at
	rig.velocity = Vector3.ZERO
	await physics_frame
	var rec: Dictionary = await drv.call("drag", from, to, 16)
	rec["grabbed_handle"] = handle != null
	return rec

func _press(panel: Node, btn_name: String) -> bool:
	if panel == null: return false
	var btn: Node = panel.find_child(btn_name, true, false)
	var area: Node = btn.get_node_or_null("InteractableAreaButton") if btn != null else null
	if area == null or not area.has_signal("button_pressed"): return false
	area.emit_signal("button_pressed", area)
	return true

func _all_mesh_extent(node: Node) -> AABB:
	var merged := AABB(); var first := true
	for n in node.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = n
		if mi.mesh == null or mi.layers == 0: continue
		var box: AABB = mi.global_transform * mi.get_aabb()
		merged = box if first else merged.merge(box); first = false
	return merged

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
		"lanes": {"model_lane": "slider_moved and button_pressed emitted on the panel's own controls",
			"pointer_lane_expected": _live(), "pointer_lane_ran": (measurements.get("desktop_input", {}) as Dictionary).has("drag_amp")},
		"control_path": ("AMP and PHASE dragged and FREEZE and RESET pressed through the desktop pointer, the meshes and colliders read after each, and the player's own body walked through the passage at its narrowest; the model lane emits the same controls' signals"
			if (measurements.get("desktop_input", {}) as Dictionary).has("drag_amp")
			else "model lane in this run: slider_moved and button_pressed emitted on the panel's own controls, no pointer; the live lane drags both sliders, presses both buttons and walks the player's body through the passage"),
		"hand_file": "ada_run/necklace_hand.json (real)", "headset_verified": false,
		"engine": Engine.get_version_info().string, "physics_fps": Engine.physics_ticks_per_second}
	var f := FileAccess.open(OUT + "probe_sine_space.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  ")); f.close()
	print("[wcn-sine] ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
