extends SceneTree
## CAN THEY FIT — AND DOES THE ANSWER SURVIVE THE TICK RATE?
##
## droplet_cusp (rebuilt 2026-10-13) drops a SoftBody3D sphere onto a boolean
## funnel and reads the settled pose: PASSED, HANGS, or PROUD. Three claims:
##
##   1. snug/firm PASSES — a throat wider than the ball swallows it whole.
##   2. scant/firm does NOT pass — the negative half. A version where
##      everything passes is a funnel-shaped slide, not an experiment.
##   3. softness buys depth: at waist=tight, jelly ends lower than firm by a
##      clear margin, or outright passes while firm does not. The artifact's
##      whole argument, stated relatively so it does not hang on exact numbers.
##
## EVERY CLAIM RUNS AT 60 AND 90 HZ: settle verdicts in this corpus have
## flipped with tick rate before (a die read 15/16 at 90 Hz, 2/16 at 60).
##
## HARNESS SCARS, each bought in this file:
##  - Engine.time_scale stays 1. At 4 the solver injects energy and a ball
##    EXPLODES resting on a plain floor (probe_softbody_bench measured it), and
##    three innocent colliders were blamed before the bench isolated it.
##  - Every artifact is FREED after reading. An earlier version left each one
##    standing at the origin, so run N settled inside the wreckage of runs 1..N-1.
##  - Verdicts are snapshotted into a Dictionary before queue_free, because the
##    node is gone by the time the claims are compared.

const SCENE := "res://commons/artifacts/droplet_cusp/droplet_cusp.tscn"
const MAX_TICKS := 1500


func _run(waist: String, flesh: String) -> Dictionary:
	var n = load(SCENE).instantiate()
	n.set("flesh", flesh)
	n.set("waist", waist)
	get_root().add_child(n)
	var guard := 0
	while guard < MAX_TICKS:
		await physics_frame
		guard += 1
		if n.is_settled():
			break
	var out := {
		"word": n.verdict_word(),
		"top": n.ball_top_m(),
		"bottom": n.ball_bottom_m(),
		"phys": n.used_physics_bounds(),
		"steals": _count(n, "Camera3D") + _count(n, "WorldEnvironment")
			+ _count(n, "CanvasLayer") + _count(n, "DirectionalLight3D"),
	}
	n.queue_free()
	await process_frame
	return out


func _count(n: Node, cls: String) -> int:
	var k := 0
	if n.get_class() == cls:
		k += 1
	for c in n.get_children():
		k += _count(c, cls)
	return k


func _init() -> void:
	var fails := 0
	Engine.time_scale = 1.0
	var reported_lane := false

	for rate in [60, 90]:
		Engine.physics_ticks_per_second = rate
		print("--- %d Hz ---" % rate)

		var a := await _run("snug", "firm")
		print("  snug/firm    -> %-7s top=%+.0f mm  (must be PASSED)"
			% [a["word"], a["top"] * 1000.0])
		if a["word"] != "PASSED":
			print("   FAIL a throat wider than the ball refused it")
			fails += 1
		if not reported_lane:
			reported_lane = true
			print("  physics-side bounds available = %s" % a["phys"])

		var b := await _run("scant", "firm")
		print("  scant/firm   -> %-7s bottom=%+.0f mm  (must NOT pass)"
			% [b["word"], b["bottom"] * 1000.0])
		if b["word"] in ["PASSED", "ESCAPED", "UNSTABLE"]:
			print("   FAIL the ball went through a throat barely half its size")
			fails += 1

		var c := await _run("tight", "firm")
		var d := await _run("tight", "jelly")
		var sank: float = (c["bottom"] - d["bottom"]) * 1000.0
		print("  tight/firm   -> %-7s bottom=%+.0f mm" % [c["word"], c["bottom"] * 1000.0])
		print("  tight/jelly  -> %-7s bottom=%+.0f mm   jelly deeper by %.0f mm (need >=8)"
			% [d["word"], d["bottom"] * 1000.0, sank])
		var softness_pays: bool = d["word"] == "PASSED" and c["word"] != "PASSED"
		if c["word"] in ["ESCAPED", "UNSTABLE"] or d["word"] in ["ESCAPED", "UNSTABLE"]:
			print("   FAIL a broken run (%s/%s) cannot witness the softness claim"
				% [c["word"], d["word"]])
			fails += 1
		elif not softness_pays and sank < 8.0:
			print("   FAIL softness bought nothing at the tight waist -- the one")
			print("   claim this artifact exists to make")
			fails += 1

		if a["steals"] > 0:
			print("   FAIL artifact steals from the room (cam/env/canvas/light = %d)" % a["steals"])
			fails += 1

	print("probe_droplet_fit: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(0 if fails == 0 else 1)
