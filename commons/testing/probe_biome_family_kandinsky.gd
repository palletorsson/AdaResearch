extends SceneTree
## probe_biome_family_kandinsky.gd — the kandinsky family keeps the families contract.
##
##   Godot_v4.6-stable_win64.exe --headless --path . --xr-mode off --script res://commons/testing/probe_biome_family_kandinsky.gd
##
## For 20 seeds (rng.seed = hash([seed, "score"])), all four sign pairs, at inner 2.0 and
## 11.5: the score's a, b, lift, tilts are present and typed; path(0) == a and path(1) == b
## within 1e-4; |a - b| >= 1.1 * inner; lift in 0.6..1.8; 41 path samples and 41 across
## samples lie inside |x|, |z| <= inner with y = 0; heading is finite along the spine and
## at t = 1 points at the focus; two rngs of one seed give equal dictionaries; a mirrored
## sign pair is the mirror image of (1, 1). Then the clearance the README asks for at the
## shipped size: the vitrine's garden elements (point, second point, corner sphere, two
## planes, cube, beam, the beam's rider — sizes and heights copied from biome_vitrine.gd's
## _build_garden, k = size / 5) are built as spheres and oriented boxes and every pair is
## separated by a separating-axis test, under three yaw conventions a loader might use.
## The Boundary plane is left out: it sweeps the spine by design and crosses the point
## in the built-in families too. Ends with an ASCII plan of seed 7 at inner 2.0 and
##   [probe_biome_family_kandinsky] N checks, F failed
## exit 1 on any failure. No scene, no MultiMesh readback: --headless is fine.

const FAMILY := preload("res://commons/biome_layers/families/kandinsky.gd")
const SEEDS := 20
const INNERS: Array[float] = [2.0, 11.5]
const SIGNS: Array = [[1.0, 1.0], [-1.0, 1.0], [1.0, -1.0], [-1.0, -1.0]]
const SAMPLES := 41
const EPS := 1e-4
const CLEAR_M := 0.02   # touching counts as a collision

var _checks := 0
var _fails := 0
## The tightest gap seen per element pair at each inner: exact for spheres, the widest
## separating axis for boxes (a lower bound), so the report can say how much room the
## family has and which pair would go first.
var _tightest: Dictionary = {}


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails += 1
		print("  FAIL  ", msg)


func _initialize() -> void:
	_check(FAMILY.NAME == "kandinsky", "NAME is the token value")
	_check(FAMILY.REFERENCE.begins_with("Wassily Kandinsky"), "REFERENCE names the painter")
	_check(FAMILY.LINE.length() > 20, "LINE is a sentence")
	for inner in INNERS:
		for seed in range(SEEDS):
			var base: Dictionary = _score(seed, inner, 1.0, 1.0)
			for pair in SIGNS:
				var sx: float = pair[0]
				var sz: float = pair[1]
				var tag := "seed %d inner %.1f (%d,%d)" % [seed, inner, int(sx), int(sz)]
				var s: Dictionary = _score(seed, inner, sx, sz)
				_contract(s, inner, tag)
				_determinism(seed, inner, sx, sz, s, tag)
				_mirror(base, s, inner, sx, sz, tag)
				_clearance(s, inner, tag)
	_plan(7, 2.0)
	for key in _tightest.keys():
		var pairs: Array = _tightest[key].keys()
		pairs.sort_custom(func(p: String, q: String) -> bool: return float(_tightest[key][p]["gap"]) < float(_tightest[key][q]["gap"]))
		print("[probe_biome_family_kandinsky] five tightest pairs at inner %s (gap is a lower bound):" % key)
		for i in range(mini(5, pairs.size())):
			var t: Dictionary = _tightest[key][pairs[i]]
			print("  %-14s >= %.2f m  (%s)" % [pairs[i], float(t["gap"]), t["where"]])
	print("[probe_biome_family_kandinsky] %d checks, %d failed" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


func _score(seed: int, inner: float, sx: float, sz: float) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "score"])
	return FAMILY.score(rng, inner, sx, sz)


func _inside(p: Vector3, inner: float) -> bool:
	return absf(p.x) <= inner + EPS and absf(p.z) <= inner + EPS and is_zero_approx(p.y)


func _contract(s: Dictionary, inner: float, tag: String) -> void:
	for key in ["a", "b", "lift", "tilt0", "tilt1"]:
		_check(s.has(key), "%s: score has %s" % [tag, key])
	var a: Vector3 = s["a"]
	var b: Vector3 = s["b"]
	_check(is_zero_approx(a.y) and is_zero_approx(b.y), "%s: a and b on the floor" % tag)
	_check(FAMILY.path(s, 0.0).distance_to(a) < EPS, "%s: path(0) == a" % tag)
	_check(FAMILY.path(s, 1.0).distance_to(b) < EPS, "%s: path(1) == b" % tag)
	_check(a.distance_to(b) >= 1.1 * inner, "%s: span %.2f >= %.2f" % [tag, a.distance_to(b), 1.1 * inner])
	var lift: float = float(s["lift"])
	_check(lift >= 0.6 and lift <= 1.8, "%s: lift %.2f in 0.6..1.8" % [tag, lift])
	for key in s.keys():
		_check(key in ["a", "b", "lift", "tilt0", "tilt1"] or String(key).begins_with("kandinsky_"), "%s: private key %s prefixed" % [tag, key])
	var path_ok := true
	var across_ok := true
	var heading_ok := true
	for i in range(SAMPLES):
		var t: float = float(i) / float(SAMPLES - 1)
		if not _inside(FAMILY.path(s, t), inner):
			path_ok = false
		if not _inside(FAMILY.across(s, -1.0 + 2.0 * t), inner):
			across_ok = false
		var h: float = FAMILY.heading(s, t)
		if is_nan(h) or is_inf(h):
			heading_ok = false
	_check(path_ok, "%s: 41 path samples inside |x|,|z| <= inner, y = 0" % tag)
	_check(across_ok, "%s: 41 across samples inside |x|,|z| <= inner, y = 0" % tag)
	_check(heading_ok, "%s: heading finite along the spine" % tag)
	# the family's own claims: u = ±1 near the glass, u = 0 the focus, the arrival aimed
	var edge_ok := true
	for u in [-1.0, 1.0]:
		var p: Vector3 = FAMILY.across(s, u)
		if maxf(absf(p.x), absf(p.z)) < 0.85 * inner:
			edge_ok = false
	_check(edge_ok, "%s: across(±1) within 15%% of the inner edge" % tag)
	var focus: Vector3 = s["kandinsky_focus"]
	_check(FAMILY.across(s, 0.0).distance_to(focus) < EPS, "%s: across(0) is the focus" % tag)
	var aim: float = FAMILY.heading(s, 1.0)
	var to_focus: Vector3 = focus - b
	var want: float = atan2(to_focus.x, to_focus.z)
	_check(absf(angle_difference(aim, want)) < 1e-3, "%s: heading(1) points at the focus" % tag)
	_check(absf(FAMILY.heading(s, 0.0) - FAMILY.heading(s, 1.0)) > deg_to_rad(5.0), "%s: the spine bows (heading turns %.1f deg)" % [tag, rad_to_deg(absf(angle_difference(FAMILY.heading(s, 0.0), FAMILY.heading(s, 1.0))))])


func _determinism(seed: int, inner: float, sx: float, sz: float, s: Dictionary, tag: String) -> void:
	var again: Dictionary = _score(seed, inner, sx, sz)
	_check(again == s, "%s: two rngs of one seed give one score" % tag)
	var same := true
	for i in range(SAMPLES):
		var t: float = float(i) / float(SAMPLES - 1)
		if FAMILY.path(again, t) != FAMILY.path(s, t) or FAMILY.across(again, -1.0 + 2.0 * t) != FAMILY.across(s, -1.0 + 2.0 * t):
			same = false
	_check(same, "%s: path and across repeat exactly" % tag)


## A sign pair is the mirror of (1, 1): every path and across sample, multiplied.
func _mirror(base: Dictionary, s: Dictionary, _inner: float, sx: float, sz: float, tag: String) -> void:
	var m := Vector3(sx, 1.0, sz)
	var ok := true
	for i in range(SAMPLES):
		var t: float = float(i) / float(SAMPLES - 1)
		if FAMILY.path(s, t).distance_to(FAMILY.path(base, t) * m) > EPS:
			ok = false
		if FAMILY.across(s, -1.0 + 2.0 * t).distance_to(FAMILY.across(base, -1.0 + 2.0 * t) * m) > EPS:
			ok = false
	_check(ok, "%s: the mirror image of (1,1)" % tag)
	_check(is_equal_approx(float(s["lift"]), float(base["lift"])) and is_equal_approx(float(s["tilt0"]), float(base["tilt0"])), "%s: lift and tilt survive the mirror" % tag)


# ── clearance: the vitrine's garden, as spheres and oriented boxes ─────────────────

## One element: {name, sphere: bool, c: Vector3, r: float | basis: Basis, h: Vector3}
func _sphere(name: String, c: Vector3, r: float) -> Dictionary:
	return {"name": name, "sphere": true, "c": c, "r": r}


func _box(name: String, c: Vector3, rot: Vector3, size: Vector3) -> Dictionary:
	return {"name": name, "sphere": false, "c": c, "basis": Basis.from_euler(rot), "h": size * 0.5}


func _garden(s: Dictionary, inner: float, yaws: Dictionary) -> Array:
	var k: float = (2.0 * inner + 1.0) / 5.0   # size = 2 * (inner + 0.5); k = size / 5
	var lift: float = float(s["lift"])
	var out: Array = []
	var at := func(t: float, y: float) -> Vector3:
		var p: Vector3 = FAMILY.path(s, t)
		p.y = y * lift
		return p
	var over := func(u: float, y: float) -> Vector3:
		var p: Vector3 = FAMILY.across(s, u)
		p.y = y * lift
		return p
	out.append(_sphere("point", at.call(0.618, 1.25 * k), 0.15 * k))
	out.append(_sphere("point2", at.call(0.15, 0.85 * k), 0.11 * k))
	out.append(_sphere("sphere0", at.call(0.0, 0.45 * k), 0.45 * k))
	out.append(_box("plane0", at.call(0.382, 1.5 * k), Vector3(deg_to_rad(float(s["tilt0"])), float(yaws["plane0"]), 0.0), Vector3(1.6 * k, 1.1 * k, 0.03 * k)))
	out.append(_box("plane1", over.call(-0.6, 0.95 * k), Vector3(deg_to_rad(float(s["tilt1"])), float(yaws["plane1"]) + PI * 0.5, 0.0), Vector3(1.2 * k, 0.8 * k, 0.03 * k)))
	out.append(_box("cube", at.call(0.85, 0.35 * k), Vector3(0.0, float(yaws["cube"]) + deg_to_rad(15.0), 0.0), Vector3.ONE * 0.7 * k))
	var beam: Dictionary = _box("beam", over.call(0.55, 1.9 * k), Vector3(0.0, float(yaws["beam"]) + deg_to_rad(30.0), 0.0), Vector3(1.4 * k, 0.3 * k, 0.3 * k))
	out.append(beam)
	# the small sphere rides the beam at local (0.62k, 0.27k, 0): it sits ON the beam, so
	# the pair beam/rider is skipped below
	out.append(_sphere("rider", beam["c"] + (beam["basis"] as Basis) * Vector3(0.62 * k, 0.27 * k, 0.0), 0.125 * k))
	return out


## The gap between two elements, metres: exact for a sphere pair and a sphere against a
## box, a lower bound (the widest separating axis) for two boxes. Negative means they
## overlap; under CLEAR_M counts as a collision.
func _gap(e0: Dictionary, e1: Dictionary) -> float:
	if bool(e0["sphere"]) and bool(e1["sphere"]):
		return (e0["c"] as Vector3).distance_to(e1["c"]) - float(e0["r"]) - float(e1["r"])
	if bool(e0["sphere"]) != bool(e1["sphere"]):
		var sp: Dictionary = e0 if bool(e0["sphere"]) else e1
		var bx: Dictionary = e1 if bool(e0["sphere"]) else e0
		var local: Vector3 = (bx["basis"] as Basis).inverse() * ((sp["c"] as Vector3) - (bx["c"] as Vector3))
		var h: Vector3 = bx["h"]
		var nearest := Vector3(clampf(local.x, -h.x, h.x), clampf(local.y, -h.y, h.y), clampf(local.z, -h.z, h.z))
		return local.distance_to(nearest) - float(sp["r"])
	return _obb_gap(e0, e1)


## Separating-axis test on two oriented boxes: 3 + 3 face normals and 9 edge crosses.
## Returns the widest separation any axis shows (a lower bound on the true gap).
func _obb_gap(b0: Dictionary, b1: Dictionary) -> float:
	var a0: Basis = b0["basis"]
	var a1: Basis = b1["basis"]
	var h0: Vector3 = b0["h"]
	var h1: Vector3 = b1["h"]
	var d: Vector3 = (b1["c"] as Vector3) - (b0["c"] as Vector3)
	var ax0: Array[Vector3] = [a0.x, a0.y, a0.z]
	var ax1: Array[Vector3] = [a1.x, a1.y, a1.z]
	var axes: Array[Vector3] = []
	axes.append_array(ax0)
	axes.append_array(ax1)
	for i in range(3):
		for j in range(3):
			var cr: Vector3 = ax0[i].cross(ax1[j])
			if cr.length_squared() > 1e-8:
				axes.append(cr.normalized())
	var widest: float = -INF
	for l in axes:
		var r0: float = h0.x * absf(ax0[0].dot(l)) + h0.y * absf(ax0[1].dot(l)) + h0.z * absf(ax0[2].dot(l))
		var r1: float = h1.x * absf(ax1[0].dot(l)) + h1.y * absf(ax1[1].dot(l)) + h1.z * absf(ax1[2].dot(l))
		widest = maxf(widest, absf(d.dot(l)) - r0 - r1)
	return widest


func _clearance(s: Dictionary, inner: float, tag: String) -> void:
	var chord: Vector3 = (s["b"] as Vector3) - (s["a"] as Vector3)
	var chord_yaw: float = atan2(chord.x, chord.z)
	var mid: float = FAMILY.heading(s, 0.5)
	var conventions: Dictionary = {
		"heading(0.5)": {"plane0": mid, "plane1": mid, "cube": mid, "beam": mid},
		"per element": {"plane0": FAMILY.heading(s, 0.382), "plane1": FAMILY.heading(s, 1.0), "cube": FAMILY.heading(s, 0.85), "beam": FAMILY.heading(s, 1.0)},
		"chord": {"plane0": chord_yaw, "plane1": chord_yaw, "cube": chord_yaw, "beam": chord_yaw},
	}
	for conv in conventions.keys():
		var garden: Array = _garden(s, inner, conventions[conv])
		var hits: Array[String] = []
		for i in range(garden.size()):
			for j in range(i + 1, garden.size()):
				var n0: String = garden[i]["name"]
				var n1: String = garden[j]["name"]
				if n0 == "beam" and n1 == "rider":
					continue
				var gap: float = _gap(garden[i], garden[j])
				if gap < CLEAR_M:
					hits.append("%s/%s %.2f m" % [n0, n1, gap])
				var key := "%.1f" % inner
				if not _tightest.has(key):
					_tightest[key] = {}
				var pair := "%s/%s" % [n0, n1]
				if not _tightest[key].has(pair) or gap < float(_tightest[key][pair]["gap"]):
					_tightest[key][pair] = {"gap": gap, "where": "%s yaw %s" % [tag, conv]}
		_check(hits.is_empty(), "%s: garden clear under yaw %s (hit %s)" % [tag, conv, ", ".join(hits)])


# ── the plan ───────────────────────────────────────────────────────────────────────

func _plan(seed: int, inner: float) -> void:
	var s: Dictionary = _score(seed, inner, 1.0, 1.0)
	var n := 21
	var rows: Array = []
	for r in range(n):
		var row: Array = []
		for c in range(n):
			row.append(" ")
		rows.append(row)
	var put := func(p: Vector3, ch: String) -> void:
		var cx: int = clampi(int(round((p.x + inner) / (2.0 * inner) * float(n - 1))), 0, n - 1)
		var cz: int = clampi(int(round((p.z + inner) / (2.0 * inner) * float(n - 1))), 0, n - 1)
		rows[cz][cx] = ch
	for i in range(SAMPLES):
		var t: float = float(i) / float(SAMPLES - 1)
		put.call(FAMILY.path(s, t), ".")
	for i in range(SAMPLES):
		var u: float = -1.0 + 2.0 * float(i) / float(SAMPLES - 1)
		put.call(FAMILY.across(s, u), "x")
	put.call(s["kandinsky_focus"], "F")
	put.call(FAMILY.path(s, 0.618), "O")
	put.call(s["a"], "A")
	put.call(s["b"], "B")
	print("[probe_biome_family_kandinsky] plan: seed %d inner %.1f, x right, z down; A head, B foot, O point, F focus, . spine, x ribs" % [seed, inner])
	print("  a %s  b %s  focus %s  spread %.1f  bow %.1f  lift %.2f  tilt0 %.1f  tilt1 %.1f" % [
		str(s["a"]), str(s["b"]), str(s["kandinsky_focus"]), float(s["kandinsky_spread"]),
		float(s["kandinsky_bow"]), float(s["lift"]), float(s["tilt0"]), float(s["tilt1"])])
	print("  +" + "-".repeat(n) + "+")
	for r in range(n):
		print("  |" + "".join(rows[r]) + "|")
	print("  +" + "-".repeat(n) + "+")
