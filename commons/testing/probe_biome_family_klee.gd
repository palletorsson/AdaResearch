extends SceneTree
## probe_biome_family_klee.gd — the klee family keeps the cage's composition contract.
##
##   Godot_v4.6-stable_win64.exe --headless --path . --xr-mode off --script res://commons/testing/probe_biome_family_klee.gd
##
## For 20 seeds (rng.seed = hash([seed, "score"])), all four sign pairs, at inner 2.0 (the
## 5 m cage) and 11.5 (the 24 m cage): path sampled at 41 t and across at 41 u lie inside
## |x|, |z| <= inner on the floor; path(0) == a and path(1) == b; |a - b| >= 1.1 * inner;
## lift in 0.6 .. 1.8; tilts within 15 degrees (tiles); every path sample is on a grid
## line and every across sample is a cell centre; the heading is one of four right angles
## and turns five times (three L-shaped arms); two rngs with one seed give one score.
## At inner 2.0 the garden's own bodies are hung exactly as biome_vitrine._build_garden
## hangs them (sizes, heights, rotations, the work's yaw for cube and beam) and checked
## against each other with a separating-axis test and against the glass. Then the ASCII
## plan of seed 7. Pure arithmetic — no scene, no renderer; quits from _initialize.

const KLEE := preload("res://commons/biome_layers/families/klee.gd")
const SEEDS := 20
const INNERS: Array[float] = [2.0, 11.5]
const SIGNS: Array[Vector2] = [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]

var _checks := 0
var _fails := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails += 1
		print("  FAIL  ", msg)


func _initialize() -> void:
	_check(KLEE.NAME == "klee", "NAME is the token value")
	_check(String(KLEE.REFERENCE).length() > 8 and String(KLEE.LINE).length() > 20, "REFERENCE and LINE are written")
	for inner in INNERS:
		for seed in range(SEEDS):
			for sg in SIGNS:
				_case(seed, inner, sg.x, sg.y)
	_plan(7, 2.0)
	print("[probe_biome_family_klee] %d checks, %d failed" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


func _score_for(seed: int, inner: float, sx: float, sz: float) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "score"])
	return KLEE.score(rng, inner, sx, sz)


func _inside(p: Vector3, inner: float) -> bool:
	return absf(p.x) <= inner + 1e-6 and absf(p.z) <= inner + 1e-6


## v is a cell centre: the centres are -inner, -inner + 1, ..., inner
func _is_cell(v: float, inner: float) -> bool:
	return absf(v + inner - round(v + inner)) < 1e-4


func _case(seed: int, inner: float, sx: float, sz: float) -> void:
	var tag := "seed %d inner %.1f (%+d, %+d)" % [seed, inner, int(sx), int(sz)]
	var s: Dictionary = _score_for(seed, inner, sx, sz)
	var s2: Dictionary = _score_for(seed, inner, sx, sz)
	_check(str(s) == str(s2), tag + ": determinism — one seed, one score")
	_check(s.has_all(["a", "b", "lift", "tilt0", "tilt1"]), tag + ": contract keys")
	for key in s.keys():
		_check(key in ["a", "b", "lift", "tilt0", "tilt1"] or String(key).begins_with("klee_"), tag + ": private key `%s` is prefixed" % key)
	var a: Vector3 = s["a"]
	var b: Vector3 = s["b"]
	_check(a.y == 0.0 and b.y == 0.0, tag + ": a and b on the floor")
	_check(_inside(a, inner) and _inside(b, inner), tag + ": a and b inside")
	_check(_is_cell(a.x, inner) and _is_cell(a.z, inner) and _is_cell(b.x, inner) and _is_cell(b.z, inner), tag + ": a and b are cell centres")
	_check(a.distance_to(b) >= 1.1 * inner, tag + ": span %.2f >= %.2f" % [a.distance_to(b), 1.1 * inner])
	var lift: float = float(s["lift"])
	_check(lift >= 0.6 and lift <= 1.8, tag + ": lift %.2f in 0.6 .. 1.8" % lift)
	_check(lift <= 0.8, tag + ": lift %.2f is low (tiles)" % lift)
	_check(absf(float(s["tilt0"])) <= 15.0 and absf(float(s["tilt1"])) <= 15.0, tag + ": tilts %.1f / %.1f within 15 deg" % [float(s["tilt0"]), float(s["tilt1"])])
	_check(KLEE.path(s, 0.0).distance_to(a) < 1e-4, tag + ": path(0) == a")
	_check(KLEE.path(s, 1.0).distance_to(b) < 1e-4, tag + ": path(1) == b")

	# the spine at 41 t
	var in_bounds := true
	var flat := true
	var on_grid := true
	var right_angles := true
	var turns := 0
	var last_h: float = KLEE.heading(s, 0.0)
	for i in range(41):
		var t: float = float(i) / 40.0
		var p: Vector3 = KLEE.path(s, t)
		in_bounds = in_bounds and _inside(p, inner)
		flat = flat and p.y == 0.0
		on_grid = on_grid and (_is_cell(p.x, inner) or _is_cell(p.z, inner))
		var h: float = KLEE.heading(s, t)
		right_angles = right_angles and absf(sin(2.0 * h)) < 1e-4
		if absf(wrapf(h - last_h, -PI, PI)) > 1e-3:
			turns += 1
		last_h = h
	_check(in_bounds, tag + ": 41 path samples inside |x|, |z| <= inner")
	_check(flat, tag + ": path samples on the floor")
	_check(on_grid, tag + ": every path sample lies on a cell row or column")
	_check(right_angles, tag + ": heading is one of four right angles at every t")
	var arms: int = (s["klee_arms"] as Array).size()
	_check(arms == 3, tag + ": three arms (%d)" % arms)
	_check(turns == 2 * arms - 1, tag + ": the spine turns %d times for %d arms" % [turns, arms])

	# across at 41 u
	var x_in := true
	var x_cells := true
	for i in range(41):
		var u: float = -1.0 + float(i) / 20.0
		var p: Vector3 = KLEE.across(s, u)
		x_in = x_in and _inside(p, inner) and p.y == 0.0
		x_cells = x_cells and _is_cell(p.x, inner) and _is_cell(p.z, inner)
	_check(x_in, tag + ": 41 across samples inside, on the floor")
	_check(x_cells, tag + ": every across sample is a cell centre")
	_check(KLEE.across(s, -1.0).distance_to(KLEE.across(s, 1.0)) >= 1.5 * inner, tag + ": across reaches both inner edges")

	if inner == 2.0:
		_collisions(s, tag)


# ── the garden's bodies at k = 1, as biome_vitrine._build_garden hangs them ─────────────

func _sphere(name: String, c: Vector3, r: float) -> Dictionary:
	return {"name": name, "kind": "sphere", "c": c, "r": r}


func _box(name: String, pos: Vector3, rot: Vector3, size: Vector3) -> Dictionary:
	return {"name": name, "kind": "box", "xf": Transform3D(Basis.from_euler(rot), pos), "h": size * 0.5}


func _bodies(s: Dictionary) -> Array:
	var lift: float = float(s["lift"])
	var a: Vector3 = s["a"]
	var b: Vector3 = s["b"]
	var yaw: float = atan2((b - a).x, (b - a).z)      # the work's yaw: _score["yaw"]
	var up := Vector3.UP
	var out: Array = []
	out.append(_sphere("sphere0", KLEE.path(s, 0.0) + up * 0.45 * lift, 0.45))
	out.append(_sphere("point2", KLEE.path(s, 0.15) + up * 0.85 * lift, 0.11))
	out.append(_sphere("point", KLEE.path(s, 0.618) + up * 1.25 * lift, 0.15))
	out.append(_box("plane0", KLEE.path(s, 0.382) + up * 1.5 * lift,
		Vector3(deg_to_rad(float(s["tilt0"])), KLEE.heading(s, 0.382), 0.0), Vector3(1.6, 1.1, 0.03)))
	out.append(_box("plane1", KLEE.across(s, -0.6) + up * 0.95 * lift,
		Vector3(deg_to_rad(float(s["tilt1"])), KLEE.heading(s, 0.5) + PI * 0.5, 0.0), Vector3(1.2, 0.8, 0.03)))
	out.append(_box("cube", KLEE.path(s, 0.85) + up * 0.35 * lift,
		Vector3(0.0, yaw + deg_to_rad(15.0), 0.0), Vector3(0.7, 0.7, 0.7)))
	var beam: Dictionary = _box("beam", KLEE.across(s, 0.55) + up * 1.9 * lift,
		Vector3(0.0, yaw + deg_to_rad(30.0), 0.0), Vector3(1.4, 0.3, 0.3))
	out.append(beam)
	out.append(_sphere("sphere1", (beam["xf"] as Transform3D) * Vector3(0.62, 0.27, 0.0), 0.125))
	return out


## Oriented boxes: separating-axis test over the 15 candidate axes.
func _box_box(p: Dictionary, q: Dictionary) -> bool:
	var ta: Transform3D = p["xf"]
	var tb: Transform3D = q["xf"]
	var ha: Vector3 = p["h"]
	var hb: Vector3 = q["h"]
	var d: Vector3 = tb.origin - ta.origin
	var axes: Array[Vector3] = [ta.basis.x, ta.basis.y, ta.basis.z, tb.basis.x, tb.basis.y, tb.basis.z]
	for i in range(3):
		for j in range(3):
			var c: Vector3 = axes[i].cross(axes[3 + j])
			if c.length() > 1e-6:
				axes.append(c.normalized())
	for L in axes:
		var ra: float = ha.x * absf(ta.basis.x.dot(L)) + ha.y * absf(ta.basis.y.dot(L)) + ha.z * absf(ta.basis.z.dot(L))
		var rb: float = hb.x * absf(tb.basis.x.dot(L)) + hb.y * absf(tb.basis.y.dot(L)) + hb.z * absf(tb.basis.z.dot(L))
		if absf(d.dot(L)) > ra + rb:
			return false
	return true


## A sphere against an oriented box: the nearest point of the box to the centre.
func _sphere_box(sp: Dictionary, bx: Dictionary) -> bool:
	var local: Vector3 = (bx["xf"] as Transform3D).affine_inverse() * (sp["c"] as Vector3)
	var h: Vector3 = bx["h"]
	var nearest := Vector3(clampf(local.x, -h.x, h.x), clampf(local.y, -h.y, h.y), clampf(local.z, -h.z, h.z))
	return nearest.distance_to(local) < float(sp["r"])


func _overlap(p: Dictionary, q: Dictionary) -> bool:
	if p["kind"] == "box" and q["kind"] == "box":
		return _box_box(p, q)
	if p["kind"] == "sphere" and q["kind"] == "sphere":
		return (p["c"] as Vector3).distance_to(q["c"]) < float(p["r"]) + float(q["r"])
	if p["kind"] == "sphere":
		return _sphere_box(p, q)
	return _sphere_box(q, p)


## Every point of the body within the glass at ±(inner + 0.5), horizontally.
func _within_glass(body: Dictionary, inner: float) -> bool:
	var lim: float = inner + 0.5 - 0.01
	if body["kind"] == "sphere":
		var c: Vector3 = body["c"]
		var r: float = body["r"]
		return absf(c.x) + r <= lim and absf(c.z) + r <= lim
	var xf: Transform3D = body["xf"]
	var h: Vector3 = body["h"]
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var w: Vector3 = xf * Vector3(h.x * sx, h.y * sy, h.z * sz)
				if absf(w.x) > lim or absf(w.z) > lim:
					return false
	return true


func _collisions(s: Dictionary, tag: String) -> void:
	var bodies: Array = _bodies(s)
	var hits: Array[String] = []
	for i in range(bodies.size()):
		for j in range(i + 1, bodies.size()):
			var p: Dictionary = bodies[i]
			var q: Dictionary = bodies[j]
			if p["name"] == "beam" and q["name"] == "sphere1":
				continue          # sphere1 rides the beam by design
			if _overlap(p, q):
				hits.append("%s/%s" % [p["name"], q["name"]])
	_check(hits.is_empty(), tag + ": no two bodies overlap at k = 1 (%s)" % ", ".join(hits))
	var outside: Array[String] = []
	for body in bodies:
		if not _within_glass(body, float(s["klee_inner"])):
			outside.append(body["name"])
	_check(outside.is_empty(), tag + ": every body within the glass (%s)" % ", ".join(outside))


# ── the plan ─────────────────────────────────────────────────────────────────────────────

## A 21×21 plan of the cage floor, 0.25 m per character, -z (the lattice's back pane) at
## the top: '.' the spine, 'x' across, 'A' and 'B' its ends, 'O' the point at path(0.618).
func _plan(seed: int, inner: float) -> void:
	var s: Dictionary = _score_for(seed, inner, 1.0, 1.0)
	var half: float = inner + 0.5
	var step: float = 2.0 * half / 20.0
	var grid: Array = []
	for r in range(21):
		var row: Array[String] = []
		for c in range(21):
			row.append(" ")
		grid.append(row)
	var put := func(p: Vector3, ch: String, over: String) -> void:
		var c: int = clampi(int(round((p.x + half) / step)), 0, 20)
		var r: int = clampi(int(round((p.z + half) / step)), 0, 20)
		if over.contains(grid[r][c]):
			grid[r][c] = ch
	for i in range(401):
		put.call(KLEE.path(s, float(i) / 400.0), ".", " ")
	for i in range(41):
		put.call(KLEE.across(s, -1.0 + float(i) / 20.0), "x", " .")
	put.call(KLEE.path(s, 0.618), "O", " .x")
	put.call(s["a"], "A", " .xO")
	put.call(s["b"], "B", " .xO")
	print("[probe_biome_family_klee] plan of seed %d at inner %.1f — hand %s, arms %s, a %s, b %s, lift %.2f, tilts %.1f / %.1f" % [
		seed, inner, "swapped" if bool(s["klee_hand"]) else "plain", str(s["klee_arms"]),
		str(Vector2(s["a"].x, s["a"].z)), str(Vector2(s["b"].x, s["b"].z)), float(s["lift"]), float(s["tilt0"]), float(s["tilt1"])])
	print("[probe_biome_family_klee] +" + "-".repeat(21) + "+   x -> right, z -> down, 0.25 m per char")
	for r in range(21):
		print("[probe_biome_family_klee] |" + "".join(grid[r]) + "|")
	print("[probe_biome_family_klee] +" + "-".repeat(21) + "+")
