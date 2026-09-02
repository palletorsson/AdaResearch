extends RefCounted

## dream_bodies / masked_dancer — a body-painted dancer in a pale animal mask, mid-turn.
##
## Reference: scratchpad/refs/friedrich_mask.png (2048x536 panorama) — a row of
## nude dancers in a grey wood, each painted head to foot in ONE pattern (a green
## diamond lattice, fine dark veins over pink, leopard blotches, flat rose) and
## wearing a pale hard shell over the face: pointed ears or a small beak, almond
## eye holes, a blue lid painted on the shell, arms swept out mid-step.
##
## Reproduced, and how:
##   1. Paint dealt by seed — one of four 128x128 ImageTextures painted pixel by
##      pixel: a rotated diamond lattice (green net + centre lozenge), a random
##      walk of 58-88 branching vein lines over pink, leopard rosettes with lobed
##      rims, or mottled rose. ONE material for the whole body with world-space
##      triplanar, so the pattern runs unbroken across every capsule and sphere.
##   2. Contrapposto and twist — the spine is 11-15 basis-scaled ellipsoid
##      spheres; the hips ride over the standing foot, the shoulders counter, the
##      waist bows sideways, and each segment is yawed along a seeded 18-40 deg
##      twist so the chest turns off the pelvis.
##   3. The sweep — one arm thrown out and up (elevation dealt -6..30 deg) to
##      about 0.55 m from the spine, the other bent in to the cheek or swept back
##      behind the hip; upper arms bow, wrists drop, each hand is a flattened
##      palm with five capsule fingers.
##   4. Mid-step legs — the weight leg nearly straight under the shifted hips,
##      the other trailing back with the heel up and the toe brushing the floor,
##      or lifted clear of it; feet are boxes toed out on their own axes.
##   5. The mask — a bent shell built with SurfaceTool: an 18x20 grid over a
##      tapering ellipsoid section, a front and a back layer plus a stitched rim,
##      with almond eye holes (and, on a full-face deal, a mouth slit) cut by
##      OMITTING cells; every gap edge gets its own rim quad.
##   6. Painted blue lid — a second thin strip of the same shell surface, sitting
##      4 mm proud, following the arc above each eye hole.
##   7. Ears or beak — two cupped leaf plates through the same shell builder,
##      with a pink inner pad, rising off the mask's temples; on some seeds a
##      cone beak with two ear nubs instead.
##   8. What shows through the holes — dark eyes on the skull behind them, and
##      lips below the shell's lower edge.
##
## Given up: the wood and the other seven dancers, the blonde figure's hair and
## headdress, skin translucency and the wet sheen of real body paint, fingernails,
## and the dark outline the reference's veins gain where they cross a fold.

const TEX: int = 128

const SKIN_BASE: Array = ["#E7EFD6", "#E9AFAB", "#E0B79C", "#DE8296"]
const SKIN_INK: Array = ["#5C8C32", "#5B3038", "#4B2A21", "#B04E68"]
const SKIN_MID: Array = ["#9DC463", "#F3CBC6", "#B9805A", "#F0AEB6"]
const SKIN_UV: Array = [2.5, 1.8, 2.1, 1.3]

const IVORY: Array = ["#F2EADE", "#EFE2D0", "#E7E6E1"]
const LID_BLUE: Array = ["#3D5FA6", "#4E79C0", "#2C4C88"]

const MASK_NU: int = 18
const MASK_NV: int = 20


static func describe() -> String:
	return "A dancer painted head to foot in one pattern — green diamond lattice, dark veins, leopard or rose — twisting mid-step with one arm swept out, face hidden behind a pale eared shell mask with a painted blue lid."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# ---- the paint ---------------------------------------------------------
	var kind: int = rng.randi_range(0, 3)
	var hex_base: String = SKIN_BASE[kind]
	var hex_ink: String = SKIN_INK[kind]
	var hex_mid: String = SKIN_MID[kind]
	var base_c := Color(hex_base)
	var ink_c := Color(hex_ink)
	var mid_c := Color(hex_mid)
	var uv_base: float = SKIN_UV[kind]
	var uv_k: float = uv_base * rng.randf_range(0.86, 1.16)

	var skin_tex: ImageTexture = null
	if kind == 0:
		skin_tex = _tex_diamond(rng, base_c, ink_c, mid_c)
	elif kind == 1:
		skin_tex = _tex_veins(rng, base_c, ink_c, mid_c)
	elif kind == 2:
		skin_tex = _tex_leopard(rng, base_c, ink_c, mid_c)
	else:
		skin_tex = _tex_rose(rng, base_c, ink_c, mid_c)

	var mat_skin := StandardMaterial3D.new()
	mat_skin.albedo_color = Color(1.0, 1.0, 1.0)
	mat_skin.albedo_texture = skin_tex
	mat_skin.uv1_triplanar = true
	mat_skin.uv1_world_triplanar = true
	mat_skin.uv1_scale = Vector3(uv_k, uv_k, uv_k)
	mat_skin.roughness = 0.58
	mat_skin.metallic = 0.0

	var hex_ivory: String = IVORY[rng.randi_range(0, IVORY.size() - 1)]
	var mat_mask := StandardMaterial3D.new()
	mat_mask.albedo_color = Color(hex_ivory)
	mat_mask.roughness = 0.31
	mat_mask.clearcoat_enabled = true
	mat_mask.clearcoat = 0.55
	mat_mask.clearcoat_roughness = 0.22

	var hex_lid: String = LID_BLUE[rng.randi_range(0, LID_BLUE.size() - 1)]
	var mat_lid := StandardMaterial3D.new()
	mat_lid.albedo_color = Color(hex_lid)
	mat_lid.roughness = 0.38

	var mat_inner := StandardMaterial3D.new()
	mat_inner.albedo_color = Color("#D98E97").lerp(base_c, 0.25)
	mat_inner.roughness = 0.55

	var mat_eye := StandardMaterial3D.new()
	mat_eye.albedo_color = Color("#2A1D1B")
	mat_eye.roughness = 0.16
	mat_eye.clearcoat_enabled = true
	mat_eye.clearcoat = 0.8

	var mat_lip := StandardMaterial3D.new()
	mat_lip.albedo_color = ink_c.lerp(Color("#9C4657"), 0.45)
	mat_lip.roughness = 0.35

	var mat_hair := StandardMaterial3D.new()
	mat_hair.albedo_color = Color("#3A2E2A").lerp(ink_c, 0.3)
	mat_hair.roughness = 0.66

	# ---- the pose ----------------------------------------------------------
	var sweep: float = 1.0 if rng.randf() < 0.5 else -1.0
	var stand: float = -sweep
	var body_k: float = rng.randf_range(0.95, 1.05)
	var twist: float = deg_to_rad(rng.randf_range(18.0, 40.0)) * sweep
	var n_spine: int = rng.randi_range(11, 15)
	var hip_y: float = 0.945 * body_k
	var sh_y: float = hip_y + rng.randf_range(0.415, 0.455) * body_k
	var hip_x: float = stand * rng.randf_range(0.030, 0.058)
	var sh_x: float = -stand * rng.randf_range(0.018, 0.052)
	var bow: float = stand * rng.randf_range(0.018, 0.042)
	var lean_z: float = rng.randf_range(-0.055, -0.008)
	var free_lift: bool = rng.randf() < 0.35
	var other_pose: int = 0 if rng.randf() < 0.55 else 1
	var arm_el: float = deg_to_rad(rng.randf_range(-6.0, 30.0))
	var head_yaw: float = deg_to_rad(rng.randf_range(-32.0, 32.0)) * sweep
	var head_tilt: float = deg_to_rad(rng.randf_range(-9.0, 15.0))
	var full_face: bool = rng.randf() < 0.55
	var beaked: bool = rng.randf() < 0.32
	var has_bun: bool = rng.randf() < 0.42

	# ---- spine -------------------------------------------------------------
	var pts: Array = []
	var yaws: Array = []
	for i in range(n_spine):
		var t: float = float(i) / float(n_spine - 1)
		var s: float = t * t * (3.0 - 2.0 * t)
		var px: float = lerpf(hip_x, sh_x, s) + bow * sin(PI * t)
		var py: float = lerpf(hip_y, sh_y, t)
		var pz: float = lean_z * s + 0.016 * sin(PI * t)
		pts.append(Vector3(px, py, pz))
		yaws.append(twist * s)

	for i in range(n_spine):
		var t: float = float(i) / float(n_spine - 1)
		var q: Vector3 = pts[i]
		var yaw: float = yaws[i]
		var rb := Basis(Vector3.UP, yaw)
		var half_w: float = _torso_w(t) * body_k
		var half_d: float = _torso_d(t) * body_k
		var sph := SphereMesh.new()
		sph.radius = 0.10
		sph.height = 0.20
		sph.radial_segments = 20
		sph.rings = 12
		var mi: MeshInstance3D = _add(root, sph, mat_skin)
		var sy: float = 0.062 * body_k / 0.10
		mi.transform = Transform3D(Basis(rb.x * (half_w / 0.10), rb.y * sy, rb.z * (half_d / 0.10)), q)

	var p_hip: Vector3 = pts[0]
	var p_top: Vector3 = pts[n_spine - 1]
	var b_hip := Basis(Vector3.UP, 0.0)
	var b_top := Basis(Vector3.UP, twist)

	# chest plates
	var i_chest: int = int(floor(float(n_spine - 1) * 0.80))
	var p_chest: Vector3 = pts[i_chest]
	var yaw_chest: float = yaws[i_chest]
	var b_chest := Basis(Vector3.UP, yaw_chest)
	for sgn in [-1.0, 1.0]:
		var sd: float = sgn
		var pec := SphereMesh.new()
		pec.radius = 0.055 * body_k
		pec.height = 0.11 * body_k
		var pm: MeshInstance3D = _add(root, pec, mat_skin)
		var pp: Vector3 = p_chest + b_chest * Vector3(sd * 0.062 * body_k, 0.004, -0.062 * body_k)
		pm.transform = Transform3D(Basis(b_chest.x * 1.18, b_chest.y * 0.72, b_chest.z * 0.62), pp)

	# seat and hip pads
	for sgn in [-1.0, 1.0]:
		var sd: float = sgn
		var glute := SphereMesh.new()
		glute.radius = 0.078 * body_k
		glute.height = 0.156 * body_k
		var gm: MeshInstance3D = _add(root, glute, mat_skin)
		var gp: Vector3 = p_hip + b_hip * Vector3(sd * 0.056 * body_k, -0.028, 0.048 * body_k)
		gm.transform = Transform3D(Basis(b_hip.x * 1.0, b_hip.y * 0.86, b_hip.z * 0.90), gp)

		var pad := SphereMesh.new()
		pad.radius = 0.070 * body_k
		pad.height = 0.14 * body_k
		var dm: MeshInstance3D = _add(root, pad, mat_skin)
		var dp: Vector3 = p_hip + b_hip * Vector3(sd * 0.082 * body_k, -0.052, 0.0)
		dm.transform = Transform3D(Basis(b_hip.x * 0.95, b_hip.y * 0.95, b_hip.z * 1.0), dp)

	# ---- neck and head -----------------------------------------------------
	var neck_dir: Vector3 = (Vector3(sin(head_yaw) * 0.12, 1.0, -0.10 - sin(head_tilt) * 0.2)).normalized()
	var neck_a: Vector3 = p_top + Vector3(0.0, 0.015, 0.0)
	var neck_b: Vector3 = neck_a + neck_dir * (0.085 * body_k)
	_bone(root, neck_a, neck_b, 0.049 * body_k, 0.044 * body_k, mat_skin)
	var neck_c: Vector3 = neck_b + neck_dir * (0.030 * body_k)
	_bone(root, neck_b, neck_c, 0.044 * body_k, 0.041 * body_k, mat_skin)

	var hb: Basis = Basis(Vector3.UP, twist + head_yaw) * Basis(Vector3.RIGHT, head_tilt)
	var head_c: Vector3 = neck_c + hb * Vector3(0.0, 0.072 * body_k, -0.012)
	var skull := SphereMesh.new()
	skull.radius = 0.098 * body_k
	skull.height = 0.196 * body_k
	skull.radial_segments = 22
	skull.rings = 14
	var skm: MeshInstance3D = _add(root, skull, mat_skin)
	skm.transform = Transform3D(Basis(hb.x * 0.92, hb.y * 1.08, hb.z * 0.99), head_c)

	var jaw := SphereMesh.new()
	jaw.radius = 0.070 * body_k
	jaw.height = 0.14 * body_k
	var jm: MeshInstance3D = _add(root, jaw, mat_skin)
	jm.transform = Transform3D(Basis(hb.x * 0.90, hb.y * 0.80, hb.z * 1.00), head_c + hb * Vector3(0.0, -0.055 * body_k, -0.020 * body_k))

	# eyes on the skull, seen through the holes
	for sgn in [-1.0, 1.0]:
		var sd: float = sgn
		var eye := SphereMesh.new()
		eye.radius = 0.019 * body_k
		eye.height = 0.038 * body_k
		var em: MeshInstance3D = _add(root, eye, mat_eye)
		em.transform = Transform3D(hb, head_c + hb * Vector3(sd * 0.040 * body_k, 0.008 * body_k, -0.082 * body_k))

	# lips below the shell
	for sgn in [-1.0, 1.0]:
		var sd: float = sgn
		var lip := SphereMesh.new()
		lip.radius = 0.017 * body_k
		lip.height = 0.034 * body_k
		var lm: MeshInstance3D = _add(root, lip, mat_lip)
		var ly: float = -0.070 * body_k + sd * 0.011 * body_k
		lm.transform = Transform3D(Basis(hb.x * 1.35, hb.y * 0.55, hb.z * 0.65), head_c + hb * Vector3(0.0, ly, -0.078 * body_k))

	if has_bun:
		var bun_c: Vector3 = head_c + hb * Vector3(0.0, 0.030 * body_k, 0.098 * body_k)
		for k in range(7):
			var fk: float = float(k) / 6.0
			var ang: float = fk * TAU + rng.randf_range(-0.2, 0.2)
			var rad: float = 0.034 * body_k * (0.55 + 0.45 * sin(fk * PI))
			var knot := SphereMesh.new()
			knot.radius = 0.028 * body_k
			knot.height = 0.056 * body_k
			var km: MeshInstance3D = _add(root, knot, mat_hair)
			km.transform = Transform3D(hb, bun_c + hb * Vector3(cos(ang) * rad, sin(ang) * rad, rng.randf_range(-0.01, 0.02)))

	# ---- legs --------------------------------------------------------------
	var thigh_l: float = 0.405 * body_k
	var shin_l: float = 0.392 * body_k
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var weight: bool = absf(sd - stand) < 0.5
		var hip_j: Vector3 = p_hip + Vector3(sd * 0.085 * body_k, -0.078 * body_k, 0.004)
		var d_thigh: Vector3 = Vector3.DOWN
		var d_shin: Vector3 = Vector3.DOWN
		if weight:
			d_thigh = Vector3(sd * rng.randf_range(0.02, 0.07), -1.0, rng.randf_range(0.01, 0.06)).normalized()
			d_shin = Vector3(sd * 0.01, -1.0, rng.randf_range(-0.08, -0.02)).normalized()
		elif free_lift:
			d_thigh = Vector3(sd * rng.randf_range(0.10, 0.22), -0.86, -rng.randf_range(0.30, 0.46)).normalized()
			d_shin = Vector3(sd * 0.04, -0.94, rng.randf_range(0.18, 0.34)).normalized()
		else:
			d_thigh = Vector3(sd * rng.randf_range(0.06, 0.16), -0.94, rng.randf_range(0.22, 0.34)).normalized()
			d_shin = Vector3(sd * 0.03, -0.86, rng.randf_range(0.36, 0.52)).normalized()
		var knee: Vector3 = hip_j + d_thigh * thigh_l
		var ankle: Vector3 = knee + d_shin * shin_l

		var mid_t: Vector3 = (hip_j + knee) * 0.5 + Vector3(sd * 0.012, 0.0, -0.012)
		_bone(root, hip_j, mid_t, 0.085 * body_k, 0.072 * body_k, mat_skin)
		_bone(root, mid_t, knee, 0.072 * body_k, 0.055 * body_k, mat_skin)
		var kn := SphereMesh.new()
		kn.radius = 0.056 * body_k
		kn.height = 0.112 * body_k
		var knm: MeshInstance3D = _add(root, kn, mat_skin)
		knm.transform = Transform3D(Basis(), knee)

		var mid_s: Vector3 = (knee + ankle) * 0.5 + Vector3(0.0, 0.0, 0.016)
		_bone(root, knee, mid_s, 0.055 * body_k, 0.049 * body_k, mat_skin)
		_bone(root, mid_s, ankle, 0.049 * body_k, 0.033 * body_k, mat_skin)
		var an := SphereMesh.new()
		an.radius = 0.036 * body_k
		an.height = 0.072 * body_k
		var anm: MeshInstance3D = _add(root, an, mat_skin)
		anm.transform = Transform3D(Basis(), ankle)

		# foot: heel block and toe block, on their own axis
		var toe_pt: Vector3 = ankle
		if weight:
			toe_pt = Vector3(ankle.x + sd * 0.026 * body_k, 0.020 * body_k, ankle.z - 0.135 * body_k)
		elif free_lift:
			var d_toe: Vector3 = Vector3(sd * 0.12, -0.42, -0.90).normalized()
			toe_pt = ankle + d_toe * (0.145 * body_k)
		else:
			# heel up, toe brushing the floor a hand's width behind the body
			var foot_l: float = 0.150 * body_k
			var drop: float = clampf(ankle.y - 0.028 * body_k, 0.03, foot_l * 0.94)
			var horiz: float = sqrt(maxf(foot_l * foot_l - drop * drop, 0.0016))
			toe_pt = ankle + Vector3(sd * 0.14 * horiz, -drop, 0.99 * horiz)

		var f_fwd: Vector3 = (toe_pt - ankle).normalized()
		var f_up: Vector3 = (Vector3.UP - f_fwd * Vector3.UP.dot(f_fwd)).normalized()
		var f_rt: Vector3 = f_fwd.cross(f_up).normalized()
		var fb := Basis(f_rt, f_up, -f_fwd)

		var heel := BoxMesh.new()
		heel.size = Vector3(0.074 * body_k, 0.062 * body_k, 0.070 * body_k)
		var hm: MeshInstance3D = _add(root, heel, mat_skin)
		hm.transform = Transform3D(fb, ankle - f_fwd * (0.026 * body_k) - f_up * (0.012 * body_k))

		var fin := BoxMesh.new()
		fin.size = Vector3(0.078 * body_k, 0.042 * body_k, 0.152 * body_k)
		var fm: MeshInstance3D = _add(root, fin, mat_skin)
		fm.transform = Transform3D(fb, (ankle + toe_pt) * 0.5 - f_up * (0.010 * body_k))

	# ---- arms --------------------------------------------------------------
	var upper_l: float = 0.272 * body_k
	var fore_l: float = 0.252 * body_k
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var sw: bool = absf(sd - sweep) < 0.5
		var sh_pt: Vector3 = p_top + b_top * Vector3(sd * 0.150 * body_k, -0.022, 0.004)
		var d_up: Vector3 = Vector3.DOWN
		var d_fo: Vector3 = Vector3.DOWN
		var curl: float = 0.0
		if sw:
			d_up = Vector3(sd * cos(arm_el), sin(arm_el), -rng.randf_range(0.10, 0.24)).normalized()
			d_fo = Vector3(sd * cos(arm_el + 0.30) * 0.92, sin(arm_el + 0.30), -rng.randf_range(0.26, 0.46)).normalized()
			curl = rng.randf_range(-0.15, 0.20)
		elif other_pose == 0:
			d_up = Vector3(sd * rng.randf_range(0.40, 0.62), -0.80, -rng.randf_range(0.10, 0.26)).normalized()
			d_fo = Vector3(-sd * rng.randf_range(0.16, 0.36), 0.86, -rng.randf_range(0.34, 0.52)).normalized()
			curl = rng.randf_range(0.30, 0.65)
		else:
			d_up = Vector3(sd * rng.randf_range(0.26, 0.44), -0.90, rng.randf_range(0.14, 0.30)).normalized()
			d_fo = Vector3(sd * rng.randf_range(0.10, 0.28), -0.72, rng.randf_range(0.50, 0.70)).normalized()
			curl = rng.randf_range(-0.30, 0.05)

		var elbow: Vector3 = sh_pt + d_up * upper_l
		var wrist: Vector3 = elbow + d_fo * fore_l

		var delt := SphereMesh.new()
		delt.radius = 0.062 * body_k
		delt.height = 0.124 * body_k
		var dm2: MeshInstance3D = _add(root, delt, mat_skin)
		dm2.transform = Transform3D(Basis(b_top.x * 1.0, b_top.y * 0.92, b_top.z * 0.94), sh_pt)

		var bow_v: Vector3 = Vector3(0.0, 0.014, -0.010) * (1.0 if sw else -1.0)
		var mid_u: Vector3 = (sh_pt + elbow) * 0.5 + bow_v
		_bone(root, sh_pt, mid_u, 0.055 * body_k, 0.048 * body_k, mat_skin)
		_bone(root, mid_u, elbow, 0.048 * body_k, 0.039 * body_k, mat_skin)
		var el := SphereMesh.new()
		el.radius = 0.040 * body_k
		el.height = 0.080 * body_k
		var elm: MeshInstance3D = _add(root, el, mat_skin)
		elm.transform = Transform3D(Basis(), elbow)

		var mid_f: Vector3 = (elbow + wrist) * 0.5 + bow_v * 0.6
		_bone(root, elbow, mid_f, 0.042 * body_k, 0.037 * body_k, mat_skin)
		_bone(root, mid_f, wrist, 0.037 * body_k, 0.026 * body_k, mat_skin)
		var wr := SphereMesh.new()
		wr.radius = 0.028 * body_k
		wr.height = 0.056 * body_k
		var wrm: MeshInstance3D = _add(root, wr, mat_skin)
		wrm.transform = Transform3D(Basis(), wrist)

		_hand(root, wrist, d_fo, sd, curl, body_k, mat_skin)

	# ---- the mask ----------------------------------------------------------
	var mask_tf := Transform3D(hb, head_c)
	var m_hw: float = 0.108 * body_k * rng.randf_range(0.96, 1.06)
	var m_ht: float = 0.088 * body_k * rng.randf_range(0.94, 1.10)
	var m_hb: float = (0.118 if full_face else 0.062) * body_k * rng.randf_range(0.94, 1.08)
	var m_dep: float = 0.116 * body_k * rng.randf_range(0.95, 1.08)
	var m_arc: float = rng.randf_range(1.14, 1.36)
	var m_th: float = 0.0095 * body_k
	var eye_u: float = rng.randf_range(0.40, 0.50)
	var eye_v: float = rng.randf_range(0.02, 0.12)
	var eye_ru: float = rng.randf_range(0.22, 0.30)
	var eye_rv: float = rng.randf_range(0.13, 0.19)

	var fr: Array = []
	var bk: Array = []
	for i in range(MASK_NU + 1):
		var rowf: Array = []
		var rowb: Array = []
		for j in range(MASK_NV + 1):
			var fu: float = -1.0 + 2.0 * float(i) / float(MASK_NU)
			var fv: float = 1.0 - 2.0 * float(j) / float(MASK_NV)
			rowf.append(_mask_pt(fu, fv, m_hw, m_ht, m_hb, m_dep, m_arc, m_th * 0.5))
			rowb.append(_mask_pt(fu, fv, m_hw, m_ht, m_hb, m_dep, m_arc, -m_th * 0.5))
		fr.append(rowf)
		bk.append(rowb)

	var solid: Array = []
	for i in range(MASK_NU):
		var rows: Array = []
		for j in range(MASK_NV):
			var fu: float = -1.0 + 2.0 * (float(i) + 0.5) / float(MASK_NU)
			var fv: float = 1.0 - 2.0 * (float(j) + 0.5) / float(MASK_NV)
			var keep: bool = true
			for sgn in [-1.0, 1.0]:
				var sd: float = sgn
				var du: float = (fu - sd * eye_u) / eye_ru
				var dv: float = (fv - eye_v) / eye_rv
				var e: float = pow(absf(du), 1.5) + pow(absf(dv), 2.2)
				if e < 1.0:
					keep = false
			if full_face:
				var mu: float = fu / 0.30
				var mv: float = (fv + 0.66) / 0.13
				var em2: float = pow(absf(mu), 1.8) + pow(absf(mv), 2.0)
				if em2 < 1.0:
					keep = false
			rows.append(keep)
		solid.append(rows)

	var mask_mesh: ArrayMesh = _shell(fr, bk, solid, MASK_NU, MASK_NV)
	var mm: MeshInstance3D = _add(root, mask_mesh, mat_mask)
	mm.transform = mask_tf

	# painted blue lid, a strip riding the arc above each eye hole
	for sgn in [-1.0, 1.0]:
		var sd: float = sgn
		var lu: int = 8
		var lv: int = 2
		var lf: Array = []
		var lb: Array = []
		for i in range(lu + 1):
			var rowf: Array = []
			var rowb: Array = []
			for j in range(lv + 1):
				var fi: float = float(i) / float(lu)
				var fj: float = float(j) / float(lv)
				var fu: float = sd * eye_u + (fi * 2.0 - 1.0) * eye_ru * 1.06
				var arch: float = sqrt(maxf(1.0 - pow(absf((fu - sd * eye_u) / (eye_ru * 1.06)), 1.5), 0.0))
				var fv0: float = eye_v + eye_rv * arch
				var fv: float = fv0 + fj * (eye_rv * 0.62)
				rowf.append(_mask_pt(fu, fv, m_hw, m_ht, m_hb, m_dep, m_arc, m_th * 0.5 + 0.0042))
				rowb.append(_mask_pt(fu, fv, m_hw, m_ht, m_hb, m_dep, m_arc, m_th * 0.5 + 0.0008))
			lf.append(rowf)
			lb.append(rowb)
		var lsolid: Array = []
		for i in range(lu):
			var rows: Array = []
			for j in range(lv):
				rows.append(true)
			lsolid.append(rows)
		var lid_mesh: ArrayMesh = _shell(lf, lb, lsolid, lu, lv)
		var lidm: MeshInstance3D = _add(root, lid_mesh, mat_lid)
		lidm.transform = mask_tf

	# ---- ears, or a beak ---------------------------------------------------
	if beaked:
		var beak_l: float = rng.randf_range(0.075, 0.115) * body_k
		var beak := CylinderMesh.new()
		beak.bottom_radius = 0.034 * body_k
		beak.top_radius = 0.004
		beak.height = beak_l
		beak.radial_segments = 12
		var bm2: MeshInstance3D = _add(root, beak, mat_mask)
		var b_dir: Vector3 = Vector3(0.0, -rng.randf_range(0.20, 0.50), -1.0).normalized()
		var b_base: Vector3 = _mask_pt(0.0, eye_v - eye_rv * 1.4, m_hw, m_ht, m_hb, m_dep, m_arc, 0.0)
		bm2.transform = mask_tf * Transform3D(_basis_y_to(b_dir), b_base + b_dir * (beak_l * 0.42))
		for sgn in [-1.0, 1.0]:
			var sd: float = sgn
			var nub := SphereMesh.new()
			nub.radius = 0.026 * body_k
			nub.height = 0.052 * body_k
			var nm: MeshInstance3D = _add(root, nub, mat_mask)
			var np: Vector3 = _mask_pt(sd * 0.86, 0.74, m_hw, m_ht, m_hb, m_dep, m_arc, 0.006)
			nm.transform = mask_tf * Transform3D(Basis(), np)
	else:
		var ear_len: float = rng.randf_range(0.098, 0.152) * body_k
		var ear_hw: float = rng.randf_range(0.034, 0.050) * body_k
		var ear_cup: float = rng.randf_range(0.10, 0.26)
		var ear_out: float = rng.randf_range(0.36, 0.62)
		for sgn in [-1.0, 1.0]:
			var sd: float = sgn
			var anchor: Vector3 = _mask_pt(sd * 0.78, 0.72, m_hw, m_ht, m_hb, m_dep, m_arc, 0.0)
			var nrm: Vector3 = _mask_nrm(sd * 0.78, 0.72, m_arc)
			var ey: Vector3 = Vector3(sd * ear_out, 1.0, 0.06).normalized()
			ey = (ey - nrm * ey.dot(nrm)).normalized()
			var ex: Vector3 = ey.cross(nrm).normalized()
			var eb := Basis(ex, ey, nrm)
			var ef: Array = []
			var eb2: Array = []
			var nu: int = 8
			var nv: int = 9
			for i in range(nu + 1):
				var rowf: Array = []
				var rowb: Array = []
				for j in range(nv + 1):
					var fu: float = -1.0 + 2.0 * float(i) / float(nu)
					var fv: float = float(j) / float(nv)
					var wid: float = ear_hw * pow(1.0 - fv, 0.62) * (1.0 + 0.30 * sin(PI * fv))
					var zz: float = ear_cup * ear_hw * fu * fu + 0.10 * ear_hw * fv
					var lp := Vector3(fu * wid, fv * ear_len, zz)
					rowf.append(anchor + eb * (lp + Vector3(0.0, 0.0, 0.0045 * body_k)))
					rowb.append(anchor + eb * (lp - Vector3(0.0, 0.0, 0.0045 * body_k)))
				ef.append(rowf)
				eb2.append(rowb)
			var esolid: Array = []
			for i in range(nu):
				var rows: Array = []
				for j in range(nv):
					rows.append(true)
				esolid.append(rows)
			var ear_mesh: ArrayMesh = _shell(ef, eb2, esolid, nu, nv)
			var earm: MeshInstance3D = _add(root, ear_mesh, mat_mask)
			earm.transform = mask_tf

			# pink inner pad, a smaller leaf standing 2 mm proud
			var pf: Array = []
			var pb: Array = []
			for i in range(nu + 1):
				var rowf: Array = []
				var rowb: Array = []
				for j in range(nv + 1):
					var fu: float = -1.0 + 2.0 * float(i) / float(nu)
					var fv: float = 0.08 + 0.78 * float(j) / float(nv)
					var wid: float = ear_hw * 0.62 * pow(1.0 - fv, 0.62) * (1.0 + 0.30 * sin(PI * fv))
					var zz: float = ear_cup * ear_hw * fu * fu + 0.10 * ear_hw * fv
					var lp := Vector3(fu * wid, fv * ear_len, zz)
					rowf.append(anchor + eb * (lp + Vector3(0.0, 0.0, 0.0072 * body_k)))
					rowb.append(anchor + eb * (lp + Vector3(0.0, 0.0, 0.0050 * body_k)))
				pf.append(rowf)
				pb.append(rowb)
			var pad_mesh: ArrayMesh = _shell(pf, pb, esolid, nu, nv)
			var padm: MeshInstance3D = _add(root, pad_mesh, mat_inner)
			padm.transform = mask_tf

	# ---- settle: fit, centre, floor ---------------------------------------
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
	var centre: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-centre.x, -box.position.y, -centre.z)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + shift)


# ---------------------------------------------------------------------------
# body helpers

static func _torso_w(t: float) -> float:
	var keys: Array = [0.128, 0.112, 0.108, 0.126, 0.140, 0.138]
	return _key(keys, t)


static func _torso_d(t: float) -> float:
	var keys: Array = [0.092, 0.082, 0.078, 0.090, 0.094, 0.086]
	return _key(keys, t)


static func _key(keys: Array, t: float) -> float:
	var n: int = keys.size() - 1
	var f: float = clampf(t, 0.0, 1.0) * float(n)
	var i: int = int(floor(f))
	if i >= n:
		var last: float = keys[n]
		return last
	var u: float = f - float(i)
	var va: float = keys[i]
	var vb: float = keys[i + 1]
	return lerpf(va, vb, u * u * (3.0 - 2.0 * u))


static func _hand(root: Node3D, wrist: Vector3, fdir: Vector3, sd: float, curl: float, body_k: float, mat: StandardMaterial3D) -> void:
	var hy: Vector3 = fdir.normalized()
	var ref_v: Vector3 = Vector3.UP if absf(hy.dot(Vector3.UP)) < 0.88 else Vector3.FORWARD
	var hx: Vector3 = ref_v.cross(hy).normalized()
	var hz: Vector3 = hx.cross(hy).normalized()

	var palm := SphereMesh.new()
	palm.radius = 0.040 * body_k
	palm.height = 0.080 * body_k
	var pm: MeshInstance3D = _add(root, palm, mat)
	pm.transform = Transform3D(Basis(hx * 1.10, hy * 1.30, hz * 0.52), wrist + hy * (0.046 * body_k))

	for f in range(4):
		var ff: float = float(f) - 1.5
		var spread: float = ff * 0.20
		var d: Vector3 = (hy * cos(curl) + hz * sin(curl) + hx * spread * 0.55).normalized()
		var a: Vector3 = wrist + hy * (0.084 * body_k) + hx * (ff * 0.019 * body_k)
		var ln: float = (0.072 - absf(ff) * 0.008) * body_k
		var b: Vector3 = a + d * ln
		var fin := CapsuleMesh.new()
		fin.radius = 0.0085 * body_k
		fin.height = ln + 0.017 * body_k
		fin.radial_segments = 8
		fin.rings = 3
		var fm: MeshInstance3D = _add(root, fin, mat)
		fm.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)

	var td: Vector3 = (hx * (-sd * 0.86) + hy * 0.44 + hz * 0.20).normalized()
	var ta: Vector3 = wrist + hy * (0.034 * body_k) + hx * (-sd * 0.026 * body_k)
	var tb: Vector3 = ta + td * (0.056 * body_k)
	var thumb := CapsuleMesh.new()
	thumb.radius = 0.0105 * body_k
	thumb.height = 0.056 * body_k + 0.021 * body_k
	thumb.radial_segments = 8
	thumb.rings = 3
	var tm: MeshInstance3D = _add(root, thumb, mat)
	tm.transform = Transform3D(_basis_y_to(td), (ta + tb) * 0.5)


static func _bone(root: Node3D, a: Vector3, b: Vector3, r0: float, r1: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.004)
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = r0
	cyl.top_radius = r1
	cyl.height = ln
	cyl.radial_segments = 14
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


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
# shell builder — front layer, back layer, stitched rim around every gap

static func _mask_pt(fu: float, fv: float, hw: float, ht: float, hb: float, dep: float, arc: float, off: float) -> Vector3:
	var down: float = clampf(-fv, 0.0, 1.0)
	var up: float = clampf(fv, 0.0, 1.0)
	var taper: float = 1.0 - 0.50 * pow(down, 1.6)
	var crown: float = 1.0 - 0.22 * pow(up, 2.2)
	var wid: float = hw * taper * crown
	var yy: float = ht * fv if fv >= 0.0 else hb * fv
	var bulge: float = 1.0 - 0.34 * fv * fv
	var ang: float = fu * arc
	var xx: float = sin(ang) * wid
	var zz: float = -dep * cos(ang) * bulge
	var nrm: Vector3 = _mask_nrm(fu, fv, arc)
	return Vector3(xx, yy, zz) + nrm * off


static func _mask_nrm(fu: float, fv: float, arc: float) -> Vector3:
	var ang: float = fu * arc
	return Vector3(sin(ang) * 0.88, -0.30 * fv, -cos(ang)).normalized()


static func _shell(fr: Array, bk: Array, solid: Array, nu: int, nv: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(nu):
		for j in range(nv):
			if not _solid_at(solid, nu, nv, i, j):
				continue
			var f00: Vector3 = _grid(fr, i, j)
			var f10: Vector3 = _grid(fr, i + 1, j)
			var f11: Vector3 = _grid(fr, i + 1, j + 1)
			var f01: Vector3 = _grid(fr, i, j + 1)
			var b00: Vector3 = _grid(bk, i, j)
			var b10: Vector3 = _grid(bk, i + 1, j)
			var b11: Vector3 = _grid(bk, i + 1, j + 1)
			var b01: Vector3 = _grid(bk, i, j + 1)
			var cf: Vector3 = (f00 + f10 + f11 + f01) * 0.25
			var cb: Vector3 = (b00 + b10 + b11 + b01) * 0.25
			var out_n: Vector3 = (cf - cb).normalized()
			var mid: Vector3 = (cf + cb) * 0.5
			_quad_n(st, f00, f10, f11, f01, out_n)
			_quad_n(st, b00, b10, b11, b01, -out_n)
			if not _solid_at(solid, nu, nv, i - 1, j):
				_rim(st, f00, f01, b01, b00, mid)
			if not _solid_at(solid, nu, nv, i + 1, j):
				_rim(st, f10, f11, b11, b10, mid)
			if not _solid_at(solid, nu, nv, i, j - 1):
				_rim(st, f00, f10, b10, b00, mid)
			if not _solid_at(solid, nu, nv, i, j + 1):
				_rim(st, f01, f11, b11, b01, mid)
	st.generate_normals()
	return st.commit()


static func _grid(g: Array, i: int, j: int) -> Vector3:
	var row: Array = g[i]
	var v: Vector3 = row[j]
	return v


static func _solid_at(solid: Array, nu: int, nv: int, i: int, j: int) -> bool:
	if i < 0 or j < 0 or i >= nu or j >= nv:
		return false
	var row: Array = solid[i]
	var b: bool = row[j]
	return b


static func _rim(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, inner: Vector3) -> void:
	var mid: Vector3 = (a + b + c + d) * 0.25
	var want: Vector3 = (mid - inner)
	if want.length() < 0.00001:
		want = Vector3.UP
	_quad_n(st, a, b, c, d, want.normalized())


static func _quad_n(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, want: Vector3) -> void:
	var n_front: Vector3 = (c - a).cross(b - a)
	if n_front.dot(want) >= 0.0:
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


# ---------------------------------------------------------------------------
# painted skins

static func _tex_diamond(rng: RandomNumberGenerator, base: Color, ink: Color, mid: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var cells: float = float(rng.randi_range(6, 9))
	var net: float = rng.randf_range(0.64, 0.76)
	var core: float = rng.randf_range(0.26, 0.40)
	var jitter: Array = []
	for k in range(64):
		jitter.append(rng.randf_range(0.90, 1.06))
	for y in range(TEX):
		for x in range(TEX):
			var u: float = float(x) / float(TEX) * cells
			var v: float = float(y) / float(TEX) * cells
			var a: float = u + v
			var b: float = u - v
			var fa: float = absf(a - floorf(a) - 0.5) * 2.0
			var fb: float = absf(b - floorf(b) - 0.5) * 2.0
			var m: float = maxf(fa, fb)
			# cell index folded by the tile period, so the lattice stays seamless
			var ci: int = int(cells)
			var ia: int = posmod(int(floorf(a)), ci)
			var ib: int = posmod(int(floorf(b)), ci)
			var jt: float = jitter[posmod(ia * 11 + ib, 64)]
			var col: Color = base
			var e_net: float = clampf((m - net) / 0.10, 0.0, 1.0)
			var e_core: float = clampf((core - m) / 0.14, 0.0, 1.0)
			col = base.lerp(mid, e_core * 0.92)
			col = col.lerp(ink, e_net)
			var shade: float = clampf(jt * (0.94 + 0.10 * (1.0 - fb)), 0.7, 1.12)
			img.set_pixel(x, y, Color(clampf(col.r * shade, 0.0, 1.0), clampf(col.g * shade, 0.0, 1.0), clampf(col.b * shade, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


static func _tex_veins(rng: RandomNumberGenerator, base: Color, ink: Color, mid: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	# integer frequencies keep the ground mottle seamless across the tile
	var wx: float = float(rng.randi_range(1, 3))
	var wy: float = float(rng.randi_range(2, 4))
	for y in range(TEX):
		for x in range(TEX):
			var fx: float = float(x) / float(TEX) * TAU
			var fy: float = float(y) / float(TEX) * TAU
			var n: float = 0.5 + 0.26 * sin(fx * wx + 0.7) + 0.24 * sin(fy * wy + 1.9)
			img.set_pixel(x, y, base.lerp(mid, clampf(n * 0.55, 0.0, 1.0)))
	var n_walks: int = rng.randi_range(58, 88)
	for k in range(n_walks):
		var px: float = rng.randf() * float(TEX)
		var py: float = rng.randf() * float(TEX)
		var ang: float = rng.randf() * TAU
		var steps: int = rng.randi_range(50, 150)
		var wobble: float = rng.randf_range(0.16, 0.34)
		var strength: float = rng.randf_range(0.45, 0.85)
		for s in range(steps):
			ang += rng.randf_range(-wobble, wobble)
			px += cos(ang)
			py += sin(ang)
			var ix: int = posmod(int(roundf(px)), TEX)
			var iy: int = posmod(int(roundf(py)), TEX)
			img.set_pixel(ix, iy, img.get_pixel(ix, iy).lerp(ink, strength))
			var jx: int = posmod(ix + 1, TEX)
			var jy: int = posmod(iy + 1, TEX)
			img.set_pixel(jx, iy, img.get_pixel(jx, iy).lerp(ink, strength * 0.28))
			img.set_pixel(ix, jy, img.get_pixel(ix, jy).lerp(ink, strength * 0.28))
	return ImageTexture.create_from_image(img)


static func _tex_leopard(rng: RandomNumberGenerator, base: Color, ink: Color, mid: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	for y in range(TEX):
		for x in range(TEX):
			var fx: float = float(x) / float(TEX) * TAU
			var fy: float = float(y) / float(TEX) * TAU
			var n: float = 0.5 + 0.3 * sin(fx * 2.0 + 1.1) * sin(fy * 3.0 + 0.4)
			img.set_pixel(x, y, base.lerp(mid, clampf(n * 0.6, 0.0, 1.0)))
	var n_spots: int = rng.randi_range(26, 42)
	for k in range(n_spots):
		var cx: int = rng.randi_range(0, TEX - 1)
		var cy: int = rng.randi_range(0, TEX - 1)
		var rr: float = rng.randf_range(6.5, 15.0)
		var wob: float = rng.randf_range(0.16, 0.42)
		var ph: float = rng.randf() * TAU
		var lobes: float = float(rng.randi_range(3, 5))
		var filled: bool = rng.randf() < 0.38
		var span: int = int(ceilf(rr * 1.6)) + 2
		for dy in range(-span, span + 1):
			for dx in range(-span, span + 1):
				var d: float = sqrt(float(dx * dx + dy * dy))
				var a: float = atan2(float(dy), float(dx))
				var rad: float = rr * (1.0 + wob * sin(a * lobes + ph))
				var t: float = d / maxf(rad, 0.5)
				if t >= 1.0:
					continue
				var col: Color = ink
				if not filled and t < 0.52:
					col = base.lerp(ink, 0.22)
				var f: float = clampf((1.0 - t) / 0.20, 0.0, 1.0)
				var px: int = posmod(cx + dx, TEX)
				var py: int = posmod(cy + dy, TEX)
				img.set_pixel(px, py, img.get_pixel(px, py).lerp(col, f))
	return ImageTexture.create_from_image(img)


static func _tex_rose(rng: RandomNumberGenerator, base: Color, ink: Color, mid: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var w1: float = float(rng.randi_range(1, 3))
	var w2: float = float(rng.randi_range(2, 4))
	var w3: float = float(rng.randi_range(3, 6))
	var amp: float = rng.randf_range(0.10, 0.26)
	for y in range(TEX):
		for x in range(TEX):
			var fx: float = float(x) / float(TEX) * TAU
			var fy: float = float(y) / float(TEX) * TAU
			var n: float = 0.5 + 0.5 * (0.5 * sin(fx * w1 + 0.3) + 0.3 * sin(fy * w2 + 1.7) + 0.2 * sin((fx + fy) * w3))
			var col: Color = base.lerp(mid, clampf(n * amp * 3.0, 0.0, 1.0))
			col = col.lerp(ink, clampf((n - 0.86) * 2.2, 0.0, 0.35))
			var grain: float = rng.randf_range(0.975, 1.025)
			img.set_pixel(x, y, Color(clampf(col.r * grain, 0.0, 1.0), clampf(col.g * grain, 0.0, 1.0), clampf(col.b * grain, 0.0, 1.0)))
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
