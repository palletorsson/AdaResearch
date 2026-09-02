extends RefCounted

## dream_bodies / paik_light — one white gallery mannequin wearing scattered light.
##
## Reference: scratchpad/refs/paik.png (2048x536 panorama) — a Nam June Paik
## crowd of glossy white shop mannequins, each one washed with saturated
## patches of coloured light (magenta, cyan, yellow, green, red blobs and short
## pixel strips) on white plastic, black cables looping over the shoulders,
## round the arms and trailing to the gallery floor, small dark boxes and
## connectors strapped to the bodies, hands on hips, blank ovoid heads.
##
## Reproduced, and how:
##   1. The standing hand-on-hip figure — a 16-segment ellipsoid spine (hip,
##      waist, chest, shoulder, neck profile keyed in five stops) with capsule
##      limbs; the seed picks which hand goes to the hip, the elbow swings out
##      and back, the other arm hangs.
##   2. Contrapposto — the seed picks the weight leg: that hip rides 15 mm
##      high, that shoulder drops 18 mm, the pelvis shifts toward it and the
##      chest drifts away, the free foot stands forward and turned out.
##   3. The light skin — one 256x256 ImageTexture painted in code: near-white
##      base, pastel washes, then ~150 saturated rectangles, dots, pixel-strip
##      runs and small black marks. A SECOND texture holds the same marks on
##      black and drives emission (energy 1.2), so the colour glows and the
##      plastic between it does not.
##   4. Unbroken across the body — world triplanar UV1, so the scatter runs
##      over the seam between every capsule, sphere and box in the chain; the
##      seed shifts uv1_offset, so no two figures wear the same patches.
##   5. Glossy white plastic — clearcoat 0.85 at roughness 0.06 over a
##      roughness-0.16 albedo, the gallery-lit shop-dummy finish.
##   6. Raised light blobs — 26..44 flattened emissive spheres and thin boxes
##      stuck to the skin along its real surface normals, the brightest marks,
##      rolled at random so the strips do not line up.
##   7. Black cables — 8..14 SurfaceTool swept tubes on Catmull-Rom paths:
##      over-the-shoulder loops from floor to floor, a helix wound down one
##      arm, a sagging drape between both shoulders, thigh loops, and one
##      cable falling from the free hand. Every path is clamped above the floor.
##   8. Hardware — 3..5 dark connector boxes strapped on with torus bands, each
##      with a small glowing screen face.
##
## Given up: the crowd (this is one body, not the row), the painted backdrop,
## the real transparency of the plastic, the video content inside the monitors,
## and the light actually spilling onto neighbouring bodies.

const TEX: int = 256

const LIGHT_COLS: Array = [
	"#FF2BB4", "#22E4FF", "#FFE21C", "#2BFF74", "#FF3A22",
	"#FF8A1C", "#3D63FF", "#B84BFF", "#FF66C2", "#7BFF3A",
	"#FF1F6E", "#4CFFE0",
]

const WASH_COLS: Array = ["#F0C7EC", "#C9E4F5", "#F5E8C4", "#D6F0DA", "#E4D2F5"]

const SKIN_TONES: Array = ["#F2F3F5", "#EFF1F4", "#F5F2F0", "#EDEFF3"]

# torso half-width / half-depth at hip, waist, chest, shoulder, neck-base
const HW_KEYS: Array = [0.142, 0.104, 0.142, 0.126, 0.062]
const HD_KEYS: Array = [0.110, 0.084, 0.108, 0.090, 0.055]


static func describe() -> String:
	return "A glossy white gallery mannequin standing hand on hip, its skin scattered with glowing patches of magenta, cyan and yellow light, black cables looping over one shoulder and trailing to the floor."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# ---- the individual ----------------------------------------------------
	var total_h: float = rng.randf_range(1.47, 1.63)
	var k: float = total_h / 1.625
	var girth: float = rng.randf_range(0.93, 1.07)
	var hip_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var weight_side: float = hip_side
	if rng.randf() < 0.42:
		weight_side = -hip_side
	var lean_z: float = rng.randf_range(-0.030, 0.022)
	var head_yaw: float = deg_to_rad(rng.randf_range(-17.0, 17.0))
	var head_tilt: float = deg_to_rad(rng.randf_range(-7.0, 10.0))
	var n_spine: int = 16
	var n_cable: int = rng.randi_range(8, 14)
	var n_conn: int = rng.randi_range(3, 5)
	var n_decal: int = rng.randi_range(26, 44)
	var phase: float = rng.randf()

	# ---- skeleton heights (unscaled, total 1.625) --------------------------
	var y_ankle: float = 0.078 * k
	var y_knee: float = 0.452 * k
	var y_hip: float = 0.880 * k
	var y_chest: float = 1.205 * k
	var y_sh: float = 1.330 * k
	var y_neck: float = 1.410 * k
	var y_head: float = 1.520 * k

	# ---- materials ---------------------------------------------------------
	var texs: Array = _skin_textures(rng)
	var alb_tex: ImageTexture = texs[0]
	var emi_tex: ImageTexture = texs[1]

	var mat_skin := StandardMaterial3D.new()
	mat_skin.albedo_color = Color(str(SKIN_TONES[rng.randi_range(0, SKIN_TONES.size() - 1)]))
	mat_skin.albedo_texture = alb_tex
	mat_skin.emission_enabled = true
	mat_skin.emission = Color(1.0, 1.0, 1.0)
	mat_skin.emission_texture = emi_tex
	mat_skin.emission_energy_multiplier = 1.2
	mat_skin.roughness = 0.16
	mat_skin.metallic = 0.0
	mat_skin.clearcoat_enabled = true
	mat_skin.clearcoat = 0.85
	mat_skin.clearcoat_roughness = 0.06
	mat_skin.uv1_triplanar = true
	mat_skin.uv1_world_triplanar = true
	mat_skin.uv1_scale = Vector3(1.75, 1.75, 1.75)
	mat_skin.uv1_offset = Vector3(phase * 3.1, phase * 5.3, phase * 7.7)

	var mat_cable := StandardMaterial3D.new()
	mat_cable.albedo_color = Color("#0E0E12")
	mat_cable.roughness = 0.30
	mat_cable.metallic = 0.05
	mat_cable.clearcoat_enabled = true
	mat_cable.clearcoat = 0.55
	mat_cable.clearcoat_roughness = 0.15
	mat_cable.cull_mode = BaseMaterial3D.CULL_DISABLED

	var mat_box := StandardMaterial3D.new()
	mat_box.albedo_color = Color("#17171D")
	mat_box.roughness = 0.42
	mat_box.metallic = 0.20

	var mat_strap := StandardMaterial3D.new()
	mat_strap.albedo_color = Color("#101015")
	mat_strap.roughness = 0.62

	# shared unit meshes
	var unit_sph := SphereMesh.new()
	unit_sph.radius = 1.0
	unit_sph.height = 2.0
	unit_sph.radial_segments = 18
	unit_sph.rings = 10
	var unit_box := BoxMesh.new()
	unit_box.size = Vector3(1.0, 1.0, 1.0)

	# ---- spine -------------------------------------------------------------
	var spine_pts: Array = []
	var spine_hw: Array = []
	var spine_hd: Array = []
	for i in range(n_spine):
		var t: float = float(i) / float(n_spine - 1)
		var sx: float = weight_side * (0.020 * (1.0 - t) - 0.014 * t) * k
		var sz: float = lean_z * k * t - 0.012 * k * sin(PI * t)
		var yy: float = lerpf(y_hip, y_neck, t)
		spine_pts.append(Vector3(sx, yy, sz))
		spine_hw.append(_key5(HW_KEYS, t) * k * girth)
		spine_hd.append(_key5(HD_KEYS, t) * k * girth)

	var seg_y: float = (y_neck - y_hip) / float(n_spine - 1) * 1.55
	for i in range(n_spine):
		var q: Vector3 = spine_pts[i]
		var hw: float = spine_hw[i]
		var hd: float = spine_hd[i]
		var mi: MeshInstance3D = _add(root, unit_sph, mat_skin)
		mi.transform = Transform3D(Basis.from_scale(Vector3(hw, seg_y, hd)), q)

	var p_hip: Vector3 = spine_pts[0]
	var p_top: Vector3 = spine_pts[n_spine - 1]
	var i_chest: int = int(floor(float(n_spine - 1) * 0.60))
	var p_chest: Vector3 = spine_pts[i_chest]

	# glute / hip mass, so the pelvis is not a bare ellipsoid
	for si in range(2):
		var sd: float = -1.0 if si == 0 else 1.0
		var gm: MeshInstance3D = _add(root, unit_sph, mat_skin)
		var gp := Vector3(p_hip.x + sd * 0.070 * k * girth, y_hip - 0.055 * k, p_hip.z + 0.030 * k)
		gm.transform = Transform3D(Basis.from_scale(Vector3(0.085, 0.090, 0.090) * k * girth), gp)

	# ---- surface anchors for the light blobs -------------------------------
	var anchors: Array = []
	for i in range(n_spine):
		var q: Vector3 = spine_pts[i]
		var hw: float = spine_hw[i]
		var hd: float = spine_hd[i]
		for a in range(7):
			var ang: float = TAU * float(a) / 7.0 + float(i) * 0.41
			var off := Vector3(hw * cos(ang), 0.0, hd * sin(ang))
			var nr: Vector3 = Vector3(cos(ang) / maxf(hw, 0.001), 0.0, sin(ang) / maxf(hd, 0.001)).normalized()
			anchors.append([q + off, nr])

	# ---- legs --------------------------------------------------------------
	for si in range(2):
		var sd: float = -1.0 if si == 0 else 1.0
		var free: bool = sd != weight_side
		var hip_y: float = y_hip + (0.015 * k if not free else -0.006 * k)
		var hip_pt := Vector3(p_hip.x + sd * 0.082 * k * girth, hip_y - 0.030 * k, p_hip.z + 0.006 * k)
		var knee_x: float = hip_pt.x + (sd * 0.030 * k if free else sd * 0.008 * k)
		var knee_z: float = p_hip.z + (-0.048 * k if free else 0.004 * k)
		var knee_pt := Vector3(knee_x, y_knee, knee_z)
		var ank_x: float = hip_pt.x * 0.86 + (sd * 0.024 * k if free else sd * 0.004 * k)
		var ank_z: float = p_hip.z + (-0.098 * k if free else 0.012 * k)
		var ankle_pt := Vector3(ank_x, y_ankle, ank_z)
		var r_thigh: float = 0.079 * k * girth
		var r_shin: float = 0.055 * k * girth
		_limb(root, hip_pt, knee_pt, r_thigh, mat_skin)
		_limb(root, knee_pt, ankle_pt, r_shin, mat_skin)
		_ball(root, unit_sph, knee_pt, Vector3(0.062, 0.066, 0.062) * k * girth, mat_skin)
		_ball(root, unit_sph, ankle_pt, Vector3(0.048, 0.048, 0.050) * k * girth, mat_skin)
		var turn: float = deg_to_rad((13.0 if free else 7.0) * sd)
		var fb := Basis(Vector3.UP, turn)
		var foot_c: Vector3 = ankle_pt + fb * Vector3(0.0, -0.040 * k, -0.052 * k)
		var fm: MeshInstance3D = _add(root, unit_box, mat_skin)
		fm.transform = Transform3D(fb * Basis.from_scale(Vector3(0.088, 0.058, 0.185) * k), foot_c)
		var toe_c: Vector3 = ankle_pt + fb * Vector3(0.0, -0.049 * k, -0.148 * k)
		var tm: MeshInstance3D = _add(root, unit_box, mat_skin)
		tm.transform = Transform3D(fb * Basis(Vector3.RIGHT, deg_to_rad(-7.0)) * Basis.from_scale(Vector3(0.076, 0.040, 0.070) * k), toe_c)
		_leg_anchors(anchors, hip_pt, knee_pt, r_thigh, 3, rng)
		_leg_anchors(anchors, knee_pt, ankle_pt, r_shin, 3, rng)

	# ---- arms --------------------------------------------------------------
	var sh_pts: Array = []
	var elbow_pts: Array = []
	var wrist_pts: Array = []
	for si in range(2):
		var sd: float = -1.0 if si == 0 else 1.0
		var on_hip: bool = sd == hip_side
		var sh_y: float = y_sh + (-0.018 * k if sd == weight_side else 0.008 * k)
		var sh_pt := Vector3(p_top.x + sd * 0.126 * k * girth, sh_y, p_chest.z + 0.004 * k)
		_ball(root, unit_sph, sh_pt, Vector3(0.066, 0.072, 0.066) * k * girth, mat_skin)
		var elbow_pt: Vector3
		var wrist_pt: Vector3
		if on_hip:
			elbow_pt = sh_pt + Vector3(sd * (0.118 + rng.randf_range(-0.014, 0.020)) * k, -0.238 * k, (0.082 + rng.randf_range(-0.02, 0.03)) * k)
			wrist_pt = Vector3(p_hip.x + sd * 0.142 * k * girth, y_hip + 0.048 * k, p_hip.z - 0.026 * k)
		else:
			elbow_pt = sh_pt + Vector3(sd * (0.030 + rng.randf_range(-0.012, 0.024)) * k, -0.246 * k, (-0.012 + rng.randf_range(-0.02, 0.03)) * k)
			wrist_pt = elbow_pt + Vector3(sd * rng.randf_range(0.010, 0.048) * k, -0.238 * k, rng.randf_range(-0.070, -0.014) * k)
		var r_up: float = 0.055 * k * girth
		var r_fore: float = 0.043 * k * girth
		_limb(root, sh_pt, elbow_pt, r_up, mat_skin)
		_limb(root, elbow_pt, wrist_pt, r_fore, mat_skin)
		_ball(root, unit_sph, elbow_pt, Vector3(0.048, 0.050, 0.048) * k * girth, mat_skin)
		_ball(root, unit_sph, wrist_pt, Vector3(0.038, 0.040, 0.038) * k * girth, mat_skin)
		var hand_dir: Vector3 = (wrist_pt - elbow_pt).normalized()
		var hand_c: Vector3 = wrist_pt + hand_dir * (0.058 * k)
		var hm: MeshInstance3D = _add(root, unit_box, mat_skin)
		hm.transform = Transform3D(_basis_y_to(hand_dir) * Basis.from_scale(Vector3(0.052, 0.115, 0.030) * k), hand_c)
		sh_pts.append(sh_pt)
		elbow_pts.append(elbow_pt)
		wrist_pts.append(wrist_pt)
		_leg_anchors(anchors, sh_pt, elbow_pt, r_up, 3, rng)
		_leg_anchors(anchors, elbow_pt, wrist_pt, r_fore, 2, rng)

	var i_free_arm: int = 0 if hip_side > 0.0 else 1

	# ---- neck and head -----------------------------------------------------
	var head_c := Vector3(p_top.x + sin(head_yaw) * 0.010 * k, y_head, p_top.z - 0.014 * k)
	var neck_top := Vector3(p_top.x, y_neck + 0.026 * k, p_top.z - 0.004 * k)
	_tapered_cyl(root, Vector3(p_top.x, y_neck - 0.048 * k, p_top.z), neck_top, 0.060 * k * girth, 0.049 * k * girth, mat_skin)
	var hb := Basis(Vector3.UP, head_yaw) * Basis(Vector3.RIGHT, head_tilt)
	var hs := Vector3(0.084, 0.104, 0.094) * k * girth
	var head_m: MeshInstance3D = _add(root, unit_sph, mat_skin)
	head_m.transform = Transform3D(hb * Basis.from_scale(hs), head_c)
	var jaw_m: MeshInstance3D = _add(root, unit_sph, mat_skin)
	jaw_m.transform = Transform3D(hb * Basis.from_scale(Vector3(0.066, 0.058, 0.074) * k * girth), head_c + hb * Vector3(0.0, -0.062 * k, -0.014 * k))
	var nose_m: MeshInstance3D = _add(root, unit_sph, mat_skin)
	nose_m.transform = Transform3D(hb * Basis.from_scale(Vector3(0.017, 0.034, 0.026) * k), head_c + hb * Vector3(0.0, -0.016 * k, -0.082 * k))
	for a in range(6):
		var ang: float = TAU * float(a) / 6.0 + 0.3
		var nr: Vector3 = (hb * Vector3(cos(ang), 0.30, sin(ang))).normalized()
		anchors.append([head_c + nr * (0.088 * k * girth), nr])

	# ---- connector boxes ---------------------------------------------------
	var sh_free: Vector3 = sh_pts[i_free_arm]
	var el_free: Vector3 = elbow_pts[i_free_arm]
	var hw_chest: float = spine_hw[i_chest]
	var hd_chest: float = spine_hd[i_chest]
	var hw_3: float = spine_hw[3]
	var hd_3: float = spine_hd[3]
	var hd_10: float = spine_hd[10]
	var p_3: Vector3 = spine_pts[3]
	var p_10: Vector3 = spine_pts[10]
	var thigh_mid := Vector3(p_hip.x - 0.076 * k * hip_side, (y_hip - 0.030 * k + y_knee) * 0.5, p_hip.z)
	var conn_slots: Array = [
		[p_chest + Vector3(hw_chest * 0.42 * hip_side, 0.012 * k, -hd_chest * 0.86), Vector3(0.22 * hip_side, 0.05, -1.0)],
		[p_3 + Vector3(hw_3 * 0.80 * -hip_side, 0.0, hd_3 * 0.40), Vector3(-hip_side, 0.0, 0.42)],
		[(sh_free + el_free) * 0.5, Vector3(-hip_side * 0.9, 0.12, -0.42)],
		[p_10 + Vector3(0.0, 0.0, hd_10 * 0.92), Vector3(0.10, 0.06, 1.0)],
		[thigh_mid, Vector3(-hip_side, 0.0, -0.35)],
	]
	for ci in range(n_conn):
		var slot: Array = conn_slots[ci % conn_slots.size()]
		var cpos: Vector3 = slot[0]
		var cdir_raw: Vector3 = slot[1]
		var cdir: Vector3 = cdir_raw.normalized()
		var cw: float = rng.randf_range(0.055, 0.082) * k
		var ch_h: float = rng.randf_range(0.042, 0.062) * k
		var cd: float = rng.randf_range(0.022, 0.034) * k
		var cb: Basis = _basis_z_to(cdir) * Basis(Vector3(0.0, 0.0, 1.0), rng.randf_range(-0.4, 0.4))
		var bm: MeshInstance3D = _add(root, unit_box, mat_box)
		bm.transform = Transform3D(cb * Basis.from_scale(Vector3(cw, ch_h, cd)), cpos + cdir * (cd * 0.42))
		var scr_col: Color = Color(str(LIGHT_COLS[rng.randi_range(0, LIGHT_COLS.size() - 1)]))
		var mat_scr := StandardMaterial3D.new()
		mat_scr.albedo_color = scr_col
		mat_scr.roughness = 0.20
		mat_scr.emission_enabled = true
		mat_scr.emission = scr_col
		mat_scr.emission_energy_multiplier = 2.2
		var sm: MeshInstance3D = _add(root, unit_box, mat_scr)
		sm.transform = Transform3D(cb * Basis.from_scale(Vector3(cw * 0.66, ch_h * 0.62, cd * 0.30)), cpos + cdir * (cd * 0.86))
		var strap_axis: Vector3 = Vector3(0.0, 1.0, 0.0)
		if ci % conn_slots.size() == 2:
			strap_axis = (el_free - sh_free).normalized()
		var torus := TorusMesh.new()
		var band_r: float = rng.randf_range(0.062, 0.086) * k * girth
		torus.inner_radius = band_r
		torus.outer_radius = band_r + 0.013 * k
		torus.rings = 12
		torus.ring_segments = 8
		var tm2: MeshInstance3D = _add(root, torus, mat_strap)
		tm2.transform = Transform3D(_basis_y_to(strap_axis), cpos - cdir * (cd * 0.30))

	# ---- raised light blobs ------------------------------------------------
	for di in range(n_decal):
		var an: Array = anchors[rng.randi_range(0, anchors.size() - 1)]
		var apos: Vector3 = an[0]
		var anrm_raw: Vector3 = an[1]
		var anrm: Vector3 = anrm_raw.normalized()
		var jit: Vector3 = Vector3(rng.randf_range(-0.018, 0.018), rng.randf_range(-0.030, 0.030), rng.randf_range(-0.018, 0.018)) * k
		var col: Color = Color(str(LIGHT_COLS[rng.randi_range(0, LIGHT_COLS.size() - 1)]))
		var mat_d := StandardMaterial3D.new()
		mat_d.albedo_color = col
		mat_d.roughness = 0.24
		mat_d.metallic = 0.0
		mat_d.emission_enabled = true
		mat_d.emission = col
		mat_d.emission_energy_multiplier = rng.randf_range(1.5, 2.6)
		mat_d.clearcoat_enabled = true
		mat_d.clearcoat = 0.6
		var roll: float = rng.randf_range(0.0, TAU)
		var db: Basis = _basis_z_to(anrm) * Basis(Vector3(0.0, 0.0, 1.0), roll)
		if rng.randf() < 0.58:
			var rr: float = rng.randf_range(0.016, 0.042) * k
			var mi_d: MeshInstance3D = _add(root, unit_sph, mat_d)
			mi_d.transform = Transform3D(db * Basis.from_scale(Vector3(rr, rr * rng.randf_range(0.45, 1.15), rr * 0.30)), apos + jit + anrm * (rr * 0.16))
		else:
			var bw: float = rng.randf_range(0.026, 0.086) * k
			var bh: float = rng.randf_range(0.010, 0.028) * k
			var mi_d2: MeshInstance3D = _add(root, unit_box, mat_d)
			mi_d2.transform = Transform3D(db * Basis.from_scale(Vector3(bw, bh, 0.008 * k)), apos + jit + anrm * (0.004 * k))

	# ---- cables ------------------------------------------------------------
	var floor_y: float = 0.011
	for ci in range(n_cable):
		var kind: int = ci % 5
		var r_cab: float = rng.randf_range(0.0075, 0.0115) * k
		var ctrl: Array = []
		if kind == 0 or kind == 1:
			# over the shoulder, floor to floor
			var sd: float = hip_side if rng.randf() < 0.55 else -hip_side
			var jx: float = rng.randf_range(-0.05, 0.05) * k
			ctrl = [
				Vector3(sd * 0.10 * k + jx, floor_y, (0.26 + rng.randf_range(-0.06, 0.12)) * k),
				Vector3(sd * (0.10 + rng.randf_range(-0.03, 0.03)) * k, y_hip * 0.52, 0.170 * k),
				Vector3(sd * 0.075 * k, y_chest, 0.132 * k),
				Vector3(sd * (0.125 + rng.randf_range(0.0, 0.055)) * k, y_sh + 0.048 * k, 0.006 * k),
				Vector3(sd * (0.095 + rng.randf_range(-0.02, 0.03)) * k, y_chest - 0.040 * k, -0.128 * k),
				Vector3(sd * 0.055 * k, y_hip - 0.115 * k, -0.118 * k),
				Vector3(sd * 0.020 * k + jx, floor_y, -(0.23 + rng.randf_range(-0.05, 0.14)) * k),
			]
		elif kind == 2:
			# helix wound down the free arm, then trailing to the floor
			var a0: Vector3 = sh_pts[i_free_arm]
			var a1: Vector3 = wrist_pts[i_free_arm]
			var axis: Vector3 = a1 - a0
			var turns: float = rng.randf_range(1.5, 2.9)
			var ph: float = rng.randf_range(0.0, TAU)
			var steps: int = 13
			for j in range(steps + 1):
				var f: float = float(j) / float(steps)
				var c: Vector3 = a0.lerp(a1, f)
				var rr: float = lerpf(0.078, 0.050, f) * k * girth
				ctrl.append(c + _perp(axis, ph + f * TAU * turns) * rr)
			ctrl.append(a1 + Vector3(-hip_side * 0.05 * k, -0.13 * k, -0.03 * k))
			ctrl.append(Vector3(a1.x - hip_side * 0.15 * k, floor_y, a1.z - (0.10 + rng.randf_range(0.0, 0.14)) * k))
		elif kind == 3:
			# a drape sagging from shoulder to shoulder, then down the back
			var s1: Vector3 = sh_pts[0]
			var s2: Vector3 = sh_pts[1]
			var sag: float = rng.randf_range(0.16, 0.31) * k
			ctrl = [
				s1 + Vector3(0.0, 0.030 * k, 0.062 * k),
				s1 + Vector3(-s1.x * 0.35, -sag * 0.55, -0.135 * k),
				Vector3(rng.randf_range(-0.04, 0.04) * k, y_sh - sag, -0.155 * k),
				s2 + Vector3(-s2.x * 0.35, -sag * 0.55, -0.135 * k),
				s2 + Vector3(0.0, 0.030 * k, 0.062 * k),
				s2 + Vector3(0.0, -0.30 * k, 0.130 * k),
				Vector3(s2.x * 0.75, floor_y, (0.27 + rng.randf_range(-0.04, 0.13)) * k),
			]
		else:
			# a loop dropped round a thigh, or a fall from the free hand
			if rng.randf() < 0.5:
				var sd2: float = 1.0 if rng.randf() < 0.5 else -1.0
				var ty: float = lerpf(y_hip - 0.06 * k, y_knee + 0.08 * k, rng.randf())
				var tx: float = p_hip.x + sd2 * 0.080 * k * girth
				var rr2: float = rng.randf_range(0.088, 0.115) * k * girth
				ctrl = [
					Vector3(tx + sd2 * rr2, ty + 0.05 * k, p_hip.z - 0.02 * k),
					Vector3(tx, ty, p_hip.z - rr2),
					Vector3(tx - sd2 * rr2 * 0.9, ty - 0.03 * k, p_hip.z),
					Vector3(tx, ty - 0.05 * k, p_hip.z + rr2),
					Vector3(tx + sd2 * rr2 * 1.05, ty - 0.09 * k, p_hip.z + 0.01 * k),
					Vector3(tx + sd2 * (rr2 + 0.05 * k), ty * 0.45, p_hip.z + 0.09 * k),
					Vector3(tx + sd2 * (0.12 + rng.randf_range(0.0, 0.12)) * k, floor_y, p_hip.z + (0.16 + rng.randf_range(0.0, 0.14)) * k),
				]
			else:
				var w: Vector3 = wrist_pts[i_free_arm]
				var swing: float = rng.randf_range(-0.10, 0.16) * k
				ctrl = [
					w + Vector3(0.0, 0.02 * k, -0.02 * k),
					w + Vector3(-hip_side * 0.03 * k, -0.16 * k, -0.055 * k + swing),
					w + Vector3(-hip_side * 0.07 * k, -0.34 * k, -0.030 * k + swing * 1.4),
					Vector3(w.x - hip_side * (0.10 + rng.randf_range(0.0, 0.10)) * k, floor_y, w.z - (0.06 + rng.randf_range(0.0, 0.20)) * k),
				]
		_cable(root, ctrl, r_cab, r_cab * rng.randf_range(0.75, 1.0), mat_cable, floor_y)

	_settle(root)


# ---------------------------------------------------------------------------
# painting

static func _skin_textures(rng: RandomNumberGenerator) -> Array:
	var alb: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var emi: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	alb.fill(Color(0.935, 0.940, 0.950))
	emi.fill(Color(0.0, 0.0, 0.0))

	# fine speckle in the plastic
	for y in range(0, TEX, 2):
		for x in range(0, TEX, 2):
			var n: float = rng.randf_range(-0.014, 0.010)
			alb.set_pixel(x, y, Color(clampf(0.935 + n, 0.0, 1.0), clampf(0.940 + n, 0.0, 1.0), clampf(0.950 + n, 0.0, 1.0)))

	# soft pastel washes (albedo only) — the lilac / pink haze in the reference
	var n_wash: int = rng.randi_range(20, 30)
	for w in range(n_wash):
		var wc: Color = Color(str(WASH_COLS[rng.randi_range(0, WASH_COLS.size() - 1)]))
		var cx: int = rng.randi_range(0, TEX - 1)
		var cy: int = rng.randi_range(0, TEX - 1)
		var rad: int = rng.randi_range(11, 34)
		var strength: float = rng.randf_range(0.14, 0.40)
		for dy in range(-rad, rad + 1):
			for dx in range(-rad, rad + 1):
				var d2: float = float(dx * dx + dy * dy)
				var rr: float = float(rad * rad)
				if d2 > rr:
					continue
				var f: float = (1.0 - d2 / rr)
				var px: int = posmod(cx + dx, TEX)
				var py: int = posmod(cy + dy, TEX)
				var cur: Color = alb.get_pixel(px, py)
				alb.set_pixel(px, py, cur.lerp(wc, strength * f * f))

	# saturated marks — dots, strips, blocks; albedo saturated, emission glowing
	var n_mark: int = rng.randi_range(120, 170)
	for m in range(n_mark):
		var col: Color = Color(str(LIGHT_COLS[rng.randi_range(0, LIGHT_COLS.size() - 1)]))
		var kind: int = rng.randi_range(0, 3)
		var mw: int = 4
		var mh: int = 4
		if kind == 0:
			mw = rng.randi_range(2, 6)
			mh = mw
		elif kind == 1:
			mw = rng.randi_range(9, 30)
			mh = rng.randi_range(2, 5)
		elif kind == 2:
			mw = rng.randi_range(2, 5)
			mh = rng.randi_range(8, 24)
		else:
			mw = rng.randi_range(6, 15)
			mh = rng.randi_range(5, 13)
		var ox: int = rng.randi_range(0, TEX - 1)
		var oy: int = rng.randi_range(0, TEX - 1)
		var glow: float = rng.randf_range(0.55, 1.0)
		var fade: float = rng.randf_range(0.72, 1.0)
		_rect(alb, emi, ox, oy, mw, mh, col, fade, glow)

	# runs of little coloured squares — the pixel strips
	var n_run: int = rng.randi_range(8, 15)
	for r in range(n_run):
		var ox: int = rng.randi_range(0, TEX - 1)
		var oy: int = rng.randi_range(0, TEX - 1)
		var cells: int = rng.randi_range(4, 9)
		var cw: int = rng.randi_range(3, 6)
		var gap: int = rng.randi_range(1, 3)
		var vertical: bool = rng.randf() < 0.4
		for c in range(cells):
			var col2: Color = Color(str(LIGHT_COLS[rng.randi_range(0, LIGHT_COLS.size() - 1)]))
			var sx: int = ox + (0 if vertical else c * (cw + gap))
			var sy: int = oy + (c * (cw + gap) if vertical else 0)
			_rect(alb, emi, sx, sy, cw, cw, col2, 0.95, rng.randf_range(0.6, 1.0))

	# small black marks and hot white cores
	var n_black: int = rng.randi_range(14, 26)
	for b in range(n_black):
		var bw: int = rng.randi_range(2, 7)
		var bh: int = rng.randi_range(2, 6)
		_rect(alb, emi, rng.randi_range(0, TEX - 1), rng.randi_range(0, TEX - 1), bw, bh, Color(0.055, 0.055, 0.065), 1.0, 0.0)
	var n_hot: int = rng.randi_range(10, 20)
	for h in range(n_hot):
		var hw2: int = rng.randi_range(2, 4)
		_rect(alb, emi, rng.randi_range(0, TEX - 1), rng.randi_range(0, TEX - 1), hw2, hw2, Color(1.0, 1.0, 1.0), 1.0, 1.0)

	return [ImageTexture.create_from_image(alb), ImageTexture.create_from_image(emi)]


static func _rect(alb: Image, emi: Image, ox: int, oy: int, w: int, h: int, col: Color, fade: float, glow: float) -> void:
	for dy in range(h):
		for dx in range(w):
			var px: int = posmod(ox + dx, TEX)
			var py: int = posmod(oy + dy, TEX)
			var cur: Color = alb.get_pixel(px, py)
			alb.set_pixel(px, py, cur.lerp(col, fade))
			if glow > 0.0:
				emi.set_pixel(px, py, Color(col.r * glow, col.g * glow, col.b * glow))


# ---------------------------------------------------------------------------
# shape helpers

static func _key5(keys: Array, t: float) -> float:
	var f: float = clampf(t, 0.0, 1.0) * 4.0
	var i: int = int(floor(f))
	if i >= 4:
		return float(keys[4])
	var u: float = f - float(i)
	var s: float = u * u * (3.0 - 2.0 * u)
	return lerpf(float(keys[i]), float(keys[i + 1]), s)


static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _ball(root: Node3D, unit_sph: Mesh, at: Vector3, sz: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi: MeshInstance3D = _add(root, unit_sph, mat)
	mi.transform = Transform3D(Basis.from_scale(sz), at)
	return mi


static func _limb(root: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.01)
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = ln + r * 1.9
	cap.radial_segments = 14
	cap.rings = 6
	var mi: MeshInstance3D = _add(root, cap, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _tapered_cyl(root: Node3D, a: Vector3, b: Vector3, r0: float, r1: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.01)
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = r0
	cyl.top_radius = r1
	cyl.height = ln
	cyl.radial_segments = 14
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _basis_y_to(dir: Vector3) -> Basis:
	var d: Vector3 = dir.normalized()
	if d.length() < 0.0001:
		return Basis()
	var dot_up: float = d.dot(Vector3.UP)
	if dot_up > 0.9999:
		return Basis()
	if dot_up < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	var ax: Vector3 = Vector3.UP.cross(d).normalized()
	var ang: float = acos(clampf(dot_up, -1.0, 1.0))
	return Basis(ax, ang)


static func _basis_z_to(dir: Vector3) -> Basis:
	var d: Vector3 = dir.normalized()
	var u := Vector3(0.0, 1.0, 0.0)
	if absf(d.dot(u)) > 0.97:
		u = Vector3(1.0, 0.0, 0.0)
	var rt: Vector3 = u.cross(d).normalized()
	var uu: Vector3 = d.cross(rt).normalized()
	return Basis(rt, uu, d)


static func _perp(axis: Vector3, ang: float) -> Vector3:
	var d: Vector3 = axis.normalized()
	if d.length() < 0.0001:
		d = Vector3(0.0, 1.0, 0.0)
	var u := Vector3(0.0, 1.0, 0.0)
	if absf(d.dot(u)) > 0.9:
		u = Vector3(1.0, 0.0, 0.0)
	var e1: Vector3 = d.cross(u).normalized()
	var e2: Vector3 = d.cross(e1).normalized()
	return (e1 * cos(ang) + e2 * sin(ang)).normalized()


static func _leg_anchors(anchors: Array, a: Vector3, b: Vector3, r: float, n_f: int, rng: RandomNumberGenerator) -> void:
	var axis: Vector3 = b - a
	for i in range(n_f):
		var f: float = (float(i) + 0.5) / float(n_f)
		var c: Vector3 = a.lerp(b, f)
		for j in range(4):
			var ang: float = TAU * float(j) / 4.0 + rng.randf_range(0.0, 1.2)
			var nr: Vector3 = _perp(axis, ang)
			anchors.append([c + nr * r, nr])


# ---------------------------------------------------------------------------
# cables

static func _cable(root: Node3D, ctrl: Array, r0: float, r1: float, mat: StandardMaterial3D, floor_y: float) -> void:
	var clamped: Array = []
	for i in range(ctrl.size()):
		var p: Vector3 = ctrl[i]
		var cx: float = clampf(p.x, -0.42, 0.42)
		var cz: float = clampf(p.z, -0.42, 0.42)
		clamped.append(Vector3(cx, maxf(p.y, floor_y), cz))
	var pts: Array = _smooth(clamped, 5)
	var out: Array = []
	for i in range(pts.size()):
		var q: Vector3 = pts[i]
		q = Vector3(clampf(q.x, -0.44, 0.44), maxf(q.y, floor_y), clampf(q.z, -0.44, 0.44))
		if out.size() > 0:
			var prev: Vector3 = out[out.size() - 1]
			if prev.distance_to(q) < 0.0004:
				continue
		out.append(q)
	if out.size() < 2:
		return
	_tube(root, out, r0, r1, mat)


static func _smooth(ctrl: Array, per: int) -> Array:
	var n: int = ctrl.size()
	if n < 3:
		return ctrl.duplicate()
	var out: Array = []
	for i in range(n - 1):
		var p0: Vector3 = ctrl[maxi(i - 1, 0)]
		var p1: Vector3 = ctrl[i]
		var p2: Vector3 = ctrl[i + 1]
		var p3: Vector3 = ctrl[mini(i + 2, n - 1)]
		var last: int = per
		if i == n - 2:
			last = per + 1
		for j in range(last):
			var u: float = float(j) / float(per)
			out.append(_cr(p0, p1, p2, p3, u))
	return out


static func _cr(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, u: float) -> Vector3:
	var u2: float = u * u
	var u3: float = u2 * u
	var a: Vector3 = p1 * 2.0
	var b: Vector3 = (p2 - p0) * u
	var c: Vector3 = (p0 * 2.0 - p1 * 5.0 + p2 * 4.0 - p3) * u2
	var d: Vector3 = (p1 * 3.0 - p0 - p2 * 3.0 + p3) * u3
	return (a + b + c + d) * 0.5


static func _tube(root: Node3D, pts: Array, r0: float, r1: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var n: int = pts.size()
	if n < 2:
		return null
	var sides: int = 7
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var first_a: Vector3 = pts[0]
	var first_b: Vector3 = pts[1]
	var prev_t: Vector3 = (first_b - first_a).normalized()
	if prev_t.length() < 0.0001:
		prev_t = Vector3(0.0, 1.0, 0.0)
	var nrm: Vector3 = _perp(prev_t, 0.0)
	var rings: Array = []
	for i in range(n):
		var pa: Vector3 = pts[maxi(i - 1, 0)]
		var pb: Vector3 = pts[mini(i + 1, n - 1)]
		var tg: Vector3 = pb - pa
		if tg.length() < 0.00001:
			tg = prev_t
		tg = tg.normalized()
		nrm = nrm - tg * nrm.dot(tg)
		if nrm.length() < 0.0002:
			nrm = _perp(tg, 0.7)
		nrm = nrm.normalized()
		var bi: Vector3 = tg.cross(nrm).normalized()
		var f: float = float(i) / float(n - 1)
		var rr: float = lerpf(r0, r1, f)
		var here: Vector3 = pts[i]
		var ring: Array = []
		for s in range(sides):
			var ang: float = TAU * float(s) / float(sides)
			ring.append(here + nrm * (cos(ang) * rr) + bi * (sin(ang) * rr))
		rings.append(ring)
		prev_t = tg
	for i in range(n - 1):
		var ra: Array = rings[i]
		var rb: Array = rings[i + 1]
		for s in range(sides):
			var s2: int = (s + 1) % sides
			var v_a: Vector3 = ra[s]
			var v_b: Vector3 = rb[s]
			var v_c: Vector3 = rb[s2]
			var v_d: Vector3 = ra[s2]
			st.add_vertex(v_a)
			st.add_vertex(v_b)
			st.add_vertex(v_c)
			st.add_vertex(v_a)
			st.add_vertex(v_c)
			st.add_vertex(v_d)
	st.generate_normals()
	return _add(root, st.commit(), mat)


# ---------------------------------------------------------------------------
# settle: floor it, centre it, fit it

static func _settle(root: Node3D) -> void:
	var box: AABB = _union_aabb(root)
	if box.size.length() < 0.0001:
		return
	var c: Vector3 = box.position + box.size * 0.5
	_shift_all(root, Vector3(-c.x, -box.position.y, -c.z))
	box = _union_aabb(root)
	var kx: float = 1.20 / maxf(box.size.x, 0.0001)
	var kz: float = 1.20 / maxf(box.size.z, 0.0001)
	var ky: float = 1.68 / maxf(box.size.y, 0.0001)
	var kf: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kf < 1.0:
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var mi: MeshInstance3D = ch
			var tf: Transform3D = mi.transform
			mi.transform = Transform3D(tf.basis.scaled(Vector3(kf, kf, kf)), tf.origin * kf)
	box = _union_aabb(root)
	var c2: Vector3 = box.position + box.size * 0.5
	var dy: float = 0.0
	if box.position.y < 0.0:
		dy = -box.position.y
	_shift_all(root, Vector3(-c2.x, dy, -c2.z))


static func _shift_all(root: Node3D, shift: Vector3) -> void:
	if shift.length() < 0.000001:
		return
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var mi: MeshInstance3D = ch
		var tf: Transform3D = mi.transform
		mi.transform = Transform3D(tf.basis, tf.origin + shift)


static func _union_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var mi: MeshInstance3D = ch
		if mi.mesh == null:
			continue
		var local: AABB = mi.mesh.get_aabb()
		var wb: AABB = mi.transform * local
		if first:
			box = wb
			first = false
		else:
			box = box.merge(wb)
	return box
