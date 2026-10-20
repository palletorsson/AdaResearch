extends SceneTree
## DOES THE BODY FIND THE GAP, AND IS THE DEFLECTION THE BANDS' DOING?
##
## Four claims, gated at 60 AND 90 Hz like every settle verdict in this corpus:
##  1. none/firm rests essentially downhill (the control: no bands, no
##     deflection, azimuth near zero at the rim).
##  2. pair/firm rests CLEAR of the band, deflected past its edge -- the band
##     straddles downhill, so any clear rest is a measured refusal.
##  3. belt/firm rests ON the forbidden: when no clear arc remains, refusal has
##     nowhere to send you. The negative half of claim 2.
##  4. pair/level never reaches the rim at all -- the bands are never met, and
##     the axis is honest about being conditional on lean.

const SCENE := "res://commons/artifacts/forbidden_bands/forbidden_bands.tscn"
const MAX_TICKS := 1500


func _run(bands: String, lean: String) -> Dictionary:
	var n = load(SCENE).instantiate()
	n.set("lean", lean)
	n.set("bands", bands)
	get_root().add_child(n)
	var guard := 0
	while guard < MAX_TICKS:
		await physics_frame
		guard += 1
		if n.is_settled():
			break
	var out := {
		"az": n.rest_azimuth_deg(),
		"rho": n.rest_rho_m(),
		"rim": n.at_rim(),
		"band": n.on_band(),
		"edge": n.nearest_band_edge_deg(),
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

	for rate in [60, 90]:
		Engine.physics_ticks_per_second = rate
		print("--- %d Hz ---" % rate)

		var a := await _run("none", "firm")
		print("  none/firm   az=%+.0f deg rho=%.0f mm rim=%s   (|az|<14, at rim)"
			% [a["az"], a["rho"] * 1000.0, a["rim"]])
		if absf(a["az"]) >= 14.0 or not a["rim"]:
			fails += 1
			print("   FAIL with nothing forbidding it the ball must rest straight downhill")

		var b := await _run("pair", "firm")
		print("  pair/firm   az=%+.0f deg on_band=%s edge=%+.0f deg   (clear, past the band)"
			% [b["az"], b["band"], b["edge"]])
		# not b["rim"] was required here once, wrongly: a correctly deflected
		# ball rests against the band's END FACE and need not touch the outer
		# wall at all. The honest requirement is clear-of-band and not-centered.
		if b["band"] or b["rho"] < 0.05:
			fails += 1
			print("   FAIL the ball rested on the forbidden with a clear arc available")
		if b["edge"] < 1.0:
			fails += 1
			print("   FAIL clear but not PAST the edge; the deflection was not real")
		if absf(b["az"]) < 14.0:
			fails += 1
			print("   FAIL azimuth unchanged from the control; the band deflected nothing")

		var c := await _run("belt", "firm")
		print("  belt/firm   az=%+.0f deg on_band=%s   (must rest ON the forbidden)"
			% [c["az"], c["band"]])
		if not c["band"]:
			fails += 1
			print("   FAIL a 310-degree belt leaves no clear arc at the rim downhill")

		var d := await _run("pair", "level")
		print("  pair/level  rho=%.0f mm rim=%s   (centered; the bands never met)"
			% [d["rho"] * 1000.0, d["rim"]])
		if d["rim"]:
			fails += 1
			print("   FAIL a level dish must hold the ball at the centre")

		if a["steals"] > 0:
			fails += 1
			print("   FAIL steals = %d" % a["steals"])

	print("probe_forbidden_bands: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(0 if fails == 0 else 1)
