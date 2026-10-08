extends RefCounted

## dream_bodies / deity_figurine — one dancing temple deity, many-armed, painted
## pink and cream.
##
## Reference (described this pass, no image): pink-and-cream painted temple
## figurines standing against carved grey stone — dancing deities with four to six
## arms, cream skin and hot-pink limbs, saffron drapery falling in narrow pleats
## from the hip, heavy gold jewellery (armlets, anklets, layered necklaces, a tall
## crown), one of them elephant-headed with a curling trunk, big fan ears and
## small tusks. The poses are dance: hip thrown out, one knee lifted and crossed,
## arms fanned around the body each holding a small attribute.
##
## Reproduced, and how:
##   1. Tribhanga — the spine is 13..16 basis-scaled ellipsoids on a three-bend
##      curve: hips thrown to the weight side, the waist bowing back through it,
##      the chest carried over the other foot, every ring yawed so the shoulders
##      turn off the pelvis, and the head tipped BACK, rolled and turned.
##   2. Four or six arms (dealt by seed) fanned around the torso from about +70
##      deg down to -34 deg of elevation, each sprouting from a different spine
##      ring between the low ribs and the shoulder; each has a bowed upper bone,
##      an elbow ball, a forearm turned to its own angle, a wrist and a small palm
##      with three fingers and a thumb.
##   3. Attributes — every hand is dealt one of six: a chakra disc, a lotus bud
##      with three petals, a conch, a bell, a goad, or an empty open palm.
##   4. Elephant head, one seed in three — a wide skull and brow dome, a trunk of
##      11..15 tapering capsules whose BEND AXIS rotates a little each segment so
##      the curl spirals rather than closing flat, two small curving tusks with
##      gold bands, and two fan ears as thin double-sided SurfaceTool plates that
##      widen outward, droop at the lower corner and curl back at a wavy rim.
##   5. Otherwise a cream head — skull, jaw, nose, painted eyes, brows, lips, ears
##      with gold rings and a jewel tilaka — under a tall crown of 3..5 stacked
##      gold-and-jewel tori, a cone tier and a finial.
##   6. Saffron pleated skirt — ONE SurfaceTool surface whose radius is corrugated
##      by 12..20 pleats, the corrugation deepening from waist to hem while the
##      fold lines twist as they fall; the hem is cut back over the lifted knee
##      and the whole skirt swings to the weight side. A second gold surface rides
##      the last tenth, 6 mm proud, as the hem band.
##   7. Gold ornament at metallic 0.9 — an armlet and a bangle on every arm, a
##      girdle with hanging bells, three layered necklaces with a bead strand and
##      a pendant, and paired anklets: 30..40 small tori and beads in all.
##   8. Painted surfaces — a plaster texture (warm mottle plus hairline crackle)
##      run world-triplanar so cream and pink parts share one unbroken skin across
##      the whole capsule chain, a striped saffron cloth on the skirt's own UVs,
##      and a hammered ground under every gold piece.
##
## Given up: the carved grey stone behind and the rest of the row, cloth that
## really drapes around the lifted knee (the hem is CUT, not folded, over it),
## fingernails and painted eyeliner, the worn edges of the gold leaf, and the
## second and third figurines' different attributes.
##
## AXES
##   manifestation — how many bodies the one body is, and whether it still has
##     flesh: dancing (as cast) · multiplied (eight arms and a trinity of heads,
##     two smaller skulls budding off the neck) · blooming (every attribute
##     opens into a seven-petalled blossom, the hands splay, the crown flowers)
##     · fossilised (every fleshy mesh squeezed to 0.34 of its width and depth
##     so the figure becomes a bone armature, the full-size gold hoops left
##     hanging off it, plus seven rib rings around the empty chest).
##   drapery — what the saffron cloth has become: pleats (the corrugated skirt)
##     · flood (the pleats fuse into one smooth pour that reaches the floor and
##     spreads into a pool, the legs submerged) · threads (the cloth unravels
##     into thirty twisting ribbons falling almost to the feet) · flame (the
##     cloth has burnt off and twenty tongues rise from the bare hips).

const TEX: int = 128

# scheme: [cream, hot pink, saffron, gold, dark gold, jewel]
const SCHEMES: Array = [
	["#F6E7CE", "#E8467F", "#F2A93B", "#D9A62E", "#8F6412", "#C8305E"],
	["#F9EEDC", "#F0559A", "#EFB047", "#E0B443", "#9E6E15", "#B8336A"],
	["#F2E1C6", "#DB3B72", "#E89B2A", "#CE9A25", "#8A5F10", "#D94F8C"],
]


static func describe() -> String:
	return "A many-armed temple deity dancing in tribhanga — cream skin and hot-pink limbs, a saffron skirt of narrow pleats, heavy gold ornament, and by seed an elephant head with a spiralling trunk and fan ears."


static func axes() -> Dictionary:
	return {
		"manifestation": ["dancing", "multiplied", "blooming", "fossilised"],
		"drapery": ["pleats", "flood", "threads", "flame"],
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var manifestation: String = String(opts.get("manifestation", "dancing"))
	var drapery: String = String(opts.get("drapery", "pleats"))
	var m_mult: bool = manifestation == "multiplied"
	var m_bloom: bool = manifestation == "blooming"
	var m_foss: bool = manifestation == "fossilised"

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# ---- paint -------------------------------------------------------------
	var scheme: Array = SCHEMES[rng.randi_range(0, SCHEMES.size() - 1)]
	var col_cream: Color = _c(scheme, 0)
	var col_pink: Color = _c(scheme, 1)
	var col_cloth: Color = _c(scheme, 2)
	var col_gold: Color = _c(scheme, 3)
	var col_gold_dk: Color = _c(scheme, 4)
	var col_jewel: Color = _c(scheme, 5)

	var skin_tex: ImageTexture = _tex_plaster(rng)
	var cloth_tex: ImageTexture = _tex_cloth(rng)
	var gold_tex: ImageTexture = _tex_hammer(rng)
	var uv_k: float = rng.randf_range(1.6, 2.6)

	var mat_cream: StandardMaterial3D = _paint(col_cream, skin_tex, uv_k)
	var mat_pink: StandardMaterial3D = _paint(col_pink, skin_tex, uv_k)
	var mat_hide: StandardMaterial3D = _paint(col_pink.lerp(Color("#CBA3A9"), 0.54), skin_tex, uv_k)
	var mat_ivory: StandardMaterial3D = _paint(col_cream.lerp(Color("#FFFFFF"), 0.45), skin_tex, uv_k * 0.65)
	var mat_dark: StandardMaterial3D = _paint(Color("#2C1A16"), null, 1.0)
	mat_dark.roughness = 0.13
	var mat_lip: StandardMaterial3D = _paint(col_pink.lerp(Color("#8E2144"), 0.32), null, 1.0)
	var mat_jewel: StandardMaterial3D = _paint(col_jewel, null, 1.0)
	var mat_gold: StandardMaterial3D = _metal(col_gold, gold_tex, uv_k * 1.4)
	var mat_gold_dk: StandardMaterial3D = _metal(col_gold_dk, gold_tex, uv_k * 1.9)

	var mat_cloth := StandardMaterial3D.new()
	mat_cloth.albedo_color = col_cloth
	mat_cloth.albedo_texture = cloth_tex
	mat_cloth.uv1_scale = Vector3(1.0, 1.0, 1.0)
	mat_cloth.roughness = 0.44
	mat_cloth.metallic = 0.0
	mat_cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_cloth.clearcoat_enabled = true
	mat_cloth.clearcoat = 0.30
	mat_cloth.clearcoat_roughness = 0.35

	# petal cloth for the blooming manifestation
	var mat_petal: StandardMaterial3D = _paint(col_jewel.lerp(Color("#FFFFFF"), 0.24), skin_tex, uv_k * 2.4)
	mat_petal.roughness = 0.30
	mat_petal.cull_mode = BaseMaterial3D.CULL_DISABLED

	# burnt cloth for the flame drapery
	var mat_flame := StandardMaterial3D.new()
	mat_flame.albedo_color = col_cloth.lerp(Color("#FFF2C4"), 0.40)
	mat_flame.albedo_texture = cloth_tex
	mat_flame.uv1_triplanar = true
	mat_flame.uv1_world_triplanar = true
	mat_flame.uv1_scale = Vector3(3.2, 3.2, 3.2)
	mat_flame.roughness = 0.50
	mat_flame.metallic = 0.0
	mat_flame.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_flame.emission_enabled = true
	mat_flame.emission = col_cloth.lerp(Color("#FFFFFF"), 0.34)
	mat_flame.emission_energy_multiplier = 0.85

	# dry bone for the fossilised manifestation — the paint and the flesh gone
	var mat_bone: StandardMaterial3D = _paint(Color("#E7DFC8"), skin_tex, uv_k * 1.7)
	mat_bone.roughness = 0.66
	mat_bone.clearcoat_enabled = false
	if m_foss:
		mat_cream = mat_bone
		mat_pink = mat_bone
		mat_hide = mat_bone
		mat_ivory = mat_bone
		mat_dark = mat_gold_dk
		mat_lip = mat_gold_dk

	# ---- the pose ----------------------------------------------------------
	var body_k: float = rng.randf_range(0.96, 1.05)
	var hip_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var n_arms: int = 4 if rng.randf() < 0.5 else 6
	var elephant: bool = rng.randf() < 0.34
	var legs_pink: bool = rng.randf() < 0.62
	var n_spine: int = rng.randi_range(13, 16)
	if m_mult:
		# the multiplied body pays for its extra arms and heads with a shorter
		# spine, so the mesh budget holds
		n_arms = 8
		n_spine = mini(n_spine, 11)

	var hip_y: float = 0.845 * body_k
	var sh_y: float = hip_y + rng.randf_range(0.392, 0.424) * body_k
	var hip_x: float = hip_side * rng.randf_range(0.052, 0.082)
	var sh_x: float = -hip_side * rng.randf_range(0.026, 0.058)
	var waist_bow: float = hip_side * rng.randf_range(0.020, 0.042)
	var hip_yaw: float = -hip_side * rng.randf_range(0.09, 0.21)
	var sh_yaw: float = hip_side * rng.randf_range(0.20, 0.38)
	var lean_z: float = rng.randf_range(-0.048, 0.008)
	var head_yaw: float = hip_side * deg_to_rad(rng.randf_range(9.0, 30.0))
	var head_back: float = deg_to_rad(rng.randf_range(7.0, 20.0))
	var head_roll: float = -hip_side * deg_to_rad(rng.randf_range(4.0, 14.0))

	# ---- spine -------------------------------------------------------------
	var pts: Array = []
	var yaws: Array = []
	for i in range(n_spine):
		var t: float = float(i) / float(n_spine - 1)
		var s: float = t * t * (3.0 - 2.0 * t)
		var px: float = lerpf(hip_x, sh_x, s) + waist_bow * sin(PI * t)
		var py: float = lerpf(hip_y, sh_y, t)
		var pz: float = lean_z * s + 0.018 * sin(PI * t)
		pts.append(Vector3(px, py, pz))
		yaws.append(lerpf(hip_yaw, sh_yaw, s))

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
		var mi: MeshInstance3D = _add(root, sph, mat_cream)
		var sy: float = 0.060 * body_k / 0.10
		mi.transform = Transform3D(Basis(rb.x * (half_w / 0.10), rb.y * sy, rb.z * (half_d / 0.10)), q)

	var p_hip: Vector3 = pts[0]
	var p_top: Vector3 = pts[n_spine - 1]
	var b_hip := Basis(Vector3.UP, hip_yaw)
	var b_top := Basis(Vector3.UP, sh_yaw)

	# breast plates and belly
	var i_chest: int = int(floor(float(n_spine - 1) * 0.80))
	var p_chest: Vector3 = pts[i_chest]
	var yaw_chest: float = yaws[i_chest]
	var b_chest := Basis(Vector3.UP, yaw_chest)
	for sgn in [-1.0, 1.0]:
		var sd: float = sgn
		var pec := SphereMesh.new()
		pec.radius = 0.054 * body_k
		pec.height = 0.108 * body_k
		var pm: MeshInstance3D = _add(root, pec, mat_cream)
		var pp: Vector3 = p_chest + b_chest * Vector3(sd * 0.060 * body_k, 0.004, -0.058 * body_k)
		pm.transform = Transform3D(Basis(b_chest.x * 1.16, b_chest.y * 0.74, b_chest.z * 0.64), pp)

	var i_belly: int = int(floor(float(n_spine - 1) * 0.26))
	var p_belly: Vector3 = pts[i_belly]
	var yaw_belly: float = yaws[i_belly]
	var belly := SphereMesh.new()
	belly.radius = 0.058 * body_k
	belly.height = 0.116 * body_k
	var bem: MeshInstance3D = _add(root, belly, mat_cream)
	bem.transform = Transform3D(Basis(Vector3.UP, yaw_belly).scaled(Vector3(1.06, 0.80, 0.72)), p_belly + Vector3(0.0, 0.0, -0.048 * body_k))

	# seat and hip pads
	for sgn in [-1.0, 1.0]:
		var sd: float = sgn
		var glute := SphereMesh.new()
		glute.radius = 0.074 * body_k
		glute.height = 0.148 * body_k
		var gm: MeshInstance3D = _add(root, glute, mat_cream)
		gm.transform = Transform3D(Basis(b_hip.x * 1.0, b_hip.y * 0.86, b_hip.z * 0.92), p_hip + b_hip * Vector3(sd * 0.054 * body_k, -0.030, 0.046 * body_k))

		var pad := SphereMesh.new()
		pad.radius = 0.068 * body_k
		pad.height = 0.136 * body_k
		var dm: MeshInstance3D = _add(root, pad, mat_cream)
		dm.transform = Transform3D(Basis(b_hip.x * 0.96, b_hip.y * 0.94, b_hip.z * 1.0), p_hip + b_hip * Vector3(sd * 0.080 * body_k, -0.052, 0.0))

	# ---- legs: one standing, one knee lifted and crossed -------------------
	var mat_leg: StandardMaterial3D = mat_pink if legs_pink else mat_cream
	var thigh_l: float = 0.352 * body_k
	var shin_l: float = 0.348 * body_k
	var lift_lean: float = rng.randf_range(0.26, 0.44)
	var lift_cross: float = rng.randf_range(0.34, 0.56)
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var weight: bool = absf(sd - hip_side) < 0.5
		var hip_j: Vector3 = p_hip + b_hip * Vector3(sd * 0.082 * body_k, -0.076 * body_k, 0.004)
		var d_thigh := Vector3.DOWN
		var d_shin := Vector3.DOWN
		if weight:
			d_thigh = Vector3(sd * rng.randf_range(0.02, 0.07), -1.0, rng.randf_range(0.00, 0.05)).normalized()
			d_shin = Vector3(sd * 0.02, -1.0, rng.randf_range(-0.07, -0.01)).normalized()
		else:
			d_thigh = Vector3(sd * rng.randf_range(0.18, 0.32), -lift_lean, -rng.randf_range(0.72, 0.92)).normalized()
			d_shin = Vector3(-sd * lift_cross, -0.86, rng.randf_range(0.14, 0.34)).normalized()
		var knee: Vector3 = hip_j + d_thigh * thigh_l
		var ankle: Vector3 = knee + d_shin * shin_l

		var mid_t: Vector3 = (hip_j + knee) * 0.5 + Vector3(sd * 0.012, 0.0, -0.012)
		_bone(root, hip_j, mid_t, 0.082 * body_k, 0.070 * body_k, mat_leg)
		_bone(root, mid_t, knee, 0.070 * body_k, 0.052 * body_k, mat_leg)
		_ball(root, knee, 0.053 * body_k, Basis(), mat_leg)

		var mid_s: Vector3 = (knee + ankle) * 0.5 + Vector3(0.0, 0.0, 0.014)
		_bone(root, knee, mid_s, 0.052 * body_k, 0.046 * body_k, mat_leg)
		_bone(root, mid_s, ankle, 0.046 * body_k, 0.031 * body_k, mat_leg)

		# foot
		var toe_pt: Vector3 = ankle
		if weight:
			toe_pt = Vector3(ankle.x + sd * 0.030 * body_k, 0.020 * body_k, ankle.z - 0.132 * body_k)
		else:
			var d_toe: Vector3 = Vector3(-sd * 0.22, -0.86, 0.46).normalized()
			toe_pt = ankle + d_toe * (0.140 * body_k)
		var f_fwd: Vector3 = (toe_pt - ankle).normalized()
		var f_up: Vector3 = (Vector3.UP - f_fwd * Vector3.UP.dot(f_fwd)).normalized()
		var f_rt: Vector3 = f_fwd.cross(f_up).normalized()
		var fb := Basis(f_rt, f_up, -f_fwd)

		var heel := BoxMesh.new()
		heel.size = Vector3(0.070 * body_k, 0.058 * body_k, 0.064 * body_k)
		var hm: MeshInstance3D = _add(root, heel, mat_leg)
		hm.transform = Transform3D(fb, ankle - f_fwd * (0.024 * body_k) - f_up * (0.010 * body_k))

		var fin := BoxMesh.new()
		fin.size = Vector3(0.074 * body_k, 0.040 * body_k, 0.146 * body_k)
		var fm: MeshInstance3D = _add(root, fin, mat_leg)
		fm.transform = Transform3D(fb, (ankle + toe_pt) * 0.5 - f_up * (0.009 * body_k))

		# anklets
		_ring(root, ankle + d_shin * (0.014 * body_k), d_shin, 0.031 * body_k, 0.045 * body_k, mat_gold)
		_ring(root, ankle - d_shin * (0.030 * body_k), d_shin, 0.033 * body_k, 0.048 * body_k, mat_gold_dk)

	# ---- the saffron skirt -------------------------------------------------
	var n_pleats: int = rng.randi_range(12, 20)
	var skirt_len: float = rng.randf_range(0.50, 0.60) * body_k
	var r_waist: float = rng.randf_range(0.128, 0.145) * body_k
	var r_hem: float = rng.randf_range(0.205, 0.245) * body_k
	var skirt_twist: float = hip_side * rng.randf_range(0.20, 0.44)
	var cut: float = rng.randf_range(0.26, 0.40)
	var cut_ang: float = atan2(-hip_side * 0.55, -0.84)
	var swing := Vector3(hip_side * rng.randf_range(0.035, 0.070), 0.0, rng.randf_range(0.020, 0.055))
	var hip_c: Vector3 = p_hip + Vector3(0.0, -0.028 * body_k, 0.0)

	if drapery == "flood":
		# the pleats fuse into one pour that runs to the floor and spreads
		var pour_len: float = maxf(hip_c.y - 0.022 * body_k, 0.30)
		var pour_hem: float = 0.385 * body_k
		var pour_pl: int = maxi(n_pleats / 4, 3)
		var pour_sw: Vector3 = swing * 0.32
		var pour: ArrayMesh = _skirt_surface(hip_c, pour_sw, hip_yaw, pour_pl, pour_len, r_waist, pour_hem, cut_ang, 0.0, skirt_twist * 0.22, 0.0, 1.0, 16, 0.0, float(pour_pl), 0.20, 2.40)
		var pom: MeshInstance3D = _add(root, pour, mat_cloth)
		pom.transform = Transform3D()
		var pband: ArrayMesh = _skirt_surface(hip_c, pour_sw, hip_yaw, pour_pl, pour_len, r_waist, pour_hem, cut_ang, 0.0, skirt_twist * 0.22, 0.90, 1.0, 3, 0.007 * body_k, float(pour_pl), 0.20, 2.40)
		var pbm: MeshInstance3D = _add(root, pband, mat_gold)
		pbm.transform = Transform3D()
		var pool_c := Vector3(hip_c.x + pour_sw.x, hip_c.y - pour_len, hip_c.z + pour_sw.z)
		var pool := CylinderMesh.new()
		pool.bottom_radius = pour_hem * 1.14
		pool.top_radius = pour_hem * 1.02
		pool.height = 0.028 * body_k
		pool.radial_segments = 28
		var plm: MeshInstance3D = _add(root, pool, mat_cloth)
		plm.transform = Transform3D(Basis(), pool_c + Vector3(0.0, 0.014 * body_k, 0.0))
		for k in range(3):
			var fk: float = float(k) / 2.0
			var rr2: float = pour_hem * lerpf(1.16, 1.40, fk)
			_ring(root, pool_c + Vector3(0.0, 0.010 * body_k, 0.0), Vector3.UP, rr2, rr2 + 0.018 * body_k, mat_cloth)
	elif drapery == "threads":
		# the cloth has come apart into ribbons that twist as they fall
		var n_str: int = 30
		var njt: int = 7
		var fall: float = maxf(hip_c.y - 0.070 * body_k, 0.24)
		var stt := SurfaceTool.new()
		stt.begin(Mesh.PRIMITIVE_TRIANGLES)
		var tips: Array = []
		for s in range(n_str):
			var fs: float = float(s) / float(n_str)
			var th: float = TAU * fs
			var ln_s: float = fall * (0.44 + 0.54 * absf(sin(fs * 11.0 + 1.3)))
			var spin: float = skirt_twist * 2.4 + sin(fs * 7.0) * 1.5
			var out_s: float = 0.055 * body_k + 0.105 * body_k * absf(sin(fs * 5.0))
			var hw: float = 0.015 * body_k * (0.58 + 0.84 * absf(cos(fs * 9.0)))
			for j in range(njt):
				var t0: float = float(j) / float(njt)
				var t1: float = float(j + 1) / float(njt)
				var a0: Vector3 = _thread_pt(hip_c, swing, hip_yaw, th, t0, ln_s, r_waist, out_s, spin, hw, -1.0)
				var a1: Vector3 = _thread_pt(hip_c, swing, hip_yaw, th, t0, ln_s, r_waist, out_s, spin, hw, 1.0)
				var b1: Vector3 = _thread_pt(hip_c, swing, hip_yaw, th, t1, ln_s, r_waist, out_s, spin, hw, 1.0)
				var b0: Vector3 = _thread_pt(hip_c, swing, hip_yaw, th, t1, ln_s, r_waist, out_s, spin, hw, -1.0)
				var cen: Vector3 = (a0 + a1 + b0 + b1) * 0.25
				var want := Vector3(cen.x - hip_c.x, 0.0, cen.z - hip_c.z)
				if want.length() < 0.0001:
					want = Vector3.RIGHT
				_quad_n(stt, a0, a1, b1, b0, want.normalized())
			tips.append(_thread_pt(hip_c, swing, hip_yaw, th, 1.0, ln_s, r_waist, out_s, spin, hw, 0.0))
		stt.generate_normals()
		var thm: MeshInstance3D = _add(root, stt.commit(), mat_cloth)
		thm.transform = Transform3D()
		for k in range(5):
			var ti: int = clampi(int(float(k) * float(n_str) / 5.0) + 1, 0, tips.size() - 1)
			var tp2: Vector3 = tips[ti]
			_ball(root, tp2, 0.013 * body_k, Basis(), mat_gold)
	elif drapery == "flame":
		# the cloth has burnt off the hips and stands up as tongues
		var n_tng: int = 20
		var njf: int = 6
		var drop: float = 0.100 * body_k
		var stf := SurfaceTool.new()
		stf.begin(Mesh.PRIMITIVE_TRIANGLES)
		for s in range(n_tng):
			var fs: float = float(s) / float(n_tng)
			var th: float = TAU * fs
			var rise: float = (0.235 + 0.265 * absf(sin(fs * 13.0 + 0.7))) * body_k
			var flare: float = (0.055 + 0.085 * absf(cos(fs * 6.0))) * body_k
			var twist: float = skirt_twist * 1.4 + sin(fs * 9.0) * 0.9
			var hw: float = 0.034 * body_k * (0.55 + 0.80 * absf(sin(fs * 8.0 + 2.0)))
			for j in range(njf):
				var t0: float = float(j) / float(njf)
				var t1: float = float(j + 1) / float(njf)
				var a0: Vector3 = _flame_pt(hip_c, hip_yaw, th, t0, drop, rise, r_waist, flare, twist, hw, -1.0)
				var a1: Vector3 = _flame_pt(hip_c, hip_yaw, th, t0, drop, rise, r_waist, flare, twist, hw, 1.0)
				var b1: Vector3 = _flame_pt(hip_c, hip_yaw, th, t1, drop, rise, r_waist, flare, twist, hw, 1.0)
				var b0: Vector3 = _flame_pt(hip_c, hip_yaw, th, t1, drop, rise, r_waist, flare, twist, hw, -1.0)
				var cen: Vector3 = (a0 + a1 + b0 + b1) * 0.25
				var want := Vector3(cen.x - hip_c.x, 0.0, cen.z - hip_c.z)
				if want.length() < 0.0001:
					want = Vector3.RIGHT
				_quad_n(stf, a0, a1, b1, b0, want.normalized())
		stf.generate_normals()
		var flm: MeshInstance3D = _add(root, stf.commit(), mat_flame)
		flm.transform = Transform3D()
		for k in range(5):
			var fk: float = float(k) / 5.0
			var ea: float = hip_yaw + TAU * fk + 0.4
			var er: float = r_waist * 1.06
			_ball(root, Vector3(hip_c.x + sin(ea) * er, hip_c.y - drop * 0.5, hip_c.z + cos(ea) * er), 0.021 * body_k, Basis(), mat_flame)
	else:
		var skirt: ArrayMesh = _skirt_surface(hip_c, swing, hip_yaw, n_pleats, skirt_len, r_waist, r_hem, cut_ang, cut, skirt_twist, 0.0, 1.0, 12, 0.0, float(n_pleats))
		var skm: MeshInstance3D = _add(root, skirt, mat_cloth)
		skm.transform = Transform3D()

		var band: ArrayMesh = _skirt_surface(hip_c, swing, hip_yaw, n_pleats, skirt_len, r_waist, r_hem, cut_ang, cut, skirt_twist, 0.885, 1.0, 3, 0.006 * body_k, float(n_pleats))
		var bm: MeshInstance3D = _add(root, band, mat_gold)
		bm.transform = Transform3D()

	# girdle over the waist of the skirt, with hanging bells
	_ring(root, hip_c + Vector3(0.0, 0.014 * body_k, 0.0), Vector3.UP, r_waist * 0.99, r_waist * 1.13, mat_gold)
	var n_bells: int = rng.randi_range(3, 5)
	if m_mult:
		n_bells = 3
	for k in range(n_bells):
		var fk: float = float(k) / float(n_bells)
		var ang: float = hip_yaw + PI + (fk - 0.5) * 1.5
		var bp := Vector3(hip_c.x + sin(ang) * r_waist * 1.06, hip_c.y - 0.030 * body_k, hip_c.z + cos(ang) * r_waist * 1.06)
		_cone(root, bp, Vector3.DOWN, 0.030 * body_k, 0.017 * body_k, mat_gold_dk)

	# ---- neck --------------------------------------------------------------
	var neck_dir: Vector3 = (Vector3(sin(head_yaw) * 0.14, 1.0, 0.10 + sin(head_back) * 0.24)).normalized()
	var neck_a: Vector3 = p_top + Vector3(0.0, 0.014, 0.0)
	var neck_b: Vector3 = neck_a + neck_dir * (0.062 * body_k)
	var neck_c: Vector3 = neck_b + neck_dir * (0.048 * body_k)
	_bone(root, neck_a, neck_b, 0.052 * body_k, 0.047 * body_k, mat_cream)
	_bone(root, neck_b, neck_c, 0.047 * body_k, 0.044 * body_k, mat_cream)

	# ---- layered necklaces --------------------------------------------------
	for k in range(3):
		var fk: float = float(k) / 2.0
		var ny: float = lerpf(neck_a.y - 0.008, p_chest.y + 0.010, fk)
		var nr: float = lerpf(0.062, 0.104, fk) * body_k
		var nc := Vector3(lerpf(neck_a.x, p_chest.x, fk), ny, lerpf(neck_a.z, p_chest.z, fk) - 0.010 * fk)
		var mat_n: StandardMaterial3D = mat_gold if (k % 2) == 0 else mat_gold_dk
		var n_ax: Vector3 = (b_top * Vector3(0.0, 1.0, -0.22)).normalized()
		_ring(root, nc, n_ax, nr, nr + 0.013 * body_k, mat_n)

	var n_beads: int = rng.randi_range(5, 9)
	if m_mult:
		n_beads = mini(n_beads, 5)
	var bead_top: Vector3 = p_chest + b_chest * Vector3(0.0, 0.012, -0.070 * body_k)
	for k in range(n_beads):
		var fk: float = float(k) / float(n_beads - 1)
		var bp: Vector3 = bead_top + Vector3(sin(fk * PI) * 0.010 * hip_side, -fk * 0.086 * body_k, -0.004 * sin(fk * PI))
		var br: float = lerpf(0.011, 0.016, fk) * body_k
		var mat_b: StandardMaterial3D = mat_gold if (k % 2) == 0 else mat_jewel
		_ball(root, bp, br, Basis(), mat_b)
	_ball(root, bead_top + Vector3(0.0, -0.100 * body_k, -0.006), 0.021 * body_k, Basis().scaled(Vector3(1.0, 1.2, 0.6)), mat_jewel)

	# ---- arms: four or six, fanned ------------------------------------------
	var arms_per_side: int = n_arms / 2
	var span: float = float(maxi(arms_per_side - 1, 1))
	var el_top: float = deg_to_rad(rng.randf_range(56.0, 74.0))
	var el_low: float = deg_to_rad(rng.randf_range(-34.0, -14.0))
	var upper_l: float = rng.randf_range(0.222, 0.246) * body_k
	var fore_l: float = rng.randf_range(0.204, 0.226) * body_k
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		for k in range(arms_per_side):
			var fk: float = float(k) / span
			var el: float = lerpf(el_top, el_low, fk) + rng.randf_range(-0.08, 0.08)
			var anchor_t: float = lerpf(0.96, 0.74, fk)
			var i_a: int = clampi(int(round(anchor_t * float(n_spine - 1))), 1, n_spine - 1)
			var yaw_a: float = yaws[i_a]
			var p_a: Vector3 = pts[i_a]
			var ba := Basis(Vector3.UP, yaw_a)
			var t_a: float = float(i_a) / float(n_spine - 1)
			var out_w: float = _torso_w(t_a) * body_k * 1.22
			var sh_pt: Vector3 = p_a + ba * Vector3(sd * out_w, -0.012 * body_k, lerpf(-0.010, 0.030, fk))

			var lat: float = rng.randf_range(0.74, 0.88)
			var fwd: float = rng.randf_range(-0.32, -0.06)
			var d_up: Vector3 = Vector3(sd * cos(el) * lat, sin(el), fwd).normalized()
			var turn: float = rng.randf_range(0.20, 0.78) if el < 0.20 else -rng.randf_range(0.08, 0.62)
			var lat2: float = lat * rng.randf_range(0.52, 0.92)
			var fwd2: float = fwd - rng.randf_range(0.10, 0.42)
			var d_fo: Vector3 = Vector3(sd * cos(el + turn) * lat2, sin(el + turn), fwd2).normalized()

			var elbow: Vector3 = sh_pt + d_up * upper_l
			var wrist: Vector3 = elbow + d_fo * fore_l
			var mat_arm: StandardMaterial3D = mat_pink if rng.randf() < 0.68 else mat_cream

			_ball(root, sh_pt, 0.058 * body_k, ba.scaled(Vector3(1.0, 0.92, 0.94)), mat_arm)
			var bow_v := Vector3(0.0, 0.012, -0.014)
			var mid_u: Vector3 = (sh_pt + elbow) * 0.5 + bow_v
			_bone(root, sh_pt, mid_u, 0.052 * body_k, 0.045 * body_k, mat_arm)
			_bone(root, mid_u, elbow, 0.045 * body_k, 0.037 * body_k, mat_arm)
			_ball(root, elbow, 0.038 * body_k, Basis(), mat_arm)
			var mid_f: Vector3 = (elbow + wrist) * 0.5 + bow_v * 0.5
			_bone(root, elbow, mid_f, 0.040 * body_k, 0.035 * body_k, mat_arm)
			_bone(root, mid_f, wrist, 0.035 * body_k, 0.025 * body_k, mat_arm)
			_ball(root, wrist, 0.026 * body_k, Basis(), mat_arm)

			_ring(root, sh_pt + d_up * (upper_l * 0.44), d_up, 0.040 * body_k, 0.055 * body_k, mat_gold)
			_ring(root, wrist - d_fo * (0.012 * body_k), d_fo, 0.026 * body_k, 0.038 * body_k, mat_gold_dk)

			var curl: float = rng.randf_range(-0.30, 0.55)
			var splay: float = 1.0
			if m_bloom:
				# the hands have opened as well: the fingers rake back off the
				# palm and stand apart, the way a flower's own sepals do
				curl = -0.66 - curl * 0.22
				splay = 2.05
			_hand(root, wrist, d_fo, sd, curl, body_k, mat_arm, splay)
			var kind: int = rng.randi_range(0, 5)
			if m_bloom:
				_blossom(root, wrist + d_fo * (0.092 * body_k), d_fo, sd, body_k, mat_petal, mat_jewel)
			else:
				_attribute(root, wrist + d_fo * (0.078 * body_k), d_fo, sd, kind, body_k, mat_gold, mat_jewel, mat_ivory)

	# ---- head ---------------------------------------------------------------
	var hb: Basis = Basis(Vector3.UP, sh_yaw + head_yaw) * Basis(Vector3.RIGHT, head_back) * Basis(Vector3.FORWARD, head_roll)
	var crown_top := Vector3.ZERO
	var crown_r: float = 0.084 * body_k
	var crown_h: float = 0.170 * body_k * rng.randf_range(0.90, 1.16)

	if elephant:
		var head_c: Vector3 = neck_c + hb * Vector3(0.0, 0.086 * body_k, 0.006)
		var skull := SphereMesh.new()
		skull.radius = 0.108 * body_k
		skull.height = 0.216 * body_k
		skull.radial_segments = 22
		skull.rings = 14
		var skm2: MeshInstance3D = _add(root, skull, mat_hide)
		skm2.transform = Transform3D(Basis(hb.x * 1.10, hb.y * 1.00, hb.z * 1.02), head_c)

		var brow := SphereMesh.new()
		brow.radius = 0.082 * body_k
		brow.height = 0.164 * body_k
		var brm: MeshInstance3D = _add(root, brow, mat_hide)
		brm.transform = Transform3D(Basis(hb.x * 1.02, hb.y * 0.86, hb.z * 0.80), head_c + hb * Vector3(0.0, 0.044 * body_k, -0.056 * body_k))

		for sgn in [-1.0, 1.0]:
			var sd: float = sgn
			_ball(root, head_c + hb * Vector3(sd * 0.046 * body_k, 0.006 * body_k, -0.092 * body_k), 0.017 * body_k, hb, mat_dark)

		# fan ears
		var ear_len: float = rng.randf_range(0.175, 0.230) * body_k
		var ear_h: float = rng.randf_range(0.180, 0.235) * body_k
		var ear_curl: float = rng.randf_range(0.22, 0.46)
		var ear_wave: float = rng.randf_range(0.010, 0.026) * body_k
		var ear_th: float = 0.0058 * body_k
		for sgn in [-1.0, 1.0]:
			var sd: float = sgn
			var anchor: Vector3 = head_c + hb * Vector3(sd * 0.100 * body_k, 0.006 * body_k, 0.014 * body_k)
			var e_out: Vector3 = (hb * Vector3(sd * 0.94, 0.12, 0.32)).normalized()
			var e_up: Vector3 = hb * Vector3(0.0, 1.0, 0.0)
			e_up = (e_up - e_out * e_up.dot(e_out)).normalized()
			var e_nrm: Vector3 = e_out.cross(e_up).normalized()
			var nu: int = 9
			var nv: int = 8
			var fr: Array = []
			var bk: Array = []
			var pf: Array = []
			var pb: Array = []
			for i in range(nu + 1):
				var rowf: Array = []
				var rowb: Array = []
				var rowpf: Array = []
				var rowpb: Array = []
				for j in range(nv + 1):
					var fu: float = -1.0 + 2.0 * float(i) / float(nu)
					var fv: float = float(j) / float(nv)
					var lp: Vector3 = _ear_pt(fu, fv, e_out, e_up, e_nrm, ear_len, ear_h, ear_curl, ear_wave, 1.0)
					rowf.append(anchor + lp + e_nrm * ear_th)
					rowb.append(anchor + lp - e_nrm * ear_th)
					var fv2: float = 0.10 + 0.72 * fv
					var lp2: Vector3 = _ear_pt(fu * 0.72, fv2, e_out, e_up, e_nrm, ear_len, ear_h, ear_curl, ear_wave, 0.70)
					rowpf.append(anchor + lp2 + e_nrm * (ear_th + 0.0030 * body_k))
					rowpb.append(anchor + lp2 + e_nrm * (ear_th + 0.0008 * body_k))
				fr.append(rowf)
				bk.append(rowb)
				pf.append(rowpf)
				pb.append(rowpb)
			var solid: Array = []
			for i in range(nu):
				var rows: Array = []
				for j in range(nv):
					rows.append(true)
				solid.append(rows)
			var ear_mesh: ArrayMesh = _shell(fr, bk, solid, nu, nv)
			var eam: MeshInstance3D = _add(root, ear_mesh, mat_hide)
			eam.transform = Transform3D()
			var pad_mesh: ArrayMesh = _shell(pf, pb, solid, nu, nv)
			var pdm: MeshInstance3D = _add(root, pad_mesh, mat_pink)
			pdm.transform = Transform3D()

		# tusks
		for sgn in [-1.0, 1.0]:
			var sd: float = sgn
			var base_p: Vector3 = head_c + hb * Vector3(sd * 0.056 * body_k, -0.066 * body_k, -0.070 * body_k)
			var d1: Vector3 = (hb * Vector3(sd * 0.38, -0.74, -0.56)).normalized()
			var mid_p: Vector3 = base_p + d1 * (0.068 * body_k)
			var d2: Vector3 = (hb * Vector3(sd * 0.46, 0.06, -0.89)).normalized()
			var tip_p: Vector3 = mid_p + d2 * (0.060 * body_k)
			_bone(root, base_p, mid_p, 0.020 * body_k, 0.014 * body_k, mat_ivory)
			_bone(root, mid_p, tip_p, 0.014 * body_k, 0.002, mat_ivory)
			_ring(root, mid_p, d2, 0.014 * body_k, 0.021 * body_k, mat_gold)

		# the curling trunk
		var n_trunk: int = rng.randi_range(11, 15)
		var trunk_len: float = rng.randf_range(0.36, 0.47) * body_k
		var curve: float = rng.randf_range(0.20, 0.31)
		var spiral: float = rng.randf_range(0.12, 0.34) * (1.0 if rng.randf() < 0.5 else -1.0)
		var td: Vector3 = (hb * Vector3(0.0, -0.58, -0.82)).normalized()
		var ax: Vector3 = hb * Vector3(1.0, 0.0, 0.0)
		ax = (ax - td * ax.dot(td)).normalized()
		var tp: Vector3 = head_c + hb * Vector3(0.0, -0.052 * body_k, -0.098 * body_k)
		for k in range(n_trunk):
			var s: float = float(k) / float(n_trunk - 1)
			var seg: float = trunk_len / float(n_trunk) * lerpf(1.18, 0.70, s)
			var r0: float = lerpf(0.046, 0.014, pow(s, 0.82)) * body_k
			td = td.rotated(ax, curve * lerpf(0.72, 1.46, s)).normalized()
			ax = ax.rotated(td, spiral).normalized()
			var q2: Vector3 = tp + td * seg
			_cap(root, tp, q2, r0, mat_hide)
			tp = q2
		_ball(root, tp, 0.014 * body_k, Basis(), mat_hide)

		crown_top = head_c + hb * Vector3(0.0, 0.094 * body_k, 0.010 * body_k)
		crown_r = 0.072 * body_k
		crown_h = 0.098 * body_k * rng.randf_range(0.9, 1.2)
	else:
		var head_c: Vector3 = neck_c + hb * Vector3(0.0, 0.072 * body_k, -0.006)
		var skull := SphereMesh.new()
		skull.radius = 0.092 * body_k
		skull.height = 0.184 * body_k
		skull.radial_segments = 22
		skull.rings = 14
		var skm3: MeshInstance3D = _add(root, skull, mat_cream)
		skm3.transform = Transform3D(Basis(hb.x * 0.94, hb.y * 1.06, hb.z * 0.98), head_c)

		var jaw := SphereMesh.new()
		jaw.radius = 0.066 * body_k
		jaw.height = 0.132 * body_k
		var jm: MeshInstance3D = _add(root, jaw, mat_cream)
		jm.transform = Transform3D(Basis(hb.x * 0.92, hb.y * 0.82, hb.z * 1.00), head_c + hb * Vector3(0.0, -0.052 * body_k, -0.018 * body_k))

		var nose := SphereMesh.new()
		nose.radius = 0.019 * body_k
		nose.height = 0.038 * body_k
		var nm: MeshInstance3D = _add(root, nose, mat_cream)
		nm.transform = Transform3D(Basis(hb.x * 0.92, hb.y * 1.30, hb.z * 1.40), head_c + hb * Vector3(0.0, -0.014 * body_k, -0.084 * body_k))

		for sgn in [-1.0, 1.0]:
			var sd: float = sgn
			_ball(root, head_c + hb * Vector3(sd * 0.036 * body_k, 0.010 * body_k, -0.080 * body_k), 0.017 * body_k, Basis(hb.x * 1.35, hb.y * 0.62, hb.z * 0.75), mat_dark)
			_ball(root, head_c + hb * Vector3(sd * 0.038 * body_k, 0.033 * body_k, -0.078 * body_k), 0.014 * body_k, Basis(hb.x * 1.55, hb.y * 0.34, hb.z * 0.60), mat_dark)
			_ball(root, head_c + hb * Vector3(sd * 0.088 * body_k, -0.006 * body_k, 0.010 * body_k), 0.024 * body_k, Basis(hb.x * 0.42, hb.y * 1.30, hb.z * 0.90), mat_cream)
			_ring(root, head_c + hb * Vector3(sd * 0.086 * body_k, -0.034 * body_k, 0.010 * body_k), hb * Vector3(1.0, 0.0, 0.0), 0.013 * body_k, 0.023 * body_k, mat_gold)
			var ly: float = -0.066 * body_k + sd * 0.010 * body_k
			_ball(root, head_c + hb * Vector3(0.0, ly, -0.076 * body_k), 0.016 * body_k, Basis(hb.x * 1.40, hb.y * 0.50, hb.z * 0.62), mat_lip)

		var tilaka := CylinderMesh.new()
		tilaka.bottom_radius = 0.011 * body_k
		tilaka.top_radius = 0.008 * body_k
		tilaka.height = 0.010 * body_k
		tilaka.radial_segments = 10
		var tim: MeshInstance3D = _add(root, tilaka, mat_jewel)
		var tdir: Vector3 = hb * Vector3(0.0, 0.12, -1.0)
		tim.transform = Transform3D(_basis_y_to(tdir), head_c + hb * Vector3(0.0, 0.046 * body_k, -0.082 * body_k))

		crown_top = head_c + hb * Vector3(0.0, 0.084 * body_k, 0.004 * body_k)
		crown_r = 0.086 * body_k

	# ---- multiplied: two more heads bud off the neck -------------------------
	if m_mult:
		for sgn in [-1.0, 1.0]:
			var sb: float = sgn
			var bud_face: Vector3 = (hb * Vector3(sb * 0.90, 0.16, -0.42)).normalized()
			var bud_c: Vector3 = neck_c + hb * Vector3(sb * 0.106 * body_k, -0.008 * body_k, 0.012 * body_k)
			_bud_head(root, bud_c, hb, bud_face, body_k * 0.92, mat_cream, mat_dark, mat_gold)

	# ---- crown --------------------------------------------------------------
	var n_tier: int = rng.randi_range(3, 5)
	var c_up: Vector3 = hb * Vector3(0.0, 1.0, 0.0)
	for k in range(n_tier):
		var fk: float = float(k) / float(n_tier)
		var yy: float = crown_h * 0.52 * fk
		var rr: float = lerpf(crown_r, crown_r * 0.58, fk)
		var mat_t: StandardMaterial3D = mat_gold if (k % 2) == 0 else mat_jewel
		_ring(root, crown_top + c_up * yy, c_up, rr * 0.78, rr, mat_t)
	var cone_base: Vector3 = crown_top + c_up * (crown_h * 0.52)
	var cone_r: float = crown_r * 0.60
	_cone2(root, cone_base, c_up, crown_h * 0.34, cone_r, cone_r * 0.22, mat_gold)
	var fin_p: Vector3 = cone_base + c_up * (crown_h * 0.34)
	_ball(root, fin_p, crown_r * 0.20, Basis(), mat_jewel)
	_cone(root, fin_p + c_up * (crown_r * 0.16), c_up, crown_h * 0.20, crown_r * 0.13, mat_gold)
	if m_bloom:
		# the crown flowers too — the finial was a bud, and it has opened
		_blossom(root, fin_p + c_up * (crown_h * 0.30), c_up, hip_side, body_k * 1.35, mat_petal, mat_jewel)

	# ---- fossilised: the flesh pinched off the frame -------------------------
	if m_foss:
		_fossil(root, mat_bone, 0.34)
		_ribs(root, pts, yaws, n_spine, body_k, mat_bone)

	# ---- settle: fit, centre, floor -----------------------------------------
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
# body profile

static func _torso_w(t: float) -> float:
	var keys: Array = [0.118, 0.104, 0.097, 0.110, 0.130, 0.137]
	return _key(keys, t)


static func _torso_d(t: float) -> float:
	var keys: Array = [0.086, 0.078, 0.073, 0.085, 0.092, 0.086]
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


# ---------------------------------------------------------------------------
# hands and attributes

static func _hand(root: Node3D, wrist: Vector3, fdir: Vector3, sd: float, curl: float, k: float, mat: StandardMaterial3D, splay: float = 1.0) -> void:
	var hy: Vector3 = fdir.normalized()
	var ref_v: Vector3 = Vector3.UP if absf(hy.dot(Vector3.UP)) < 0.88 else Vector3.FORWARD
	var hx: Vector3 = ref_v.cross(hy).normalized()
	var hz: Vector3 = hx.cross(hy).normalized()

	var palm := SphereMesh.new()
	palm.radius = 0.034 * k
	palm.height = 0.068 * k
	palm.radial_segments = 14
	palm.rings = 8
	var pm: MeshInstance3D = _add(root, palm, mat)
	pm.transform = Transform3D(Basis(hx * 1.10, hy * 1.25, hz * 0.54), wrist + hy * (0.036 * k))

	for f in range(3):
		var ff: float = float(f) - 1.0
		var spread: float = ff * 0.22 * splay
		var d: Vector3 = (hy * cos(curl) + hz * sin(curl) + hx * spread * 0.60).normalized()
		var a: Vector3 = wrist + hy * (0.066 * k) + hx * (ff * 0.019 * k * splay)
		var ln: float = (0.058 - absf(ff) * 0.008) * k
		var b: Vector3 = a + d * ln
		var fin := CapsuleMesh.new()
		fin.radius = 0.0080 * k
		fin.height = ln + 0.016 * k
		fin.radial_segments = 8
		fin.rings = 3
		var fm: MeshInstance3D = _add(root, fin, mat)
		fm.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)

	var td: Vector3 = (hx * (-sd * 0.84) + hy * 0.46 + hz * 0.24).normalized()
	var ta: Vector3 = wrist + hy * (0.028 * k) + hx * (-sd * 0.024 * k)
	var tb: Vector3 = ta + td * (0.046 * k)
	var thumb := CapsuleMesh.new()
	thumb.radius = 0.0098 * k
	thumb.height = 0.046 * k + 0.020 * k
	thumb.radial_segments = 8
	thumb.rings = 3
	var tm: MeshInstance3D = _add(root, thumb, mat)
	tm.transform = Transform3D(_basis_y_to(td), (ta + tb) * 0.5)


static func _attribute(root: Node3D, at_p: Vector3, fdir: Vector3, sd: float, kind: int, k: float, mat_gold: StandardMaterial3D, mat_jewel: StandardMaterial3D, mat_ivory: StandardMaterial3D) -> void:
	var hy: Vector3 = fdir.normalized()
	var ref_v: Vector3 = Vector3.UP if absf(hy.dot(Vector3.UP)) < 0.88 else Vector3.FORWARD
	var hx: Vector3 = ref_v.cross(hy).normalized()
	var hz: Vector3 = hx.cross(hy).normalized()
	if kind == 0:
		# chakra disc, edge-on in the fingers, cocked to the hand's own side
		var disc_ax: Vector3 = (hz + hx * (sd * 0.22)).normalized()
		_ring(root, at_p, disc_ax, 0.020 * k, 0.040 * k, mat_gold)
		_ball(root, at_p, 0.014 * k, Basis(hx, hz * 0.35, hy), mat_jewel)
	elif kind == 1:
		# lotus bud
		_ball(root, at_p + hy * (0.014 * k), 0.024 * k, Basis(hx, hy * 1.35, hz), mat_jewel)
		for p in range(3):
			var fp: float = float(p) / 3.0 * TAU + sd * 0.4
			var d: Vector3 = (hy * 1.25 + hx * cos(fp) * 0.7 + hz * sin(fp) * 0.7).normalized()
			_cone(root, at_p + d * (0.012 * k), d, 0.036 * k, 0.012 * k, mat_jewel)
	elif kind == 2:
		# conch
		_cone2(root, at_p - hy * (0.014 * k), hy, 0.062 * k, 0.026 * k, 0.008 * k, mat_ivory)
		_ball(root, at_p - hy * (0.020 * k), 0.020 * k, Basis(), mat_ivory)
	elif kind == 3:
		# bell
		_cone2(root, at_p + hy * (0.040 * k), -hy, 0.048 * k, 0.010 * k, 0.026 * k, mat_gold)
		_ball(root, at_p - hy * (0.012 * k), 0.010 * k, Basis(), mat_gold)
	elif kind == 4:
		# goad
		var tip: Vector3 = at_p + hy * (0.072 * k)
		_bone(root, at_p - hy * (0.026 * k), tip, 0.007 * k, 0.005 * k, mat_gold)
		var head := BoxMesh.new()
		head.size = Vector3(0.030 * k, 0.020 * k, 0.012 * k)
		var hm: MeshInstance3D = _add(root, head, mat_gold)
		hm.transform = Transform3D(Basis(hx, hy, hz), tip)
	# kind 5: the empty open palm, abhaya — nothing held


# ---------------------------------------------------------------------------
# what the body becomes: the three manifestations that are not the cast one

static func _blossom(root: Node3D, at_p: Vector3, fdir: Vector3, sd: float, k: float, mat_petal: StandardMaterial3D, mat_heart: StandardMaterial3D) -> void:
	# BLOOMING. The attribute has opened: where the hand held a disc or a conch
	# there are seven petals raked back off a squat heart. Each petal is a
	# spheroid flattened along the flower's own axis and drawn out along its
	# length, so it reads as a blade and not as a bead, and the whole flower
	# stands on the hand's forward axis — it opens away from the palm, which is
	# the direction the attribute it replaces was held out in.
	var hy: Vector3 = fdir.normalized()
	var ref_v: Vector3 = Vector3.UP if absf(hy.dot(Vector3.UP)) < 0.88 else Vector3.FORWARD
	var hx: Vector3 = ref_v.cross(hy).normalized()
	var hz: Vector3 = hx.cross(hy).normalized()
	var heart: Vector3 = at_p + hy * (0.010 * k)
	var pr: float = 0.030 * k
	for p in range(7):
		var fp: float = float(p) / 7.0 * TAU + sd * 0.36
		var out_v: Vector3 = (hx * cos(fp) + hz * sin(fp)).normalized()
		var tan_v: Vector3 = (hx * -sin(fp) + hz * cos(fp)).normalized()
		var rake: float = 0.74 + 0.14 * sin(fp * 3.0 + sd)
		var d: Vector3 = (out_v * sin(rake) + hy * cos(rake)).normalized()
		var pn: Vector3 = tan_v.cross(d).normalized()
		_ball(root, heart + d * (pr * 1.15), pr, Basis(tan_v * 0.52, d * 1.42, pn * 0.17), mat_petal)
	_ball(root, heart, 0.017 * k, Basis(hx, hy * 0.62, hz), mat_heart)


static func _bud_head(root: Node3D, at_p: Vector3, hb: Basis, face: Vector3, k: float, mat_skin: StandardMaterial3D, mat_dark: StandardMaterial3D, mat_gold: StandardMaterial3D) -> void:
	# MULTIPLIED. A second and a third head bud off the neck at two thirds of
	# the first one's size, each turned out and away from it and set low enough
	# to overlap the skull it grew from — a bud, not a passenger. Each carries
	# its own jaw, its own painted eyes and its own coronet, so the trinity
	# reads as three heads rather than as two lumps on a shoulder.
	var f: Vector3 = face.normalized()
	var up: Vector3 = hb * Vector3(0.0, 1.0, 0.0)
	up = (up - f * up.dot(f)).normalized()
	var rt: Vector3 = f.cross(up).normalized()
	var bb := Basis(rt, up, -f)
	_ball(root, at_p, 0.052 * k, Basis(bb.x * 0.96, bb.y * 1.12, bb.z * 1.04), mat_skin)
	_ball(root, at_p + bb * Vector3(0.0, -0.034 * k, -0.014 * k), 0.036 * k, Basis(bb.x * 0.90, bb.y * 0.80, bb.z * 1.00), mat_skin)
	for sgn in [-1.0, 1.0]:
		var se: float = sgn
		_ball(root, at_p + bb * Vector3(se * 0.021 * k, 0.008 * k, -0.046 * k), 0.010 * k, Basis(bb.x * 1.30, bb.y * 0.66, bb.z * 0.78), mat_dark)
	_ring(root, at_p + bb * Vector3(0.0, 0.044 * k, 0.004 * k), up, 0.032 * k, 0.044 * k, mat_gold)


static func _fossil(root: Node3D, mat_flesh: StandardMaterial3D, squeeze: float) -> void:
	# FOSSILISED. The flesh comes off and the armature stays. Every part painted
	# in bone is pinched to a fraction of its width and depth while its length,
	# its place and its angle hold — so the tribhanga survives as a stick.
	# Two things make this the fossil and not a melt. The pinch happens in each
	# part's OWN frame, so a limb capsule thins to a rod and a spine ellipsoid
	# to a vertebra instead of everything squashing toward one world axis. And
	# it happens about each part's own centre, so the ear plates — ArrayMeshes
	# that carry their vertices in world coordinates under an identity transform
	# — narrow where they stand rather than sliding in toward the origin.
	# Gold is not flesh: the armlets, the girdle, the necklaces and the crown
	# keep their full size and are left hanging loose on the frame.
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		if cm.mesh == null:
			continue
		if cm.material_override != mat_flesh:
			continue
		var tf: Transform3D = cm.transform
		var c_local: Vector3 = cm.mesh.get_aabb().get_center()
		var nb := Basis(tf.basis.x * squeeze, tf.basis.y, tf.basis.z * squeeze)
		cm.transform = Transform3D(nb, tf.origin + tf.basis * c_local - nb * c_local)


static func _ribs(root: Node3D, pts: Array, yaws: Array, n_spine: int, k: float, mat: StandardMaterial3D) -> void:
	# FOSSILISED, part two. Seven hoops around the chest the flesh has left,
	# each cut to the width and depth the torso used to have at that height and
	# carrying the same yaw, so the cage still turns the shoulders off the
	# pelvis. They slope further down the higher they sit. Called AFTER the
	# pinch above, or they would be pinched with everything else.
	for i in range(7):
		var fi: float = float(i) / 6.0
		var t: float = lerpf(0.22, 0.84, fi)
		var idx: int = clampi(int(round(t * float(n_spine - 1))), 0, n_spine - 1)
		var q: Vector3 = pts[idx]
		var yaw: float = yaws[idx]
		var rw: float = _torso_w(t) * k * 1.06
		var rd: float = _torso_d(t) * k * 1.06
		var tube: float = lerpf(0.0092, 0.0060, fi) * k
		var slope: float = deg_to_rad(lerpf(-4.0, -13.0, fi))
		var hoop := TorusMesh.new()
		hoop.inner_radius = maxf(rd - tube, 0.004)
		hoop.outer_radius = rd + tube
		hoop.rings = 20
		hoop.ring_segments = 6
		var rb: Basis = Basis(Vector3.UP, yaw) * Basis(Vector3(1.0, 0.0, 0.0), slope)
		var kx: float = rw / maxf(rd, 0.001)
		var mi: MeshInstance3D = _add(root, hoop, mat)
		mi.transform = Transform3D(Basis(rb.x * kx, rb.y, rb.z), q)


# ---------------------------------------------------------------------------
# the pleated skirt

static func _skirt_pt(hip_c: Vector3, swing: Vector3, base_ang: float, th: float, t: float, n_pleats: int, skirt_len: float, r_waist: float, r_hem: float, cut_ang: float, cut: float, twist: float, bulge: float, amp_k: float = 1.0, flare_pow: float = 1.35) -> Vector3:
	var pa: float = th + base_ang + twist * t
	var len_f: float = 1.0 - cut * pow(maxf(cos(pa - cut_ang), 0.0), 1.6)
	var tt: float = t * len_f
	var fold: float = 0.5 + 0.5 * cos(float(n_pleats) * th)
	var crisp: float = pow(maxf(fold, 0.0), 0.60)
	var amp: float = lerpf(0.016, 0.118, pow(t, 1.2)) * amp_k
	var r_base: float = lerpf(r_waist, r_hem, pow(t, flare_pow))
	var rr: float = r_base * (1.0 + amp * (crisp - 0.45)) + bulge
	var cx: float = hip_c.x + swing.x * t * t
	var cz: float = hip_c.z + swing.z * t * t
	var yy: float = hip_c.y - skirt_len * tt
	return Vector3(cx + sin(pa) * rr, yy, cz + cos(pa) * rr)


static func _skirt_surface(hip_c: Vector3, swing: Vector3, base_ang: float, n_pleats: int, skirt_len: float, r_waist: float, r_hem: float, cut_ang: float, cut: float, twist: float, t_lo: float, t_hi: float, nt: int, bulge: float, uv_rep: float, amp_k: float = 1.0, flare_pow: float = 1.35) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# the pleats are what carry the angular detail, so a surface with its
	# corrugation flattened away (the flood's pour) has to be sampled finer or it
	# comes back as a faceted drum instead of a smooth fall of cloth
	var n_th: int = maxi(n_pleats * 4, int(round(float(n_pleats) * 4.0 / maxf(amp_k, 0.22))))
	var grid: Array = []
	for i in range(n_th + 1):
		var row: Array = []
		for j in range(nt + 1):
			var th: float = TAU * float(i) / float(n_th)
			var tj: float = lerpf(t_lo, t_hi, float(j) / float(nt))
			row.append(_skirt_pt(hip_c, swing, base_ang, th, tj, n_pleats, skirt_len, r_waist, r_hem, cut_ang, cut, twist, bulge, amp_k, flare_pow))
		grid.append(row)
	for i in range(n_th):
		var row0: Array = grid[i]
		var row1: Array = grid[i + 1]
		for j in range(nt):
			var p00: Vector3 = row0[j]
			var p01: Vector3 = row0[j + 1]
			var p10: Vector3 = row1[j]
			var p11: Vector3 = row1[j + 1]
			var tm: float = lerpf(t_lo, t_hi, (float(j) + 0.5) / float(nt))
			var cen: Vector3 = (p00 + p01 + p10 + p11) * 0.25
			var axis_x: float = hip_c.x + swing.x * tm * tm
			var axis_z: float = hip_c.z + swing.z * tm * tm
			var want := Vector3(cen.x - axis_x, 0.0, cen.z - axis_z)
			if want.length() < 0.0001:
				want = Vector3.RIGHT
			want = want.normalized()
			var u0: float = float(i) / float(n_th) * uv_rep
			var u1: float = float(i + 1) / float(n_th) * uv_rep
			var v0: float = float(j) / float(nt) * 1.4
			var v1: float = float(j + 1) / float(nt) * 1.4
			_quad_uv(st, p00, p10, p11, p01, Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1), want)
	st.generate_normals()
	return st.commit()


static func _quad_uv(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2, want: Vector3) -> void:
	var n_front: Vector3 = (c - a).cross(b - a)
	if n_front.dot(want) >= 0.0:
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
# what the cloth becomes: one ribbon of the unravelled skirt, one tongue of the
# burnt one. Both are ruled strips — the caller sweeps t along the fall and
# side across the width, and every quad it stitches comes from here, so the
# strip stays one continuous piece however hard it twists.

static func _thread_pt(hip_c: Vector3, swing: Vector3, base_ang: float, th: float, t: float, ln_s: float, r_waist: float, out_s: float, spin: float, hw: float, side: float) -> Vector3:
	# THREADS. One strand of the unravelled skirt. It leaves the waist at the
	# skirt's own radius, swings outward and around as it falls, and rolls about
	# its own length so the ribbon turns face-on, edge-on and face-on again on
	# the way down — which is what stops thirty of these reading as a fringe of
	# flat blades. side is -1 for the near edge, +1 for the far one, 0 for the
	# centreline the caller hangs a bead on.
	var drop: float = pow(clampf(t, 0.0, 1.0), 0.92)
	var pa: float = base_ang + th + spin * 0.38 * drop
	var rr: float = r_waist * (0.98 + 0.06 * drop) + out_s * pow(drop, 1.7)
	var sway: float = r_waist * 0.11 * sin(drop * PI * 1.6 + th * 2.0)
	var cx: float = hip_c.x + swing.x * drop * drop
	var cz: float = hip_c.z + swing.z * drop * drop
	var yy: float = hip_c.y - ln_s * drop
	var out_v := Vector3(sin(pa), 0.0, cos(pa))
	var tan_v := Vector3(cos(pa), 0.0, -sin(pa))
	var roll: float = spin * drop * 2.6 + th
	var edge: Vector3 = (tan_v * cos(roll) + Vector3.UP * sin(roll)) * (hw * side)
	return Vector3(cx, yy, cz) + out_v * (rr + sway) + edge


static func _flame_pt(hip_c: Vector3, base_ang: float, th: float, t: float, drop: float, rise: float, r_waist: float, flare: float, twist: float, hw: float, side: float) -> Vector3:
	# FLAME. One tongue standing off the bare hip. It starts a little below the
	# waist, leans out through the middle of its rise and licks back in toward
	# the body at the tip, twisting around the hips as it goes and narrowing to
	# a blunt point — never to nothing, because a zero-width top edge would hand
	# the surface a fold of degenerate triangles to average a normal from.
	var u: float = clampf(t, 0.0, 1.0)
	var pa: float = base_ang + th + twist * u * u
	var lick: float = sin(u * PI * 0.92)
	var rr: float = r_waist * (1.00 + 0.14 * u) + flare * lick
	var yy: float = hip_c.y - drop + rise * pow(u, 0.88)
	var out_v := Vector3(sin(pa), 0.0, cos(pa))
	var tan_v := Vector3(cos(pa), 0.0, -sin(pa))
	var roll: float = twist * u * 1.7 + th * 0.5
	var taper: float = pow(maxf(1.0 - u * 0.94, 0.06), 0.62) * (0.62 + 0.38 * sin(u * PI))
	var edge: Vector3 = (tan_v * cos(roll) + Vector3.UP * sin(roll) * 0.55) * (hw * taper * side)
	return Vector3(hip_c.x, yy, hip_c.z) + out_v * rr + edge


# ---------------------------------------------------------------------------
# fan ear surface + the double-sided shell builder

static func _ear_pt(fu: float, fv: float, e_out: Vector3, e_up: Vector3, e_nrm: Vector3, ear_len: float, ear_h: float, ear_curl: float, ear_wave: float, k: float) -> Vector3:
	var half_h: float = ear_h * (0.30 + 0.70 * pow(maxf(fv, 0.0), 0.55)) * k
	var droop: float = -0.14 * ear_h * fv * maxf(-fu, 0.0)
	var back: float = -ear_curl * ear_len * fv * fv + ear_wave * sin(fu * PI * 2.0) * fv
	return e_out * (fv * ear_len * k) + e_up * (fu * half_h + droop) + e_nrm * back


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
	var want: Vector3 = mid - inner
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
# primitives

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


static func _ball(root: Node3D, p: Vector3, r: float, bas: Basis, mat: StandardMaterial3D) -> MeshInstance3D:
	var sph := SphereMesh.new()
	sph.radius = r
	sph.height = r * 2.0
	sph.radial_segments = 14
	sph.rings = 8
	var mi: MeshInstance3D = _add(root, sph, mat)
	mi.transform = Transform3D(bas, p)
	return mi


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


static func _cap(root: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.006)
	var caps := CapsuleMesh.new()
	caps.radius = r
	caps.height = ln + r * 2.0
	caps.radial_segments = 12
	caps.rings = 4
	var mi: MeshInstance3D = _add(root, caps, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _cone(root: Node3D, base: Vector3, dir: Vector3, h: float, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	return _cone2(root, base, dir, h, r, 0.0, mat)


static func _cone2(root: Node3D, base: Vector3, dir: Vector3, h: float, r0: float, r1: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = dir.normalized()
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = r0
	cyl.top_radius = r1
	cyl.height = h
	cyl.radial_segments = 12
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(d), base + d * (h * 0.5))
	return mi


static func _ring(root: Node3D, centre: Vector3, axis: Vector3, inner: float, outer: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var tor := TorusMesh.new()
	tor.inner_radius = inner
	tor.outer_radius = maxf(outer, inner + 0.002)
	tor.rings = 16
	tor.ring_segments = 8
	var mi: MeshInstance3D = _add(root, tor, mat)
	mi.transform = Transform3D(_basis_y_to(axis), centre)
	return mi


static func _c(scheme: Array, i: int) -> Color:
	var code: String = scheme[i]
	return Color(code)


static func _paint(c: Color, tex: ImageTexture, k: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if tex != null:
		m.albedo_texture = tex
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(k, k, k)
	m.roughness = 0.24
	m.metallic = 0.0
	m.clearcoat_enabled = true
	m.clearcoat = 0.62
	m.clearcoat_roughness = 0.16
	return m


static func _metal(c: Color, tex: ImageTexture, k: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(k, k, k)
	m.metallic = 0.90
	m.metallic_specular = 0.68
	m.roughness = 0.26
	return m


# ---------------------------------------------------------------------------
# painted textures

static func _tex_plaster(rng: RandomNumberGenerator) -> ImageTexture:
	# near-white painted plaster: warm mottle + hairline crackle, so albedo tints it
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var w1: float = float(rng.randi_range(1, 3))
	var w2: float = float(rng.randi_range(2, 4))
	var w3: float = float(rng.randi_range(3, 6))
	var amp: float = rng.randf_range(0.05, 0.12)
	for y in range(TEX):
		for x in range(TEX):
			var fx: float = float(x) / float(TEX) * TAU
			var fy: float = float(y) / float(TEX) * TAU
			var n: float = 0.5 + 0.5 * (0.5 * sin(fx * w1 + 0.4) + 0.3 * sin(fy * w2 + 1.6) + 0.2 * sin((fx + fy) * w3))
			var v: float = 1.0 - amp * (1.0 - n)
			var grain: float = rng.randf_range(0.985, 1.012)
			var vv: float = clampf(v * grain, 0.0, 1.0)
			img.set_pixel(x, y, Color(vv, vv * 0.995, vv * 0.985))
	var n_cracks: int = rng.randi_range(14, 26)
	for c in range(n_cracks):
		var px: float = rng.randf() * float(TEX)
		var py: float = rng.randf() * float(TEX)
		var ang: float = rng.randf() * TAU
		var steps: int = rng.randi_range(24, 70)
		var wobble: float = rng.randf_range(0.10, 0.26)
		var strength: float = rng.randf_range(0.10, 0.22)
		for s in range(steps):
			ang += rng.randf_range(-wobble, wobble)
			px += cos(ang)
			py += sin(ang)
			var ix: int = posmod(int(round(px)), TEX)
			var iy: int = posmod(int(round(py)), TEX)
			var old: Color = img.get_pixel(ix, iy)
			img.set_pixel(ix, iy, old.lerp(Color(0.72, 0.68, 0.66), strength))
	return ImageTexture.create_from_image(img)


static func _tex_cloth(rng: RandomNumberGenerator) -> ImageTexture:
	# saffron cloth: fine vertical stripe grooves + scattered dots, greyscale ground
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var stripes: float = float(rng.randi_range(4, 9))
	var deep: float = rng.randf_range(0.16, 0.30)
	var weave: float = float(rng.randi_range(20, 34))
	for y in range(TEX):
		for x in range(TEX):
			var u: float = float(x) / float(TEX)
			var v: float = float(y) / float(TEX)
			var st_v: float = 0.5 + 0.5 * cos(u * TAU * stripes)
			var base: float = 1.0 - deep * pow(maxf(1.0 - st_v, 0.0), 1.4)
			var wv: float = 0.028 * sin(v * TAU * weave) * sin(u * TAU * weave * 0.5)
			var vv: float = clampf(base + wv, 0.0, 1.0)
			img.set_pixel(x, y, Color(vv, vv * 0.985, vv * 0.955))
	var n_dots: int = rng.randi_range(18, 40)
	for c in range(n_dots):
		var cx: int = rng.randi_range(0, TEX - 1)
		var cy: int = rng.randi_range(0, TEX - 1)
		var rr: float = rng.randf_range(1.6, 3.6)
		var pale: float = rng.randf_range(0.14, 0.34)
		var span: int = int(ceil(rr)) + 1
		for dy in range(-span, span + 1):
			for dx in range(-span, span + 1):
				var dd: float = sqrt(float(dx * dx + dy * dy))
				if dd > rr:
					continue
				var f: float = clampf((rr - dd) / maxf(rr, 0.5), 0.0, 1.0)
				var ix: int = posmod(cx + dx, TEX)
				var iy: int = posmod(cy + dy, TEX)
				var old: Color = img.get_pixel(ix, iy)
				img.set_pixel(ix, iy, old.lerp(Color(1.0, 0.97, 0.86), f * pale))
	return ImageTexture.create_from_image(img)


static func _tex_hammer(rng: RandomNumberGenerator) -> ImageTexture:
	# hammered ground under the gold: soft round dents, near white
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	for y in range(TEX):
		for x in range(TEX):
			img.set_pixel(x, y, Color(1.0, 0.99, 0.96))
	var n_dents: int = rng.randi_range(40, 78)
	for c in range(n_dents):
		var cx: int = rng.randi_range(0, TEX - 1)
		var cy: int = rng.randi_range(0, TEX - 1)
		var rr: float = rng.randf_range(4.0, 11.0)
		var deep: float = rng.randf_range(0.06, 0.17)
		var span: int = int(ceil(rr)) + 1
		for dy in range(-span, span + 1):
			for dx in range(-span, span + 1):
				var dd: float = sqrt(float(dx * dx + dy * dy))
				if dd > rr:
					continue
				var f: float = 1.0 - dd / maxf(rr, 0.5)
				var shade: float = 1.0 - deep * f * f
				var ix: int = posmod(cx + dx, TEX)
				var iy: int = posmod(cy + dy, TEX)
				var old: Color = img.get_pixel(ix, iy)
				img.set_pixel(ix, iy, Color(clampf(old.r * shade, 0.0, 1.0), clampf(old.g * shade, 0.0, 1.0), clampf(old.b * shade, 0.0, 1.0)))
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
