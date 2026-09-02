extends SceneTree
## The Portals room's code must be TRUE. Functions copied verbatim from
## Primitives_Portals/tutorial.md and asked questions with known answers.
##
##   1  the gap to the circle is positive for n = 3..4096 and strictly shrinks
##   2  Archimedes: the 96-gon gives a ratio between 3.1408 and 3.1416
##   3  achilles(10) is under 1.0; in MATHEMATICS no step arrives
##   4  in the MACHINE it arrives: find the step where covered == 1.0 exactly,
##      and it must be in the fifties (a 64-bit float has 53 bits of mantissa)
##   5  torus Euler is 0 at every resolution; a prism's is 2   <- the hole
##   6  through_portal keeps speed and changes direction

func polygon_perimeter(n: int, r: float) -> float:
	var total := 0.0
	for i in n:
		var a := Vector2.RIGHT.rotated(TAU * i / n) * r
		var b := Vector2.RIGHT.rotated(TAU * (i + 1) / n) * r
		total += a.distance_to(b)
	return total

func gap_to_circle(n: int, r: float) -> float:
	return TAU * r - polygon_perimeter(n, r)

func achilles(steps: int) -> float:
	var covered := 0.0
	for i in steps:
		covered += (1.0 - covered) * 0.5
	return covered

func torus_counts(rings: int, segments: int) -> Dictionary:
	var v := rings * segments
	var f := rings * segments
	var e := 2 * rings * segments
	return {"vertices": v, "edges": e, "faces": f, "euler": v - e + f}

func through_portal(entry: Transform3D, exit: Transform3D, velocity: Vector3) -> Vector3:
	var turn := exit.basis * entry.basis.inverse()
	return turn * velocity

func _init() -> void:
	var fails := 0

	# 1. positive and shrinking
	var last := INF
	var ok := true
	var n := 3
	while n <= 4096:
		var g := gap_to_circle(n, 1.0)
		if g <= 0.0 or g >= last:
			ok = false
		last = g
		n *= 2
	print("1  gap to the circle positive and shrinking for n = 3..4096: %s (gap at 4096 = %.9f)" % [ok, last])
	if not ok:
		print("   FAIL the polygon reached or overshot the circle"); fails += 1

	# 2. Archimedes
	var ratio96 := polygon_perimeter(96, 1.0) / 2.0
	print("2  96-gon ratio %.5f (must lie in [3.1408, 3.1416])" % ratio96)
	if ratio96 < 3.1408 or ratio96 > 3.1416:
		print("   FAIL Archimedes disagrees"); fails += 1

	# 3. ten steps do not arrive
	var a10 := achilles(10)
	print("3  achilles(10) = %.6f (must be under 1)" % a10)
	if a10 >= 1.0:
		print("   FAIL ten steps arrived"); fails += 1

	# 4. the machine arrives: find the step
	var arrived := -1
	var covered := 0.0
	for i in range(1, 200):
		covered += (1.0 - covered) * 0.5
		if covered == 1.0:
			arrived = i
			break
	print("4  the float reaches exactly 1.0 at step %d (must be 50..60)" % arrived)
	if arrived < 50 or arrived > 60:
		print("   FAIL the machine did not arrive where a 53-bit mantissa says it should"); fails += 1

	# 5. the hole
	var eul_ok := true
	for r in [3, 8, 16]:
		for s in [4, 12, 32]:
			if torus_counts(r, s)["euler"] != 0:
				eul_ok = false
	var prism_euler: int = 2 * 6 - 3 * 6 + (6 + 2)
	print("5  torus Euler at nine resolutions all 0: %s; a hexagonal prism's is %d (must be 2)" % [eul_ok, prism_euler])
	if not eul_ok or prism_euler != 2:
		print("   FAIL the hole did not change the number"); fails += 1

	# 6. the portal: speed kept, direction changed
	var entry := Transform3D(Basis(), Vector3.ZERO)
	var exit := Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(10, 0, 10))
	var v_in := Vector3(0, 0, -3)
	var v_out := through_portal(entry, exit, v_in)
	var same_speed: bool = absf(v_out.length() - v_in.length()) < 1e-6
	var turned: bool = v_out.normalized().dot(v_in.normalized()) < 0.01
	print("6  velocity in %s -> out %s: speed kept=%s, turned=%s" % [v_in, v_out, same_speed, turned])
	if not same_speed or not turned:
		print("   FAIL the portal transported instead of transforming"); fails += 1

	print("")
	print("PROBE %s" % ("OK" if fails == 0 else "FAILED %d" % fails))
	quit(fails)
