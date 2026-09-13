extends SceneTree
## WaveFunctions_Pendulum, batch W1 (doc/research/waves-chance-noise, 2026-09-10):
## does the installed pendulum keep a bounded record of its own past, and can a
## visitor read count, span and interval off the room?
##
## Stands up the ACTUAL museum hall with its artifacts (the pattern of
## probe_wcn_intro.gd), hands the museum the REAL necklace hand file (the
## stamps under wavefunctions|pendulum are keyed to an old pearl name and must
## not claim anything; the map opts into artifact_placement=map besides), finds
## the PendulumWave, and measures the record under the three sampling policies.
## Buttons are pressed by EMITTING the push button's own signal — no tracked hand.
##
##   godot --rendering-method gl_compatibility --path . --xr-mode off --script res://commons/testing/probe_wcn_pendulum.gd -- --capture
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_wcn_pendulum.gd
##
## Writes res://ada_run/waves_chance_noise/WaveFunctions_Pendulum/probe_pendulum.json
## (and probe_pendulum.png under --capture). Exit code 1 on any failed check.
var checks := 0
var failures: Array[String] = []
var measurements: Dictionary = {}
const MAP := "WaveFunctions_Pendulum"
const OUT := "res://ada_run/waves_chance_noise/WaveFunctions_Pendulum/"
const MAP_CELL := Vector2i(6, 11)

func _initialize() -> void: run.call_deferred()

## True under the live harness (probe_live.tscn, project startup with autoloads);
## false under --script, where the desktop rig cannot compile.
func _live() -> bool:
	return str(get_script().resource_path).ends_with("_live.gd")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[wcn-pendulum] ", "PASS " if ok else "FAIL ", message)

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

	# ── 1. built where the map put it, housed ────────────────────────────────
	var pend: Node3D
	var pend_cell: Array = []
	for record: Dictionary in em.get("_edit_records"):
		var node: Node = record.get("node")
		if node != null and seg.is_ancestor_of(node) and node.get_script() != null and str(node.get_script().resource_path).ends_with("PendulumWave.gd"):
			pend = node; pend_cell = record.get("tile_cell", [])
	if pend == null:
		for n in seg.find_children("*", "Node3D", true, false):
			if n.get_script() != null and str(n.get_script().resource_path).ends_with("PendulumWave.gd"): pend = n; break
	check(pend != null, "PendulumWave is built in the hall")
	if pend == null:
		_finish(); return
	if pend_cell.size() >= 2:
		# _edit_records keeps the MAP cell (observed 2026-09-10: [6, 11]); the vestibule offset lives in world z only
		check(int(pend_cell[0]) == MAP_CELL.x and int(pend_cell[1]) == MAP_CELL.y,
			"built at the map's cell (6,11), not a bench bead (got %s)" % str(pend_cell))
	var local_origin: Vector3 = seg.to_local(pend.global_position)
	measurements["origin_local"] = [local_origin.x, local_origin.y, local_origin.z]
	check(absf(local_origin.x - 6.5) < 0.6 and absf(local_origin.z - (11.5 + vest)) < 0.6, "the installation stands on its cell (%.1f, %.1f)" % [local_origin.x, local_origin.z - vest])
	check(pend.get_node_or_null("Frame/PostL") != null and pend.get_node_or_null("Frame/Beam") != null, "the gallows frame is built")
	var readout: Label3D = pend.get_node_or_null("ReadoutCase/Readout")
	check(readout != null, "the cased readout exists")
	var panel: Node = pend.get_node_or_null("Panel")
	check(panel != null, "the sampler panel exists")
	check(panel != null and panel.get_meta("em_local_instrument", false), "the panel is marked a local instrument (its button areas are not the installation's footprint)")
	if readout != null:
		var rh: float = seg.to_local(readout.global_position).y
		measurements["readout_height"] = rh
		check(rh > 1.2 and rh < 1.7, "the readout sits at reading height (%.2f m above the deck)" % rh)
		var rz: float = seg.to_local(readout.global_position).z - vest
		check(rz > 13.5 and rz < 15.5, "the readout stands three metres down the record, south of the bob (z %.1f)" % rz)
		var rx: float = seg.to_local(readout.global_position).x
		check(rx > 7.5, "on the east walkway side (x %.1f)" % rx)
	var btn0: Node = panel.find_child("Btn_0", true, false) if panel != null else null
	if btn0 != null:
		var bh: float = seg.to_local(btn0.global_position).y
		measurements["panel_height"] = bh
		check(bh > 0.9 and bh < 1.45, "the panel buttons are at hand height (%.2f m)" % bh)
	if panel != null:
		# the visual pass of 12 September: the panel faces the east walkway (world +x), where
		# the visitor stands to see the bob, the trail and the buttons together
		var facing: Vector3 = seg.global_transform.basis.inverse() * (panel as Node3D).global_transform.basis.z
		measurements["panel_facing"] = [snappedf(facing.x, 0.01), snappedf(facing.y, 0.01), snappedf(facing.z, 0.01)]
		check(facing.x > 0.9, "the sampler panel faces the east walkway (%s)" % str(measurements["panel_facing"]))
		var px: float = seg.to_local((panel as Node3D).global_position).x
		check(px > 8.0, "the panel stands outboard of the east post (x %.2f)" % px)
	check(pend.get_node_or_null("Runner") != null, "a dark runner lies under the record")
	# the two holes the museum read from the map's 0 cells — the tc cell in the west aisle
	# (2,8) and the teleporter's cell (7,18) — are floored by museum.floor_cells now
	var pspace0 := seg.get_world_3d().direct_space_state
	for hole in [[2.5, 8.5, "the west aisle's tc cell (2,8)"], [7.5, 18.5, "the teleporter's cell (7,18)"]]:
		var rq := PhysicsRayQueryParameters3D.create(seg.to_global(Vector3(hole[0], 3.0, hole[1] + vest)), seg.to_global(Vector3(hole[0], -3.0, hole[1] + vest)))
		var hit: Dictionary = pspace0.intersect_ray(rq)
		var fy: float = seg.to_local(hit["position"]).y if not hit.is_empty() else -99.0
		measurements["floor_" + str(hole[2]).replace(" ", "_").replace("'", "")] = snappedf(fy, 0.001)
		check(abs(fy) < 0.02, "floor under %s (%.2f)" % [hole[2], fy])
	var bob_w: Vector3 = pend.call("bob_world_position")
	var bob_h: float = seg.to_local(bob_w).y
	measurements["bob_rest_height"] = bob_h
	check(bob_h > 0.7 and bob_h < 1.6, "the bob swings at hand-to-eye height (%.2f m)" % bob_h)
	# the swing envelope and the record's lane are clear of the hall's collision
	var L: float = float(pend.get("length"))
	var ph: float = float(pend.get("pivot_height"))
	var env := BoxShape3D.new(); env.size = Vector3(2.0 * L + 0.3, L + 0.3, 0.3)
	var q := PhysicsShapeQueryParameters3D.new(); q.shape = env
	q.transform = Transform3D(Basis.IDENTITY, pend.to_global(Vector3(0, ph - L * 0.5, 0)))
	check(_solid_hits(seg, q) == 0, "the complete swing is clear of walls and platforms")
	var lane := BoxShape3D.new(); lane.size = Vector3(3.0, 0.8, 6.2)
	q.shape = lane; q.transform = Transform3D(Basis.IDENTITY, pend.to_global(Vector3(0, ph - L + 0.4, -3.1)))
	check(_solid_hits(seg, q) == 0, "the six-metre lane the record recedes into is clear of the hall's collision")
	# ...and of everything else with a collider: museum plinths, sculptures, other bodies
	var others: Array = []
	for h in seg.get_world_3d().direct_space_state.intersect_shape(q, 16):
		var c: Node = h.collider
		if c == seg.get_node_or_null("Collision") or pend.is_ancestor_of(c): continue
		others.append(str(c.get_path()).right(70))
	measurements["lane_other_colliders"] = others
	check(others.is_empty(), "nothing else with a collider stands in the record's lane (%s)" % str(others))

	# ── 2. the fine record: count, span, depth, direction ─────────────────────
	pend.call("reset_experiment")
	await create_timer(3.0).timeout
	var n3: int = int(pend.call("sample_count"))
	var kept3: float = float(pend.call("retained_seconds"))
	measurements["fine_after_3s"] = {"count": n3, "kept": kept3, "t": float(pend.call("experiment_time"))}
	check(n3 >= 100 and n3 <= 130, "after ~3 s the fine sampler has taken about 120 marks (25 ms target): %d" % n3)
	var observed_gaps: Vector2 = pend.call("recorded_interval_range")
	measurements["fine_actual_gaps_ms"] = [observed_gaps.x * 1000.0, observed_gaps.y * 1000.0]
	if Engine.physics_ticks_per_second == 60:
		check(absf(observed_gaps.x - 1.0 / 60.0) < 0.0001 and absf(observed_gaps.y - 2.0 / 60.0) < 0.0001,
			"25 ms target is visibly quantized to one/two physics ticks")
	check(str(pend.call("readout_text")).contains("target ") and str(pend.call("readout_text")).contains("actual gaps"),
		"the display distinguishes the requested interval from the recorded gaps")
	check(absf(kept3 - 3.0) < 0.4, "and the span kept is the time elapsed (%.2f s)" % kept3)
	await create_timer(6.0).timeout
	var n9: int = int(pend.call("sample_count"))
	var kept9: float = float(pend.call("retained_seconds"))
	var depth9: float = float(pend.call("oldest_depth"))
	measurements["fine_after_9s"] = {"count": n9, "kept": kept9, "oldest_depth": depth9}
	check(n9 == 300, "the count stops at the first limit, 300 marks (%d)" % n9)
	check(absf(kept9 - 7.5) < 0.15, "300 marks at the 25 ms target keep about 7.5 s under the 10 s age limit (%.2f s)" % kept9)
	check(absf(depth9 - 4.5) < 0.15, "the oldest mark stands 4.5 m behind the bob: 7.5 s at 0.6 m per s (%.2f m)" % depth9)
	var marks: PackedVector3Array = pend.call("mark_world_positions")
	if marks.size() > 1:
		var newest: Vector3 = seg.to_local(marks[0]); var oldest: Vector3 = seg.to_local(marks[marks.size() - 1])
		measurements["newest_local"] = [newest.x, newest.y, newest.z - vest]
		measurements["oldest_local"] = [oldest.x, oldest.y, oldest.z - vest]
		check(oldest.z > newest.z + 4.0, "the record recedes SOUTH, down the open half toward the exit (rotation 180 honoured)")
		var xs := PackedFloat32Array()
		for m in marks: xs.append(seg.to_local(m).x)
		var lo: float = xs[0]; var hi: float = xs[0]
		for v in xs: lo = minf(lo, v); hi = maxf(hi, v)
		measurements["fine_x_spread"] = hi - lo
		check(hi - lo > 2.0, "the fine record spans the swing (x spread %.2f m)" % (hi - lo))
	var period: float = float(pend.call("period_measured"))
	measurements["period_measured"] = period
	check(period > 2.7 and period < 3.2, "the pendulum has measured its own period from two upward crossings (%.3f s; small-angle %.3f s)" % [period, float(pend.call("small_angle_period"))])
	var interval: float = float(pend.call("current_interval"))
	check(period > 0.0 and absf(period / interval - _marks_per_period(marks, pend)) < 4.0,
		"marks between two same-side crossings ≈ period / target interval (%.1f vs counted %d)" % [period / interval, _marks_per_period(marks, pend)])
	if readout != null:
		measurements["readout_fine"] = readout.text
		check(readout.text.contains("300 marks kept 7.5 s") and readout.text.contains("target 25 ms"), "the readout prints the count, the span and the interval")

	# ── 3. COARSE through the panel's own signal ──────────────────────────────
	var pressed_coarse: bool = _press(panel, "Btn_1")
	check(pressed_coarse, "COARSE pressed by emitting the push button's button_pressed (programmatic, no hand)")
	await physics_frame
	check(int(pend.call("sample_count")) <= 1, "switching the sampler starts the record again")
	var angle_before: float = float(pend.get("angle"))
	await create_timer(10.5).timeout
	var nc: int = int(pend.call("sample_count"))
	var keptc: float = float(pend.call("retained_seconds"))
	measurements["coarse_after_10.5s"] = {"count": nc, "kept": keptc, "oldest_depth": float(pend.call("oldest_depth"))}
	check(nc >= 48 and nc <= 52, "the coarse sampler never reaches 300: ~50 marks at 200 ms (%d)" % nc)
	check(absf(keptc - 10.0) < 0.25, "and is cut by the second limit, the 10 s age (%.2f s)" % keptc)
	check(absf(float(pend.call("oldest_depth")) - 6.0) < 0.2, "so the oldest mark stands 6 m back (%.2f m)" % float(pend.call("oldest_depth")))
	check(absf(float(pend.call("period_measured")) - period) < 0.02, "the motion was not touched by the switch: the period is the same (%.3f s)" % float(pend.call("period_measured")))

	# ── 4. STROBE: a record at the rhythm of the thing recorded ───────────────
	check(_press(panel, "Btn_2"), "STROBE pressed through its signal")
	await create_timer(10.5).timeout
	var ns: int = int(pend.call("sample_count"))
	var smarks: PackedVector3Array = pend.call("mark_world_positions")
	var slo: float = INF; var shi: float = -INF
	for m in smarks:
		var x: float = seg.to_local(m).x; slo = minf(slo, x); shi = maxf(shi, x)
	measurements["strobe"] = {"count": ns, "interval": float(pend.call("current_interval")), "x_spread": (shi - slo) if ns > 0 else 0.0}
	check(ns >= 3 and ns <= 4, "one mark per period: 3–4 marks in 10 s (%d)" % ns)
	check(absf(float(pend.call("current_interval")) - period) < 0.02, "the strobe interval IS the measured period (%.3f s)" % float(pend.call("current_interval")))
	check(ns >= 2 and (shi - slo) < 0.12, "the sampled positions nearly align while the bob moves (x spread %.3f m)" % (shi - slo))

	# ── 5. RESET resets this experiment only ──────────────────────────────────
	var t_before: float = float(pend.call("experiment_time"))
	var engine_ticks_before := Engine.get_physics_frames()
	check(_press(panel, "Btn_3"), "RESET pressed through its signal")
	await physics_frame
	check(float(pend.call("experiment_time")) < t_before and float(pend.call("experiment_time")) < 0.1, "the experiment clock returns to zero")
	check(int(pend.call("sample_count")) <= 1, "the record is emptied")
	check(absf(float(pend.get("angle")) - deg_to_rad(float(pend.get("initial_angle")))) < 0.05, "the swing returns to its starting angle")
	check(str(pend.get("sampler")) == "strobe", "the chosen sampler survives a reset (the reset is of the experiment, not the settings)")
	check(Engine.get_physics_frames() > engine_ticks_before, "engine physics ticks advance while the local experiment resets")

	# ── 5b. ONE POLICY, TWO RENDER RATES (Astra's evidence) ──────────────────────
	# The sampler runs on the physics step, so the render rate should change nothing it
	# records. Asserted, not assumed: the same FINE record at 30 and at 120 frames a
	# second, with the frames actually drawn counted so the two rates are shown to differ.
	var fps_saved: int = Engine.max_fps
	var rates: Dictionary = {}
	pend.call("set_sampler", "fine")
	for fps in [30, 120]:
		Engine.max_fps = fps
		pend.call("reset_experiment")
		await physics_frame
		var f0: int = Engine.get_frames_drawn()
		var p0: int = Engine.get_physics_frames()
		var w0: int = Time.get_ticks_msec()
		while float(pend.call("experiment_time")) < 3.0:
			await physics_frame
		var wall: float = maxf(0.001, float(Time.get_ticks_msec() - w0) / 1000.0)
		var g: Vector2 = pend.call("recorded_interval_range")
		rates[str(fps)] = {"count": int(pend.call("sample_count")), "kept_s": snappedf(float(pend.call("retained_seconds")), 0.001),
			"gap_ms": [snappedf(g.x * 1000.0, 0.1), snappedf(g.y * 1000.0, 0.1)],
			"frames_drawn": Engine.get_frames_drawn() - f0, "physics_steps": Engine.get_physics_frames() - p0,
			"render_fps": snappedf(float(Engine.get_frames_drawn() - f0) / wall, 0.1)}
		note("render %d: %s" % [fps, JSON.stringify(rates[str(fps)])])
	Engine.max_fps = fps_saved
	measurements["render_rates"] = rates
	var r30: Dictionary = rates["30"]
	var r120: Dictionary = rates["120"]
	check(float(r120["render_fps"]) > 1.8 * float(r30["render_fps"]), "the two render rates really differ (%.1f and %.1f frames a second)" % [float(r30["render_fps"]), float(r120["render_fps"])])
	check(absi(int(r30["count"]) - int(r120["count"])) <= 1, "and the record does not: %d marks at 30, %d at 120" % [int(r30["count"]), int(r120["count"])])
	check(absf(float(r30["kept_s"]) - float(r120["kept_s"])) < 0.03, "the same span kept (%.3f s, %.3f s)" % [float(r30["kept_s"]), float(r120["kept_s"])])
	check(r30["gap_ms"] == r120["gap_ms"], "the same actual gaps, which are the physics step's, not the requested 25 ms (%s ms)" % str(r30["gap_ms"]))

	# ── 5c. EVICTION, AND MEMORY THAT STOPS GROWING ──────────────────────────────
	# Past the 300-mark cap the record must lose its oldest marks as it gains new ones.
	# Sampled three times, five seconds apart: the count, the OLDEST retained timestamp
	# (which must move on), the marks' instance count and the trail's vertex count, and
	# the engine's static memory.
	var tm: ImmediateMesh = pend.get("trail_mesh")
	var mmi: MultiMeshInstance3D = pend.get("_marks")
	var evict: Array = []
	for target in [9.0, 14.0, 19.0]:
		while float(pend.call("experiment_time")) < target:
			await create_timer(0.5, true, false, true).timeout
			note("record at %.1f s: %d marks" % [float(pend.call("experiment_time")), int(pend.call("sample_count"))])
		var pts: Array = pend.get("trail_points")
		evict.append({"t": snappedf(float(pend.call("experiment_time")), 0.01), "count": pts.size(),
			"oldest_stamp": snappedf(float((pts.back() as Vector3).z), 0.01) if not pts.is_empty() else -1.0,
			"instance_count": mmi.multimesh.instance_count if mmi != null else -1,
			"visible_instances": mmi.multimesh.visible_instance_count if mmi != null else -1,
			# ImmediateMesh has no surface_get_array_len in 4.6; read the vertex array itself
			"trail_vertices": ((tm.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() if tm != null and tm.get_surface_count() > 0 else -1),
			"static_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.01)})
	measurements["eviction"] = evict
	note("eviction " + JSON.stringify(evict))
	check(evict.all(func(e): return int((e as Dictionary)["count"]) == 300), "past the cap the count holds at 300 at 9, 14 and 19 s (%s)" % str(evict.map(func(e): return e["count"])))
	check(float(evict[2]["oldest_stamp"]) - float(evict[0]["oldest_stamp"]) > 9.5, "while the oldest retained mark moves on by ten seconds: old marks are evicted (%.2f s -> %.2f s)" % [float(evict[0]["oldest_stamp"]), float(evict[2]["oldest_stamp"])])
	check(evict.all(func(e): return int((e as Dictionary)["instance_count"]) == 300 and int((e as Dictionary)["trail_vertices"]) == 300), "the marks' instances and the trail's vertices stay at 300: nothing accumulates in the drawing either")
	var growth_mb: float = float(evict[2]["static_mb"]) - float(evict[0]["static_mb"])
	measurements["static_memory_growth_mb"] = snappedf(growth_mb, 0.01)
	check(growth_mb < 4.0, "and the engine's static memory does not climb with the record (%+.2f MB over ten seconds)" % growth_mb)

	# ── 5d. A STEP LONGER THAN THE INTERVAL ──────────────────────────────────────
	# The sampler can only fire on a physics step. At 30 ticks a step is 33.3 ms, longer
	# than FINE's 25 ms: the request cannot be met, and the record says so in its gaps.
	# The carried clock must stay under one interval; the shipped code let it grow by
	# 8.3 ms every step.
	var ticks_saved: int = Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second = 30
	pend.call("reset_experiment")
	var clock_max := 0.0
	while float(pend.call("experiment_time")) < 2.0:
		await physics_frame
		clock_max = maxf(clock_max, float(pend.call("sample_clock")))
	var g30: Vector2 = pend.call("recorded_interval_range")
	Engine.physics_ticks_per_second = ticks_saved
	measurements["slow_step"] = {"ticks": 30, "gap_ms": [snappedf(g30.x * 1000.0, 0.1), snappedf(g30.y * 1000.0, 0.1)],
		"clock_max_ms": snappedf(clock_max * 1000.0, 0.1), "count_2s": int(pend.call("sample_count"))}
	note("slow step " + JSON.stringify(measurements["slow_step"]))
	check(absf(g30.x - 1.0 / 30.0) < 0.001 and absf(g30.y - 1.0 / 30.0) < 0.001, "at 30 ticks every gap is one 33.3 ms step: the 25 ms request is not met, and the record shows it (%s ms)" % str(measurements["slow_step"]["gap_ms"]))
	check(clock_max < float(pend.get("fine_interval")), "and the sampler's carried clock stays under one interval (max %.1f ms, bound 25 ms)" % (clock_max * 1000.0))
	pend.call("reset_experiment")

	# ── 6. the walkways beside the record ─────────────────────────────────────
	var space := seg.get_world_3d().direct_space_state
	var cap := CapsuleShape3D.new(); cap.radius = 0.22; cap.height = 1.6
	var wq := PhysicsShapeQueryParameters3D.new(); wq.shape = cap
	for route in [["east walkway", Vector3(9.5, 0.81, 10.5), Vector3(0, 0, 9.0)],
			["west walkway", Vector3(3.5, 0.81, 10.5), Vector3(0, 0, 9.0)],
			["to the south door", Vector3(9.5, 0.81, 19.5), Vector3(-3.0, 0, 0)]]:
		wq.transform = Transform3D(Basis.IDENTITY, seg.to_global(Vector3(route[1].x, route[1].y, route[1].z + vest)))
		wq.motion = route[2]
		var frac: float = space.cast_motion(wq)[0]
		measurements["walk_" + str(route[0]).replace(" ", "_")] = frac
		check(frac > 0.99, "a body walks the %s (%.2f of the way)" % [route[0], frac])
	measurements["scale"] = [pend.scale.x, pend.scale.y, pend.scale.z]
	check(pend.scale.is_equal_approx(Vector3.ONE), "the subject's scale is what the map asked (1)")

	# ── ACTUAL DESKTOP INPUT (live harness only: the desktop rig names autoloads) ──
	# The project's desktop rig stands on the east walkway north of the panel post,
	# looks at COARSE and left-clicks through the input pipeline; then walks the
	# walkway on ui_up. Nothing here emits an artifact signal.
	if _live():
		var drv: Node = load("res://commons/testing/wcn_desktop_driver.gd").new()
		root.add_child(drv)   # a SceneTree has no add_child; the port maps root. to get_tree().root.
		# EVERY BUTTON, THROUGH THE POINTER. The pilot pressed COARSE and emitted the
		# other three. Each press is counted at the button's own signal, the hover must
		# name the button (every push button shares the InteractableAreaButton class),
		# and the sampler is read back after each.
		var stand: Vector3 = seg.to_global(Vector3(8.3, 0.0, 10.3 + vest))
		drv.call("spawn", stand, em)
		await create_timer(0.5).timeout
		var facing_p: Vector3 = (panel.global_transform.basis * Vector3(0.0, 0.0, 1.0)).normalized() if panel != null else Vector3.RIGHT
		var presses: Array = []
		for spec in [["Btn_1", "COARSE", "coarse"], ["Btn_2", "STROBE", "strobe"], ["Btn_0", "FINE", "fine"], ["Btn_3", "RESET", ""]]:
			var btn: Node = panel.find_child(str(spec[0]), true, false) if panel != null else null
			if btn == null:
				check(false, "%s exists on the panel" % str(spec[1]))
				continue
			var area_b: Node = btn.find_child("InteractableAreaButton", true, false)
			var tally := {"n": 0}
			if area_b != null and area_b.has_signal("button_pressed"):
				area_b.connect("button_pressed", func(_b): tally["n"] = int(tally["n"]) + 1)
			var t_exp_before: float = float(pend.call("experiment_time"))
			var rec: Dictionary = await drv.call("press", btn, stand)
			await physics_frame
			var how := "the walkway stand"
			if int(tally["n"]) == 0:
				# a 2 x 2 rack: from one stand the lower row can sit under the crosshair's
				# reach. Stand in front of THIS button along the panel's facing and try once.
				var own: Vector3 = (btn as Node3D).global_position + facing_p * 0.55
				own.y = seg.to_global(Vector3.ZERO).y
				rec = await drv.call("press", btn, own)
				await physics_frame
				how = "a stand in front of the button"
			var row := {"button": str(spec[1]), "hover": str(rec.get("hover", "")).right(40), "emissions": int(tally["n"]), "from": how,
				"sampler_after": str(pend.get("sampler")), "count_after": int(pend.call("sample_count")),
				"interval_after": snappedf(float(pend.call("current_interval")), 0.001), "experiment_time_after": snappedf(float(pend.call("experiment_time")), 0.001)}
			presses.append(row)
			note("press " + JSON.stringify(row))
			check(str(rec.get("hover", "")).contains(str(spec[0])), "%s: the crosshair was on %s itself (%s)" % [str(spec[1]), str(spec[0]), row["hover"]])
			check(int(tally["n"]) == 1, "%s took exactly one press from one click (%d, from %s)" % [str(spec[1]), int(tally["n"]), how])
			if str(spec[2]) != "":
				check(str(pend.get("sampler")) == str(spec[2]) and int(pend.call("sample_count")) <= 1,
					"%s switched the sampler and started the record again (%s, %d marks)" % [str(spec[1]), str(pend.get("sampler")), int(pend.call("sample_count"))])
			else:
				check(float(pend.call("experiment_time")) < 0.1 and t_exp_before > 0.5 and str(pend.get("sampler")) == "fine",
					"RESET returned the experiment clock to zero and kept the chosen sampler (%.2f s, %s)" % [float(pend.call("experiment_time")), str(pend.get("sampler"))])
		measurements["desktop_input"] = {"presses": presses}
		drv.get("rig").global_position = seg.to_global(Vector3(9.5, 0.05, 10.5 + vest))
		await physics_frame
		drv.call("aim_at", seg.to_global(Vector3(9.5, 1.2, 19.0 + vest)))
		var moved: Vector3 = await drv.call("walk", "ui_up", 60)
		var moved_local: Vector3 = seg.global_transform.basis.inverse() * moved
		measurements["desktop_input"]["walk_east_walkway_1s"] = [snappedf(moved_local.x, 0.01), snappedf(moved_local.z, 0.01)]
		check(moved_local.z > 3.5, "the rig walked the east walkway south on ui_up (%.2f m in one second)" % moved_local.z)
		if "--capture" in OS.get_cmdline_user_args():
			print("[wcn-pendulum] capture: the rig's walk view, camera ", str(root.get_camera_3d().get_path()).right(40) if root.get_camera_3d() != null else "none")
			for i in range(10): await process_frame
			await create_timer(0.3, true, false, true).timeout
			root.get_texture().get_image().save_png(OUT + "probe_pendulum_desktop_walk.png")
			print("[wcn-pendulum] capture: saved")
			measurements["desktop_input"]["walk_capture_pose"] = drv.call("pose")
		# what stands between the rig and the south door on this walkway (meshes whose
		# world box crosses x 8.5..10.5, rows 15..20 of the map): the walk capture shows a block
		var on_walkway: Array = []
		var box := AABB(seg.to_global(Vector3(8.5, -0.1, 15.0 + vest)), Vector3(2.0, 3.0, 5.5))
		for mi in seg.find_children("*", "MeshInstance3D", true, false):
			var m3: MeshInstance3D = mi
			if m3.mesh == null: continue
			var wb: AABB = m3.global_transform * m3.get_aabb()
			if wb.intersects(box):
				on_walkway.append([str(m3.get_path()).right(70), [snappedf(wb.position.x, 0.01), snappedf(wb.position.y, 0.01), snappedf(wb.position.z, 0.01)], [snappedf(wb.size.x, 0.01), snappedf(wb.size.y, 0.01), snappedf(wb.size.z, 0.01)]])
		measurements["desktop_input"]["south_walkway_meshes"] = on_walkway
		await drv.call("teardown")
		measurements["desktop_input"]["log"] = drv.get("log")
		measurements["desktop_input"]["walker_cam_guard_stopped"] = drv.get("walker_cam_guard_stopped")
		await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		pend.call("set_sampler", "fine")
		await create_timer(8.0).timeout
		var cam := Camera3D.new(); em.add_child(cam); cam.fov = 62
		# a real standing view from the east wall (12 September; the old spot at (9.8, 9.6)
		# stood inside the lab table's footprint and photographed its back): the bob and the
		# frame ahead, the record running away to the left, the panel on the near post — a
		# wider lens than the other captures, because the panel is close and to the side
		cam.fov = 80
		# (13 September) south of the GlassRack at (10,12): from z 12.2 the camera looked
		# straight through the rack's black frame, which filled the foreground of the frame
		cam.global_position = seg.to_global(Vector3(11.5, 1.7, 13.7 + vest)); cam.look_at(seg.to_global(Vector3(6.5, 1.2, 12.0 + vest)))
		for i in range(30): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_pendulum.png")
		measurements["captures"] = {"primary": _cam_pose(cam)}
		# the cased readout from a visitor's standing distance on the east walkway
		if readout != null:
			var plate: Vector3 = readout.global_position
			cam.global_position = plate + seg.global_transform.basis * Vector3(0.15, 0.12, -1.35)
			cam.look_at(plate)
			for i in range(20): cam.make_current(); await process_frame
			await create_timer(0.3, true, false, true).timeout
			root.get_texture().get_image().save_png(OUT + "probe_pendulum_readout.png")
			measurements["captures"]["readout"] = _cam_pose(cam)
			measurements["captures"]["readout_plate_world"] = [snappedf(plate.x, 0.01), snappedf(plate.y, 0.01), snappedf(plate.z, 0.01)]
		# the controls from the walkway, a step from the post, with the bob and the near
		# record behind them
		if panel != null:
			cam.fov = 62
			cam.global_position = seg.to_global(Vector3(9.9, 1.55, 12.3 + vest)); cam.look_at((panel as Node3D).global_position + seg.global_transform.basis * Vector3(-0.6, 0.15, 0.3))
			for i in range(20): cam.make_current(); await process_frame
			await create_timer(0.3, true, false, true).timeout
			root.get_texture().get_image().save_png(OUT + "probe_pendulum_controls.png")
			measurements["captures"]["controls"] = _cam_pose(cam)
	# the museum's own verdict on this body: not a severing seal
	var severed: Array = em.get("_seg_severed") if em.get("_seg_severed") != null else []
	var sev_tokens: Array = []
	for s in severed: sev_tokens.append(str((s as Dictionary).get("token", "")))
	measurements["museum_severed_tokens"] = sev_tokens
	measurements["museum_severed"] = severed          # token + the cells each seal, map coords (x, z-from-segment-base)
	check(not sev_tokens.has("PendulumWave"), "the museum did not report the installation as severing the hall")
	check(sev_tokens.is_empty(), "no body in this hall severs the museum's route (severed: %s)" % str(sev_tokens))
	# the museum's own record of this hall as built: walk grid, seals, severance, bodies
	var rows: Array = em.get("_built") if em.get("_built") != null else []
	var mine: Dictionary = {}
	for r in rows:
		if str((r as Dictionary).get("map", "")) == MAP: mine = r
	if mine.is_empty() and not rows.is_empty(): mine = rows[rows.size() - 1]
	if not mine.is_empty():
		measurements["built_cells"] = mine.get("cells", [])
		measurements["built_seals"] = mine.get("seals", [])
		measurements["built_severed"] = mine.get("severed", [])
		measurements["built_refused"] = mine.get("refused", [])
		var toks: Array = []
		for b in mine.get("bodies", []):
			toks.append([str((b as Dictionary).get("token", "")), (b as Dictionary).get("world", []), (b as Dictionary).get("tile_cell", [])])
		measurements["built_bodies"] = toks
	# ── MUSEUM STREAMING: free this hall through the museum's own streamer, rebuild it ──
	# (last: the segment reference dies here). The bare-root reload probe showed the
	# artifact scenes clean up after themselves; this is the museum doing it.
	var seg_i: int = -1
	var segs: Array = em.get("_segments")
	for i in range(segs.size()):
		if (segs[i] as Dictionary).get("node") == seg: seg_i = i
	if seg_i >= 0:
		var z0_key: float = float((segs[seg_i] as Dictionary).get("z0", -1.0))
		var old_pend: Node = pend
		em.call("_stream_free", seg_i, "south")
		for i in range(5): await process_frame
		check(not is_instance_valid(old_pend), "the museum's streamer freed the hall and the pendulum with it")
		var rec_f: Dictionary = {}
		for r in (em.get("_freed") as Array):
			if absf(float((r as Dictionary).get("z0", -2.0)) - z0_key) < 0.5: rec_f = r
		var can_rebuild: bool = not rec_f.is_empty() and not ((rec_f.get("snap", {})) as Dictionary).is_empty()
		measurements["streaming"] = {"freed": not rec_f.is_empty(), "rebuildable": can_rebuild}
		if can_rebuild:
			em.call("_stream_rebuild", rec_f)
			em.call("flush_stamps")
			for i in range(30): await process_frame
			var seg2: Node3D = null
			for rec2: Dictionary in em.get("_segments"):
				if rec2.node.get_meta("em_map", "") == MAP: seg2 = rec2.node
			var pend2: Node3D = null
			if seg2 != null:
				for n in seg2.find_children("*", "Node3D", true, false):
					if n.get_script() != null and str(n.get_script().resource_path).ends_with("PendulumWave.gd"): pend2 = n; break
			check(pend2 != null, "the hall rebuilt through the streamer and stands a fresh pendulum")
			if pend2 != null:
				await create_timer(1.0).timeout
				check(int(pend2.call("sample_count")) > 20 and pend2.get_node_or_null("Panel") != null and pend2.get_node_or_null("ReadoutCase/Readout") != null, "the rebuilt pendulum records again, with its panel and readout (%d marks)" % int(pend2.call("sample_count")))
				measurements["streaming"]["rebuilt_marks"] = int(pend2.call("sample_count"))
		else:
			measurements["streaming"]["note"] = "no cursor snapshot for the start hall (pre-window hall): the museum's streamer frees it but cannot rebuild it by design"
	_finish()

func note(message: String) -> void:
	print("[wcn-pendulum] note: ", message)

func _press(panel: Node, btn_name: String) -> bool:
	if panel == null: return false
	var btn: Node = panel.find_child(btn_name, true, false)
	var area: Node = btn.get_node_or_null("InteractableAreaButton") if btn != null else null
	if area == null or not area.has_signal("button_pressed"): return false
	area.emit_signal("button_pressed", area)
	return true

## Count marks between two successive crossings of x=0 in the same direction.
func _marks_per_period(marks: PackedVector3Array, pend: Node3D) -> int:
	var xs: Array[float] = []
	# Cross the pendulum's own x=0, wherever the installation stands in the hall.
	for m in marks: xs.append(pend.to_local(m).x)
	var first := -1
	for i in range(1, xs.size()):
		if xs[i - 1] < 0.0 and xs[i] >= 0.0:
			if first < 0: first = i
			else: return i - first
	return -1

func _solid_hits(seg: Node3D, q: PhysicsShapeQueryParameters3D) -> int:
	var n := 0
	for h in seg.get_world_3d().direct_space_state.intersect_shape(q, 8):
		if h.collider == seg.get_node_or_null("Collision"): n += 1
	return n

func _finish() -> void:
	var report := {"map": MAP, "checks": checks, "failures": failures, "measurements": measurements,
		# SAY WHICH LANE RAN: _live() is a filename test, so the pointer block can be skipped in silence.
		"lanes": {"model_lane": "button_pressed emitted on the panel's push buttons", "pointer_lane_expected": _live(),
			"pointer_lane_ran": (measurements.get("desktop_input", {}) as Dictionary).has("presses")},
		"control_path": ("all four sampler buttons pressed through the desktop pointer, the sampler read back after each; the model lane emits the same buttons' signals"
			if (measurements.get("desktop_input", {}) as Dictionary).has("presses")
			else "model lane in this run: button_pressed emitted on the panel's push buttons, no pointer; the live lane presses all four through the desktop pointer"),
		"hand_file": "ada_run/necklace_hand.json (real)", "headset_verified": false,
		"engine": Engine.get_version_info().string, "physics_fps": Engine.physics_ticks_per_second}
	var f := FileAccess.open(OUT + "probe_pendulum.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  ")); f.close()
	print("[wcn-pendulum] ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)

## Which camera the viewport draws from at a capture, and where it stands and looks.
func _cam_pose(cam: Camera3D) -> Dictionary:
	var cur: Camera3D = root.get_camera_3d()
	var fwd: Vector3 = -cam.global_transform.basis.z
	return {"current_camera": str(cur.get_path()).right(50) if cur != null else "none", "is_ours": cur == cam,
		"at": [snappedf(cam.global_position.x, 0.01), snappedf(cam.global_position.y, 0.01), snappedf(cam.global_position.z, 0.01)],
		"forward": [snappedf(fwd.x, 0.01), snappedf(fwd.y, 0.01), snappedf(fwd.z, 0.01)]}
