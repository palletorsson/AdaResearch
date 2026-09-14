extends SceneTree
## Noise_One, batch N3 (doc/research/waves-chance-noise, 2026-09-12, the third hall of Astra's
## noise arc): is the restless thing a field, a surface, or our way of reading it?
##
## Stands up the ACTUAL museum hall with its artifacts, hands the museum the REAL necklace hand
## file, and tests the pair as the map stages it (noisetorus:180#stand:pair at (5,2), placement
## authority with the map): two rings of the same size on one bench, the same shader and the same
## noise scale — the same FIELD — one spending it as relief and the other as colour, with a
## marker standing on the same coordinate of both and a plate naming that coordinate, the value
## there and what each reading makes of it.
##
## The evidence Astra's card asks for, and how it is taken here. That both readings use the same
## value at a fixed coordinate is a fact about the SHADER, so the probe reads the shader source:
## the vertex and fragment build the same noise input from the same expression, both spend the
## same noise_value, and every TIME in the file is multiplied by one of the two speed uniforms —
## which is what makes FREEZE a freeze rather than a material parameter at zero. That the two
## readings are not equivalent is the room's own finding and is measured: the field runs from -1
## to 1, the relief spends all of it, and the colour clamps the negative half to black. Then
## amplitude against frequency (a reading that leaves the value alone, against the field itself
## changing under the coordinate), and the collision contract: no collider on either ring, so a
## corrugation you can see is not one you could touch.
##
##   godot --rendering-method gl_compatibility --path . --xr-mode off --script res://commons/testing/probe_wcn_torus.gd -- --capture
##
## Writes res://ada_run/waves_chance_noise/Noise_One/probe_torus.json
## (and probe_torus*.png under --capture). Exit code 1 on any failed check.
var checks := 0
var failures: Array[String] = []
var measurements: Dictionary = {}
const MAP := "Noise_One"
const OUT := "res://ada_run/waves_chance_noise/Noise_One/"
## Screenshots and audio go to the evidence root, ada_encyclopedia/captures/ada-run/ (2026-09-14);
## the JSON record stays in OUT, where it is committed.
var _evidence: String = preload("res://commons/testing/evidence_root.gd").dir("waves_chance_noise/Noise_One") + "/"
const MAP_CELL := Vector2i(5, 2)
const SHADER_PATH := "res://commons/resourses/shaders/noiseTorus.gdshader"
const SPOT := Vector3(5.5, 0.0, 1.35)   # the visitor's spot: before the bench's front
const EYE_H := 1.6

func _initialize() -> void: run.call_deferred()

func _live() -> bool:
	return str(get_script().resource_path).ends_with("_live.gd")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[wcn-torus] ", "PASS " if ok else "FAIL ", message)

func note(message: String) -> void:
	print("[wcn-torus] note: ", message)

func run() -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() == "headless":
		check(false, "PNG capture requires a rendered window; omit --headless, or omit --capture for logic only")
		_finish(); return

	# ── 0. the shader, read as source: what the two readings actually share ──
	var src: String = FileAccess.get_file_as_string(SHADER_PATH)
	measurements["shader_bytes"] = src.length()
	var vert_line: String = ""
	var frag_line: String = ""
	var time_lines: Array = []
	var lines: PackedStringArray = src.split("\n")
	var in_frag: bool = false
	for l in lines:
		var t: String = str(l).strip_edges()
		if t.begins_with("void fragment"): in_frag = true
		if t.contains("vec2 noise_input = vec2(object_pos.x"):
			if in_frag: frag_line = t
			else: vert_line = t
		if t.contains("noise_input += vec2(time_offset, time_offset)") and not in_frag:
			vert_line += " | " + t
		if t.contains("TIME") and not t.begins_with("//"):
			time_lines.append(t)
	measurements["shader"] = {"vertex_input": vert_line, "fragment_input": frag_line, "time_lines": time_lines}
	for tl in time_lines: note("TIME line: " + str(tl))
	check(vert_line != "" and frag_line != "", "the shader builds a noise input in both stages (%s / %s)" % [vert_line.substr(0, 60), frag_line.substr(0, 60)])
	check(vert_line.contains("object_pos.x * noise_scale") and frag_line.contains("object_pos.x * noise_scale")
			and vert_line.contains("object_pos.z * noise_scale") and frag_line.contains("object_pos.z * noise_scale"),
		"and builds it from the same expression in both: the colour and the relief are readings of ONE value at one coordinate")
	# A TIME is safe if it is multiplied by a speed on the spot, OR if it is assigned to a
	# name whose every later use is. The shipped file does the second: `wrapped_time` takes
	# TIME bare and is spent only as `wrapped_time * noise_speed`. Checking the line alone
	# called that unfrozen, which is the opposite of true — and checking nothing at all is
	# what Astra's card warns about ("a material parameter at zero does not prove all time
	# inputs are frozen"). So the check follows the variable.
	var unscaled: Array = []
	for tl in time_lines:
		var t2: String = str(tl)
		if t2.contains("noise_speed") or t2.contains("hue_shift_speed"):
			continue
		var name: String = ""
		if t2.contains("=") and t2.contains("float "):
			name = t2.split("=")[0].strip_edges().replace("float ", "").strip_edges()
		if name == "":
			unscaled.append(t2)
			continue
		var uses: int = 0
		var scaled_uses: int = 0
		for l2 in lines:
			var u: String = str(l2).strip_edges()
			if u == t2 or not u.contains(name) or u.begins_with("//"):
				continue
			uses += 1
			if u.contains("noise_speed") or u.contains("hue_shift_speed"):
				scaled_uses += 1
		if uses == 0 or scaled_uses != uses:
			unscaled.append("%s (spent %d times, %d of them scaled)" % [t2, uses, scaled_uses])
	measurements["shader"]["unscaled_time"] = unscaled
	check(time_lines.size() > 0 and unscaled.is_empty(),
		"every TIME in the shader reaches an output only through one of the two speed uniforms, so zeroing both really is a freeze (%d TIME lines, %d unscaled)" % [time_lines.size(), unscaled.size()])
	check(src.contains("ALBEDO = mix(plain_albedo, rainbow_color * noise_value, show_colour)") and src.contains("height_multiplier * show_relief"),
		"the two readings can be shown apart, and both default to 1.0 — the shipped picture is unchanged")

	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl := "res://ada_run/waves_chance_noise/wcn-probe-control.json"
	em.set("EM_CONTROL", ctl); em.set("_overrides_path", ctl + ".unused")
	em.set("_hand_path", "res://ada_run/necklace_hand.json")   # the REAL hand, on purpose
	em.set("start_chapter", "noise"); em.set("start_map", MAP)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/em_layout.json"))
	layout.get_or_add("stream", {})["bodies"] = 1
	em.set("_layout", layout)
	var f := FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "noise", "dollhouse": 0, "grid_pack": 1})); f.close()
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
	measurements["captures"] = {}

	# ── 1. the hall ─────────────────────────────────────────────────────────
	var tile: Array = seg.get_meta("em_tile", [])
	var tile_rows: Array = []
	for row in tile:
		var line := ""
		for c in row: line += str(c)
		tile_rows.append(line)
	measurements["tile"] = tile_rows
	for r in range(tile_rows.size()): note("tile %2d %s" % [r, tile_rows[r]])
	var bodies: Array = []
	var prim: Node3D
	var by_token: Dictionary = {}
	for record: Dictionary in em.get("_edit_records"):
		var node: Node = record.get("node")
		if node == null or not (node is Node3D) or not seg.is_ancestor_of(node): continue
		if str(record.get("token", "")) == "": continue
		var lp: Vector3 = seg.to_local((node as Node3D).global_position)
		var sp: String = str(node.get_script().resource_path).get_file() if node.get_script() != null else "-"
		var ent := {"token": record.get("token"), "script": sp, "cell": record.get("tile_cell", []), "at": [snappedf(lp.x, 0.01), snappedf(lp.y, 0.01), snappedf(lp.z - vest, 0.01)]}
		bodies.append(ent)
		by_token[str(record.get("token"))] = ent
		if sp == "noisetorus.gd" and node.get("stand") == "pair": prim = node
	measurements["bodies"] = bodies
	for b in bodies:
		if not str(b["token"]).begins_with("lobby") and str(b["token"]) != "showing": note("body %-22s %-22s cell %-8s at %s" % [str(b["token"]), str(b["script"]), str(b["cell"]), str(b["at"])])
	check(prim != null, "the pair is built in the hall")
	if prim == null:
		_finish(); return
	check((by_token.get("noisetorus", {}) as Dictionary).get("cell", []) == [MAP_CELL.x, MAP_CELL.y],
		"it stands at its map cell (5,2), on the floor rather than over the hall's hole (%s)" % str((by_token.get("noisetorus", {}) as Dictionary).get("cell")))
	await create_timer(0.3).timeout
	var walk_sev: Array = em.get("_walk_severed") if em.get("_walk_severed") != null else []
	var mine: Array = []
	for e in walk_sev:
		if str((e as Dictionary).get("hall", "")).contains(MAP): mine.append(e)
	measurements["museum_walk_severed"] = mine
	check(mine.is_empty(), "the museum walks this hall door to door with the bench in it (%s)" % str(mine))

	# ── 2. one field, two readings ──────────────────────────────────────────
	var st: Dictionary = prim.call("pair_state")
	measurements["pair"] = st
	note("pair " + JSON.stringify(st))
	var rings: Array = st["rings"]
	check(rings.size() == 2, "two rings stand on the bench (%d)" % rings.size())
	var relief_ring: Dictionary = {}
	var colour_ring: Dictionary = {}
	for r in rings:
		if str((r as Dictionary)["kind"]) == "relief": relief_ring = r
		else: colour_ring = r
	check(not relief_ring.is_empty() and not colour_ring.is_empty(), "one reads as relief and one as colour")
	check(is_equal_approx(float(relief_ring["noise_scale"]), float(colour_ring["noise_scale"])),
		"and they sample the SAME field: one noise scale, %.3f on both" % float(relief_ring["noise_scale"]))
	check(str(relief_ring["shader"]) == str(colour_ring["shader"]) and str(relief_ring["shader"]) == "noiseTorus.gdshader",
		"through the same shader (%s / %s)" % [str(relief_ring["shader"]), str(colour_ring["shader"])])
	check(is_equal_approx(float(relief_ring["show_relief"]), 1.0) and is_equal_approx(float(relief_ring["show_colour"]), 0.0)
			and is_equal_approx(float(colour_ring["show_colour"]), 1.0) and is_equal_approx(float(colour_ring["show_relief"]), 0.0),
		"each ring shows one reading and only one (relief %s/%s, colour %s/%s)" % [str(relief_ring["show_relief"]), str(relief_ring["show_colour"]), str(colour_ring["show_relief"]), str(colour_ring["show_colour"])])
	check(is_equal_approx(float(relief_ring["aabb"]), float(colour_ring["aabb"])), "the two rings are the same size, so nothing but the reading differs (%.3f m)" % float(relief_ring["aabb"]))
	# the plate's arithmetic, against the artifact's own model of the field
	var v: float = float(st["value"])
	check(abs(float(st["relief"]) - v * float(st["amplitude"])) < 0.0005,
		"at the marked coordinate the relief is the value times the amplitude (%.4f x %.2f = %.4f)" % [v, float(st["amplitude"]), float(st["relief"])])
	check(abs(float(st["colour"]) - maxf(v, 0.0)) < 0.0005,
		"and the colour is the same value, clamped at zero (%.4f → %.4f)" % [v, float(st["colour"])])

	# ── 3. the half the colour throws away ──────────────────────────────────
	var walked: Array = []
	var found_negative: Dictionary = {}
	for i in range(6):
		var s2: Dictionary = prim.call("pair_state")
		walked.append({"i": int(s2["sample_index"]), "at": s2["sample_at"], "value": float(s2["value"]),
			"relief": float(s2["relief"]), "colour": float(s2["colour"])})
		if float(s2["value"]) < 0.0 and found_negative.is_empty(): found_negative = walked[walked.size() - 1]
		prim.call("next_sample")
		await create_timer(0.15, true, false, true).timeout
	measurements["samples"] = walked
	note("samples " + JSON.stringify(walked))
	check(not found_negative.is_empty(), "somewhere on the ring the field is negative (%s)" % JSON.stringify(found_negative))
	if not found_negative.is_empty():
		check(is_equal_approx(float(found_negative["colour"]), 0.0) and abs(float(found_negative["relief"])) > 0.0001,
			"and there the two readings part company: the relief goes inward %.4f m while the colour is black (%.4f)" % [float(found_negative["relief"]), float(found_negative["colour"])])

	# ── 4. freeze, and what a freeze has to cover ───────────────────────────
	check(_press_panel(prim, "Btn_0"), "FREEZE pressed through the button's signal (one argument)")
	await create_timer(0.4, true, false, true).timeout
	var frozen: Dictionary = prim.call("pair_state")
	var speeds_zero: bool = true
	for r in (frozen["rings"] as Array):
		if not is_equal_approx(float((r as Dictionary)["noise_speed"]), 0.0): speeds_zero = false
		if not is_equal_approx(float((r as Dictionary)["hue_shift_speed"]), 0.0): speeds_zero = false
	check(bool(frozen["frozen"]) and speeds_zero, "FREEZE stops BOTH clocks on both rings — the sample offset and the hue rotation")
	var t0: float = float(frozen["time"])
	var v0: float = float(frozen["value"])
	await create_timer(1.2, true, false, true).timeout
	var later: Dictionary = prim.call("pair_state")
	measurements["freeze"] = {"t_before": t0, "t_after": float(later["time"]), "value_before": v0, "value_after": float(later["value"])}
	check(is_equal_approx(float(later["time"]), t0) and is_equal_approx(float(later["value"]), v0),
		"and the sampled value does not move while it holds (%s)" % JSON.stringify(measurements["freeze"]))

	# ── 5. a reading, and the field ─────────────────────────────────────────
	var before_amp: Dictionary = prim.call("pair_state")
	check(_press_panel(prim, "Btn_2"), "AMPLITUDE pressed")
	await create_timer(0.4, true, false, true).timeout
	var after_amp: Dictionary = prim.call("pair_state")
	measurements["amplitude"] = {"was": float(before_amp["amplitude"]), "now": float(after_amp["amplitude"]),
		"value_was": float(before_amp["value"]), "value_now": float(after_amp["value"]),
		"relief_was": float(before_amp["relief"]), "relief_now": float(after_amp["relief"])}
	check(not is_equal_approx(float(after_amp["amplitude"]), float(before_amp["amplitude"])), "the amplitude changes (%.2f → %.2f)" % [float(before_amp["amplitude"]), float(after_amp["amplitude"])])
	check(is_equal_approx(float(after_amp["value"]), float(before_amp["value"])),
		"and the field does NOT: the same value stands at the same coordinate (%.4f)" % float(after_amp["value"]))
	var before_freq: Dictionary = prim.call("pair_state")
	check(_press_panel(prim, "Btn_3"), "FREQUENCY pressed")
	await create_timer(0.4, true, false, true).timeout
	var after_freq: Dictionary = prim.call("pair_state")
	measurements["frequency"] = {"was": float(before_freq["frequency"]), "now": float(after_freq["frequency"]),
		"value_was": float(before_freq["value"]), "value_now": float(after_freq["value"])}
	check(not is_equal_approx(float(after_freq["frequency"]), float(before_freq["frequency"])), "the frequency changes (%.3f → %.3f)" % [float(before_freq["frequency"]), float(after_freq["frequency"])])
	check(not is_equal_approx(float(after_freq["value"]), float(before_freq["value"])),
		"and the field does: another value stands at the same coordinate (%.4f → %.4f)" % [float(before_freq["value"]), float(after_freq["value"])])

	# ── 6. the collision contract ───────────────────────────────────────────
	var ring_colliders: Array = []
	for r in ["Ring_relief", "Ring_colour"]:
		var holder: Node = prim.get_node_or_null("Pair/%s" % r)
		if holder == null: continue
		for n in (holder as Node).find_children("*", "CollisionShape3D", true, false):
			ring_colliders.append(str((n as Node).get_path()).right(36))
		for n in (holder as Node).find_children("*", "StaticBody3D", true, false):
			ring_colliders.append(str((n as Node).get_path()).right(36))
	measurements["ring_colliders"] = ring_colliders
	check(ring_colliders.is_empty(), "neither ring carries a collider: the corrugation is in the vertex stage and cannot be touched (%s)" % str(ring_colliders))
	var ro: Label3D = prim.get_node_or_null("Pair/Readout/Text")
	check(ro != null, "the plate is cased on the bench's front")
	if ro != null:
		measurements["readout"] = ro.text.split("\n")
		for l in ro.text.split("\n"): note("plate | " + l)
		check(ro.text.contains("field value") and ro.text.contains("relief") and ro.text.contains("colour"),
			"and names the coordinate, the value and both readings")
		check(ro.text.contains("no collider"), "and says the relief is not a surface you can hit")
		check(ro.font_size >= 16 and ro.outline_size >= 2, "at a readable size (%d px)" % ro.font_size)

	# ── 7. captures, and the desktop rig in the live port ───────────────────
	if capture:
		var pair_node: Node3D = prim.get_node_or_null("Pair")
		# the hall gives about a metre and a half of standing room before the bench (the
		# middle of this room is a hole), so the standing view is taken from the corner of
		# that strip rather than straight back through the door
		cam.fov = 76
		cam.global_position = seg.to_global(Vector3(4.55, EYE_H, SPOT.z - 0.05 + vest))
		cam.look_at(seg.to_global(Vector3(5.5, 1.16, 2.45 + vest)))
		for i in range(20): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(_evidence + "probe_torus.png")
		measurements["captures"]["primary"] = _cam_pose(cam)
		cam.fov = 62
		for ring_name in ["Ring_relief", "Ring_colour"]:
			var holder: Node3D = pair_node.get_node_or_null(ring_name) if pair_node != null else null
			if holder == null: continue
			# over the plate, not through it: the cased readout stands at the rings' own
			# height on the bench's front, and a level close-up looks straight into it
			cam.global_position = holder.global_position + seg.global_transform.basis * Vector3(0.0, 0.62, -1.05)
			cam.look_at(holder.global_position)
			for i in range(14): cam.make_current(); await process_frame
			await create_timer(0.25, true, false, true).timeout
			root.get_texture().get_image().save_png(_evidence + "probe_torus_%s.png" % ring_name.to_lower().replace("ring_", ""))
			measurements["captures"][ring_name] = _cam_pose(cam)
		var rn: Node3D = pair_node.get_node_or_null("Readout") if pair_node != null else null
		if rn != null:
			cam.global_position = rn.global_position + seg.global_transform.basis * Vector3(0.0, 0.26, -0.70)
			cam.look_at(rn.global_position)
			for i in range(14): cam.make_current(); await process_frame
			await create_timer(0.25, true, false, true).timeout
			root.get_texture().get_image().save_png(_evidence + "probe_torus_readout.png")
			measurements["captures"]["readout"] = _cam_pose(cam)
		cam.global_position = seg.to_global(Vector3(5.5, 11.0, 4.5 + vest))
		cam.look_at(seg.to_global(Vector3(5.48, 0.0, 4.4 + vest)))
		for i in range(14): cam.make_current(); await process_frame
		await create_timer(0.25, true, false, true).timeout
		root.get_texture().get_image().save_png(_evidence + "probe_torus_plan.png")
		measurements["captures"]["plan"] = _cam_pose(cam)

	if _live():
		var drv: Node = load("res://commons/testing/wcn_desktop_driver.gd").new()
		root.add_child(drv)
		var stand_at: Vector3 = seg.to_global(Vector3(SPOT.x, 0.05, SPOT.z + vest))
		drv.call("spawn", stand_at, em)
		for i in range(20): await process_frame
		check(bool(drv.call("is_ready")), "the desktop rig stands before the bench")
		measurements["desktop_input"] = {"stand_pose": drv.call("pose")}
		var panel: Node = prim.find_child("Panel", true, false)
		var press_from: Vector3 = stand_at
		if panel != null:
			var pl: Vector3 = seg.to_local((panel as Node3D).global_position)
			press_from = seg.to_global(Vector3(pl.x, 0.05, pl.z - 0.45))
		measurements["desktop_input"]["press_from"] = [snappedf(press_from.x, 0.01), snappedf(press_from.z, 0.01)]
		for pair in [["Btn_1", "SAMPLE", "sample_index"], ["Btn_2", "AMPLITUDE", "amp_index"], ["Btn_3", "FREQUENCY", "freq_index"], ["Btn_0", "FREEZE", "frozen"]]:
			var btn: Node = panel.find_child(pair[0], true, false) if panel != null else null
			var was = prim.call("pair_state")[pair[2]]
			var rec: Dictionary = await drv.call("press", btn, press_from) if btn != null else {}
			await create_timer(0.4, true, false, true).timeout
			var now = prim.call("pair_state")[pair[2]]
			measurements["desktop_input"]["press_%s" % pair[1]] = {"hover": rec.get("hover", "-"), "was": was, "now": now}
			check(now != was, "%s pressed through the pointer changes what it says it changes (%s → %s)" % [pair[1], str(was), str(now)])
		if capture:
			drv.call("aim_at", seg.to_global(Vector3(5.5, 1.2, 2.5 + vest)))
			for i in range(8): await process_frame
			await create_timer(0.3, true, false, true).timeout
			root.get_texture().get_image().save_png(_evidence + "probe_torus_desktop_front.png")
			measurements["desktop_input"]["front_pose"] = drv.call("pose")
		drv.call("teardown")

	_finish()

func _press_panel(prim: Node, btn_name: String) -> bool:
	var panel: Node = prim.find_child("Panel", true, false)
	if panel == null: return false
	var btn: Node = panel.find_child(btn_name, true, false)
	if btn == null: return false
	var area: Node = btn.get_node_or_null("InteractableAreaButton")
	if area == null or not area.has_signal("button_pressed"): return false
	area.emit_signal("button_pressed", area)
	return true

func _cam_pose(cam: Camera3D) -> Dictionary:
	var cur: Camera3D = root.get_camera_3d()
	var fwd: Vector3 = -cam.global_transform.basis.z
	return {"current_camera": str(cur.get_path()).right(50) if cur != null else "none", "is_ours": cur == cam,
		"at": [snappedf(cam.global_position.x, 0.01), snappedf(cam.global_position.y, 0.01), snappedf(cam.global_position.z, 0.01)],
		"forward": [snappedf(fwd.x, 0.01), snappedf(fwd.y, 0.01), snappedf(fwd.z, 0.01)]}

func _finish() -> void:
	var report := {"map": MAP, "checks": checks, "failures": failures, "measurements": measurements,
		"control_path": "FREEZE / SAMPLE / AMPLITUDE / FREQUENCY through InteractableAreaButton.button_pressed (one argument); the live port presses all four through the desktop pointer from arm's length",
		"hand_file": "ada_run/necklace_hand.json (real)", "headset_verified": false,
		"engine": Engine.get_version_info().string, "physics_fps": Engine.physics_ticks_per_second}
	var f := FileAccess.open(OUT + "probe_torus.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  ")); f.close()
	print("[wcn-torus] ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
