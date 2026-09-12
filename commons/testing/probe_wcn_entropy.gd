extends SceneTree
## Random_Entropy, batch R1 (doc/research/waves-chance-noise, 2026-09-11, Astra's thread from
## Random_Definition: a repeatable result → what a number retains of an arrangement): which
## differences disappear when a sequence becomes one number?
##
## Stands up the ACTUAL museum hall with its artifacts (the pattern of probe_wcn_synthesis_lab.gd),
## hands the museum the REAL necklace hand file, finds shannon_entropy_meter staged on its
## ledger, and measures: the staging (the post, the desk, the panel at reading height, the
## ribbon of every draw, the strip mark, the LEDGER panel, the readout); the measurement
## contract (counts sum to N, H recomputed from the counts, the histogram bars ∝ the counts,
## the strip = the ribbon's first forty = the sample's first forty); SORT through the panel's
## button signal (the tiles regroup, the counts, the bars and H do not move, the sorted copy's
## H equal, the moved tiles counted, the strip mark gone) and back; CONTRAST (a second sample,
## same N, same alphabet, lower H, its own seed named) and back to the arrival sample;
## measure() on a single-symbol sample (H = 0) and on an evenly populated one (H = log₂ 10);
## DISCLOSE stepping the meter's own rung with the sample unchanged and the staging kept;
## walks, the museum's verdicts, plinths, captures and streaming. The live port adds the
## project's desktop rig pressing the panel through its pointer.
##
##   godot --rendering-method gl_compatibility --path . --xr-mode off --script res://commons/testing/probe_wcn_entropy.gd -- --capture
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_wcn_entropy.gd
##
## Writes res://ada_run/waves_chance_noise/Random_Entropy/probe_entropy.json
## (and probe_entropy*.png under --capture). Exit code 1 on any failed check.
var checks := 0
var failures: Array[String] = []
var measurements: Dictionary = {}
const MAP := "Random_Entropy"
const OUT := "res://ada_run/waves_chance_noise/Random_Entropy/"
const MAP_CELL := Vector2i(5, 6)
var _seg: Node3D
var _lift: float = 0.0

func _initialize() -> void: run.call_deferred()

func _live() -> bool:
	return str(get_script().resource_path).ends_with("_live.gd")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[wcn-entropy] ", "PASS " if ok else "FAIL ", message)

func run() -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() == "headless":
		check(false, "PNG capture requires a rendered window; omit --headless, or omit --capture for logic only")
		_finish(); return
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl := "res://ada_run/waves_chance_noise/wcn-probe-control.json"
	em.set("EM_CONTROL", ctl); em.set("_overrides_path", ctl + ".unused")
	em.set("_hand_path", "res://ada_run/necklace_hand.json")   # the REAL hand, on purpose
	em.set("start_chapter", "randomness"); em.set("start_map", MAP)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/em_layout.json"))
	layout.get_or_add("stream", {})["bodies"] = 1
	em.set("_layout", layout)
	var f := FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "randomness", "dollhouse": 0, "grid_pack": 1})); f.close()
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

	# ── 1. built where the map put it, facing the corridor ────────────────────
	var meter: Node3D
	var meter_cell: Array = []
	for record: Dictionary in em.get("_edit_records"):
		var node: Node = record.get("node")
		if node != null and seg.is_ancestor_of(node) and node.get_script() != null and str(node.get_script().resource_path).ends_with("shannon_entropy_meter.gd"):
			meter = node; meter_cell = record.get("tile_cell", [])
	if meter == null:
		for n in seg.find_children("*", "Node3D", true, false):
			if n.get_script() != null and str(n.get_script().resource_path).ends_with("shannon_entropy_meter.gd"): meter = n; break
	check(meter != null, "shannon_entropy_meter is built in the hall")
	if meter == null:
		_finish(); return
	if meter_cell.size() >= 2:
		check(int(meter_cell[0]) == MAP_CELL.x and int(meter_cell[1]) == MAP_CELL.y, "built at the map's cell (5,6) (got %s)" % str(meter_cell))
	var lo: Vector3 = seg.to_local(meter.global_position)
	measurements["origin_local"] = [lo.x, lo.y, lo.z - vest]
	check(absf(lo.x - 5.5) < 0.6 and absf(lo.z - (6.5 + vest)) < 0.6, "the gauge stands on its cell (%.1f, %.1f)" % [lo.x, lo.z - vest])
	check(absf(lo.y) < 0.05, "the deck is the origin: the meter stands ON the floor (y %.2f)" % lo.y)
	var front: Vector3 = seg.global_transform.basis.inverse() * (meter.global_transform.basis * Vector3(0, 0, 1))
	check(front.x > 0.9, "the front (+z: the desk, the ribbon) faces east, the corridor (x %.2f)" % front.x)
	check(str(meter.get("stand")) == "ledger", "the token's #stand:ledger reached the artifact (stand = %s)" % str(meter.get("stand")))
	check(str(meter.get("disclosure")) == "ledger", "the arrival rung is ledger: bars, the number and the first forty draws (disclosure = %s)" % str(meter.get("disclosure")))
	check(int(meter.get("num_symbols")) == 10 and int(meter.get("sequence_length")) == 200, "ten symbols, two hundred draws (%d, %d)" % [int(meter.get("num_symbols")), int(meter.get("sequence_length"))])
	check(meter.scale.is_equal_approx(Vector3.ONE), "the subject's scale is what the map asked (1)")

	# ── 2. the staging ─────────────────────────────────────────────────────────
	var LIFT: float = float(meter.get("LIFT"))
	_seg = seg; _lift = LIFT
	var DESK_H: float = float(meter.get("DESK_H"))
	var desk: Node3D = meter.get_node_or_null("Staging/Desk")
	check(desk != null and desk is StaticBody3D, "the desk is a solid support (StaticBody3D)")
	var desk_top: float = -1.0
	if desk != null:
		desk_top = seg.to_local(desk.global_position).y + DESK_H * 0.5
		measurements["desk_top"] = desk_top
		check(absf(desk_top - 0.92) < 0.02, "the desk top is at 0.92 m (%.2f)" % desk_top)
	check(meter.get_node_or_null("Staging/Post") != null, "the gauge hangs on a post")
	var panel_mesh: MeshInstance3D = meter.get("_panel_mesh")
	var panel_y: float = seg.to_local(panel_mesh.global_position).y if panel_mesh != null else -1.0
	measurements["panel_centre_height"] = panel_y
	check(absf(panel_y - LIFT) < 0.02 and LIFT > 1.2 and LIFT < 1.6, "the panel's centre hangs at %.2f m, at reading height" % panel_y)
	var ribbon: MultiMeshInstance3D = meter.get_node_or_null("Staging/Ribbon")
	check(ribbon != null and ribbon.multimesh != null and ribbon.multimesh.instance_count == 200, "the ribbon carries one tile per draw (%d)" % (ribbon.multimesh.instance_count if ribbon != null and ribbon.multimesh != null else -1))
	var ribbon_y: float = seg.to_local(ribbon.global_position).y if ribbon != null else -1.0
	check(ribbon_y > desk_top and ribbon_y < desk_top + 0.05, "the tiles stand on the desk top (%.3f m)" % ribbon_y)
	var mark: MeshInstance3D = meter.get_node_or_null("Staging/StripMark")
	check(mark != null and mark.visible, "a pale mark under the first forty tiles says which the strip shows")
	var panel: Node3D = meter.get_node_or_null("Staging/Panel")
	check(panel != null, "the LEDGER panel exists")
	for b in ["Btn_0", "Btn_1", "Btn_2"]:
		check(panel != null and panel.find_child(b, true, false) != null, "the panel has %s" % b)
	var readout: Label3D = meter.get_node_or_null("Staging/ReadoutCase/Readout")
	check(readout != null, "the housed readout exists")
	# the boards, lifted with the panel: the number and the strip
	var elabel: Node3D = meter.get("_entropy_label")
	var slabel: Node3D = meter.get("_sequence_label")
	check(elabel != null and absf(seg.to_local(elabel.global_position).y - (LIFT + 0.095)) < 0.03, "the glowing H sits on the lifted panel (%.2f m)" % (seg.to_local(elabel.global_position).y if elabel != null else -1.0))
	check(slabel != null and seg.to_local(slabel.global_position).y > LIFT - 0.26 and seg.to_local(slabel.global_position).y < LIFT - 0.18, "the forty-symbol strip sits along the lifted panel's foot (%.2f m)" % (seg.to_local(slabel.global_position).y if slabel != null else -1.0))
	var formula: Node3D = meter.get("_formula_label")
	check(formula == null, "at ledger the formula is withheld (works reveals it)")

	# ── 2b. the visual pass of 12 September: the first forty magnified on the desk's front ──
	var excerpt: MultiMeshInstance3D = meter.get_node_or_null("Staging/Excerpt")
	check(excerpt != null and excerpt.multimesh.instance_count == 40, "the first forty draws stand magnified on the desk's front (%d)" % (excerpt.multimesh.instance_count if excerpt != null else -1))
	if excerpt != null and ribbon != null:
		var same_colours: bool = true
		for i in range(40):
			if not excerpt.multimesh.get_instance_color(i).is_equal_approx(ribbon.multimesh.get_instance_color(i)): same_colours = false
		check(same_colours, "…in the ribbon's own colours, draw for draw")
		var eb: BoxMesh = excerpt.multimesh.mesh
		check(eb.size.y >= 0.09 and eb.size.x >= 0.024, "…at four times the tile (%.3f × %.3f)" % [eb.size.x, eb.size.y])
	check(meter.get_node_or_null("Staging/ExcerptCaption") != null, "…and labelled as the excerpt it is")

	# ── 3. the measurement contract ───────────────────────────────────────────
	var st: Dictionary = meter.call("get_ledger_state")
	var counts: Array = st["counts"]
	var sum: int = 0
	for c in counts: sum += int(c)
	measurements["arrival"] = {"counts": counts.duplicate(), "sum": sum, "entropy": st["entropy"], "max": st["max"], "seed": st["seed"], "source": st["source"]}
	check(counts.size() == 10 and sum == 200, "the ten counts sum to N = 200 (%s → %d)" % [str(counts), sum])
	var h_re: float = _entropy(counts, 200)
	check(absf(float(st["entropy"]) - h_re) < 0.000001, "H is -Σ p log₂ p over the counts with zero-count terms omitted (%.6f = %.6f)" % [float(st["entropy"]), h_re])
	check(float(st["entropy"]) <= float(st["max"]) + 0.000001 and float(st["entropy"]) > 3.0, "H %.3f lies below the ceiling log₂(10) = %.3f, near it for a uniform source" % [float(st["entropy"]), float(st["max"])])
	var bars: Array = meter.get("_freq_bars")
	var max_count: int = 0
	for c in counts: max_count = maxi(max_count, int(c))
	var bars_ok := bars.size() == 10
	var bar_ratios: Array = []
	var bar_diffs: Array = []
	for i in range(mini(10, bars.size())):
		var h: float = ((bars[i] as MeshInstance3D).mesh as QuadMesh).size.y
		bar_ratios.append(snappedf(h / 0.1, 0.001))
		var diff: float = absf(h / 0.1 - float(counts[i]) / float(max_count))
		bar_diffs.append(snappedf(diff, 0.00001))
		if diff > 0.002: bars_ok = false
	measurements["histogram_bar_ratios"] = bar_ratios
	measurements["histogram_bar_diffs"] = {"bars": bars.size(), "max_count": max_count, "diffs": bar_diffs}
	check(bars_ok, "the ten histogram bars stand in proportion to the counts, built once (%d bars, diffs %s)" % [bars.size(), str(bar_diffs)])
	var seq: Array = meter.call("get_sequence")
	var strip: String = str(st["strip"])
	var first40: Array = seq.slice(0, 40)
	var strip_nums: Array = []
	for tok in strip.replace(" ...", "").split(" "):
		if tok != "": strip_nums.append(int(tok))
	measurements["strip"] = strip
	check(strip_nums == first40, "the panel's strip is the sample's first forty draws, in order")
	check((st["ribbon_first_40"] as Array) == first40, "the ribbon's first forty tiles are the same forty")
	var tile_counts: Array = _tile_counts_by_colour(ribbon, meter)
	measurements["ribbon_tile_counts"] = tile_counts
	check(tile_counts == counts, "the ribbon's tiles, counted by colour, are the histogram's counts (%s)" % str(tile_counts))
	if readout != null:
		check(readout.text.begins_with("N 200 · 10 symbols · uniform · seed"), "the readout names N, the alphabet, the source and its seed (%s)" % readout.text.get_slice("\n", 0))
		check(readout.text.get_slice("\n", 1).ends_with("sum 200"), "…and the counts with their sum (%s)" % readout.text.get_slice("\n", 1))
		check(readout.text.get_slice("\n", 2).begins_with("H %.3f bits · max log2(10) = 3.322" % float(st["entropy"])), "…and H against log₂(10) (%s)" % readout.text.get_slice("\n", 2))
	if capture:
		cam.global_position = seg.to_global(Vector3(6.95, 1.55, 6.5 + vest)); cam.look_at(seg.to_global(Vector3(5.5, 1.15, 6.5 + vest)))
		for i in range(20): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_entropy.png")
		measurements["captures"] = {"primary": _cam_pose(cam)}

	# ── 4. SORT through the panel's button signal ─────────────────────────────
	var bars_before: Array = bar_ratios.duplicate()
	var h_before: float = float(st["entropy"])
	var xs_before: Array = _tile_xs(ribbon)
	check(_press(panel, "Btn_0"), "SORT pressed through its signal")
	await create_timer(1.6).timeout
	st = meter.call("get_ledger_state")
	measurements["after_sort"] = {"sorted_view": st["sorted_view"], "sort_t": st["sort_t"], "counts": st["counts"], "entropy": st["entropy"], "sorted_entropy": st["sorted_entropy"], "sorted_counts": st["sorted_counts"], "tiles_moved": st["tiles_moved"]}
	check(bool(st["sorted_view"]) and float(st["sort_t"]) > 0.99, "the ribbon is in its sorted layout (t %.2f)" % float(st["sort_t"]))
	check((st["counts"] as Array) == counts and (st["sorted_counts"] as Array) == counts, "the sorted copy has exactly the same ten counts")
	check(float(st["entropy"]) == h_before and float(st["sorted_entropy"]) == float(st["entropy"]), "the sorted copy's H equals the reading exactly (%.9f)" % float(st["sorted_entropy"]))
	var bars_after: Array = []
	for i in range(mini(10, bars.size())): bars_after.append(snappedf(((bars[i] as MeshInstance3D).mesh as QuadMesh).size.y / 0.1, 0.001))
	check(bars_after == bars_before, "the histogram did not move")
	var xs_after: Array = _tile_xs(ribbon)
	var grouped := true
	for i in range(199):
		if int(seq[_order_by_x(xs_after)[i]]) > int(seq[_order_by_x(xs_after)[i + 1]]): grouped = false
	check(grouped, "read left to right, the tiles now run 0…9 in blocks")
	check(int(st["tiles_moved"]) > 150, "%d of 200 tiles changed place — the order changed and the number did not" % int(st["tiles_moved"]))
	check(mark != null and not mark.visible, "the mark under the first forty is gone: they are scattered through the blocks")
	if readout != null:
		check(readout.text.get_slice("\n", 3).begins_with("sorted copy: H %.3f · equal · %d of 200 tiles moved" % [float(st["sorted_entropy"]), int(st["tiles_moved"])]), "the readout prints the sorted copy's H, equal, and the moved tiles (%s)" % readout.text.get_slice("\n", 3))
	if capture:
		for i in range(6): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_entropy_sorted.png")
		measurements["captures"]["sorted"] = _cam_pose(cam)
	check(_press(panel, "Btn_0"), "SORT pressed again")
	await create_timer(1.6).timeout
	st = meter.call("get_ledger_state")
	check(not bool(st["sorted_view"]) and float(st["sort_t"]) < 0.01 and _tile_xs(ribbon) == xs_before, "the tiles are back in the order drawn, at their first places")
	check(mark != null and mark.visible, "…and the mark under the first forty is back")

	# ── 5. CONTRAST: the same N and alphabet, a concentrated law ──────────────
	check(_press(panel, "Btn_1"), "CONTRAST pressed through its signal")
	await process_frame
	await process_frame
	st = meter.call("get_ledger_state")
	var c2: Array = st["counts"]
	var sum2: int = 0
	for c in c2: sum2 += int(c)
	measurements["contrast"] = {"counts": c2.duplicate(), "sum": sum2, "entropy": st["entropy"], "seed": st["seed"], "source": st["source"], "strip": st["strip"]}
	check(bool(st["contrast"]) and str(st["source"]) == "concentrated", "the concentrated sample is on the wall")
	check(c2.size() == 10 and sum2 == 200, "…with the same alphabet and the same N (%s → %d)" % [str(c2), sum2])
	check(int(c2[0]) > 80 and int(c2[0]) > int(c2[1]) and int(c2[1]) > int(c2[3]), "…symbol 0 near half the draws, then falling (%s)" % str(c2))
	check(float(st["entropy"]) < 2.4 and float(st["entropy"]) < h_before - 0.8, "…and H is far lower: %.3f against %.3f bits" % [float(st["entropy"]), h_before])
	check(absf(float(st["entropy"]) - _entropy(c2, 200)) < 0.000001, "…by the same loop over these counts")
	var place_c: Dictionary = _bars_place(meter)
	measurements["contrast"]["bars_place"] = place_c
	check(bool(place_c["on_panel"]), "…and the ten bars are still on the lifted panel, not dropped into the desk (y %.2f–%.2f)" % [float(place_c["min_y"]), float(place_c["max_y"])])
	check(int(st["seed"]) == int(measurements["arrival"]["seed"]) + 1, "the contrast has its own seed, the first sample's plus one (%d)" % int(st["seed"]))
	var seq2: Array = meter.call("get_sequence")
	var strip2_nums: Array = []
	for tok in str(st["strip"]).replace(" ...", "").split(" "):
		if tok != "": strip2_nums.append(int(tok))
	check(strip2_nums == seq2.slice(0, 40) and (st["ribbon_first_40"] as Array) == seq2.slice(0, 40), "the strip and the ribbon show the contrast sample's first forty")
	check(_tile_counts_by_colour(ribbon, meter) == c2, "the ribbon's tiles, by colour, are the contrast counts")
	var bars_c: Array = []
	for i in range(mini(10, bars.size())): bars_c.append(snappedf(((bars[i] as MeshInstance3D).mesh as QuadMesh).size.y / 0.1, 0.001))
	check(absf(float(bars_c[0]) - 1.0) < 0.002 and float(bars_c[9]) < 0.1, "the histogram shows it: the first bar tallest, the last near nothing (%s)" % str(bars_c))
	if readout != null:
		check(readout.text.begins_with("N 200 · 10 symbols · concentrated"), "the readout names the concentrated source (%s)" % readout.text.get_slice("\n", 0))
	if capture:
		for i in range(6): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_entropy_contrast.png")
		measurements["captures"]["contrast"] = _cam_pose(cam)
	check(_press(panel, "Btn_1"), "CONTRAST pressed again")
	await process_frame
	await process_frame
	st = meter.call("get_ledger_state")
	check(not bool(st["contrast"]) and (meter.call("get_sequence") as Array) == seq and float(st["entropy"]) == h_before, "the arrival sample is back on the wall, draw for draw, H the same")
	check(bool(_bars_place(meter)["on_panel"]), "…the bars on the panel after the measure back")

	# ── 6. the contract at its ends: one symbol, and an even population ───────
	var ones: Array = []
	for i in range(200): ones.append(0)
	check(bool(meter.call("measure", ones)), "measure() accepts a sample of 200 draws")
	await process_frame
	var h_one: float = float(meter.call("get_entropy"))
	check(h_one == 0.0, "a single-symbol sample reads H = %.6f: nothing to learn" % h_one)
	var even: Array = []
	for i in range(200): even.append(i % 10)
	meter.call("measure", even)
	await process_frame
	var h_even: float = float(meter.call("get_entropy"))
	measurements["contract_ends"] = {"single_symbol": h_one, "even": h_even, "log2_10": log(10.0) / log(2.0)}
	check(absf(h_even - log(10.0) / log(2.0)) < 0.000001, "an evenly populated ten-symbol sample reads log₂(10) = %.6f (%.6f)" % [log(10.0) / log(2.0), h_even])
	meter.call("set_contrast", false)
	await process_frame
	check((meter.call("get_sequence") as Array) == seq and float(meter.call("get_entropy")) == h_before, "and the arrival sample is restored")

	# ── 7. DISCLOSE steps the meter's own rung; the sample and the staging stay ──
	var staging_before: Node = meter.get_node_or_null("Staging")
	check(_press(panel, "Btn_2"), "DISCLOSE pressed through its signal")
	await process_frame
	await process_frame
	st = meter.call("get_ledger_state")
	measurements["disclose"] = [{"rung": st["disclosure"], "entropy": st["entropy"]}]
	check(str(st["disclosure"]) == "works", "ledger → works")
	check(meter.get("_formula_label") != null, "…the formula hangs under the title now")
	check((meter.call("get_sequence") as Array) == seq and float(st["entropy"]) == h_before, "…the sample is the same draws (a seeded redraw), H the same")
	check(meter.get_node_or_null("Staging") == staging_before and (meter.get_node_or_null("Staging/Ribbon") as MultiMeshInstance3D).multimesh.instance_count == 200, "…and the staging survived the rebuild with its ribbon")
	var elabel2: Node3D = meter.get("_entropy_label")
	check(elabel2 != null and absf(seg.to_local(elabel2.global_position).y - (LIFT + 0.095)) < 0.03, "…the rebuilt boards are lifted onto the post again (%.2f m)" % (seg.to_local(elabel2.global_position).y if elabel2 != null else -1.0))
	panel = meter.get_node_or_null("Staging/Panel")
	check(_press(panel, "Btn_2"), "DISCLOSE pressed again")
	await process_frame
	await process_frame
	st = meter.call("get_ledger_state")
	(measurements["disclose"] as Array).append({"rung": st["disclosure"], "entropy": st["entropy"]})
	check(str(st["disclosure"]) == "origin" and meter.get("_origin_label") != null and (meter.get("_expected_bars") as Array).size() == 10, "works → origin: the source strip and the ten ghost bars of the declared law")
	if readout != null:
		check(readout.text.get_slice("\n", 4).begins_with("disclosure origin"), "the readout names the rung (%s)" % readout.text.get_slice("\n", 4))
	if capture:
		cam.global_position = meter.to_global(Vector3(0.0, LIFT + 0.05, 1.0)); cam.look_at(meter.to_global(Vector3(0.0, LIFT, 0.0)))
		for i in range(15): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_entropy_origin.png")
		measurements["captures"]["origin"] = _cam_pose(cam)
	for k in range(3):
		check(_press(panel, "Btn_2"), "DISCLOSE pressed (%d of 3 more)" % (k + 1))
		await process_frame
		await process_frame
	st = meter.call("get_ledger_state")
	check(str(st["disclosure"]) == "ledger", "origin → oracle → tally → ledger: the ladder wraps to the arrival rung (%s)" % str(st["disclosure"]))
	check((meter.call("get_sequence") as Array) == seq and float(st["entropy"]) == h_before and not bool(st["sorted_view"]), "the sample, H and the layout are the arrival's")

	# ── 7b. the origin ghosts follow the ACTIVE law (Astra's review): both orders, sorted and not ──
	var ghost_records: Array = []
	# order A: CONTRAST first, then DISCLOSE to origin
	check(_press(panel, "Btn_1"), "order A: CONTRAST pressed (concentrated on the wall)")
	await process_frame
	await process_frame
	for k in range(2):
		panel = meter.get_node_or_null("Staging/Panel")
		_press(panel, "Btn_2")
		await process_frame
		await process_frame
	panel = meter.get_node_or_null("Staging/Panel")
	st = meter.call("get_ledger_state")
	check(str(st["disclosure"]) == "origin" and bool(st["contrast"]), "…then DISCLOSE twice: origin, with the concentrated sample (%s, contrast %s)" % [str(st["disclosure"]), str(st["contrast"])])
	ghost_records.append(_ghost_check("A: contrast → origin, as drawn", st, meter))
	check(_press(panel, "Btn_0"), "…SORT on")
	await create_timer(1.6).timeout
	st = meter.call("get_ledger_state")
	ghost_records.append(_ghost_check("A: contrast → origin, sorted", st, meter))
	check(_press(panel, "Btn_1"), "…CONTRAST off at origin: the uniform sample back")
	await process_frame
	await process_frame
	st = meter.call("get_ledger_state")
	ghost_records.append(_ghost_check("A: uniform at origin, sorted", st, meter))
	check(_press(panel, "Btn_0"), "…SORT off")
	await create_timer(1.6).timeout
	for k in range(3):
		panel = meter.get_node_or_null("Staging/Panel")
		_press(panel, "Btn_2")
		await process_frame
		await process_frame
	panel = meter.get_node_or_null("Staging/Panel")
	st = meter.call("get_ledger_state")
	check(str(st["disclosure"]) == "ledger" and not bool(st["contrast"]) and not bool(st["sorted_view"]), "…and round to ledger, uniform, as drawn")
	# order B: DISCLOSE to origin first, then CONTRAST
	for k in range(2):
		panel = meter.get_node_or_null("Staging/Panel")
		_press(panel, "Btn_2")
		await process_frame
		await process_frame
	panel = meter.get_node_or_null("Staging/Panel")
	st = meter.call("get_ledger_state")
	check(str(st["disclosure"]) == "origin" and not bool(st["contrast"]), "order B: DISCLOSE twice to origin with the uniform sample")
	ghost_records.append(_ghost_check("B: uniform at origin, as drawn", st, meter))
	check(_press(panel, "Btn_1"), "…then CONTRAST at origin")
	await process_frame
	await process_frame
	st = meter.call("get_ledger_state")
	ghost_records.append(_ghost_check("B: origin → contrast, as drawn", st, meter))
	if readout != null:
		check(readout.text.get_slice("\n", 5).begins_with("law p∝2⁻ᵏ · expected 100.1 50.0 25.0"), "the readout names the law and its expected counts at origin (%s)" % readout.text.get_slice("\n", 5))
	if capture:
		cam.global_position = meter.to_global(Vector3(0.0, LIFT + 0.05, 1.0)); cam.look_at(meter.to_global(Vector3(0.0, LIFT, 0.0)))
		for i in range(15): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_entropy_origin_contrast.png")
		measurements["captures"]["origin_contrast"] = _cam_pose(cam)
	check(_press(panel, "Btn_0"), "…SORT on at origin with the contrast")
	await create_timer(1.6).timeout
	st = meter.call("get_ledger_state")
	ghost_records.append(_ghost_check("B: origin → contrast, sorted", st, meter))
	check(_press(panel, "Btn_0"), "…SORT off")
	await create_timer(1.6).timeout
	check(_press(panel, "Btn_1"), "…CONTRAST off")
	await process_frame
	await process_frame
	st = meter.call("get_ledger_state")
	ghost_records.append(_ghost_check("B: uniform at origin again, as drawn", st, meter))
	for k in range(3):
		panel = meter.get_node_or_null("Staging/Panel")
		_press(panel, "Btn_2")
		await process_frame
		await process_frame
	panel = meter.get_node_or_null("Staging/Panel")
	st = meter.call("get_ledger_state")
	measurements["ghosts"] = ghost_records
	check(str(st["disclosure"]) == "ledger" and (meter.call("get_sequence") as Array) == seq and float(st["entropy"]) == h_before and not bool(st["sorted_view"]) and not bool(st["contrast"]) and (st["ghost_heights"] as Array).is_empty(),
		"back at the arrival: ledger, the first sample, as drawn, no ghosts")

	# ── 8. what else, and the museum's verdicts ───────────────────────────────
	await create_timer(0.3).timeout
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
		for rc in [[4, 4, 7, 9], [7, 0, 10, 11]]:
			if int(p[1]) >= rc[0] and int(p[1]) < rc[2] and int(p[2]) >= rc[1] and int(p[2]) < rc[3]: in_rect = true   # the far edge is exclusive, as the museum reads it
	check(not in_rect, "no dealt plinth stands in the clear rects (the desk and its approach, the door route) (plinths: %s)" % str(plinths))

	# ── 9. walks: the door route, the approach, into the desk, along its front ──
	var pspace := seg.get_world_3d().direct_space_state
	var capsule := CapsuleShape3D.new(); capsule.radius = 0.22; capsule.height = 1.6
	var wq := PhysicsShapeQueryParameters3D.new(); wq.shape = capsule
	var lane_fracs: Array = []
	for route in [["the door route south along column 7, row 1 to row 10", Vector3(7.5, 0.81, 1.5), Vector3(0, 0, 9.0), 2],
			["the door route south along column 8, row 1 to row 10", Vector3(8.5, 0.81, 1.5), Vector3(0, 0, 9.0), 2],
			["the door route south along column 9, row 1 to row 10", Vector3(9.5, 0.81, 1.5), Vector3(0, 0, 9.0), 2],
			["from the corridor west to the desk's front", Vector3(8.5, 0.81, 6.5), Vector3(-1.6, 0, 0), 1],
			["along the desk's front, north to south", Vector3(6.75, 0.81, 4.9), Vector3(0, 0, 3.2), 1],
			["into the desk from the corridor side", Vector3(7.0, 0.81, 6.5), Vector3(-1.2, 0, 0), 0]]:
		wq.transform = Transform3D(Basis.IDENTITY, seg.to_global(Vector3(route[1].x, route[1].y, route[1].z + vest)))
		wq.motion = route[2]
		var frac: float = pspace.cast_motion(wq)[0]
		var key: String = "walk_" + str(route[0]).replace(" ", "_").replace("'", "").replace(",", "")
		measurements[key] = frac
		if frac < 0.99:
			# what stopped the body, by collider name, at the stop
			var blockers: Array = []
			var stop: Vector3 = wq.transform.origin + route[2] * frac + route[2].normalized() * 0.03
			var q2 := PhysicsShapeQueryParameters3D.new(); q2.shape = capsule; q2.transform = Transform3D(Basis.IDENTITY, stop)
			for hit in pspace.intersect_shape(q2, 8):
				var col: Node = (hit as Dictionary).get("collider")
				if col != null: blockers.append(str(col.get_path()).right(70))
			measurements[key + "_blockers"] = blockers
			print("[wcn-entropy] measured: %s %.2f of the way; stopped by %s" % [route[0], frac, str(blockers)])
		if int(route[3]) == 1:
			check(frac > 0.99, "a body walks %s (%.2f of the way)" % [route[0], frac])
		elif int(route[3]) == 0:
			check(frac < 0.75, "the desk is solid: a body walking into it is stopped (%.2f of 1.2 m)" % frac)
		else:
			lane_fracs.append(frac)
	check(lane_fracs.max() > 0.99, "at least one lane of the three-wide door route runs from row 1 to row 10 (columns 7, 8, 9: %s)" % str(lane_fracs))
	# reading distance: from a standing eye before the desk to the ribbon's far ends
	var eye: Vector3 = seg.to_global(Vector3(6.85, 1.55, 6.5 + vest))
	var far_tile: float = maxf(eye.distance_to(meter.to_global(Vector3(-1.0, DESK_H, float(meter.get("RIBBON_Z"))))), eye.distance_to(meter.to_global(Vector3(1.0, DESK_H, float(meter.get("RIBBON_Z"))))))
	measurements["reading_distance_to_ribbon_end"] = far_tile
	check(far_tile < 1.7, "the ribbon's far ends are within reading distance of a standing eye (%.2f m)" % far_tile)
	var b0n: Node3D = panel.find_child("Btn_0", true, false)
	# a step to the right: the eye before the panel, 0.5 m from the desk's front
	var eye_p: Vector3 = meter.to_global(Vector3(0.78, 1.55, 1.15))
	measurements["reach_to_sort_button"] = eye_p.distance_to(b0n.global_position) if b0n != null else -1.0
	check(b0n != null and eye_p.distance_to(b0n.global_position) < 1.1, "the SORT button is within an arm of an eye before the panel (%.2f m)" % (eye_p.distance_to(b0n.global_position) if b0n != null else -1.0))

	# ── ACTUAL DESKTOP INPUT (live harness only) ─────────────────────────────
	if _live():
		var drv: Node = load("res://commons/testing/wcn_desktop_driver.gd").new()
		root.add_child(drv)   # a SceneTree has no add_child; the port maps root. to get_tree().root.
		# a metre and a half before the desk's front, clear of every collider
		var stand: Vector3 = seg.to_global(Vector3(7.7, 0.0, 6.0 + vest))
		drv.call("spawn", stand, em)
		await create_timer(0.5).timeout
		var b0: Node = panel.find_child("Btn_0", true, false)
		var rec0: Dictionary = await drv.call("press", b0, stand) if b0 != null else {}
		await create_timer(1.6).timeout
		st = meter.call("get_ledger_state")
		measurements["desktop_input"] = {"press_sort": rec0, "sorted_after": st["sorted_view"]}
		check(str(rec0.get("hover", "")).contains("Btn_0") or str(rec0.get("hover", "")).contains("InteractableAreaButton"), "the desktop pointer had SORT under the crosshair (%s)" % str(rec0.get("hover", "")))
		check(bool(st["sorted_view"]), "SORT pressed through the pointer regroups the tiles")
		if capture:
			drv.call("aim_at", meter.to_global(Vector3(0.0, 1.15, 0.2)))
			for i in range(12): await process_frame
			await create_timer(0.3, true, false, true).timeout
			root.get_texture().get_image().save_png(OUT + "probe_entropy_desktop_front.png")
			measurements["desktop_input"]["front_capture_pose"] = drv.call("pose")
		await drv.call("press", b0, stand)
		await create_timer(1.6).timeout
		var b1: Node = panel.find_child("Btn_1", true, false)
		var rec1: Dictionary = await drv.call("press", b1, stand) if b1 != null else {}
		await process_frame
		await process_frame
		st = meter.call("get_ledger_state")
		measurements["desktop_input"]["press_contrast"] = rec1
		check(bool(st["contrast"]), "CONTRAST pressed through the pointer puts the concentrated sample on the wall")
		await drv.call("press", b1, stand)
		await process_frame
		await process_frame
		var b2: Node = panel.find_child("Btn_2", true, false)
		var rec2: Dictionary = await drv.call("press", b2, stand) if b2 != null else {}
		await process_frame
		await process_frame
		measurements["desktop_input"]["press_disclose"] = rec2
		check(str(meter.get("disclosure")) == "works", "DISCLOSE pressed through the pointer steps the rung (%s)" % str(meter.get("disclosure")))
		panel = meter.get_node_or_null("Staging/Panel")
		b2 = panel.find_child("Btn_2", true, false)
		for k in range(4):
			await drv.call("press", b2, stand)
			await process_frame
			await process_frame
			panel = meter.get_node_or_null("Staging/Panel")
			b2 = panel.find_child("Btn_2", true, false)
		check(str(meter.get("disclosure")) == "ledger", "…and four more presses bring it round to ledger (%s)" % str(meter.get("disclosure")))
		# the door route: walk south from the north door on ui_up; then into the desk
		drv.get("rig").global_position = seg.to_global(Vector3(8.5, 0.05, 1.2 + vest))
		await physics_frame
		drv.call("aim_at", seg.to_global(Vector3(8.5, 1.2, 8.0 + vest)))
		var moved_v: Vector3 = await drv.call("walk", "ui_up", 30)
		var ml: Vector3 = seg.global_transform.basis.inverse() * moved_v
		measurements["desktop_input"]["walk_door_route_south"] = [snappedf(ml.x, 0.01), snappedf(ml.z, 0.01)]
		check(ml.z > 2.0, "the rig walks the door route south on ui_up (%.2f m in half a second)" % ml.z)
		drv.get("rig").global_position = seg.to_global(Vector3(7.4, 0.05, 6.5 + vest))
		await physics_frame
		drv.call("aim_at", seg.to_global(Vector3(5.5, 1.0, 6.5 + vest)))
		moved_v = await drv.call("walk", "ui_up", 20)
		ml = seg.global_transform.basis.inverse() * moved_v
		measurements["desktop_input"]["walk_into_the_desk"] = [snappedf(ml.x, 0.01), snappedf(ml.z, 0.01)]
		check(ml.x > -1.0, "walking west from the corridor, the rig is stopped by the desk (%.2f m of a possible 1.67)" % -ml.x)
		await drv.call("teardown")
		measurements["desktop_input"]["log"] = drv.get("log")
		measurements["desktop_input"]["walker_cam_guard_stopped"] = drv.get("walker_cam_guard_stopped")
		await process_frame

	# ── captures ─────────────────────────────────────────────────────────────
	if capture:
		await create_timer(0.5).timeout
		cam.global_position = seg.to_global(Vector3(6.95, 1.55, 6.5 + vest)); cam.look_at(seg.to_global(Vector3(5.5, 1.15, 6.5 + vest)))
		for i in range(20): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_entropy.png")
		measurements["captures"]["primary"] = _cam_pose(cam)
		var rc_node: Node3D = meter.get_node_or_null("Staging/ReadoutCase")
		if rc_node != null:
			cam.global_position = rc_node.global_position + meter.global_transform.basis * Vector3(0.0, 0.55, 0.62); cam.look_at(rc_node.global_position)
			for i in range(15): cam.make_current(); await process_frame
			await create_timer(0.3, true, false, true).timeout
			root.get_texture().get_image().save_png(OUT + "probe_entropy_readout.png")
			measurements["captures"]["readout"] = _cam_pose(cam)
		cam.global_position = meter.to_global(Vector3(0.0, 1.35, 1.1)); cam.look_at(meter.to_global(Vector3(0.0, 0.95, 0.4)))
		for i in range(15): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_entropy_ribbon.png")
		measurements["captures"]["ribbon"] = _cam_pose(cam)
		# standing approach: the corridor's west edge, 2.2 m from the panel, eye height
		cam.global_position = seg.to_global(Vector3(7.7, 1.6, 6.9 + vest)); cam.look_at(seg.to_global(Vector3(5.5, 1.3, 6.5 + vest)))
		for i in range(15): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_entropy_approach.png")
		measurements["captures"]["approach"] = _cam_pose(cam)
		# at the panel: leaning in, 0.75 m before it
		cam.global_position = meter.to_global(Vector3(0.0, LIFT + 0.08, 0.75)); cam.look_at(meter.to_global(Vector3(0.0, LIFT, 0.0)))
		for i in range(15): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_entropy_panel_close.png")
		measurements["captures"]["panel_close"] = _cam_pose(cam)
		# the buttons, from a standing eye a step to the right
		cam.global_position = meter.to_global(Vector3(0.78, 1.55, 1.15)); cam.look_at(meter.to_global(Vector3(0.78, 0.74, 0.69)))
		for i in range(15): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_entropy_buttons.png")
		measurements["captures"]["buttons"] = _cam_pose(cam)
		cam.global_position = seg.to_global(Vector3(8.6, 2.0, 10.6 + vest)); cam.look_at(seg.to_global(Vector3(5.8, 1.1, 6.6 + vest)))
		for i in range(15): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_entropy_overview.png")
		measurements["captures"]["overview"] = _cam_pose(cam)
		cam.queue_free()

	# ── MUSEUM STREAMING: free the hall, rebuild it ──────────────────────────────
	var seg_i: int = -1
	var segs: Array = em.get("_segments")
	for i in range(segs.size()):
		if (segs[i] as Dictionary).get("node") == seg: seg_i = i
	if seg_i >= 0 and em.has_method("_stream_free"):
		var z0: float = seg.global_position.z
		var meter_ref: WeakRef = weakref(meter)
		var panel_ref: WeakRef = weakref(panel)
		em.call("_stream_free", seg_i, "south")
		for i in range(5): await process_frame
		var freed: bool = meter_ref.get_ref() == null and panel_ref.get_ref() == null
		check(freed, "the museum's streamer frees the hall, the gauge and its panel with it")
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
			var meter2: Node3D
			if seg2 != null:
				for n in seg2.find_children("*", "Node3D", true, false):
					if n.get_script() != null and str(n.get_script().resource_path).ends_with("shannon_entropy_meter.gd"): meter2 = n; break
			var rebuilt: Dictionary = {"found": meter2 != null, "stand": str(meter2.get("stand")) if meter2 != null else "", "desk": meter2 != null and meter2.get_node_or_null("Staging/Desk") != null,
				"panel": meter2 != null and meter2.get_node_or_null("Staging/Panel") != null, "ribbon": meter2 != null and meter2.get_node_or_null("Staging/Ribbon") != null,
				"bars": (meter2.get("_freq_bars") as Array).size() if meter2 != null else -1, "children": meter2.get_child_count() if meter2 != null else -1}
			measurements["rebuilt"] = rebuilt
			check(meter2 != null and str(meter2.get("stand")) == "ledger" and meter2.get_node_or_null("Staging/Desk") != null and meter2.get_node_or_null("Staging/Panel") != null,
				"the rebuilt hall has its gauge again, staged, with desk and panel (%s)" % str(rebuilt))
			if meter2 != null:
				check((meter2.call("get_sequence") as Array) == seq and float(meter2.call("get_entropy")) == h_before, "the rebuilt gauge reads the same draws and the same H")
	_finish()

## At `origin`: the ten ghost bars must be the ACTIVE law's expected counts, in value and in
## drawn height — p(k) normalised, expected = p(k)·N, height = clamp(expected / max count, 0, 1)·0.1.
func _ghost_check(label: String, st: Dictionary, meter: Node) -> Dictionary:
	var probs: Array = st["probabilities"]
	var expected: Array = st["expected_counts"]
	var heights: Array = st["ghost_heights"]
	var counts: Array = st["counts"]
	var n: int = int(st["n"])
	var psum: float = 0.0
	for pv in probs: psum += float(pv)
	var esum: float = 0.0
	for ev in expected: esum += float(ev)
	var max_count: int = 0
	for c in counts: max_count = maxi(max_count, int(c))
	var law_ok := true
	var want_probs: Array = []
	if bool(st["contrast"]):
		var total: float = 0.0
		for k in range(10): total += pow(2.0, -float(k))
		for k in range(10): want_probs.append(pow(2.0, -float(k)) / total)
	else:
		for k in range(10): want_probs.append(0.1)
	for k in range(10):
		if absf(float(probs[k]) - float(want_probs[k])) > 0.000001: law_ok = false
	var heights_ok := heights.size() == 10
	var want_heights: Array = []
	for k in range(10):
		var wh: float = maxf(0.002, clampf(float(expected[k]) / float(max_count), 0.0, 1.0) * 0.1)
		want_heights.append(snappedf(wh, 0.0001))
		if heights.size() == 10 and absf(float(heights[k]) - wh) > 0.0002: heights_ok = false
	var staircase := true
	if bool(st["contrast"]) and heights.size() == 10:
		for k in range(9):
			if float(heights[k]) < float(heights[k + 1]) - 0.0000001: staircase = false
	var flat := true
	if not bool(st["contrast"]) and heights.size() == 10:
		for k in range(9):
			if absf(float(heights[k]) - float(heights[k + 1])) > 0.0000001: flat = false
	var place: Dictionary = _bars_place(meter)
	var rec := {"label": label, "contrast": st["contrast"], "sorted": st["sorted_view"], "probabilities": probs, "expected": expected, "expected_sum": esum, "ghost_heights": heights, "want_heights": want_heights, "max_count": max_count, "bars_place": place}
	check(bool(place["on_panel"]), "%s: the bars and the ghosts stand on the lifted panel (y %.2f–%.2f)" % [label, float(place["min_y"]), float(place["max_y"])])
	check(absf(psum - 1.0) < 0.000001 and absf(esum - float(n)) < 0.0001 and law_ok, "%s: the law's probabilities are the named ones and sum to 1; expected counts sum to N (%.4f)" % [label, esum])
	check(heights_ok, "%s: the ten ghost bars are drawn at the expected counts' heights (%s vs %s)" % [label, str(heights), str(want_heights)])
	check((staircase and bool(st["contrast"])) or (flat and not bool(st["contrast"])), "%s: the ghosts read as %s" % [label, "a descending staircase (p ∝ 2⁻ᵏ)" if bool(st["contrast"]) else "one flat line (uniform)"])
	return rec

## Where the histogram bars and the ghosts stand (segment-local y): on the lifted panel means
## within [LIFT - 0.25, LIFT + 0.05]; a bar written in the shipped frame sits 1.4 m lower.
func _bars_place(meter: Node) -> Dictionary:
	var lo: float = 99.0
	var hi: float = -99.0
	var n: int = 0
	for arr_name in ["_freq_bars", "_expected_bars"]:
		for b in (meter.get(arr_name) as Array):
			if not is_instance_valid(b): continue
			var y: float = _seg.to_local((b as Node3D).global_position).y
			lo = minf(lo, y); hi = maxf(hi, y); n += 1
	return {"count": n, "min_y": lo, "max_y": hi, "on_panel": n > 0 and lo > _lift - 0.25 and hi < _lift + 0.05}

## The measurement's loop, in the probe's own words: -Σ p log₂ p, zero counts omitted.
func _entropy(counts: Array, n: int) -> float:
	var h: float = 0.0
	for c in counts:
		if int(c) > 0:
			var p: float = float(int(c)) / float(n)
			h -= p * (log(p) / log(2.0))
	return h

## The ribbon's tiles counted by their instance colour against the meter's symbol colours.
func _tile_counts_by_colour(ribbon: MultiMeshInstance3D, meter: Node) -> Array:
	var out: Array = []
	for i in range(10): out.append(0)
	if ribbon == null or ribbon.multimesh == null: return out
	var mm: MultiMesh = ribbon.multimesh
	# instance colours come back quantised from the buffer: the nearest symbol colour wins
	for i in range(mm.instance_count):
		var col: Color = mm.get_instance_color(i)
		var best: int = -1
		var best_d: float = 9.0
		for s in range(10):
			var sc: Color = meter.call("_symbol_color", s)
			var dd: float = absf(col.r - sc.r) + absf(col.g - sc.g) + absf(col.b - sc.b)
			if dd < best_d:
				best_d = dd; best = s
		if best >= 0 and best_d < 0.1:
			out[best] = int(out[best]) + 1
	return out

func _tile_xs(ribbon: MultiMeshInstance3D) -> Array:
	var out: Array = []
	if ribbon == null or ribbon.multimesh == null: return out
	for i in range(ribbon.multimesh.instance_count):
		out.append(snappedf(ribbon.multimesh.get_instance_transform(i).origin.x, 0.0001))
	return out

## Tile indices ordered by their x on the desk (left to right).
func _order_by_x(xs: Array) -> Array:
	var idx: Array = []
	for i in range(xs.size()): idx.append(i)
	idx.sort_custom(func(a, b): return float(xs[a]) < float(xs[b]))
	return idx

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
		"control_path": "panel buttons through the push button's own signal; measure() for the contract's ends; the live lane adds the desktop rig's pointer pressing the panel; no tracked hand",
		"hand_file": "ada_run/necklace_hand.json (real)", "headset_verified": false,
		"engine": Engine.get_version_info().string, "physics_fps": Engine.physics_ticks_per_second}
	var f := FileAccess.open(OUT + "probe_entropy.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  ")); f.close()
	print("[wcn-entropy] ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
