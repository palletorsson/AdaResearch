extends SceneTree
## PARAMETRIC PENDULUM WAVES — do fifteen lengths make fifteen rates, and do the rates come home?
##
## Written 2026-09-16 with the repair. The rig shipped with every length clamped to 0.8 m
## (fifteen copies of one pendulum), a swing along the row, and damping applied once per
## FRAME. Each section below asserts the claim the repair makes, against the real .tscn, and
## reads the answer back off the built rig — the dictionaries the motion runs on and the
## meshes a visitor sees — rather than off a copy of the formula.
##
##   1  lengths strictly distinct, strictly decreasing, inside the window (and a CONTROL
##      showing the old clamp collapses them, so the check can bite)
##   2  the periods the lengths realise give consecutive integer swing counts over the cycle
##   3  stepped at a fixed dt for one cycle, every pendulum is back on its starting phase —
##      and at half a cycle neighbours are in ANTIPHASE, so it really went somewhere
##   4  damping at dt = 1/30 and dt = 1/120 agrees (and a CONTROL: the old per-frame form
##      would not)
##   5  with relaunch on the swing is lowest at mid-cycle and ARRIVES at unison at full
##      height, so nothing jumps there (and a CONTROL prints the old lift)
##   6  the _process lane drives the rig at wall-clock rate
##   7  the caption is a TextScreen whose text stands in front of its frame, laid out as
##      written, clear of the swing, stating the real cycle
##   8  RELEASE: the rig (not only the PushButton) is connected, with an unwired CONTROL; the
##      desktop pointer's own ray, mask and resolution land on the area from two standpoints;
##      a press through XRToolsPointerEvent emits once and restarts the rig
##   9  a fixed cycle_time (60 s) still gives consecutive counts and a unison at 60 s
##  10  apply_grid_config before _ready builds once
##  11  the gantry's hoist clears the pivot bar and every rod
##
## WHAT IT CANNOT PROVE: section 8's ray stands where a visitor would, but no DesktopPlayer
## walks there, so a museum pushing the rig out of a collider after its aim is not modelled;
## and no VR fingertip pokes the area. Both remain live-rig checks.
##
##   godot --headless --xr-mode off --path . \
##     --script res://commons/testing/probe_parametric_pendulum_waves.gd

const SCENE := "res://algorithms/wavefunctions/parametric_pendulum_waves/parametric_pendulum_waves.tscn"

var _fails := 0
var _emits := 0

## DesktopInteractionPointer's own ray mask: layers 19 (handles) + 21 (area buttons).
const POINTER_MASK := 1310720
## desktop_player.tscn: Head at y 1.6, the camera at the head pivot.
const DESKTOP_EYE_Y := 1.6


func _ok(label: String, cond: bool, detail: String = "") -> void:
	print("   %s %s%s" % ["ok  " if cond else "FAIL", label, ("  " + detail) if detail != "" else ""])
	if not cond:
		_fails += 1


func _initialize() -> void:
	call_deferred("_run")


func _spawn(cycle: float = -1.0, config: Dictionary = {}) -> Node3D:
	var packed := load(SCENE) as PackedScene
	if packed == null:
		return null
	var a := packed.instantiate() as Node3D
	if cycle >= 0.0:
		a.set("cycle_time", cycle)
	if not config.is_empty():
		a.call("apply_grid_config", config)       # BEFORE the tree, as the museum may
	get_root().add_child(a)
	return a


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame


## A pendulum's amplitude from its state: sqrt(θ² + (θ'/ω)²), exact for the model it runs.
func _amplitude(pd: Dictionary) -> float:
	var th: float = float(pd["angle"])
	var vw: float = float(pd["angular_velocity"]) / float(pd["omega"])
	return sqrt(th * th + vw * vw)


## Resolve a ray's collider the way DesktopInteractionPointer does: the nearest ancestor with
## pointer_event().
func _pointer_target(collider: Object) -> Node:
	var cur: Node = collider as Node
	while cur != null:
		if cur.has_method("pointer_event") or cur.has_signal("pointer_event"):
			return cur
		cur = cur.get_parent()
	return null


## button_pressed connections held by anything OTHER than the PushButton that owns the area.
## push_button.gd connects its own _on_button_pressed, so a bare size() > 0 cannot fail.
func _foreign_presses(area: Area3D, owner_btn: Node) -> Array:
	var out: Array = []
	for conn in area.get_signal_connection_list("button_pressed"):
		var cb: Callable = conn["callable"]
		var holder: Object = cb.get_object()
		if holder != owner_btn:
			var who: String = holder.get_class() if holder != null else "<null>"
			out.append("%s.%s" % [who, str(cb.get_method())])
	return out


func _count_emit(_button) -> void:
	_emits += 1


## Step the rig by exactly `seconds` in fixed dt steps, plus one remainder step.
func _step_for(a: Node3D, seconds: float, dt: float) -> void:
	var steps: int = int(floor(seconds / dt))
	for s in range(steps):
		a.call("step", dt)
	var rest: float = seconds - float(steps) * dt
	if rest > 0.0:
		a.call("step", rest)


func _run() -> void:
	print("PARAMETRIC PENDULUM WAVES — distinct lengths, consecutive swings, a return to unison")
	print("")

	var a := _spawn()
	if a == null:
		print("   FAIL the scene did not load")
		print("PROBE FAILED")
		quit(1)
		return
	await _frames(4)
	a.set_process(false)      # from here the probe owns the clock

	var pends: Array = a.get("pendulums")
	var lengths: PackedFloat64Array = a.call("get_lengths")
	var swings: PackedInt32Array = a.call("get_swing_counts")
	var T: float = float(a.call("get_cycle_time"))
	var n: int = int(a.get("num_pendulums"))
	var lo: float = float(a.get("shortest_length"))
	var hi: float = float(a.get("longest_length"))
	var g: float = float(a.get("gravity"))
	var rel: float = float(a.get("release_angle"))
	var damping: float = float(a.get("damping"))
	print("   built: %d pendulums, swings %s, cycle %.3f s" % [lengths.size(), str(swings), T])
	if lengths.size() < 2 or swings.size() != lengths.size():
		print("   FAIL the rig built fewer than two pendulums — nothing below can be tested")
		print("FAIL probe_parametric_pendulum_waves")
		quit(1)
		return

	# ── 1. lengths ────────────────────────────────────────────────────────
	print("1  the lengths")
	_ok("one length per pendulum", lengths.size() == n and pends.size() == n, "%d of %d" % [lengths.size(), n])
	var decreasing := true
	var min_gap := 1e9
	for i in range(1, lengths.size()):
		min_gap = minf(min_gap, lengths[i - 1] - lengths[i])
		if not (lengths[i] < lengths[i - 1] - 1e-4):
			decreasing = false
	_ok("strictly distinct and strictly decreasing", decreasing and lengths.size() > 1,
		"smallest step %.4f m" % min_gap)
	var inside := true
	for L in lengths:
		if L < lo - 1e-9 or L > hi + 1e-9:
			inside = false
	_ok("every length inside the window, none clamped", inside and lengths.size() > 0,
		"%.4f .. %.4f m in [%.3f, %.3f]" % [lengths[lengths.size() - 1], lengths[0], lo, hi])
	_ok("the longest hangs exactly longest_length", absf(lengths[0] - hi) < 1e-9, "%.9f m" % lengths[0])
	# CONTROL — the shipped formula, re-run here only to show this section can fail:
	# 51..65 swings in 60 s, clamped to the window, collapses to one value.
	var legacy := {}
	for i in range(n):
		var p_old: float = 60.0 / float(51 + i)
		legacy[snappedf(clampf(g * pow(p_old / TAU, 2.0), lo, hi), 1e-4)] = true
	print("   control: the old clamp gives %d distinct length(s) for %d pendulums" % [legacy.size(), n])

	# ── 2. periods → consecutive integer swings ──────────────────────────
	print("2  the periods the lengths realise")
	var integral := true
	var consecutive := true
	var realised := true
	for i in range(pends.size()):
		var pd: Dictionary = pends[i]
		var L_i: float = float(pd["length"])
		var period_from_length: float = TAU * sqrt(L_i / g)
		if absf(period_from_length - float(pd["period"])) > 1e-9:
			realised = false
		var count: float = T / period_from_length
		if absf(count - round(count)) > 1e-6:
			integral = false
		if int(round(count)) != int(swings[0]) + i or int(swings[i]) != int(swings[0]) + i:
			consecutive = false
	_ok("T = 2π√(L/g) of each length is the period it swings at", realised)
	_ok("each pendulum makes a WHOLE number of swings per cycle", integral)
	_ok("the counts are consecutive integers", consecutive,
		"%d .. %d" % [int(swings[0]), int(swings[swings.size() - 1])])

	# readback off the meshes: each bob hangs its own length, across the bar
	a.call("release")
	a.call("sync_visuals")
	var bobs_ok := true
	var across := true
	for i in range(n):
		var bob := a.get_node_or_null("Pendulum_%d/Bob" % i) as Node3D
		if bob == null:
			bobs_ok = false
			continue
		if absf(bob.position.length() - lengths[i]) > 1e-4:
			bobs_ok = false
		if absf(bob.position.x) > 1e-6 or bob.position.z <= 0.0:
			across = false
	_ok("READBACK: every Bob mesh sits its own length from its pivot", bobs_ok)
	_ok("READBACK: released bobs are displaced across the bar (Z), not along it (X)", across)

	# ── 3. one cycle at a fixed dt ────────────────────────────────────────
	print("3  one cycle, stepped at dt = 1/60")
	a.set("relaunch_each_cycle", false)
	var k: float = float(a.call("get_decay_rate"))
	_ok("the decay rate is -ln(damping) per second", absf(k + log(damping)) < 1e-12, "k = %.6f /s" % k)

	a.call("release")
	_step_for(a, T * 0.5, 1.0 / 60.0)
	var env_half: float = rel * exp(-k * T * 0.5)
	var antiphase := true
	var signs := {}
	var worst_half := 0.0
	for i in range(n):
		var pd: Dictionary = a.get("pendulums")[i]
		var want: float = 1.0 if (int(swings[i]) % 2) == 0 else -1.0
		var got: float = float(pd["angle"]) / env_half
		worst_half = maxf(worst_half, absf(got - want))
		signs[want] = true
		if absf(got - want) > 1e-6:
			antiphase = false
	_ok("at T/2 neighbours are in antiphase — two interleaved rows", antiphase and signs.size() == 2,
		"worst |θ/A - (±1)| = %.9f" % worst_half)

	a.call("release")
	_step_for(a, T, 1.0 / 60.0)
	_ok("the clock reads one cycle", absf(float(a.get("time_since_release")) - T) < 1e-6,
		"%.9f s" % float(a.get("time_since_release")))
	var env_T: float = rel * exp(-k * T)
	var home := true
	var worst_phase := 0.0
	for i in range(n):
		var pd: Dictionary = a.get("pendulums")[i]
		var w: float = float(pd["omega"])
		var th: float = float(pd["angle"])
		var v: float = float(pd["angular_velocity"])
		var phase: float = absf(atan2(-v / w, th))
		worst_phase = maxf(worst_phase, phase)
		if phase > 1e-4 or absf(th / env_T - 1.0) > 1e-4:
			home = false
	_ok("after T every pendulum is back on its starting phase (UNISON)", home,
		"worst phase error %.9f rad" % worst_phase)

	# ── 4. damping at two frame rates ─────────────────────────────────────
	print("4  damping at dt = 1/30 and dt = 1/120")
	a.call("release")
	_step_for(a, 10.0, 1.0 / 30.0)
	var s30: Array = []
	for pd in a.get("pendulums"):
		s30.append(Vector2(float(pd["angle"]), float(pd["angular_velocity"])))
	a.call("release")
	_step_for(a, 10.0, 1.0 / 120.0)
	var worst_rate := 0.0
	var env_ok := true
	var env10: float = rel * pow(damping, 10.0)
	var i4 := 0
	for pd in a.get("pendulums"):
		var st := Vector2(float(pd["angle"]), float(pd["angular_velocity"]))
		var prev: Vector2 = s30[i4]
		var diff: Vector2 = (st - prev).abs()
		worst_rate = maxf(worst_rate, maxf(diff.x, diff.y))
		var w4: float = float(pd["omega"])
		var amp: float = sqrt(st.x * st.x + (st.y / w4) * (st.y / w4))
		if absf(amp - env10) > 1e-6:
			env_ok = false
		i4 += 1
	_ok("the state after 10 s agrees at 30 and 120 steps a second", worst_rate < 1e-6,
		"worst difference %.9f" % worst_rate)
	_ok("the swing kept damping^10 of its amplitude", env_ok and env10 < rel,
		"%.6f rad of %.3f" % [env10, rel])
	print("   control: the old per-frame form keeps %.4f at 30 fps and %.4f at 120 fps"
		% [pow(damping, 300.0), pow(damping, 1200.0)])

	# ── 5. relaunch at unison ─────────────────────────────────────────────
	print("5  relaunch at the return to unison")
	a.set("relaunch_each_cycle", true)
	a.call("release")
	# 5a  the height lost on the way out is lowest at mid-cycle ...
	_step_for(a, T * 0.5, 1.0 / 60.0)
	var mid_ok := true
	var env_mid: float = rel * exp(-k * T * 0.5)
	for pd in a.get("pendulums"):
		if absf(_amplitude(pd) - env_mid) > 1e-6:
			mid_ok = false
	_ok("with relaunch on, the swing is lowest at mid-cycle: exp(-k T/2) of its height", mid_ok,
		"%.6f rad of %.3f" % [env_mid, rel])
	# 5b  ... and given back on the way home, so the bobs ARRIVE at unison at full height.
	_step_for(a, T * 0.5 - 0.5, 1.0 / 60.0)
	var before: Array = []
	var arrive_ok := true
	var env_arrive: float = rel * exp(-k * 0.5)
	for pd in a.get("pendulums"):
		before.append(float(pd["angle"]))
		if absf(_amplitude(pd) - env_arrive) > 1e-6:
			arrive_ok = false
	_ok("half a second before unison the swing is back to exp(-0.5 k) of release_angle", arrive_ok,
		"want %.6f rad; the old decay-then-lift would read %.6f" % [env_arrive, rel * exp(-k * (T - 0.5))])
	# 5c  no jump: one second straddling the unison leaves every bob where it would be if the
	#     motion simply reversed through it (θ(T - 0.5) = θ(T + 0.5) for a whole-swing count).
	_step_for(a, 1.0, 1.0 / 60.0)
	var t_after: float = float(a.get("time_since_release"))
	var worst_jump := 0.0
	var idx5 := 0
	for pd in a.get("pendulums"):
		worst_jump = maxf(worst_jump, absf(float(pd["angle"]) - float(before[idx5])))
		idx5 += 1
	_ok("the clock wrapped at unison, half a second into the next cycle", absf(t_after - 0.5) < 1e-6, "%.9f s" % t_after)
	_ok("NO JUMP at unison: each bob leaves at the height it arrived", worst_jump < 1e-6,
		"worst |θ(T+0.5) - θ(T-0.5)| = %.9f rad" % worst_jump)
	print("   control: the old relaunch lifted every bob %.4f rad at unison (%.1f cm at the longest)"
		% [rel * (1.0 - exp(-k * T)), 100.0 * lengths[0] * (sin(rel) - sin(rel * exp(-k * T)))])
	# 5d  the next cycle, from a fresh release, is the first again
	a.call("release")
	_step_for(a, T + 5.0, 1.0 / 60.0)
	var t5: float = float(a.get("time_since_release"))
	_ok("the clock wrapped at unison", absf(t5 - 5.0) < 1e-6, "%.9f s into the next cycle" % t5)
	var relaunched := true
	for pd in a.get("pendulums"):
		var want5: float = rel * exp(-k * 5.0) * cos(float(pd["omega"]) * 5.0)
		if absf(float(pd["angle"]) - want5) > 1e-6:
			relaunched = false
	_ok("the second cycle is the first again, full height, same phase", relaunched)

	# ── 6. the _process lane ──────────────────────────────────────────────
	print("6  the frame loop drives it")
	# Sections 3-5 ran thousands of steps inside ONE frame, so the next frame's delta carries
	# all of that CPU time. Let that frame pass with the rig not processing, then start clean.
	await process_frame
	await process_frame
	a.call("release")
	a.set_process(true)
	var wall_start: int = Time.get_ticks_usec()
	await create_timer(0.6).timeout
	a.set_process(false)
	var wall6: float = float(Time.get_ticks_usec() - wall_start) / 1000000.0
	var t6: float = float(a.get("time_since_release"))
	_ok("_process advanced the clock by the time that passed", t6 > 0.4 and t6 < 1.5 and absf(t6 - wall6) < 0.25,
		"%.3f s on the rig's clock, %.3f s on the wall clock, 0.6 s timer" % [t6, wall6])

	# ── 7. the caption ────────────────────────────────────────────────────
	print("7  the caption")
	var cap := a.get_node_or_null("Caption") as Node3D
	_ok("a Caption node exists", cap != null)
	if cap != null:
		var body: String = str(cap.get("body"))
		var t_text: String = "%.1f s" % T
		_ok("it is a TextScreen in SCREEN mode", cap.has_method("set_text") and int(cap.get("mode")) == 0)
		_ok("the TextScreen built its face", cap.get_node_or_null("TextScreenRoot") != null)
		_ok("it states the REAL cycle", body.contains(t_text), "'%s'" % t_text)
		_ok("it states the real swing counts",
			body.contains("%d to %d" % [int(swings[0]), int(swings[swings.size() - 1])]))
		# FACING, from what a visitor would see: the baked text sits IN FRONT of the frame
		# plate on the +Z side. A caption turned to face -Z puts its text behind its own frame
		# in world z, and this reads it; the node's basis alone is identity by construction.
		var screen := cap.get_node_or_null("TextScreenRoot/Screen") as Node3D
		var frame_n: Node3D = null
		var text_n: Node3D = null
		if screen != null and screen.get_child_count() >= 3:
			frame_n = screen.get_child(0) as Node3D
			text_n = screen.get_child(screen.get_child_count() - 1) as Node3D
		var dz: float = (text_n.global_position.z - frame_n.global_position.z) if (frame_n != null and text_n != null) else -1.0
		_ok("its text stands in front of its frame on the +Z side (it reads from the front)", dz > 0.005,
			"text z - frame z = %.4f m, %d text line quad(s)" % [dz, text_n.get_child_count() if text_n != null else -1])
		# LAYOUT: every authored line fits TextScreen's columns, so nothing reflows and the
		# name of the work is not split across two lines.
		if cap.has_method("_lay_out"):
			var consts: Dictionary = cap.get_script().get_script_constant_map()
			var w_m: float = float(cap.get("width_m"))
			var h_m: float = w_m * float(consts.get("ASPECT", 0.62))
			var avail: float = (h_m - h_m * float(consts.get("TITLE_FRAC", 0.26))) * 0.9
			var laid: PackedStringArray = cap.call("_lay_out", body, w_m * 0.92, avail)
			var authored: PackedStringArray = body.split("\n", false)
			var same: bool = laid.size() == authored.size()
			for li in range(mini(laid.size(), authored.size())):
				if String(laid[li]) != String(authored[li]).strip_edges():
					same = false
			var piano_whole := false
			for ln in laid:
				if String(ln).contains("Piano Phase (1967)"):
					piano_whole = true
			_ok("the screen lays the body out as written, no line reflowed or cut", same,
				"%d authored, %d laid out" % [authored.size(), laid.size()])
			_ok("'Piano Phase (1967)' stays on one line", piano_whole)
		var reach: float = hi * sin(rel) + float(a.get("bob_radius"))
		_ok("it stands clear of the swing", cap.position.z > reach, "z %.2f > reach %.2f" % [cap.position.z, reach])
		print("   body: %s" % body.replace("\n", " / "))

	# ── 8. RELEASE ────────────────────────────────────────────────────────
	print("8  the RELEASE button")
	var panel := a.get_node_or_null("ReleasePanel") as Node3D
	_ok("a ReleasePanel exists", panel != null)
	if panel != null:
		_ok("it is a local instrument, not the rig's footprint", bool(panel.get_meta("em_local_instrument", false)))
		var btn := panel.find_child("Btn_0", true, false)
		var area: Area3D = null
		if btn != null:
			area = btn.get_node_or_null("InteractableAreaButton") as Area3D
		_ok("Btn_0 carries an InteractableAreaButton Area3D", area != null)
		if area != null:
			_ok("on the layer the desktop pointer's ray masks", (area.collision_layer & POINTER_MASK) != 0,
				"layer bits %d, pointer mask %d" % [area.collision_layer, POINTER_MASK])
			# 8a  WIRED: a connection held by something other than the PushButton itself. Read
			#     before the probe adds its own counter, which would be foreign too.
			var foreign: Array = _foreign_presses(area, btn)
			_ok("the rig connected button_pressed (beyond the PushButton's own)", foreign.size() >= 1,
				"total %d, foreign %s" % [area.get_signal_connection_list("button_pressed").size(), str(foreign)])
			# CONTROL: the same RackTemplates button with nobody wiring it has NO foreign
			# connection, or the check above could never have failed.
			var rack: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
			var bare: Node3D = null
			if rack != null:
				bare = rack.create_panel("", [[{"type": "button", "label": "X"}]])
			if bare != null:
				bare.position = Vector3(0, 0, 40)
				get_root().add_child(bare)
				await _frames(2)
				var bare_btn: Node = bare.find_child("Btn_0", true, false)
				var bare_area: Area3D = null
				if bare_btn != null:
					bare_area = bare_btn.get_node_or_null("InteractableAreaButton") as Area3D
				var bare_total: int = -1
				var bare_foreign: Array = ["<no area>"]
				if bare_area != null:
					bare_total = bare_area.get_signal_connection_list("button_pressed").size()
					bare_foreign = _foreign_presses(bare_area, bare_btn)
				_ok("control: an unwired RackTemplates button holds its PushButton's connection and no other",
					bare_total >= 1 and bare_foreign.is_empty(), "total %d, foreign %s" % [bare_total, str(bare_foreign)])
				bare.queue_free()
			else:
				_ok("control: RackTemplates builds an unwired panel", false)

			# 8b  REACH (desktop): cast the pointer's own ray, with its own mask, bodies and
			#     areas both, from where a visitor would stand, and resolve the hit the way the
			#     pointer does. Physics must have stepped for the area to be in the space.
			for pf in range(3):
				await physics_frame
			var space: PhysicsDirectSpaceState3D = a.get_world_3d().direct_space_state
			var aim: Vector3 = area.global_position
			var eyes: Array = [
				["straight on, 0.45 m in front", aim + Vector3(0, 0, 0.45)],
				["a standing desktop eye (%.1f m), 0.6 m in front" % DESKTOP_EYE_Y, Vector3(aim.x, DESKTOP_EYE_Y, aim.z + 0.6)],
			]
			for pair in eyes:
				var eye: Vector3 = pair[1]
				var q := PhysicsRayQueryParameters3D.create(eye, eye + (aim - eye).normalized() * 5.0, POINTER_MASK)
				q.collide_with_areas = true
				q.collide_with_bodies = true
				var hit: Dictionary = space.intersect_ray(q)
				var who: Node = _pointer_target(hit.get("collider", null))
				var who_s: String = str(who.get_path()) if who != null else ("nothing" if hit.is_empty() else "a collider with no pointer_event")
				_ok("REACH: the pointer ray from %s lands on RELEASE" % str(pair[0]), who == area, "hit %s" % who_s)

			# 8c  PRESS through the area's own input path (the one the desktop pointer calls once
			#     its ray lands): XRToolsPointerEvent -> pointer_event -> _on_button_entered ->
			#     button_pressed. Count the emissions, then read the rig back.
			area.connect("button_pressed", _count_emit)
			a.call("release")
			_step_for(a, 20.0, 1.0 / 60.0)
			var pointer := Node3D.new()
			get_root().add_child(pointer)
			XRToolsPointerEvent.pressed(pointer, area, area.global_position)
			XRToolsPointerEvent.released(pointer, area, area.global_position)
			await _frames(2)
			_ok("one press emitted button_pressed once", _emits == 1, "%d" % _emits)
			var restarted := absf(float(a.get("time_since_release"))) < 1e-12
			for pd in a.get("pendulums"):
				if absf(float(pd["angle"]) - rel) > 1e-12 or absf(float(pd["angular_velocity"])) > 1e-12:
					restarted = false
			_ok("READBACK: the press restarted every bob together at release_angle", restarted,
				"clock %.6f s" % float(a.get("time_since_release")))
			pointer.queue_free()

	a.queue_free()
	await _frames(2)

	# ── 9. a fixed cycle ──────────────────────────────────────────────────
	print("9  cycle_time = 60 s (the classic demonstration's cycle)")
	print("   (a push_warning about the window is EXPECTED here: the true lengths are kept)")
	var b := _spawn(60.0)
	await _frames(4)
	b.set_process(false)
	var Tb: float = float(b.call("get_cycle_time"))
	var sb: PackedInt32Array = b.call("get_swing_counts")
	var lb: PackedFloat64Array = b.call("get_lengths")
	_ok("the cycle is the one asked for", absf(Tb - 60.0) < 1e-9, "%.9f s" % Tb)
	var cons_b := sb.size() == n
	for i in range(1, sb.size()):
		if sb[i] != sb[i - 1] + 1 or not (lb[i] < lb[i - 1] - 1e-4):
			cons_b = false
	_ok("consecutive counts, distinct lengths", cons_b,
		"%d .. %d swings, %.3f .. %.3f m" % [sb[0], sb[sb.size() - 1], lb[0], lb[lb.size() - 1]])
	b.set("relaunch_each_cycle", false)
	b.call("release")
	_step_for(b, 60.0, 1.0 / 90.0)
	var home_b := true
	for pd in b.get("pendulums"):
		var phase_b: float = absf(atan2(-float(pd["angular_velocity"]) / float(pd["omega"]), float(pd["angle"])))
		if phase_b > 1e-4:
			home_b = false
	_ok("unison at 60 s, stepped at 1/90", home_b)
	b.queue_free()
	await _frames(2)

	# ── 10. configured before _ready ──────────────────────────────────────
	print("10 apply_grid_config before the tree")
	var c := _spawn(-1.0, {"armature": "datum"})
	await _frames(4)
	c.set_process(false)
	var arm_count := 0
	var pend_count := 0
	var suffixed := 0
	for child in c.get_children():
		var nm: String = str(child.name)
		if nm.begins_with("Armature"):
			arm_count += 1
		if nm.begins_with("Pendulum_"):
			pend_count += 1
		if nm.contains("@"):
			suffixed += 1
	_ok("one armature host", arm_count == 1, "%d" % arm_count)
	_ok("one set of pendulums, no suffixed duplicates", pend_count == n and suffixed == 0,
		"%d pendulums, %d suffixed names" % [pend_count, suffixed])
	var host := c.get_node_or_null("Armature") as Node3D
	if host != null and host.get_child_count() > 0:
		var board := host.get_child(0) as Node3D
		var reach_c: float = hi * sin(rel) + float(c.get("bob_radius"))
		_ok("the datum board stands behind the swing", board.position.z < -reach_c,
			"z %.2f < -%.2f" % [board.position.z, reach_c])
	c.queue_free()
	await _frames(2)

	# ── 11. the gantry's hoist ────────────────────────────────────────────
	# It used to hang at x = 0, z = 0: chain links through the pivot bar, block and hook
	# inside the centre pendulum's rod. Test the clearance off the built meshes.
	print("11 armature = gantry: the hoist clears the bar and the rods")
	var d := _spawn(-1.0, {"armature": "gantry"})
	await _frames(4)
	d.set_process(false)
	var bar_mi := d.get_node_or_null("PivotBar") as MeshInstance3D
	var gantry_host := d.get_node_or_null("Armature") as Node3D
	var hoist: Array = []
	if gantry_host != null:
		for ch in gantry_host.get_children():
			if str(ch.name).begins_with("Hoist") and ch is MeshInstance3D:
				hoist.append(ch)
	_ok("the hoist is built and named (trolley, arm, 6 links, block, hook)", hoist.size() == 10, "%d Hoist* meshes" % hoist.size())
	if bar_mi != null and hoist.size() > 0:
		var bar_box: AABB = bar_mi.global_transform * bar_mi.get_aabb()
		var rt: float = float(d.get("rod_thickness"))
		var base_y: float = float(d.get("base_height"))
		var through_bar: PackedStringArray = PackedStringArray()
		var through_rod: PackedStringArray = PackedStringArray()
		for h in hoist:
			var mi: MeshInstance3D = h
			var box: AABB = mi.global_transform * mi.get_aabb()
			if box.intersects(bar_box):
				through_bar.append(str(mi.name))
			for pd in d.get("pendulums"):
				var pivot: Vector3 = pd["pivot_position"]
				var px: float = pivot.x + d.global_position.x
				var overlaps_x: bool = box.position.x < px + rt and box.end.x > px - rt
				if overlaps_x and box.position.y < base_y:
					through_rod.append("%s@x%.2f" % [str(mi.name), px])
		_ok("no hoist piece passes through the pivot bar", through_bar.is_empty(), ", ".join(through_bar))
		_ok("no hoist piece hangs in a rod's plane below the pivots", through_rod.is_empty(), ", ".join(through_rod))
	d.queue_free()
	await _frames(2)

	print("")
	print("NOT TESTED HERE: a DesktopPlayer walking to the stand, and a VR fingertip on the RELEASE area.")
	print("")
	if _fails == 0:
		print("PASS probe_parametric_pendulum_waves")
	else:
		print("FAIL probe_parametric_pendulum_waves (%d)" % _fails)
	quit(1 if _fails > 0 else 0)
