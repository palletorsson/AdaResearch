extends RefCounted

## dream_bodies / asawa_wire — one body drawn entirely in looping cord.
##
## Reference: scratchpad/refs/asawa.png (2048x536 panorama) — a wall of Asawa-like
## bodies made of continuous cord: a dusty-rose torso where the loops crowd into
## knitted skin, warm-sand figures that are pure open tangle (you look straight
## through them to the loops on the far side), navy thickets behind, slate-grey
## and sand balls of wound cord resting at their feet, one arm reaching out of
## the mass toward the next figure.
##
## Reproduced, and how:
##   1. No solid skin anywhere. The whole body is TorusMesh rings and swept
##      SurfaceTool cord tubes laid ON an invisible lathe surface, so the volume
##      exists only as line and the far side of the body shows through the near.
##   2. The lathe silhouette — a 15-key half-width profile (hip flare, waist
##      pinch, chest, shoulder slope, neck, skull, crown), squashed front-to-back
##      per height so every cross-section is an ellipse, never a machined hoop.
##   3. Knitted patches — two seeded bands where the ring spacing collapses to
##      ~7 mm and small stitch rings lie flat against the surface, set against
##      ~17 mm open spacing everywhere else: dense skin, then tangle.
##   4. Continuous loops — closed SurfaceTool tubes that climb the body, wrap it
##      one to three times and come back down, plus open tangle arcs that balloon
##      right off the surface and re-land, the way the sand figures unravel.
##   5. Two cord colours — one main, a second on roughly 10-20% of the rings,
##      banded the way a section of the reference changes yarn, not sprinkled.
##   6. Cord as material — a twisted two-ply fibre painted in code (ImageTexture,
##      integer frequencies so it tiles) on triplanar UVs, so the twist runs
##      unbroken across a whole chain of separate rings.
##   7. The gesture — contrapposto: hips pushed one way and shoulders the other
##      along an S centre-line, one standing leg and one free leg forward, one
##      arm hanging heavy and one reaching out to the side.
##   8. A ball of wound cord on the floor beside the feet, and every ring tilted
##      a few degrees of its own, so the stack reads as hand-wound.
##
## Given up: the wall of neighbouring bodies and the navy thicket behind them,
## the mannequin head with painted eyes and knitted cap, true interlocked stitch
## topology (the dense patches are crowded rings, not knitting), and the loose
## cord ends that trail out of the reference's tangles.
##
## DNA axes — two, in the family's own language:
##   winding — what the wound cord is DOING as a whole. figure = one standing
##     figure (today's statue). mirrored = a second, smaller body buds sideways
##     out of the shoulder and reaches back, tied on by two running cords.
##     skein = the figure dissolves into a swarm of small wound balls of its own
##     rings, heaped at the feet. unravelled = the skin becomes long single
##     threads that spiral the whole body and spill into a flat coil on the
##     floor. flooded = the lower half is drowned in a solid pour the torso
##     rises out of, legs gone.
##   strand — what the cord IS. fibre = twisted two-ply yarn (today). fossil =
##     the flesh gone, cord bleached to chalk and more than twice as thick, with
##     concretions grown on it. molten = glossy sagging wax, every ring drooped
##     and dripping bulbed threads, the floor ball flattened to a puddle.
##     bloom = the cord flowers — hands, crown, tangle-ends and buds along the
##     body burst into petal fans.

const TEX_SIZE: int = 128

# [main cord, second cord, stitch accent, ball of cord]
const SCHEMES: Array = [
	["#B96B84", "#26304F", "#D9BB9C", "#C98BA0"],
	["#D2A97F", "#E9A9B5", "#8C93A2", "#C1996F"],
	["#78838F", "#D6B48F", "#E3A3AF", "#5E6875"],
	["#E3A3AF", "#6E7A88", "#C89A76", "#D08FA0"],
	["#2E3959", "#CBA985", "#B96B84", "#3B4870"],
]

# half-width of the body from the bottom of the hip mass (v = 0) to the crown
# (v = 1), 15 evenly spaced keys
const PROFILE: Array = [0.150, 0.172, 0.164, 0.138, 0.122, 0.126, 0.142, 0.154, 0.158, 0.148, 0.112, 0.056, 0.062, 0.078, 0.034]
# leg half-width from ankle (0) to hip (1), 7 evenly spaced keys
const LEGKEYS: Array = [0.040, 0.056, 0.060, 0.048, 0.060, 0.076, 0.092]

const V0_Y: float = 0.44   # v = 0 sits at 0.44 * height
const V_SPAN: float = 0.56 # v = 1 sits at 1.00 * height

const FLOOD_FRAC: float = 0.58 # flooded: the pour surface, as a fraction of height


static func describe() -> String:
	return "A hollow standing figure drawn only in looping cord — a hundred-odd rings and swept loops trace hips, waist, shoulders and skull, crowding into knitted skin in two bands and unravelling into open tangle elsewhere, so you see through the body to the far side."


static func axes() -> Dictionary:
	return {
		"winding": ["figure", "mirrored", "skein", "unravelled", "flooded"],
		"strand": ["fibre", "fossil", "molten", "bloom"],
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var winding: String = String(opts.get("winding", "figure"))
	var strand: String = String(opts.get("strand", "fibre"))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- what the axes cost in rings, so the mesh budget survives every value --
	var w_spread: float = 1.0
	if winding == "mirrored":
		w_spread = 1.55
	elif winding == "skein":
		w_spread = 2.45
	elif winding == "unravelled":
		w_spread = 3.05
	elif winding == "flooded":
		w_spread = 1.12
	var s_spread: float = 1.0
	var s_thick: float = 1.0
	if strand == "fossil":
		s_spread = 1.30
		s_thick = 2.15
	elif strand == "molten":
		s_spread = 1.18
		s_thick = 1.55
	elif strand == "bloom":
		s_spread = 1.30
		s_thick = 1.05
	var spread: float = minf(3.40, w_spread * s_spread)
	var flooded: bool = winding == "flooded"

	var scheme: Array = SCHEMES[rng.randi_range(0, SCHEMES.size() - 1)]
	var col_main: Color = _c(scheme, 0)
	var col_alt: Color = _c(scheme, 1)
	var col_knot: Color = _c(scheme, 2)
	var col_ball: Color = _c(scheme, 3)

	var tex_tight: ImageTexture = _cord_texture(rng, 7, 4, 0.34)
	var tex_loose: ImageTexture = _cord_texture(rng, 4, 3, 0.26)
	var tex_main: ImageTexture = tex_tight
	var tex_second: ImageTexture = tex_loose
	if strand == "fossil":
		var tex_chalk: ImageTexture = _grain_texture(rng, 0.46)
		tex_main = tex_chalk
		tex_second = tex_chalk
		col_main = _bone(col_main)
		col_alt = _bone(col_alt)
		col_knot = _bone(col_knot).darkened(0.12)
		col_ball = _bone(col_ball)
	elif strand == "molten":
		var tex_wax: ImageTexture = _cord_texture(rng, 2, 1, 0.11)
		tex_main = tex_wax
		tex_second = tex_wax
		col_main = _wax(col_main)
		col_alt = _wax(col_alt)
		col_knot = _wax(col_knot)
		col_ball = _wax(col_ball)

	var mats_main: Array = [
		_cord2(strand, col_main, tex_main, 12.0),
		_cord2(strand, col_main.lightened(0.09), tex_main, 12.0),
		_cord2(strand, col_main.darkened(0.09), tex_main, 12.0),
	]
	var mats_alt: Array = [
		_cord2(strand, col_alt, tex_second, 10.0),
		_cord2(strand, col_alt.lightened(0.10), tex_second, 10.0),
	]
	var mat_knot: StandardMaterial3D = _cord2(strand, col_knot, tex_main, 26.0)
	var mat_ball: StandardMaterial3D = _cord2(strand, col_ball, tex_second, 8.0)

	# --- this individual ----------------------------------------------------
	var body_h: float = rng.randf_range(1.42, 1.62)
	var body_k: float = rng.randf_range(0.92, 1.08)
	var cord_r: float = rng.randf_range(0.0075, 0.0105)
	var lean_x: float = rng.randf_range(-0.050, 0.050)
	var lean_z: float = rng.randf_range(-0.045, 0.028)
	var sway_mag: float = rng.randf_range(0.020, 0.042)
	var sway_sign: float = 1.0 if rng.randf() < 0.5 else -1.0
	var sway: float = sway_mag * sway_sign
	var twist: float = deg_to_rad(rng.randf_range(-28.0, 28.0))
	var tilt_amp: float = deg_to_rad(rng.randf_range(4.0, 11.0))
	var tilt_ph: float = rng.randf_range(0.0, TAU)
	var depth_lo: float = rng.randf_range(0.66, 0.80)
	var reach: float = 1.0 if rng.randf() < 0.5 else -1.0
	var stand_leg: float = 1.0 if rng.randf() < 0.5 else -1.0
	var alt_a: float = rng.randf_range(0.06, 0.36)
	var alt_b: float = rng.randf_range(0.56, 0.92)
	var alt_w: float = rng.randf_range(0.025, 0.050)
	var knit_a: float = rng.randf_range(0.10, 0.30)
	var knit_b: float = rng.randf_range(0.48, 0.72)
	var knit_w: float = rng.randf_range(0.050, 0.085)

	var cord: float = cord_r * s_thick
	var flood_y: float = FLOOD_FRAC * body_h
	var flood_v: float = clampf((FLOOD_FRAC - V0_Y) / V_SPAN, 0.0, 1.0)

	# molten lets every ring sag and spread on the way down
	var sag_x: float = 1.0
	var sag_z: float = 1.0
	var sag_y: float = 0.0
	if strand == "molten":
		sag_x = 1.12
		sag_z = 0.86
		sag_y = 0.055

	var bp := {
		"h": body_h,
		"k": body_k,
		"lx": lean_x,
		"lz": lean_z,
		"sw": sway,
		"dlo": depth_lo,
	}

	# points on the skin, harvested as the body is drawn: drips, concretions and
	# buds all hang off these, so no mode has to re-derive the surface
	var surf_sites: Array = []
	# flower sites, collected always, grown only when the strand blooms
	var bloom_p: Array = []
	var bloom_d: Array = []
	var bloom_s: Array = []

	# --- torso: the lathe drawn as a stack of rings -------------------------
	var v: float = 0.0
	var guard: int = 0
	while v <= 1.0001 and guard < 92:
		guard += 1
		var dense: bool = _in_band(v, knit_a, knit_w) or _in_band(v, knit_b, knit_w)
		var ctr: Vector3 = _axis_at(bp, v)
		var r_maj: float = _profile_at(v) * body_k
		var dk: float = _depth_at(v, depth_lo)
		var yaw: float = twist * v + rng.randf_range(-0.06, 0.06)
		var tx: float = tilt_amp * sin(v * 7.0 + tilt_ph) + rng.randf_range(-0.035, 0.035)
		var tz: float = tilt_amp * cos(v * 5.3 + tilt_ph * 1.7) + rng.randf_range(-0.035, 0.035)
		ctr.y -= sag_y * r_maj
		var frame: Basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, tx) * Basis(Vector3.FORWARD, tz) * Basis.from_scale(Vector3(sag_x, 1.0, dk * sag_z))
		var use_alt: bool = _in_band(v, alt_a, alt_w) or _in_band(v, alt_b, alt_w) or rng.randf() < 0.05
		var mat: StandardMaterial3D = null
		if use_alt:
			mat = mats_alt[rng.randi_range(0, mats_alt.size() - 1)]
		else:
			mat = mats_main[rng.randi_range(0, mats_main.size() - 1)]
		var thick: float = cord * (0.82 if dense else 1.0)
		var drowned: bool = flooded and ctr.y < flood_y
		if not drowned:
			_ring(root, ctr, frame, r_maj, thick, mat)
			if guard % 4 == 2:
				var th_s: float = float(guard) * 1.71
				surf_sites.append(Vector3(ctr.x + cos(th_s) * r_maj, ctr.y, ctr.z + sin(th_s) * r_maj * dk))
		var dy: float = 0.0165
		if dense:
			dy = 0.0072
		elif v > 0.80:
			dy = 0.0110
		v += dy * spread / (body_h * V_SPAN)

	# --- skull: three meridian rings close the head cage ---------------------
	var skull_v: float = 0.925
	var skull_c: Vector3 = _axis_at(bp, skull_v)
	var skull_r: float = _profile_at(skull_v) * body_k
	for m_i in range(3):
		var phi: float = PI * float(m_i) / 3.0 + twist
		var ax: Vector3 = Vector3(cos(phi), 0.0, sin(phi))
		_ring(root, skull_c, _basis_y_to(ax), skull_r * 0.96, cord * 0.9, mats_main[m_i % mats_main.size()])
	bloom_p.append(skull_c + Vector3(0.0, skull_r * 0.9, 0.0))
	bloom_d.append(Vector3(0.0, 1.0, 0.0))
	bloom_s.append(0.082)

	# --- legs: two ring columns, one standing, one free and forward ----------
	var hip_off: Vector3 = _axis_at(bp, 0.10)
	for side_i in range(2):
		if flooded:
			continue
		var sd: float = -1.0 if side_i == 0 else 1.0
		var is_stand: bool = (sd == stand_leg)
		var foot_fwd: float = -0.030 if is_stand else 0.060
		var spread_leg: float = 0.046 if is_stand else 0.082
		var knee_out: float = 0.012 if is_stand else 0.030
		var y_ankle: float = 0.030
		var y_hip: float = 0.50 * body_h
		var steps: int = clampi(int(round((y_hip - y_ankle) / (0.030 * spread))), 8, 28)
		var prev: Vector3 = Vector3.ZERO
		for k in range(steps + 1):
			var w: float = float(k) / float(steps)
			var lx: float = sd * lerpf(spread_leg, 0.085, w) * body_k + hip_off.x * (w * w) + sd * knee_out * sin(PI * w)
			var lz: float = hip_off.z * (w * w) - foot_fwd * (1.0 - w) - 0.030 * sin(PI * w)
			var ly: float = lerpf(y_ankle, y_hip, w)
			var q := Vector3(lx, ly, lz)
			if k == 0:
				prev = q
				continue
			var tang: Vector3 = (q - prev).normalized()
			var r_leg: float = _leg_at(w) * body_k
			var jx: float = rng.randf_range(-0.06, 0.06)
			var jz: float = rng.randf_range(-0.06, 0.06)
			var lf: Basis = _basis_y_to(tang) * Basis(Vector3.RIGHT, jx) * Basis(Vector3.FORWARD, jz) * Basis.from_scale(Vector3(sag_x, 1.0, 0.86 * sag_z))
			var lm: StandardMaterial3D = null
			if rng.randf() < 0.10:
				lm = mats_alt[rng.randi_range(0, mats_alt.size() - 1)]
			else:
				lm = mats_main[rng.randi_range(0, mats_main.size() - 1)]
			_ring(root, q, lf, r_leg, cord, lm)
			if k % 5 == 3:
				surf_sites.append(q + Vector3(sd * r_leg, 0.0, 0.0))
			prev = q
		# foot: three near-flat rings running forward from the ankle
		var ankle := Vector3(sd * spread_leg * body_k, y_ankle, -foot_fwd)
		for f_i in range(3):
			var ff: float = float(f_i)
			var fr: float = 0.042 - ff * 0.007
			var fy: float = 0.023 - ff * 0.002
			var fz: float = ankle.z - 0.030 - ff * 0.028
			var fax := Vector3(sd * 0.10, 1.0, -0.26).normalized()
			_ring(root, Vector3(ankle.x + sd * 0.004 * ff, fy, fz), _basis_y_to(fax), fr * body_k, cord * 0.9, mats_main[f_i % mats_main.size()])

	# --- arms: one hanging, one reaching out ---------------------------------
	var v_sh: float = 0.640
	var sh_c: Vector3 = _axis_at(bp, v_sh)
	var sh_r: float = _profile_at(v_sh) * body_k
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var reaching: bool = (sd == reach)
		var sp: Vector3 = sh_c + Vector3(sd * sh_r * 1.06, 0.012, 0.0)
		var el: Vector3 = Vector3.ZERO
		var wr: Vector3 = Vector3.ZERO
		if reaching:
			el = sp + Vector3(sd * 0.165, -0.095, -0.060 + rng.randf_range(-0.03, 0.03))
			wr = el + Vector3(sd * 0.170, 0.050 + rng.randf_range(-0.03, 0.05), -0.110)
		else:
			el = sp + Vector3(sd * 0.058, -0.235, 0.028)
			wr = el + Vector3(-sd * 0.010, -0.215, 0.048 + rng.randf_range(-0.03, 0.03))
		var a_steps: int = clampi(int(round(13.0 / spread)), 5, 13)
		for k in range(a_steps + 1):
			var s: float = 0.05 + 0.95 * float(k) / float(a_steps)
			var q: Vector3 = _bez(sp, el, wr, s)
			var d: Vector3 = 2.0 * (1.0 - s) * (el - sp) + 2.0 * s * (wr - el)
			if d.length() < 0.0001:
				d = Vector3.DOWN
			var r_arm: float = lerpf(0.056, 0.030, pow(s, 0.85)) * body_k
			var jx: float = rng.randf_range(-0.10, 0.10)
			var jz: float = rng.randf_range(-0.10, 0.10)
			var af: Basis = _basis_y_to(d.normalized()) * Basis(Vector3.RIGHT, jx) * Basis(Vector3.FORWARD, jz) * Basis.from_scale(Vector3(sag_x, 1.0, 0.90 * sag_z))
			var am: StandardMaterial3D = null
			if rng.randf() < 0.16:
				am = mats_alt[rng.randi_range(0, mats_alt.size() - 1)]
			else:
				am = mats_main[rng.randi_range(0, mats_main.size() - 1)]
			_ring(root, q, af, r_arm, cord * 0.95, am)
			if k % 4 == 1:
				surf_sites.append(q + Vector3(0.0, -r_arm * 0.9, 0.0))
		# a knot of two crossed rings for the hand
		var hd: Vector3 = (wr - el).normalized()
		var hx: Vector3 = hd.cross(Vector3.UP)
		if hx.length() < 0.0001:
			hx = hd.cross(Vector3.RIGHT)
		_ring(root, wr + hd * 0.020, _basis_y_to(hx.normalized()), 0.036 * body_k, cord * 0.9, mat_knot)
		_ring(root, wr + hd * 0.036, _basis_y_to(hd), 0.030 * body_k, cord * 0.9, mat_knot)
		bloom_p.append(wr + hd * 0.062)
		bloom_d.append(hd)
		bloom_s.append(0.078)

	# --- knitted patches: small stitch rings lying on the skin ---------------
	if winding != "unravelled":
		for band_i in range(2):
			var bc: float = knit_a if band_i == 0 else knit_b
			var th0: float = -PI * 0.5 + rng.randf_range(-0.7, 0.7)
			for r_i in range(2):
				for c_i in range(5):
					var vv: float = bc + (float(r_i) - 0.5) * 0.034
					var th: float = th0 + (float(c_i) - 2.0) * 0.40
					var pos: Vector3 = _body_point(bp, vv, th, 1.0)
					if flooded and pos.y < flood_y:
						continue
					var dk2: float = _depth_at(vv, depth_lo)
					var nn: Vector3 = Vector3(cos(th), 0.14, sin(th) / maxf(dk2, 0.35)).normalized()
					_ring(root, pos + nn * (cord * 0.5), _basis_y_to(nn), cord * 2.5, cord * 0.7, mat_knot)

	# --- continuous loops climbing and wrapping the body ---------------------
	var n_loops: int = rng.randi_range(3, 5)
	for l_i in range(n_loops):
		var v0: float = rng.randf_range(0.0, 0.42)
		var v1: float = minf(0.95, v0 + rng.randf_range(0.26, 0.55))
		if flooded:
			v0 = maxf(v0, flood_v + 0.03)
			v1 = maxf(v1, v0 + 0.22)
		var turns: int = rng.randi_range(1, 3)
		var phase: float = rng.randf_range(0.0, TAU)
		var bulge: float = rng.randf_range(0.03, 0.15)
		var wob: float = rng.randf_range(0.0, 0.05)
		var path := PackedVector3Array()
		for k in range(44):
			var s: float = float(k) / 44.0
			var vv: float = v0 + (v1 - v0) * (0.5 - 0.5 * cos(TAU * s)) + wob * sin(TAU * 3.0 * s)
			var th: float = TAU * float(turns) * s + phase
			var out_k: float = 1.03 + bulge * sin(TAU * 2.0 * s + phase)
			path.append(_body_point(bp, clampf(vv, 0.0, 1.0), th, out_k))
		var lm: StandardMaterial3D = null
		if rng.randf() < 0.42:
			lm = mats_alt[rng.randi_range(0, mats_alt.size() - 1)]
		else:
			lm = mats_main[rng.randi_range(0, mats_main.size() - 1)]
		_tube(root, path, cord * 0.92, lm, true)

	# --- open tangle arcs that balloon off the surface and re-land -----------
	var n_tangle: int = rng.randi_range(2, 3)
	for t_i in range(n_tangle):
		var va: float = rng.randf_range(0.06, 0.72)
		var vb: float = clampf(va + rng.randf_range(-0.24, 0.26), 0.02, 0.94)
		if flooded:
			va = maxf(va, flood_v + 0.04)
			vb = maxf(vb, flood_v + 0.04)
		var tha: float = rng.randf_range(0.0, TAU)
		var thb: float = tha + rng.randf_range(1.1, 3.4)
		var bulge2: float = rng.randf_range(0.40, 1.00)
		var wig: float = rng.randf_range(0.10, 0.55)
		var path2 := PackedVector3Array()
		for k in range(33):
			var s: float = float(k) / 32.0
			var vv: float = lerpf(va, vb, s)
			var th: float = lerpf(tha, thb, s) + wig * sin(TAU * 2.0 * s)
			var out_k: float = 1.0 + bulge2 * sin(PI * s) * (1.0 + 0.35 * sin(TAU * 3.0 * s))
			var q: Vector3 = _body_point(bp, vv, th, out_k)
			q.y += 0.055 * sin(PI * s) * sin(TAU * 1.5 * s)
			path2.append(q)
		var tm: StandardMaterial3D = null
		if rng.randf() < 0.5:
			tm = mats_alt[rng.randi_range(0, mats_alt.size() - 1)]
		else:
			tm = mats_main[rng.randi_range(0, mats_main.size() - 1)]
		_tube(root, path2, cord * 0.85, tm, false)
		var apex: Vector3 = path2[16]
		var apex_ax: Vector3 = _axis_at(bp, lerpf(va, vb, 0.5))
		var apex_d: Vector3 = apex - apex_ax
		apex_d.y = maxf(apex_d.y, 0.10)
		bloom_p.append(apex)
		bloom_d.append(apex_d.normalized())
		bloom_s.append(0.055)

	# --- a ball of wound cord on the floor beside the feet -------------------
	var ball_r: float = rng.randf_range(0.085, 0.115)
	var ball_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var ball_c := Vector3(ball_side * rng.randf_range(0.22, 0.30), ball_r + cord * 1.4 + 0.003, rng.randf_range(-0.06, 0.16))
	if flooded:
		ball_c = Vector3(ball_side * 0.13, flood_y + ball_r * 0.50, 0.05)
	if strand == "molten":
		ball_c.y = ball_r * 0.42
	var n_ball: int = rng.randi_range(7, 9)
	for b_i in range(n_ball):
		var fb: float = float(b_i) / float(n_ball)
		var ax2 := Vector3(sin(fb * 9.4 + 0.7), cos(fb * 6.1), sin(fb * 4.3 + 2.1)).normalized()
		var rb: float = ball_r * (0.78 + 0.22 * cos(fb * 5.0))
		var bb: Basis = _basis_y_to(ax2)
		if strand == "molten":
			bb = bb * Basis.from_scale(Vector3(1.55, 0.30, 1.55))
		_ring(root, ball_c, bb, rb, cord * 1.05, mat_ball)

	# --- winding: mirrored — a second body budding out of the shoulder -------
	if winding == "mirrored":
		var bud_side: float = -reach
		var bud_k: float = rng.randf_range(0.50, 0.66)
		var bud_v: float = rng.randf_range(0.64, 0.78)
		var bud_lean: float = deg_to_rad(rng.randf_range(44.0, 64.0)) * bud_side
		var bud_yaw: float = rng.randf_range(-0.8, 0.8)
		var bud_rot: Basis = Basis(Vector3.FORWARD, bud_lean) * Basis(Vector3.UP, bud_yaw)
		var bud_org: Vector3 = _axis_at(bp, bud_v) + Vector3(bud_side * _profile_at(bud_v) * body_k * 1.05, 0.0, 0.0)
		var b_steps: int = 20
		for k in range(b_steps + 1):
			var vv: float = float(k) / float(b_steps)
			var lp: Vector3 = _axis_at(bp, vv)
			lp.y -= V0_Y * body_h
			var wp: Vector3 = bud_org + bud_rot * (lp * bud_k)
			var rr: float = _profile_at(vv) * body_k * bud_k
			var dk3: float = _depth_at(vv, depth_lo)
			var bf: Basis = bud_rot * Basis(Vector3.UP, twist * vv) * Basis(Vector3.RIGHT, rng.randf_range(-0.06, 0.06)) * Basis.from_scale(Vector3(sag_x, 1.0, dk3 * sag_z))
			var bm: StandardMaterial3D = null
			if rng.randf() < 0.24:
				bm = mats_alt[rng.randi_range(0, mats_alt.size() - 1)]
			else:
				bm = mats_main[rng.randi_range(0, mats_main.size() - 1)]
			_ring(root, wp, bf, rr, cord * 0.92, bm)
			if k % 4 == 2:
				surf_sites.append(wp + bud_rot * Vector3(rr, 0.0, 0.0))
		var blp: Vector3 = _axis_at(bp, 0.93)
		blp.y -= V0_Y * body_h
		var bskull: Vector3 = bud_org + bud_rot * (blp * bud_k)
		var bsr: float = _profile_at(0.93) * body_k * bud_k
		for m_i in range(3):
			var phi2: float = PI * float(m_i) / 3.0
			var ax3: Vector3 = bud_rot * Vector3(cos(phi2), 0.0, sin(phi2))
			_ring(root, bskull, _basis_y_to(ax3), bsr * 0.96, cord * 0.85, mats_main[m_i % mats_main.size()])
		bloom_p.append(bskull + bud_rot * Vector3(0.0, bsr * 1.1, 0.0))
		bloom_d.append((bud_rot * Vector3(0.0, 1.0, 0.0)).normalized())
		bloom_s.append(0.060)
		# the bud's small arm, reaching back at the body it grew from
		var bsh: Vector3 = bud_org + bud_rot * ((_axis_at(bp, 0.64) - Vector3(0.0, V0_Y * body_h, 0.0)) * bud_k)
		var b_wr: Vector3 = _axis_at(bp, 0.52) + Vector3(bud_side * 0.03, 0.0, -0.11)
		var b_el: Vector3 = (bsh + b_wr) * 0.5 + Vector3(0.0, 0.10, -0.15)
		for k in range(7):
			var s: float = 0.08 + 0.92 * float(k) / 6.0
			var q: Vector3 = _bez(bsh, b_el, b_wr, s)
			var d: Vector3 = 2.0 * (1.0 - s) * (b_el - bsh) + 2.0 * s * (b_wr - b_el)
			if d.length() < 0.0001:
				d = Vector3.DOWN
			var ra: float = lerpf(0.040, 0.022, s) * body_k
			_ring(root, q, _basis_y_to(d.normalized()), ra, cord * 0.9, mats_main[k % mats_main.size()])
		bloom_p.append(b_wr)
		bloom_d.append((b_wr - b_el).normalized())
		bloom_s.append(0.050)
		# two cords running out of the parent's skin and into the bud
		for c_i in range(2):
			var pth := PackedVector3Array()
			var th_c: float = rng.randf_range(0.0, TAU)
			for k in range(18):
				var s: float = float(k) / 17.0
				var sm3: float = s * s * (3.0 - 2.0 * s)
				var pa: Vector3 = _body_point(bp, lerpf(0.44, bud_v, s), th_c + 1.6 * s, 1.03 + 0.10 * sin(PI * s))
				var pb: Vector3 = bud_org + bud_rot * ((_axis_at(bp, lerpf(0.06, 0.58, s)) - Vector3(0.0, V0_Y * body_h, 0.0)) * bud_k)
				pth.append(pa.lerp(pb, sm3))
			_tube(root, pth, cord * 0.80, mats_alt[c_i % mats_alt.size()], false)

	# --- winding: skein — the body scattered into balls of its own cord ------
	if winding == "skein":
		var n_sw: int = rng.randi_range(44, 58)
		for i in range(n_sw):
			var vv: float = rng.randf_range(0.0, 1.0)
			var th: float = rng.randf_range(0.0, TAU)
			var okk: float = rng.randf_range(0.30, 1.30)
			var p: Vector3 = _body_point(bp, vv, th, okk)
			p.y += rng.randf_range(-0.03, 0.03)
			var rr: float = rng.randf_range(0.016, 0.050) * body_k
			var sm2: StandardMaterial3D = null
			if rng.randf() < 0.34:
				sm2 = mats_alt[rng.randi_range(0, mats_alt.size() - 1)]
			else:
				sm2 = mats_main[rng.randi_range(0, mats_main.size() - 1)]
			_wound_ball(root, p, rr, cord * 0.75, sm2, rng)
			if i % 6 == 4:
				surf_sites.append(p + Vector3(0.0, rr, 0.0))
		var n_low: int = rng.randi_range(12, 18)
		for i in range(n_low):
			var yy: float = rng.randf_range(0.02, 0.46) * body_h
			var t2: float = clampf(yy / (0.46 * body_h), 0.0, 1.0)
			var rad: float = lerpf(0.30, 0.09, t2) * rng.randf_range(0.25, 1.0)
			var aa: float = rng.randf_range(0.0, TAU)
			var rr2: float = rng.randf_range(0.020, 0.055) * body_k
			var p2 := Vector3(cos(aa) * rad, maxf(yy, rr2 * 0.95), sin(aa) * rad)
			var lm2: StandardMaterial3D = null
			if rng.randf() < 0.5:
				lm2 = mats_alt[rng.randi_range(0, mats_alt.size() - 1)]
			else:
				lm2 = mat_ball
			_wound_ball(root, p2, rr2, cord * 0.80, lm2, rng)

	# --- winding: unravelled — the skin become thread, spilling on the floor -
	if winding == "unravelled":
		var n_th: int = rng.randi_range(6, 8)
		for i in range(n_th):
			var turns2: float = rng.randf_range(2.5, 5.2)
			var ph2: float = rng.randf_range(0.0, TAU)
			var vtop: float = rng.randf_range(0.70, 0.99)
			var pth := PackedVector3Array()
			var nw: int = 54
			for k in range(nw):
				var s: float = float(k) / float(nw - 1)
				var vv: float = lerpf(vtop, 0.02, s)
				var th: float = ph2 + TAU * turns2 * s
				var okk: float = 1.04 + 0.11 * sin(TAU * 2.0 * s + ph2)
				pth.append(_body_point(bp, clampf(vv, 0.0, 1.0), th, okk))
			var last: Vector3 = pth[pth.size() - 1]
			var cx: float = rng.randf_range(-0.10, 0.10)
			var cz: float = rng.randf_range(-0.05, 0.18)
			var r0: float = rng.randf_range(0.10, 0.16)
			var r1: float = rng.randf_range(0.22, 0.32)
			var ph3: float = rng.randf_range(0.0, TAU)
			var nf: int = 30
			for k in range(nf):
				var s: float = float(k) / float(nf - 1)
				var rr3: float = lerpf(r0, r1, s)
				var aa: float = ph3 + TAU * 1.7 * s
				var yy: float = lerpf(last.y, cord * 1.4, pow(s, 0.55))
				pth.append(Vector3(cx + cos(aa) * rr3, yy, cz + sin(aa) * rr3))
			var um: StandardMaterial3D = null
			if rng.randf() < 0.42:
				um = mats_alt[rng.randi_range(0, mats_alt.size() - 1)]
			else:
				um = mats_main[rng.randi_range(0, mats_main.size() - 1)]
			_tube(root, pth, cord * 0.90, um, false)
			surf_sites.append(pth[18])

	# --- winding: flooded — a solid pour drowns the lower half ---------------
	if flooded:
		var ax_c: Vector3 = _axis_at(bp, flood_v)
		var r_top: float = maxf(_profile_at(flood_v) * body_k * 1.80, 0.20)
		var r_base: float = r_top * rng.randf_range(1.45, 1.80)
		var mat_pour: StandardMaterial3D = _cord2(strand, col_ball.darkened(0.16), tex_second, 3.0)
		mat_pour.roughness = minf(mat_pour.roughness, 0.46)
		mat_pour.uv1_scale = Vector3(2.0, 2.0, 2.0)
		_pour(root, ax_c.x, ax_c.z, flood_y, r_top, r_base, mat_pour, rng)
		for i in range(3):
			var rip: float = r_top * (1.02 + 0.13 * float(i))
			_ring(root, Vector3(ax_c.x, flood_y - 0.004 - 0.004 * float(i), ax_c.z), Basis(), rip, cord * 0.85, mats_alt[i % mats_alt.size()])

	# --- strand: fossil — concretions grown on the bleached cage -------------
	if strand == "fossil" and surf_sites.size() > 0:
		var n_nod: int = rng.randi_range(14, 20)
		for i in range(n_nod):
			var si: int = rng.randi_range(0, surf_sites.size() - 1)
			var p0: Vector3 = surf_sites[si]
			var rr: float = rng.randf_range(0.016, 0.042) * body_k
			var sph := SphereMesh.new()
			sph.radius = rr
			sph.height = rr * rng.randf_range(1.3, 2.6)
			sph.radial_segments = 8
			sph.rings = 5
			var nm: StandardMaterial3D = mat_knot
			if rng.randf() < 0.4:
				nm = mats_main[rng.randi_range(0, mats_main.size() - 1)]
			var mi: MeshInstance3D = _add(root, sph, nm)
			mi.transform = Transform3D(Basis(Vector3.UP, rng.randf_range(0.0, TAU)), p0)

	# --- strand: molten — the cord weeps bulbed threads ----------------------
	if strand == "molten" and surf_sites.size() > 0:
		for b in range(5):
			var paths: Array = []
			for d_i in range(9):
				var si: int = rng.randi_range(0, surf_sites.size() - 1)
				var p0: Vector3 = surf_sites[si]
				var len_d: float = rng.randf_range(0.05, 0.26)
				var swing: float = rng.randf_range(-0.040, 0.040)
				var pth := PackedVector3Array()
				for k in range(7):
					var s: float = float(k) / 6.0
					var yy: float = maxf(p0.y - len_d * s, 0.008)
					pth.append(Vector3(p0.x + swing * s * s, yy, p0.z + swing * 0.6 * s * s))
				paths.append(pth)
			var stb := SurfaceTool.new()
			stb.begin(Mesh.PRIMITIVE_TRIANGLES)
			for q in paths:
				var qq: PackedVector3Array = q
				_tube_into(stb, qq, cord * 0.52, false)
				_sphere_into(stb, qq[qq.size() - 1], cord * 1.45, 4)
			stb.generate_normals()
			var dmesh: ArrayMesh = stb.commit()
			if dmesh != null and dmesh.get_surface_count() > 0:
				var dm: StandardMaterial3D = mats_main[b % mats_main.size()]
				if b % 4 == 3:
					dm = mats_alt[b % mats_alt.size()]
				var dmi: MeshInstance3D = _add(root, dmesh, dm)
				dmi.transform = Transform3D(Basis(), Vector3.ZERO)

	# --- strand: bloom — the cord flowers ------------------------------------
	if strand == "bloom":
		if surf_sites.size() > 0:
			var n_bud: int = rng.randi_range(6, 9)
			for i in range(n_bud):
				var si: int = rng.randi_range(0, surf_sites.size() - 1)
				var p0: Vector3 = surf_sites[si]
				var d0 := Vector3(p0.x, 0.0, p0.z)
				if d0.length() < 0.02:
					d0 = Vector3(1.0, 0.0, 0.0)
				d0 = d0.normalized()
				d0.y = 0.30
				bloom_p.append(p0)
				bloom_d.append(d0.normalized())
				bloom_s.append(rng.randf_range(0.028, 0.044))
		var mat_pet: StandardMaterial3D = _cord2(strand, col_knot.lightened(0.26), tex_second, 4.5)
		mat_pet.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat_pet.roughness = 0.60
		var mat_core: StandardMaterial3D = _cord2(strand, col_alt.lightened(0.30), tex_main, 22.0)
		for i in range(bloom_p.size()):
			var pp: Vector3 = bloom_p[i]
			var dd: Vector3 = bloom_d[i]
			var ss: float = float(bloom_s[i]) * body_k
			_flower(root, pp, dd, ss, mat_pet, mat_core, rng)

	# --- settle: measure, fit the box, sit it on the floor, centre it --------
	var box: AABB = _union_aabb(root)
	var wide: float = maxf(box.size.x, box.size.z)
	var kw: float = 1.20 / maxf(wide, 0.001)
	var kh: float = 1.68 / maxf(box.size.y, 0.001)
	var kfit: float = minf(1.0, minf(kw, kh))
	if kfit < 1.0:
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cm: MeshInstance3D = ch
			var tf: Transform3D = cm.transform
			cm.transform = Transform3D(tf.basis.scaled(Vector3(kfit, kfit, kfit)), tf.origin * kfit)
		box = _union_aabb(root)
	var ctr2: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-ctr2.x, -box.position.y, -ctr2.z)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + shift)


# ---------------------------------------------------------------------------
# body surface

static func _profile_at(v: float) -> float:
	var s: float = clampf(v, 0.0, 1.0)
	var f: float = s * 14.0
	var i: int = int(floor(f))
	if i >= 14:
		return float(PROFILE[14])
	var u: float = f - float(i)
	var sm: float = u * u * (3.0 - 2.0 * u)
	var a: float = float(PROFILE[i])
	var b: float = float(PROFILE[i + 1])
	return lerpf(a, b, sm)


static func _leg_at(w: float) -> float:
	var s: float = clampf(w, 0.0, 1.0)
	var f: float = s * 6.0
	var i: int = int(floor(f))
	if i >= 6:
		return float(LEGKEYS[6])
	var u: float = f - float(i)
	var sm: float = u * u * (3.0 - 2.0 * u)
	var a: float = float(LEGKEYS[i])
	var b: float = float(LEGKEYS[i + 1])
	return lerpf(a, b, sm)


static func _depth_at(v: float, dlo: float) -> float:
	var t: float = clampf((v - 0.74) / 0.26, 0.0, 1.0)
	return lerpf(dlo, 0.94, t)


static func _axis_at(bp: Dictionary, v: float) -> Vector3:
	var s: float = clampf(v, 0.0, 1.2)
	var body_h: float = float(bp["h"])
	var y: float = (V0_Y + V_SPAN * s) * body_h
	var x: float = float(bp["lx"]) * s * s + float(bp["sw"]) * sin(TAU * 0.75 * s)
	var z: float = float(bp["lz"]) * s * s - 0.018 * sin(PI * 1.6 * s)
	return Vector3(x, y, z)


static func _body_point(bp: Dictionary, v: float, th: float, out_k: float) -> Vector3:
	var ctr: Vector3 = _axis_at(bp, v)
	var r_maj: float = _profile_at(v) * float(bp["k"]) * out_k
	var dk: float = _depth_at(v, float(bp["dlo"]))
	return Vector3(ctr.x + cos(th) * r_maj, ctr.y, ctr.z + sin(th) * r_maj * dk)


static func _in_band(v: float, c: float, w: float) -> bool:
	return absf(v - c) < w


static func _bez(a: Vector3, b: Vector3, c: Vector3, s: float) -> Vector3:
	var iv: float = 1.0 - s
	return a * (iv * iv) + b * (2.0 * iv * s) + c * (s * s)


static func _pour_r(t: float, r_base: float, r_top: float) -> float:
	var s: float = clampf(t, 0.0, 1.0)
	var sm: float = s * s * (3.0 - 2.0 * s)
	var base: float = lerpf(r_base, r_top, sm)
	return base * (1.0 + 0.09 * sin(PI * s))


static func _sph(phi: float, th: float) -> Vector3:
	return Vector3(sin(phi) * cos(th), cos(phi), sin(phi) * sin(th))


# ---------------------------------------------------------------------------
# primitives

static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _ring(root: Node3D, ctr: Vector3, bs: Basis, r_maj: float, cord: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var rr: float = maxf(r_maj, cord * 1.35)
	var tor := TorusMesh.new()
	tor.inner_radius = maxf(rr - cord, 0.0015)
	tor.outer_radius = rr + cord
	var seg: int = clampi(int(round(rr * 200.0)), 14, 40)
	tor.rings = seg
	tor.ring_segments = 6
	var mi: MeshInstance3D = _add(root, tor, mat)
	mi.transform = Transform3D(bs, ctr)
	return mi


static func _tube_into(st: SurfaceTool, pts_in: PackedVector3Array, r: float, closed: bool) -> void:
	var pts: PackedVector3Array = pts_in.duplicate()
	if closed and pts.size() > 2:
		pts.append(pts_in[0])
	var n: int = pts.size()
	if n < 3:
		return
	var sides: int = 6
	var tangs: Array = []
	for i in range(n):
		var a: Vector3 = pts[maxi(i - 1, 0)]
		var b: Vector3 = pts[mini(i + 1, n - 1)]
		var d: Vector3 = b - a
		if d.length() < 0.000001:
			d = Vector3.UP
		tangs.append(d.normalized())
	var t0: Vector3 = tangs[0]
	var ref := Vector3.UP
	if absf(t0.dot(ref)) > 0.9:
		ref = Vector3.RIGHT
	var nrm: Vector3 = (ref - t0 * t0.dot(ref)).normalized()
	var fns: Array = []
	var fbs: Array = []
	for i in range(n):
		var t: Vector3 = tangs[i]
		var pn: Vector3 = nrm - t * t.dot(nrm)
		if pn.length() < 0.0001:
			pn = t.cross(Vector3.UP)
			if pn.length() < 0.0001:
				pn = t.cross(Vector3.RIGHT)
		nrm = pn.normalized()
		fns.append(nrm)
		fbs.append(t.cross(nrm).normalized())
	for i in range(n - 1):
		var c0: Vector3 = pts[i]
		var c1: Vector3 = pts[i + 1]
		var mid: Vector3 = (c0 + c1) * 0.5
		var n0: Vector3 = fns[i]
		var b0: Vector3 = fbs[i]
		var n1: Vector3 = fns[i + 1]
		var b1: Vector3 = fbs[i + 1]
		for j in range(sides):
			var a0: float = TAU * float(j) / float(sides)
			var a1: float = TAU * float(j + 1) / float(sides)
			var p00: Vector3 = c0 + (n0 * cos(a0) + b0 * sin(a0)) * r
			var p01: Vector3 = c0 + (n0 * cos(a1) + b0 * sin(a1)) * r
			var p10: Vector3 = c1 + (n1 * cos(a0) + b1 * sin(a0)) * r
			var p11: Vector3 = c1 + (n1 * cos(a1) + b1 * sin(a1)) * r
			_quad_out(st, p00, p10, p11, p01, mid)


static func _tube(root: Node3D, pts_in: PackedVector3Array, r: float, mat: StandardMaterial3D, closed: bool) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_tube_into(st, pts_in, r, closed)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var mi: MeshInstance3D = _add(root, mesh, mat)
	mi.transform = Transform3D(Basis(), Vector3.ZERO)


static func _sphere_into(st: SurfaceTool, ctr: Vector3, r: float, seg: int) -> void:
	var rows: int = maxi(seg, 3)
	var cols: int = maxi(seg * 2, 6)
	for i in range(rows):
		var p0: float = PI * float(i) / float(rows)
		var p1: float = PI * float(i + 1) / float(rows)
		for j in range(cols):
			var a0: float = TAU * float(j) / float(cols)
			var a1: float = TAU * float(j + 1) / float(cols)
			var v00: Vector3 = ctr + _sph(p0, a0) * r
			var v01: Vector3 = ctr + _sph(p0, a1) * r
			var v10: Vector3 = ctr + _sph(p1, a0) * r
			var v11: Vector3 = ctr + _sph(p1, a1) * r
			_quad_out(st, v00, v10, v11, v01, ctr)


static func _wound_ball(root: Node3D, ctr: Vector3, r: float, cord: float, mat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for c_i in range(3):
		var ax := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
		if ax.length() < 0.02:
			ax = Vector3.UP
		var bs: Basis = _basis_y_to(ax.normalized())
		var rr: float = r * (0.70 + 0.15 * float(c_i))
		var path := PackedVector3Array()
		for k in range(14):
			var a: float = TAU * float(k) / 14.0
			path.append(ctr + bs * Vector3(cos(a) * rr, 0.0, sin(a) * rr))
		_tube_into(st, path, cord, true)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var mi: MeshInstance3D = _add(root, mesh, mat)
	mi.transform = Transform3D(Basis(), Vector3.ZERO)


static func _flower(root: Node3D, pos: Vector3, dir_in: Vector3, size: float, mat_pet: StandardMaterial3D, mat_core: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	var up: Vector3 = dir_in
	if up.length() < 0.0001:
		up = Vector3.UP
	up = up.normalized()
	var side: Vector3 = up.cross(Vector3.UP)
	if side.length() < 0.001:
		side = up.cross(Vector3.RIGHT)
	side = side.normalized()
	var side2: Vector3 = up.cross(side).normalized()
	var np: int = rng.randi_range(6, 9)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(np):
		var a: float = TAU * float(i) / float(np) + rng.randf_range(-0.12, 0.12)
		var out_d: Vector3 = (side * cos(a) + side2 * sin(a)).normalized()
		var curl: float = rng.randf_range(0.75, 1.40)
		var tip: Vector3 = pos + out_d * (size * 1.35 * curl) + up * (size * rng.randf_range(-0.25, 0.55))
		var mid: Vector3 = pos + out_d * (size * 0.50) + up * (size * 1.05)
		var perp: Vector3 = out_d.cross(up).normalized()
		var prev_l: Vector3 = pos
		var prev_r: Vector3 = pos
		for k in range(6):
			var s: float = float(k) / 5.0
			var p: Vector3 = _bez(pos, mid, tip, s)
			var w: float = sin(PI * s) * size * 0.46
			var pl: Vector3 = p + perp * w
			var pr: Vector3 = p - perp * w
			if k > 0:
				_quad_out(st, prev_l, prev_r, pr, pl, pos - up * size)
			prev_l = pl
			prev_r = pr
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	if mesh != null and mesh.get_surface_count() > 0:
		var mi: MeshInstance3D = _add(root, mesh, mat_pet)
		mi.transform = Transform3D(Basis(), Vector3.ZERO)
	var sph := SphereMesh.new()
	sph.radius = size * 0.34
	sph.height = size * 0.60
	sph.radial_segments = 10
	sph.rings = 6
	var mc: MeshInstance3D = _add(root, sph, mat_core)
	mc.transform = Transform3D(Basis(), pos + up * (size * 0.20))


static func _pour(root: Node3D, cx: float, cz: float, top_y: float, r_top: float, r_base: float, mat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	var cols: int = 26
	var rows: int = 10
	var wob := PackedFloat32Array()
	for j in range(cols):
		wob.append(rng.randf_range(-0.030, 0.042))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(rows):
		var t0: float = float(i) / float(rows)
		var t1: float = float(i + 1) / float(rows)
		var y0: float = top_y * t0
		var y1: float = top_y * t1
		var rr0: float = _pour_r(t0, r_base, r_top)
		var rr1: float = _pour_r(t1, r_base, r_top)
		for j in range(cols):
			var j1: int = (j + 1) % cols
			var a0: float = TAU * float(j) / float(cols)
			var a1: float = TAU * float(j1) / float(cols)
			var w00: float = rr0 + float(wob[j]) * (1.0 - t0)
			var w01: float = rr0 + float(wob[j1]) * (1.0 - t0)
			var w10: float = rr1 + float(wob[j]) * (1.0 - t1)
			var w11: float = rr1 + float(wob[j1]) * (1.0 - t1)
			var p00 := Vector3(cx + cos(a0) * w00, y0, cz + sin(a0) * w00)
			var p01 := Vector3(cx + cos(a1) * w01, y0, cz + sin(a1) * w01)
			var p10 := Vector3(cx + cos(a0) * w10, y1, cz + sin(a0) * w10)
			var p11 := Vector3(cx + cos(a1) * w11, y1, cz + sin(a1) * w11)
			_quad_out(st, p00, p10, p11, p01, Vector3(cx, (y0 + y1) * 0.5, cz))
	var apex := Vector3(cx, top_y + 0.012, cz)
	var rim: float = _pour_r(1.0, r_base, r_top)
	for j in range(cols):
		var j1: int = (j + 1) % cols
		var a0: float = TAU * float(j) / float(cols)
		var a1: float = TAU * float(j1) / float(cols)
		var q0 := Vector3(cx + cos(a0) * rim, top_y, cz + sin(a0) * rim)
		var q1 := Vector3(cx + cos(a1) * rim, top_y, cz + sin(a1) * rim)
		_quad_out(st, apex, q0, q1, apex, Vector3(cx, top_y - 0.30, cz))
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var mi: MeshInstance3D = _add(root, mesh, mat)
	mi.transform = Transform3D(Basis(), Vector3.ZERO)


static func _quad_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, inside: Vector3) -> void:
	# emit a quad whose Godot front face points away from `inside`
	var n_front: Vector3 = (c - a).cross(b - a)
	var centroid: Vector3 = (a + b + c + d) * 0.25
	if n_front.dot(centroid - inside) >= 0.0:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(d)
	else:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)
		st.add_vertex(a)
		st.add_vertex(d)
		st.add_vertex(c)


static func _basis_y_to(dir: Vector3) -> Basis:
	if dir.length() < 0.000001:
		return Basis()
	var d: Vector3 = dir.normalized()
	var dot_up: float = d.dot(Vector3.UP)
	if dot_up > 0.9999:
		return Basis()
	if dot_up < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	var ax: Vector3 = Vector3.UP.cross(d).normalized()
	var ang: float = acos(clampf(dot_up, -1.0, 1.0))
	return Basis(ax, ang)


# ---------------------------------------------------------------------------
# material

static func _c(scheme: Array, i: int) -> Color:
	var code: String = scheme[i]
	return Color(code)


static func _bone(c: Color) -> Color:
	var t := Color(0.88, 0.86, 0.79)
	return Color(lerpf(c.r, t.r, 0.74), lerpf(c.g, t.g, 0.74), lerpf(c.b, t.b, 0.74))


static func _wax(c: Color) -> Color:
	return Color(clampf(c.r * 1.10 + 0.06, 0.0, 1.0), clampf(c.g * 0.88, 0.0, 1.0), clampf(c.b * 0.80, 0.0, 1.0))


static func _cord(c: Color, tex: ImageTexture, uv: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.albedo_texture = tex
	m.roughness = 0.93
	m.metallic = 0.0
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(uv, uv, uv)
	return m


static func _cord2(strand: String, c: Color, tex: ImageTexture, uv: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = _cord(c, tex, uv)
	if strand == "fossil":
		m.roughness = 1.0
		m.uv1_scale = Vector3(uv * 0.55, uv * 0.55, uv * 0.55)
	elif strand == "molten":
		m.roughness = 0.16
		m.metallic = 0.22
		m.uv1_scale = Vector3(uv * 0.45, uv * 0.45, uv * 0.45)
	return m


static func _cord_texture(rng: RandomNumberGenerator, n1: int, n2: int, contrast: float) -> ImageTexture:
	# two counter-twisted plies; integer frequencies so the tile is seamless,
	# near-white so albedo_color tints it
	var img: Image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	var ph: float = rng.randf_range(0.0, TAU)
	for y in range(TEX_SIZE):
		for x in range(TEX_SIZE):
			var fx: float = float(x) / float(TEX_SIZE)
			var fy: float = float(y) / float(TEX_SIZE)
			var a: float = sin(TAU * (fx * float(n1) + fy * float(n2)) + ph)
			var b: float = sin(TAU * (fx * float(n2) - fy * float(n1)) - ph * 0.7)
			var ply: float = 0.5 + 0.5 * maxf(a, b * 0.85)
			var val: float = 1.0 - contrast * (1.0 - ply)
			var fuzz: float = rng.randf_range(-0.035, 0.035)
			var r_v: float = clampf(val + fuzz, 0.0, 1.0)
			var g_v: float = clampf(val + fuzz * 0.8, 0.0, 1.0)
			var b_v: float = clampf(val + fuzz * 0.6, 0.0, 1.0)
			img.set_pixel(x, y, Color(r_v, g_v, b_v))
	return ImageTexture.create_from_image(img)


static func _grain_texture(rng: RandomNumberGenerator, contrast: float) -> ImageTexture:
	# chalk: mottled pitting, no twist — integer frequencies so the tile is seamless
	var img: Image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	var ph: float = rng.randf_range(0.0, TAU)
	for y in range(TEX_SIZE):
		for x in range(TEX_SIZE):
			var fx: float = float(x) / float(TEX_SIZE)
			var fy: float = float(y) / float(TEX_SIZE)
			var a: float = sin(TAU * (fx * 3.0 + fy * 5.0) + ph) * sin(TAU * (fx * 7.0 - fy * 2.0) - ph)
			var b: float = sin(TAU * (fx * 11.0 - fy * 9.0) + ph * 0.3)
			var m: float = 0.5 + 0.36 * a + 0.14 * b
			var val: float = 1.0 - contrast * clampf(1.0 - m, 0.0, 1.0)
			var fuzz: float = rng.randf_range(-0.055, 0.055)
			var r_v: float = clampf(val + fuzz, 0.0, 1.0)
			var g_v: float = clampf(val + fuzz * 0.9, 0.0, 1.0)
			var b_v: float = clampf(val + fuzz * 0.75, 0.0, 1.0)
			img.set_pixel(x, y, Color(r_v, g_v, b_v))
	return ImageTexture.create_from_image(img)


static func _union_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		if cm.mesh == null:
			continue
		var local: AABB = cm.mesh.get_aabb()
		var wb: AABB = cm.transform * local
		if first:
			box = wb
			first = false
		else:
			box = box.merge(wb)
	return box
