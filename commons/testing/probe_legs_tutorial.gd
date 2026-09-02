extends SceneTree
## VFM_09 Legs' one rule must be TRUE. can_lift() is copied from
## VFM_09_Legs/tutorial.md; _inside_polygon, which the tutorial leaves undefined,
## is a strict convex point-in-polygon on the floor plane (a point ON an edge is
## not inside: a line is a fall). Feet are given in order around the body.
##
##   1  one leg fails always; two fail always
##   2  three pass only with all three down; lift one and it is a fall
##   3  four: lift one and the centre sits EXACTLY on the diagonal, marginal until the body
##      leans; lift a diagonal pair and only a line is left           <- the trot is a fall
##   4  five: lift two ADJACENT legs and fall; lift two apart and stand   <- the odd gait
##   5  six: lift alternate legs (0,2,4) and stand on the other tripod; lift one side and fall
##   6  eight: lift alternate four and stand

func can_lift(planted: Array[Vector3], com: Vector3) -> bool:
	if planted.size() < 3:
		return false          # two points make a line, and a line is a fall
	return _inside_polygon(planted, com)

func _inside_polygon(poly: Array[Vector3], p: Vector3) -> bool:
	# strict: the point must be on the same side of every edge, never on one
	var sign := 0.0
	for i in poly.size():
		var a: Vector3 = poly[i]; var b: Vector3 = poly[(i + 1) % poly.size()]
		var cross := (b.x - a.x) * (p.z - a.z) - (b.z - a.z) * (p.x - a.x)
		if absf(cross) < 1e-9:
			return false
		if sign == 0.0:
			sign = signf(cross)
		elif signf(cross) != sign:
			return false
	return true

func ring(n: int, r: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for k in n:
		out.append(Vector3(r * cos(TAU * k / n), 0.0, r * sin(TAU * k / n)))
	return out

func keep(feet: Array[Vector3], lifted: Array) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for i in feet.size():
		if not lifted.has(i):
			out.append(feet[i])
	return out

func _init() -> void:
	var fails := 0
	var com := Vector3.ZERO

	# 1. one and two
	var one := ring(1, 0.3); var two := ring(2, 0.3)
	var c1 := can_lift(one, com); var c2 := can_lift(two, com)
	print("1  one planted foot: stable %s; two planted: stable %s (both must be false: pogo and fall-and-catch)" % [c1, c2])
	if c1 or c2:
		print("   FAIL fewer than three feet counted as stable"); fails += 1

	# 2. three
	var three := ring(3, 0.4)
	var all3 := can_lift(three, com); var lift1of3 := can_lift(keep(three, [0]), com)
	print("2  three down: stable %s (must be true); lift one: stable %s (must be false: no foot leaves without a dynamic moment)" % [all3, lift1of3])
	if not all3 or lift1of3:
		print("   FAIL three legs did not behave as the tutorial says"); fails += 1

	# 3. four: a rectangle, 0.6 long and 0.4 wide, centre of mass at the centre
	var four: Array[Vector3] = [Vector3(0.3, 0, 0.2), Vector3(-0.3, 0, 0.2), Vector3(-0.3, 0, -0.2), Vector3(0.3, 0, -0.2)]
	var lift1_centred := can_lift(keep(four, [0]), com)
	var lift1_leaned := can_lift(keep(four, [0]), Vector3(-0.05, 0, -0.05))   # lean 5 cm away from the lifted foot
	var diag := can_lift(keep(four, [0, 2]), com)
	var lateral := can_lift(keep(four, [0, 1]), com)
	print("3  four: lift one with the body centred: stable %s (must be FALSE: the centre sits exactly on the diagonal); lean 5 cm first: stable %s (must be true); lift a diagonal pair: %s; lift one side: %s (both must be false)" % [lift1_centred, lift1_leaned, diag, lateral])
	if lift1_centred or not lift1_leaned or diag or lateral:
		print("   FAIL the four-leg case is not what the tutorial says"); fails += 1

	# 4. five
	var five := ring(5, 0.4)
	var lift1of5 := can_lift(keep(five, [0]), com)
	var adjacent_ok := 0; var apart_ok := 0
	for i in 5:
		for j in range(i + 1, 5):
			var stands := can_lift(keep(five, [i, j]), com)
			var adj: bool = (j - i == 1) or (j - i == 4)
			if adj and stands: adjacent_ok += 1
			if not adj and stands: apart_ok += 1
	print("4  five: lift one: stable %s (must be true); of the 5 ADJACENT pairs %d can be lifted (must be 0); of the 5 pairs APART %d can (must be 5)" % [lift1of5, adjacent_ok, apart_ok])
	if not lift1of5 or adjacent_ok != 0 or apart_ok != 5:
		print("   FAIL the pentagon's pairs are not what the text says"); fails += 1

	# 5. six
	var six := ring(6, 0.4)
	var tripod := can_lift(keep(six, [0, 2, 4]), com)
	var one_side := can_lift(keep(six, [0, 1, 2]), com)
	print("5  six: lift 0,2,4 and stand on the other tripod: %s (must be true); lift one whole side 0,1,2: %s (must be false)" % [tripod, one_side])
	if not tripod or one_side:
		print("   FAIL the alternating tripod is not what the text says"); fails += 1

	# 6. eight
	var eight := ring(8, 0.4)
	var tetra := can_lift(keep(eight, [0, 2, 4, 6]), com)
	var half := can_lift(keep(eight, [0, 1, 2, 3]), com)
	print("6  eight: lift alternate four: %s (must be true); lift one half: %s (must be false)" % [tetra, half])
	if not tetra or half:
		print("   FAIL eight legs did not behave"); fails += 1

	print("")
	print("PROBE %s" % ("OK" if fails == 0 else "FAILED %d" % fails))
	quit(fails)
