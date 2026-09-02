extends RefCounted

## dream_bodies / piped_icing — one arching confectionery body extruded like piped icing.
##
## Reference: scratchpad/refs/wesselmann_vasarely.png (2048x536 panorama) — a black
## wall of glossy plastic bodies: a reclining mass built of dense parallel ribbed
## ribbons striped pink-and-white, fat lemon-yellow balloon tubes with pinched
## joints and trumpet mouths branching out of it, one cyan balloon limb, a knobbly
## grey patch of small spheres like a bunch of grapes, a pale cream-lime ribbed
## lobe alongside, and frilled ruffles where the ribbons stop.
##
## Reproduced, and how:
##   1. The piped ribs — 24..32 ribbons, each ONE SurfaceTool tube swept along a
##      full helical turn around the body's elliptical cross-section, advancing
##      exactly one pitch per turn so the turns stack into a continuous coil of
##      icing; tube radius is derived from the measured spine length / turn count
##      so neighbours touch and leave a groove.
##   2. Pink-and-white candy stripe — the coil colour follows a repeating pattern
##      (deep pink / white / pale pink / cream) with a seeded offset, so the
##      stripe reads across the whole mass instead of per-part.
##   3. The arching reclining gesture — a Catmull-Rom spine over 6 control points:
##      a heavy haunch sitting on the floor, the back rising and swinging back,
##      the shoulder arching over forward, the tip curling down and out. Seeded
##      lean, sway, twist and left/right mirror; the cross-section is an ellipse
##      with an off-axis bulge, so no station is radially symmetric.
##   4. Balloon limbs — 3..4 tapering chains of capsule bulbs separated by a gap
##      and bridged by a small sphere, which reads as the pinched neck of a
##      balloon animal; each ends in a flared cone mouth with a TorusMesh lip.
##      All lemon yellow but one, which is the thinner cyan limb.
##   5. The bubble patch — 24..40 small grey spheres in rings around a short
##      curved grey core, sizes and greys jittered, two pink strays, hung off the
##      mid-body on the opposite side from the cream lobe.
##   6. Frilled ends — 3 fans of curled ArrayMesh ruffles (skirt at the foot, at
##      the tip of the arch, at the tip of the lobe): each petal is an arc-bent
##      sheet that widens as it goes and carries a sine flute across its width
##      growing toward the free edge.
##   7. The second ribbed mass — a short cream-lime lobe branching off the lower
##      body, built by the same coil routine at smaller scale, so the two ribbed
##      bodies interleave the way the pink and green ones do in the reference.
##   8. Confectionery plastic — clearcoat 1.0, roughness 0.1 on everything; the
##      hidden core carries a code-painted fine stripe texture on triplanar UVs
##      and the bubble core a dot lattice, so any groove that shows through still
##      reads as icing rather than as a gap.
##
## Given up: the black leaf wallpaper and the whole rest of the frieze, the
## neighbouring bodies, the smooth fishnet-textured pink torso at the left, the
## brain-coral surface of the pale lobe (plain ribs stand in), and subsurface
## translucency in the pale icing.

const TEX_SIZE: int = 128

# [pink_deep, pink_pale, white, cream, yellow, cyan, grey_a, grey_b, core, lobe_a, lobe_b]
const SCHEMES: Array = [
	["#EF9AB6", "#F9CFDB", "#FDF5F2", "#F2E3C3", "#F5C41F", "#68CFE2", "#CCCECB", "#A5A9A7", "#EEA6BD", "#E7EBC6", "#F4F5DE"],
	["#E77FA6", "#F6BFCF", "#FEF8F4", "#EEE1BD", "#F2BA1A", "#5FC7DD", "#C5C8C5", "#9DA2A0", "#E794B3", "#DFE6BE", "#EFF1D6"],
	["#F3AEC0", "#FADCE2", "#FFFAF7", "#E9E2C5", "#F8CE33", "#7BD8E6", "#D3D5D2", "#ACB0AE", "#F2B7C6", "#EAEFCF", "#F7F8E6"],
]

const PATTERNS: Array = [
	[0, 2, 2, 1, 2, 0, 2, 3, 2],
	[0, 2, 1, 2, 0, 2, 2, 3],
	[0, 0, 2, 2, 1, 2, 3, 2, 2],
]


static func describe() -> String:
	return "An arching confectionery body coiled out of dense pink-and-white piped icing ribs, with fat yellow balloon limbs, one cyan limb, a knobbly grey bubble patch and cream ruffles at every end."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var sch: Array = SCHEMES[rng.randi_range(0, SCHEMES.size() - 1)]
	var c_pink: Color = _c(sch, 0)
	var c_pink2: Color = _c(sch, 1)
	var c_white: Color = _c(sch, 2)
	var c_cream: Color = _c(sch, 3)
	var c_yellow: Color = _c(sch, 4)
	var c_cyan: Color = _c(sch, 5)
	var c_grey_a: Color = _c(sch, 6)
	var c_grey_b: Color = _c(sch, 7)
	var c_core: Color = _c(sch, 8)
	var c_lobe_a: Color = _c(sch, 9)
	var c_lobe_b: Color = _c(sch, 10)

	var tex_stripe: ImageTexture = _stripe_texture(rng, rng.randi_range(10, 16))
	var tex_dots: ImageTexture = _dot_texture(rng, rng.randi_range(8, 12))

	var mat_core: StandardMaterial3D = _icing(c_core, 0.16)
	mat_core.albedo_texture = tex_stripe
	mat_core.uv1_triplanar = true
	mat_core.uv1_scale = Vector3(2.4, 2.4, 2.4)

	var mat_lobe_core: StandardMaterial3D = _icing(c_lobe_a.darkened(0.06), 0.16)
	mat_lobe_core.albedo_texture = tex_stripe
	mat_lobe_core.uv1_triplanar = true
	mat_lobe_core.uv1_scale = Vector3(2.8, 2.8, 2.8)

	var rib_mats: Array = [
		_icing(c_pink, 0.10),
		_icing(c_pink2, 0.10),
		_icing(c_white, 0.10),
		_icing(c_cream, 0.12),
	]
	var lobe_mats: Array = [
		_icing(c_lobe_a, 0.10),
		_icing(c_cream, 0.11),
		_icing(c_lobe_b, 0.10),
		_icing(c_white, 0.10),
	]
	var mat_yellow: StandardMaterial3D = _icing(c_yellow, 0.09)
	var mat_yellow_j: StandardMaterial3D = _icing(c_yellow.lightened(0.10), 0.09)
	var mat_cyan: StandardMaterial3D = _icing(c_cyan, 0.09)
	var mat_cyan_j: StandardMaterial3D = _icing(c_cyan.lightened(0.10), 0.09)
	var mat_bub_a: StandardMaterial3D = _icing(c_grey_a, 0.11)
	var mat_bub_b: StandardMaterial3D = _icing(c_grey_b, 0.11)
	var mat_bub_c: StandardMaterial3D = _icing(c_pink2, 0.11)
	var mat_bub_core: StandardMaterial3D = _icing(c_grey_b.darkened(0.10), 0.18)
	mat_bub_core.albedo_texture = tex_dots
	mat_bub_core.uv1_triplanar = true
	mat_bub_core.uv1_scale = Vector3(5.0, 5.0, 5.0)

	var mat_frill_a: StandardMaterial3D = _sheet(c_cream)
	var mat_frill_b: StandardMaterial3D = _sheet(c_white)
	var mat_frill_c: StandardMaterial3D = _sheet(c_lobe_b)

	# --- gesture ------------------------------------------------------------
	var side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var lean: float = rng.randf_range(-0.085, 0.085)
	var sway: float = rng.randf_range(-0.07, 0.07)
	var body_k: float = rng.randf_range(0.93, 1.06)
	var squash: float = rng.randf_range(0.10, 0.20)
	var bulge: float = rng.randf_range(0.06, 0.15)
	var bulge_phase: float = rng.randf_range(0.0, TAU)
	var twist: float = rng.randf_range(-1.2, 1.2)

	var raw: Array = [
		Vector3(0.12 + lean, 0.10, 0.20 + sway),
		Vector3(0.02 + lean * 0.6, 0.41, 0.27),
		Vector3(-0.09 + sway, 0.72, 0.12),
		Vector3(-0.05, 1.00, -0.09),
		Vector3(0.08 - sway, 1.15, -0.27),
		Vector3(0.22 + lean, 0.97, -0.36),
	]
	var ctrl: Array = []
	for i in range(raw.size()):
		var cp: Vector3 = raw[i]
		var jx: float = rng.randf_range(-0.022, 0.022)
		var jz: float = rng.randf_range(-0.022, 0.022)
		var jy: float = rng.randf_range(-0.015, 0.015)
		ctrl.append(Vector3((cp.x + jx) * body_k * side, (cp.y + jy) * body_k, (cp.z + jz) * body_k))

	var r_keys: Array = [
		0.150 * body_k, 0.182 * body_k, 0.196 * body_k, 0.172 * body_k,
		0.138 * body_k, 0.108 * body_k, 0.086 * body_k,
	]
	var st_main: Array = _stations(ctrl, 200, r_keys, squash, twist)
	var len_main: float = _spine_length(st_main)

	# --- main body: hidden core, then the coil of ribs -----------------------
	_core_chain(root, st_main, 22, 0.90, mat_core)

	var n_rib: int = rng.randi_range(24, 32)
	var t0: float = 0.02
	var t1: float = 0.985
	var pitch: float = len_main * (t1 - t0) / float(n_rib)
	var tube_r: float = pitch * rng.randf_range(0.50, 0.57)
	var overrun: float = rng.randf_range(0.40, 0.75)
	var phase0: float = rng.randf_range(0.0, TAU)
	var pat: Array = PATTERNS[rng.randi_range(0, PATTERNS.size() - 1)]
	var pat_off: int = rng.randi_range(0, 7)
	for k in range(n_rib):
		var a0: float = lerpf(t0, t1, float(k) / float(n_rib))
		var a1: float = lerpf(t0, t1, float(k + 1) / float(n_rib))
		var ph: float = phase0 + float(k) * overrun
		var mesh: ArrayMesh = _ribbon(st_main, a0, a1, ph, 34, tube_r, overrun, bulge, bulge_phase)
		var pick: int = int(pat[posmod(k + pat_off, pat.size())])
		var mi: MeshInstance3D = _add(root, mesh, rib_mats[pick])
		mi.transform = Transform3D()

	# --- the pale ribbed lobe ------------------------------------------------
	var lob_t: float = rng.randf_range(0.26, 0.40)
	var lob_s: Array = _sample(st_main, lob_t)
	var lob_p: Vector3 = lob_s[0]
	var lob_u: Vector3 = lob_s[1]
	var lob_v: Vector3 = lob_s[2]
	var lob_dir: Vector3 = (lob_u * (0.85 * side) + lob_v * rng.randf_range(-0.35, 0.35) + Vector3(0.0, 0.30, 0.0)).normalized()
	var lob_up: Vector3 = (Vector3.UP - lob_dir * Vector3.UP.dot(lob_dir)).normalized()
	var lob_k: float = rng.randf_range(0.85, 1.05)
	var lctrl: Array = [
		lob_p,
		lob_p + lob_dir * (0.13 * lob_k),
		lob_p + lob_dir * (0.25 * lob_k) + lob_up * (0.09 * lob_k),
		lob_p + lob_dir * (0.32 * lob_k) + lob_up * (0.22 * lob_k),
		lob_p + lob_dir * (0.30 * lob_k) + lob_up * (0.35 * lob_k),
	]
	for i in range(lctrl.size()):
		var lp: Vector3 = lctrl[i]
		lctrl[i] = lp + Vector3(rng.randf_range(-0.018, 0.018), rng.randf_range(-0.015, 0.015), rng.randf_range(-0.018, 0.018))
	var lr_keys: Array = [
		0.105 * lob_k, 0.124 * lob_k, 0.116 * lob_k, 0.088 * lob_k, 0.058 * lob_k,
	]
	var st_lobe: Array = _stations(lctrl, 120, lr_keys, squash * 0.7, twist * 0.6)
	var len_lobe: float = _spine_length(st_lobe)
	_core_chain(root, st_lobe, 10, 0.90, mat_lobe_core)

	var n_rib2: int = rng.randi_range(9, 13)
	var pitch2: float = len_lobe * 0.94 / float(n_rib2)
	var tube_r2: float = pitch2 * rng.randf_range(0.50, 0.57)
	var phase2: float = rng.randf_range(0.0, TAU)
	var pat2: Array = PATTERNS[rng.randi_range(0, PATTERNS.size() - 1)]
	for k in range(n_rib2):
		var b0: float = lerpf(0.03, 0.97, float(k) / float(n_rib2))
		var b1: float = lerpf(0.03, 0.97, float(k + 1) / float(n_rib2))
		var ph2: float = phase2 + float(k) * overrun
		var mesh2: ArrayMesh = _ribbon(st_lobe, b0, b1, ph2, 28, tube_r2, overrun, bulge * 0.7, bulge_phase)
		var pick2: int = int(pat2[posmod(k, pat2.size())])
		var mi2: MeshInstance3D = _add(root, mesh2, lobe_mats[pick2])
		mi2.transform = Transform3D()

	# --- balloon limbs -------------------------------------------------------
	var n_limb: int = rng.randi_range(3, 4)
	var cyan_i: int = rng.randi_range(0, n_limb - 1)
	for li in range(n_limb):
		var f: float = float(li) / float(maxi(n_limb - 1, 1))
		var lt: float = lerpf(0.50, 0.87, f) + rng.randf_range(-0.045, 0.045)
		var s: Array = _sample(st_main, lt)
		var sp: Vector3 = s[0]
		var su: Vector3 = s[1]
		var sv: Vector3 = s[2]
		var sra: float = float(s[3])
		var ang: float = rng.randf_range(0.0, TAU)
		var radial: Vector3 = (su * cos(ang) + sv * sin(ang)).normalized()
		var org: Vector3 = sp + radial * (sra * 0.72)
		var d0: Vector3 = (radial * 0.80 + Vector3(0.0, 0.90, 0.0)).normalized()
		var bax: Vector3 = _perp(d0).rotated(d0, rng.randf_range(0.0, TAU))
		var bend: float = rng.randf_range(0.20, 0.42) * (1.0 if rng.randf() < 0.5 else -1.0)
		var segs: int = rng.randi_range(4, 6)
		if li == cyan_i:
			_balloon(root, org, d0, bax, segs, rng.randf_range(0.037, 0.047), bend, mat_cyan, mat_cyan_j, rng)
		else:
			_balloon(root, org, d0, bax, segs, rng.randf_range(0.050, 0.063), bend, mat_yellow, mat_yellow_j, rng)

	# --- the grey bubble patch ----------------------------------------------
	var bt: float = rng.randf_range(0.38, 0.54)
	var bs: Array = _sample(st_main, bt)
	var bp0: Vector3 = bs[0]
	var bu: Vector3 = bs[1]
	var bv: Vector3 = bs[2]
	var bra: float = float(bs[3])
	var b_dir: Vector3 = (bu * (-0.90 * side) + bv * rng.randf_range(-0.3, 0.3) + Vector3(0.0, -0.22, 0.0)).normalized()
	var b_axis: Vector3 = _perp(b_dir).rotated(b_dir, rng.randf_range(0.0, TAU))
	var b_bend: float = rng.randf_range(-0.26, 0.26)
	var b_steps: int = rng.randi_range(6, 8)
	var b_step: float = rng.randf_range(0.048, 0.060)
	var bpath: Array = []
	var bpp: Vector3 = bp0 + b_dir * (bra * 0.55)
	var bdd: Vector3 = b_dir
	for i in range(b_steps):
		bpath.append(bpp)
		bpp = bpp + bdd * b_step
		bdd = bdd.rotated(b_axis, b_bend).normalized()
	for i in range(b_steps - 1):
		var ca: Vector3 = bpath[i]
		var cb: Vector3 = bpath[i + 1]
		var cr: float = lerpf(0.058, 0.040, float(i) / float(maxi(b_steps - 2, 1)))
		_bulb(root, ca, cb, cr, mat_bub_core)
	var per_ring: int = rng.randi_range(4, 5)
	for i in range(b_steps):
		var fr: float = float(i) / float(maxi(b_steps - 1, 1))
		var cr2: float = lerpf(0.058, 0.038, fr)
		var e1: Vector3 = _perp(bdd)
		var e2: Vector3 = bdd.cross(e1).normalized()
		var roll: float = rng.randf_range(0.0, TAU)
		for j in range(per_ring):
			var a2: float = roll + TAU * float(j) / float(per_ring) + rng.randf_range(-0.22, 0.22)
			var br: float = rng.randf_range(0.026, 0.043)
			var rd: Vector3 = (e1 * cos(a2) + e2 * sin(a2)).normalized()
			var wob: Vector3 = bdd * rng.randf_range(-0.016, 0.016)
			var sph := SphereMesh.new()
			sph.radius = br
			sph.height = br * 2.0
			sph.radial_segments = 14
			sph.rings = 8
			var pickm: StandardMaterial3D = mat_bub_a
			var roll2: float = rng.randf()
			if roll2 > 0.94:
				pickm = mat_bub_c
			elif roll2 > 0.5:
				pickm = mat_bub_b
			var seat: Vector3 = bpath[i]
			var bm: MeshInstance3D = _add(root, sph, pickm)
			bm.transform = Transform3D(Basis(), seat + rd * (cr2 * 0.72 + br * 0.42) + wob)

	# --- frills where the ribbons stop --------------------------------------
	var f_foot: Array = _sample(st_main, 0.015)
	var f_foot2: Array = _sample(st_main, 0.06)
	var foot_p: Vector3 = f_foot[0]
	var foot_p2: Vector3 = f_foot2[0]
	var foot_r: float = float(f_foot[3])
	var foot_dir: Vector3 = (foot_p2 - foot_p).normalized()
	_frill(root, foot_p - foot_dir * (foot_r * 0.20), -foot_dir, rng.randi_range(5, 7), 0.115, 0.085, mat_frill_a, rng)

	var f_tip: Array = _sample(st_main, 0.99)
	var f_tip2: Array = _sample(st_main, 0.93)
	var tip_p: Vector3 = f_tip[0]
	var tip_p2: Vector3 = f_tip2[0]
	var tip_dir: Vector3 = (tip_p - tip_p2).normalized()
	_frill(root, tip_p + tip_dir * 0.015, tip_dir, rng.randi_range(4, 6), 0.100, 0.072, mat_frill_b, rng)

	var f_lob: Array = _sample(st_lobe, 0.985)
	var f_lob2: Array = _sample(st_lobe, 0.90)
	var lt_p: Vector3 = f_lob[0]
	var lt_p2: Vector3 = f_lob2[0]
	var lt_dir: Vector3 = (lt_p - lt_p2).normalized()
	_frill(root, lt_p + lt_dir * 0.012, lt_dir, rng.randi_range(4, 6), 0.082, 0.060, mat_frill_c, rng)

	# --- settle: fit the box, centre on x/z, sit on the floor ----------------
	_settle(root)


# ---------------------------------------------------------------------------
# body construction

static func _core_chain(root: Node3D, st_arr: Array, n: int, shrink: float, mat: StandardMaterial3D) -> void:
	var total: float = _spine_length(st_arr)
	var sy: float = maxf(total / float(maxi(n - 1, 1)) * 0.80, 0.03)
	for i in range(n):
		var t: float = float(i) / float(n - 1)
		var s: Array = _sample(st_arr, t)
		var p: Vector3 = s[0]
		var u_v: Vector3 = s[1]
		var v_v: Vector3 = s[2]
		var ra: float = float(s[3]) * shrink
		var rb: float = float(s[4]) * shrink
		var tg: Vector3 = u_v.cross(v_v).normalized()
		var sph := SphereMesh.new()
		sph.radius = 1.0
		sph.height = 2.0
		sph.radial_segments = 18
		sph.rings = 10
		var mi: MeshInstance3D = _add(root, sph, mat)
		mi.transform = Transform3D(Basis(u_v * ra, tg * sy, v_v * rb), p)


static func _ribbon(st_arr: Array, a0: float, a1: float, phase: float, steps: int, tube_r: float, overrun: float, bulge: float, bulge_phase: float) -> ArrayMesh:
	var path: Array = []
	var radii: Array = []
	var sweep: float = TAU + overrun
	for j in range(steps + 1):
		var f: float = float(j) / float(steps)
		var th: float = phase + f * sweep
		var tt: float = a0 + (a1 - a0) * (f * sweep / TAU)
		var s: Array = _sample(st_arr, tt)
		var p: Vector3 = s[0]
		var u_v: Vector3 = s[1]
		var v_v: Vector3 = s[2]
		var swell: float = 1.0 + bulge * cos(th - bulge_phase)
		var ra: float = float(s[3]) * swell
		var rb: float = float(s[4]) * swell
		path.append(p + u_v * (cos(th) * ra) + v_v * (sin(th) * rb))
		var taper: float = 1.0
		if f < 0.07:
			taper = 0.42 + 0.58 * (f / 0.07)
		elif f > 0.93:
			taper = 0.42 + 0.58 * ((1.0 - f) / 0.07)
		radii.append(tube_r * taper)
	return _tube_mesh(path, radii, 7)


static func _balloon(root: Node3D, org: Vector3, dir0: Vector3, axis: Vector3, n_seg: int, r0: float, bend: float, mat_a: StandardMaterial3D, mat_b: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	var p: Vector3 = org
	var d: Vector3 = dir0.normalized()
	var r: float = r0
	for i in range(n_seg):
		var f: float = float(i) / float(maxi(n_seg - 1, 1))
		r = r0 * lerpf(1.0, 0.55, f) * rng.randf_range(0.94, 1.06)
		var ln: float = r * rng.randf_range(2.2, 2.9)
		var q: Vector3 = p + d * ln
		_bulb(root, p, q, r, mat_a)
		var rn: float = r * 0.50
		var kn := SphereMesh.new()
		kn.radius = rn
		kn.height = rn * 2.0
		kn.radial_segments = 14
		kn.rings = 8
		var km: MeshInstance3D = _add(root, kn, mat_b)
		km.transform = Transform3D(Basis(), q + d * (rn * 0.35))
		p = q + d * (rn * 0.70)
		d = d.rotated(axis, bend + rng.randf_range(-0.09, 0.09)).normalized()
	var mouth_r: float = r * 1.55
	var bell := CylinderMesh.new()
	bell.bottom_radius = r * 0.72
	bell.top_radius = mouth_r
	bell.height = r * 1.75
	bell.radial_segments = 18
	var bm: MeshInstance3D = _add(root, bell, mat_a)
	bm.transform = Transform3D(_basis_y_to(d), p + d * (r * 0.88))
	var lip := TorusMesh.new()
	lip.inner_radius = mouth_r * 0.84
	lip.outer_radius = mouth_r * 1.06
	lip.rings = 10
	lip.ring_segments = 20
	var lm: MeshInstance3D = _add(root, lip, mat_b)
	lm.transform = Transform3D(_basis_y_to(d), p + d * (r * 1.74))


static func _frill(root: Node3D, org: Vector3, axis: Vector3, n: int, length: float, width: float, mat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	var a: Vector3 = axis.normalized()
	var e1: Vector3 = _perp(a)
	var e2: Vector3 = a.cross(e1).normalized()
	var off: float = rng.randf_range(0.0, TAU)
	for k in range(n):
		var ang: float = off + TAU * float(k) / float(n) + rng.randf_range(-0.14, 0.14)
		var radial: Vector3 = (e1 * cos(ang) + e2 * sin(ang)).normalized()
		var tilt: float = rng.randf_range(0.20, 0.80)
		var fwd: Vector3 = (radial * cos(tilt) + a * sin(tilt)).normalized()
		var sd: Vector3 = a.cross(radial).normalized()
		var up_v: Vector3 = sd.cross(fwd).normalized()
		var ln: float = length * rng.randf_range(0.72, 1.22)
		var wd: float = width * rng.randf_range(0.78, 1.28)
		var bend: float = rng.randf_range(1.0, 2.4) * (1.0 if rng.randf() < 0.7 else -1.0)
		var waves: float = float(rng.randi_range(3, 5))
		var mesh: ArrayMesh = _ruffle(org + radial * (width * 0.28), fwd, up_v, sd, ln, wd, bend, waves, wd * 0.30)
		var mi: MeshInstance3D = _add(root, mesh, mat)
		mi.transform = Transform3D()


static func _ruffle(org: Vector3, fwd: Vector3, up_v: Vector3, sd: Vector3, length: float, width: float, bend: float, waves: float, amp: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ua: int = 9
	var vb: int = 6
	var kk: float = bend
	if absf(kk) < 0.1:
		kk = 0.1
	var grid: Array = []
	for i in range(ua + 1):
		var a: float = float(i) / float(ua)
		var ang: float = kk * a
		var c: Vector3 = org + fwd * (length * sin(ang) / kk) + up_v * (length * (1.0 - cos(ang)) / kk)
		var tg: Vector3 = (fwd * cos(ang) + up_v * sin(ang)).normalized()
		var nn: Vector3 = tg.cross(sd).normalized()
		var row: Array = []
		for j in range(vb + 1):
			var b: float = float(j) / float(vb)
			var wdt: float = width * (0.40 + 0.95 * a)
			var flute: float = amp * sin(waves * PI * b) * pow(a, 1.25)
			row.append(c + sd * ((b - 0.5) * wdt) + nn * flute)
		grid.append(row)
	for i in range(ua):
		var r0: Array = grid[i]
		var r1: Array = grid[i + 1]
		for j in range(vb):
			var p00: Vector3 = r0[j]
			var p01: Vector3 = r0[j + 1]
			var p10: Vector3 = r1[j]
			var p11: Vector3 = r1[j + 1]
			st.add_vertex(p00)
			st.add_vertex(p10)
			st.add_vertex(p11)
			st.add_vertex(p00)
			st.add_vertex(p11)
			st.add_vertex(p01)
	st.generate_normals()
	return st.commit()


# ---------------------------------------------------------------------------
# spine / frame helpers

static func _spline(ctrl: Array, t: float) -> Vector3:
	var n: int = ctrl.size()
	var f: float = clampf(t, 0.0, 1.0) * float(n - 1)
	var i: int = int(floor(f))
	if i > n - 2:
		i = n - 2
	if i < 0:
		i = 0
	var u: float = f - float(i)
	var p0: Vector3 = ctrl[maxi(i - 1, 0)]
	var p1: Vector3 = ctrl[i]
	var p2: Vector3 = ctrl[mini(i + 1, n - 1)]
	var p3: Vector3 = ctrl[mini(i + 2, n - 1)]
	return p1.cubic_interpolate(p2, p0, p3, u)


static func _key(keys: Array, t: float) -> float:
	var n: int = keys.size()
	var f: float = clampf(t, 0.0, 1.0) * float(n - 1)
	var i: int = int(floor(f))
	if i >= n - 1:
		return float(keys[n - 1])
	var u: float = f - float(i)
	var s: float = u * u * (3.0 - 2.0 * u)
	return lerpf(float(keys[i]), float(keys[i + 1]), s)


static func _stations(ctrl: Array, ns: int, r_keys: Array, squash: float, twist: float) -> Array:
	var pts: Array = []
	for i in range(ns):
		pts.append(_spline(ctrl, float(i) / float(ns - 1)))
	var tang: Array = []
	for i in range(ns):
		var a: Vector3 = pts[maxi(i - 1, 0)]
		var b: Vector3 = pts[mini(i + 1, ns - 1)]
		var d: Vector3 = b - a
		if d.length() < 0.00001:
			d = Vector3.UP
		tang.append(d.normalized())
	var t0: Vector3 = tang[0]
	var u_v: Vector3 = _perp(t0)
	var out: Array = []
	for i in range(ns):
		var tg: Vector3 = tang[i]
		var pu: Vector3 = u_v - tg * u_v.dot(tg)
		if pu.length() < 0.0001:
			pu = _perp(tg)
		u_v = pu.normalized()
		var v_v: Vector3 = tg.cross(u_v).normalized()
		var t: float = float(i) / float(ns - 1)
		var rr: float = _key(r_keys, t)
		var ang: float = twist * t
		var uu: Vector3 = (u_v * cos(ang) + v_v * sin(ang)).normalized()
		var vv: Vector3 = (u_v * -sin(ang) + v_v * cos(ang)).normalized()
		out.append([pts[i], uu, vv, rr * (1.0 + squash), rr * (1.0 - squash)])
	return out


static func _sample(st_arr: Array, t: float) -> Array:
	var ns: int = st_arr.size()
	var f: float = clampf(t, 0.0, 1.0) * float(ns - 1)
	var i: int = int(floor(f))
	if i > ns - 2:
		i = ns - 2
	if i < 0:
		i = 0
	var w: float = f - float(i)
	var ra_: Array = st_arr[i]
	var rb_: Array = st_arr[i + 1]
	var pa: Vector3 = ra_[0]
	var pb: Vector3 = rb_[0]
	var ua: Vector3 = ra_[1]
	var ub: Vector3 = rb_[1]
	var va: Vector3 = ra_[2]
	var vb2: Vector3 = rb_[2]
	var p: Vector3 = pa.lerp(pb, w)
	var u_v: Vector3 = ua.lerp(ub, w)
	if u_v.length() < 0.0001:
		u_v = ua
	u_v = u_v.normalized()
	var v_v: Vector3 = va.lerp(vb2, w)
	if v_v.length() < 0.0001:
		v_v = va
	v_v = v_v.normalized()
	var r_a: float = lerpf(float(ra_[3]), float(rb_[3]), w)
	var r_b: float = lerpf(float(ra_[4]), float(rb_[4]), w)
	return [p, u_v, v_v, r_a, r_b]


static func _spine_length(st_arr: Array) -> float:
	var total: float = 0.0
	for i in range(st_arr.size() - 1):
		var ra_: Array = st_arr[i]
		var rb_: Array = st_arr[i + 1]
		var a: Vector3 = ra_[0]
		var b: Vector3 = rb_[0]
		total += a.distance_to(b)
	return total


static func _perp(v: Vector3) -> Vector3:
	var d: Vector3 = v.normalized()
	var a: Vector3 = Vector3.UP
	if absf(d.dot(a)) > 0.9:
		a = Vector3.RIGHT
	return (a - d * a.dot(d)).normalized()


static func _basis_y_to(dir: Vector3) -> Basis:
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
# mesh helpers

static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _bulb(root: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.001)
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = maxf(ln, r * 2.02)
	cap.radial_segments = 16
	cap.rings = 6
	var mi: MeshInstance3D = _add(root, cap, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _tri_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, inside: Vector3) -> void:
	var n_front: Vector3 = (c - a).cross(b - a)
	var centroid: Vector3 = (a + b + c) / 3.0
	if n_front.dot(centroid - inside) >= 0.0:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)
	else:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)


static func _quad_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, inside: Vector3) -> void:
	_tri_out(st, a, b, c, inside)
	_tri_out(st, a, c, d, inside)


static func _tube_mesh(path: Array, radii: Array, sides: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = path.size()
	if n < 2:
		return st.commit()
	var tang: Array = []
	for i in range(n):
		var a: Vector3 = path[maxi(i - 1, 0)]
		var b: Vector3 = path[mini(i + 1, n - 1)]
		var d: Vector3 = b - a
		if d.length() < 0.000001:
			d = Vector3.UP
		tang.append(d.normalized())
	var t0: Vector3 = tang[0]
	var nrm: Vector3 = _perp(t0)
	var rings: Array = []
	for i in range(n):
		var tg: Vector3 = tang[i]
		var pn: Vector3 = nrm - tg * nrm.dot(tg)
		if pn.length() < 0.0001:
			pn = _perp(tg)
		nrm = pn.normalized()
		var bi: Vector3 = tg.cross(nrm).normalized()
		var r: float = float(radii[i])
		var centre: Vector3 = path[i]
		var ring: Array = []
		for j in range(sides):
			var ang: float = TAU * float(j) / float(sides)
			ring.append(centre + nrm * (cos(ang) * r) + bi * (sin(ang) * r))
		rings.append(ring)
	for i in range(n - 1):
		var r0: Array = rings[i]
		var r1: Array = rings[i + 1]
		var pa: Vector3 = path[i]
		var pb: Vector3 = path[i + 1]
		var inside: Vector3 = (pa + pb) * 0.5
		for j in range(sides):
			var j2: int = (j + 1) % sides
			var q0: Vector3 = r0[j]
			var q1: Vector3 = r0[j2]
			var q2: Vector3 = r1[j2]
			var q3: Vector3 = r1[j]
			_quad_out(st, q0, q1, q2, q3, inside)
	# caps so the piped ends read as cut icing, not as holes
	var first_ring: Array = rings[0]
	var cap_a: Vector3 = path[0]
	var in_a: Vector3 = path[1]
	for j in range(sides):
		var j2: int = (j + 1) % sides
		var qa: Vector3 = first_ring[j]
		var qb: Vector3 = first_ring[j2]
		_tri_out(st, cap_a, qa, qb, in_a)
	var last_ring: Array = rings[n - 1]
	var cap_b: Vector3 = path[n - 1]
	var in_b: Vector3 = path[n - 2]
	for j in range(sides):
		var j2: int = (j + 1) % sides
		var qa: Vector3 = last_ring[j]
		var qb: Vector3 = last_ring[j2]
		_tri_out(st, cap_b, qa, qb, in_b)
	st.generate_normals()
	return st.commit()


# ---------------------------------------------------------------------------
# materials and code-painted patterns

static func _c(sch: Array, i: int) -> Color:
	var code: String = sch[i]
	return Color(code)


static func _icing(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	m.clearcoat_enabled = true
	m.clearcoat = 1.0
	m.clearcoat_roughness = 0.08
	return m


static func _sheet(c: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = _icing(c, 0.12)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func _stripe_texture(rng: RandomNumberGenerator, bands: int) -> ImageTexture:
	# fine ribbed banding, near white so albedo_color tints it; seamless in v
	var img: Image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	for y in range(TEX_SIZE):
		var fy: float = float(y) / float(TEX_SIZE)
		var wv: float = fy * float(bands) * TAU
		var g: float = 0.70 + 0.30 * (0.5 + 0.5 * cos(wv))
		for x in range(TEX_SIZE):
			var jit: float = rng.randf_range(-0.018, 0.018)
			var v: float = clampf(g + jit, 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v * 0.985, v * 0.975))
	return ImageTexture.create_from_image(img)


static func _dot_texture(rng: RandomNumberGenerator, cells: int) -> ImageTexture:
	# staggered lattice of soft light dots, so a gap between bubbles still reads bubbly
	var img: Image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	var cw: float = float(TEX_SIZE) / float(cells)
	var tints: Array = []
	for i in range(cells * cells):
		tints.append(rng.randf_range(0.90, 1.0))
	for y in range(TEX_SIZE):
		for x in range(TEX_SIZE):
			var px: float = float(x) + 0.5
			var py: float = float(y) + 0.5
			var rowi: int = int(floor(py / cw))
			var off: float = 0.5 * cw if posmod(rowi, 2) == 1 else 0.0
			var coli: int = int(floor((px - off) / cw))
			var cx: float = (float(coli) + 0.5) * cw + off
			var cy: float = (float(rowi) + 0.5) * cw
			var dx: float = px - cx
			var dy: float = py - cy
			var dd: float = sqrt(dx * dx + dy * dy) / (cw * 0.5)
			var lift: float = clampf(1.0 - dd, 0.0, 1.0)
			var tint: float = float(tints[posmod(rowi, cells) * cells + posmod(coli, cells)])
			var shade: float = 0.58 + 0.42 * pow(lift, 0.6)
			var v: float = clampf(shade * tint, 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v, v * 0.99))
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------------------
# settle: measured fit, centre, floor

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


static func _settle(root: Node3D) -> void:
	var box: AABB = _union_aabb(root)
	var sx: float = maxf(box.size.x, 0.0001)
	var sy: float = maxf(box.size.y, 0.0001)
	var sz: float = maxf(box.size.z, 0.0001)
	var k_max: float = minf(1.20 / sx, minf(1.20 / sz, 1.68 / sy))
	var k_up: float = 1.08 / sy
	var kfit: float = 1.0
	if k_max < 1.0:
		kfit = k_max
	elif k_up > 1.0:
		kfit = minf(k_up, k_max)
	if absf(kfit - 1.0) > 0.0005:
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cm: MeshInstance3D = ch
			var tf: Transform3D = cm.transform
			cm.transform = Transform3D(tf.basis.scaled(Vector3(kfit, kfit, kfit)), tf.origin * kfit)
		box = _union_aabb(root)
	var shift := Vector3(
		-(box.position.x + box.size.x * 0.5),
		-box.position.y,
		-(box.position.z + box.size.z * 0.5)
	)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + shift)
