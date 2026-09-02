extends SceneTree
## The triangle room's tutorial code must be TRUE, not just plausible. Each
## function is copied here verbatim from tutorial.md and asked a question with
## a known answer -- a number the probe can be wrong about.
##
##   1  third_vertex(3, 4, 5) lands at (0, 4): the 3-4-5 triangle is right-angled
##      at the origin, so Pythagoras alone placed the corner
##   2  the mirror (x, -y) has the SAME three lengths        <- the "plus its reflection"
##   3  quad_from_rods keeps all four lengths for two different leans   <- "four rods lean"
##   4  is_planar: three points always pass; a lifted fourth fails  <- negative
##   5  faces_you flips when two corners are swapped         <- "the order decides the front"
##   6  fan_triangulate(n points) gives n - 2 triangles

func triangle_normal(a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	return (b - a).cross(c - a).normalized()

func triangle_area(a: Vector3, b: Vector3, c: Vector3) -> float:
	return (b - a).cross(c - a).length() * 0.5

func fan_triangulate(loop: Array[Vector3]) -> Array:
	var tris: Array = []
	for i in range(1, loop.size() - 1):
		tris.append([loop[0], loop[i], loop[i + 1]])
	return tris

func third_vertex(a: float, b: float, c: float) -> Vector2:
	var x := (a * a + b * b - c * c) / (2.0 * a)
	var y := sqrt(maxf(b * b - x * x, 0.0))
	return Vector2(x, y)

func quad_from_rods(a: float, b: float, lean: Vector2) -> Array[Vector2]:
	lean = lean.normalized() * b
	return [Vector2.ZERO, Vector2(a, 0.0), Vector2(a, 0.0) + lean, lean]

func is_planar(p: Array[Vector3], tol: float = 0.001) -> bool:
	var n := (p[1] - p[0]).cross(p[2] - p[0]).normalized()
	return absf((p[3] - p[0]).dot(n)) < tol

func faces_you(a: Vector3, b: Vector3, c: Vector3, eye: Vector3) -> bool:
	return triangle_normal(a, b, c).dot(eye - a) > 0.0

func _sides(q: Array[Vector2]) -> Array:
	var out: Array = []
	for i in q.size():
		out.append(q[i].distance_to(q[(i + 1) % q.size()]))
	return out

func _init() -> void:
	var fails := 0

	# 1. the 3-4-5
	var p := third_vertex(3.0, 4.0, 5.0)
	print("1  third_vertex(3,4,5) = (%.3f, %.3f)  (must be (0, 4))" % [p.x, p.y])
	if not (absf(p.x) < 1e-4 and absf(p.y - 4.0) < 1e-4):
		print("   FAIL Pythagoras did not place the corner"); fails += 1
	var A := Vector2.ZERO; var B := Vector2(3, 0)
	print("   lengths: |AP|=%.3f |BP|=%.3f (must be 4, 5)" % [A.distance_to(p), B.distance_to(p)])

	# 2. the mirror keeps the lengths
	var pm := Vector2(p.x, -p.y)
	var same: bool = absf(A.distance_to(pm) - 4.0) < 1e-4 and absf(B.distance_to(pm) - 5.0) < 1e-4
	print("2  mirrored corner has the same lengths: %s" % same)
	if not same:
		print("   FAIL the reflection is not the same triangle"); fails += 1

	# 3. four rods lean without changing length
	var q1 := quad_from_rods(2.0, 1.5, Vector2(0, 1))
	var q2 := quad_from_rods(2.0, 1.5, Vector2(1, 1))
	var s1 := _sides(q1); var s2 := _sides(q2)
	var kept := true
	for i in 4:
		if absf(float(s1[i]) - float(s2[i])) > 1e-4:
			kept = false
	var moved: bool = q1[2].distance_to(q2[2]) > 0.1
	print("3  two leans: sides %s vs %s -> lengths kept=%s, shape moved=%s" % [s1, s2, kept, moved])
	if not (kept and moved):
		print("   FAIL four rods did not lean, or leaned by changing length"); fails += 1

	# 4. planarity: three always, a lifted fourth never
	var flat: Array[Vector3] = [Vector3(0,0,0), Vector3(1,0,0), Vector3(1,0,1), Vector3(0,0,1)]
	var bent: Array[Vector3] = [Vector3(0,0,0), Vector3(1,0,0), Vector3(1,0,1), Vector3(0,0.3,1)]
	print("4  flat quad planar=%s, lifted corner planar=%s (must be true / false)" % [is_planar(flat), is_planar(bent)])
	if not is_planar(flat) or is_planar(bent):
		print("   FAIL planarity test does not bite"); fails += 1

	# 5. winding decides the front
	var a := Vector3(0,0,0); var b := Vector3(1,0,0); var c := Vector3(0,1,0)
	var eye := Vector3(0.3, 0.3, 2.0)
	var f1 := faces_you(a, b, c, eye); var f2 := faces_you(a, c, b, eye)
	print("5  faces_you(a,b,c)=%s  faces_you(a,c,b)=%s (must differ)" % [f1, f2])
	if f1 == f2:
		print("   FAIL swapping two corners did not flip the face"); fails += 1

	# 6. n - 2
	var loop: Array[Vector3] = [Vector3(0,0,0), Vector3(1,0,0), Vector3(1.5,0,1), Vector3(0.5,0,1.6), Vector3(-0.5,0,1)]
	var tris := fan_triangulate(loop)
	print("6  a 5-point loop fans into %d triangles (must be 3)" % tris.size())
	if tris.size() != 3:
		print("   FAIL n - 2 does not hold"); fails += 1
	var total := 0.0
	for t in tris:
		total += triangle_area(t[0], t[1], t[2])
	print("   fan area = %.3f" % total)

	print("")
	print("PROBE %s" % ("OK" if fails == 0 else "FAILED %d" % fails))
	quit(fails)
