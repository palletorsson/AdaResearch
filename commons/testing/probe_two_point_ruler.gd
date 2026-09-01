extends SceneTree
## DOES MEASURING CHANGE THE THING IT IS NOT MEASURING?
##
## Five checks, and the two that matter are the ones asserting what must NOT
## move. The whole argument rests on the subject being honest: if measuring
## changed the subject too, the artifact would just be a broken ruler, and the
## unsettling part — that the reading is TRUE and the world is different — would
## be gone.

func _init() -> void:
	var R := load("res://commons/artifacts/two_point_ruler/two_point_ruler.tscn")
	var a = R.instantiate()
	get_root().add_child(a)
	await process_frame
	await process_frame
	var fails := 0

	var s0: float = a.subject_scale()
	var w0: float = a.witness_scale()
	print("1  at rest: subject=%.3f witness=%.3f" % [s0, w0])
	if s0 <= 0.0 or w0 <= 0.0:
		print("   FAIL nothing was built"); fails += 1

	var r: float = a.measure()
	await process_frame
	print("2  reading = %.2f m (must be the unit, 0.50)" % r)
	if abs(r - 0.5) > 0.001:
		print("   FAIL the reading is not honest"); fails += 1

	# let the tween land
	for i in 40:
		await process_frame
	var s1: float = a.subject_scale()
	var w1: float = a.witness_scale()
	print("3  after: subject=%.3f witness=%.3f" % [s1, w1])

	# THE NEGATIVE THAT CARRIES THE ARGUMENT
	print("4  subject unchanged? %s (must be true)" % [abs(s1 - s0) < 0.001])
	if abs(s1 - s0) >= 0.001:
		print("   FAIL measuring changed what it measured — that is just a bad ruler"); fails += 1

	print("5  witness changed?   %s (must be true)" % [abs(w1 - w0) > 0.01])
	if abs(w1 - w0) <= 0.01:
		print("   FAIL nothing was displaced; the reading was inert"); fails += 1

	# and it must not run away: repeated readings stop at the floor
	for i in 12:
		a.measure()
		for j in 6:
			await process_frame
	var w2: float = a.witness_scale()
	print("6  after 12 more readings: witness=%.3f (must be >= 0.18, still present)" % w2)
	if w2 < 0.179:
		print("   FAIL the witness left; there is nothing to watch"); fails += 1

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)
