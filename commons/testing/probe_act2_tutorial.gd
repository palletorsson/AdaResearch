extends SceneTree
## Act II's arithmetic must be TRUE. Functions copied verbatim from
## Vectors_Act2_VectorArithmetic/tutorial.md and asked questions with known
## answers.
##
##   1  head_to_tail closes the walk: the third point is a + b
##   2  difference is the arrow from b's tip to a's tip
##   3  weight_of keeps the line (straight down) and scales the length
##   4  agreement: same direction 1, square 0, opposed -1; angle_between(RIGHT, UP) = 90
##   5  project + reject add back to a, and reject is square to the rail
##   6  torque of a push ALONG the arm is zero; square to it, |r||F|   <- the negative
##   7  "the same question in opposite directions": |r x F| equals |r| times what
##      is left of F after wasted_half is removed

func head_to_tail(a: Vector3, b: Vector3) -> Array[Vector3]:
	var origin := Vector3.ZERO
	return [origin, a, a + b]

func difference(a: Vector3, b: Vector3) -> Vector3:
	var b_flipped := -b
	return a + b_flipped

func weight_of(mass: float) -> Vector3:
	return Vector3.DOWN * 9.8 * mass

func agreement(a: Vector3, b: Vector3) -> float:
	return clampf(a.normalized().dot(b.normalized()), -1.0, 1.0)

func angle_between(a: Vector3, b: Vector3) -> float:
	return rad_to_deg(acos(agreement(a, b)))

func project(a: Vector3, onto: Vector3) -> Vector3:
	var n := onto.normalized()
	return n * a.dot(n)

func reject(a: Vector3, onto: Vector3) -> Vector3:
	return a - project(a, onto)

func torque(arm: Vector3, force: Vector3) -> Vector3:
	return arm.cross(force)

func wasted_half(arm: Vector3, force: Vector3) -> Vector3:
	var r := arm.normalized()
	return r * force.dot(r)

func _init() -> void:
	var fails := 0
	var a := Vector3(2, 0, 1)
	var b := Vector3(-1, 3, 2)

	var walk := head_to_tail(a, b)
	print("1  walk %s -> closes at %s (must be a + b = %s)" % [walk, walk[2], a + b])
	if not walk[2].is_equal_approx(a + b):
		print("   FAIL the walk does not close"); fails += 1

	var d := difference(a, b)
	print("2  a - b = %s; from b's tip to a's tip = %s" % [d, a - b])
	if not d.is_equal_approx(a - b):
		print("   FAIL subtraction is not the gap"); fails += 1

	var w1 := weight_of(1.0); var w3 := weight_of(3.0)
	print("3  weight of 1 kg %s, of 3 kg %s: same line=%s, length x3=%s" % [w1, w3, w1.normalized().is_equal_approx(w3.normalized()), absf(w3.length() - 3.0 * w1.length()) < 1e-6])
	if not w1.normalized().is_equal_approx(w3.normalized()) or absf(w3.length() - 3.0 * w1.length()) > 1e-6:
		print("   FAIL the scalar turned the line"); fails += 1

	var same := agreement(Vector3.RIGHT, Vector3.RIGHT * 5)
	var sq := agreement(Vector3.RIGHT, Vector3.UP)
	var opp := agreement(Vector3.RIGHT, Vector3.LEFT)
	var ang := angle_between(Vector3.RIGHT, Vector3.UP)
	print("4  agreement same %.2f square %.2f opposed %.2f; angle RIGHT/UP %.1f (must be 1 / 0 / -1 / 90)" % [same, sq, opp, ang])
	if absf(same - 1.0) > 1e-6 or absf(sq) > 1e-6 or absf(opp + 1.0) > 1e-6 or absf(ang - 90.0) > 1e-4:
		print("   FAIL agreement is not cos of the angle"); fails += 1

	var rail := Vector3(1, 1, 0)
	var p := project(a, rail); var q := reject(a, rail)
	print("5  project %s + reject %s = %s (must be a = %s); reject . rail = %.6f (must be 0)" % [p, q, p + q, a, q.dot(rail)])
	if not (p + q).is_equal_approx(a) or absf(q.dot(rail)) > 1e-6:
		print("   FAIL the split does not add back, or is not square"); fails += 1

	var arm := Vector3(2, 0, 0)
	var along := torque(arm, Vector3(5, 0, 0))
	var across := torque(arm, Vector3(0, 0, 5))
	print("6  push along the arm: torque %s (must be zero); across: |torque| %.2f (must be |r||F| = 10)" % [along, across.length()])
	if along.length() > 1e-6 or absf(across.length() - 10.0) > 1e-6:
		print("   FAIL the cross product does not discard the along part"); fails += 1

	var F := Vector3(3, 4, 1)
	var arm2 := Vector3(0, 0, 2)
	var left_over := F - wasted_half(arm2, F)
	var lhs := torque(arm2, F).length()
	var rhs := arm2.length() * left_over.length()
	print("7  |r x F| = %.4f; |r| x |F - wasted_half| = %.4f (must be equal)" % [lhs, rhs])
	if absf(lhs - rhs) > 1e-4:
		print("   FAIL dot and cross are not the same question in opposite directions"); fails += 1

	print("")
	print("PROBE %s" % ("OK" if fails == 0 else "FAILED %d" % fails))
	quit(fails)
