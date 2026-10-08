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
##
## AXES (see axes()):
##   piping  — what the nozzle did to the icing: "coil" the standing arch of
##             stacked turns, "melted" the whole body slumped down and spread
##             into a solid pour at its foot, "swarm" the coil dissolved into a
##             hundred loose droplets riding the same helix, "wire" the icing
##             gone and only its thread-and-hoop cage left in chalk, "burst" the
##             turns hovering apart along their own radius and down the spine.
##   budding — what grows out of it: "limbs" the balloon arms with trumpet
##             mouths, "bloom" every limb opening into a six-petal flower,
##             "twinned" a second smaller body arching backwards out of its
##             flank, "crowned" the single tip split into three heads under a
##             ring of icing spikes.

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


static func axes() -> Dictionary:
	return {
		"piping": ["coil", "melted", "swarm", "wire", "burst"],
		"budding": ["limbs", "bloom", "twinned", "crowned"],
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var piping: String = String(opts.get("piping", "coil"))
	var budding: String = String(opts.get("budding", "limbs"))
	var melted: bool = piping == "melted"
	var swarmed: bool = piping == "swarm"
	var wired: bool = piping == "wire"
	var burst: bool = piping == "burst"
	var bloom: bool = budding == "bloom"
	var twinned: bool = budding == "twinned"
	var crowned: bool = budding == "crowned"

	# per-variant budget so every combination stays inside the mesh ceiling
	var core_n: int = 22
	var lobe_core_n: int = 10
	var core_k: float = 0.90
	if wired:
		core_k = 0.24
	elif swarmed:
		core_n = 16
		lobe_core_n = 8
		core_k = 0.62
	var frill_add: int = 0
	var frill_k: float = 1.0
	if bloom:
		frill_add = 3
		frill_k = 1.45
	var frill_cap: int = 99
	if swarmed:
		frill_cap = 4

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

	if wired:
		# the sugar has gone; what is left is chalk over a wire cage
		var all_mats: Array = [
			mat_core, mat_lobe_core, mat_yellow, mat_yellow_j, mat_cyan, mat_cyan_j,
			mat_bub_a, mat_bub_b, mat_bub_c, mat_bub_core,
			mat_frill_a, mat_frill_b, mat_frill_c,
		]
		for i in range(rib_mats.size()):
			all_mats.append(rib_mats[i])
		for i in range(lobe_mats.size()):
			all_mats.append(lobe_mats[i])
		for i in range(all_mats.size()):
			_fossilise(all_mats[i])

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
	_core_chain(root, st_main, core_n, core_k, mat_core)

	var n_rib: int = rng.randi_range(24, 32)
	var t0: float = 0.02
	var t1: float = 0.985
	var pitch: float = len_main * (t1 - t0) / float(n_rib)
	var tube_r: float = pitch * rng.randf_range(0.50, 0.57)
	var overrun: float = rng.randf_range(0.40, 0.75)
	var phase0: float = rng.randf_range(0.0, TAU)
	var pat: Array = PATTERNS[rng.randi_range(0, PATTERNS.size() - 1)]
	var pat_off: int = rng.randi_range(0, 7)
	var turns: int = n_rib
	if wired:
		turns = n_rib + 6
		tube_r *= 0.26
	elif melted:
		tube_r *= 1.14
	elif swarmed:
		turns = 16
	if twinned:
		turns = maxi(int(round(float(turns) * 0.80)), 8)
	_coil_body(root, st_main, turns, t0, t1, 34, tube_r, overrun, phase0, bulge, bulge_phase, rib_mats, pat, pat_off, piping, 6, rng)

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
	_core_chain(root, st_lobe, lobe_core_n, core_k, mat_lobe_core)

	var n_rib2: int = rng.randi_range(9, 13)
	var pitch2: float = len_lobe * 0.94 / float(n_rib2)
	var tube_r2: float = pitch2 * rng.randf_range(0.50, 0.57)
	var phase2: float = rng.randf_range(0.0, TAU)
	var pat2: Array = PATTERNS[rng.randi_range(0, PATTERNS.size() - 1)]
	var turns2: int = n_rib2
	if wired:
		turns2 = n_rib2 + 4
		tube_r2 *= 0.26
	elif melted:
		tube_r2 *= 1.14
	elif swarmed:
		turns2 = 6
	_coil_body(root, st_lobe, turns2, 0.03, 0.97, 28, tube_r2, overrun, phase2, bulge * 0.7, bulge_phase, lobe_mats, pat2, 0, piping, 3, rng)

	# --- balloon limbs -------------------------------------------------------
	var n_limb: int = rng.randi_range(3, 4)
	if swarmed:
		n_limb = 2
	var tip_mode: String = "mouth"
	if bloom:
		tip_mode = "bloom"
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
			_balloon(root, org, d0, bax, segs, rng.randf_range(0.037, 0.047), bend, mat_cyan, mat_cyan_j, rng, wired, tip_mode, mat_frill_b)
		else:
			_balloon(root, org, d0, bax, segs, rng.randf_range(0.050, 0.063), bend, mat_yellow, mat_yellow_j, rng, wired, tip_mode, mat_frill_a)

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
	if swarmed:
		b_steps = 6
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
	if swarmed:
		per_ring = 3
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
			var pickm: StandardMaterial3D = mat_bub_a
			var roll2: float = rng.randf()
			if roll2 > 0.94:
				pickm = mat_bub_c
			elif roll2 > 0.5:
				pickm = mat_bub_b
			var seat: Vector3 = bpath[i]
			var sit: Vector3 = seat + rd * (cr2 * 0.72 + br * 0.42) + wob
			var bm: MeshInstance3D
			if wired:
				# every grape has lost its flesh: a bare hoop where the bubble was
				var ring := TorusMesh.new()
				ring.inner_radius = br * 0.70
				ring.outer_radius = br * 1.00
				ring.rings = 6
				ring.ring_segments = 12
				bm = _add(root, ring, pickm)
				bm.transform = Transform3D(_basis_y_to(rd), sit)
			else:
				var sph := SphereMesh.new()
				sph.radius = br
				sph.height = br * 2.0
				sph.radial_segments = 14
				sph.rings = 8
				bm = _add(root, sph, pickm)
				bm.transform = Transform3D(Basis(), sit)

	# --- frills where the ribbons stop --------------------------------------
	var f_foot: Array = _sample(st_main, 0.015)
	var f_foot2: Array = _sample(st_main, 0.06)
	var foot_p: Vector3 = f_foot[0]
	var foot_p2: Vector3 = f_foot2[0]
	var foot_r: float = float(f_foot[3])
	var foot_dir: Vector3 = (foot_p2 - foot_p).normalized()
	_frill(root, foot_p - foot_dir * (foot_r * 0.20), -foot_dir, mini(rng.randi_range(5, 7) + frill_add, frill_cap), 0.115 * frill_k, 0.085 * frill_k, mat_frill_a, rng)

	var f_tip: Array = _sample(st_main, 0.99)
	var f_tip2: Array = _sample(st_main, 0.93)
	var tip_p: Vector3 = f_tip[0]
	var tip_p2: Vector3 = f_tip2[0]
	var tip_dir: Vector3 = (tip_p - tip_p2).normalized()
	if not crowned:
		_frill(root, tip_p + tip_dir * 0.015, tip_dir, mini(rng.randi_range(4, 6) + frill_add, frill_cap), 0.100 * frill_k, 0.072 * frill_k, mat_frill_b, rng)

	var f_lob: Array = _sample(st_lobe, 0.985)
	var f_lob2: Array = _sample(st_lobe, 0.90)
	var lt_p: Vector3 = f_lob[0]
	var lt_p2: Vector3 = f_lob2[0]
	var lt_dir: Vector3 = (lt_p - lt_p2).normalized()
	_frill(root, lt_p + lt_dir * 0.012, lt_dir, mini(rng.randi_range(4, 6) + frill_add, frill_cap), 0.082 * frill_k, 0.060 * frill_k, mat_frill_c, rng)

	# --- twinned: a second, smaller body arching backwards out of the flank ---
	if twinned:
		var tw_t: float = rng.randf_range(0.28, 0.42)
		var tws: Array = _sample(st_main, tw_t)
		var twp: Vector3 = tws[0]
		var twu: Vector3 = tws[1]
		var twv: Vector3 = tws[2]
		var twr: float = float(tws[3])
		var tw_ang: float = rng.randf_range(0.0, TAU)
		var tw_rad: Vector3 = (twu * cos(tw_ang) + twv * sin(tw_ang)).normalized()
		var tw_base: Vector3 = twp + tw_rad * (twr * 0.85)
		var tw_k: float = 0.58
		var c_root: Vector3 = ctrl[0]
		var twctrl: Array = []
		for i in range(ctrl.size()):
			var cc: Vector3 = ctrl[i]
			var dv: Vector3 = cc - c_root
			twctrl.append(tw_base + Vector3(-dv.x, dv.y, -dv.z) * tw_k + tw_rad * (float(i) * 0.012))
		var twkeys: Array = []
		for i in range(r_keys.size()):
			twkeys.append(float(r_keys[i]) * tw_k)
		var st_tw: Array = _stations(twctrl, 150, twkeys, squash, -twist)
		var len_tw: float = _spine_length(st_tw)
		_core_chain(root, st_tw, 8, core_k, mat_core)
		var tw_turns: int = 14
		if wired:
			tw_turns = 18
		elif swarmed:
			tw_turns = 5
		var tw_pitch: float = len_tw * 0.955 / float(tw_turns)
		var tw_tube: float = tw_pitch * 0.54
		if wired:
			tw_tube *= 0.26
		elif melted:
			tw_tube *= 1.14
		_coil_body(root, st_tw, tw_turns, 0.02, 0.985, 30, tw_tube, overrun, rng.randf_range(0.0, TAU), bulge, bulge_phase, lobe_mats, pat, pat_off + 2, piping, 3, rng)
		var tw_e: Array = _sample(st_tw, 0.99)
		var tw_e2: Array = _sample(st_tw, 0.92)
		var twe_p: Vector3 = tw_e[0]
		var twe_p2: Vector3 = tw_e2[0]
		var twe_d: Vector3 = (twe_p - twe_p2).normalized()
		_frill(root, twe_p + twe_d * 0.010, twe_d, mini(4, frill_cap), 0.070 * frill_k, 0.052 * frill_k, mat_frill_a, rng)

	# --- crowned: the one tip splits into three heads under a ring of spikes --
	if crowned:
		var hs: Array = _sample(st_main, 0.84)
		var hp: Vector3 = hs[0]
		var hu: Vector3 = hs[1]
		var hv: Vector3 = hs[2]
		var hr: float = float(hs[3])
		var htg: Vector3 = hu.cross(hv).normalized()
		var head_turns: int = 5
		if swarmed:
			head_turns = 4
		var h_off: float = rng.randf_range(0.0, TAU)
		for hi in range(3):
			var ha: float = h_off + TAU * float(hi) / 3.0
			var h_rad: Vector3 = (hu * cos(ha) + hv * sin(ha)).normalized()
			var hd: Vector3 = (h_rad * 0.62 + htg * 0.55 + Vector3(0.0, 0.75, 0.0)).normalized()
			var hup: Vector3 = Vector3.UP - hd * Vector3.UP.dot(hd)
			if hup.length() < 0.001:
				hup = _perp(hd)
			hup = hup.normalized()
			var hk: float = rng.randf_range(0.86, 1.14)
			var hctrl: Array = [
				hp + h_rad * (hr * 0.55),
				hp + h_rad * (hr * 0.75) + hd * (0.10 * hk),
				hp + h_rad * (hr * 0.85) + hd * (0.19 * hk) + hup * (0.045 * hk),
				hp + h_rad * (hr * 0.90) + hd * (0.25 * hk) + hup * (0.115 * hk),
			]
			var hkeys: Array = [
				0.072 * body_k * hk, 0.064 * body_k * hk, 0.046 * body_k * hk, 0.024 * body_k * hk,
			]
			var st_head: Array = _stations(hctrl, 70, hkeys, squash * 0.6, twist * 0.5)
			var hlen: float = _spine_length(st_head)
			var hpitch: float = hlen * 0.94 / float(head_turns)
			var htube: float = hpitch * 0.54
			if wired:
				htube *= 0.30
			elif melted:
				htube *= 1.14
			_coil_body(root, st_head, head_turns, 0.03, 0.97, 22, htube, overrun, rng.randf_range(0.0, TAU), bulge * 0.6, bulge_phase, rib_mats, pat, hi, piping, 2, rng)
		var top_s: Array = _sample(st_main, 0.965)
		var tp: Vector3 = top_s[0]
		var tu: Vector3 = top_s[1]
		var tv: Vector3 = top_s[2]
		var tr: float = float(top_s[3])
		for ci in range(8):
			var ca2: float = h_off + TAU * float(ci) / 8.0
			var cd: Vector3 = (tu * cos(ca2) + tv * sin(ca2)).normalized()
			var spike := CylinderMesh.new()
			spike.top_radius = 0.0035
			spike.bottom_radius = 0.020 * body_k
			spike.height = 0.085 * body_k * rng.randf_range(0.78, 1.30)
			spike.radial_segments = 12
			var sd2: Vector3 = (cd * 0.62 + Vector3(0.0, 0.80, 0.0)).normalized()
			var sm: MeshInstance3D = _add(root, spike, mat_yellow)
			sm.transform = Transform3D(_basis_y_to(sd2), tp + cd * (tr * 1.05) + sd2 * (spike.height * 0.5))

	# --- what happened to the icing after it was piped -----------------------
	if melted:
		_melt_pass(root)
		_puddle(root, _icing(c_pink2, 0.07), _icing(c_white, 0.08), rng)
	elif burst:
		_burst_pass(root, st_main, 0.10, 0.30)

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


static func _coil_body(root: Node3D, st_arr: Array, turns: int, t0: float, t1: float, steps: int, tube_r: float, overrun: float, phase0: float, bulge: float, bulge_phase: float, mats: Array, pat: Array, pat_off: int, mode: String, extra_n: int, rng: RandomNumberGenerator) -> void:
	# The nozzle runs the length of the spine, laying `turns` full sweeps of the
	# cross-section and advancing exactly one pitch per sweep. WHAT each sweep is
	# made of is the piping axis: a solid rope of icing, a line of loose droplets
	# riding the same helix, or nothing but the hoop the rope used to follow.
	var n: int = maxi(turns, 1)
	var dt: float = (t1 - t0) / float(n)
	var np: int = maxi(pat.size(), 1)
	var nm: int = maxi(mats.size(), 1)
	for i in range(n):
		var a0: float = t0 + dt * float(i)
		var a1: float = a0 + dt
		var ph: float = phase0 + float(i) * 0.21 + rng.randf_range(-0.05, 0.05)
		var mat: StandardMaterial3D = mats[posmod(int(pat[posmod(i + pat_off, np)]), nm)]
		if mode == "swarm":
			_coil_drops(root, st_arr, a0, a1, ph, tube_r, overrun, bulge, bulge_phase, maxi(extra_n, 2), mat, rng)
		else:
			var mesh: ArrayMesh = _ribbon(st_arr, a0, a1, ph, steps, tube_r, overrun, bulge, bulge_phase)
			var mi: MeshInstance3D = _add(root, mesh, mat)
			mi.transform = Transform3D()
	if mode == "wire":
		# the hoops are there but nothing ties them; run the threads
		_cage_rods(root, st_arr, t0, t1, extra_n, tube_r, phase0, bulge, bulge_phase, mats, rng)


static func _coil_drops(root: Node3D, st_arr: Array, a0: float, a1: float, phase: float, tube_r: float, overrun: float, bulge: float, bulge_phase: float, count: int, mat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	# one turn of the coil, broken: the rope is gone and what is left is the
	# droplets it was made of, still on its helix but hovering off the surface
	var sweep: float = TAU + overrun
	var n: int = maxi(count, 1)
	for k in range(n):
		var f: float = (float(k) + rng.randf_range(0.15, 0.85)) / float(n)
		var th: float = phase + f * sweep
		var tt: float = a0 + (a1 - a0) * (f * sweep / TAU)
		var s: Array = _sample(st_arr, tt)
		var p: Vector3 = s[0]
		var u_v: Vector3 = s[1]
		var v_v: Vector3 = s[2]
		var tg: Vector3 = u_v.cross(v_v).normalized()
		var swell: float = 1.0 + bulge * cos(th - bulge_phase)
		var ra: float = float(s[3]) * swell
		var rb: float = float(s[4]) * swell
		var seat: Vector3 = p + u_v * (cos(th) * ra) + v_v * (sin(th) * rb)
		var outw: Vector3 = (u_v * cos(th) + v_v * sin(th)).normalized()
		var fly: float = tube_r * rng.randf_range(0.15, 2.70)
		var drift: Vector3 = tg * (tube_r * rng.randf_range(-1.35, 1.35)) + u_v * (tube_r * rng.randf_range(-0.65, 0.65)) + v_v * (tube_r * rng.randf_range(-0.65, 0.65))
		var dr: float = tube_r * rng.randf_range(0.40, 1.05)
		var drop := SphereMesh.new()
		drop.radius = dr
		drop.height = dr * 2.0
		drop.radial_segments = 12
		drop.rings = 7
		var rot: Basis = _basis_y_to(outw)
		var pinch: float = rng.randf_range(0.78, 0.96)
		var stretch: float = rng.randf_range(1.05, 1.42)
		var mi: MeshInstance3D = _add(root, drop, mat)
		mi.transform = Transform3D(Basis(rot.x * pinch, rot.y * stretch, rot.z * pinch), seat + outw * fly + drift)


static func _cage_rods(root: Node3D, st_arr: Array, t0: float, t1: float, extra_n: int, tube_r: float, phase0: float, bulge: float, bulge_phase: float, mats: Array, rng: RandomNumberGenerator) -> void:
	# the longitudinal threads of the cage: each runs the whole spine at a fixed
	# angle in the twisting frame, so it spirals gently and ties the hoops
	var rods: int = clampi(extra_n - 2, 2, 5)
	var nm: int = maxi(mats.size(), 1)
	var steps: int = 30
	for k in range(rods):
		var ang: float = phase0 + TAU * float(k) / float(rods) + rng.randf_range(-0.10, 0.10)
		var path: Array = []
		var radii: Array = []
		for j in range(steps + 1):
			var f: float = float(j) / float(steps)
			var tt: float = lerpf(t0, t1, f)
			var s: Array = _sample(st_arr, tt)
			var p: Vector3 = s[0]
			var u_v: Vector3 = s[1]
			var v_v: Vector3 = s[2]
			var swell: float = 1.0 + bulge * cos(ang - bulge_phase)
			var ra: float = float(s[3]) * swell
			var rb: float = float(s[4]) * swell
			path.append(p + u_v * (cos(ang) * ra) + v_v * (sin(ang) * rb))
			var taper: float = 1.0
			if f < 0.05:
				taper = 0.45 + 0.55 * (f / 0.05)
			elif f > 0.95:
				taper = 0.45 + 0.55 * ((1.0 - f) / 0.05)
			radii.append(tube_r * 1.15 * taper)
		var mesh: ArrayMesh = _tube_mesh(path, radii, 5)
		var mi: MeshInstance3D = _add(root, mesh, mats[posmod(k, nm)])
		mi.transform = Transform3D()


static func _balloon(root: Node3D, org: Vector3, dir0: Vector3, axis: Vector3, n_seg: int, r0: float, bend: float, mat_a: StandardMaterial3D, mat_b: StandardMaterial3D, rng: RandomNumberGenerator, wired: bool, tip_mode: String, mat_tip: StandardMaterial3D) -> void:
	var p: Vector3 = org
	var d: Vector3 = dir0.normalized()
	var r: float = r0
	for i in range(n_seg):
		var f: float = float(i) / float(maxi(n_seg - 1, 1))
		r = r0 * lerpf(1.0, 0.55, f) * rng.randf_range(0.94, 1.06)
		var ln: float = r * rng.randf_range(2.2, 2.9)
		var q: Vector3 = p + d * ln
		var rn: float = r * 0.50
		if wired:
			# the balloon has lost its skin: a rod down its length, a hoop at its girth
			_bulb(root, p, q, maxf(r * 0.15, 0.0035), mat_a)
			var hoop := TorusMesh.new()
			hoop.inner_radius = r * 0.86
			hoop.outer_radius = r * 1.04
			hoop.rings = 8
			hoop.ring_segments = 16
			var hm: MeshInstance3D = _add(root, hoop, mat_b)
			hm.transform = Transform3D(_basis_y_to(d), (p + q) * 0.5)
		else:
			_bulb(root, p, q, r, mat_a)
			var kn := SphereMesh.new()
			kn.radius = rn
			kn.height = rn * 2.0
			kn.radial_segments = 14
			kn.rings = 8
			var km: MeshInstance3D = _add(root, kn, mat_b)
			km.transform = Transform3D(Basis(), q + d * (rn * 0.35))
		p = q + d * (rn * 0.70)
		d = d.rotated(axis, bend + rng.randf_range(-0.09, 0.09)).normalized()
	if tip_mode == "bloom":
		_flower(root, p + d * (r * 0.55), d, r * 0.92, mat_tip, mat_b, rng)
	elif wired:
		var mouth_rw: float = r * 1.55
		var throat := TorusMesh.new()
		throat.inner_radius = r * 0.58
		throat.outer_radius = r * 0.76
		throat.rings = 8
		throat.ring_segments = 16
		var tm: MeshInstance3D = _add(root, throat, mat_a)
		tm.transform = Transform3D(_basis_y_to(d), p + d * (r * 0.32))
		var rim := TorusMesh.new()
		rim.inner_radius = mouth_rw * 0.84
		rim.outer_radius = mouth_rw * 1.00
		rim.rings = 8
		rim.ring_segments = 18
		var rm: MeshInstance3D = _add(root, rim, mat_b)
		rm.transform = Transform3D(_basis_y_to(d), p + d * (r * 1.74))
	else:
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


static func _flower(root: Node3D, org: Vector3, dir_v: Vector3, r: float, mat_petal: StandardMaterial3D, mat_bud: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	# the trumpet mouth has opened: six petals curling back off a squashed bud
	var a: Vector3 = dir_v.normalized()
	var e1: Vector3 = _perp(a)
	var e2: Vector3 = a.cross(e1).normalized()
	var off: float = rng.randf_range(0.0, TAU)
	for k in range(6):
		var ang: float = off + TAU * float(k) / 6.0 + rng.randf_range(-0.11, 0.11)
		var radial: Vector3 = (e1 * cos(ang) + e2 * sin(ang)).normalized()
		var tilt: float = rng.randf_range(0.52, 1.02)
		var fwd: Vector3 = (radial * cos(tilt) + a * sin(tilt)).normalized()
		var sd: Vector3 = a.cross(radial).normalized()
		var up_v: Vector3 = sd.cross(fwd).normalized()
		var ln: float = r * rng.randf_range(2.4, 3.4)
		var wd: float = r * rng.randf_range(1.5, 2.2)
		var curl: float = rng.randf_range(-2.30, -1.15)
		var mesh: ArrayMesh = _ruffle(org + radial * (r * 0.50) + a * (r * 0.10), fwd, up_v, sd, ln, wd, curl, 2.0, wd * 0.15)
		var mi: MeshInstance3D = _add(root, mesh, mat_petal)
		mi.transform = Transform3D()
	var bud := SphereMesh.new()
	bud.radius = r * 0.95
	bud.height = r * 1.50
	bud.radial_segments = 16
	bud.rings = 9
	var bm2: MeshInstance3D = _add(root, bud, mat_bud)
	bm2.transform = Transform3D(_basis_y_to(a), org + a * (r * 0.28))


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


static func _fossilise(m: StandardMaterial3D) -> void:
	# sugar to chalk: the confectionery gloss is the whole reading of this body,
	# so the wire cage has to lose it — no clearcoat, no painted stripe, and the
	# candy hue bleached to a bone that keeps only a memory of which part it was
	var c: Color = m.albedo_color
	var lum: float = clampf(c.r * 0.30 + c.g * 0.59 + c.b * 0.11, 0.0, 1.0)
	var chalk := Color(
		clampf(0.62 + lum * 0.32, 0.0, 1.0),
		clampf(0.60 + lum * 0.32, 0.0, 1.0),
		clampf(0.55 + lum * 0.30, 0.0, 1.0),
		1.0
	)
	m.albedo_color = chalk.lerp(c, 0.12)
	m.albedo_texture = null
	m.uv1_triplanar = false
	m.metallic = 0.0
	m.roughness = 0.88
	m.clearcoat_enabled = false
	m.clearcoat = 0.0


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
# what happened to the icing after it was piped
#
# These run over the finished body, so they reach every part of it — coil, lobe,
# limbs, bubbles, frills, and whatever budding added. Half the meshes here are
# ArrayMeshes whose vertices are already in world space under an identity
# transform, so a pass cannot just move an origin: it takes each mesh's own
# world AABB centre as its handle and composes the deformation onto whatever
# transform the mesh already has.

static func _mesh_centre(cm: MeshInstance3D) -> Vector3:
	var wb: AABB = cm.transform * cm.mesh.get_aabb()
	return wb.position + wb.size * 0.5


static func _melt_pass(root: Node3D) -> void:
	# the whole body slumps: the higher a part stood the further it falls, and
	# what falls spreads sideways as it goes, so the arch closes down onto its own
	# haunch and every rope of icing flattens from round to oval on the way
	var box: AABB = _union_aabb(root)
	var y0: float = box.position.y
	var span: float = maxf(box.size.y, 0.0001)
	var cx: float = box.position.x + box.size.x * 0.5
	var cz: float = box.position.z + box.size.z * 0.5
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		if cm.mesh == null:
			continue
		var ctr: Vector3 = _mesh_centre(cm)
		var h: float = clampf((ctr.y - y0) / span, 0.0, 1.0)
		var sunk: float = pow(h, 1.45) * 0.52
		var spread: float = 1.0 + (h - sunk) * 0.45
		var flat: float = lerpf(0.88, 0.32, h)
		var wide: float = lerpf(1.10, 1.38, h)
		var nx: float = cx + (ctr.x - cx) * spread
		var nz: float = cz + (ctr.z - cz) * spread
		var ny: float = y0 + span * sunk
		var target: Vector3 = Vector3(nx, ny, nz)
		var sq: Basis = Basis().scaled(Vector3(wide, flat, wide))
		var warp: Transform3D = Transform3D(sq, target - sq * ctr)
		cm.transform = warp * cm.transform


static func _puddle(root: Node3D, mat_a: StandardMaterial3D, mat_b: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	# and what ran off it set on the floor: one broad pool with lobes where the
	# pour reached furthest, and a rising skirt that drowns the slumped foot, so
	# the body has no ankle left — it just becomes the floor
	var box: AABB = _union_aabb(root)
	var cx: float = box.position.x + box.size.x * 0.5
	var cz: float = box.position.z + box.size.z * 0.5
	var y0: float = box.position.y
	var hgt: float = maxf(box.size.y, 0.02)
	var rad: float = maxf(maxf(box.size.x, box.size.z) * 0.5, 0.05)
	var pool_h: float = maxf(hgt * 0.085, 0.016)

	var pool := SphereMesh.new()
	pool.radius = 1.0
	pool.height = 2.0
	pool.radial_segments = 26
	pool.rings = 10
	var pm: MeshInstance3D = _add(root, pool, mat_a)
	pm.transform = Transform3D(Basis().scaled(Vector3(rad * 1.05, pool_h, rad * 1.05)), Vector3(cx, y0 + pool_h * 0.55, cz))

	var lobes: int = rng.randi_range(6, 8)
	var off: float = rng.randf_range(0.0, TAU)
	for i in range(lobes):
		var a: float = off + TAU * float(i) / float(lobes) + rng.randf_range(-0.26, 0.26)
		var dd: float = rad * rng.randf_range(0.35, 0.78)
		var rr: float = rad * rng.randf_range(0.20, 0.36)
		var th: float = pool_h * rng.randf_range(0.50, 1.00)
		var blob := SphereMesh.new()
		blob.radius = 1.0
		blob.height = 2.0
		blob.radial_segments = 20
		blob.rings = 8
		var mm: StandardMaterial3D = mat_a if posmod(i, 2) == 0 else mat_b
		var mi: MeshInstance3D = _add(root, blob, mm)
		mi.transform = Transform3D(Basis().scaled(Vector3(rr, th, rr)), Vector3(cx + cos(a) * dd, y0 + th * 0.52, cz + sin(a) * dd))

	var climbs: int = rng.randi_range(4, 5)
	for i in range(climbs):
		var f: float = (float(i) + 0.5) / float(climbs)
		var a2: float = off * 1.7 + TAU * float(i) * 0.618 + rng.randf_range(-0.20, 0.20)
		var yy: float = y0 + hgt * lerpf(0.05, 0.36, f)
		var dd2: float = rad * lerpf(0.72, 0.28, f) * rng.randf_range(0.86, 1.10)
		var rr2: float = rad * lerpf(0.46, 0.24, f)
		var th2: float = pool_h * rng.randf_range(1.15, 1.95)
		var skirt := SphereMesh.new()
		skirt.radius = 1.0
		skirt.height = 2.0
		skirt.radial_segments = 18
		skirt.rings = 8
		var mm2: StandardMaterial3D = mat_b if posmod(i, 2) == 0 else mat_a
		var mi2: MeshInstance3D = _add(root, skirt, mm2)
		mi2.transform = Transform3D(Basis().scaled(Vector3(rr2, th2, rr2)), Vector3(cx + cos(a2) * dd2, yy, cz + sin(a2) * dd2))


static func _burst_pass(root: Node3D, st_arr: Array, out_amt: float, along_amt: float) -> void:
	# the coil comes apart without losing its order: every part backs off along
	# the radius it was piped on and slides along the spine, so the stack opens
	# into an exploded view of itself and the gesture is still legible through it
	var ns: int = st_arr.size()
	if ns < 2:
		return
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		if cm.mesh == null:
			continue
		var ctr: Vector3 = _mesh_centre(cm)
		var best: int = 0
		var best_d: float = 1.0e20
		for i in range(ns):
			var row: Array = st_arr[i]
			var pp: Vector3 = row[0]
			var dd: float = ctr.distance_squared_to(pp)
			if dd < best_d:
				best_d = dd
				best = i
		var st_row: Array = st_arr[best]
		var sp: Vector3 = st_row[0]
		var su: Vector3 = st_row[1]
		var sv: Vector3 = st_row[2]
		var tg: Vector3 = su.cross(sv).normalized()
		var t: float = float(best) / float(maxi(ns - 1, 1))
		var rvec: Vector3 = ctr - sp
		var flat_r: Vector3 = rvec - tg * rvec.dot(tg)
		var rdir: Vector3 = su
		if flat_r.length() > 0.0005:
			rdir = flat_r.normalized()
		var push: Vector3 = rdir * (out_amt * (0.45 + 0.85 * t)) + tg * (along_amt * (t - 0.42))
		cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + push)


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
