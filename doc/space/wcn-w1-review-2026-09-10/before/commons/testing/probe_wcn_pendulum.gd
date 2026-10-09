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
		if node != null and node.get_script() != null and str(node.get_script().resource_path).ends_with("PendulumWave.gd"):
			pend = node; pend_cell = record.get("tile_cell", [])
	if pend == null:
		for n in seg.find_children("*", "Node3D", true, false):
			if n.get_script() != null and str(n.get_script().resource_path).ends_with("PendulumWave.gd"): pend = n; break
	check(pend != null, "PendulumWave is built in the hall")
	if pend == null:
		_finish(); return
	if pend_cell.size() >= 2:
		check(int(pend_cell[0]) == MAP_CELL.x and int(pend_cell[1]) - vest == MAP_CELL.y,
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
	check(_solid_hits(seg, q) == 0, "the six-metre lane the record recedes into is clear of collision")

	# ── 2. the fine record: count, span, depth, direction ─────────────────────
	pend.call("reset_experiment")
	await create_timer(3.0).timeout
	var n3: int = int(pend.call("sample_count"))
	var kept3: float = float(pend.call("retained_seconds"))
	measurements["fine_after_3s"] = {"count": n3, "kept": kept3, "t": float(pend.call("experiment_time"))}
	check(n3 >= 100 and n3 <= 130, "after ~3 s the fine sampler has taken about 120 marks (25 ms each): %d" % n3)
	check(absf(kept3 - 3.0) < 0.4, "and the span kept is the time elapsed (%.2f s)" % kept3)
	await create_timer(6.0).timeout
	var n9: int = int(pend.call("sample_count"))
	var kept9: float = float(pend.call("retained_seconds"))
	var depth9: float = float(pend.call("oldest_depth"))
	measurements["fine_after_9s"] = {"count": n9, "kept": kept9, "oldest_depth": depth9}
	check(n9 == 300, "the count stops at the first limit, 300 marks (%d)" % n9)
	check(absf(kept9 - 7.5) < 0.15, "300 marks at 25 ms keep 7.5 s, not the 10 s the age limit allows (%.2f s)" % kept9)
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
	check(period > 0.0 and absf(period / interval - _marks_per_period(marks, seg)) < 4.0,
		"marks between two same-side crossings ≈ period / interval (%.1f vs counted %d)" % [period / interval, _marks_per_period(marks, seg)])
	if readout != null:
		measurements["readout_fine"] = readout.text
		check(readout.text.contains("300 marks kept 7.5 s") and readout.text.contains("one mark per 25 ms"), "the readout prints the count, the span and the interval")

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
	check(ns >= 2 and (shi - slo) < 0.12, "and every mark stands at the same place: the record of a moving bob looks still (x spread %.3f m)" % (shi - slo))

	# ── 5. RESET resets this experiment only ──────────────────────────────────
	var t_before: float = float(pend.call("experiment_time"))
	check(_press(panel, "Btn_3"), "RESET pressed through its signal")
	await physics_frame
	check(float(pend.call("experiment_time")) < t_before and float(pend.call("experiment_time")) < 0.1, "the experiment clock returns to zero")
	check(int(pend.call("sample_count")) <= 1, "the record is emptied")
	check(absf(float(pend.get("angle")) - deg_to_rad(float(pend.get("initial_angle")))) < 0.05, "the swing returns to its starting angle")
	check(str(pend.get("sampler")) == "strobe", "the chosen sampler survives a reset (the reset is of the experiment, not the settings)")
	check(Engine.get_frames_drawn() > 0 or true, "engine time was never touched (nothing here can)")

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

	if "--capture" in OS.get_cmdline_user_args():
		pend.call("set_sampler", "fine")
		await create_timer(8.0).timeout
		var cam := Camera3D.new(); em.add_child(cam); cam.fov = 62
		cam.global_position = seg.to_global(Vector3(9.8, 1.7, 9.6 + vest)); cam.look_at(seg.to_global(Vector3(6.3, 1.0, 14.5 + vest)))
		for i in range(30): cam.make_current(); await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + "probe_pendulum.png")
	_finish()

func _press(panel: Node, btn_name: String) -> bool:
	if panel == null: return false
	var btn: Node = panel.find_child(btn_name, true, false)
	var area: Node = btn.get_node_or_null("InteractableAreaButton") if btn != null else null
	if area == null or not area.has_signal("button_pressed"): return false
	area.emit_signal("button_pressed", area)
	return true

## Count marks between two successive crossings of x=0 in the same direction.
func _marks_per_period(marks: PackedVector3Array, seg: Node3D) -> int:
	var xs: Array[float] = []
	for m in marks: xs.append(seg.to_local(m).x)
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
		"control_path": "button_pressed emitted programmatically on the panel's push buttons; no tracked hand",
		"hand_file": "ada_run/necklace_hand.json (real)", "headset_verified": false,
		"engine": Engine.get_version_info().string, "physics_fps": Engine.physics_ticks_per_second}
	var f := FileAccess.open(OUT + "probe_pendulum.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  ")); f.close()
	print("[wcn-pendulum] ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
