extends SceneTree
## probe_biome_family_moholy.gd — the moholy family keeps the cage's contract.
##
##   Godot_v4.6-stable_win64.exe --headless --path . --xr-mode off --script res://commons/testing/probe_biome_family_moholy.gd
##
## For 20 seeds (rng.seed = hash([seed, "score"])), all four sign pairs, at inner 2.0 and
## 11.5: the score has its keys; a and b lie on the floor and span >= 1.1 * inner;
## path(0) == a and path(1) == b within 1e-4; 41 samples of path and 41 of across stay
## inside |x|, |z| <= inner with y = 0; lift in 0.6 .. 1.8, the tilts where the family
## says; across(0) is the elbow and across(±1) is near the glass; the heading is constant
## on each leg and jumps by the turn at the elbow; the elbow sits near path(0.618); two
## rngs with one seed give one dictionary, and a mirrored seed mirrors. At inner 2.0 the
## clearances the family's comment claims are measured in metres against the vitrine's
## element sizes. Then an ASCII plan of seed 7 at inner 2.0. No scene, no MultiMesh:
## --headless is fine. Exit 1 on any failed check.

const FAMILY := preload("res://commons/biome_layers/families/moholy.gd")
const SEEDS := 20
const INNERS: Array[float] = [2.0, 11.5]
const SIGNS: Array[Vector2] = [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]
const SAMPLES := 41
const DEG := PI / 180.0

var _checks := 0
var _fails := 0
# the clearances measured at inner 2.0, minimum over every seed and sign pair
var _min_disc_cube := INF
var _min_loop_cube := INF
var _min_point_divided := INF
var _min_raft_over_wall := INF
var _min_plane1_crown := INF


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails += 1
		print("  FAIL  ", msg)


func _initialize() -> void:
	_check(FAMILY.NAME == "moholy", "NAME is the token value")
	_check(FAMILY.REFERENCE.contains("Moholy"), "REFERENCE names the painter")
	_check(FAMILY.LINE.length() > 20 and FAMILY.LINE.ends_with("."), "LINE is a sentence")
	for inner in INNERS:
		for seed in range(SEEDS):
			var base: Dictionary = _score(seed, inner, 1.0, 1.0)
			for sg in SIGNS:
				_layout(seed, inner, sg.x, sg.y, base)
	print("[probe_biome_family_moholy] clearances at inner 2.0 (m): disc sweep to cube %.2f (>= 0.80), loop to cube %.2f (>= 0.53), point to divided cube %.2f (>= 0.49), raft above the boundary wall %.2f (>= 0), leaning plane to crown %.2f (>= 0.93)"
		% [_min_disc_cube, _min_loop_cube, _min_point_divided, _min_raft_over_wall, _min_plane1_crown])
	_plan(7, 2.0)
	print("[probe_biome_family_moholy] %d checks, %d failed" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


func _score(seed: int, inner: float, sx: float, sz: float) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "score"])
	return FAMILY.score(rng, inner, sx, sz)


func _xz(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z)


func _inside(p: Vector3, inner: float) -> bool:
	return absf(p.x) <= inner + 1e-6 and absf(p.z) <= inner + 1e-6 and is_zero_approx(p.y)


func _layout(seed: int, inner: float, sx: float, sz: float, base: Dictionary) -> void:
	var tag := "seed %d inner %.1f (%+d,%+d)" % [seed, inner, int(sx), int(sz)]
	var s: Dictionary = _score(seed, inner, sx, sz)
	for key in ["a", "b", "lift", "tilt0", "tilt1"]:
		_check(s.has(key), "%s: has %s" % [tag, key])
	if not (s.has("a") and s.has("b") and s.has("lift")):
		return
	var a: Vector3 = s["a"]
	var b: Vector3 = s["b"]
	_check(is_zero_approx(a.y) and is_zero_approx(b.y), "%s: a and b on the floor" % tag)
	_check(a.distance_to(b) >= 1.1 * inner, "%s: span %.3f >= %.3f" % [tag, a.distance_to(b), 1.1 * inner])
	_check(FAMILY.path(s, 0.0).distance_to(a) < 1e-4, "%s: path(0) == a" % tag)
	_check(FAMILY.path(s, 1.0).distance_to(b) < 1e-4, "%s: path(1) == b" % tag)
	var lift: float = float(s["lift"])
	_check(lift >= 0.6 and lift <= 1.8, "%s: lift %.3f in 0.6 .. 1.8" % [tag, lift])
	_check(lift >= 1.4, "%s: lift %.3f is in the air (>= 1.4)" % [tag, lift])
	_check(float(s["tilt0"]) >= 85.0 and float(s["tilt0"]) <= 90.0, "%s: tilt0 %.1f near-vertical" % [tag, float(s["tilt0"])])
	_check(float(s["tilt1"]) >= -35.0 and float(s["tilt1"]) <= -25.0, "%s: tilt1 %.1f oblique" % [tag, float(s["tilt1"])])

	# 41 samples of the spine, 41 across it
	var path_ok := true
	for i in range(SAMPLES):
		if not _inside(FAMILY.path(s, float(i) / float(SAMPLES - 1)), inner):
			path_ok = false
	_check(path_ok, "%s: every path sample inside |x|,|z| <= %.1f, y = 0" % [tag, inner])
	var across_ok := true
	for i in range(SAMPLES):
		if not _inside(FAMILY.across(s, -1.0 + 2.0 * float(i) / float(SAMPLES - 1)), inner):
			across_ok = false
	_check(across_ok, "%s: every across sample inside |x|,|z| <= %.1f, y = 0" % [tag, inner])

	# the elbow: the cross-centre, on the spine, near the golden section
	var e: Vector3 = s["moholy_elbow"]
	var te: float = float(s["moholy_t"])
	_check(FAMILY.across(s, 0.0).distance_to(e) < 1e-6, "%s: across(0) is the elbow" % tag)
	_check(FAMILY.path(s, te).distance_to(e) < 1e-4, "%s: path(moholy_t) is the elbow" % tag)
	_check(FAMILY.path(s, 0.618).distance_to(e) < 1e-4, "%s: path(0.618) is the hinge" % tag)
	var arc_t: float = float(s["moholy_arc_t"])
	_check(arc_t >= 0.55 and arc_t <= 0.65, "%s: by length the elbow is near the golden section (%.3f)" % [tag, arc_t])
	_check(is_equal_approx(arc_t, float(s["moholy_len1"]) / (float(s["moholy_len1"]) + float(s["moholy_len2"]))), "%s: moholy_arc_t is len1 / (len1 + len2)" % tag)
	for u in [-1.0, 1.0]:
		var p: Vector3 = FAMILY.across(s, u)
		_check(maxf(absf(p.x), absf(p.z)) >= 0.9 * inner, "%s: across(%+.0f) near the inner edge" % [tag, u])

	# the heading: one value per leg, a jump of the turn between them
	var h1: float = FAMILY.heading(s, 0.1)
	var h2: float = FAMILY.heading(s, 0.9)
	_check(is_equal_approx(h1, FAMILY.heading(s, 0.5)) and is_equal_approx(h1, FAMILY.heading(s, 0.0)), "%s: heading constant on the first leg" % tag)
	_check(is_equal_approx(h2, FAMILY.heading(s, 0.7)) and is_equal_approx(h2, FAMILY.heading(s, 1.0)), "%s: heading constant on the second leg" % tag)
	var jump: float = absf(wrapf(h2 - h1, -PI, PI))
	_check(jump >= 50.0 * DEG and jump <= 70.0 * DEG, "%s: heading jumps %.1f deg at the elbow" % [tag, jump / DEG])
	var d1: Vector3 = FAMILY.path(s, te * 0.5) - a
	_check(is_equal_approx(atan2(d1.x, d1.z), h1), "%s: heading is atan2(dx, dz) of the travel" % tag)
	var d3: Vector3 = FAMILY.across(s, 0.5) - e
	var cross: float = absf(wrapf(atan2(d3.x, d3.z) - h1, -PI, PI))
	_check(cross >= 50.0 * DEG and cross <= 70.0 * DEG, "%s: the second axis crosses the first at %.1f deg" % [tag, cross / DEG])

	# determinism, and the mirror
	_check(str(_score(seed, inner, sx, sz)) == str(s), "%s: one seed, one dictionary" % tag)
	var ba: Vector3 = base["a"]
	var bb: Vector3 = base["b"]
	var be: Vector3 = base["moholy_elbow"]
	_check(a.is_equal_approx(Vector3(ba.x * sx, 0.0, ba.z * sz)) and b.is_equal_approx(Vector3(bb.x * sx, 0.0, bb.z * sz))
		and e.is_equal_approx(Vector3(be.x * sx, 0.0, be.z * sz)), "%s: a mirrored seed mirrors" % tag)
	if seed > 0:
		_check(not _score(seed - 1, inner, sx, sz)["a"].is_equal_approx(a), "%s: another seed draws another foot" % tag)

	# the clearances at the shipped size (k = 1): the vitrine's element sizes in metres
	if is_equal_approx(inner, 2.0):
		var cube: Vector2 = _xz(FAMILY.path(s, 0.85))
		var sweep := INF
		for i in range(SAMPLES):
			sweep = minf(sweep, cube.distance_to(_xz(FAMILY.across(s, -0.55 + 1.1 * float(i) / float(SAMPLES - 1)))))
		_min_disc_cube = minf(_min_disc_cube, sweep)
		_check(sweep >= 0.80, "%s: the sliding disc (r 0.45) never reaches the cube (half 0.35): %.2f" % [tag, sweep])
		var loop_d: float = cube.distance_to(_xz(FAMILY.across(s, 0.85)))
		_min_loop_cube = minf(_min_loop_cube, loop_d)
		_check(loop_d >= 0.53, "%s: the loop cube clears the black cube: %.2f" % [tag, loop_d])
		var pd: float = _xz(FAMILY.path(s, 0.618)).distance_to(_xz(FAMILY.across(s, -0.3)))
		_min_point_divided = minf(_min_point_divided, pd)
		_check(pd >= 0.49, "%s: the point clears the divided cube: %.2f" % [tag, pd])
		var half_v: float = 0.55 * sin((90.0 - float(s["tilt0"])) * DEG) + 0.015
		var gap: float = (1.5 * lift - half_v) - (0.9 * lift + 0.9)
		_min_raft_over_wall = minf(_min_raft_over_wall, gap)
		_check(gap >= 0.0, "%s: the raft's underside clears the boundary wall's top: %.3f" % [tag, gap])
		var pc: float = _xz(FAMILY.across(s, -0.6)).distance_to(cube)
		_min_plane1_crown = minf(_min_plane1_crown, pc)
		_check(pc >= 0.93, "%s: the leaning plane clears the crown on the cube: %.2f" % [tag, pc])


## A 21 x 21 plan of one seed: rows are z from -inner (top, the back pane) to +inner,
## columns x from -inner to +inner. '.' the spine, 'x' the second axis, 'O' path(0.618),
## 'A' and 'B' the ends.
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
		put.call(FAMILY.across(s, -1.0 + 2.0 * float(i) / float(SAMPLES - 1)), "x")
	for i in range(SAMPLES):
		put.call(FAMILY.path(s, float(i) / float(SAMPLES - 1)), ".")
	put.call(FAMILY.path(s, 0.618), "O")
	put.call(s["a"], "A")
	put.call(s["b"], "B")
	print("[probe_biome_family_moholy] plan of seed %d at inner %.1f — x left to right, z top (-%.1f, the back pane) to bottom" % [seed, inner, inner])
	print("  a %s  elbow %s  b %s" % [_fmt(s["a"]), _fmt(s["moholy_elbow"]), _fmt(s["b"])])
	print("  turn %.1f deg  elbow at t %.3f (%.3f by length)  bars %.2f + %.2f m  lift %.2f  tilt0 %.1f  tilt1 %.1f  heading %.1f -> %.1f deg"
		% [float(s["moholy_turn_deg"]), float(s["moholy_t"]), float(s["moholy_arc_t"]), float(s["moholy_len1"]), float(s["moholy_len2"]),
		float(s["lift"]), float(s["tilt0"]), float(s["tilt1"]), FAMILY.heading(s, 0.0) / DEG, FAMILY.heading(s, 1.0) / DEG])
	print("  +" + "-".repeat(n) + "+")
	for r in range(n):
		print("  |" + "".join(grid[r]) + "|")
	print("  +" + "-".repeat(n) + "+")


func _fmt(p: Vector3) -> String:
	return "(%.2f, %.2f)" % [p.x, p.z]
