extends SceneTree
## The Ignorance room's counting code must be TRUE. Functions copied verbatim
## from Primitives_Ignorance/tutorial.md and asked questions with known answers.
##
##   1  platonic_candidates() is exactly the five: (3,3) (3,4) (3,5) (4,3) (5,3)
##   2  720 / defect gives the vertex counts 4, 6, 12, 8, 20
##   3  six triangles, four squares, three hexagons leave defect 0  <- the negative: no sixth
##   4  prism_from_segments satisfies Euler for n = 3..12
##   5  has_centre_of_symmetry: even true, odd false, 3..9
##   6  the five-segment body: a vertex faces +X, and nothing faces -X   <- the capsule claim

func regular_corner_defect(face_sides: int, faces_at_vertex: int) -> float:
	var interior := 180.0 * (face_sides - 2) / face_sides
	return 360.0 - interior * faces_at_vertex

func platonic_candidates() -> Array:
	var out: Array = []
	for sides in [3, 4, 5, 6]:
		for k in [3, 4, 5, 6]:
			if regular_corner_defect(sides, k) > 0.0:
				out.append([sides, k])
	return out

func prism_from_segments(n: int) -> Dictionary:
	return {"faces": n + 2, "vertices": 2 * n, "edges": 3 * n}

func has_centre_of_symmetry(n: int) -> bool:
	for i in n:
		var p := Vector2.RIGHT.rotated(TAU * i / n)
		var back := -p
		var hit := false
		for j in n:
			if back.distance_to(Vector2.RIGHT.rotated(TAU * j / n)) < 0.0001:
				hit = true
		if not hit:
			return false
	return true

func _init() -> void:
	var fails := 0

	# 1. exactly five
	var c := platonic_candidates()
	var want := [[3, 3], [3, 4], [3, 5], [4, 3], [5, 3]]
	print("1  candidates: %s (must be %s)" % [c, want])
	if c != want:
		print("   FAIL the arithmetic did not leave five"); fails += 1

	# 2. 720 / defect = V
	var vs := []
	for pair in c:
		vs.append(int(round(720.0 / regular_corner_defect(pair[0], pair[1]))))
	print("2  vertex counts from 720/defect: %s (must be [4, 6, 12, 8, 20])" % [vs])
	if vs != [4, 6, 12, 8, 20]:
		print("   FAIL 720 over the defect is not the vertex count"); fails += 1

	# 3. the flat ones
	var flat := [regular_corner_defect(3, 6), regular_corner_defect(4, 4), regular_corner_defect(6, 3)]
	print("3  six triangles / four squares / three hexagons: defects %s (all must be 0)" % [flat])
	for d in flat:
		if absf(float(d)) > 0.001:
			print("   FAIL a flat arrangement was counted as a corner"); fails += 1

	# 4. prisms obey Euler
	var euler_ok := true
	for n in range(3, 13):
		var p := prism_from_segments(n)
		if p["vertices"] - p["edges"] + p["faces"] != 2:
			euler_ok = false
	print("4  prisms n=3..12 satisfy V - E + F = 2: %s" % euler_ok)
	if not euler_ok:
		print("   FAIL a prism broke Euler"); fails += 1

	# 5. centre of symmetry: even yes, odd no
	var sym := {}
	for n in range(3, 10):
		sym[n] = has_centre_of_symmetry(n)
	print("5  centre of symmetry 3..9: %s" % [sym])
	for n in range(3, 10):
		if sym[n] != (n % 2 == 0):
			print("   FAIL n=%d" % n); fails += 1

	# 6. the five-segment body, stated as a fact about faces: +X is a vertex, -X is not
	var five := []
	for i in 5:
		five.append(Vector2.RIGHT.rotated(TAU * i / 5))
	var front_is_vertex: bool = five[0].distance_to(Vector2.RIGHT) < 0.0001
	var back_is_vertex := false
	for v in five:
		if v.distance_to(Vector2.LEFT) < 0.0001:
			back_is_vertex = true
	print("6  pentagon: a vertex faces +X = %s, a vertex faces -X = %s (must be true / false)" % [front_is_vertex, back_is_vertex])
	if not front_is_vertex or back_is_vertex:
		print("   FAIL the back of the five-segment body is derivable from its front"); fails += 1

	print("")
	print("PROBE %s" % ("OK" if fails == 0 else "FAILED %d" % fails))
	quit(fails)
