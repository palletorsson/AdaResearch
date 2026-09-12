extends SceneTree
## WaveFunctions_Synthesis_Lab, batch W4 (doc/research/waves-chance-noise, 2026-09-11, Astra's
## thread: AirMusic's two decays overlapping → the additive sum on purpose): what shape can
## several simple returns make together?
##
## Stands up the ACTUAL museum hall with its artifacts (the pattern of probe_wcn_air_music.gd),
## hands the museum the REAL necklace hand file, finds additive_wave_demo staged on its bench,
## and measures: the staging (the bench, the display lifted, every ladder row clear of the
## bench-top sight line, the console within reach, the SUM panel, the readout, the marker);
## for several places on the display, the DRAWN total against the sum of the DRAWN rows (read
## from the meshes' own vertices in one frame); each slider changing its own amplitude through
## the slider's real move path (move_slider → slider_moved → _on_harmonic_changed); H1 ALONE
## and BASELINE through the panel's button signal; five sliders moved and all five restored;
## the finite corner (five harmonics against the sawtooth they approximate); walks, the
## museum's verdicts, plinths, captures and streaming. The live port adds the project's
## desktop rig dragging a slider and pressing the panel through its pointer.
##
##   godot --rendering-method gl_compatibility --path . --xr-mode off --script res://commons/testing/probe_wcn_synthesis_lab.gd -- --capture
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_wcn_synthesis_lab.gd
##
## Writes res://ada_run/waves_chance_noise/WaveFunctions_Synthesis_Lab/probe_synthesis_lab.json
## (and probe_synthesis_lab*.png under --capture). Exit code 1 on any failed check.
var checks := 0
var failures: Array[String] = []
var measurements: Dictionary = {}
const MAP := "WaveFunctions_Synthesis_Lab"
const OUT := "res://ada_run/waves_chance_noise/WaveFunctions_Synthesis_Lab/"
const MAP_CELL := Vector2i(4, 2)
const SAWTOOTH := [1.0, 0.5, 0.333, 0.25, 0.2]

func _initialize() -> void: run.call_deferred()

func _live() -> bool:
	return str(get_script().resource_path).ends_with("_live.gd")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[wcn-synthesis] ", "PASS " if ok else "FAIL ", message)

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
	var capture: bool = "--capture" in OS.get_cmdline_user_args()
	var cam: Camera3D
	if capture:
		var wc: Camera3D = em.get("_cam")
		if wc != null and is_instance_valid(wc):
			for c in wc.get_children():
				if c is Timer: (c as Timer).stop()
		cam = Camera3D.new(); em.add_child(cam); cam.fov = 62

	# ── 1. built where the map put it, against the north wall, facing the room ──
	var demo: Node3D
	var demo_cell: Array = []
	for record: Dictionary in em.get("_edit_records"):
		var node: Node = record.get("node")
		if node != null and seg.is_ancestor_of(node) and node.get_script() != null and str(node.get_script().resource_path).ends_with("additive_wave_demo.gd"):
			demo = node; demo_cell = record.get("tile_cell", [])
	if demo == null:
		for n in seg.find_children("*", "Node3D", true, false):
			if n.get_script() != null and str(n.get_script().resource_path).ends_with("additive_wave_demo.gd"): demo = n; break
	check(demo != null, "additive_wave_demo is built in the hall")
	if demo == null:
		_finish(); return
	if demo_cell.size() >= 2:
		check(int(demo_cell[0]) == MAP_CELL.x and int(demo_cell[1]) == MAP_CELL.y, "built at the map's cell (4,2) (got %s)" % str(demo_cell))
	var lo: Vector3 = seg.to_local(demo.global_position)
	measurements["origin_local"] = [lo.x, lo.y, lo.z - vest]
	check(absf(lo.x - 4.5) < 0.6 and absf(lo.z - (2.5 + vest)) < 0.6, "the instrument stands on its cell (%.1f, %.1f)" % [lo.x, lo.z - vest])
	check(absf(lo.y) < 0.05, "the deck is the origin: the demo stands ON the floor (y %.2f)" % lo.y)
	var front: Vector3 = seg.global_transform.basis.inverse() * (demo.global_transform.basis * Vector3(0, 0, 1))
	check(front.z > 0.9, "the front (+z: the bench, the console) faces south into the room (z %.2f)" % front.z)
	check(str(demo.get("stand")) == "bench", "the token's #stand:bench reached the artifact (stand = %s)" % str(demo.get("stand")))
	check(str(demo.get("waveform")) == "sawtooth", "the placed preset is the sawtooth (waveform = %s)" % str(demo.get("waveform")))
	check(str(demo.get("components")) == "ladder", "the rows are the ladder (components = %s)" % str(demo.get("components")))
	check(demo.scale.is_equal_approx(Vector3.ONE), "the subject's scale is what the map asked (1)")
	var amps: Array = demo.get("harmonic_amplitudes")
	measurements["arrival_amplitudes"] = amps.duplicate()
	check(_amps_equal(amps, SAWTOOTH), "the arrival coefficients are the sawtooth's five: %s" % _fmt(amps))
	var base: Array = demo.call("get_baseline")
	check(_amps_equal(base, SAWTOOTH), "…and they are the baseline the panel restores (%s)" % _fmt(base))
	var sliders: Array = demo.get("harmonic_sliders")
	check(sliders.size() == 5, "five sliders are wired (%d)" % sliders.size())
	if sliders.size() < 5:
		_finish(); return
	var slider_vals: Array = []
	for s in sliders: slider_vals.append(snappedf(float(s.call("get_normalized_value")), 0.001))
	measurements["arrival_slider_values"] = slider_vals
	check(_amps_equal(slider_vals, SAWTOOTH, 0.01), "each slider reads back its harmonic's amplitude (%s)" % _fmt(slider_vals))

	# ── 2. the staging: the bench, the lifted display, the rows above the sight line ──
	var LIFT: float = float(demo.get("LIFT"))
	var bench: Node3D = demo.get_node_or_null("Staging/Bench")
	check(bench != null and bench is StaticBody3D, "the bench is a solid support (StaticBody3D)")
	var bench_top: float = -1.0
	if bench != null:
		bench_top = seg.to_local(bench.global_position).y + float(demo.get("BENCH_H")) * 0.5
		measurements["bench_top"] = bench_top
		check(absf(bench_top - 0.92) < 0.02, "the bench top is at 0.92 m (%.2f)" % bench_top)
	var wave_mesh: MeshInstance3D = demo.get("wave_mesh")
	var wave_y: float = seg.to_local(wave_mesh.global_position).y if wave_mesh != null else -1.0
	measurements["sum_axis_height"] = wave_y
	check(absf(wave_y - LIFT) < 0.02 and LIFT > 1.6 and LIFT < 1.9, "the sum's axis hangs at %.2f m, near a standing eye" % wave_y)
	var rows_node: Node3D = demo.get("component_meshes")
	var row_heights: Array = []
	for h in range(5):
		row_heights.append(snappedf(seg.to_local(rows_node.global_position).y - 0.35 - h * 0.15, 0.001))
	measurements["row_axis_heights"] = row_heights
	check(float(row_heights[4]) >= 0.79, "the lowest row's axis is at %.2f m: the whole ladder is above the deck and above the bench top" % float(row_heights[4]))
	# a standing eye 0.55 m before the bench's front (z 4.0), the lowest row's axis at z 2.6
	var eye_l := Vector3(4.5, 1.55, 4.0)
	var low_row_l := Vector3(4.5, float(row_heights[4]), 2.5 + 0.1)
	var bench_back_z: float = 2.5 + float(demo.get("BENCH_Z")) - float(demo.get("BENCH_D")) * 0.5
	var sight_at_bench_back: float = _line_y(eye_l, low_row_l, bench_back_z)
	var readout_case: Node3D = demo.get_node_or_null("Staging/ReadoutCase")
	var readout_top_y: float = 0.0
	var readout_top_z: float = 0.0
	if readout_case != null:
		var plate: MeshInstance3D = readout_case.get_node_or_null("Plate")
		var half_h: float = (plate.mesh as BoxMesh).size.y * 0.5 if plate != null else 0.105
		var top_local: Vector3 = readout_case.to_global(Vector3(0, half_h, 0))
		readout_top_y = seg.to_local(top_local).y
		readout_top_z = seg.to_local(top_local).z - vest
	var sight_at_readout: float = _line_y(eye_l, low_row_l, readout_top_z)
	measurements["sight_line"] = {"eye": [eye_l.x, eye_l.y, eye_l.z], "lowest_row_axis": [low_row_l.x, low_row_l.y, low_row_l.z],
		"bench_back_edge": [bench_back_z, bench_top, sight_at_bench_back], "readout_top_edge": [readout_top_z, readout_top_y, sight_at_readout]}
	check(sight_at_bench_back > bench_top + 0.03, "from a standing eye the lowest row clears the bench's back edge (line %.2f m over an edge at %.2f m)" % [sight_at_bench_back, bench_top])
	check(readout_case != null and sight_at_readout > readout_top_y + 0.02, "…and clears the readout's top edge (line %.2f m over an edge at %.2f m)" % [sight_at_readout, readout_top_y])
	var backboard: Node3D = demo.get_node_or_null("Staging/Backboard")
	check(backboard != null, "a dark backboard stands behind the sum and the ladder")
	# the console: five handles at hand height, within reach from the bench's front
	var console: Node3D = demo.get_node_or_null("ControlPanel")
	var handle_pos: Array = []
	var reach_eye: Vector3 = seg.to_global(Vector3(5.86, 1.55, 3.85 + vest))
	var far_handle: float = 0.0
	var handles_low: float = 9.0
	var handles_high: float = 0.0
	for s in sliders:
		var hnd: Node3D = (s as Node).get_node_or_null("SliderOrigin/InteractableSlider/HandleOrigin/InteractableHandle")
		if hnd == null: continue
		var hl: Vector3 = seg.to_local(hnd.global_position)
		handle_pos.append([snappedf(hl.x, 0.01), snappedf(hl.y, 0.01), snappedf(hl.z - vest, 0.01)])
		far_handle = maxf(far_handle, reach_eye.distance_to(hnd.global_position))
		handles_low = minf(handles_low, hl.y); handles_high = maxf(handles_high, hl.y)
	measurements["handles_local"] = handle_pos
	measurements["reach_to_farthest_handle"] = far_handle
	check(handle_pos.size() == 5 and handles_low > 0.93 and handles_high < 1.45, "the five handles stand on the bench between %.2f and %.2f m: hand height" % [handles_low, handles_high])
	check(far_handle < 0.95, "every handle is within an arm of the console's standing spot (farthest %.2f m from the eye)" % far_handle)
	check(console != null and seg.to_local(console.global_position).x > 5.5, "the console stands at the bench's right end, clear of the display (x %.2f)" % seg.to_local(console.global_position).x)
	var panel: Node3D = demo.get_node_or_null("Staging/Panel")
	check(panel != null, "the SUM panel exists")
	for b in ["Btn_0", "Btn_1", "Btn_2"]:
		check(panel != null and panel.find_child(b, true, false) != null, "the panel has %s" % b)
	var readout: Label3D = demo.get_node_or_null("Staging/ReadoutCase/Readout")
	check(readout != null, "the housed readout exists")
	if readout != null:
		check(readout.text.begins_with("a     1.00 0.50 0.33 0.25 0.20"), "the readout prints the five coefficients (%s)" % readout.text.get_slice("\n", 0))
		check(readout.text.get_slice("\n", 1).begins_with("base  1.00 0.50 0.33 0.25 0.20"), "…the arrival five (%s)" % readout.text.get_slice("\n", 1))
		check(readout.text.get_slice("\n", 4) == "differs: none", "…and that nothing differs yet (%s)" % readout.text.get_slice("\n", 4))
	var marker: Node3D = demo.get_node_or_null("Staging/Marker")
	check(marker != null, "the marker line exists")
	if marker != null:
		var mx: float = seg.to_local(marker.global_position).x - lo.x
		measurements["marker_x_local"] = mx
		check(absf(mx - float(demo.call("mark_x"))) < 0.005, "the marker stands at the readout's sample (x %.3f = sample %d)" % [mx, int(demo.call("mark_index"))])
	var expl: Node3D = demo.get_node_or_null("ExplanationLabel")
	check(expl != null and seg.to_local(expl.global_position).y > 0.5, "the shipped caption reads from the bench's front, above the floor (%.2f m)" % (seg.to_local(expl.global_position).y if expl != null else -1.0))

	# ── 3. the drawn total against the drawn rows: read from the meshes in ONE frame ──
	demo.call("set_held", true)
	await process_frame
	await process_frame
	check(bool(demo.get("held")), "HOLD stops the scroll (held = true)")
	var t0: float = float(demo.get("_time"))
	await create_timer(0.3).timeout
	check(absf(float(demo.get("_time")) - t0) < 0.000001, "…the display's clock stands still while held (%.4f → %.4f)" % [t0, float(demo.get("_time"))])
	var sum_pts: Array = _centerline(wave_mesh)
	var row_pts: Array = []
	var rows_drawn: Array = []
	for h in range(5):
		var rm: MeshInstance3D = rows_node.get_child(h)
		rows_drawn.append(rm.visible)
		row_pts.append(_centerline(rm) if rm.visible else [])
	measurements["sum_vertices"] = sum_pts.size()
	check(sum_pts.size() == 256, "the sum is drawn from 256 samples (WAVE_POINTS), read back from its ribbon (%d)" % sum_pts.size())
	check(rows_drawn == [true, true, true, true, true], "all five rows are drawn under the sawtooth (%s)" % str(rows_drawn))
	var comparisons: Array = []
	var worst: float = 0.0
	for i in [20, 59, 100, int(demo.call("mark_index")), 200, 240]:
		if i >= sum_pts.size(): continue
		var total_drawn: float = float((sum_pts[i] as Vector3).y) / 0.3
		var rows_sum: float = 0.0
		var rows_v: Array = []
		for h in range(5):
			if row_pts[h].is_empty(): continue
			var v: float = (float((row_pts[h][i] as Vector3).y) + 0.35 + h * 0.15) / 0.2
			rows_v.append(snappedf(v, 0.001)); rows_sum += v
		var dv: Dictionary = demo.call("display_values", i)
		var err: float = absf(total_drawn - rows_sum)
		worst = maxf(worst, err)
		comparisons.append({"sample": i, "x": snappedf(float((sum_pts[i] as Vector3).x), 0.001), "total_drawn": snappedf(total_drawn, 0.001),
			"rows_drawn": rows_v, "sum_of_rows_drawn": snappedf(rows_sum, 0.001), "total_computed": snappedf(float(dv["total"]), 0.001), "error": snappedf(err, 0.0001)})
	measurements["drawn_total_vs_rows"] = comparisons
	check(comparisons.size() == 6 and worst < 0.01, "at six places the DRAWN total equals the sum of the DRAWN rows (worst difference %.4f)" % worst)
	if readout != null:
		var mline: String = readout.text.get_slice("\n", 2)
		var sline: String = readout.text.get_slice("\n", 3)
		var dvm: Dictionary = demo.call("display_values", int(demo.call("mark_index")))
		check(mline.begins_with("mark  ") and sline.contains("= total") and sline.ends_with("· held"), "the readout prints the rows at the mark and sum = total, held (%s | %s)" % [mline, sline])
		var printed_total: float = float(sline.get_slice("total ", 1).get_slice(" ", 0))
		check(absf(printed_total - float(dvm["total"])) < 0.006, "the printed total is the marker sample's (%.2f vs %.3f)" % [printed_total, float(dvm["total"])])
	if capture:
		cam.global_position = seg.to_global(Vector3(4.5, 1.55, 4.15 + vest)); cam.look_at(seg.to_global(Vector3(4.5, 1.35, 2.5 + vest)))
		for i in range(20): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_synthesis_lab.png")
		measurements["captures"] = {"primary": _cam_pose(cam)}

	# ── 4. each slider through its real move path ──────────────────────────────
	var per_slider: Array = []
	for h in range(5):
		var before: Array = (demo.get("harmonic_amplitudes") as Array).duplicate()
		var xr: Node = (sliders[h] as Node).get_node_or_null("SliderOrigin/InteractableSlider")
		var target: float = 0.7
		var pos: float = remap(target, 0.0, 1.0, float(xr.get("slider_limit_min")), float(xr.get("slider_limit_max")))
		xr.call("move_slider", pos)   # what a hand's handle and the desktop pointer's drag both end in
		# two frames: a coroutine resumed from a timer runs after that frame's draw, so one
		# process_frame later the meshes still show the previous amplitude (measured 09:26)
		await process_frame
		await process_frame
		var after: Array = (demo.get("harmonic_amplitudes") as Array).duplicate()
		var only_this := true
		for k in range(5):
			if k != h and absf(float(after[k]) - float(before[k])) > 0.0001: only_this = false
		var rm: MeshInstance3D = rows_node.get_child(h)
		var pts: Array = _centerline(rm)
		var peak: float = 0.0
		for p in pts: peak = maxf(peak, (float((p as Vector3).y) + 0.35 + h * 0.15) / 0.2)
		var lbl: Label3D = (sliders[h] as Node).get_node_or_null("Frame/Label3DValue")
		var diffs: Array = demo.call("differences_from_baseline")
		per_slider.append({"harmonic": h + 1, "before": float(before[h]), "after": float(after[h]), "only_this_changed": only_this,
			"row_peak": snappedf(peak, 0.001), "value_label": lbl.text if lbl != null else "", "differences": diffs.duplicate()})
		check(absf(float(after[h]) - target) < 0.01 and only_this, "slider %d moved to 0.70 changes a%d alone (%.2f → %.2f)" % [h + 1, h + 1, float(before[h]), float(after[h])])
		check(absf(peak - target) < 0.02, "…and its own row is redrawn at that amplitude (peak %.2f)" % peak)
		check(diffs.size() >= 1 and str(diffs[diffs.size() - 1]).begins_with("a%d " % (h + 1)), "…and the readout names the difference from the arrival (%s)" % str(diffs))
	measurements["sliders"] = per_slider
	var formula: Label3D = demo.get("formula_label")
	check(formula != null and formula.text == "f(t) = 0.7·sin(ωt) + 0.7·sin(2ωt) + 0.7·sin(3ωt) + 0.7·sin(4ωt) + 0.7·sin(5ωt)", "the formula label lists the five coefficients (%s)" % (formula.text if formula != null else ""))

	# ── 5. BASELINE and H1 ALONE through the panel's button signal ───────────────
	check(_press(panel, "Btn_0"), "BASELINE pressed through its signal")
	await process_frame
	await process_frame
	amps = demo.get("harmonic_amplitudes")
	slider_vals = []
	for s in sliders: slider_vals.append(snappedf(float(s.call("get_normalized_value")), 0.001))
	measurements["after_baseline"] = {"amplitudes": amps.duplicate(), "sliders": slider_vals}
	check(_amps_equal(amps, SAWTOOTH), "BASELINE restores all five coefficients exactly (%s)" % _fmt(amps))
	check(_amps_equal(slider_vals, SAWTOOTH, 0.01), "…and moves all five sliders back (%s)" % _fmt(slider_vals))
	check((demo.call("differences_from_baseline") as Array).is_empty(), "…and nothing differs from the arrival")
	var preset: Label3D = demo.get("preset_label")
	check(preset != null and preset.text.begins_with("≈ Sawtooth"), "the preset label recognises the sawtooth again (%s)" % (preset.text if preset != null else ""))
	check(_press(panel, "Btn_1"), "H1 ALONE pressed through its signal")
	await process_frame
	await process_frame
	amps = demo.get("harmonic_amplitudes")
	check(_amps_equal(amps, [1.0, 0.0, 0.0, 0.0, 0.0]), "H1 ALONE leaves the first harmonic and zeroes the rest (%s)" % _fmt(amps))
	check(preset != null and preset.text == "Pure Sine Wave", "the preset label says Pure Sine Wave (%s)" % (preset.text if preset != null else ""))
	var drawn_now: Array = []
	for h in range(5): drawn_now.append((rows_node.get_child(h) as MeshInstance3D).visible)
	check(drawn_now == [true, false, false, false, false], "four rows leave the ladder (%s)" % str(drawn_now))
	var sine_pts: Array = _centerline(wave_mesh)
	var sine_peak: float = 0.0
	for p in sine_pts: sine_peak = maxf(sine_peak, absf(float((p as Vector3).y)) / 0.3)
	measurements["h1_alone_peak"] = sine_peak
	check(absf(sine_peak - 1.0) < 0.02, "the sum is one sine at amplitude 1 (peak %.3f)" % sine_peak)
	if readout != null:
		check(readout.text.get_slice("\n", 4).begins_with("differs: a2 0.50→0.00, a3 0.33→0.00 +2 more"), "the readout names the four removed contributions (%s)" % readout.text.get_slice("\n", 4))
	if capture:
		for i in range(6): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_synthesis_lab_h1_alone.png")
		measurements["captures"]["h1_alone"] = _cam_pose(cam)
	# one harmonic back, on its slider
	var xr2: Node = (sliders[1] as Node).get_node_or_null("SliderOrigin/InteractableSlider")
	xr2.call("move_slider", remap(0.5, 0.0, 1.0, float(xr2.get("slider_limit_min")), float(xr2.get("slider_limit_max"))))
	await process_frame
	await process_frame
	amps = demo.get("harmonic_amplitudes")
	check(_amps_equal(amps, [1.0, 0.5, 0.0, 0.0, 0.0]), "the second harmonic raised again on its slider: [1, 0.5, 0, 0, 0] (%s)" % _fmt(amps))
	check(_press(panel, "Btn_0"), "BASELINE pressed again")
	await process_frame
	await process_frame

	# ── 6. the finite corner: five harmonics against the sawtooth they approximate ──
	var saw_pts: Array = _centerline(wave_mesh)
	var maxima: int = 0
	var gmax_i: int = 0
	var gmax: float = -9.0
	for i in range(1, saw_pts.size() - 1):
		var y0: float = float((saw_pts[i - 1] as Vector3).y)
		var y1: float = float((saw_pts[i] as Vector3).y)
		var y2: float = float((saw_pts[i + 1] as Vector3).y)
		if y1 > y0 and y1 >= y2: maxima += 1
		if y1 > gmax: gmax = y1; gmax_i = i
	var gmin_i: int = 0
	var gmin: float = 9.0
	for i in range(saw_pts.size()):
		if float((saw_pts[i] as Vector3).y) < gmin: gmin = float((saw_pts[i] as Vector3).y); gmin_i = i
	var next_max_i: int = gmin_i
	for i in range(gmin_i + 1, saw_pts.size() - 1):
		if float((saw_pts[i] as Vector3).y) >= float((saw_pts[i + 1] as Vector3).y): next_max_i = i; break
	var rise_samples: int = next_max_i - gmin_i
	var rise_width_m: float = float(rise_samples) * 2.0 / 255.0
	var max_err_corner: float = 0.0
	var max_err_flank: float = 0.0
	for i in range(saw_pts.size()):
		var phase: float = float(demo.call("phase_at", i))
		var u: float = fposmod(phase, TAU)
		var ideal: float = (PI - u) * 0.5   # Σ sin(nφ)/n on (0, 2π): a descent, then a jump up
		var drawn: float = float((saw_pts[i] as Vector3).y) / 0.3
		var e: float = absf(drawn - ideal)
		if u < 0.35 or u > TAU - 0.35: max_err_corner = maxf(max_err_corner, e)
		else: max_err_flank = maxf(max_err_flank, e)
	measurements["finite_corner"] = {"local_maxima_over_four_cycles": maxima, "per_cycle": maxima / 4.0, "peak": snappedf(gmax / 0.3, 0.001), "trough": snappedf(gmin / 0.3, 0.001),
		"rise_samples": rise_samples, "rise_width_m": snappedf(rise_width_m, 0.001), "max_error_near_corner": snappedf(max_err_corner, 0.001), "max_error_on_flank": snappedf(max_err_flank, 0.001)}
	check(maxima >= 14 and maxima <= 24, "five terms ripple: about five local maxima per cycle where a sawtooth has one (%d over four cycles)" % maxima)
	check(rise_samples >= 4, "the sawtooth's cliff takes a finite width here: the rise from trough to crest is %d samples, %.3f m of a 0.5 m cycle" % [rise_samples, rise_width_m])
	check(max_err_corner > 1.0 and max_err_flank < 0.4, "the five-term sum misses the ideal sawtooth by up to %.2f at the corner and %.2f on the flank" % [max_err_corner, max_err_flank])
	demo.call("set_held", false)
	await process_frame
	check(not bool(demo.get("held")), "HOLD released: the scroll runs again")

	# ── 7. what else sounds, and the museum's verdicts ──────────────────────────
	await create_timer(0.5).timeout
	var others: Array = []
	for n in seg.find_children("*", "AudioStreamPlayer3D", true, false):
		var pl: AudioStreamPlayer3D = n
		if demo.is_ancestor_of(pl) or not pl.playing: continue
		others.append([str(pl.get_path()).right(50), snappedf(pl.global_position.distance_to(demo.global_position), 0.1)])
	measurements["other_players_playing"] = others
	var severed: Array = em.get("_seg_severed") if em.get("_seg_severed") != null else []
	var sev_tokens: Array = []
	for s2 in severed: sev_tokens.append(str((s2 as Dictionary).get("token", "")))
	measurements["museum_severed_tokens"] = sev_tokens
	var walk_sev: Array = em.get("_walk_severed") if em.get("_walk_severed") != null else []
	var mine_sev: Array = []
	for e in walk_sev:
		if str((e as Dictionary).get("hall", "")).contains(MAP): mine_sev.append(e)
	measurements["museum_walk_severed"] = mine_sev
	check(mine_sev.is_empty(), "the museum walks this hall door to door (local seals: %s)" % str(sev_tokens))
	var plinths: Array = []
	for n in seg.find_children("ArtPlinth*", "", true, false):
		var pl2: Vector3 = seg.to_local((n as Node3D).global_position)
		plinths.append([n.name, int(floor(pl2.x)), int(floor(pl2.z)) - vest])
	measurements["plinths"] = plinths
	var in_rect := false
	for p in plinths:
		for rc in [[2, 2, 6, 4], [6, 0, 8, 3], [7, 3, 7, 11], [5, 10, 8, 13]]:
			if int(p[1]) >= rc[0] and int(p[1]) < rc[2] and int(p[2]) >= rc[1] and int(p[2]) < rc[3]: in_rect = true   # the far edge is exclusive, as the museum reads it
	check(not in_rect, "no dealt plinth stands in the clear rects (the bench, the north door, the corridor column, the south door approach) (plinths: %s)" % str(plinths))
	var rows: Array = em.get("_built") if em.get("_built") != null else []
	for r in rows:
		if str((r as Dictionary).get("map", "")) == MAP:
			measurements["built_seals"] = r.get("seals", []); measurements["built_severed"] = r.get("severed", [])

	# ── 7b. the hallway hero on the synthesis stand fits its slab (12 September) ──────────
	var syn_stand: Node3D
	var hallway_solo: Node3D
	for n in seg.find_children("*", "Node3D", true, false):
		if n.get_script() == null: continue
		var spath: String = str(n.get_script().resource_path)
		if spath.ends_with("synthesis_stand.gd") and syn_stand == null: syn_stand = n
		if spath.ends_with("hallway_scene.gd") and (n.get_parent() == null or n.get_parent().get_script() == null or not str(n.get_parent().get_script().resource_path).ends_with("synthesis_stand.gd")): hallway_solo = n
	check(syn_stand != null, "the synthesis stand (subject hallway_scene, mode hero) is built")
	if syn_stand != null:
		var hero: Node3D
		for c in syn_stand.find_children("*", "Node3D", true, false):
			if c.get_script() != null and str(c.get_script().resource_path).ends_with("hallway_scene.gd"): hero = c
		check(hero != null, "the stand carries the hallway scene as its hero")
		if hero != null:
			var hmin := Vector3(1e9, 1e9, 1e9)
			var hmax := Vector3(-1e9, -1e9, -1e9)
			var meshes: int = 0
			for mi in hero.find_children("*", "MultiMeshInstance3D", true, false):
				var aabb: AABB = (mi as MultiMeshInstance3D).get_aabb()
				for k in range(8):
					var gp: Vector3 = seg.to_local((mi as MultiMeshInstance3D).global_transform * aabb.get_endpoint(k))
					hmin = hmin.min(gp); hmax = hmax.max(gp)
				meshes += 1
			var ext: Vector3 = hmax - hmin
			measurements["hallway_hero"] = {"meshes": meshes, "min": [snappedf(hmin.x, 0.01), snappedf(hmin.y, 0.01), snappedf(hmin.z - vest, 0.01)], "max": [snappedf(hmax.x, 0.01), snappedf(hmax.y, 0.01), snappedf(hmax.z - vest, 0.01)], "extent": [snappedf(ext.x, 0.01), snappedf(ext.y, 0.01), snappedf(ext.z, 0.01)], "hallway_length": hero.get("hallway_length")}
			print("[wcn-synthesis] measured: hallway hero %s" % str(measurements["hallway_hero"]))
			check(meshes > 0 and ext.x < 4.0 and ext.z < 4.0 and ext.y < 2.5, "the hero fits its slab: under 4 m across and 2.5 m tall (%s)" % str(measurements["hallway_hero"]["extent"]))
			check(hmax.x < 8.0 or hmin.x > 8.5, "the hero does not reach the bench's operating spot at x 4.8 (x %.2f..%.2f)" % [hmin.x, hmax.x])
	if hallway_solo != null:
		var smin := Vector3(1e9, 1e9, 1e9)
		var smax := Vector3(-1e9, -1e9, -1e9)
		for mi in hallway_solo.find_children("*", "MultiMeshInstance3D", true, false):
			var aabb: AABB = (mi as MultiMeshInstance3D).get_aabb()
			for k in range(8):
				var gp: Vector3 = seg.to_local((mi as MultiMeshInstance3D).global_transform * aabb.get_endpoint(k))
				smin = smin.min(gp); smax = smax.max(gp)
		measurements["hallway_solo"] = {"scale": snappedf(hallway_solo.scale.x, 0.001), "min": [snappedf(smin.x, 0.01), snappedf(smin.y, 0.01), snappedf(smin.z - vest, 0.01)], "max": [snappedf(smax.x, 0.01), snappedf(smax.y, 0.01), snappedf(smax.z - vest, 0.01)]}
		print("[wcn-synthesis] measured: the standalone hallway token %s" % str(measurements["hallway_solo"]))
	var wcam0: Camera3D = em.get("_cam")
	var env_note: String = "none"
	if wcam0 != null and is_instance_valid(wcam0) and wcam0.environment != null:
		var e: Environment = wcam0.environment
		env_note = "bg %d · sky %s · fog %s %.3f · glow %s" % [e.background_mode, str(e.sky != null), str(e.volumetric_fog_enabled), e.volumetric_fog_density, str(e.glow_enabled)]
	measurements["walker_camera_environment"] = env_note
	check(env_note == "none", "the museum walker's camera carries no environment override (%s; coloredlines.setup_scene dresses the current camera in a dark sky and fog)" % env_note)

	# ── 8. walks: the door route, the aisle before the bench, into the bench ────
	var pspace := seg.get_world_3d().direct_space_state
	var capsule := CapsuleShape3D.new(); capsule.radius = 0.22; capsule.height = 1.6
	var wq := PhysicsShapeQueryParameters3D.new(); wq.shape = capsule
	for route in [["the corridor south along column 7, from row 3 to row 10", Vector3(7.5, 0.81, 3.5), Vector3(0, 0, 7.0), false],
			["from the corridor west along row 3 to the console's spot", Vector3(7.5, 0.81, 3.75), Vector3(-1.6, 0, 0), true],
			["along the bench's front from the console to the display's centre", Vector3(5.9, 0.81, 3.75), Vector3(-1.4, 0, 0), true],
			["from the display's centre south into the room", Vector3(4.5, 0.81, 3.9), Vector3(0, 0, 1.6), true],
			["row 3 west past the platform at (3,4), between it and the bench", Vector3(4.5, 0.81, 3.72), Vector3(-2.0, 0, 0), false],
			["the detour east from (7,8) to column 8", Vector3(7.5, 0.81, 8.5), Vector3(1.0, 0, 0), false],
			["column 8 south from row 8 to row 10, past the lifted radio rack", Vector3(8.5, 0.81, 8.5), Vector3(0, 0, 2.0), false],
			["west from (8,10) back to the corridor and the door approach", Vector3(8.5, 0.81, 10.5), Vector3(-2.0, 0, 0), false]]:
		wq.transform = Transform3D(Basis.IDENTITY, seg.to_global(Vector3(route[1].x, route[1].y, route[1].z + vest)))
		wq.motion = route[2]
		var frac: float = pspace.cast_motion(wq)[0]
		measurements["walk_" + str(route[0]).replace(" ", "_").replace("'", "").replace("(", "").replace(")", "")] = frac
		if route[3]:
			check(frac > 0.99, "a body walks %s (%.2f of the way)" % [route[0], frac])
		else:
			# informational: and what stopped the body, by collider name
			var blockers: Array = []
			if frac < 0.99:
				var stop: Vector3 = wq.transform.origin + route[2] * frac + route[2].normalized() * 0.03
				var q2 := PhysicsShapeQueryParameters3D.new(); q2.shape = capsule; q2.transform = Transform3D(Basis.IDENTITY, stop)
				for hit in pspace.intersect_shape(q2, 8):
					var col: Node = (hit as Dictionary).get("collider")
					if col != null: blockers.append(str(col.get_path()).right(70))
			measurements["walk_" + str(route[0]).replace(" ", "_").replace("'", "").replace("(", "").replace(")", "") + "_blockers"] = blockers
			print("[wcn-synthesis] measured: %s %.2f of the way; stopped by %s" % [route[0], frac, str(blockers)])
	wq.transform = Transform3D(Basis.IDENTITY, seg.to_global(Vector3(4.5, 0.81, 4.2 + vest)))
	wq.motion = Vector3(0, 0, -1.5)
	var into: float = pspace.cast_motion(wq)[0]
	measurements["walk_into_the_bench"] = into
	check(into < 0.7, "the bench is solid: a body walking into it from the room is stopped (%.2f of 1.5 m)" % into)

	# ── ACTUAL DESKTOP INPUT (live harness only) ─────────────────────────────
	if _live():
		var drv: Node = load("res://commons/testing/wcn_desktop_driver.gd").new()
		root.add_child(drv)   # a SceneTree has no add_child; the port maps root. to get_tree().root.
		var stand: Vector3 = seg.to_global(Vector3(5.86, 0.0, 3.85 + vest))
		drv.call("spawn", stand, em)
		await create_timer(0.5).timeout
		# a slider dragged through the rig's pointer: press on H2's handle, swing the view along the track, release
		var h2: Node = sliders[1]
		var hnd2: Node3D = h2.get_node_or_null("SliderOrigin/InteractableSlider/HandleOrigin/InteractableHandle")
		var a2_before: float = float((demo.get("harmonic_amplitudes") as Array)[1])
		var track_x: Vector3 = (h2.get_node("SliderOrigin") as Node3D).global_transform.basis.x.normalized()
		var rec_drag: Dictionary = await drv.call("drag", hnd2.global_position, hnd2.global_position + track_x * 0.05, 20)
		await process_frame
		var a2_after: float = float((demo.get("harmonic_amplitudes") as Array)[1])
		measurements["desktop_input"] = {"drag": rec_drag, "a2_before": a2_before, "a2_after": a2_after}
		check(str(rec_drag.get("hover", "")).contains("Slider"), "the desktop pointer had H2's slider under the crosshair (%s)" % str(rec_drag.get("hover", "")))
		check(bool(rec_drag.get("dragging_midway", false)), "…the pointer was dragging it midway")
		check(a2_after > a2_before + 0.1, "…and the drag raised a2 through the pointer (%.2f → %.2f)" % [a2_before, a2_after])
		var b0: Node = panel.find_child("Btn_0", true, false)
		measurements["desktop_input"]["button_inspection"] = drv.call("inspect_control", b0) if b0 != null else {}
		measurements["desktop_input"]["handle_inspection"] = drv.call("inspect_control", hnd2) if hnd2 != null else {}
		var stands: Array = [Vector3(3.7, 0.0, 3.85), Vector3(4.4, 0.0, 4.3)]
		var rec0: Dictionary = {}
		var tries0: Array = []
		var b0_area: Node = b0.find_child("InteractableAreaButton", true, false) if b0 != null else null
		for st in stands:
			rec0 = await drv.call("press", b0, seg.to_global(Vector3(st.x, st.y, st.z + vest))) if b0 != null else {}
			tries0.append(rec0)
			await process_frame
			if str(rec0.get("hover", "")) != "nothing": break
			if b0_area != null:
				rec0 = await drv.call("press", b0_area, seg.to_global(Vector3(st.x, st.y, st.z + vest)))
				tries0.append(rec0)
				await process_frame
				if str(rec0.get("hover", "")) != "nothing": break
		await process_frame
		measurements["desktop_input"]["press_baseline"] = rec0
		measurements["desktop_input"]["press_baseline_tries"] = tries0
		check(str(rec0.get("hover", "")).contains("Btn_0") or str(rec0.get("hover", "")).contains("InteractableAreaButton"), "the desktop pointer had BASELINE under the crosshair (%s)" % str(rec0.get("hover", "")))
		check(_amps_equal(demo.get("harmonic_amplitudes"), SAWTOOTH), "BASELINE pressed through the pointer restores the five (%s)" % _fmt(demo.get("harmonic_amplitudes")))
		var b2: Node = panel.find_child("Btn_2", true, false)
		var rec2: Dictionary = {}
		for st in stands:
			rec2 = await drv.call("press", b2, seg.to_global(Vector3(st.x, st.y, st.z + vest))) if b2 != null else {}
			await process_frame
			if str(rec2.get("hover", "")) != "nothing": break
		await process_frame
		measurements["desktop_input"]["press_hold"] = rec2
		check(bool(demo.get("held")), "HOLD pressed through the pointer stops the scroll")
		if capture:
			drv.get("rig").global_position = seg.to_global(Vector3(4.8, 0.05, 4.3 + vest))
			await physics_frame
			drv.call("aim_at", demo.to_global(Vector3(0.0, 1.45, 0.0)))
			for i in range(12): await process_frame
			await create_timer(0.3, true, false, true).timeout
			root.get_texture().get_image().save_png(OUT + "probe_synthesis_lab_desktop_front.png")
			measurements["desktop_input"]["front_capture_pose"] = drv.call("pose")
		var st2: Array = rec2.get("stand", [3.7, 0.0, 3.85 + vest])
		await drv.call("press", b2, Vector3(float(st2[0]), float(st2[1]), float(st2[2])))
		await process_frame
		await process_frame
		check(not bool(demo.get("held")), "HOLD pressed again through the pointer runs it again")
		# the door route: walk south from the north door on ui_up; then into the bench
		drv.get("rig").global_position = seg.to_global(Vector3(8.5, 0.05, 0.7 + vest))
		await physics_frame
		drv.call("aim_at", seg.to_global(Vector3(8.5, 1.2, 6.0 + vest)))
		var moved_v: Vector3 = await drv.call("walk", "ui_up", 30)
		var ml: Vector3 = seg.global_transform.basis.inverse() * moved_v
		measurements["desktop_input"]["walk_door_route_south"] = [snappedf(ml.x, 0.01), snappedf(ml.z, 0.01)]
		check(ml.z > 2.0, "the rig walks the door route south on ui_up, column 8 from the north door (%.2f m in half a second)" % ml.z)
		drv.get("rig").global_position = seg.to_global(Vector3(4.5, 0.05, 4.3 + vest))
		await physics_frame
		drv.call("aim_at", seg.to_global(Vector3(4.5, 1.0, 2.5 + vest)))
		moved_v = await drv.call("walk", "ui_up", 20)
		ml = seg.global_transform.basis.inverse() * moved_v
		measurements["desktop_input"]["walk_into_the_bench"] = [snappedf(ml.x, 0.01), snappedf(ml.z, 0.01)]
		check(ml.z > -0.75, "walking north from the room, the rig is stopped by the bench (%.2f m of a possible 1.67)" % -ml.z)
		await drv.call("teardown")
		measurements["desktop_input"]["log"] = drv.get("log")
		measurements["desktop_input"]["walker_cam_guard_stopped"] = drv.get("walker_cam_guard_stopped")
		await process_frame

	# ── captures ─────────────────────────────────────────────────────────────
	if capture:
		demo.call("set_held", true)
		await create_timer(0.5).timeout
		cam.global_position = seg.to_global(Vector3(4.5, 1.55, 4.15 + vest)); cam.look_at(seg.to_global(Vector3(4.5, 1.35, 2.5 + vest)))
		for i in range(20): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_synthesis_lab.png")
		measurements["captures"]["primary"] = _cam_pose(cam)
		cam.global_position = seg.to_global(Vector3(4.5, 1.25, 3.75 + vest)); cam.look_at(seg.to_global(Vector3(4.5, 1.05, 2.6 + vest)))
		for i in range(15): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_synthesis_lab_ladder.png")
		measurements["captures"]["ladder"] = _cam_pose(cam)
		if readout_case != null:
			cam.global_position = readout_case.global_position + seg.global_transform.basis * Vector3(0.0, 0.55, 0.62); cam.look_at(readout_case.global_position)
			for i in range(15): cam.make_current(); await process_frame
			await create_timer(0.3, true, false, true).timeout
			root.get_texture().get_image().save_png(OUT + "probe_synthesis_lab_readout.png")
			measurements["captures"]["readout"] = _cam_pose(cam)
		if console != null:
			cam.global_position = seg.to_global(Vector3(5.86, 1.5, 3.9 + vest)); cam.look_at(console.global_position)
			for i in range(15): cam.make_current(); await process_frame
			await create_timer(0.3, true, false, true).timeout
			root.get_texture().get_image().save_png(OUT + "probe_synthesis_lab_console.png")
			measurements["captures"]["console"] = _cam_pose(cam)
		cam.global_position = seg.to_global(Vector3(2.3, 2.0, 6.2 + vest)); cam.look_at(seg.to_global(Vector3(5.2, 1.2, 2.9 + vest)))
		for i in range(15): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_synthesis_lab_overview.png")
		measurements["captures"]["overview"] = _cam_pose(cam)
		# the plan: straight down from under the ceiling, the whole hall
		cam.fov = 110
		cam.global_transform = Transform3D(Basis.looking_at(Vector3(0, -1, 0), Vector3(0, 0, -1)), seg.to_global(Vector3(7.0, 2.9, 6.8 + vest)))
		for i in range(15): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_synthesis_lab_plan.png")
		measurements["captures"]["plan"] = _cam_pose(cam)
		cam.fov = 62
		demo.call("set_held", false)
		cam.queue_free()

	# ── MUSEUM STREAMING: free the hall, rebuild it ──────────────────────────────
	var seg_i: int = -1
	var segs: Array = em.get("_segments")
	for i in range(segs.size()):
		if (segs[i] as Dictionary).get("node") == seg: seg_i = i
	if seg_i >= 0 and em.has_method("_stream_free"):
		var z0: float = seg.global_position.z
		var demo_ref: WeakRef = weakref(demo)
		var panel_ref: WeakRef = weakref(panel)
		em.call("_stream_free", seg_i, "south")
		for i in range(5): await process_frame
		var freed: bool = demo_ref.get_ref() == null and panel_ref.get_ref() == null
		check(freed, "the museum's streamer frees the hall, the instrument and its panel with it")
		var rec: Dictionary = {}
		for r in em.get("_freed"):
			if absf(float((r as Dictionary).get("z0", -1e9)) - z0) < 0.01: rec = r
		if rec.is_empty():
			for r in em.get("_freed"): rec = r
		measurements["streaming"] = {"freed": freed, "rebuildable": rec.has("snap")}
		if rec.has("snap"):
			em.call("_stream_rebuild", rec)
			await create_timer(1.5).timeout
			var seg2: Node3D
			for rec2: Dictionary in em.get("_segments"):
				if rec2.node.get_meta("em_map", "") == MAP: seg2 = rec2.node
			var demo2: Node3D
			if seg2 != null:
				for n in seg2.find_children("*", "Node3D", true, false):
					if n.get_script() != null and str(n.get_script().resource_path).ends_with("additive_wave_demo.gd"): demo2 = n; break
			check(demo2 != null and str(demo2.get("stand")) == "bench" and demo2.get_node_or_null("Staging/Bench") != null and demo2.get_node_or_null("Staging/Panel") != null,
				"the rebuilt hall has its instrument again, staged, with bench and panel")
			if demo2 != null:
				check(_amps_equal(demo2.get("harmonic_amplitudes"), SAWTOOTH), "the rebuilt instrument arrives at the sawtooth again (%s)" % _fmt(demo2.get("harmonic_amplitudes")))
	_finish()

## The points a ribbon (or a line strip) was drawn through, from the mesh's own vertices:
## a ribbon has six vertices per segment, a+n, b+n, b-n, a+n, b-n, a-n, so the point at
## sample k is the mean of vertices 6k and 6k+5 (and the last point of 6k+1 and 6k+2).
func _centerline(mi: MeshInstance3D) -> Array:
	var out: Array = []
	if mi == null or mi.mesh == null: return out
	var im: ImmediateMesh = mi.mesh
	if im.get_surface_count() < 1: return out
	var v: PackedVector3Array = im.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	# ImmediateMesh does not expose the primitive type: a ribbon has 6 (N-1) vertices, a
	# line strip N (256 is not a multiple of 6)
	if v.size() % 6 != 0 or v.size() < 12:
		for p in v: out.append(p)
		return out
	var segs: int = v.size() / 6
	for k in range(segs):
		out.append((v[6 * k] + v[6 * k + 5]) * 0.5)
	if segs > 0:
		out.append((v[6 * (segs - 1) + 1] + v[6 * (segs - 1) + 2]) * 0.5)
	return out

## y of the line eye → target at depth z (segment-local, z without the vestibule).
func _line_y(eye: Vector3, target: Vector3, z: float) -> float:
	var t: float = (eye.z - z) / maxf(eye.z - target.z, 0.0001)
	return eye.y + (target.y - eye.y) * t

func _amps_equal(a: Array, b: Array, tol: float = 0.0005) -> bool:
	if a.size() != b.size(): return false
	for i in range(a.size()):
		if absf(float(a[i]) - float(b[i])) > tol: return false
	return true

func _fmt(a: Array) -> String:
	var parts: Array[String] = []
	for v in a: parts.append("%.3f" % float(v))
	return "[" + ", ".join(parts) + "]"

func _press(panel: Node, btn_name: String) -> bool:
	if panel == null: return false
	var btn: Node = panel.find_child(btn_name, true, false)
	var area: Node = btn.get_node_or_null("InteractableAreaButton") if btn != null else null
	if area == null or not area.has_signal("button_pressed"): return false
	area.emit_signal("button_pressed", area)
	return true

## Which camera the viewport draws from at a capture, and where it stands and looks.
func _cam_pose(cam: Camera3D) -> Dictionary:
	var cur: Camera3D = root.get_camera_3d()
	var fwd: Vector3 = -cam.global_transform.basis.z
	return {"current_camera": str(cur.get_path()).right(50) if cur != null else "none", "is_ours": cur == cam,
		"at": [snappedf(cam.global_position.x, 0.01), snappedf(cam.global_position.y, 0.01), snappedf(cam.global_position.z, 0.01)],
		"forward": [snappedf(fwd.x, 0.01), snappedf(fwd.y, 0.01), snappedf(fwd.z, 0.01)]}

func _finish() -> void:
	var report := {"map": MAP, "checks": checks, "failures": failures, "measurements": measurements,
		"control_path": "sliders through move_slider (the end of the handle's and the pointer's drag path); panel buttons through the push button's own signal; the live lane adds the desktop rig's pointer dragging a slider and pressing the panel; no tracked hand",
		"hand_file": "ada_run/necklace_hand.json (real)", "headset_verified": false,
		"engine": Engine.get_version_info().string, "physics_fps": Engine.physics_ticks_per_second}
	var f := FileAccess.open(OUT + "probe_synthesis_lab.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  ")); f.close()
	print("[wcn-synthesis] ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
