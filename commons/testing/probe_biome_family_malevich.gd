extends SceneTree
## probe_biome_family_malevich.gd — the malevich composition family keeps its contract.
##
##   Godot_v4.6-stable_win64.exe --headless --path . --xr-mode off --script res://commons/testing/probe_biome_family_malevich.gd
##
## For 20 seeds (rng.seed = hash([seed, "score"]), as the vitrine seeds it), both sign pairs
## and two cage sizes (inner 2.0 and 11.5): the score carries the contract's keys; lift in
## 0.6..1.8; |a - b| >= 1.1 * inner; path(0) == a and path(1) == b; 41 path samples and 41
## across samples inside |x|, |z| <= inner with y = 0; across(±1) near the inner edge; the
## heading is the numerical tangent and stays 12..38 degrees off a wall (the family's own
## claim); two rngs on one seed give equal dictionaries; the x mirror and the z mirror of a
## seed are the seed's mirror image. At inner 2.0 (the 5 m cage, k = 1) the elements as the
## vitrine places them do not collide — the moving boundary wall is excluded, it sweeps
## through every family's point by design. Then an ASCII plan of seed 7 at inner 2.0.
## Exits 1 on any failed check. No scene is built; quit() is called from _initialize().

const FAMILY := preload("res://commons/biome_layers/families/malevich.gd")
const SEEDS := 20
const SAMPLES := 41
const EPS := 1e-4
## the vitrine's element placement for the 5 m cage (k = 1): t or u, height x lift, extent
const GLASS_M := 0.5 # the inner bound sits 0.5 m inside the glass

var _checks := 0
var _fails := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails += 1
		print("  FAIL  ", msg)


func _initialize() -> void:
	_check(FAMILY.NAME == "malevich", "NAME is the token value")
	_check(FAMILY.REFERENCE.begins_with("Kazimir Malevich"), "REFERENCE names the painter")
	_check(FAMILY.LINE.length() > 20, "LINE is a sentence")
	for inner in [2.0, 11.5]:
		for signs in [[1.0, 1.0], [-1.0, -1.0], [1.0, -1.0], [-1.0, 1.0]]:
			for seed in range(SEEDS):
				_probe_seed(seed, float(inner), float(signs[0]), float(signs[1]))
	_plan(7, 2.0)
	print("[probe_biome_family_malevich] %d checks, %d failed" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


func _score(seed: int, inner: float, sx: float, sz: float) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "score"])
	return FAMILY.score(rng, inner, sx, sz)


func _inside(p: Vector3, inner: float) -> bool:
	return absf(p.x) <= inner + 1e-6 and absf(p.z) <= inner + 1e-6


## the acute angle, in degrees, between a heading (radians about +y) and the nearest wall
func _off_wall_deg(h: float) -> float:
	var d: float = fmod(absf(rad_to_deg(h)), 90.0)
	return minf(d, 90.0 - d)


func _probe_seed(seed: int, inner: float, sx: float, sz: float) -> void:
	var tag := "seed %d inner %.1f sx %+.0f sz %+.0f" % [seed, inner, sx, sz]
	var s: Dictionary = _score(seed, inner, sx, sz)
	# the contract's keys
	for key in ["a", "b", "lift", "tilt0", "tilt1"]:
		_check(s.has(key), "%s: has %s" % [tag, key])
	for key in s.keys():
		var k := String(key)
		_check(k in ["a", "b", "lift", "tilt0", "tilt1"] or k.begins_with("malevich_"), "%s: key %s is contract or private" % [tag, k])
	var a: Vector3 = s["a"]
	var b: Vector3 = s["b"]
	var lift: float = float(s["lift"])
	_check(lift >= 0.6 and lift <= 1.8, "%s: lift %.3f in 0.6..1.8" % [tag, lift])
	_check(is_zero_approx(a.y) and is_zero_approx(b.y), "%s: a, b on the floor" % tag)
	_check(a.distance_to(b) >= 1.1 * inner, "%s: span %.3f >= %.3f" % [tag, a.distance_to(b), 1.1 * inner])
	_check(FAMILY.path(s, 0.0).distance_to(a) < EPS, "%s: path(0) == a" % tag)
	_check(FAMILY.path(s, 1.0).distance_to(b) < EPS, "%s: path(1) == b" % tag)
	# the planes are nearly flat: tilt 90 is horizontal (measured), so |tilt| in 76..86
	_check(absf(float(s["tilt0"])) >= 76.0 and absf(float(s["tilt0"])) <= 86.0, "%s: tilt0 %.1f nearly flat" % [tag, float(s["tilt0"])])
	_check(absf(float(s["tilt1"])) >= 76.0 and absf(float(s["tilt1"])) <= 86.0, "%s: tilt1 %.1f nearly flat" % [tag, float(s["tilt1"])])
	# 41 path samples: bounds, y = 0, heading = tangent, heading an odd angle
	var path_ok := true
	var head_ok := true
	var odd_ok := true
	for i in range(SAMPLES):
		var t: float = float(i) / float(SAMPLES - 1)
		var p: Vector3 = FAMILY.path(s, t)
		if not _inside(p, inner) or not is_zero_approx(p.y):
			path_ok = false
		var h: float = FAMILY.heading(s, t)
		var dt := 1e-3
		var tv: Vector3 = FAMILY.path(s, minf(t + dt, 1.0)) - FAMILY.path(s, maxf(t - dt, 0.0))
		var hn: float = atan2(tv.x, tv.z)
		if absf(angle_difference(h, hn)) > 1e-3:
			head_ok = false
		var off: float = _off_wall_deg(h)
		if off < 11.5 or off > 38.5:
			odd_ok = false
	_check(path_ok, "%s: 41 path samples inside |x|,|z| <= inner, y = 0" % tag)
	_check(head_ok, "%s: heading is the tangent's atan2(dx, dz)" % tag)
	_check(odd_ok, "%s: every heading 12..38 degrees off a wall" % tag)
	# 41 across samples: bounds, y = 0, the ends near the inner edge, u = 0 on the spine
	var across_ok := true
	for i in range(SAMPLES):
		var u: float = -1.0 + 2.0 * float(i) / float(SAMPLES - 1)
		var q: Vector3 = FAMILY.across(s, u)
		if not _inside(q, inner) or not is_zero_approx(q.y):
			across_ok = false
	_check(across_ok, "%s: 41 across samples inside |x|,|z| <= inner, y = 0" % tag)
	for u in [-1.0, 1.0]:
		var e: Vector3 = FAMILY.across(s, u)
		_check(maxf(absf(e.x), absf(e.z)) >= 0.9 * inner, "%s: across(%+.0f) near the inner edge (%.2f of it)" % [tag, u, maxf(absf(e.x), absf(e.z)) / inner])
	_check(FAMILY.across(s, 0.0).distance_to(FAMILY.path(s, FAMILY.PHI)) < EPS, "%s: across(0) is the spine's golden section" % tag)
	# the shear: the across line scissors the flight axis (heading at t = 0, where the drift
	# has no slope yet) at 42..65 degrees, and is itself 22..35 degrees off a wall
	var ad: Vector3 = (FAMILY.across(s, 0.5) - FAMILY.across(s, -0.5)).normalized()
	var h0: float = FAMILY.heading(s, 0.0)
	var axis_dir := Vector3(sin(h0), 0.0, cos(h0))
	var scissor: float = rad_to_deg(acos(clampf(absf(ad.dot(axis_dir)), 0.0, 1.0)))
	_check(scissor > 41.0 and scissor < 66.0, "%s: across scissors the flight at 42..65 deg (%.1f)" % [tag, scissor])
	var across_off: float = _off_wall_deg(atan2(ad.x, ad.z))
	_check(across_off > 21.5 and across_off < 35.5, "%s: across 22..35 deg off a wall (%.1f)" % [tag, across_off])
	# +u is the weight side: the beam's side of the spine is the side the head drifted to
	var drift_side: Vector3 = FAMILY.path(s, 1.0) - FAMILY.path(s, 0.0)
	var perp := Vector3(-axis_dir.z, 0.0, axis_dir.x)
	var beam_side: float = signf((FAMILY.across(s, 0.55) - FAMILY.path(s, FAMILY.PHI)).dot(perp))
	_check(beam_side == signf(drift_side.dot(perp)), "%s: the beam (u > 0) sits on the side the flight drifts to" % tag)
	# determinism: two rngs on one seed
	var s2: Dictionary = _score(seed, inner, sx, sz)
	_check(s == s2 and str(s) == str(s2), "%s: two rngs on one seed give equal dictionaries" % tag)
	# mirrors: flipping sx mirrors x, flipping sz mirrors z, sample for sample
	var mx: Dictionary = _score(seed, inner, -sx, sz)
	var mz: Dictionary = _score(seed, inner, sx, -sz)
	var mirror_ok := true
	for i in range(SAMPLES):
		var t: float = float(i) / float(SAMPLES - 1)
		var u: float = -1.0 + 2.0 * t
		var p: Vector3 = FAMILY.path(s, t)
		var q: Vector3 = FAMILY.across(s, u)
		var px: Vector3 = FAMILY.path(mx, t)
		var qx: Vector3 = FAMILY.across(mx, u)
		var pz: Vector3 = FAMILY.path(mz, t)
		var qz: Vector3 = FAMILY.across(mz, u)
		if px.distance_to(Vector3(-p.x, 0.0, p.z)) > EPS or qx.distance_to(Vector3(-q.x, 0.0, q.z)) > EPS:
			mirror_ok = false
		if pz.distance_to(Vector3(p.x, 0.0, -p.z)) > EPS or qz.distance_to(Vector3(q.x, 0.0, -q.z)) > EPS:
			mirror_ok = false
	_check(mirror_ok, "%s: the x mirror and the z mirror are mirror images" % tag)
	if is_equal_approx(inner, 2.0):
		_probe_collisions(s, inner, tag)


## The elements as biome_vitrine._build_garden places them for k = 1, against each other
## and against the glass. Boxes use the vitrine's single yaw (the chord's), as today.
func _probe_collisions(s: Dictionary, inner: float, tag: String) -> void:
	var lift: float = float(s["lift"])
	var a: Vector3 = s["a"]
	var b: Vector3 = s["b"]
	var yaw: float = atan2((b - a).x, (b - a).z)
	var spheres: Array = [
		{"name": "point", "pos": _at(FAMILY.path(s, FAMILY.PHI), 1.25 * lift), "r": 0.15},
		{"name": "point2", "pos": _at(FAMILY.path(s, 0.15), 0.85 * lift), "r": 0.11},
		{"name": "sphere0", "pos": _at(FAMILY.path(s, 0.0), 0.45 * lift), "r": 0.45},
	]
	var boxes: Array = [
		{"name": "plane0", "pos": _at(FAMILY.path(s, 0.382), 1.5 * lift), "half": Vector3(0.8, 0.55, 0.015),
			"basis": Basis.from_euler(Vector3(deg_to_rad(float(s["tilt0"])), yaw, 0.0))},
		{"name": "plane1", "pos": _at(FAMILY.across(s, -0.6), 0.95 * lift), "half": Vector3(0.6, 0.4, 0.015),
			"basis": Basis.from_euler(Vector3(deg_to_rad(float(s["tilt1"])), yaw + PI * 0.5, 0.0))},
		{"name": "beam", "pos": _at(FAMILY.across(s, 0.55), 1.9 * lift), "half": Vector3(0.7, 0.15, 0.15),
			"basis": Basis.from_euler(Vector3(0.0, yaw + deg_to_rad(30.0), 0.0))},
		{"name": "cube", "pos": _at(FAMILY.path(s, 0.85), 0.35 * lift), "half": Vector3(0.35, 0.35, 0.35),
			"basis": Basis.from_euler(Vector3(0.0, yaw + deg_to_rad(15.0), 0.0))},
	]
	var margin := 0.02
	# sphere vs sphere
	for i in range(spheres.size()):
		for j in range(i + 1, spheres.size()):
			var d: float = (spheres[i]["pos"] as Vector3).distance_to(spheres[j]["pos"])
			_check(d > float(spheres[i]["r"]) + float(spheres[j]["r"]) + margin,
				"%s: %s clear of %s (%.2f m)" % [tag, spheres[i]["name"], spheres[j]["name"], d])
	# sphere vs box: the sphere's centre in the box's frame, the box-to-point distance
	for sp in spheres:
		for bx in boxes:
			var local: Vector3 = (bx["basis"] as Basis).inverse() * ((sp["pos"] as Vector3) - (bx["pos"] as Vector3))
			var half: Vector3 = bx["half"]
			var gap := Vector3(maxf(absf(local.x) - half.x, 0.0), maxf(absf(local.y) - half.y, 0.0), maxf(absf(local.z) - half.z, 0.0))
			_check(gap.length() > float(sp["r"]) + margin,
				"%s: %s clear of %s (%.2f m)" % [tag, sp["name"], bx["name"], gap.length()])
	# box vs box: separated by height (every box is a slab or a bar at its own level)
	for i in range(boxes.size()):
		for j in range(i + 1, boxes.size()):
			var gap: float = absf((boxes[i]["pos"] as Vector3).y - (boxes[j]["pos"] as Vector3).y)
			var ext: float = _vertical_extent(boxes[i]) + _vertical_extent(boxes[j])
			_check(gap > ext + margin, "%s: %s above or below %s (gap %.2f, extents %.2f)" % [tag, boxes[i]["name"], boxes[j]["name"], gap, ext])
	# every box corner inside the glass, and above the floor
	for bx in boxes:
		var ok := true
		var half: Vector3 = bx["half"]
		for cx in [-1.0, 1.0]:
			for cy in [-1.0, 1.0]:
				for cz in [-1.0, 1.0]:
					var corner: Vector3 = (bx["pos"] as Vector3) + (bx["basis"] as Basis) * Vector3(half.x * cx, half.y * cy, half.z * cz)
					if absf(corner.x) > inner + GLASS_M - margin or absf(corner.z) > inner + GLASS_M - margin or corner.y < 0.0:
						ok = false
		_check(ok, "%s: %s's corners inside the glass and above the floor" % [tag, bx["name"]])
	for sp in spheres:
		var p: Vector3 = sp["pos"]
		var r: float = float(sp["r"])
		_check(absf(p.x) + r <= inner + GLASS_M - margin and absf(p.z) + r <= inner + GLASS_M - margin and p.y - r >= 0.0,
			"%s: %s inside the glass and above the floor" % [tag, sp["name"]])


func _at(p: Vector3, y: float) -> Vector3:
	return Vector3(p.x, y, p.z)


func _vertical_extent(bx: Dictionary) -> float:
	var bs: Basis = bx["basis"]
	var half: Vector3 = bx["half"]
	return absf(bs.x.y) * half.x + absf(bs.y.y) * half.y + absf(bs.z.y) * half.z


## A 21 x 21 plan of one seed: -z at the top, +x to the right, 2 * inner across.
func _plan(seed: int, inner: float) -> void:
	var s: Dictionary = _score(seed, inner, 1.0, 1.0)
	var n := 21
	var grid: Array = []
	for r in range(n):
		var row: Array = []
		for c in range(n):
			row.append(" ")
		grid.append(row)
	var put := func(p: Vector3, ch: String) -> void:
		var c: int = clampi(int(round((p.x + inner) / (2.0 * inner) * float(n - 1))), 0, n - 1)
		var r: int = clampi(int(round((p.z + inner) / (2.0 * inner) * float(n - 1))), 0, n - 1)
		grid[r][c] = ch
	for i in range(SAMPLES):
		put.call(FAMILY.path(s, float(i) / float(SAMPLES - 1)), ".")
	for i in range(SAMPLES):
		put.call(FAMILY.across(s, -1.0 + 2.0 * float(i) / float(SAMPLES - 1)), "x")
	put.call(s["a"], "A")
	put.call(s["b"], "B")
	put.call(FAMILY.path(s, FAMILY.PHI), "O")
	print("[probe_biome_family_malevich] plan of seed %d at inner %.1f (%s): axis %.1f deg off the z wall, side %+.0f, across %.1f deg off it the other way (shear %.1f off the perpendicular), beam %s, lift %.2f, tilts %.1f / %.1f" % [
		seed, inner, FAMILY.NAME, float(s["malevich_theta_deg"]), float(s["malevich_side"]),
		float(s["malevich_psi_deg"]), float(s["malevich_shear_deg"]),
		"leads" if float(s["malevich_lead"]) > 0.0 else "trails",
		float(s["lift"]), float(s["tilt0"]), float(s["tilt1"])])
	print("[probe_biome_family_malevich] +" + "-".repeat(n) + "+")
	for r in range(n):
		print("[probe_biome_family_malevich] |" + "".join(grid[r]) + "|")
	print("[probe_biome_family_malevich] +" + "-".repeat(n) + "+")
