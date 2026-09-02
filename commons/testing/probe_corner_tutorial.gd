extends SceneTree
## The corner room's tutorial code must be TRUE. Functions copied verbatim from
## Primitives_Polythedra/tutorial.md and asked questions with known answers.
##
##   1  a cube corner is 90 short; a regular tetrahedron corner is 180 short
##   2  six equilateral triangles around a point: defect 0 (flat)   <- the KEEP line
##   3  five: defect 60 (rises)
##   4  DESCARTES: the cube's 8 corners and the tetrahedron's 4 both total 720
##   5  move one vertex of the tetrahedron: corners change, total still 720
##   6  euler: 8-12+6 and 4-6+4 are both 2; a wrong count is refused  <- negative

func face_angle_at(apex: Vector3, p: Vector3, q: Vector3) -> float:
	return rad_to_deg((p - apex).angle_to(q - apex))

func corner_defect(apex: Vector3, ring: Array) -> float:
	var total := 0.0
	for i in ring.size():
		total += face_angle_at(apex, ring[i], ring[(i + 1) % ring.size()])
	return 360.0 - total

func total_defect(corners: Dictionary) -> float:
	var sum := 0.0
	for apex in corners:
		sum += corner_defect(apex, corners[apex])
	return sum

func euler_check(V: int, E: int, F: int) -> bool:
	return V - E + F == 2

func _cube_corners() -> Dictionary:
	var d := {}
	for sx in [-1, 1]:
		for sy in [-1, 1]:
			for sz in [-1, 1]:
				var v := Vector3(sx, sy, sz)
				# the three neighbours, ordered around the corner (any cyclic order works for 3)
				d[v] = [Vector3(-sx, sy, sz), Vector3(sx, -sy, sz), Vector3(sx, sy, -sz)]
	return d

func _tetra_corners(verts: Array) -> Dictionary:
	var d := {}
	for i in 4:
		var ring := []
		for j in 4:
			if j != i:
				ring.append(verts[j])
		d[verts[i]] = ring
	return d

func _init() -> void:
	var fails := 0
	var near := func(a: float, b: float) -> bool: return absf(a - b) < 0.01

	# 1. single corners
	var cube := _cube_corners()
	var cd: float = corner_defect(Vector3(1, 1, 1), cube[Vector3(1, 1, 1)])
	var tv: Array = [Vector3(1, 1, 1), Vector3(1, -1, -1), Vector3(-1, 1, -1), Vector3(-1, -1, 1)]
	var tetra := _tetra_corners(tv)
	var td: float = corner_defect(tv[0], tetra[tv[0]])
	print("1  cube corner defect %.2f (must be 90); tetrahedron corner defect %.2f (must be 180)" % [cd, td])
	if not near.call(cd, 90.0) or not near.call(td, 180.0):
		print("   FAIL a corner's defect is wrong"); fails += 1

	# 2 + 3. six around a point lie flat; five rise
	var ring6: Array = []
	for k in 6:
		var ang := deg_to_rad(60.0 * k)
		ring6.append(Vector3(cos(ang), 0, sin(ang)))
	var d6: float = corner_defect(Vector3.ZERO, ring6)
	print("2  six equilateral around a point: defect %.2f (must be 0)" % d6)
	if not near.call(d6, 0.0):
		print("   FAIL six do not lie flat"); fails += 1

	# Five equilateral triangles CANNOT lie flat: five 60-degree wedges laid in a
	# plane close with a 120-degree gap, which is not five equilaterals. They can
	# only meet by rising -- which is the room's claim. The real corner is an
	# icosahedron vertex: five neighbours at 72 degrees on a ring of radius 1,
	# apex lifted so each adjacent pair subtends exactly 60 degrees. That height
	# is sqrt(1 - 2 cos 72) = 0.618..., the golden ratio minus one.
	var flat5: Array = []
	for k in 5:
		var ang := deg_to_rad(60.0 * k)
		flat5.append(Vector3(cos(ang), 0, sin(ang)))
	var d5flat: float = corner_defect(Vector3.ZERO, flat5)
	var h := sqrt(1.0 - 2.0 * cos(deg_to_rad(72.0)))
	var ring5: Array = []
	for k in 5:
		var ang := deg_to_rad(72.0 * k)
		ring5.append(Vector3(cos(ang), 0, sin(ang)))
	var apex5 := Vector3(0, h, 0)
	var a01: float = face_angle_at(apex5, ring5[0], ring5[1])
	var d5: float = corner_defect(apex5, ring5)
	print("3  five wedges laid flat close with a %.0f-degree gap (defect %.2f: not five equilaterals);" % [360.0 - 240.0, d5flat])
	print("   five equilaterals meeting at a lifted apex: each %.2f degrees, defect %.2f (must be 60 / 60)" % [a01, d5])
	if not near.call(a01, 60.0) or not near.call(d5, 60.0):
		print("   FAIL the KEEP line is not true of the code"); fails += 1

	# 4. Descartes
	var tc: float = total_defect(cube)
	var tt: float = total_defect(tetra)
	print("4  total defect: cube %.2f, tetrahedron %.2f (both must be 720)" % [tc, tt])
	if not near.call(tc, 720.0) or not near.call(tt, 720.0):
		print("   FAIL Descartes does not hold"); fails += 1

	# 5. move a vertex: corners change, the total does not
	var moved: Array = tv.duplicate()
	moved[0] = Vector3(1.0, 2.3, 0.6)
	var tetra2 := _tetra_corners(moved)
	var c0_before: float = corner_defect(tv[0], tetra[tv[0]])
	var c0_after: float = corner_defect(moved[0], tetra2[moved[0]])
	var tt2: float = total_defect(tetra2)
	print("5  apex moved: that corner %.2f -> %.2f (must change); total %.2f (must still be 720)" % [c0_before, c0_after, tt2])
	if near.call(c0_before, c0_after) or not near.call(tt2, 720.0):
		print("   FAIL face-shift did not conserve the total, or did not change the corner"); fails += 1

	# 6. Euler, and its negative
	var ok_cube := euler_check(8, 12, 6)
	var ok_tet := euler_check(4, 6, 4)
	var bad := euler_check(8, 12, 7)
	print("6  euler cube=%s tetra=%s wrong-count=%s (must be true / true / false)" % [ok_cube, ok_tet, bad])
	if not ok_cube or not ok_tet or bad:
		print("   FAIL the count does not bite"); fails += 1

	print("")
	print("PROBE %s" % ("OK" if fails == 0 else "FAILED %d" % fails))
	quit(fails)
