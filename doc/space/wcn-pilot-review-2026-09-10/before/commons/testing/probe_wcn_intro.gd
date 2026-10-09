extends SceneTree
## WaveFunctions_Intro pilot (doc/research/waves-chance-noise, 2026-09-10):
## can a visitor release the pendulum, and does the room show two visits to the
## centre with opposite angular velocities?
##
## Stands up the ACTUAL museum hall with its artifacts (the pattern of
## probe_wave_platform_recovery.gd), finds the ControlPendulum, checks the
## reference and the readout it was placed with, drives the bob through the
## pickable's own picked_up / dropped signals — EMITTED PROGRAMMATICALLY, no
## tracked hand — and records the centre_crossed signals it emits. Measures the
## installation bounds and the swing envelope against the hall's collision.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_wcn_intro.gd -- --capture
##
## Writes res://ada_run/waves_chance_noise/WaveFunctions_Intro/probe_intro.json
## (and probe_intro.png under --capture). What this proves: the artifact answers
## the pickable's signals and the centre crossings happen with opposite signs.
## What it cannot prove: that a tracked hand reaches the bob. Headset acceptance
## is separate and is recorded as such in the report.
var checks := 0
var failures: Array[String] = []
var measurements: Dictionary = {}
var crossings: Array = []
var t0 := 0.0
const MAP := "WaveFunctions_Intro"
const OUT := "res://ada_run/waves_chance_noise/WaveFunctions_Intro/"

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[wcn-intro] ", "PASS " if ok else "FAIL ", message)

func run() -> void:
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl := "res://ada_run/waves_chance_noise/wcn-probe-control.json"
	em.set("EM_CONTROL", ctl); em.set("_overrides_path", ctl + ".unused"); em.set("_hand_path", ctl + ".unused-hand")
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

	# ── 1. the pendulum, as placed ────────────────────────────────────────────
	var pend: Node3D
	for n in seg.find_children("*", "Node3D", true, false):
		if n is ControlPendulum: pend = n; break
	check(pend != null, "control_pendulum is built in the hall")
	if pend == null:
		_finish(); return
	check(str(pend.get("reference")) == "plumb", "placed with reference=plumb (token config reached the artifact)")
	check(str(pend.get("evidence")) == "trace", "placed with evidence=trace")
	check(str(pend.get("regime")) == "free", "regime is the shipped free")
	check(pend.get_node_or_null("Reference/RestRing") != null, "the rest ring exists")
	check(pend.get_node_or_null("Reference/Plumb") != null, "the plumb line exists")
	check(pend.get_node_or_null("Evidence/Theta") != null, "the predicted theta(t) is drawn")
	var bob: Node3D = pend.get_node_or_null("BobSphere")
	check(bob != null, "the bob is a child pickable")
	check(bob != null and bob.has_signal("picked_up") and bob.has_signal("dropped"), "the bob carries the pickable's picked_up/dropped signals")
	var rest_local: Vector3 = seg.to_local(pend.call("rest_world_position"))
	measurements["rest_point_local"] = [rest_local.x, rest_local.y, rest_local.z]
	check(rest_local.y > 0.6 and rest_local.y < 1.6, "the rest point is at hand height (%.2f m above the deck)" % rest_local.y)
	var L: float = float(pend.get("pendulum_length"))
	for side in [-1.0, 1.0]:
		var release := pend.to_global(Vector3(sin(0.6) * L * side, -cos(0.6) * L, 0.0))
		var rl := seg.to_local(release)
		check(rl.y > 0.5 and rl.y < 1.8, "release position %s is reachable (%.2f m)" % ["left" if side < 0 else "right", rl.y])
		check(not _solid_at(seg, release, 0.09), "release position %s is clear of the hall's collision" % ["left" if side < 0 else "right"])
	# the swing envelope: a box the full width of the swing under the pivot
	var env := BoxShape3D.new()
	env.size = Vector3(2.0 * L + 0.3, L + 0.3, 0.3)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = env; q.transform = Transform3D(Basis.IDENTITY, pend.to_global(Vector3(0, -L * 0.5, 0)))
	var hits: Array = seg.get_world_3d().direct_space_state.intersect_shape(q, 8)
	var solid_hits := 0
	for h in hits:
		if h.collider == seg.get_node_or_null("Collision"): solid_hits += 1
	check(solid_hits == 0, "the complete swing is clear of walls and platforms (%d solid hits)" % solid_hits)
	measurements["installation_aabb"] = _aabb(pend)

	# ── 2. the real signal path: pick up, move, drop ──────────────────────────
	pend.connect("centre_crossed", func(d: int, w: float): crossings.append({"dir": d, "omega": w, "t": Time.get_ticks_msec() / 1000.0 - t0}))
	t0 = Time.get_ticks_msec() / 1000.0
	var first: Dictionary = await _release(pend, bob, 0.6)
	check(not bool(pend.call("is_grabbed")), "the artifact answered dropped: not grabbed after release")
	check(absf(float(first.get("angle", 0.0)) - 0.6) < 0.15, "the release angle came from the bob's position (%.2f rad)" % float(first.get("angle", 0.0)))
	await create_timer(4.0).timeout
	var n1 := crossings.size()
	check(n1 >= 2, "at least two centre crossings after one release (%d)" % n1)
	if n1 >= 2:
		check(int(crossings[0]["dir"]) != int(crossings[1]["dir"]), "the first two crossings travel in opposite directions (%d then %d)" % [int(crossings[0]["dir"]), int(crossings[1]["dir"])])
		check(signf(float(crossings[0]["omega"])) != signf(float(crossings[1]["omega"])), "their angular velocities have opposite signs (%+.2f, %+.2f rad/s)" % [float(crossings[0]["omega"]), float(crossings[1]["omega"])])
	check(int(pend.call("crossings")) == n1, "the label's count matches the emitted crossings")
	var lbl: Label3D = pend.get_node_or_null("Label3D") if pend.get_node_or_null("Label3D") else null
	for c in pend.get_children():
		if c is Label3D: lbl = c
	check(lbl != null and (lbl.text.contains("ω +") or lbl.text.contains("ω -")), "the readout prints a SIGNED angular velocity")
	# ── 3. release from the other side ────────────────────────────────────────
	var before := crossings.size()
	var dir_first: int = int(crossings[0]["dir"]) if n1 > 0 else 0
	await _release(pend, bob, -0.6)
	await create_timer(2.5).timeout
	check(crossings.size() > before, "a second release crosses the centre again")
	if crossings.size() > before and n1 > 0:
		check(int(crossings[before]["dir"]) != dir_first, "released from the other side, the first crossing goes the other way")
	# ── 4. the driven cube listens to this pendulum ───────────────────────────
	var cube: Node = null
	for n in seg.find_children("*", "Node3D", true, false):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("oscillation_controlled_cube.gd"): cube = n; break
	check(cube != null, "oscillation_controlled_cube stands in the hall")
	if cube != null:
		check(cube.get("_pendulum") == pend, "the driven cube found THIS pendulum (one signal, three transformations)")
	measurements["crossings"] = crossings
	measurements["scale"] = [pend.scale.x, pend.scale.y, pend.scale.z]
	check(pend.scale.is_equal_approx(Vector3.ONE), "the subject's scale is what the map asked (1)")

	if "--capture" in OS.get_cmdline_user_args():
		var cam := Camera3D.new(); em.add_child(cam); cam.fov = 60
		cam.global_position = pend.to_global(Vector3(0.9, 0.2, 1.9)); cam.look_at(pend.to_global(Vector3(0, -0.3, 0)))
		for i in range(30): cam.make_current(); await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + "probe_intro.png")
	_finish()

## The pickable's own signal path, emitted programmatically: picked_up, the bob
## carried to the release angle over a few physics frames (so the artifact's
## velocity samples see a hand moving), then dropped.
func _release(pend: Node3D, bob: Node3D, angle: float) -> Dictionary:
	var L: float = float(pend.get("pendulum_length"))
	bob.emit_signal("picked_up", bob)
	await physics_frame
	var start: Vector3 = bob.global_position
	var target: Vector3 = pend.to_global(Vector3(sin(angle) * L, -cos(angle) * L, 0.0))
	for i in range(12):
		bob.global_position = start.lerp(target, float(i + 1) / 12.0)
		await physics_frame
	bob.global_position = target
	await physics_frame
	var a: float = float(pend.call("angle"))
	bob.emit_signal("dropped", bob)
	await physics_frame
	return {"angle": a, "omega": float(pend.call("angular_velocity"))}

func _solid_at(seg: Node3D, p: Vector3, r: float) -> bool:
	var s := SphereShape3D.new(); s.radius = r
	var q := PhysicsShapeQueryParameters3D.new(); q.shape = s; q.transform = Transform3D(Basis.IDENTITY, p)
	for h in seg.get_world_3d().direct_space_state.intersect_shape(q, 8):
		if h.collider == seg.get_node_or_null("Collision"): return true
	return false

func _aabb(node: Node) -> Array:
	var merged := AABB(); var first := true
	for n in node.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = (n as MeshInstance3D).global_transform * (n as MeshInstance3D).get_aabb()
		merged = box if first else merged.merge(box); first = false
	return [snappedf(merged.size.x, 0.01), snappedf(merged.size.y, 0.01), snappedf(merged.size.z, 0.01)]

func _finish() -> void:
	var report := {"map": MAP, "checks": checks, "failures": failures, "measurements": measurements,
		"control_path": "picked_up/dropped emitted programmatically on the bob pickable; no tracked hand",
		"headset_verified": false, "engine": Engine.get_version_info().string,
		"physics_fps": Engine.physics_ticks_per_second}
	var f := FileAccess.open(OUT + "probe_intro.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  ")); f.close()
	print("[wcn-intro] ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
