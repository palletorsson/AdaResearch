extends RefCounted

## dream_bodies / botanic_mannequin — one headless shop mannequin in a printed
## second-skin bodysuit, hand on hip, standing on a chrome pole in a dark garden.
##
## Reference: described, not seen — a rank of headless fashion mannequins in a
## dark garden, each in a printed second-skin bodysuit covering torso, arms and a
## hood over where the head would be, the neck ending in a flat oval cap. The
## prints: big green monstera leaves on white, purple-and-white leaf shadows, fine
## coral-and-cream vertical stripes, a black-and-white speckle, and one plain
## saffron with small green leaves. Classic mannequin poses — one hand on the hip
## with the elbow out, the other arm hanging, weight on one leg, the torso twisted.
## The suits crease at the elbow and gather at the waist.
##
## Reproduced, and how:
##   1. The torso as ONE lofted shell — 26..34 SurfaceTool rings through a keyed
##      profile (flared cut-off lip at mid-thigh, hips, cinched waist, bust,
##      shoulders, yoke, neck base), the section an oval made 12% deeper at the
##      front than the back, capped flat at the thigh cut where a mannequin ends.
##   2. Contrapposto and twist reach the geometry, not just the colours. Every
##      ring carries a lateral offset (hip pushed out over the weight leg, the
##      shoulders carried back the other way — a cosine plus a second harmonic, so
##      it reads as an S and not a lean), a chest-forward arch, and a yaw growing
##      as the square of height so the shoulders turn on the hips. The oval
##      section is what makes that twist visible at all.
##   3. Hand on the hip, elbow out. Shoulder, elbow and wrist are placed so the
##      elbow swings wide and BACK and the forearm returns inward to the hip bone
##      — the negative triangle between arm and flank is the whole pose. The other
##      arm hangs with a slight bend. Which side is which, and every joint offset,
##      come from the seed; both arms are built to the same bone lengths.
##   4. Five prints painted in code, one dealt per seed: (a) big monstera leaves —
##      a lobed blade from an implicit half-width, radial notches cut in from the
##      edge by a slant-sheared slit field, elliptical fenestrations near the
##      midrib, midrib and lateral veins darker; (b) the same blade stamped large
##      and overlapping in lilac at 55% blend so crossings deepen — the
##      purple-and-white leaf shadows; (c) fine coral-and-cream stripes varying
##      only across the horizontal, so triplanar runs them vertically on the body;
##      (d) black-and-white speckle, each blot 2..4 wobbled discs; (e) saffron
##      with small green leaves.
##   5. One printed skin. Torso shell, arms, hands, neck and hood share a
##      world-triplanar material, so the print crosses ~70 primitives unbroken —
##      the break is where a seam would be, not where a mesh ends.
##   6. Fabric creases and gathers. 4..8 thin curved welts (swept six-sided
##      ArrayMesh tubes tapering at both ends) at the elbows, the front waist, the
##      under-bust and over the hip, plus oval gather bands at waist and hips and
##      long seam welts down the outside of each arm and each flank.
##   7. No head. A short printed neck stem tilts off the yoke and ends in a flat
##      oval cap — a squashed cylinder scaled to an oval, with a chrome edge ring
##      — and the hood gathers as a squashed dome beneath it. Nothing above.
##   8. The pole, the base and the garden. Three chrome cylinder segments with two
##      collars, a dark disc with a chrome rim, and 4..7 dark lobed leaves on bent
##      stems rising round the foot with a few pebbles — the garden the rank
##      stands in, kept to a clutch at the ankle.
##
## Given up: the rank (there is one mannequin, not five), the garden as a place
## rather than that clutch, cloth simulation (the creases are placed, not
## settled), legs and the weight-bearing foot (the mannequin is cut at mid-thigh,
## so the contrapposto lives entirely in the hip sway), and any print that spells
## or depicts something specific.
##
## Axes (dream_bodies DNA):
##   skin — what the second skin HAS BECOME: printed (the suit as described),
##     sprouting (the print stops being a picture — leaves erupt out of the torso
##     and droop in a crown off the flat cap), unravelled (the shell shrinks to a
##     core inside a loose cage of thread spiralling off it and pooling at the
##     base), cage (fossilised — the suit and the flesh gone, hoops and ribs where
##     the body was and bones where the arms were), poured (the lower body
##     swallowed to the hip bone in a solid dark pour that runs down to the disc).
##   rank — how many mannequins are inside this one: one, twinned (a second
##     smaller body budding backward out of the upper back with its own neck, cap
##     and two hanging arms), multiplied (three necks carrying three flat caps and
##     four arms), swarm (the body shedding a rising helix of thirty small copies
##     of itself, each a whole mannequin the size of a hand).

const TEX: int = 256

# torso profile keys: [dy above the hem, half-width x, half-depth z]
const PROFILE: Array = [
	[0.000, 0.172, 0.136],
	[0.032, 0.159, 0.126],
	[0.095, 0.169, 0.133],
	[0.170, 0.187, 0.146],
	[0.255, 0.166, 0.128],
	[0.345, 0.130, 0.105],
	[0.415, 0.137, 0.112],
	[0.505, 0.158, 0.130],
	[0.580, 0.154, 0.119],
	[0.648, 0.173, 0.113],
	[0.694, 0.152, 0.101],
	[0.722, 0.108, 0.084],
	[0.744, 0.064, 0.058],
]

const PROFILE_TOP: float = 0.744
const HEM_Y: float = 0.682


static func describe() -> String:
	return "A headless shop mannequin in a printed second-skin bodysuit, one hand on the hip with the elbow out and the torso twisted, standing on a chrome pole among dark garden leaves."


static func axes() -> Dictionary:
	return {
		"skin": ["printed", "sprouting", "unravelled", "cage", "poured"],
		"rank": ["one", "twinned", "multiplied", "swarm"],
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var skin: String = str(opts.get("skin", "printed"))
	var rank: String = str(opts.get("rank", "one"))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- the print -----------------------------------------------------------
	var print_kind: int = rng.randi_range(0, 4)
	var suit_tex: ImageTexture = null
	var uv_k: float = 1.3
	var trim_col: Color = Color("#C9CDD2")
	if print_kind == 0:
		suit_tex = _tex_monstera(rng)
		uv_k = 1.02
		trim_col = Color("#CBD2C9")
	elif print_kind == 1:
		suit_tex = _tex_shadow_leaves(rng)
		uv_k = 0.94
		trim_col = Color("#CCC6D6")
	elif print_kind == 2:
		suit_tex = _tex_stripes(rng)
		uv_k = 2.20
		trim_col = Color("#D8CFC6")
	elif print_kind == 3:
		suit_tex = _tex_speckle(rng)
		uv_k = 1.55
		trim_col = Color("#CBCBCE")
	else:
		suit_tex = _tex_saffron(rng)
		uv_k = 1.35
		trim_col = Color("#D3CBB4")

	var mat_suit: StandardMaterial3D = _print_mat(suit_tex, Color(1.0, 1.0, 1.0), uv_k, 0.60)
	var mat_fold: StandardMaterial3D = _print_mat(suit_tex, Color(0.82, 0.83, 0.88), uv_k, 0.68)
	var mat_hood: StandardMaterial3D = _print_mat(suit_tex, Color(0.97, 0.97, 1.0), uv_k, 0.56)
	var mat_chrome: StandardMaterial3D = _metal_mat(Color("#C6CAD0"), 0.15)
	var mat_trim: StandardMaterial3D = _metal_mat(trim_col, 0.26)
	var mat_base: StandardMaterial3D = _flat_mat(Color("#2A2C2A"), 0.62)
	var mat_leaf: StandardMaterial3D = _flat_mat(Color("#20401F"), 0.78)
	mat_leaf.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mat_leaf_b: StandardMaterial3D = _flat_mat(Color("#17331C"), 0.80)
	mat_leaf_b.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mat_stem: StandardMaterial3D = _flat_mat(Color("#1B2E1A"), 0.72)
	var mat_stone: StandardMaterial3D = _flat_mat(Color("#33352F"), 0.86)
	var mat_pour: StandardMaterial3D = _flat_mat(Color("#141A17"), 0.16)
	mat_pour.metallic = 0.34
	mat_pour.metallic_specular = 0.74

	# When the flesh is gone the suit's mass goes with it: the bust, the shoulders
	# and the yoke shrink to knuckles on the cage, and the arms read as bones.
	var flesh_k: float = 0.52 if skin == "cage" else 1.0
	var limb_k: float = 0.58 if skin == "cage" else 1.0
	var hand_k: float = 0.80 if skin == "cage" else 1.0

	# --- this individual -----------------------------------------------------
	var body_k: float = rng.randf_range(1.00, 1.05)
	var hip_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var weight_side: float = hip_side if rng.randf() < 0.72 else -hip_side
	var twist_dir: float = 1.0 if rng.randf() < 0.5 else -1.0
	var twist: float = deg_to_rad(rng.randf_range(9.0, 21.0)) * twist_dir
	var sway: float = rng.randf_range(0.036, 0.058)
	var swing: float = rng.randf_range(0.012, 0.026)
	var arch: float = rng.randf_range(0.016, 0.032)
	var lean_z: float = rng.randf_range(-0.022, 0.014)
	var n_rings: int = rng.randi_range(26, 34)
	var seg: int = 26
	var n_crease: int = rng.randi_range(4, 8)
	var pole_r: float = rng.randf_range(0.016, 0.022)
	var base_r: float = rng.randf_range(0.175, 0.205)
	var neck_tilt_x: float = deg_to_rad(rng.randf_range(-6.0, 6.0))
	var neck_tilt_z: float = deg_to_rad(rng.randf_range(-7.0, 5.0))
	var neck_len: float = rng.randf_range(0.095, 0.118)
	var cap_r: float = rng.randf_range(0.068, 0.082)
	var cap_oval: float = rng.randf_range(0.60, 0.74)
	var n_garden: int = rng.randi_range(4, 7)

	# --- the torso rings -----------------------------------------------------
	var centres: Array = []
	var rxs: Array = []
	var rzs: Array = []
	var yaws: Array = []
	for i in range(n_rings):
		var s: float = float(i) / float(n_rings - 1)
		var key: Vector3 = _profile_at(s)
		var g: float = key.x / PROFILE_TOP
		var cx: float = weight_side * (sway * cos(PI * g) + swing * sin(TAU * g))
		var cz: float = -arch * sin(PI * g) + lean_z * g
		centres.append(Vector3(cx, (HEM_Y + key.x) * body_k, cz))
		rxs.append(key.y * body_k)
		rzs.append(key.z * body_k)
		yaws.append(twist * g * g)

	var shell_base: Vector3 = centres[0]
	if skin != "cage":
		var loft_rx: Array = rxs
		var loft_rz: Array = rzs
		if skin == "unravelled":
			# the suit has left the body: what is left is a core, and the surface
			# it used to be spirals off it as thread further down
			loft_rx = []
			loft_rz = []
			for i in range(n_rings):
				var srx: float = rxs[i]
				var srz: float = rzs[i]
				loft_rx.append(srx * 0.64)
				loft_rz.append(srz * 0.64)
		var shell: ArrayMesh = _loft(centres, loft_rx, loft_rz, yaws, seg, shell_base)
		var shell_mi: MeshInstance3D = _add(root, shell, mat_suit)
		shell_mi.transform = Transform3D(Basis(), shell_base)
	else:
		# fossilised: no suit and no flesh, only the form's cage still standing —
		# nine hoops on the profile and ten ribs run up through them
		var hoops: int = 9
		for k in range(hoops):
			var hi: int = int(round(float(k) / float(hoops - 1) * float(n_rings - 1)))
			_band_i(root, centres, rxs, rzs, yaws, clampi(hi, 0, n_rings - 1), 1.0, 0.0095, 0.0, mat_trim)
		var ribs: int = 10
		for k in range(ribs):
			var ra: float = TAU * float(k) / float(ribs)
			var rib: Array = []
			for i in range(0, n_rings, 2):
				rib.append(_pt_i(centres, rxs, rzs, yaws, i, ra, 1.0))
			_welt(root, rib, Vector3(0.0, 0.0, -1.0), 0.0072 * body_k, 0.0072 * body_k, mat_trim)

	# --- landmark rings -------------------------------------------------------
	var i_hip: int = _ring_for(centres, (HEM_Y + 0.170) * body_k)
	var i_waist: int = _ring_for(centres, (HEM_Y + 0.345) * body_k)
	var i_bust: int = _ring_for(centres, (HEM_Y + 0.505) * body_k)
	var i_sh: int = _ring_for(centres, (HEM_Y + 0.648) * body_k)
	var i_hand: int = _ring_for(centres, (HEM_Y + 0.268) * body_k)
	var p_top: Vector3 = centres[n_rings - 1]
	var c_sh: Vector3 = centres[i_sh]
	var rx_sh: float = rxs[i_sh]
	var rz_sh: float = rzs[i_sh]
	var yw_sh: float = yaws[i_sh]
	var sh_off: float = rx_sh * 0.94

	# hem lip band at the thigh cut
	_band_i(root, centres, rxs, rzs, yaws, 0, 1.010, 0.011, 0.008, mat_fold)

	# bust and shoulder mass under the suit (front of the torso is -Z)
	for sgn in [-1.0, 1.0]:
		var sf: float = sgn
		var bp: Vector3 = _pt_i(centres, rxs, rzs, yaws, i_bust, PI * 1.5 + sf * 0.55, 0.74)
		_ball(root, bp + Vector3(0.0, 0.006, -0.026 * body_k), Vector3(0.060, 0.054, 0.050) * body_k * flesh_k, Basis(Vector3.UP, yaws[i_bust]), mat_suit)
	for sgn in [-1.0, 1.0]:
		var sf: float = sgn
		_ball(root, c_sh + Vector3(sf * sh_off, 0.004, 0.0), Vector3(0.070, 0.062, 0.078) * body_k * flesh_k, Basis(Vector3.UP, yw_sh), mat_suit)
	_ball(root, c_sh + Vector3(0.0, 0.022, 0.006), Vector3(rx_sh * 0.80, 0.052, rz_sh * 0.86) * flesh_k, Basis(Vector3.UP, yw_sh), mat_suit)

	# gather bands at the waist and over the hips
	_band_i(root, centres, rxs, rzs, yaws, i_waist, 1.020, 0.0105, 0.0, mat_fold)
	_band_i(root, centres, rxs, rzs, yaws, i_waist + 1, 1.015, 0.0080, 0.0, mat_fold)
	_band_i(root, centres, rxs, rzs, yaws, maxi(i_waist - 1, 1), 1.015, 0.0080, 0.0, mat_fold)
	_band_i(root, centres, rxs, rzs, yaws, i_hip, 1.012, 0.0090, 0.0, mat_fold)
	_band_i(root, centres, rxs, rzs, yaws, i_hip + 1, 1.012, 0.0070, 0.0, mat_fold)

	# --- the pole and the base ----------------------------------------------
	var c_hem: Vector3 = centres[0]
	var mount: Vector3 = c_hem + Vector3(0.0, 0.020, 0.0)
	var pole_foot := Vector3(0.0, 0.030, 0.0)
	var seg_a: Vector3 = pole_foot.lerp(mount, 0.34)
	var seg_b: Vector3 = pole_foot.lerp(mount, 0.70)
	_tapered_cyl(root, pole_foot, seg_a, pole_r * 1.22, pole_r * 1.02, mat_chrome)
	_tapered_cyl(root, seg_a, seg_b, pole_r * 1.02, pole_r * 0.96, mat_chrome)
	_tapered_cyl(root, seg_b, mount, pole_r * 0.96, pole_r * 0.88, mat_chrome)
	_ring_band(root, seg_a, pole_r * 1.55, pole_r * 1.55, 0.0075, 0.0, mat_trim)
	_ring_band(root, seg_b, pole_r * 1.45, pole_r * 1.45, 0.0065, 0.0, mat_trim)
	_ball(root, mount, Vector3(pole_r * 2.4, pole_r * 2.0, pole_r * 2.4), Basis(), mat_chrome)

	var disc := CylinderMesh.new()
	disc.top_radius = base_r * 0.97
	disc.bottom_radius = base_r
	disc.height = 0.024
	disc.radial_segments = 40
	var disc_mi: MeshInstance3D = _add(root, disc, mat_base)
	disc_mi.transform = Transform3D(Basis(), Vector3(0.0, 0.012, 0.0))
	var bevel := CylinderMesh.new()
	bevel.top_radius = base_r * 0.60
	bevel.bottom_radius = base_r * 0.95
	bevel.height = 0.020
	bevel.radial_segments = 36
	var bev_mi: MeshInstance3D = _add(root, bevel, mat_base)
	bev_mi.transform = Transform3D(Basis(), Vector3(0.0, 0.032, 0.0))
	_ring_band(root, Vector3(0.0, 0.023, 0.0), base_r * 0.985, base_r * 0.985, 0.0070, 0.0, mat_trim)

	# --- arms: one hand on the hip, elbow out; the other hanging --------------
	# The hand is pinned to the hip ring; the elbow is then thrown out along the
	# PERPENDICULAR BISECTOR of the shoulder-wrist chord, so both bones come out at
	# exactly arm_bone however far contrapposto has carried the shoulder from the
	# hip — and the elbow swings wider the closer the hand sits to the shoulder.
	var arm_bone: float = 0.285 * body_k
	var hs: float = hip_side
	var a_sh: Vector3 = c_sh + Vector3(hs * sh_off, 0.006, 0.004)
	var wrist_ang: float = 0.0 if hs > 0.0 else PI
	var a_wr: Vector3 = _pt_i(centres, rxs, rzs, yaws, i_hand, wrist_ang, 1.0) + Vector3(hs * 0.030, 0.010, -0.038) * body_k
	var a_mid: Vector3 = (a_sh + a_wr) * 0.5
	var a_span: Vector3 = a_wr - a_sh
	var a_chord: Vector3 = a_span.normalized()
	var a_half: float = a_span.length() * 0.5
	var a_out: float = sqrt(maxf(arm_bone * arm_bone - a_half * a_half, 0.0036))
	var a_raw := Vector3(hs * (0.90 + rng.randf_range(-0.06, 0.10)), 0.10, 0.30 + rng.randf_range(-0.10, 0.12))
	var a_push: Vector3 = a_raw - a_chord * a_raw.dot(a_chord)
	if a_push.length() < 0.001:
		a_push = Vector3(hs, 0.0, 0.0)
	var a_el: Vector3 = a_mid + a_push.normalized() * a_out
	_ball(root, a_sh, Vector3(0.066, 0.062, 0.068) * body_k * limb_k, Basis(), mat_suit)
	_chain(root, a_sh, a_el, 0.058 * body_k * limb_k, 0.049 * body_k * limb_k, 5, 0.94, mat_suit)
	_ball(root, a_el, Vector3(0.053, 0.053, 0.055) * body_k * limb_k, Basis(), mat_suit)
	_chain(root, a_el, a_wr, 0.048 * body_k * limb_k, 0.036 * body_k * limb_k, 5, 0.92, mat_suit)
	_ball(root, a_wr, Vector3(0.036, 0.034, 0.036) * body_k * limb_k, Basis(), mat_suit)
	var a_dir := Vector3(-hs * 0.30, -0.88, -0.36)
	_hand(root, a_wr, a_dir.normalized(), Vector3(0.0, 0.0, -1.0), 0.34, body_k * hand_k, mat_suit)

	# The hanging arm: the same two bones, dropped almost straight. It clears the
	# hip by coming FORWARD of it rather than flaring out sideways — the hip is the
	# widest part of the torso, and a mannequin's loose hand rests just off the
	# front of the thigh, not held away from the body.
	var fs: float = -hip_side
	var b_sh: Vector3 = c_sh + Vector3(fs * sh_off, 0.006, 0.004)
	var b_d1: Vector3 = Vector3(fs * (0.20 + rng.randf_range(-0.04, 0.06)), -0.965, -0.20 + rng.randf_range(-0.05, 0.05)).normalized()
	var b_el: Vector3 = b_sh + b_d1 * arm_bone
	var b_d2: Vector3 = Vector3(fs * (0.06 + rng.randf_range(-0.03, 0.05)), -0.950, -0.41 + rng.randf_range(-0.06, 0.06)).normalized()
	var b_wr: Vector3 = b_el + b_d2 * arm_bone
	_ball(root, b_sh, Vector3(0.066, 0.062, 0.068) * body_k * limb_k, Basis(), mat_suit)
	_chain(root, b_sh, b_el, 0.058 * body_k * limb_k, 0.048 * body_k * limb_k, 5, 0.94, mat_suit)
	_ball(root, b_el, Vector3(0.052, 0.052, 0.054) * body_k * limb_k, Basis(), mat_suit)
	_chain(root, b_el, b_wr, 0.047 * body_k * limb_k, 0.035 * body_k * limb_k, 5, 0.92, mat_suit)
	_ball(root, b_wr, Vector3(0.035, 0.033, 0.035) * body_k * limb_k, Basis(), mat_suit)
	# lateral side hint, so the loose fingers fan across the hand and the palm turns
	# to the thigh (the hip hand fans front-to-back instead, over the hip bone)
	_hand(root, b_wr, b_d2, Vector3(1.0, 0.0, 0.0), 0.18, body_k * hand_k, mat_suit)

	# --- neck, hood, flat oval cap (there is no head) -------------------------
	var neck_bs: Basis = Basis(Vector3.RIGHT, neck_tilt_x) * Basis(Vector3.FORWARD, neck_tilt_z)
	var neck_up: Vector3 = (neck_bs * Vector3.UP).normalized()
	var neck_a: Vector3 = p_top + Vector3(0.0, -0.012, 0.0)
	var neck_b: Vector3 = neck_a + neck_up * (neck_len * body_k * 0.52)
	var neck_c: Vector3 = neck_a + neck_up * (neck_len * body_k)
	_tapered_cyl(root, neck_a, neck_b, 0.062 * body_k, 0.058 * body_k, mat_hood)
	_tapered_cyl(root, neck_b, neck_c, 0.058 * body_k, 0.060 * body_k, mat_hood)
	_ball(root, neck_a + neck_up * (0.016 * body_k), Vector3(0.072, 0.044, 0.066) * body_k, neck_bs, mat_hood)
	_ring_band(root, neck_a + neck_up * 0.010, 0.070 * body_k, 0.066 * body_k, 0.0095, yaws[n_rings - 1], mat_fold)

	var cap_ctr: Vector3 = neck_c + neck_up * (0.014 * body_k)
	var cap_bs: Basis = neck_bs * Basis(Vector3.UP, twist * 0.7) * Basis.from_scale(Vector3(1.0, 1.0, cap_oval))
	var cap := CylinderMesh.new()
	cap.top_radius = cap_r * body_k
	cap.bottom_radius = cap_r * body_k * 0.96
	cap.height = 0.020
	cap.radial_segments = 32
	var cap_mi: MeshInstance3D = _add(root, cap, mat_hood)
	cap_mi.transform = Transform3D(cap_bs, cap_ctr)
	var rim := TorusMesh.new()
	rim.inner_radius = cap_r * body_k - 0.006
	rim.outer_radius = cap_r * body_k + 0.004
	rim.rings = 30
	rim.ring_segments = 8
	var rim_mi: MeshInstance3D = _add(root, rim, mat_trim)
	rim_mi.transform = Transform3D(cap_bs, cap_ctr + neck_up * 0.001)
	_ball(root, cap_ctr - neck_up * (0.030 * body_k), Vector3(cap_r * 0.94, 0.030, cap_r * cap_oval * 0.96) * body_k, cap_bs, mat_hood)

	# --- creases: 4..8 welts at elbow, waist, under-bust, hip -----------------
	# front of the torso is -Z, so the front of a ring is sin(angle) < 0
	var a_flank: float = 0.0 if hs > 0.0 else PI
	var b_flank: float = 0.0 if fs > 0.0 else PI
	var a_axis: Vector3 = ((a_el - a_sh).normalized() + (a_wr - a_el).normalized()).normalized()
	var b_axis: Vector3 = ((b_el - b_sh).normalized() + (b_wr - b_el).normalized()).normalized()
	var creases: Array = []
	creases.append(_arc_pts(a_el, a_axis, Vector3(hs * 0.85, 0.0, -0.50), 0.058 * body_k, 2.2, 7))
	creases.append(_arc_i(centres, rxs, rzs, yaws, i_waist, 1.030, PI * 1.28, PI * 1.72, 8, -0.014))
	creases.append(_arc_pts(b_el, b_axis, Vector3(fs * 0.80, 0.0, -0.55), 0.056 * body_k, 2.1, 7))
	creases.append(_arc_i(centres, rxs, rzs, yaws, i_hip, 1.030, a_flank, a_flank - hs * 1.15, 7, 0.028))
	creases.append(_arc_i(centres, rxs, rzs, yaws, i_bust, 1.030, PI * 1.36, PI * 1.64, 6, -0.020))
	creases.append(_arc_i(centres, rxs, rzs, yaws, i_waist + 2, 1.030, b_flank - fs * 0.25, b_flank - fs * 1.05, 6, 0.016))
	creases.append(_arc_pts(a_sh, (a_el - a_sh).normalized(), Vector3(hs * 0.40, 0.0, -0.90), 0.072 * body_k, 1.7, 6))
	creases.append(_arc_i(centres, rxs, rzs, yaws, i_hip + 2, 1.030, b_flank - fs * 0.30, b_flank - fs * 1.15, 6, 0.024))
	for c in range(n_crease):
		var path: Array = creases[c]
		_welt(root, path, Vector3(0.0, 1.0, 0.0), 0.013 * body_k, 0.0085 * body_k, mat_fold)

	# seams down the outside of each arm and each flank
	_welt(root, _arm_seam(a_sh, a_el, a_wr, hs, 0.050 * body_k), Vector3(0.0, 0.0, -1.0), 0.0075 * body_k, 0.0055 * body_k, mat_fold)
	_welt(root, _arm_seam(b_sh, b_el, b_wr, fs, 0.050 * body_k), Vector3(0.0, 0.0, -1.0), 0.0075 * body_k, 0.0055 * body_k, mat_fold)
	for sgn in [-1.0, 1.0]:
		var sf: float = sgn
		var ang: float = 0.0 if sf > 0.0 else PI
		var seam: Array = []
		for i in range(2, i_sh):
			seam.append(_pt_i(centres, rxs, rzs, yaws, i, ang, 1.012))
		_welt(root, seam, Vector3(0.0, 0.0, -1.0), 0.0075 * body_k, 0.0055 * body_k, mat_fold)

	# --- the garden at the foot ----------------------------------------------
	var g0: float = rng.randf_range(0.0, TAU)
	for i in range(n_garden):
		var fi: float = float(i)
		var ang: float = g0 + TAU * fi / float(n_garden) + rng.randf_range(-0.30, 0.30)
		var rad: float = base_r * rng.randf_range(0.78, 1.08)
		var foot := Vector3(cos(ang) * rad, 0.014, sin(ang) * rad)
		var rise: float = rng.randf_range(0.12, 0.25)
		var out_k: float = rng.randf_range(0.14, 0.36)
		var tip := Vector3(foot.x * (1.0 + out_k), foot.y + rise, foot.z * (1.0 + out_k))
		_tapered_cyl(root, foot, tip, 0.0085, 0.0055, mat_stem)
		var grow := Vector3(cos(ang), 0.35, sin(ang))
		var blade_dir: Vector3 = (tip - foot).normalized().lerp(grow.normalized(), 0.55).normalized()
		var ln: float = rng.randf_range(0.13, 0.21)
		var wid: float = ln * rng.randf_range(0.40, 0.58)
		var lobes: float = float(rng.randi_range(3, 6))
		var blade: ArrayMesh = _garden_leaf(ln, wid, lobes, rng.randf_range(0.16, 0.34), rng.randf_range(0.10, 0.26))
		var bmat: StandardMaterial3D = mat_leaf if (i % 2) == 0 else mat_leaf_b
		var bmi: MeshInstance3D = _add(root, blade, bmat)
		bmi.transform = Transform3D(_basis_z_to(blade_dir, Vector3.UP) * Basis(Vector3.FORWARD, rng.randf_range(-0.55, 0.55)), tip)
	var n_stone: int = rng.randi_range(3, 5)
	for i in range(n_stone):
		var ang: float = rng.randf_range(0.0, TAU)
		var rad: float = base_r * rng.randf_range(0.95, 1.30)
		var sr: float = rng.randf_range(0.022, 0.042)
		var flat: float = rng.randf_range(0.72, 1.05)
		_ball(root, Vector3(cos(ang) * rad, sr * 0.52, sin(ang) * rad), Vector3(sr, sr * 0.52, sr * flat), Basis(Vector3.UP, rng.randf_range(0.0, TAU)), mat_stone)

	# --- axis "skin": what the printed second skin has become ----------------
	# Nothing below this line runs, or draws a single number off the rng, unless an
	# axis has been asked for — so build(root, seed) is the mannequin as described.
	if skin == "sprouting":
		# the print stops being a picture. Thirteen stems push out through the suit
		# all the way up the torso, each ending in one of the garden's own blades,
		# and five more droop off the rim of the flat cap where a face is not.
		var n_sprout: int = 13
		for k in range(n_sprout):
			var t: float = float(k) / float(n_sprout - 1)
			var si: int = clampi(int(round(lerpf(2.0, float(i_sh) + 1.0, t))), 1, n_rings - 2)
			var s_ctr: Vector3 = centres[si]
			var s_root: Vector3 = _pt_i(centres, rxs, rzs, yaws, si, rng.randf_range(0.0, TAU), 1.0)
			var s_out: Vector3 = Vector3(s_root.x - s_ctr.x, 0.0, s_root.z - s_ctr.z)
			if s_out.length() < 0.001:
				s_out = Vector3(1.0, 0.0, 0.0)
			s_out = s_out.normalized()
			var s_dir: Vector3 = (s_out + Vector3(0.0, rng.randf_range(0.20, 1.05), 0.0)).normalized()
			var s_tip: Vector3 = s_root + s_dir * (rng.randf_range(0.050, 0.140) * body_k)
			_tapered_cyl(root, s_root, s_tip, 0.0085 * body_k, 0.0050 * body_k, mat_stem)
			var s_len: float = rng.randf_range(0.070, 0.155) * body_k
			var s_blade: ArrayMesh = _garden_leaf(s_len, s_len * rng.randf_range(0.44, 0.62), float(rng.randi_range(3, 6)), rng.randf_range(0.18, 0.36), rng.randf_range(0.10, 0.28))
			var s_mat: StandardMaterial3D = mat_leaf if (k % 2) == 0 else mat_leaf_b
			var s_mi: MeshInstance3D = _add(root, s_blade, s_mat)
			s_mi.transform = Transform3D(_basis_z_to(s_dir, Vector3.UP) * Basis(Vector3.FORWARD, rng.randf_range(-0.80, 0.80)), s_tip)
		for k in range(5):
			var c_ang: float = TAU * float(k) / 5.0 + rng.randf_range(-0.20, 0.20)
			var c_rad := Vector3(cos(c_ang), 0.0, sin(c_ang))
			var c_dir: Vector3 = (c_rad * 0.98 - neck_up * 0.12).normalized()
			var c_root: Vector3 = cap_ctr + c_rad * (cap_r * body_k * 0.88)
			var c_tip: Vector3 = c_root + c_dir * (0.042 * body_k)
			_tapered_cyl(root, c_root, c_tip, 0.0068, 0.0044, mat_stem)
			var c_len: float = rng.randf_range(0.075, 0.130) * body_k
			var c_blade: ArrayMesh = _garden_leaf(c_len, c_len * rng.randf_range(0.44, 0.60), float(rng.randi_range(3, 5)), rng.randf_range(0.18, 0.34), rng.randf_range(0.10, 0.26))
			var c_mi: MeshInstance3D = _add(root, c_blade, mat_leaf)
			c_mi.transform = Transform3D(_basis_z_to(c_dir, Vector3.UP) * Basis(Vector3.FORWARD, rng.randf_range(-0.70, 0.70)), c_tip)
	elif skin == "unravelled":
		# the shell has already shrunk to a core up above; here is the surface it
		# used to be — fourteen threads winding round the outside where the suit
		# was, and eight loose ends that have fallen off the hem onto the base
		var n_strand: int = 14
		for k in range(n_strand):
			var a0t: float = TAU * float(k) / float(n_strand)
			var strand: Array = []
			for j in range(17):
				var ft: float = float(j) / 16.0
				var ti: int = clampi(int(round(lerpf(0.0, float(n_rings - 1), ft))), 0, n_rings - 1)
				var kt: float = lerpf(1.03, 1.34, absf(sin(PI * ft * 1.7)))
				strand.append(_pt_i(centres, rxs, rzs, yaws, ti, a0t + ft * TAU * 1.7, kt))
			_welt(root, strand, Vector3(0.0, 1.0, 0.0), 0.0055 * body_k, 0.0055 * body_k, mat_fold)
		var n_drop: int = 8
		for k in range(n_drop):
			var d_ang: float = TAU * float(k) / float(n_drop) + 0.31
			var d_top: Vector3 = _pt_i(centres, rxs, rzs, yaws, 0, d_ang, 1.06)
			var d_r: float = base_r * rng.randf_range(0.45, 1.05)
			var d_land := Vector3(cos(d_ang) * d_r, 0.020, sin(d_ang) * d_r)
			var d_bow: float = rng.randf_range(0.030, 0.090)
			var d_path: Array = []
			for j in range(9):
				var fd: float = float(j) / 8.0
				var d_p: Vector3 = d_top.lerp(d_land, fd)
				d_path.append(d_p + Vector3(cos(d_ang), 0.0, sin(d_ang)) * (d_bow * sin(PI * fd)))
			_welt(root, d_path, Vector3(0.0, 1.0, 0.0), 0.0050 * body_k, 0.0050 * body_k, mat_fold)
	elif skin == "poured":
		# flooded: the pole, the hem and the hips are inside one solid pour that
		# has set where it stopped, with runs still on its outside
		var pour_top: float = (HEM_Y + 0.220) * body_k
		var pour_r0: float = base_r * 2.20
		var pour_r1: float = 0.230 * body_k
		var layers: int = 12
		for k in range(layers):
			var f0: float = float(k) / float(layers)
			var f1: float = float(k + 1) / float(layers)
			var y_a: float = lerpf(0.004, pour_top, f0)
			var y_b: float = lerpf(0.004, pour_top, f1)
			var r_a: float = lerpf(pour_r0, pour_r1, pow(f0, 0.42))
			var r_b: float = lerpf(pour_r0, pour_r1, pow(f1, 0.42))
			_tapered_cyl(root, Vector3(0.0, y_a, 0.0), Vector3(0.0, y_b, 0.0), r_a, r_b, mat_pour)
		_ring_band(root, Vector3(0.0, pour_top, 0.0), pour_r1 * 1.07, pour_r1 * 1.07, 0.013, 0.0, mat_pour)
		var n_drip: int = 6
		for k in range(n_drip):
			var p_ang: float = TAU * float(k) / float(n_drip) + rng.randf_range(-0.26, 0.26)
			var fdp: float = rng.randf_range(0.30, 0.75)
			var p_y: float = lerpf(0.004, pour_top, fdp)
			var p_r: float = lerpf(pour_r0, pour_r1, pow(fdp, 0.42)) * 1.02
			var p_top_v := Vector3(cos(p_ang) * p_r, p_y, sin(p_ang) * p_r)
			var p_bot := Vector3(cos(p_ang) * p_r * 1.10, 0.006, sin(p_ang) * p_r * 1.10)
			_tapered_cyl(root, p_bot, p_top_v, 0.022, 0.010, mat_pour)
			_ball(root, p_top_v, Vector3(0.017, 0.021, 0.017), Basis(), mat_pour)

	# --- axis "rank": how many mannequins are inside this one -----------------
	if rank == "twinned":
		# a second, smaller mannequin has budded out of the upper back, hem first,
		# and is leaning away with its own neck, cap and two hanging arms
		var bud_at: Vector3 = _pt_i(centres, rxs, rzs, yaws, i_bust, PI * 0.5, 0.96)
		var bud_yaw: float = deg_to_rad(rng.randf_range(-24.0, 24.0))
		var bud_pitch: float = deg_to_rad(rng.randf_range(40.0, 54.0))
		var bud_tilt: Basis = Basis(Vector3.UP, bud_yaw) * Basis(Vector3.RIGHT, bud_pitch)
		_twin_body(root, 0.55 * body_k, bud_tilt, bud_at, deg_to_rad(15.0) * twist_dir, 0.020, mat_suit, mat_trim, rng)
	elif rank == "multiplied":
		# three necks off one yoke, each ending in its own flat oval cap, and two
		# more arms budding out of the flanks under the bust
		for sgn in [-1.0, 1.0]:
			var sf: float = sgn
			var m_bs: Basis = Basis(Vector3.FORWARD, deg_to_rad(sf * 34.0)) * Basis(Vector3.RIGHT, deg_to_rad(-9.0))
			var m_up: Vector3 = (m_bs * Vector3.UP).normalized()
			var m_from: Vector3 = p_top + Vector3(sf * rx_sh * 0.62, -0.024, 0.004)
			_neck_stem(root, m_from, m_up, neck_len * body_k * 0.92, cap_r * body_k * 0.78, cap_oval, m_bs, mat_hood, mat_trim)
		for sgn in [-1.0, 1.0]:
			var sf: float = sgn
			var e_ang: float = 0.0 if sf > 0.0 else PI
			var e_sh: Vector3 = _pt_i(centres, rxs, rzs, yaws, maxi(i_bust - 2, 2), e_ang, 1.0)
			var e_d1 := Vector3(sf * 0.86, -0.30, -0.42)
			var e_el: Vector3 = e_sh + e_d1.normalized() * (arm_bone * 0.88)
			var e_d2 := Vector3(sf * 0.24, -0.32, -0.92)
			var e_wr: Vector3 = e_el + e_d2.normalized() * (arm_bone * 0.88)
			_ball(root, e_sh, Vector3(0.058, 0.055, 0.060) * body_k, Basis(), mat_suit)
			_chain(root, e_sh, e_el, 0.050 * body_k, 0.041 * body_k, 4, 0.94, mat_suit)
			_ball(root, e_el, Vector3(0.046, 0.046, 0.048) * body_k, Basis(), mat_suit)
			_chain(root, e_el, e_wr, 0.041 * body_k, 0.031 * body_k, 4, 0.92, mat_suit)
			_ball(root, e_wr, Vector3(0.030, 0.029, 0.030) * body_k, Basis(), mat_suit)
			_hand(root, e_wr, e_d2.normalized(), Vector3(0.0, 1.0, 0.0), 0.26, body_k * 0.86, mat_suit)
	elif rank == "swarm":
		# the rank the reference described, but folded back into the one body: it
		# is shedding thirty small copies of itself in a helix off the base
		var n_swarm: int = 30
		for k in range(n_swarm):
			var t: float = float(k) / float(n_swarm - 1)
			var w_ang: float = t * TAU * 2.7 + rng.randf_range(-0.18, 0.18)
			var w_rad: float = lerpf(0.30, 0.15, t) + rng.randf_range(-0.035, 0.050)
			var w_y: float = lerpf(0.045, 1.470, pow(t, 0.85))
			var w_k: float = lerpf(0.300, 0.085, t) * body_k
			var w_bs: Basis = Basis(Vector3.UP, w_ang + PI * 0.5) * Basis(Vector3.FORWARD, rng.randf_range(-1.20, 1.20)) * Basis(Vector3.RIGHT, rng.randf_range(-0.90, 0.90))
			_mini_body(root, w_k, w_bs, Vector3(cos(w_ang) * w_rad, w_y, sin(w_ang) * w_rad), mat_suit, mat_trim)

	# --- measured settle: fit, centre on x/z, stand on y = 0 -----------------
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
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + shift)


# ---------------------------------------------------------------------------
# the torso profile and its rings

static func _profile_at(s: float) -> Vector3:
	var k: int = PROFILE.size()
	var f: float = clampf(s, 0.0, 1.0) * float(k - 1)
	var i: int = int(floor(f))
	if i >= k - 1:
		var last: Array = PROFILE[k - 1]
		var l0: float = last[0]
		var l1: float = last[1]
		var l2: float = last[2]
		return Vector3(l0, l1, l2)
	var u: float = f - float(i)
	var sm: float = u * u * (3.0 - 2.0 * u)
	var a: Array = PROFILE[i]
	var b: Array = PROFILE[i + 1]
	var a0: float = a[0]
	var a1: float = a[1]
	var a2: float = a[2]
	var b0: float = b[0]
	var b1: float = b[1]
	var b2: float = b[2]
	return Vector3(lerpf(a0, b0, sm), lerpf(a1, b1, sm), lerpf(a2, b2, sm))


static func _ring_for(centres: Array, y: float) -> int:
	var best: int = 0
	var best_d: float = 1.0e9
	for i in range(centres.size()):
		var c: Vector3 = centres[i]
		var d: float = absf(c.y - y)
		if d < best_d:
			best_d = d
			best = i
	return clampi(best, 1, centres.size() - 3)


static func _ring_pt(ctr: Vector3, rx: float, rz: float, yw: float, a: float, k: float) -> Vector3:
	var ca: float = cos(a)
	var sa: float = sin(a)
	var lx: float = rx * k * ca
	var lz: float = rz * k * sa * (1.0 - 0.12 * sa)
	var cy: float = cos(yw)
	var sy: float = sin(yw)
	return ctr + Vector3(lx * cy + lz * sy, 0.0, -lx * sy + lz * cy)


static func _pt_i(centres: Array, rxs: Array, rzs: Array, yaws: Array, i: int, a: float, k: float) -> Vector3:
	var ctr: Vector3 = centres[i]
	var rx: float = rxs[i]
	var rz: float = rzs[i]
	var yw: float = yaws[i]
	return _ring_pt(ctr, rx, rz, yw, a, k)


static func _band_i(root: Node3D, centres: Array, rxs: Array, rzs: Array, yaws: Array, i: int, k: float, tube: float, lift: float, mat: StandardMaterial3D) -> void:
	var ctr: Vector3 = centres[i]
	var rx: float = rxs[i]
	var rz: float = rzs[i]
	var yw: float = yaws[i]
	_ring_band(root, ctr + Vector3(0.0, lift, 0.0), rx * k, rz * k, tube, yw, mat)


static func _arc_i(centres: Array, rxs: Array, rzs: Array, yaws: Array, i: int, k: float, a0: float, a1: float, n: int, dy: float) -> Array:
	var ctr: Vector3 = centres[i]
	var rx: float = rxs[i]
	var rz: float = rzs[i]
	var yw: float = yaws[i]
	var pts: Array = []
	for j in range(n):
		var f: float = float(j) / float(n - 1)
		var a: float = lerpf(a0, a1, f)
		var p: Vector3 = _ring_pt(ctr, rx * k, rz * k, yw, a, 1.0)
		var drop: float = dy * sin(PI * f)
		pts.append(p + Vector3(0.0, drop, 0.0))
	return pts


## Lofts the torso. Vertices are emitted relative to `base` so the MeshInstance3D
## can carry a real origin instead of sitting at (0,0,0) like every other shell.
static func _loft(centres: Array, rxs: Array, rzs: Array, yaws: Array, seg: int, base: Vector3) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = centres.size()
	var mids: Array = []
	var grid: Array = []
	for i in range(n):
		var ctr: Vector3 = centres[i]
		var rx: float = rxs[i]
		var rz: float = rzs[i]
		var yw: float = yaws[i]
		mids.append(ctr - base)
		var row: Array = []
		for k in range(seg):
			var a: float = TAU * float(k) / float(seg)
			row.append(_ring_pt(ctr, rx, rz, yw, a, 1.0) - base)
		grid.append(row)
	st.set_smooth_group(0)
	for i in range(n - 1):
		var r0: Array = grid[i]
		var r1: Array = grid[i + 1]
		var c0: Vector3 = mids[i]
		var c1: Vector3 = mids[i + 1]
		var inside: Vector3 = (c0 + c1) * 0.5
		for k in range(seg):
			var j: int = (k + 1) % seg
			var q0: Vector3 = r0[k]
			var q1: Vector3 = r0[j]
			var q2: Vector3 = r1[j]
			var q3: Vector3 = r1[k]
			_quad_out(st, q0, q1, q2, q3, inside)
	st.set_smooth_group(-1)
	var bot: Array = grid[0]
	var cb: Vector3 = mids[0]
	var in_b: Vector3 = cb + Vector3(0.0, 0.06, 0.0)
	for k in range(seg):
		var j: int = (k + 1) % seg
		var q0: Vector3 = bot[k]
		var q1: Vector3 = bot[j]
		_tri_out(st, cb, q0, q1, in_b)
	var top: Array = grid[n - 1]
	var ct: Vector3 = mids[n - 1]
	var in_t: Vector3 = ct - Vector3(0.0, 0.06, 0.0)
	for k in range(seg):
		var j: int = (k + 1) % seg
		var q0: Vector3 = top[k]
		var q1: Vector3 = top[j]
		_tri_out(st, ct, q0, q1, in_t)
	st.generate_normals()
	return st.commit()


# ---------------------------------------------------------------------------
# welts, arcs, seams

static func _arc_pts(ctr: Vector3, axis: Vector3, out_dir: Vector3, r: float, span: float, n: int) -> Array:
	var ax: Vector3 = axis.normalized()
	var o: Vector3 = out_dir - ax * out_dir.dot(ax)
	if o.length() < 0.0001:
		o = Vector3(0.0, 0.0, -1.0) - ax * ax.z
	if o.length() < 0.0001:
		o = Vector3(1.0, 0.0, 0.0) - ax * ax.x
	o = o.normalized()
	var sv: Vector3 = ax.cross(o).normalized()
	var pts: Array = []
	for i in range(n):
		var f: float = float(i) / float(n - 1) - 0.5
		var a: float = f * span
		pts.append(ctr + (o * cos(a) + sv * sin(a)) * r)
	return pts


static func _arm_seam(sh: Vector3, el: Vector3, wr: Vector3, side: float, off: float) -> Array:
	var lat := Vector3(side, 0.0, -0.35)
	var out_v: Vector3 = lat.normalized() * off
	var pts: Array = []
	for i in range(9):
		var f: float = float(i) / 8.0
		var p: Vector3 = sh.lerp(el, clampf(f * 2.0, 0.0, 1.0)) if f < 0.5 else el.lerp(wr, clampf((f - 0.5) * 2.0, 0.0, 1.0))
		pts.append(p + out_v)
	return pts


## Sweeps a six-sided welt along `pts`, tapered at both ends. Vertices are local to
## the path's first point so the MeshInstance3D carries a real origin.
static func _welt(root: Node3D, world_pts: Array, up_hint: Vector3, w: float, h: float, mat: StandardMaterial3D) -> void:
	var n: int = world_pts.size()
	if n < 3:
		return
	var base: Vector3 = world_pts[0]
	var pts: Array = []
	for i in range(n):
		var wp: Vector3 = world_pts[i]
		pts.append(wp - base)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	var sides: int = 6
	var rings: Array = []
	for i in range(n):
		var a: Vector3 = pts[maxi(i - 1, 0)]
		var b: Vector3 = pts[mini(i + 1, n - 1)]
		var tg: Vector3 = b - a
		if tg.length() < 0.00001:
			tg = Vector3.UP
		tg = tg.normalized()
		var sx: Vector3 = up_hint.cross(tg)
		if sx.length() < 0.0002:
			sx = Vector3.RIGHT.cross(tg)
		if sx.length() < 0.0002:
			sx = Vector3.FORWARD.cross(tg)
		sx = sx.normalized()
		var nz: Vector3 = tg.cross(sx).normalized()
		var f: float = float(i) / float(n - 1)
		var taper: float = 0.32 + 0.68 * sin(PI * clampf(f, 0.0, 1.0))
		var ctr: Vector3 = pts[i]
		var row: Array = []
		for k in range(sides):
			var ang: float = TAU * float(k) / float(sides)
			row.append(ctr + sx * (w * taper * cos(ang)) + nz * (h * taper * sin(ang)))
		rings.append(row)
	for i in range(n - 1):
		var r0: Array = rings[i]
		var r1: Array = rings[i + 1]
		var pa: Vector3 = pts[i]
		var pb: Vector3 = pts[i + 1]
		var inside: Vector3 = (pa + pb) * 0.5
		for k in range(sides):
			var j: int = (k + 1) % sides
			var q0: Vector3 = r0[k]
			var q1: Vector3 = r0[j]
			var q2: Vector3 = r1[j]
			var q3: Vector3 = r1[k]
			_quad_out(st, q0, q1, q2, q3, inside)
	st.set_smooth_group(-1)
	var p_first: Vector3 = pts[0]
	var p_second: Vector3 = pts[1]
	var first: Array = rings[0]
	var f_in: Vector3 = p_first + (p_second - p_first) * 0.25
	for k in range(sides):
		var j: int = (k + 1) % sides
		var q0: Vector3 = first[k]
		var q1: Vector3 = first[j]
		_tri_out(st, p_first, q0, q1, f_in)
	var p_last: Vector3 = pts[n - 1]
	var p_prev: Vector3 = pts[n - 2]
	var last: Array = rings[n - 1]
	var l_in: Vector3 = p_last + (p_prev - p_last) * 0.25
	for k in range(sides):
		var j: int = (k + 1) % sides
		var q0: Vector3 = last[k]
		var q1: Vector3 = last[j]
		_tri_out(st, p_last, q0, q1, l_in)
	st.generate_normals()
	var mi: MeshInstance3D = _add(root, st.commit(), mat)
	mi.transform = Transform3D(Basis(), base)


# ---------------------------------------------------------------------------
# the garden leaf: a lobed blade, cupped along the midrib, drooping at the tip

static func _garden_leaf(ln: float, wid: float, lobes: float, notch: float, cup: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	var rows: int = 14
	var cols: int = 9
	var grid: Array = []
	for i in range(rows):
		var u: float = float(i) / float(rows - 1)
		var hw: float = wid * pow(sin(PI * maxf(u, 0.004)), 0.70)
		var lob: float = absf(sin(PI * u * lobes))
		hw *= 1.0 - notch * (1.0 - lob)
		var droop: float = -0.34 * ln * u * u
		var row: Array = []
		for k in range(cols):
			var v: float = float(k) / float(cols - 1) * 2.0 - 1.0
			var x: float = v * hw
			var lift: float = cup * hw * pow(absf(v), 1.6)
			row.append(Vector3(x, droop + lift, u * ln))
		grid.append(row)
	for i in range(rows - 1):
		var r0: Array = grid[i]
		var r1: Array = grid[i + 1]
		for k in range(cols - 1):
			var a: Vector3 = r0[k]
			var b: Vector3 = r0[k + 1]
			var c: Vector3 = r1[k + 1]
			var d: Vector3 = r1[k]
			st.add_vertex(a)
			st.add_vertex(b)
			st.add_vertex(c)
			st.add_vertex(a)
			st.add_vertex(c)
			st.add_vertex(d)
	st.generate_normals()
	return st.commit()


# ---------------------------------------------------------------------------
# the axes' extra bodies: a neck that ends in a cap, a bud, and a hand-sized copy

## One neck stem with a flat oval cap and its chrome edge ring, grown along `up_v`
## from `at`. The multiplied rank hangs two of these off the one yoke.
static func _neck_stem(root: Node3D, at: Vector3, up_v: Vector3, ln: float, cr: float, oval: float, bs_base: Basis, mat_body: StandardMaterial3D, mat_rim: StandardMaterial3D) -> void:
	var mid_p: Vector3 = at + up_v * (ln * 0.52)
	var top_p: Vector3 = at + up_v * ln
	_tapered_cyl(root, at, mid_p, cr * 0.86, cr * 0.80, mat_body)
	_tapered_cyl(root, mid_p, top_p, cr * 0.80, cr * 0.84, mat_body)
	var ctr: Vector3 = top_p + up_v * (cr * 0.20)
	var cap_bs: Basis = bs_base * Basis.from_scale(Vector3(1.0, 1.0, oval))
	var plate := CylinderMesh.new()
	plate.top_radius = cr
	plate.bottom_radius = cr * 0.96
	plate.height = 0.018
	plate.radial_segments = 28
	var plate_mi: MeshInstance3D = _add(root, plate, mat_body)
	plate_mi.transform = Transform3D(cap_bs, ctr)
	var edge := TorusMesh.new()
	edge.inner_radius = maxf(cr - 0.006, 0.002)
	edge.outer_radius = cr + 0.004
	edge.rings = 24
	edge.ring_segments = 8
	var edge_mi: MeshInstance3D = _add(root, edge, mat_rim)
	edge_mi.transform = Transform3D(cap_bs, ctr)


## A second mannequin at scale `tk`, rooted hem-first at `at` and carried by
## `tilt`: the same lofted profile, a neck, a cap and two arms hanging off it.
static func _twin_body(root: Node3D, tk: float, tilt: Basis, at: Vector3, twist_t: float, sway_t: float, mat_body: StandardMaterial3D, mat_rim: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	var t_rings: int = 18
	var t_centres: Array = []
	var t_rx: Array = []
	var t_rz: Array = []
	var t_yaw: Array = []
	for i in range(t_rings):
		var s: float = float(i) / float(t_rings - 1)
		var key: Vector3 = _profile_at(s)
		var g: float = key.x / PROFILE_TOP
		var cx: float = sway_t * cos(PI * g)
		t_centres.append(Vector3(cx, key.x * tk, 0.0))
		t_rx.append(key.y * tk)
		t_rz.append(key.z * tk)
		t_yaw.append(twist_t * g * g)
	var t_base: Vector3 = t_centres[0]
	var t_shell: ArrayMesh = _loft(t_centres, t_rx, t_rz, t_yaw, 20, t_base)
	var t_mi: MeshInstance3D = _add(root, t_shell, mat_body)
	t_mi.transform = Transform3D(tilt, at)

	var t_up: Vector3 = (tilt * Vector3.UP).normalized()
	var t_side: Vector3 = (tilt * Vector3.RIGHT).normalized()
	var t_back: Vector3 = (tilt * Vector3.BACK).normalized()
	var t_top_l: Vector3 = t_centres[t_rings - 1]
	var t_neck_a: Vector3 = at + tilt * (t_top_l - t_base) - t_up * (0.012 * tk)
	_neck_stem(root, t_neck_a, t_up, 0.108 * tk, 0.076 * tk, 0.68, tilt, mat_body, mat_rim)

	var t_sh_l: Vector3 = t_centres[t_rings - 4]
	var t_sh_w: Vector3 = at + tilt * (t_sh_l - t_base)
	var t_rx_sh: float = t_rx[t_rings - 4]
	var t_arm: float = 0.240 * tk
	for sg in [-1.0, 1.0]:
		var sf: float = sg
		var o_sh: Vector3 = t_sh_w + t_side * (sf * t_rx_sh * 0.94)
		var d1: Vector3 = t_side * (sf * 0.40) - t_up * 0.86 + t_back * rng.randf_range(-0.26, 0.20)
		var o_el: Vector3 = o_sh + d1.normalized() * t_arm
		var d2: Vector3 = t_side * (sf * 0.12) - t_up * 0.82 - t_back * rng.randf_range(0.30, 0.62)
		var o_wr: Vector3 = o_el + d2.normalized() * t_arm
		_ball(root, o_sh, Vector3(0.058, 0.055, 0.060) * tk, Basis(), mat_body)
		_chain(root, o_sh, o_el, 0.050 * tk, 0.042 * tk, 3, 0.94, mat_body)
		_ball(root, o_el, Vector3(0.046, 0.046, 0.048) * tk, Basis(), mat_body)
		_chain(root, o_el, o_wr, 0.042 * tk, 0.031 * tk, 3, 0.92, mat_body)
		_ball(root, o_wr, Vector3(0.031, 0.029, 0.031) * tk, Basis(), mat_body)


## A hand-sized copy of the whole mannequin: the same profile lofted coarse, and
## the flat cap that says it is one of these and not a bottle.
static func _mini_body(root: Node3D, mk: float, tilt: Basis, at: Vector3, mat_body: StandardMaterial3D, mat_rim: StandardMaterial3D) -> void:
	var m_n: int = 9
	var m_centres: Array = []
	var m_rx: Array = []
	var m_rz: Array = []
	var m_yaw: Array = []
	for i in range(m_n):
		var s: float = float(i) / float(m_n - 1)
		var key: Vector3 = _profile_at(s)
		m_centres.append(Vector3(0.0, key.x * mk, 0.0))
		m_rx.append(key.y * mk)
		m_rz.append(key.z * mk)
		m_yaw.append(0.0)
	var m_base: Vector3 = m_centres[0]
	var m_shell: ArrayMesh = _loft(m_centres, m_rx, m_rz, m_yaw, 12, m_base)
	var m_mi: MeshInstance3D = _add(root, m_shell, mat_body)
	m_mi.transform = Transform3D(tilt, at)
	var m_up: Vector3 = (tilt * Vector3.UP).normalized()
	var m_cap := CylinderMesh.new()
	m_cap.top_radius = 0.078 * mk
	m_cap.bottom_radius = 0.074 * mk
	m_cap.height = 0.022 * mk
	m_cap.radial_segments = 14
	var m_cap_mi: MeshInstance3D = _add(root, m_cap, mat_rim)
	m_cap_mi.transform = Transform3D(tilt * Basis.from_scale(Vector3(1.0, 1.0, 0.68)), at + m_up * (PROFILE_TOP * mk + 0.030 * mk))


# ---------------------------------------------------------------------------
# primitives

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
	sph.radial_segments = 18
	sph.rings = 10
	var mi: MeshInstance3D = _add(root, sph, mat)
	mi.transform = Transform3D(bs * Basis.from_scale(half), ctr)
	return mi


static func _limb(root: Node3D, a: Vector3, b: Vector3, r: float, flat: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.006)
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = ln + r * 2.0
	cap.radial_segments = 14
	cap.rings = 6
	var mi: MeshInstance3D = _add(root, cap, mat)
	mi.transform = Transform3D(_basis_y_to(d) * Basis.from_scale(Vector3(1.0, 1.0, flat)), (a + b) * 0.5)
	return mi


static func _chain(root: Node3D, a: Vector3, b: Vector3, r0: float, r1: float, n: int, flat: float, mat: StandardMaterial3D) -> void:
	for i in range(n):
		var f0: float = float(i) / float(n)
		var f1: float = float(i + 1) / float(n)
		var p0: Vector3 = a.lerp(b, f0)
		var p1: Vector3 = a.lerp(b, f1)
		var rr: float = lerpf(r0, r1, (f0 + f1) * 0.5)
		_limb(root, p0, p1, rr, flat, mat)


static func _tapered_cyl(root: Node3D, a: Vector3, b: Vector3, r0: float, r1: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.006)
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = r0
	cyl.top_radius = r1
	cyl.height = ln
	cyl.radial_segments = 18
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _ring_band(root: Node3D, ctr: Vector3, rx: float, rz: float, tube: float, yw: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var mean: float = maxf((rx + rz) * 0.5, 0.006)
	var tor := TorusMesh.new()
	tor.inner_radius = maxf(mean - tube, 0.0015)
	tor.outer_radius = mean + tube
	tor.rings = 30
	tor.ring_segments = 8
	var mi: MeshInstance3D = _add(root, tor, mat)
	var bs: Basis = Basis(Vector3.UP, yw) * Basis.from_scale(Vector3(rx / mean, 1.0, rz / mean))
	mi.transform = Transform3D(bs, ctr)
	return mi


static func _hand(root: Node3D, wrist: Vector3, dir: Vector3, side_hint: Vector3, curl: float, k: float, mat: StandardMaterial3D) -> void:
	var bz: Vector3 = dir.normalized()
	var bx: Vector3 = side_hint - bz * side_hint.dot(bz)
	if bx.length() < 0.001:
		bx = Vector3(1.0, 0.0, 0.0) - bz * bz.x
	bx = bx.normalized()
	var by: Vector3 = bz.cross(bx).normalized()
	var hb := Basis(bx, by, bz)
	var palm: Vector3 = wrist + bz * (0.048 * k)
	_ball(root, palm, Vector3(0.050, 0.023, 0.048) * k, hb, mat)
	for i in range(4):
		var fi: float = float(i)
		var spread: float = (fi - 1.5) * 0.24
		var fd: Vector3 = (bz * cos(spread) + bx * sin(spread) - by * curl).normalized()
		var a: Vector3 = palm + bz * (0.026 * k) + bx * ((fi - 1.5) * 0.021 * k)
		var b: Vector3 = a + fd * ((0.058 - absf(fi - 1.5) * 0.008) * k)
		_limb(root, a, b, 0.0115 * k, 0.85, mat)
	var td: Vector3 = (bz * 0.42 - bx * 0.86 - by * (curl * 0.5)).normalized()
	var ta: Vector3 = palm - bx * (0.036 * k) + bz * (0.002 * k)
	_limb(root, ta, ta + td * (0.050 * k), 0.0125 * k, 0.85, mat)


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


static func _basis_z_to(dir: Vector3, up_hint: Vector3) -> Basis:
	var bz: Vector3 = dir.normalized()
	var bx: Vector3 = up_hint.cross(bz)
	if bx.length() < 0.001:
		bx = Vector3(1.0, 0.0, 0.0).cross(bz)
	if bx.length() < 0.001:
		bx = Vector3(0.0, 0.0, 1.0).cross(bz)
	bx = bx.normalized()
	var by: Vector3 = bz.cross(bx).normalized()
	return Basis(bx, by, bz)


static func _quad_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, inside: Vector3) -> void:
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
# materials

static func _print_mat(tex: ImageTexture, tint: Color, uv_k: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 1.0
	m.uv1_scale = Vector3(uv_k, uv_k, uv_k)
	m.roughness = rough
	m.metallic = 0.0
	return m


static func _flat_mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m


static func _metal_mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.92
	m.metallic_specular = 0.62
	return m


# ---------------------------------------------------------------------------
# the five prints, painted in code

static func _blend(img: Image, x: int, y: int, c: Color, alpha: float) -> void:
	var xi: int = posmod(x, TEX)
	var yi: int = posmod(y, TEX)
	if alpha >= 0.999:
		img.set_pixel(xi, yi, c)
		return
	var prev: Color = img.get_pixel(xi, yi)
	img.set_pixel(xi, yi, prev.lerp(c, alpha))


static func _ground(img: Image, base: Color, weave: float) -> void:
	for y in range(TEX):
		for x in range(TEX):
			var fx: float = float(x)
			var fy: float = float(y)
			var n: float = weave * (sin(fx * 1.63) * sin(fy * 1.41) + 0.6 * sin((fx + fy) * 0.71))
			img.set_pixel(x, y, Color(clampf(base.r + n, 0.0, 1.0), clampf(base.g + n, 0.0, 1.0), clampf(base.b + n, 0.0, 1.0)))


## One monstera leaf: lobed blade, notches sheared in from the edge, fenestrations.
static func _stamp_leaf(img: Image, cx: float, cy: float, s: float, ang: float, ink: Color, vein: Color, slits: float, slant: float, deep: float, holes: Array, alpha: float) -> void:
	var ca: float = cos(ang)
	var sa: float = sin(ang)
	var hd: float = s * 0.78 + 3.0
	var x0: int = int(floor(cx - hd))
	var x1: int = int(ceil(cx + hd))
	var y0: int = int(floor(cy - hd))
	var y1: int = int(ceil(cy + hd))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var dx: float = float(x) + 0.5 - cx
			var dy: float = float(y) + 0.5 - cy
			var lu: float = (dx * ca + dy * sa) / s + 0.5
			var av: float = (-dx * sa + dy * ca) / s
			if lu <= 0.015 or lu >= 0.995:
				continue
			var base_w: float = 0.50 * pow(sin(PI * lu), 0.72)
			if base_w < 0.003:
				continue
			var qf: float = (lu + slant * absf(av)) * slits
			if av < 0.0:
				qf += 0.5
			var sl: float = absf(sin(PI * qf))
			var notch: float = clampf((0.36 - sl) / 0.36, 0.0, 1.0)
			var inner: float = base_w * (1.0 - deep * notch * notch)
			if absf(av) > inner:
				continue
			var cut: bool = false
			for hv in holes:
				var hh: Vector3 = hv
				var ddx: float = (lu - hh.x) / maxf(hh.z, 0.002)
				var ddy: float = (av - hh.y * base_w) / maxf(hh.z * 0.52, 0.002)
				if ddx * ddx + ddy * ddy < 1.0:
					cut = true
					break
			if cut:
				continue
			var c: Color = ink
			if absf(av) < 0.011:
				c = vein
			elif sl > 0.972 and absf(av) > 0.020:
				c = vein
			_blend(img, x, y, c, alpha)


static func _stamp_disc(img: Image, cx: float, cy: float, r: float, wob: float, ph: float, ink: Color) -> void:
	var hd: float = r * (1.0 + wob) + 2.0
	var x0: int = int(floor(cx - hd))
	var x1: int = int(ceil(cx + hd))
	var y0: int = int(floor(cy - hd))
	var y1: int = int(ceil(cy + hd))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var dx: float = float(x) + 0.5 - cx
			var dy: float = float(y) + 0.5 - cy
			var d: float = sqrt(dx * dx + dy * dy)
			if d < 0.0001:
				_blend(img, x, y, ink, 1.0)
				continue
			var th: float = atan2(dy, dx)
			var rr: float = r * (1.0 + wob * sin(3.0 * th + ph) + wob * 0.5 * sin(5.0 * th - ph * 1.7))
			if d <= rr:
				_blend(img, x, y, ink, 1.0)


static func _tex_monstera(rng: RandomNumberGenerator) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	_ground(img, Color("#F4F1E7"), 0.016)
	# leaf count and size measured for ~46% coverage: the leaves must read as big
	# and separate ON WHITE, and 6..9 of them at this size closed the ground over
	var greens: Array = [Color("#2F7A3E"), Color("#256B39"), Color("#3C8C46"), Color("#1E5C31")]
	var n: int = rng.randi_range(5, 7)
	for k in range(n):
		var gi: int = rng.randi_range(0, greens.size() - 1)
		var ink: Color = greens[gi]
		var vein: Color = ink.darkened(0.30)
		var s: float = rng.randf_range(84.0, 124.0)
		var cx: float = rng.randf_range(0.0, float(TEX))
		var cy: float = rng.randf_range(0.0, float(TEX))
		var ang: float = rng.randf_range(-PI, PI)
		var holes: Array = []
		var nh: int = rng.randi_range(2, 4)
		for h in range(nh):
			var fh: float = float(h)
			var hu: float = 0.28 + fh * 0.16 + rng.randf_range(-0.05, 0.05)
			var hside: float = 1.0 if rng.randf() < 0.5 else -1.0
			var hv: float = rng.randf_range(0.28, 0.62) * hside
			holes.append(Vector3(hu, hv, rng.randf_range(0.045, 0.080)))
		var slits: float = float(rng.randi_range(5, 8))
		_stamp_leaf(img, cx, cy, s, ang, ink, vein, slits, rng.randf_range(0.20, 0.42), rng.randf_range(0.72, 0.90), holes, 1.0)
	return ImageTexture.create_from_image(img)


static func _tex_shadow_leaves(rng: RandomNumberGenerator) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	_ground(img, Color("#F2EFF4"), 0.014)
	# denser than the monstera (these are overlapping shadows, and the 0.55 blend
	# keeps an unstacked leaf pale) but not so dense the white ground closes
	var purples: Array = [Color("#8E6FB8"), Color("#6E4E9C"), Color("#A98CCB"), Color("#5B3E86")]
	var n: int = rng.randi_range(4, 7)
	for k in range(n):
		var gi: int = rng.randi_range(0, purples.size() - 1)
		var ink: Color = purples[gi]
		var vein: Color = ink.darkened(0.22)
		var s: float = rng.randf_range(104.0, 176.0)
		var cx: float = rng.randf_range(0.0, float(TEX))
		var cy: float = rng.randf_range(0.0, float(TEX))
		var ang: float = rng.randf_range(-PI, PI)
		var holes: Array = []
		if rng.randf() < 0.6:
			holes.append(Vector3(rng.randf_range(0.32, 0.62), rng.randf_range(-0.55, 0.55), rng.randf_range(0.05, 0.09)))
		var slits: float = float(rng.randi_range(4, 7))
		_stamp_leaf(img, cx, cy, s, ang, ink, vein, slits, rng.randf_range(0.14, 0.36), rng.randf_range(0.55, 0.80), holes, 0.55)
	return ImageTexture.create_from_image(img)


static func _tex_stripes(rng: RandomNumberGenerator) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var coral := Color("#E8735A")
	var cream := Color("#F5EEDF")
	var bands: float = float(rng.randi_range(26, 38))
	var duty: float = rng.randf_range(0.34, 0.52)
	var phase: float = rng.randf_range(0.0, TAU)
	for y in range(TEX):
		var fy: float = float(y)
		for x in range(TEX):
			var fx: float = float(x)
			var v: float = sin(fx * TAU * bands / float(TEX) + phase)
			var m: float = clampf((v - (1.0 - 2.0 * duty)) * 6.0 + 0.5, 0.0, 1.0)
			var shade: float = 1.0 - 0.030 * sin(fy * 1.1 + fx * 0.4) - 0.020 * sin(fy * 0.31)
			var c: Color = cream.lerp(coral, m)
			img.set_pixel(x, y, Color(clampf(c.r * shade, 0.0, 1.0), clampf(c.g * shade, 0.0, 1.0), clampf(c.b * shade, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


static func _tex_speckle(rng: RandomNumberGenerator) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	_ground(img, Color("#F2F0EA"), 0.018)
	var ink := Color("#1E1F24")
	var n: int = rng.randi_range(16, 24)
	for k in range(n):
		var cx: float = rng.randf_range(0.0, float(TEX))
		var cy: float = rng.randf_range(0.0, float(TEX))
		var r: float = rng.randf_range(9.0, 27.0)
		var lobes: int = rng.randi_range(2, 4)
		for l in range(lobes):
			var fl: float = float(l)
			var off: float = r * rng.randf_range(0.20, 0.75)
			var oa: float = rng.randf_range(0.0, TAU) + fl
			var rr: float = r * rng.randf_range(0.45, 0.92)
			_stamp_disc(img, cx + cos(oa) * off, cy + sin(oa) * off, rr, rng.randf_range(0.10, 0.26), rng.randf_range(0.0, TAU), ink)
	var dots: int = rng.randi_range(20, 40)
	for k in range(dots):
		_stamp_disc(img, rng.randf_range(0.0, float(TEX)), rng.randf_range(0.0, float(TEX)), rng.randf_range(1.6, 4.4), 0.20, rng.randf_range(0.0, TAU), ink)
	return ImageTexture.create_from_image(img)


static func _tex_saffron(rng: RandomNumberGenerator) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	_ground(img, Color("#E8B33A"), 0.020)
	# a sprinkle, ~15% coverage: the reference calls this one PLAIN saffron
	var greens: Array = [Color("#3F7A34"), Color("#2F6A2C"), Color("#4E8C3C")]
	var n: int = rng.randi_range(12, 20)
	for k in range(n):
		var gi: int = rng.randi_range(0, greens.size() - 1)
		var ink: Color = greens[gi]
		var vein: Color = ink.darkened(0.28)
		var s: float = rng.randf_range(22.0, 42.0)
		var cx: float = rng.randf_range(0.0, float(TEX))
		var cy: float = rng.randf_range(0.0, float(TEX))
		var ang: float = rng.randf_range(-PI, PI)
		var holes: Array = []
		var slits: float = float(rng.randi_range(2, 4))
		_stamp_leaf(img, cx, cy, s, ang, ink, vein, slits, rng.randf_range(0.10, 0.30), rng.randf_range(0.20, 0.45), holes, 1.0)
	return ImageTexture.create_from_image(img)
