extends SceneTree
## The Melencolia room's code must be TRUE. Functions copied verbatim from
## Primitives_Melencolia/tutorial.md and asked questions with known answers.
##
##   1  all sixteen lines of Durer's square sum to 34
##   2  the bottom row's middle two are 15 and 14: the year
##   3  it is complete: every number 1..16 exactly once
##   4  NEGATIVE: swap two cells and the lines break, so the check bites
##   5  the cut cube: 12, 18, 8, Euler 2
##   6  go_anywhere returns a Vector3 for a hundred random transforms

func durer_square() -> Array:
	return [[16, 3, 2, 13],
			[5, 10, 11, 8],
			[9, 6, 7, 12],
			[4, 15, 14, 1]]

func line_sums(sq: Array) -> Array:
	var sums: Array = []
	for r in 4:
		sums.append(sq[r][0] + sq[r][1] + sq[r][2] + sq[r][3])
	for c in 4:
		sums.append(sq[0][c] + sq[1][c] + sq[2][c] + sq[3][c])
	sums.append(sq[0][0] + sq[1][1] + sq[2][2] + sq[3][3])
	sums.append(sq[0][3] + sq[1][2] + sq[2][1] + sq[3][0])
	sums.append(sq[0][0] + sq[0][3] + sq[3][0] + sq[3][3])
	sums.append(sq[1][1] + sq[1][2] + sq[2][1] + sq[2][2])
	for qr in [0, 2]:
		for qc in [0, 2]:
			sums.append(sq[qr][qc] + sq[qr][qc + 1] + sq[qr + 1][qc] + sq[qr + 1][qc + 1])
	return sums

func is_complete(sq: Array) -> bool:
	var seen: Array = []
	for row in sq:
		for v in row:
			seen.append(v)
	seen.sort()
	return seen == range(1, 17)

func cut_cube_counts() -> Dictionary:
	var v := 8 - 2 + 6
	var e := 12 + 6
	var f := 6 + 2
	return {"vertices": v, "edges": e, "faces": f, "euler": v - e + f}

func go_anywhere(from: Vector3, by: Transform3D) -> Vector3:
	return by * from

func _init() -> void:
	var fails := 0
	var sq := durer_square()

	# 1. sixteen lines of 34
	var sums := line_sums(sq)
	var all34 := true
	for s in sums:
		if int(s) != 34:
			all34 = false
	print("1  %d lines, all 34: %s  %s" % [sums.size(), all34, sums])
	if sums.size() != 16 or not all34:
		print("   FAIL the square is not magic on every line"); fails += 1

	# 2. the year
	print("2  bottom row %s: middle two read %d%d (must be 1514)" % [sq[3], sq[3][1], sq[3][2]])
	if sq[3][1] != 15 or sq[3][2] != 14:
		print("   FAIL the date is not in the square"); fails += 1

	# 3. complete
	print("3  uses 1..16 exactly once: %s" % is_complete(sq))
	if not is_complete(sq):
		print("   FAIL something is missing or repeated"); fails += 1

	# 4. NEGATIVE: break it
	var broken := durer_square()
	var tmp = broken[0][0]
	broken[0][0] = broken[0][1]
	broken[0][1] = tmp
	var bad := 0
	for s in line_sums(broken):
		if int(s) != 34:
			bad += 1
	print("4  swap two cells: %d of 16 lines no longer 34 (must be > 0)" % bad)
	if bad == 0:
		print("   FAIL the check cannot fail"); fails += 1
	if not is_complete(broken):
		print("   (note) a swap keeps the set complete, as it should");

	# 5. the solid
	var cc := cut_cube_counts()
	print("5  cut cube: %s (must be 12 / 18 / 8 / euler 2)" % [cc])
	if cc["vertices"] != 12 or cc["edges"] != 18 or cc["faces"] != 8 or cc["euler"] != 2:
		print("   FAIL the last solid does not count"); fails += 1

	# 6. closure
	var rng := RandomNumberGenerator.new()
	rng.seed = 1514
	var inside := true
	var p := Vector3(1, 2, 3)
	for i in 100:
		var b := Basis(Vector3(rng.randf(), rng.randf(), rng.randf()).normalized(), rng.randf() * TAU)
		var t := Transform3D(b, Vector3(rng.randf_range(-9, 9), rng.randf_range(-9, 9), rng.randf_range(-9, 9)))
		p = go_anywhere(p, t)
		if not (is_finite(p.x) and is_finite(p.y) and is_finite(p.z)):
			inside = false
	print("6  a hundred random transforms: still a finite Vector3 = %s (last %s)" % [inside, p])
	if not inside:
		print("   FAIL a transform led out"); fails += 1

	print("")
	print("PROBE %s" % ("OK" if fails == 0 else "FAILED %d" % fails))
	quit(fails)
