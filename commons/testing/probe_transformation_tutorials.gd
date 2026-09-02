extends SceneTree
## The transformation chapter's claims must be TRUE. Functions copied from the
## seven Trans_* tutorial.md files (srt, combine, invert, components, reconstruct,
## component_along, project_onto_plane, volume_ratio, the pusher's triangle wave,
## the grower) and asked questions with known answers.
##
##   1  a transformation is named by what it refuses to change: translate keeps lengths,
##      angles, area; rotate keeps them too; scale keeps angles and ratios only; shear keeps none
##   2  order matters: S then R then T lands elsewhere than T then R then S
##   3  a * b applies b first; t * invert(t) is identity
##   4  every displacement is three: components reconstruct exactly; component_along; project
##   5  sameness of form: a square turned a quarter is the same square, turned an eighth is not
##   6  3D rotations do not commute; rotation and UNIFORM scale do; rotation and non-uniform do not
##   7  double the length, eight times the volume
##   8  the tunnel: 18 segments at 10 degrees is a half turn over 51 m; the cake's top layer
##      turns 1.2^7 = 3.58 times the base
##   9  the pit: the pusher's triangle wave never leaves [0, distance]; the grower saturates

func srt(position: Vector3, rotation_rad: Vector3, scale_factors: Vector3) -> Transform3D:
	var t := Transform3D.IDENTITY
	t = t.scaled(scale_factors)
	t = t.rotated(Vector3.UP, rotation_rad.y)
	t = t.rotated(Vector3.RIGHT, rotation_rad.x)
	t = t.rotated(Vector3.FORWARD, rotation_rad.z)
	t.origin = position
	return t

func combine(a: Transform3D, b: Transform3D) -> Transform3D:
	return a * b

func invert(t: Transform3D) -> Transform3D:
	return t.affine_inverse()

func components_on_axes(v: Vector3) -> Array:
	return [v.x, v.y, v.z]

func component_along(v: Vector3, axis: Vector3) -> float:
	return v.dot(axis.normalized())

func reconstruct(cx: float, cy: float, cz: float) -> Vector3:
	return Vector3.RIGHT * cx + Vector3.UP * cy + Vector3.FORWARD * cz

func project_onto_plane(v: Vector3, plane_normal: Vector3) -> Vector3:
	return v - v.project(plane_normal)

func volume_ratio(before: Vector3, after: Vector3) -> float:
	return (after.x * after.y * after.z) / (before.x * before.y * before.z)

func tri_measures(a: Vector3, b: Vector3, c: Vector3) -> Dictionary:
	var ab := a.distance_to(b); var bc := b.distance_to(c); var ca := c.distance_to(a)
	var area := 0.5 * (b - a).cross(c - a).length()
	var angle_a := (b - a).angle_to(c - a)
	return {"sides": [ab, bc, ca], "area": area, "angle_a": angle_a}

func same_set(p: Array, q: Array) -> bool:
	for u in p:
		var found := false
		for w in q:
			if u.is_equal_approx(w): found = true
		if not found: return false
	return true

func _init() -> void:
	var fails := 0
	var A := Vector3(0, 0, 0); var B := Vector3(1, 0, 0); var C := Vector3(0, 0, 1)   # a right triangle on the floor
	var m0 := tri_measures(A, B, C)

	# 1. what each refuses to change
	var T := Transform3D.IDENTITY.translated(Vector3(3, 0, -2))
	var R := Transform3D.IDENTITY.rotated(Vector3.UP, 0.7)
	var S := Transform3D.IDENTITY.scaled(Vector3(2, 2, 2))
	var H := Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0.6, 0, 1)), Vector3.ZERO)   # shear
	var out := []
	for pair in [["translate", T], ["rotate", R], ["scale", S], ["shear", H]]:
		var t: Transform3D = pair[1]
		var m := tri_measures(t * A, t * B, t * C)
		var keeps_len: bool = absf(m["sides"][0] - m0["sides"][0]) < 1e-6 and absf(m["sides"][1] - m0["sides"][1]) < 1e-6
		var keeps_angle: bool = absf(m["angle_a"] - m0["angle_a"]) < 1e-6
		var keeps_area: bool = absf(m["area"] - m0["area"]) < 1e-6
		out.append("%s keeps lengths %s angle %s area %s" % [pair[0], keeps_len, keeps_angle, keeps_area])
		if pair[0] == "translate" and not (keeps_len and keeps_angle and keeps_area): fails += 1
		if pair[0] == "rotate" and not (keeps_len and keeps_angle and keeps_area): fails += 1
		if pair[0] == "scale" and (keeps_len or not keeps_angle or keeps_area): fails += 1
		if pair[0] == "shear" and (keeps_len or keeps_angle): fails += 1
	print("1  " + "; ".join(out) + "  (translate and rotate keep all three; scale keeps only the angle; shear keeps neither length nor angle)")

	# 2. order matters
	var p := Vector3(1, 0, 0)
	var a_srt := srt(Vector3(1, 0, 0), Vector3(0, PI / 2, 0), Vector3(2, 1, 1)) * p
	var trs := Transform3D.IDENTITY
	trs.origin = Vector3(1, 0, 0)
	trs = trs.rotated(Vector3.UP, PI / 2)
	trs = trs.scaled(Vector3(2, 1, 1))
	var a_trs := trs * p
	print("2  the point (1,0,0) lands at %s under scale-rotate-translate and at %s under translate-rotate-scale (must differ)" % [a_srt, a_trs])
	if a_srt.is_equal_approx(a_trs):
		print("   FAIL order did not matter"); fails += 1

	# 3. a * b applies b first; t * invert(t) is identity
	var ab := combine(T, R) * p          # rotate first, then translate
	var by_hand := T * (R * p)
	var ident := combine(srt(Vector3(1, 2, 3), Vector3(0.3, 0.5, 0.1), Vector3(2, 3, 4)), invert(srt(Vector3(1, 2, 3), Vector3(0.3, 0.5, 0.1), Vector3(2, 3, 4))))
	print("3  (T*R)*p = %s equals T*(R*p) = %s: %s; t * invert(t) is identity: %s" % [ab, by_hand, ab.is_equal_approx(by_hand), ident.is_equal_approx(Transform3D.IDENTITY)])
	if not ab.is_equal_approx(by_hand) or not ident.is_equal_approx(Transform3D.IDENTITY):
		print("   FAIL composition or inverse is wrong"); fails += 1

	# 4. every displacement is three
	var v := Vector3(2.5, -1.25, 0.75)
	var comps: Array = components_on_axes(v)
	var back := reconstruct(comps[0], comps[1], comps[2])
	var along := component_along(v, Vector3(1, 0, 0))
	var flat := project_onto_plane(v, Vector3.UP)
	print("4  %s -> components %s -> reconstructed %s (must match; note FORWARD is -Z, so the z component enters with a sign); along x %.2f; onto the floor %s (y must be 0)" % [v, comps, back, along, flat])
	if not back.is_equal_approx(Vector3(v.x, v.y, -v.z)) or absf(along - 2.5) > 1e-6 or absf(flat.y) > 1e-9:
		print("   FAIL decomposition did not reconstruct as the tutorial's basis says"); fails += 1

	# 5. sameness of form
	var square: Array = [Vector3(1, 0, 1), Vector3(-1, 0, 1), Vector3(-1, 0, -1), Vector3(1, 0, -1)]
	var quarter: Array = []; var eighth: Array = []
	for q in square:
		quarter.append(q.rotated(Vector3.UP, PI / 2)); eighth.append(q.rotated(Vector3.UP, PI / 4))
	var same_q := same_set(square, quarter); var same_e := same_set(square, eighth)
	print("5  a square turned a quarter is the same set of corners: %s (must be true); turned an eighth: %s (must be false)" % [same_q, same_e])
	if not same_q or same_e:
		print("   FAIL sameness of form is not where the text says"); fails += 1

	# 6. commuting
	var rx := Basis(Vector3.RIGHT, PI / 2); var ry := Basis(Vector3.UP, PI / 2)
	var xy := (rx * ry) * p; var yx := (ry * rx) * p
	var uni := Basis.from_scale(Vector3(2, 2, 2)); var non := Basis.from_scale(Vector3(2, 1, 1))
	var ru := (R.basis * uni) * Vector3(1, 0, 1); var ur := (uni * R.basis) * Vector3(1, 0, 1)
	var rn := (R.basis * non) * Vector3(1, 0, 1); var nr := (non * R.basis) * Vector3(1, 0, 1)
	print("6  Rx then Ry sends (1,0,0) to %s, Ry then Rx to %s (must differ); rotation with uniform scale commutes: %s (must); with non-uniform: %s (must not)" % [yx, xy, ru.is_equal_approx(ur), rn.is_equal_approx(nr)])
	if xy.is_equal_approx(yx) or not ru.is_equal_approx(ur) or rn.is_equal_approx(nr):
		print("   FAIL the commuting claims are wrong"); fails += 1

	# 7. volume
	var vr := volume_ratio(Vector3.ONE, Vector3(2, 2, 2))
	print("7  double every length: volume x %.1f (must be 8)" % vr)
	if absf(vr - 8.0) > 1e-9:
		print("   FAIL volume is not cubic"); fails += 1

	# 8. the tunnel and the cake
	var twist := 18 * 10.0; var length := 17 * 3.0; var top := pow(1.2, 7)
	print("8  tunnel: 18 segments x 10 deg = %.0f deg of twist over %.0f m; cake: top of 8 layers turns %.2f x the base" % [twist, length, top])
	if absf(twist - 180.0) > 1e-9 or absf(length - 51.0) > 1e-9 or absf(top - 3.583) > 0.01:
		print("   FAIL the tunnel or cake arithmetic is off"); fails += 1

	# 9. the pit
	var phase := 0.0; var lo := INF; var hi := -INF
	for i in 2000:
		phase = fmod(phase + (1.0 / 60.0) * 1.5 / 3.0, 2.0)
		var tt: float = phase if phase < 1.0 else 2.0 - phase
		var x := 3.0 * tt; lo = minf(lo, x); hi = maxf(hi, x)
	var cur := 0.3; var reached := 0.0
	for i in 2000:
		cur = minf(3.5, cur + 0.3 * (1.0 / 60.0))
		if cur >= 3.5 and reached == 0.0: reached = i / 60.0
	print("9  pusher (distance 3, speed 1.5) travels between %.3f and %.3f m; grower from 0.3 reaches 3.5 after %.1f s and stops" % [lo, hi, reached])
	if lo < -1e-6 or hi > 3.0 + 1e-6 or reached <= 0.0 or absf(cur - 3.5) > 1e-9:
		print("   FAIL the pit's motions are not bounded as the text says"); fails += 1

	print("")
	print("PROBE %s" % ("OK" if fails == 0 else "FAILED %d" % fails))
	quit(fails)
