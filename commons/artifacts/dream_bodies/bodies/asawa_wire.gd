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


static func describe() -> String:
	return "A hollow standing figure drawn only in looping cord — a hundred-odd rings and swept loops trace hips, waist, shoulders and skull, crowding into knitted skin in two bands and unravelling into open tangle elsewhere, so you see through the body to the far side."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var scheme: Array = SCHEMES[rng.randi_range(0, SCHEMES.size() - 1)]
	var col_main: Color = _c(scheme, 0)
	var col_alt: Color = _c(scheme, 1)
	var col_knot: Color = _c(scheme, 2)
	var col_ball: Color = _c(scheme, 3)

	var tex_tight: ImageTexture = _cord_texture(rng, 7, 4, 0.34)
	var tex_loose: ImageTexture = _cord_texture(rng, 4, 3, 0.26)

	var mats_main: Array = [
		_cord(col_main, tex_tight, 12.0),
		_cord(col_main.lightened(0.09), tex_tight, 12.0),
		_cord(col_main.darkened(0.09), tex_tight, 12.0),
	]
	var mats_alt: Array = [
		_cord(col_alt, tex_loose, 10.0),
		_cord(col_alt.lightened(0.10), tex_loose, 10.0),
	]
	var mat_knot: StandardMaterial3D = _cord(col_knot, tex_tight, 26.0)
	var mat_ball: StandardMaterial3D = _cord(col_ball, tex_loose, 8.0)

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

	var bp := {
		"h": body_h,
		"k": body_k,
		"lx": lean_x,
		"lz": lean_z,
		"sw": sway,
		"dlo": depth_lo,
	}

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
		var frame: Basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, tx) * Basis(Vector3.FORWARD, tz) * Basis.from_scale(Vector3(1.0, 1.0, dk))
		var use_alt: bool = _in_band(v, alt_a, alt_w) or _in_band(v, alt_b, alt_w) or rng.randf() < 0.05
		var mat: StandardMaterial3D = null
		if use_alt:
			mat = mats_alt[rng.randi_range(0, mats_alt.size() - 1)]
		else:
			mat = mats_main[rng.randi_range(0, mats_main.size() - 1)]
		var thick: float = cord_r * (0.82 if dense else 1.0)
		_ring(root, ctr, frame, r_maj, thick, mat)
		var dy: float = 0.0165
		if dense:
			dy = 0.0072
		elif v > 0.80:
			dy = 0.0110
		v += dy / (body_h * V_SPAN)

	# --- skull: three meridian rings close the head cage ---------------------
	var skull_v: float = 0.925
	var skull_c: Vector3 = _axis_at(bp, skull_v)
	var skull_r: float = _profile_at(skull_v) * body_k
	for m_i in range(3):
		var phi: float = PI * float(m_i) / 3.0 + twist
		var ax: Vector3 = Vector3(cos(phi), 0.0, sin(phi))
		_ring(root, skull_c, _basis_y_to(ax), skull_r * 0.96, cord_r * 0.9, mats_main[m_i % mats_main.size()])

	# --- legs: two ring columns, one standing, one free and forward ----------
	var hip_off: Vector3 = _axis_at(bp, 0.10)
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var is_stand: bool = (sd == stand_leg)
		var foot_fwd: float = -0.030 if is_stand else 0.060
		var spread: float = 0.046 if is_stand else 0.082
		var knee_out: float = 0.012 if is_stand else 0.030
		var y_ankle: float = 0.030
		var y_hip: float = 0.50 * body_h
		var steps: int = clampi(int(round((y_hip - y_ankle) / 0.030)), 12, 28)
		var prev: Vector3 = Vector3.ZERO
		for k in range(steps + 1):
			var w: float = float(k) / float(steps)
			var lx: float = sd * lerpf(spread, 0.085, w) * body_k + hip_off.x * (w * w) + sd * knee_out * sin(PI * w)
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
			var lf: Basis = _basis_y_to(tang) * Basis(Vector3.RIGHT, jx) * Basis(Vector3.FORWARD, jz) * Basis.from_scale(Vector3(1.0, 1.0, 0.86))
			var lm: StandardMaterial3D = null
			if rng.randf() < 0.10:
				lm = mats_alt[rng.randi_range(0, mats_alt.size() - 1)]
			else:
				lm = mats_main[rng.randi_range(0, mats_main.size() - 1)]
			_ring(root, q, lf, r_leg, cord_r, lm)
			prev = q
		# foot: three near-flat rings running forward from the ankle
		var ankle := Vector3(sd * spread * body_k, y_ankle, -foot_fwd)
		for f_i in range(3):
			var ff: float = float(f_i)
			var fr: float = 0.042 - ff * 0.007
			var fy: float = 0.023 - ff * 0.002
			var fz: float = ankle.z - 0.030 - ff * 0.028
			var fax := Vector3(sd * 0.10, 1.0, -0.26).normalized()
			_ring(root, Vector3(ankle.x + sd * 0.004 * ff, fy, fz), _basis_y_to(fax), fr * body_k, cord_r * 0.9, mats_main[f_i % mats_main.size()])

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
		var a_steps: int = 13
		for k in range(a_steps + 1):
			var s: float = 0.05 + 0.95 * float(k) / float(a_steps)
			var q: Vector3 = _bez(sp, el, wr, s)
			var d: Vector3 = 2.0 * (1.0 - s) * (el - sp) + 2.0 * s * (wr - el)
			if d.length() < 0.0001:
				d = Vector3.DOWN
			var r_arm: float = lerpf(0.056, 0.030, pow(s, 0.85)) * body_k
			var jx: float = rng.randf_range(-0.10, 0.10)
			var jz: float = rng.randf_range(-0.10, 0.10)
			var af: Basis = _basis_y_to(d.normalized()) * Basis(Vector3.RIGHT, jx) * Basis(Vector3.FORWARD, jz) * Basis.from_scale(Vector3(1.0, 1.0, 0.90))
			var am: StandardMaterial3D = null
			if rng.randf() < 0.16:
				am = mats_alt[rng.randi_range(0, mats_alt.size() - 1)]
			else:
				am = mats_main[rng.randi_range(0, mats_main.size() - 1)]
			_ring(root, q, af, r_arm, cord_r * 0.95, am)
		# a knot of two crossed rings for the hand
		var hd: Vector3 = (wr - el).normalized()
		var hx: Vector3 = hd.cross(Vector3.UP)
		if hx.length() < 0.0001:
			hx = hd.cross(Vector3.RIGHT)
		_ring(root, wr + hd * 0.020, _basis_y_to(hx.normalized()), 0.036 * body_k, cord_r * 0.9, mat_knot)
		_ring(root, wr + hd * 0.036, _basis_y_to(hd), 0.030 * body_k, cord_r * 0.9, mat_knot)

	# --- knitted patches: small stitch rings lying on the skin ---------------
	for band_i in range(2):
		var bc: float = knit_a if band_i == 0 else knit_b
		var th0: float = -PI * 0.5 + rng.randf_range(-0.7, 0.7)
		for r_i in range(2):
			for c_i in range(5):
				var vv: float = bc + (float(r_i) - 0.5) * 0.034
				var th: float = th0 + (float(c_i) - 2.0) * 0.40
				var pos: Vector3 = _body_point(bp, vv, th, 1.0)
				var dk2: float = _depth_at(vv, depth_lo)
				var nn: Vector3 = Vector3(cos(th), 0.14, sin(th) / maxf(dk2, 0.35)).normalized()
				_ring(root, pos + nn * (cord_r * 0.5), _basis_y_to(nn), cord_r * 2.5, cord_r * 0.7, mat_knot)

	# --- continuous loops climbing and wrapping the body ---------------------
	var n_loops: int = rng.randi_range(3, 5)
	for l_i in range(n_loops):
		var v0: float = rng.randf_range(0.0, 0.42)
		var v1: float = minf(0.95, v0 + rng.randf_range(0.26, 0.55))
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
		_tube(root, path, cord_r * 0.92, lm, true)

	# --- open tangle arcs that balloon off the surface and re-land -----------
	var n_tangle: int = rng.randi_range(2, 3)
	for t_i in range(n_tangle):
		var va: float = rng.randf_range(0.06, 0.72)
		var vb: float = clampf(va + rng.randf_range(-0.24, 0.26), 0.02, 0.94)
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
		_tube(root, path2, cord_r * 0.85, tm, false)

	# --- a ball of wound cord on the floor beside the feet -------------------
	var ball_r: float = rng.randf_range(0.085, 0.115)
	var ball_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var ball_c := Vector3(ball_side * rng.randf_range(0.22, 0.30), ball_r + cord_r * 1.4 + 0.003, rng.randf_range(-0.06, 0.16))
	var n_ball: int = rng.randi_range(7, 9)
	for b_i in range(n_ball):
		var fb: float = float(b_i) / float(n_ball)
		var ax2 := Vector3(sin(fb * 9.4 + 0.7), cos(fb * 6.1), sin(fb * 4.3 + 2.1)).normalized()
		var rb: float = ball_r * (0.78 + 0.22 * cos(fb * 5.0))
		_ring(root, ball_c, _basis_y_to(ax2), rb, cord_r * 1.05, mat_ball)

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


static func _tube(root: Node3D, pts_in: PackedVector3Array, r: float, mat: StandardMaterial3D, closed: bool) -> void:
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
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
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
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
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


static func _cord(c: Color, tex: ImageTexture, uv: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.albedo_texture = tex
	m.roughness = 0.93
	m.metallic = 0.0
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(uv, uv, uv)
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
