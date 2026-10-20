extends SceneTree
## DOES MORE CORD ACTUALLY ESCAPE, AND DOES THE SIDE ACTUALLY MATTER?
##
## The piece claims two things and both are testable without a single pixel:
## that slack is monotone -- more cord cannot fit better -- and that approach
## changes the problem, because the whole content of the source figure is that
## the same join is easy from one configuration and hard from the other.
##
## The negative half: at slack=taut nothing should escape, in either approach.
## A version that always reported ESCAPES would look dramatic and argue nothing.

const SCENE := "res://commons/artifacts/flex_connector/flex_connector.tscn"


func _mk(approach: String, slack: String) -> Node:
	var inst = load(SCENE).instantiate()
	inst.set("approach", approach)
	inst.set("slack", slack)
	get_root().add_child(inst)
	return inst


func _count(n: Node, cls: String) -> int:
	var k := 0
	if n.get_class() == cls:
		k += 1
	for c in n.get_children():
		k += _count(c, cls)
	return k


func _init() -> void:
	var fails := 0
	var order := ["taut", "easy", "loose", "coiled"]

	for ap in ["different", "same"]:
		var prev := -1
		var line := []
		for s in order:
			var n = _mk(ap, s)
			await process_frame
			var out: int = n.samples_outside()
			line.append("%s=%d" % [s, out])
			if out < prev:
				print("   FAIL %s: %s escaped LESS than the slacker setting before it" % [ap, s])
				fails += 1
			prev = out
		print("%-10s outside samples: %s   (must not decrease)" % [ap, ", ".join(line)])

	var t1 = _mk("different", "taut")
	await process_frame
	var t2 = _mk("same", "taut")
	await process_frame
	print("taut fits: different=%s same=%s   (both must be true)"
		% [t1.fits_inside(), t2.fits_inside()])
	if not (t1.fits_inside() and t2.fits_inside()):
		print("   FAIL a taut cord between two points on the boundary left the region")
		fails += 1

	var c1 = _mk("different", "coiled")
	await process_frame
	var c2 = _mk("same", "coiled")
	await process_frame
	print("coiled escapes: different=%s same=%s   (at least one must be true)"
		% [not c1.fits_inside(), not c2.fits_inside()])
	if c1.fits_inside() and c2.fits_inside():
		print("   FAIL twice the chord length still fits; the containment test is not biting")
		fails += 1

	var d_ratio: float = c1.cord_ratio()
	var s_ratio: float = c2.cord_ratio()
	print("approach changes the problem: different chord-ratio=%.2f vs same=%.2f" % [d_ratio, s_ratio])
	if absf(d_ratio - s_ratio) > 0.35:
		print("   NOTE the two approaches are being solved to different ratios;")
		print("   that is the bisection, not the design -- worth an eye, not a failure")

	var steals := _count(t1, "Camera3D") + _count(t1, "WorldEnvironment") \
		+ _count(t1, "CanvasLayer") + _count(t1, "DirectionalLight3D")
	print("steals (cam/env/canvas/light) = %d   (must be 0)" % steals)
	if steals > 0:
		fails += 1

	print("\nprobe_flex_connector: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(0 if fails == 0 else 1)
