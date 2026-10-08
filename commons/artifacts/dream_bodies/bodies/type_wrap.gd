extends RefCounted

## dream_bodies / type_wrap — one standing figure bandaged head to foot in torn
## printed paper.
##
## Reference (described, no image supplied): bodies wrapped entirely in
## TYPOGRAPHY — overlapping strips and sheets of printed paper in black, white
## and signal red, covered in huge letters at every angle and scale, some strips
## reading as torn newsprint, wound around torso, arms and legs like bandages so
## that no skin shows; among them one body in a fine black polka-dot mesh and one
## in pink honeycomb mesh. Behind them the same letters cover the whole wall.
##
## Reproduced, and how:
##   1. The wrap is the sculpture. A core of capsules and ellipsoids is buried
##      under 54..78 swept ArrayMesh bands, each 6-14 cm wide and 2-3 mm thick,
##      spiralling round one bone at its own pitch, phase, handedness and radial
##      stand-off (4..32 mm) so neighbours overlap and layer instead of abutting.
##      Pitch is derived, not guessed: turns = strip length / band width, the way
##      a real bandage lays down.
##   2. Torn ends. Each band is built from 5 lanes and every lane carries its own
##      start and end parameter, jittered by up to 16% of the band's length, so
##      both transverse edges come out ragged; the two outer lanes also wander
##      laterally, so the long edges are not ruled either.
##   3. Huge cropped letters. UVs are written per vertex from the band's own
##      arclength and cross-position, rotated per strip, at 0.22-0.46 m per tile,
##      and a glyph fills up to 0.89 of a tile — so a letter is routinely wider
##      than the 6-14 cm strip carrying it and gets cut off by the torn edge,
##      which is what the reference does everywhere.
##   4. Seven prints painted in code from rectangle-stroke glyphs (E F H I L T O
##      C U N Z, plus censor bars and rules; N and Z get real diagonals). Five are
##      guaranteed in every pool, so all three named colours are certain to land
##      on the figure whatever the seed does: black on white, white on black, red
##      on white, white on red, and newsprint — a warm grey sheet with columns of
##      dashed body text and rules under the big type. Two more are drawn at
##      random from the same five recipes, so no two strips need share a sheet.
##   5. The two mesh bodies, folded into this one. By seed 10-25 of the bands are
##      replaced with fine black polka-dot or pink honeycomb, one of the two
##      dominant, clustered by a favoured bone so a whole limb can go dotted.
##   6. Contrapposto. Weight on one leg with that hip riding high and its shoulder
##      dropping to answer, free leg bent with the heel lifted and the foot turned
##      out and trailing, spine bowed toward the standing side and twisted, one
##      arm raised overhead, the other hanging. Side, twist and reach are seeded.
##   7. Gesture in the paper. 3-6 bands peel: their stand-off ramps out and the
##      band flares toward its torn end, so paper lifts off the body. A sash of
##      2-3 bands crosses shoulder to opposite hip, and 2 more cross the skull.
##   8. Scraps. 2-5 torn sheets lie on the floor around the feet, laid at the
##      measured height of the figure's own lowest point so they settle flush.
##
## Given up: the group (the reference is a row of bodies leaning together), the
## lettered wall behind them, any suggestion that the letters spell words, the
## halftone photographs a real newspaper carries, and the difference in sheen
## between newsprint and poster stock — everything here is one matte paper.
##
## AXES
##   wrap    — what the paper is DOING to the body: bandage (wound flat and tight,
##             the statue as it stands today) · unravelling (every band lifts off
##             and streams away past the end of its own bone, thinning to thread) ·
##             sodden (the bandages sag off the bones and the legs drown to the
##             thigh in a poured slab of grey pulp) · quire (the strips widen into
##             flat pages standing off in five shells — the body as an open book) ·
##             shed (the wrap has slid off entirely: a bare paper mannequin
##             standing in a heap of its own strips).
##   edition — how many impressions the press pulled from this plate: single (one
##             body) · recto_verso (a second, smaller body struck back-to-back out
##             of the first) · run (the plate repeated on the same figure — three
##             heads and six arms, all of them wrapped) · offcuts (the wrap shrinks
##             to flecks clinging to the body while a blizzard of its own scraps
##             hangs in the air around it).

const TEX: int = 128
const TEXM: int = 64

# glyph strokes in unit space: [u0, v0, u1, v1] rect, or [u0, v0, u1, v1, kind]
# where kind 1 = diagonal band inside the box, kind 2 = anti-diagonal.
const GLYPHS: Array = [
	[[0.0, 0.0, 0.26, 1.0], [0.0, 0.0, 1.0, 0.23], [0.0, 0.39, 0.86, 0.61], [0.0, 0.77, 1.0, 1.0]],
	[[0.0, 0.0, 0.26, 1.0], [0.0, 0.0, 1.0, 0.23], [0.0, 0.39, 0.82, 0.61]],
	[[0.0, 0.0, 0.26, 1.0], [0.74, 0.0, 1.0, 1.0], [0.0, 0.39, 1.0, 0.61]],
	[[0.0, 0.0, 1.0, 0.22], [0.37, 0.0, 0.63, 1.0], [0.0, 0.78, 1.0, 1.0]],
	[[0.0, 0.0, 0.26, 1.0], [0.0, 0.77, 1.0, 1.0]],
	[[0.0, 0.0, 1.0, 0.23], [0.37, 0.0, 0.63, 1.0]],
	[[0.0, 0.0, 0.26, 1.0], [0.74, 0.0, 1.0, 1.0], [0.0, 0.0, 1.0, 0.23], [0.0, 0.77, 1.0, 1.0]],
	[[0.0, 0.0, 0.26, 1.0], [0.0, 0.0, 1.0, 0.23], [0.0, 0.77, 1.0, 1.0]],
	[[0.0, 0.0, 0.26, 1.0], [0.74, 0.0, 1.0, 1.0], [0.0, 0.77, 1.0, 1.0]],
	[[0.0, 0.0, 0.26, 1.0], [0.74, 0.0, 1.0, 1.0], [0.10, 0.0, 0.90, 1.0, 1.0]],
	[[0.0, 0.0, 1.0, 0.23], [0.0, 0.77, 1.0, 1.0], [0.06, 0.10, 0.94, 0.90, 2.0]],
	[[0.0, 0.31, 1.0, 0.69]],
	[[0.0, 0.08, 1.0, 0.19], [0.0, 0.63, 1.0, 0.74]],
	[[0.0, 0.0, 0.26, 1.0], [0.0, 0.0, 1.0, 0.23], [0.74, 0.0, 1.0, 0.61], [0.0, 0.39, 1.0, 0.61]],
]


static func describe() -> String:
	return "A standing figure wrapped head to foot in torn strips of printed paper, huge black, white and signal-red letters running at every angle, with bands of fine polka-dot and pink honeycomb mesh among them."


static func axes() -> Dictionary:
	return {
		"wrap": ["bandage", "unravelling", "sodden", "quire", "shed"],
		"edition": ["single", "recto_verso", "run", "offcuts"],
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var wrap_kind: String = str(opts.get("wrap", "bandage"))
	var edition: String = str(opts.get("edition", "single"))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# ---- the prints ---------------------------------------------------------
	var paper := Color("#F2EEE3")
	var news_p := Color("#DBD5C4")
	var ink_k := Color("#16160F")
	var red := Color("#CC1F17")
	var pink := Color("#EE7DB2")

	# five prints are always in the pool, so all three named colours are certain to
	# appear on the figure however the seed falls; two more are drawn at random.
	var pool: Array = []
	pool.append(_tex_type(rng, paper, ink_k, red, rng.randi_range(8, 12), false, 30.0, 108.0))
	pool.append(_tex_type(rng, ink_k, paper, red, rng.randi_range(8, 11), false, 34.0, 112.0))
	pool.append(_tex_type(rng, paper, red, ink_k, rng.randi_range(8, 11), false, 32.0, 106.0))
	pool.append(_tex_type(rng, red, paper, ink_k, rng.randi_range(7, 10), false, 34.0, 110.0))
	pool.append(_tex_type(rng, news_p, Color("#2B2822"), red, rng.randi_range(4, 7), true, 36.0, 100.0))
	for _e in range(2):
		var pick: int = rng.randi_range(0, 4)
		if pick == 0:
			pool.append(_tex_type(rng, paper, ink_k, red, rng.randi_range(9, 13), false, 26.0, 96.0))
		elif pick == 1:
			pool.append(_tex_type(rng, ink_k, paper, red, rng.randi_range(8, 12), false, 30.0, 114.0))
		elif pick == 2:
			pool.append(_tex_type(rng, paper, red, ink_k, rng.randi_range(8, 11), false, 32.0, 102.0))
		elif pick == 3:
			pool.append(_tex_type(rng, red, paper, ink_k, rng.randi_range(7, 10), false, 30.0, 108.0))
		else:
			pool.append(_tex_type(rng, news_p, Color("#26241E"), red, rng.randi_range(4, 7), true, 34.0, 104.0))
	var n_type: int = pool.size()

	var dot_a: int = pool.size()
	pool.append(_tex_dots(rng, 8, 2.1, paper, ink_k))
	pool.append(_tex_dots(rng, 11, 1.6, paper, ink_k))
	var hon_a: int = pool.size()
	pool.append(_tex_honey(rng, 7, 8, paper, pink))
	pool.append(_tex_honey(rng, 10, 11, Color("#FBEAF1"), pink))

	var core_tex: ImageTexture = _tex_type(rng, paper.darkened(0.06), ink_k, red, 8, false, 18.0, 52.0)
	var mat_core := StandardMaterial3D.new()
	mat_core.albedo_color = Color(0.80, 0.79, 0.76)
	mat_core.albedo_texture = core_tex
	mat_core.uv1_triplanar = true
	mat_core.uv1_world_triplanar = true
	mat_core.uv1_triplanar_sharpness = 1.0
	mat_core.uv1_scale = Vector3(2.6, 2.6, 2.6)
	mat_core.roughness = 0.9
	mat_core.metallic = 0.0

	# ---- this individual ----------------------------------------------------
	var ws: float = 1.0 if rng.randf() < 0.5 else -1.0
	var rs: float = -ws
	if rng.randf() < 0.28:
		rs = ws
	var body_k: float = rng.randf_range(0.96, 1.05)
	var twist: float = deg_to_rad(rng.randf_range(-13.0, 13.0))
	var reach: float = rng.randf_range(0.13, 0.22)
	var head_yaw: float = deg_to_rad(rng.randf_range(-24.0, 24.0))
	var head_tip: float = rng.randf_range(-0.10, 0.16)
	var bend: float = rng.randf_range(0.020, 0.038)

	# ---- skeleton -----------------------------------------------------------
	var ank_w := Vector3(ws * 0.072, 0.095 * body_k, -0.005)
	var kne_w := Vector3(ws * 0.082, 0.475 * body_k, 0.014)
	var hip_w := Vector3(ws * 0.098, 0.905 * body_k, 0.0)
	var ank_f := Vector3(-ws * 0.145, 0.098 * body_k, 0.118)
	var kne_f := Vector3(-ws * 0.136, 0.455 * body_k, -0.022)
	var hip_f := Vector3(-ws * 0.098, 0.862 * body_k, 0.010)
	var pel: Vector3 = (hip_w + hip_f) * 0.5

	var sk: Array = [
		pel + Vector3(0.0, 0.022, 0.002),
		Vector3(ws * bend, 1.010 * body_k, -0.008),
		Vector3(ws * bend * 1.05, 1.112 * body_k, 0.004),
		Vector3(ws * bend * 0.20, 1.212 * body_k, 0.014),
		Vector3(-ws * bend * 0.62, 1.302 * body_k, 0.004),
	]
	var s_top: Vector3 = sk[4]
	var tw_bs: Basis = Basis(Vector3.UP, twist)

	var neck_b: Vector3 = s_top + Vector3(0.0, 0.046, 0.004)
	var h_dir: Vector3 = (tw_bs * Vector3(sin(head_yaw) * 0.30, 0.96, -0.14 + head_tip * 0.5)).normalized()
	var h_ctr: Vector3 = neck_b + h_dir * (0.104 * body_k)
	var hz: Vector3 = h_dir
	var hx: Vector3 = Vector3.UP.cross(hz)
	if hx.length() < 0.02:
		hx = Vector3.RIGHT
	hx = hx.normalized()
	var hy: Vector3 = hz.cross(hx).normalized()
	var head_bs := Basis(hx, hy, hz)
	var crown: Vector3 = h_ctr + h_dir * (0.086 * body_k)

	# the loaded hip rides high, so the shoulder above it drops to answer it
	var sh_off: float = 0.178 * body_k
	var drop_r: float = -0.022 if rs == ws else 0.022
	var drop_l: float = 0.022 if rs == ws else -0.022
	var sh_r: Vector3 = s_top + tw_bs * Vector3(rs * sh_off, drop_r, 0.004)
	var sh_l: Vector3 = s_top + tw_bs * Vector3(-rs * sh_off, drop_l, 0.004)
	var el_r: Vector3 = sh_r + Vector3(rs * 0.138, 0.128, -0.056)
	var hnd_r: Vector3 = el_r + Vector3(rs * 0.008, reach, 0.048)
	var el_l: Vector3 = sh_l + Vector3(-rs * 0.048, -0.256, -0.030)
	var hnd_l: Vector3 = el_l + Vector3(-rs * 0.046, -0.244, 0.058)
	var tip_r: Vector3 = hnd_r + Vector3(rs * 0.006, 0.062, 0.010)
	var tip_l: Vector3 = hnd_l + Vector3(-rs * 0.008, -0.070, 0.014)

	# ---- the paper body under the wrap -------------------------------------
	_ball(root, ank_w + Vector3(0.0, -0.058, -0.040), Vector3(0.050, 0.030, 0.098), Basis(Vector3.UP, ws * 0.14), mat_core)
	_ball(root, ank_w + Vector3(0.0, -0.062, -0.120), Vector3(0.046, 0.026, 0.042), Basis(Vector3.UP, ws * 0.14), mat_core)
	var fb_f: Basis = Basis(Vector3.UP, -ws * 0.40) * Basis(Vector3.RIGHT, -0.26)
	_ball(root, ank_f + Vector3(-ws * 0.010, -0.048, -0.048), Vector3(0.048, 0.030, 0.096), fb_f, mat_core)
	_ball(root, ank_f + fb_f * Vector3(0.0, -0.050, -0.122), Vector3(0.044, 0.026, 0.040), fb_f, mat_core)

	_limb(root, ank_w, kne_w, 0.056 * body_k, mat_core)
	_ball(root, kne_w, Vector3(0.066, 0.070, 0.068) * body_k, Basis(), mat_core)
	_limb(root, kne_w, hip_w, 0.080 * body_k, mat_core)
	_limb(root, ank_f, kne_f, 0.055 * body_k, mat_core)
	_ball(root, kne_f, Vector3(0.068, 0.072, 0.070) * body_k, Basis(), mat_core)
	_limb(root, kne_f, hip_f, 0.080 * body_k, mat_core)
	_ball(root, hip_w, Vector3(0.086, 0.084, 0.096) * body_k, Basis(), mat_core)
	_ball(root, hip_f, Vector3(0.086, 0.084, 0.096) * body_k, Basis(), mat_core)
	_ball(root, pel + Vector3(0.0, 0.006, 0.004), Vector3(0.142, 0.108, 0.116) * body_k, Basis(Vector3.UP, twist * 0.3), mat_core)

	var t_kx: Array = [0.140, 0.116, 0.124, 0.150, 0.156]
	var t_kz: Array = [0.108, 0.094, 0.102, 0.114, 0.106]
	for i in range(8):
		var t: float = float(i) / 7.0
		var q: Vector3 = _poly_at(sk, t)
		var wx: float = _key_at(t_kx, t) * body_k
		var wz: float = _key_at(t_kz, t) * body_k
		var bs_i: Basis = Basis(Vector3.UP, twist * t)
		_ball(root, q, Vector3(wx, 0.082, wz), bs_i, mat_core)

	_ball(root, sh_r, Vector3(0.074, 0.068, 0.080) * body_k, Basis(), mat_core)
	_ball(root, sh_l, Vector3(0.074, 0.068, 0.080) * body_k, Basis(), mat_core)
	_limb(root, neck_b + Vector3(0.0, -0.030, 0.0), neck_b + h_dir * 0.072, 0.056 * body_k, mat_core)
	_ball(root, h_ctr, Vector3(0.088, 0.104, 0.096) * body_k, head_bs, mat_core)
	_ball(root, h_ctr + h_dir * 0.046, Vector3(0.078, 0.070, 0.084) * body_k, head_bs, mat_core)
	_ball(root, h_ctr - h_dir * 0.052 + head_bs * Vector3(0.0, -0.030, 0.0), Vector3(0.070, 0.058, 0.074) * body_k, head_bs, mat_core)

	_limb(root, sh_r, el_r, 0.052 * body_k, mat_core)
	_ball(root, el_r, Vector3(0.050, 0.050, 0.052) * body_k, Basis(), mat_core)
	_limb(root, el_r, hnd_r, 0.044 * body_k, mat_core)
	_ball(root, hnd_r, Vector3(0.046, 0.052, 0.042) * body_k, Basis(), mat_core)
	_ball(root, tip_r, Vector3(0.036, 0.042, 0.034) * body_k, Basis(), mat_core)
	_limb(root, sh_l, el_l, 0.052 * body_k, mat_core)
	_ball(root, el_l, Vector3(0.050, 0.050, 0.052) * body_k, Basis(), mat_core)
	_limb(root, el_l, hnd_l, 0.044 * body_k, mat_core)
	_ball(root, hnd_l, Vector3(0.046, 0.052, 0.042) * body_k, Basis(), mat_core)
	_ball(root, tip_l, Vector3(0.036, 0.040, 0.034) * body_k, Basis(), mat_core)

	# ---- bones for the wrap -------------------------------------------------
	var bones: Array = []
	bones.append(_bone(ank_w, kne_w, 0.050, 0.066, 3, 5, 0.060, 0.130))
	bones.append(_bone(kne_w, hip_w, 0.070, 0.092, 3, 5, 0.070, 0.140))
	bones.append(_bone(ank_f, kne_f, 0.050, 0.068, 3, 5, 0.060, 0.130))
	bones.append(_bone(kne_f, hip_f, 0.070, 0.092, 3, 5, 0.070, 0.140))
	bones.append(_bone(pel + Vector3(0.0, -0.050, 0.0), pel + Vector3(0.0, 0.058, 0.0), 0.138, 0.128, 3, 4, 0.080, 0.140))
	bones.append(_bone(sk[0], sk[1], 0.130, 0.112, 3, 4, 0.075, 0.140))
	bones.append(_bone(sk[1], sk[2], 0.112, 0.124, 3, 4, 0.075, 0.140))
	bones.append(_bone(sk[2], sk[3], 0.124, 0.146, 3, 4, 0.080, 0.140))
	bones.append(_bone(sk[3], sk[4], 0.146, 0.150, 3, 4, 0.080, 0.140))
	bones.append(_bone(neck_b + Vector3(0.0, -0.020, 0.0), neck_b + h_dir * 0.060, 0.062, 0.058, 2, 3, 0.060, 0.090))
	bones.append(_bone(neck_b + h_dir * 0.030, crown, 0.086, 0.058, 3, 4, 0.060, 0.100))
	bones.append(_bone(h_ctr - hx * 0.110, h_ctr + hx * 0.110, 0.084, 0.084, 2, 2, 0.060, 0.100))
	bones.append(_bone(sh_r, el_r, 0.056, 0.048, 3, 4, 0.060, 0.120))
	bones.append(_bone(el_r, hnd_r, 0.048, 0.042, 3, 4, 0.060, 0.115))
	bones.append(_bone(sh_l, el_l, 0.056, 0.048, 3, 4, 0.060, 0.120))
	bones.append(_bone(el_l, hnd_l, 0.048, 0.042, 3, 4, 0.060, 0.115))
	bones.append(_bone(hnd_r, tip_r, 0.044, 0.034, 1, 2, 0.060, 0.085))
	bones.append(_bone(hnd_l, tip_l, 0.044, 0.034, 1, 2, 0.060, 0.085))
	bones.append(_bone(ank_w + Vector3(0.0, -0.056, 0.010), ank_w + Vector3(0.0, -0.062, -0.118), 0.054, 0.044, 2, 3, 0.060, 0.095))
	bones.append(_bone(ank_f + Vector3(0.0, -0.044, 0.014), ank_f + fb_f * Vector3(0.0, -0.048, -0.118), 0.054, 0.044, 2, 3, 0.060, 0.095))
	var sash_end: Vector3 = hip_f if rs != ws else hip_w
	bones.append(_bone(sh_r + Vector3(0.0, -0.020, 0.0), sash_end + Vector3(0.0, 0.030, 0.0), 0.118, 0.128, 2, 3, 0.100, 0.140))

	# ---- edition "run": the plate struck again on the same body -------------
	# two more heads off the one neck and four more arms off the two shoulders,
	# added as core AND as bones, so the wrap covers them like everything else.
	if edition == "run":
		for hi in range(2):
			var sgn_h: float = 1.0 if hi == 0 else -1.0
			var hc2: Vector3 = h_ctr + hx * (sgn_h * rng.randf_range(0.125, 0.185)) + h_dir * rng.randf_range(-0.060, 0.030)
			var hd2: Vector3 = (h_dir + hx * (sgn_h * rng.randf_range(0.30, 0.62))).normalized()
			_limb(root, neck_b, hc2 - hd2 * 0.072, 0.044 * body_k, mat_core)
			_ball(root, hc2, Vector3(0.078, 0.094, 0.086) * body_k, head_bs, mat_core)
			_ball(root, hc2 + hd2 * 0.042, Vector3(0.068, 0.062, 0.074) * body_k, head_bs, mat_core)
			bones.append(_bone(neck_b, hc2 - hd2 * 0.048, 0.052, 0.062, 2, 3, 0.060, 0.100))
			bones.append(_bone(hc2 - hd2 * 0.038, hc2 + hd2 * (0.082 * body_k), 0.084, 0.056, 3, 4, 0.060, 0.100))
		for ai in range(4):
			var from_r: bool = ai < 2
			var sh0: Vector3 = sh_r if from_r else sh_l
			var side_s: float = rs if from_r else -rs
			var flip_a: float = 1.0 if (ai % 2) == 0 else -1.0
			var spread: float = deg_to_rad(rng.randf_range(22.0, 76.0)) * flip_a
			var dirv: Vector3 = Vector3(side_s * cos(spread), sin(spread) * 0.92, rng.randf_range(-0.34, 0.16)).normalized()
			var el2: Vector3 = sh0 + dirv * rng.randf_range(0.155, 0.215)
			var dir2: Vector3 = (dirv + Vector3(0.0, rng.randf_range(-0.60, 0.60), rng.randf_range(-0.38, 0.38))).normalized()
			var hn2: Vector3 = el2 + dir2 * rng.randf_range(0.145, 0.220)
			_limb(root, sh0, el2, 0.046 * body_k, mat_core)
			_ball(root, el2, Vector3(0.046, 0.046, 0.048) * body_k, Basis(), mat_core)
			_limb(root, el2, hn2, 0.040 * body_k, mat_core)
			_ball(root, hn2, Vector3(0.042, 0.048, 0.040) * body_k, Basis(), mat_core)
			bones.append(_bone(sh0, el2, 0.052, 0.046, 3, 4, 0.060, 0.115))
			bones.append(_bone(el2, hn2, 0.046, 0.040, 3, 4, 0.060, 0.110))

	# ---- strip specs --------------------------------------------------------
	var specs: Array = []
	for bi in range(bones.size()):
		var bn: Dictionary = bones[bi]
		var ba: Vector3 = bn["a"]
		var bb: Vector3 = bn["b"]
		var r0: float = bn["r0"]
		var r1: float = bn["r1"]
		var nlo: int = bn["nmin"]
		var nhi: int = bn["nmax"]
		var wlo: float = bn["wlo"]
		var whi: float = bn["whi"]
		var blen: float = maxf((bb - ba).length(), 0.02)
		var n: int = rng.randi_range(nlo, nhi)
		var torso_bone: bool = bi >= 4 and bi <= 8
		for i in range(n):
			var fi: float = float(i)
			var ct: float = (fi + 0.5) / float(n) + rng.randf_range(-0.22, 0.22) / float(n)
			var spanf: float = (1.0 / float(n)) * rng.randf_range(1.5, 2.4)
			var wid: float = rng.randf_range(wlo, whi)
			var sheet: bool = torso_bone and rng.randf() < 0.34
			if sheet:
				wid = maxf(wid, whi * 0.92)
				spanf *= 1.25
			var t0: float = clampf(ct - spanf * 0.5, -0.17, 0.86)
			var t1: float = clampf(ct + spanf * 0.5, t0 + 0.14, 1.17)
			var span: float = t1 - t0
			var seg_len: float = blen * span
			var turns: float = seg_len / maxf(wid * rng.randf_range(0.80, 1.55), 0.02)
			if sheet:
				turns *= 0.20
			turns = clampf(turns, 0.22, 2.60)
			if rng.randf() < 0.5:
				turns = -turns
			var off0: float = rng.randf_range(0.004, 0.030)
			var r_mid: float = (r0 + r1) * 0.5 + off0
			var cir: float = TAU * r_mid * absf(turns)
			var alen: float = sqrt(cir * cir + seg_len * seg_len)
			var steps: int = clampi(int(round(alen / 0.034)), 10, 20)
			var lanes: int = 5
			var tear_amp: float = span * rng.randf_range(0.06, 0.16)
			var tear_a: Array = []
			var tear_b: Array = []
			var wob: Array = []
			var wob_ph: Array = []
			for j in range(lanes):
				tear_a.append(rng.randf_range(-tear_amp * 0.45, tear_amp * 0.85))
				tear_b.append(rng.randf_range(-tear_amp * 0.85, tear_amp * 0.45))
				var ew: float = rng.randf_range(0.0, 0.003)
				if j == 0 or j == lanes - 1:
					ew = rng.randf_range(0.002, 0.009)
				wob.append(ew)
				wob_ph.append(rng.randf_range(0.0, TAU))
			var bow_dir := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.3, 0.3), rng.randf_range(-1.0, 1.0))
			if bow_dir.length() < 0.01:
				bow_dir = Vector3.RIGHT
			specs.append({
				"a": ba, "b": bb, "r0": r0, "r1": r1,
				"t0": t0, "t1": t1,
				"phase": rng.randf_range(0.0, TAU), "turns": turns,
				"w0": wid, "w1": wid,
				"thick": rng.randf_range(0.0020, 0.0030),
				"off0": off0, "off1": off0,
				"bow": bow_dir.normalized() * rng.randf_range(0.0, 0.010),
				"lanes": lanes, "steps": steps,
				"uv_tile": rng.randf_range(0.22, 0.46),
				"uv_rot": rng.randf_range(0.0, TAU),
				"uv_off": Vector2(rng.randf_range(0.0, 4.0), rng.randf_range(0.0, 4.0)),
				"tear_a": tear_a, "tear_b": tear_b,
				"wob": wob, "wob_ph": wob_ph,
				"bone": bi,
			})

	# peeling bands — the stand-off ramps out and the torn end flares open
	var n_peel: int = rng.randi_range(3, 6)
	for _p in range(n_peel):
		var pi_idx: int = rng.randi_range(0, specs.size() - 1)
		var sp_p: Dictionary = specs[pi_idx]
		var o0: float = sp_p["off0"]
		sp_p["off1"] = o0 + rng.randf_range(0.030, 0.085)
		var wp: float = sp_p["w0"]
		sp_p["w1"] = wp * rng.randf_range(1.10, 1.50)

	# ---- which bands are polka-dot or honeycomb -----------------------------
	var n_mesh: int = rng.randi_range(10, 25)
	n_mesh = mini(n_mesh, int(float(specs.size()) * 0.40))
	var fav: int = rng.randi_range(0, bones.size() - 1)
	var dot_led: bool = rng.randf() < 0.55
	var scores: Array = []
	for i in range(specs.size()):
		var sp_s: Dictionary = specs[i]
		var sv: float = rng.randf()
		if int(sp_s["bone"]) == fav:
			sv += 0.62
		scores.append(sv)
	var picked: Dictionary = {}
	for _m in range(n_mesh):
		var best: int = -1
		var best_v: float = -1.0
		for i in range(scores.size()):
			var v: float = scores[i]
			if v > best_v and not picked.has(i):
				best_v = v
				best = i
		if best >= 0:
			picked[best] = true

	# ---- wrap: what the paper is doing --------------------------------------
	# every band already knows its bone, span, pitch and stand-off; the axis
	# rewrites those numbers before a single strip is swept.
	var shed_floor: float = 0.0
	if wrap_kind == "shed":
		# the core body is standing and the wrap has not been built yet, so this
		# reads the naked mannequin's own lowest point to lay the heap on.
		var core_box: AABB = _union_aabb(root)
		shed_floor = core_box.position.y
	if wrap_kind != "bandage":
		for i in range(specs.size()):
			var sp_w: Dictionary = specs[i]
			if wrap_kind == "unravelling":
				var u_off: float = float(sp_w["off0"])
				sp_w["off1"] = u_off + rng.randf_range(0.055, 0.150)
				sp_w["t1"] = float(sp_w["t1"]) + rng.randf_range(0.20, 0.58)
				sp_w["turns"] = float(sp_w["turns"]) * rng.randf_range(1.8, 3.2)
				var u_w: float = float(sp_w["w0"])
				sp_w["w0"] = u_w * rng.randf_range(0.55, 0.85)
				sp_w["w1"] = u_w * rng.randf_range(0.12, 0.32)
				sp_w["thick"] = 0.0016
				sp_w["steps"] = 22
				sp_w["bow"] = Vector3(rng.randf_range(-0.022, 0.022), rng.randf_range(0.008, 0.048), rng.randf_range(-0.022, 0.022))
			elif wrap_kind == "sodden":
				var sag: float = rng.randf_range(0.045, 0.135)
				sp_w["bow"] = Vector3(rng.randf_range(-0.020, 0.020), -sag, rng.randf_range(-0.020, 0.020))
				sp_w["turns"] = float(sp_w["turns"]) * rng.randf_range(0.18, 0.42)
				var s_w: float = float(sp_w["w0"])
				sp_w["w0"] = s_w * rng.randf_range(1.15, 1.60)
				sp_w["w1"] = s_w * rng.randf_range(1.25, 1.90)
				sp_w["thick"] = rng.randf_range(0.0040, 0.0065)
				sp_w["off1"] = float(sp_w["off0"]) + rng.randf_range(0.0, 0.030)
				sp_w["uv_tile"] = float(sp_w["uv_tile"]) * 1.35
			elif wrap_kind == "quire":
				var q_w: float = float(sp_w["w0"])
				var q_s: float = rng.randf_range(1.9, 2.9)
				sp_w["w0"] = minf(q_w * q_s, 0.26)
				sp_w["w1"] = minf(q_w * q_s * rng.randf_range(0.85, 1.15), 0.28)
				sp_w["turns"] = rng.randf_range(-0.09, 0.09)
				sp_w["thick"] = rng.randf_range(0.0055, 0.0090)
				var layer: int = i % 5
				var q_off: float = 0.008 + float(layer) * rng.randf_range(0.016, 0.026)
				sp_w["off0"] = q_off
				sp_w["off1"] = q_off + rng.randf_range(0.008, 0.055)
				sp_w["uv_tile"] = rng.randf_range(0.30, 0.60)
				sp_w["bow"] = Vector3.ZERO
			elif wrap_kind == "shed":
				var ang_s: float = rng.randf_range(0.0, TAU)
				var dist_s: float = rng.randf_range(0.10, 0.44)
				var lie_y: float = shed_floor + rng.randf_range(0.0, 0.055)
				var ctr_s := Vector3(cos(ang_s) * dist_s, lie_y, sin(ang_s) * dist_s)
				var da_s: float = rng.randf_range(0.0, TAU)
				var ldir_s := Vector3(cos(da_s), rng.randf_range(-0.10, 0.10), sin(da_s))
				var slen_s: float = rng.randf_range(0.10, 0.30)
				sp_w["a"] = ctr_s - ldir_s * (slen_s * 0.5)
				sp_w["b"] = ctr_s + ldir_s * (slen_s * 0.5)
				sp_w["r0"] = 0.002
				sp_w["r1"] = 0.002
				sp_w["t0"] = 0.0
				sp_w["t1"] = 1.0
				sp_w["turns"] = rng.randf_range(-0.30, 0.30)
				sp_w["off0"] = 0.003
				sp_w["off1"] = 0.003 + rng.randf_range(0.0, 0.045)
				sp_w["bow"] = Vector3(0.0, rng.randf_range(0.004, 0.030), 0.0)

	# ---- build the wrap -----------------------------------------------------
	var band_from: int = root.get_child_count()
	for i in range(specs.size()):
		var sp: Dictionary = specs[i]
		var tex_i: int = rng.randi_range(0, n_type - 1)
		if picked.has(i):
			var dot_bias: float = 0.74 if dot_led else 0.26
			var want_dot: bool = rng.randf() < dot_bias
			if want_dot:
				tex_i = dot_a + rng.randi_range(0, 1)
			else:
				tex_i = hon_a + rng.randi_range(0, 1)
			sp["uv_tile"] = rng.randf_range(0.09, 0.19)
		var g: float = rng.randf_range(0.90, 1.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(g, g, g * 0.995)
		mat.albedo_texture = pool[tex_i]
		mat.roughness = 0.9
		mat.metallic = 0.0
		_strip(root, sp, mat)
	var band_to: int = root.get_child_count()

	# ---- torn scraps on the floor, seated on the figure's own lowest point --
	# a curled scrap tips its width out of horizontal, so each one is measured
	# and dropped onto the same ground plane rather than trusted to land there.
	var pre: AABB = _union_aabb(root)
	var floor_y: float = pre.position.y
	var n_scrap: int = rng.randi_range(2, 5)
	for _s in range(n_scrap):
		var ang: float = rng.randf_range(0.0, TAU)
		var dist: float = rng.randf_range(0.15, 0.28)
		var ctr := Vector3(cos(ang) * dist, floor_y, sin(ang) * dist)
		var da: float = rng.randf_range(0.0, TAU)
		var ldir := Vector3(cos(da), 0.0, sin(da))
		var slen: float = rng.randf_range(0.12, 0.26)
		var lanes_s: int = 5
		var tear_as: Array = []
		var tear_bs: Array = []
		var wob_s: Array = []
		var wob_ps: Array = []
		for j in range(lanes_s):
			tear_as.append(rng.randf_range(-0.05, 0.10))
			tear_bs.append(rng.randf_range(-0.10, 0.05))
			var ew2: float = rng.randf_range(0.0, 0.004)
			if j == 0 or j == lanes_s - 1:
				ew2 = rng.randf_range(0.003, 0.011)
			wob_s.append(ew2)
			wob_ps.append(rng.randf_range(0.0, TAU))
		var t_scr: int = rng.randi_range(0, n_type - 1)
		var gs: float = rng.randf_range(0.90, 1.0)
		var mat_s := StandardMaterial3D.new()
		mat_s.albedo_color = Color(gs, gs, gs)
		mat_s.albedo_texture = pool[t_scr]
		mat_s.roughness = 0.9
		mat_s.metallic = 0.0
		var scrap: MeshInstance3D = _strip(root, {
			"a": ctr - ldir * (slen * 0.5), "b": ctr + ldir * (slen * 0.5),
			"r0": 0.002, "r1": 0.002, "t0": 0.0, "t1": 1.0,
			"phase": 0.0, "turns": rng.randf_range(-0.17, 0.17),
			"w0": rng.randf_range(0.070, 0.140), "w1": rng.randf_range(0.070, 0.140),
			"thick": 0.0022,
			"off0": 0.004, "off1": 0.004 + rng.randf_range(0.0, 0.030),
			"bow": Vector3(0.0, rng.randf_range(0.0, 0.006), 0.0),
			"lanes": lanes_s, "steps": 14,
			"uv_tile": rng.randf_range(0.18, 0.36),
			"uv_rot": rng.randf_range(0.0, TAU),
			"uv_off": Vector2(rng.randf_range(0.0, 4.0), rng.randf_range(0.0, 4.0)),
			"tear_a": tear_as, "tear_b": tear_bs,
			"wob": wob_s, "wob_ph": wob_ps,
			"bone": -1,
		}, mat_s)
		if scrap.mesh != null:
			var sbox: AABB = scrap.transform * scrap.mesh.get_aabb()
			var lower: float = floor_y - sbox.position.y
			scrap.transform = Transform3D(scrap.transform.basis, scrap.transform.origin + Vector3(0.0, lower, 0.0))

	# ---- the pour, for the sodden wrap --------------------------------------
	# the paper has gone to pulp and set again; the figure is standing in it to
	# the thigh. Measured off what is already built, so it seats on the ground.
	if wrap_kind == "sodden":
		var wet: AABB = _union_aabb(root)
		var wet_y: float = wet.position.y
		var pulp_tex: ImageTexture = _tex_type(rng, news_p.darkened(0.10), ink_k, red, 5, true, 22.0, 60.0)
		var mat_pulp := StandardMaterial3D.new()
		mat_pulp.albedo_color = Color(0.72, 0.71, 0.67)
		mat_pulp.albedo_texture = pulp_tex
		mat_pulp.uv1_triplanar = true
		mat_pulp.uv1_world_triplanar = true
		mat_pulp.uv1_triplanar_sharpness = 1.0
		mat_pulp.uv1_scale = Vector3(2.2, 2.2, 2.2)
		mat_pulp.roughness = 0.62
		mat_pulp.metallic = 0.0
		var lvl: float = rng.randf_range(0.34, 0.52)
		var n_pour: int = rng.randi_range(13, 18)
		for pi2 in range(n_pour):
			var uu2: float = float(pi2) / float(n_pour - 1)
			var pour_y: float = wet_y + uu2 * lvl
			var lo_r: float = rng.randf_range(0.30, 0.40)
			var hi_r: float = rng.randf_range(0.11, 0.17)
			var pour_r: float = lerpf(lo_r, hi_r, uu2)
			var jit := Vector3(rng.randf_range(-0.022, 0.022), 0.0, rng.randf_range(-0.022, 0.022))
			var pour_h: float = maxf(lvl * 0.16, 0.030)
			_ball(root, Vector3(0.0, pour_y, 0.0) + jit, Vector3(pour_r, pour_h, pour_r * rng.randf_range(0.86, 1.12)), Basis(Vector3.UP, rng.randf_range(0.0, TAU)), mat_pulp)

	# ---- edition: what the press did with the plate --------------------------
	if edition == "recto_verso":
		# a second impression struck through the back of the first
		var kids: Array = []
		for ch0 in root.get_children():
			if ch0 is MeshInstance3D:
				kids.append(ch0)
		var sc2: float = rng.randf_range(0.78, 0.93)
		var yaw2: float = PI + deg_to_rad(rng.randf_range(-24.0, 24.0))
		var lean2: Basis = Basis(Vector3.UP, yaw2) * Basis(Vector3.RIGHT, deg_to_rad(rng.randf_range(-9.0, 9.0)))
		var back2 := Vector3(rng.randf_range(-0.06, 0.06), rng.randf_range(-0.02, 0.05), -rng.randf_range(0.10, 0.24))
		var xf2 := Transform3D(lean2.scaled(Vector3(sc2, sc2, sc2)), back2)
		for k2 in range(kids.size()):
			if root.get_child_count() >= 250:
				break
			var src2: MeshInstance3D = kids[k2]
			var cp2 := MeshInstance3D.new()
			cp2.mesh = src2.mesh
			cp2.material_override = src2.material_override
			cp2.transform = xf2 * src2.transform
			root.add_child(cp2)
	elif edition == "offcuts":
		# the wrap comes apart into a weather of its own scraps
		var band_kids: Array = []
		for ci in range(band_from, mini(band_to, root.get_child_count())):
			var chb: Node = root.get_child(ci)
			if chb is MeshInstance3D:
				band_kids.append(chb)
		if band_kids.size() > 0:
			var n_have: int = root.get_child_count()
			var n_swarm: int = clampi(206 - n_have, 40, 104)
			for _sw in range(n_swarm):
				var src3: MeshInstance3D = band_kids[rng.randi_range(0, band_kids.size() - 1)]
				var s3: float = rng.randf_range(0.16, 0.44)
				var ang3: float = rng.randf_range(0.0, TAU)
				var rad3: float = rng.randf_range(0.10, 0.50)
				var hgt3: float = rng.randf_range(0.02, 1.60)
				var rb3: Basis = Basis(Vector3.UP, rng.randf_range(0.0, TAU)) * Basis(Vector3.RIGHT, rng.randf_range(0.0, TAU)) * Basis(Vector3.FORWARD, rng.randf_range(0.0, TAU))
				var cp3 := MeshInstance3D.new()
				cp3.mesh = src3.mesh
				cp3.material_override = src3.material_override
				cp3.transform = Transform3D(rb3.scaled(Vector3(s3, s3, s3)) * src3.transform.basis, Vector3(cos(ang3) * rad3, hgt3, sin(ang3) * rad3))
				root.add_child(cp3)
			for ci3 in range(band_kids.size()):
				if rng.randf() < 0.45:
					var bm3: MeshInstance3D = band_kids[ci3]
					var sh3: float = rng.randf_range(0.22, 0.45)
					bm3.transform = Transform3D(bm3.transform.basis.scaled(Vector3(sh3, sh3, sh3)), bm3.transform.origin)

	# ---- measured settle ----------------------------------------------------
	var box: AABB = _union_aabb(root)
	var kx: float = 1.20 / maxf(box.size.x, 0.001)
	var kz: float = 1.20 / maxf(box.size.z, 0.001)
	var ky: float = 1.68 / maxf(box.size.y, 0.001)
	var kfit: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kfit < 1.0:
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cm: MeshInstance3D = ch
			var tf: Transform3D = cm.transform
			cm.transform = Transform3D(tf.basis.scaled(Vector3(kfit, kfit, kfit)), tf.origin * kfit)
		box = _union_aabb(root)
	var mid: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-mid.x, -box.position.y, -mid.z)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm2: MeshInstance3D = ch
		cm2.transform = Transform3D(cm2.transform.basis, cm2.transform.origin + shift)


# ---------------------------------------------------------------------------
# the wrapping band

static func _bone(a: Vector3, b: Vector3, r0: float, r1: float, nmin: int, nmax: int, wlo: float, whi: float) -> Dictionary:
	return {"a": a, "b": b, "r0": r0, "r1": r1, "nmin": nmin, "nmax": nmax, "wlo": wlo, "whi": whi}


static func _strip(root: Node3D, sp: Dictionary, mat: StandardMaterial3D) -> MeshInstance3D:
	var a: Vector3 = sp["a"]
	var b: Vector3 = sp["b"]
	var r0: float = sp["r0"]
	var r1: float = sp["r1"]
	var t0: float = sp["t0"]
	var t1: float = sp["t1"]
	var phase: float = sp["phase"]
	var turns: float = sp["turns"]
	var w0: float = sp["w0"]
	var w1: float = sp["w1"]
	var thick: float = sp["thick"]
	var off0: float = sp["off0"]
	var off1: float = sp["off1"]
	var bow: Vector3 = sp["bow"]
	var lanes: int = sp["lanes"]
	var steps: int = sp["steps"]
	var uv_raw: float = sp["uv_tile"]
	var uv_tile: float = maxf(uv_raw, 0.02)
	var uv_rot: float = sp["uv_rot"]
	var uv_off: Vector2 = sp["uv_off"]
	var tear_a: Array = sp["tear_a"]
	var tear_b: Array = sp["tear_b"]
	var wob: Array = sp["wob"]
	var wob_ph: Array = sp["wob_ph"]

	var seg: Vector3 = b - a
	var ln: float = maxf(seg.length(), 0.001)
	var ax: Vector3 = seg / ln
	var uax: Vector3 = Vector3.UP - ax * Vector3.UP.dot(ax)
	if uax.length() < 0.12:
		uax = Vector3.RIGHT - ax * Vector3.RIGHT.dot(ax)
	if uax.length() < 0.001:
		uax = Vector3.FORWARD
	uax = uax.normalized()
	var vax: Vector3 = ax.cross(uax).normalized()
	var span: float = maxf(t1 - t0, 0.04)
	var r_mid: float = lerpf(r0, r1, clampf((t0 + t1) * 0.5, 0.0, 1.0)) + (off0 + off1) * 0.5
	var cir: float = TAU * r_mid * absf(turns)
	var axl: float = ln * span
	var arclen: float = sqrt(cir * cir + axl * axl)
	# the band is built around its own middle so the node carries a real origin
	var anchor: Vector3 = a + ax * (ln * (t0 + t1) * 0.5)

	# helix centre-line, one lane at a time, each with its own torn span
	var gp: Array = []
	var gr: Array = []
	var gf: Array = []
	for j in range(lanes):
		var sa: float = t0 + float(tear_a[j])
		var sb: float = t1 + float(tear_b[j])
		var rowp: Array = []
		var rowr: Array = []
		var rowf: Array = []
		for k in range(steps + 1):
			var kk: float = float(k) / float(steps)
			var s: float = lerpf(sa, sb, kk)
			var f: float = (s - t0) / span
			var scl: float = clampf(s, 0.0, 1.0)
			var ctr: Vector3 = a + ax * (ln * s) + bow * sin(PI * scl)
			var rad: float = lerpf(r0, r1, scl) + lerpf(off0, off1, clampf(f, 0.0, 1.0))
			var th: float = phase + turns * TAU * f
			var rdir: Vector3 = uax * cos(th) + vax * sin(th)
			rowp.append(ctr + rdir * rad)
			rowr.append(rdir)
			rowf.append(f)
		gp.append(rowp)
		gr.append(rowr)
		gf.append(rowf)

	# frame and skin
	var vf: Array = []
	var vb: Array = []
	var vn: Array = []
	var vbn: Array = []
	var vt: Array = []
	var vu: Array = []
	for j in range(lanes):
		var pj: Array = gp[j]
		var rj: Array = gr[j]
		var fj: Array = gf[j]
		var lane_u: float = float(j) / float(lanes - 1) - 0.5
		var ew: float = wob[j]
		var eph: float = wob_ph[j]
		var rf: Array = []
		var rb: Array = []
		var rn: Array = []
		var rbn: Array = []
		var rt: Array = []
		var ru: Array = []
		for k in range(steps + 1):
			var ka: int = maxi(k - 1, 0)
			var kb: int = mini(k + 1, steps)
			var pa: Vector3 = pj[ka]
			var pb: Vector3 = pj[kb]
			var tdir: Vector3 = pb - pa
			if tdir.length() < 0.000001:
				tdir = ax
			tdir = tdir.normalized()
			var ndir: Vector3 = rj[k]
			ndir = ndir - tdir * ndir.dot(tdir)
			if ndir.length() < 0.000001:
				ndir = uax
			ndir = ndir.normalized()
			var bdir: Vector3 = ndir.cross(tdir).normalized()
			var fk: float = fj[k]
			var wid: float = lerpf(w0, w1, clampf(fk, 0.0, 1.0))
			var cw: float = lane_u * wid + ew * sin(fk * 8.3 + eph)
			var mp: Vector3 = pj[k] + bdir * cw - anchor
			rf.append(mp + ndir * (thick * 0.5))
			rb.append(mp - ndir * (thick * 0.5))
			rn.append(ndir)
			rbn.append(bdir)
			rt.append(tdir)
			var uu: float = cw / uv_tile
			var vv: float = (fk * arclen) / uv_tile
			ru.append(Vector2(uu * cos(uv_rot) - vv * sin(uv_rot) + uv_off.x, uu * sin(uv_rot) + vv * cos(uv_rot) + uv_off.y))
		vf.append(rf)
		vb.append(rb)
		vn.append(rn)
		vbn.append(rbn)
		vt.append(rt)
		vu.append(ru)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lift: float = thick * 3.0 + 0.002

	st.set_smooth_group(0)
	for j in range(lanes - 1):
		var fa: Array = vf[j]
		var fb: Array = vf[j + 1]
		var na: Array = vn[j]
		var ua: Array = vu[j]
		var ub: Array = vu[j + 1]
		for k in range(steps):
			var p0: Vector3 = fa[k]
			var p1: Vector3 = fb[k]
			var p2: Vector3 = fb[k + 1]
			var p3: Vector3 = fa[k + 1]
			var nn: Vector3 = na[k]
			var cen: Vector3 = (p0 + p1 + p2 + p3) * 0.25
			_quad_uv(st, p0, p1, p2, p3, ua[k], ub[k], ub[k + 1], ua[k + 1], cen - nn * lift)

	st.set_smooth_group(1)
	for j in range(lanes - 1):
		var ga: Array = vb[j]
		var gb: Array = vb[j + 1]
		var na2: Array = vn[j]
		var ua2: Array = vu[j]
		var ub2: Array = vu[j + 1]
		for k in range(steps):
			var q0: Vector3 = ga[k]
			var q1: Vector3 = gb[k]
			var q2: Vector3 = gb[k + 1]
			var q3: Vector3 = ga[k + 1]
			var nn2: Vector3 = na2[k]
			var cen2: Vector3 = (q0 + q1 + q2 + q3) * 0.25
			_quad_uv(st, q0, q1, q2, q3, ua2[k], ub2[k], ub2[k + 1], ua2[k + 1], cen2 + nn2 * lift)

	st.set_smooth_group(-1)
	for side in range(2):
		var j2: int = 0 if side == 0 else lanes - 1
		var sgn: float = 1.0 if side == 0 else -1.0
		var ef: Array = vf[j2]
		var eb: Array = vb[j2]
		var ebn: Array = vbn[j2]
		var eu: Array = vu[j2]
		for k in range(steps):
			var e0: Vector3 = ef[k]
			var e1: Vector3 = ef[k + 1]
			var e2: Vector3 = eb[k + 1]
			var e3: Vector3 = eb[k]
			var bd: Vector3 = ebn[k]
			var ce: Vector3 = (e0 + e1 + e2 + e3) * 0.25
			_quad_uv(st, e0, e1, e2, e3, eu[k], eu[k + 1], eu[k + 1], eu[k], ce + bd * (sgn * lift))

	for endi in range(2):
		var k2: int = 0 if endi == 0 else steps
		var sgn2: float = 1.0 if endi == 0 else -1.0
		for j in range(lanes - 1):
			var ca: Array = vf[j]
			var cb: Array = vf[j + 1]
			var da: Array = vb[j]
			var db: Array = vb[j + 1]
			var ta: Array = vt[j]
			var uca: Array = vu[j]
			var ucb: Array = vu[j + 1]
			var c0: Vector3 = ca[k2]
			var c1: Vector3 = da[k2]
			var c2: Vector3 = db[k2]
			var c3: Vector3 = cb[k2]
			var td: Vector3 = ta[k2]
			var cc: Vector3 = (c0 + c1 + c2 + c3) * 0.25
			_quad_uv(st, c0, c1, c2, c3, uca[k2], uca[k2], ucb[k2], ucb[k2], cc + td * (sgn2 * lift))

	st.generate_normals()
	var mesh_res: ArrayMesh = st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh_res
	mi.material_override = mat
	mi.transform = Transform3D(Basis(), anchor)
	root.add_child(mi)
	return mi


static func _quad_uv(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2, inside: Vector3) -> void:
	var n_front: Vector3 = (c - a).cross(b - a)
	var cen: Vector3 = (a + b + c + d) * 0.25
	if n_front.dot(cen - inside) >= 0.0:
		st.set_uv(ua)
		st.add_vertex(a)
		st.set_uv(ub)
		st.add_vertex(b)
		st.set_uv(uc)
		st.add_vertex(c)
		st.set_uv(ua)
		st.add_vertex(a)
		st.set_uv(uc)
		st.add_vertex(c)
		st.set_uv(ud)
		st.add_vertex(d)
	else:
		st.set_uv(ua)
		st.add_vertex(a)
		st.set_uv(uc)
		st.add_vertex(c)
		st.set_uv(ub)
		st.add_vertex(b)
		st.set_uv(ua)
		st.add_vertex(a)
		st.set_uv(ud)
		st.add_vertex(d)
		st.set_uv(uc)
		st.add_vertex(c)


# ---------------------------------------------------------------------------
# core primitives

static func _add(root: Node3D, mesh_res: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh_res
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _ball(root: Node3D, ctr: Vector3, half: Vector3, bs: Basis, mat: StandardMaterial3D) -> MeshInstance3D:
	var sph := SphereMesh.new()
	sph.radius = 1.0
	sph.height = 2.0
	sph.radial_segments = 16
	sph.rings = 8
	var mi: MeshInstance3D = _add(root, sph, mat)
	mi.transform = Transform3D(bs * Basis.from_scale(half), ctr)
	return mi


static func _limb(root: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.01)
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = ln + r * 2.0
	cap.radial_segments = 14
	cap.rings = 4
	var mi: MeshInstance3D = _add(root, cap, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _basis_y_to(dir: Vector3) -> Basis:
	var d: Vector3 = dir.normalized()
	var dot_up: float = d.dot(Vector3.UP)
	if dot_up > 0.9999:
		return Basis()
	if dot_up < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	var axis: Vector3 = Vector3.UP.cross(d).normalized()
	var ang: float = acos(clampf(dot_up, -1.0, 1.0))
	return Basis(axis, ang)


static func _poly_at(keys: Array, t: float) -> Vector3:
	var n: int = keys.size()
	var f: float = clampf(t, 0.0, 1.0) * float(n - 1)
	var i: int = int(floor(f))
	if i >= n - 1:
		var tail: Vector3 = keys[n - 1]
		return tail
	var u: float = f - float(i)
	var pa: Vector3 = keys[i]
	var pb: Vector3 = keys[i + 1]
	return pa.lerp(pb, u)


static func _key_at(keys: Array, t: float) -> float:
	var n: int = keys.size()
	var f: float = clampf(t, 0.0, 1.0) * float(n - 1)
	var i: int = int(floor(f))
	if i >= n - 1:
		var tail: float = keys[n - 1]
		return tail
	var u: float = f - float(i)
	var va: float = keys[i]
	var vb: float = keys[i + 1]
	return lerpf(va, vb, u)


static func _union_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		if cm.mesh == null:
			continue
		var wb: AABB = cm.transform * cm.mesh.get_aabb()
		if first:
			box = wb
			first = false
		else:
			box = box.merge(wb)
	return box


# ---------------------------------------------------------------------------
# the prints, painted in code

static func _px(img: Image, x: int, y: int, c: Color) -> void:
	img.set_pixel(posmod(x, TEX), posmod(y, TEX), c)


static func _tex_type(rng: RandomNumberGenerator, ground: Color, ink: Color, ink2: Color, n_glyph: int, news: bool, size_lo: float, size_hi: float) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	for y in range(TEX):
		var fy: float = float(y)
		for x in range(TEX):
			var fx: float = float(x)
			var nz: float = 0.022 * sin(fx * 2.13 + fy * 0.61) + 0.016 * sin(fy * 3.07 - fx * 0.44) + 0.011 * sin((fx + fy) * 1.31)
			img.set_pixel(x, y, Color(clampf(ground.r + nz, 0.0, 1.0), clampf(ground.g + nz, 0.0, 1.0), clampf(ground.b + nz * 0.9, 0.0, 1.0)))
	if news:
		var nb: int = rng.randi_range(2, 3)
		for _b in range(nb):
			var bx: int = rng.randi_range(0, TEX - 40)
			var by: int = rng.randi_range(0, TEX - 40)
			var bw: int = rng.randi_range(34, 76)
			var bh: int = rng.randi_range(30, 70)
			_news_block(img, rng, bx, by, bw, bh, ink)
		var n_rule: int = rng.randi_range(1, 2)
		for _r in range(n_rule):
			var ry: int = rng.randi_range(0, TEX - 1)
			for x in range(TEX):
				_px(img, x, ry, ink)
				_px(img, x, ry + 1, ink)
	for _k in range(n_glyph):
		var gi: int = rng.randi_range(0, GLYPHS.size() - 1)
		var strokes: Array = GLYPHS[gi]
		var s: float = rng.randf_range(size_lo, size_hi)
		var cx: float = rng.randf_range(0.0, float(TEX))
		var cy: float = rng.randf_range(0.0, float(TEX))
		var ang: float = rng.randf_range(-PI, PI)
		var shade: float = rng.randf_range(0.90, 1.0)
		var use2: bool = rng.randf() < 0.26
		var base: Color = ink2 if use2 else ink
		_stamp_glyph(img, strokes, cx, cy, s, ang, Color(base.r * shade, base.g * shade, base.b * shade))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _news_block(img: Image, rng: RandomNumberGenerator, x0: int, y0: int, w: int, h: int, ink: Color) -> void:
	var line_h: int = rng.randi_range(4, 6)
	var y: int = y0
	while y < y0 + h:
		var x: int = x0 + rng.randi_range(0, 3)
		while x < x0 + w:
			var wl: int = rng.randi_range(3, 11)
			if x + wl > x0 + w:
				wl = x0 + w - x
			for yy in range(2):
				for xx in range(wl):
					_px(img, x + xx, y + yy, ink)
			x += wl + rng.randi_range(2, 3)
		y += line_h


static func _stamp_glyph(img: Image, strokes: Array, cx: float, cy: float, s: float, ang: float, ink: Color) -> void:
	var w: float = s * 0.74
	var hd: float = sqrt(w * w + s * s) * 0.5 + 2.0
	var ca: float = cos(ang)
	var sa: float = sin(ang)
	var x0: int = int(floor(cx - hd))
	var x1: int = int(ceil(cx + hd))
	var y0: int = int(floor(cy - hd))
	var y1: int = int(ceil(cy + hd))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var dx: float = float(x) + 0.5 - cx
			var dy: float = float(y) + 0.5 - cy
			var lu: float = (dx * ca + dy * sa) / w + 0.5
			var lv: float = (-dx * sa + dy * ca) / s + 0.5
			if lu < 0.0 or lu > 1.0 or lv < 0.0 or lv > 1.0:
				continue
			var hit: bool = false
			for sk in strokes:
				var rc: Array = sk
				var u0: float = rc[0]
				var v0: float = rc[1]
				var u1: float = rc[2]
				var v1: float = rc[3]
				if lu < u0 or lu > u1 or lv < v0 or lv > v1:
					continue
				if rc.size() >= 5:
					var kind: float = rc[4]
					var pu: float = (lu - u0) / maxf(u1 - u0, 0.001)
					var pv: float = (lv - v0) / maxf(v1 - v0, 0.001)
					var dref: float = pv if kind < 1.5 else 1.0 - pv
					if absf(pu - dref) < 0.20:
						hit = true
						break
					continue
				hit = true
				break
			if hit:
				_px(img, x, y, ink)


static func _tex_dots(rng: RandomNumberGenerator, cols: int, dot_r: float, ground: Color, ink: Color) -> ImageTexture:
	var img: Image = Image.create(TEXM, TEXM, false, Image.FORMAT_RGB8)
	var cell: float = float(TEXM) / float(cols)
	var jx: Array = []
	var jy: Array = []
	for _c in range(cols * cols):
		jx.append(rng.randf_range(-0.10, 0.10) * cell)
		jy.append(rng.randf_range(-0.10, 0.10) * cell)
	var rr: float = dot_r * dot_r
	for y in range(TEXM):
		var fy: float = float(y) + 0.5
		for x in range(TEXM):
			var fx: float = float(x) + 0.5
			var ci: int = int(floor(fx / cell))
			var cj: int = int(floor(fy / cell))
			var hit: bool = false
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					var gi: int = posmod(cj + oy, cols) * cols + posmod(ci + ox, cols)
					var dxx: float = fx - ((float(ci + ox) + 0.5) * cell + float(jx[gi]))
					var dyy: float = fy - ((float(cj + oy) + 0.5) * cell + float(jy[gi]))
					if dxx * dxx + dyy * dyy <= rr:
						hit = true
			var nz: float = 0.018 * sin(fx * 2.7 + fy * 1.1)
			var c: Color = ink if hit else ground
			img.set_pixel(x, y, Color(clampf(c.r + nz, 0.0, 1.0), clampf(c.g + nz, 0.0, 1.0), clampf(c.b + nz, 0.0, 1.0)))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _tex_honey(rng: RandomNumberGenerator, cols: int, rows: int, ground: Color, ink: Color) -> ImageTexture:
	var img: Image = Image.create(TEXM, TEXM, false, Image.FORMAT_RGB8)
	var w: float = float(TEXM) / float(cols)
	var h: float = float(TEXM) / float(rows)
	var line_w: float = rng.randf_range(0.13, 0.21)
	for y in range(TEXM):
		var py: float = float(y) + 0.5
		var row_c: int = int(floor(py / h))
		for x in range(TEXM):
			var px: float = float(x) + 0.5
			var best_d: float = 1.0e9
			var best_dx: float = 0.0
			var best_dy: float = 0.0
			for rr in range(row_c - 1, row_c + 2):
				var rw: int = posmod(rr, rows)
				var off: float = w * 0.5 if (rw % 2) == 1 else 0.0
				var cy: float = (float(rr) + 0.5) * h
				var col_c: int = int(floor((px - off) / w))
				for cc in range(col_c - 1, col_c + 2):
					var cx: float = (float(cc) + 0.5) * w + off
					var dx: float = px - cx
					var dy: float = py - cy
					var dd: float = dx * dx + dy * dy
					if dd < best_d:
						best_d = dd
						best_dx = dx
						best_dy = dy
			var ndy: float = best_dy * (0.866 * w / h)
			var hdv: float = maxf(absf(best_dx), maxf(absf(best_dx * 0.5 + ndy * 0.866), absf(best_dx * 0.5 - ndy * 0.866))) / (w * 0.5)
			var band: float = clampf((hdv - (1.0 - line_w)) / 0.16, 0.0, 1.0)
			var c: Color = ground.lerp(ink, band)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
