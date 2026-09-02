extends RefCounted

## dream_bodies / brass_stamen — one braced factory body, flesh bound into brass.
##
## Reference: scratchpad/refs/steampunk_stamen.png (2048x536 panorama) — a row of
## cream-fleshed doll bodies folded into a dark machine hall: kneeling, crouched,
## gripping, each one only PART of a body (a torso, a thigh, an arm, a smooth bald
## skull) laced into an armature of warm worn brass. Pipe runs joined by ball
## elbows, valve blocks with handwheels, open gears, copper coil springs, and
## dusty rose armour plates strapped over thigh, arm and shoulder with thin dark
## straps. Faces are closed and serene under brass headbands, with a lens on a
## swan-neck arm hanging in front of the brow.
##
## Reproduced, and how:
##  1. THE BRACE — a half-kneel: one flesh thigh folded down onto the footplate,
##     the other leg replaced entirely by brass pipe (hip ball, pipe femur, gear
##     knee, pipe shin, bracket foot), and the one flesh arm reaching down and
##     forward to grip a brass hand-rail on two stanchions. Torso leans into it.
##  2. PARTIAL BODY — only torso, one thigh, one arm and the head are flesh; the
##     other shoulder ends in a brass socket cap with three bolts and a pipe stub,
##     so the figure reads as half-built rather than wounded.
##  3. THE ARMATURE — 23 CylinderMesh pipe runs on six routes (back mast arching
##     over the crown, shoulder yoke, elliptical hip girdle, thigh brace, the leg
##     itself, the hand-rail), 24 SphereMesh ball elbows at the junctions, and
##     TorusMesh flanges at six couplings. Valve stems add five more cylinders.
##  4. VALVES AND GEARS — 4-5 valve blocks (BoxMesh body + stem + TorusMesh
##     handwheel) hung on frame nodes; 3-4 gears, each a CylinderMesh disc with a
##     hub and 9-12 BoxMesh teeth stepped around the rim, at hip, knee and spine.
##  5. COIL SPRINGS — two helices of small spheres (yoke-to-girdle, and round the
##     thigh brace) plus one swept SurfaceTool tube helix from the mast to the
##     pipe knee, so the springs read both as beads and as drawn wire.
##  6. DUSTY PINK PLATES — 4-5 thin curved SurfaceTool shells (outer skin, inner
##     skin, rim strips, tapered arc) strapped over thigh, upper arm, shoulder and
##     pipe femur with TorusMesh straps in near-black leather and rivet spheres.
##  7. THE SERENE SKULL — bald egg cranium, closed lid domes, small nose, ears,
##     ringed by three brass bands (headband, sagittal crown band, chin strap)
##     with temple bosses, and a lens on a bracket in front of the brow.
##  8. WORN SURFACE — three code-painted ImageTextures on triplanar UVs: lathe
##     banding and patina flecks on the brass, scuffed paint on the plates, faint
##     mottle on the flesh, so a chain of primitives reads as one worn casting.
##
## Given up: the dark factory hall itself, the neighbouring bodies the reference
## packs shoulder to shoulder, the flexible braided hoses, the clock faces, and
## any nipple/genital detail — this is a museum statue on a plinth, so the flesh
## is smoothed to doll geometry.

const TEX_BRASS: int = 128
const TEX_PAINT: int = 96
const TEX_FLESH: int = 64
const GROUND: float = 0.045

# scheme: [flesh, flesh shadow, brass, brass dark, plate, plate worn, strap, lens]
const SCHEMES: Array = [
	["#E9C7A4", "#D8AE8A", "#BE8F3E", "#7E5A23", "#C88AA8", "#DCA6BE", "#33241E", "#221E18"],
	["#EFD3B4", "#DCB894", "#C99A45", "#8A6529", "#CE93AF", "#E2B0C4", "#2C2420", "#1D2420"],
	["#E3BE9B", "#CFA47F", "#AE8236", "#6F4F1F", "#BE7E9C", "#D69CB4", "#38281F", "#241C16"],
	["#F0D6BA", "#DDBC9B", "#C4913C", "#7A5622", "#D49BB4", "#E6B8C9", "#302A22", "#1E1A14"],
]


static func describe() -> String:
	return "A half-kneeling factory body in pale flesh-cream, laced into a brass armature of pipes, ball elbows, valves, gears and coil springs, with dusty pink armour plates strapped over thigh, arm and shoulder."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var scheme: Array = SCHEMES[rng.randi_range(0, SCHEMES.size() - 1)]
	var col_flesh: Color = Color(scheme[0])
	var col_flesh_dk: Color = Color(scheme[1])
	var col_brass: Color = Color(scheme[2])
	var col_brass_dk: Color = Color(scheme[3])
	var col_plate: Color = Color(scheme[4])
	var col_plate_lo: Color = Color(scheme[5])
	var col_strap: Color = Color(scheme[6])
	var col_lens: Color = Color(scheme[7])

	var tex_brass: ImageTexture = _brass_texture(rng)
	var tex_paint: ImageTexture = _paint_texture(rng)
	var tex_flesh: ImageTexture = _flesh_texture(rng)

	var mat_flesh: StandardMaterial3D = _skin(col_flesh, tex_flesh, 2.0)
	var mat_flesh_dk: StandardMaterial3D = _skin(col_flesh_dk, tex_flesh, 2.4)
	var mat_brass: StandardMaterial3D = _metal(col_brass, tex_brass, 4.0, 0.35)
	var mat_brass_dk: StandardMaterial3D = _metal(col_brass_dk, tex_brass, 5.0, 0.48)
	var mat_iron: StandardMaterial3D = _metal(col_brass_dk.darkened(0.42), tex_brass, 3.0, 0.62)
	var mat_plate: StandardMaterial3D = _paint(col_plate, tex_paint, 3.0)
	var mat_plate_lo: StandardMaterial3D = _paint(col_plate_lo, tex_paint, 3.4)
	var mat_strap := StandardMaterial3D.new()
	mat_strap.albedo_color = col_strap
	mat_strap.roughness = 0.78
	mat_strap.metallic = 0.0
	var mat_lens := StandardMaterial3D.new()
	mat_lens.albedo_color = col_lens
	mat_lens.roughness = 0.12
	mat_lens.metallic = 0.35
	mat_lens.clearcoat_enabled = true
	mat_lens.clearcoat = 0.8
	mat_lens.emission_enabled = true
	mat_lens.emission = col_brass
	mat_lens.emission_energy_multiplier = 0.16

	# --- the individual --------------------------------------------------------
	var mir: float = 1.0 if rng.randf() < 0.5 else -1.0
	var rt := Vector3(mir, 0.0, 0.0)
	var n_spine: int = rng.randi_range(10, 12)
	var lean: float = rng.randf_range(0.14, 0.30)
	var twist: float = rng.randf_range(-0.055, 0.055)
	var sho_y: float = rng.randf_range(1.020, 1.080)
	var hip_y: float = rng.randf_range(0.505, 0.535)
	var head_pitch: float = rng.randf_range(-0.34, -0.11)
	var head_yaw: float = deg_to_rad(rng.randf_range(-15.0, 15.0))
	var head_r: float = rng.randf_range(0.118, 0.130)
	var knee_out: float = rng.randf_range(0.020, 0.060)
	var n_gears: int = rng.randi_range(3, 4)
	var n_valves: int = rng.randi_range(4, 5)
	var n_plates: int = rng.randi_range(4, 5)
	var gear_teeth: int = rng.randi_range(9, 12)
	var coil_a: int = rng.randi_range(9, 12)
	var coil_b: int = rng.randi_range(8, 10)

	# --- 1. footplate ----------------------------------------------------------
	var base := BoxMesh.new()
	base.size = Vector3(0.90, GROUND, 0.94)
	var bm: MeshInstance3D = _add(root, base, mat_iron)
	bm.transform = Transform3D(Basis(), Vector3(0.0, GROUND * 0.5, -0.03))
	for i in range(6):
		var ang: float = TAU * float(i) / 6.0 + 0.4
		var rp := Vector3(cos(ang) * 0.39, GROUND, -0.03 + sin(ang) * 0.41)
		var riv := SphereMesh.new()
		riv.radius = 0.019
		riv.height = 0.020
		riv.radial_segments = 10
		riv.rings = 5
		var rm: MeshInstance3D = _add(root, riv, mat_brass_dk)
		rm.transform = Transform3D(Basis(), rp)

	# --- 2. torso --------------------------------------------------------------
	var spine_pts: Array = []
	var spine_rad: Array = []
	for i in range(n_spine):
		var t: float = float(i) / float(n_spine - 1)
		var yy: float = lerpf(hip_y, sho_y, t)
		var zz: float = lerpf(0.085, -0.055 - lean * 0.34, t) + 0.035 * sin(PI * t)
		var xx: float = mir * (0.018 * sin(PI * t) + twist * t)
		spine_pts.append(Vector3(xx, yy, zz))
		spine_rad.append(_torso_r(t))
	for i in range(n_spine):
		var q: Vector3 = spine_pts[i]
		var r2: float = spine_rad[i]
		var tang: Vector3 = _tangent(spine_pts, i)
		var sph := SphereMesh.new()
		sph.radius = r2
		sph.height = r2 * 1.94
		sph.radial_segments = 20
		sph.rings = 11
		var mi: MeshInstance3D = _add(root, sph, mat_flesh)
		mi.transform = Transform3D(_basis_y_to(tang), q)
	var p_hip: Vector3 = spine_pts[0]
	var p_sho: Vector3 = spine_pts[n_spine - 1]
	for sgn in [-1.0, 1.0]:
		var sf: float = sgn
		var glute := SphereMesh.new()
		glute.radius = 0.118
		glute.height = 0.210
		glute.radial_segments = 18
		glute.rings = 10
		var gm: MeshInstance3D = _add(root, glute, mat_flesh)
		gm.transform = Transform3D(Basis(), p_hip + rt * (sf * 0.072) + Vector3(0.0, -0.030, 0.045))

	var hip_r: Vector3 = p_hip + rt * 0.140
	var hip_l: Vector3 = p_hip - rt * 0.140
	var sho_r: Vector3 = p_sho + rt * 0.170 + Vector3(0.0, -0.012, -0.010)
	var sho_l: Vector3 = p_sho - rt * 0.170 + Vector3(0.0, -0.012, -0.010)

	# --- 3. head ---------------------------------------------------------------
	var neck_a: Vector3 = p_sho + Vector3(0.0, 0.030, -0.010)
	var head_c: Vector3 = p_sho + Vector3(mir * 0.010, 0.245, -0.075 - lean * 0.10)
	var hb: Basis = Basis(Vector3.UP, head_yaw) * Basis(Vector3.RIGHT, head_pitch)
	_limb(root, neck_a, head_c - hb * Vector3(0.0, 0.075, 0.0), 0.062, mat_flesh)
	_ball(root, neck_a + Vector3(0.0, 0.030, 0.0), 0.070, mat_flesh)
	var skull := SphereMesh.new()
	skull.radius = head_r
	skull.height = head_r * 2.36
	skull.radial_segments = 24
	skull.rings = 14
	var skm: MeshInstance3D = _add(root, skull, mat_flesh)
	skm.transform = Transform3D(hb, head_c)
	var jaw := SphereMesh.new()
	jaw.radius = head_r * 0.72
	jaw.height = head_r * 1.30
	jaw.radial_segments = 18
	jaw.rings = 10
	var jm: MeshInstance3D = _add(root, jaw, mat_flesh)
	jm.transform = Transform3D(hb, head_c + hb * Vector3(0.0, -head_r * 0.62, -head_r * 0.34))
	var brow := SphereMesh.new()
	brow.radius = head_r * 0.58
	brow.height = head_r * 0.34
	brow.radial_segments = 16
	brow.rings = 8
	var brm: MeshInstance3D = _add(root, brow, mat_flesh)
	brm.transform = Transform3D(hb * Basis(Vector3.RIGHT, 1.35), head_c + hb * Vector3(0.0, head_r * 0.24, -head_r * 0.80))
	for sgn in [-1.0, 1.0]:
		var sf2: float = sgn
		var lid := SphereMesh.new()
		lid.radius = 0.028
		lid.height = 0.030
		lid.radial_segments = 14
		lid.rings = 7
		var lm: MeshInstance3D = _add(root, lid, mat_flesh_dk)
		lm.transform = Transform3D(hb * Basis(Vector3.RIGHT, 1.4), head_c + hb * Vector3(sf2 * head_r * 0.42, head_r * 0.01, -head_r * 0.86))
		var ear := SphereMesh.new()
		ear.radius = 0.030
		ear.height = 0.052
		ear.radial_segments = 12
		ear.rings = 7
		var em: MeshInstance3D = _add(root, ear, mat_flesh)
		em.transform = Transform3D(hb * Basis(Vector3.FORWARD, sf2 * 0.3), head_c + hb * Vector3(sf2 * head_r * 0.94, -head_r * 0.10, head_r * 0.06))
	_cone(root, head_c + hb * Vector3(0.0, -head_r * 0.24, -head_r * 0.86), hb * Vector3(0.0, -0.28, -1.0), 0.042, 0.022, mat_flesh)
	var mouth := SphereMesh.new()
	mouth.radius = 0.024
	mouth.height = 0.012
	mouth.radial_segments = 12
	mouth.rings = 6
	var mom: MeshInstance3D = _add(root, mouth, mat_flesh_dk)
	mom.transform = Transform3D(hb * Basis(Vector3.RIGHT, 1.25), head_c + hb * Vector3(0.0, -head_r * 0.60, -head_r * 0.72))

	# --- 4. brass skull harness ------------------------------------------------
	var band_y: TorusMesh = _torus_mesh(head_r * 0.90, head_r * 1.04)
	var by_m: MeshInstance3D = _add(root, band_y, mat_brass)
	by_m.transform = Transform3D(hb, head_c + hb * Vector3(0.0, head_r * 0.36, 0.0))
	var band_x: TorusMesh = _torus_mesh(head_r * 0.98, head_r * 1.12)
	var bx_m: MeshInstance3D = _add(root, band_x, mat_brass)
	bx_m.transform = Transform3D(hb * Basis(Vector3.FORWARD, PI * 0.5), head_c + hb * Vector3(0.0, head_r * 0.06, 0.0))
	var band_z: TorusMesh = _torus_mesh(head_r * 1.00, head_r * 1.13)
	var bz_m: MeshInstance3D = _add(root, band_z, mat_brass_dk)
	bz_m.transform = Transform3D(hb * Basis(Vector3.RIGHT, PI * 0.5), head_c + hb * Vector3(0.0, -head_r * 0.10, head_r * 0.10))
	for sgn in [-1.0, 1.0]:
		var sf3: float = sgn
		var boss := CylinderMesh.new()
		boss.top_radius = 0.026
		boss.bottom_radius = 0.030
		boss.height = 0.022
		boss.radial_segments = 12
		var bo_m: MeshInstance3D = _add(root, boss, mat_brass)
		bo_m.transform = Transform3D(hb * Basis(Vector3.FORWARD, PI * 0.5), head_c + hb * Vector3(sf3 * head_r * 1.03, head_r * 0.30, 0.0))
		for k in range(2):
			var kf: float = -1.0 if k == 0 else 1.0
			var bolt := SphereMesh.new()
			bolt.radius = 0.010
			bolt.height = 0.012
			bolt.radial_segments = 8
			bolt.rings = 4
			var bl_m: MeshInstance3D = _add(root, bolt, mat_brass_dk)
			bl_m.transform = Transform3D(Basis(), head_c + hb * Vector3(sf3 * head_r * 1.03, head_r * 0.30 + kf * 0.024, kf * 0.018))

	# --- 5. flesh leg, kneeling ------------------------------------------------
	var knee_r: Vector3 = Vector3(hip_r.x + mir * knee_out, GROUND + 0.088, hip_r.z - 0.215)
	var ankle_r: Vector3 = Vector3(knee_r.x + mir * 0.006, GROUND + 0.064, knee_r.z + 0.395)
	var toe_r: Vector3 = Vector3(knee_r.x + mir * 0.006, GROUND + 0.042, knee_r.z + 0.505)
	_limb(root, hip_r, knee_r, 0.106, mat_flesh)
	_ball(root, knee_r, 0.094, mat_flesh)
	_limb(root, knee_r, ankle_r, 0.083, mat_flesh)
	_ball(root, ankle_r, 0.070, mat_flesh)
	_limb(root, ankle_r, toe_r, 0.056, mat_flesh)
	_ball(root, toe_r, 0.050, mat_flesh_dk)

	# --- 6. brass leg ----------------------------------------------------------
	var knee_l: Vector3 = Vector3(hip_l.x - mir * 0.088, 0.398, hip_l.z - 0.335)
	var ankle_l: Vector3 = Vector3(knee_l.x + mir * 0.016, GROUND + 0.068, knee_l.z - 0.055)
	var toe_l: Vector3 = ankle_l + Vector3(0.0, -0.024, -0.120)
	_ball(root, hip_l, 0.082, mat_brass)
	_pipe(root, hip_l, knee_l, 0.046, 0.038, mat_brass)
	_ball(root, knee_l, 0.058, mat_brass_dk)
	_pipe(root, knee_l, ankle_l, 0.038, 0.033, mat_brass)
	_ball(root, ankle_l, 0.046, mat_brass_dk)
	var foot_l := BoxMesh.new()
	foot_l.size = Vector3(0.095, 0.038, 0.170)
	var fl_m: MeshInstance3D = _add(root, foot_l, mat_iron)
	fl_m.transform = Transform3D(Basis(Vector3.UP, mir * 0.13), (ankle_l + toe_l) * 0.5 + Vector3(0.0, -0.012, 0.0))
	var heel_l := BoxMesh.new()
	heel_l.size = Vector3(0.070, 0.048, 0.052)
	var hl_m: MeshInstance3D = _add(root, heel_l, mat_brass_dk)
	hl_m.transform = Transform3D(Basis(Vector3.UP, mir * 0.13), ankle_l + Vector3(0.0, -0.016, 0.036))
	_pipe(root, knee_l + rt * (-0.052), ankle_l + rt * (-0.030) + Vector3(0.0, 0.0, -0.020), 0.020, 0.016, mat_brass)

	# --- 7. flesh arm, gripping the rail ---------------------------------------
	var hand_c: Vector3 = sho_r + rt * 0.092 + Vector3(0.0, -0.665, -0.300 - lean * 0.10)
	var arm_mid: Vector3 = (sho_r + hand_c) * 0.5
	var elbow_r: Vector3 = arm_mid + rt * 0.078 + Vector3(0.0, 0.024, 0.082)
	var wrist_r: Vector3 = elbow_r.lerp(hand_c, 0.80)
	_ball(root, sho_r, 0.098, mat_flesh)
	_limb(root, sho_r, elbow_r, 0.074, mat_flesh)
	_ball(root, elbow_r, 0.066, mat_flesh)
	_limb(root, elbow_r, wrist_r, 0.058, mat_flesh)
	_ball(root, wrist_r, 0.049, mat_flesh)
	_ball(root, hand_c, 0.058, mat_flesh)
	for k in range(4):
		var kf2: float = float(k) - 1.5
		var fa: Vector3 = hand_c + rt * (kf2 * 0.028) + Vector3(0.0, -0.014, -0.046)
		var fb: Vector3 = hand_c + rt * (kf2 * 0.028) + Vector3(0.0, -0.086, -0.030)
		_limb(root, fa, fb, 0.017, mat_flesh)
	_limb(root, hand_c + rt * (-0.052) + Vector3(0.0, -0.010, 0.010), hand_c + rt * (-0.058) + Vector3(0.0, -0.062, -0.038), 0.019, mat_flesh)

	var rail_a: Vector3 = hand_c + rt * (-0.130) + Vector3(0.0, -0.052, 0.008)
	var rail_b: Vector3 = hand_c + rt * 0.140 + Vector3(0.0, -0.052, -0.026)
	_pipe(root, rail_a, rail_b, 0.026, 0.026, mat_brass)
	for k in range(2):
		var kp: Vector3 = rail_a if k == 0 else rail_b
		var foot_p := Vector3(kp.x, GROUND, kp.z + 0.020)
		_pipe(root, foot_p, kp, 0.022, 0.019, mat_brass)
		_ball(root, kp, 0.031, mat_brass_dk)
		var pad := CylinderMesh.new()
		pad.top_radius = 0.040
		pad.bottom_radius = 0.046
		pad.height = 0.018
		pad.radial_segments = 14
		var pm2: MeshInstance3D = _add(root, pad, mat_iron)
		pm2.transform = Transform3D(Basis(), foot_p + Vector3(0.0, 0.008, 0.0))

	# --- 8. the missing shoulder, capped ---------------------------------------
	_ball(root, sho_l, 0.092, mat_flesh)
	var cap := CylinderMesh.new()
	cap.top_radius = 0.084
	cap.bottom_radius = 0.092
	cap.height = 0.034
	cap.radial_segments = 18
	var cap_ax: Vector3 = (-rt + Vector3(0.0, 0.16, -0.10)).normalized()
	var cm2: MeshInstance3D = _add(root, cap, mat_brass)
	cm2.transform = Transform3D(_basis_y_to(cap_ax), sho_l + cap_ax * 0.062)
	for k in range(3):
		var ang2: float = TAU * float(k) / 3.0 + 0.3
		var cb: Basis = _basis_y_to(cap_ax)
		var bolt2 := SphereMesh.new()
		bolt2.radius = 0.013
		bolt2.height = 0.016
		bolt2.radial_segments = 8
		bolt2.rings = 4
		var b2m: MeshInstance3D = _add(root, bolt2, mat_brass_dk)
		b2m.transform = Transform3D(Basis(), sho_l + cap_ax * 0.078 + cb * Vector3(cos(ang2) * 0.058, 0.0, sin(ang2) * 0.058))
	var stub_end: Vector3 = sho_l + cap_ax * 0.062 + (-rt * 0.9 + Vector3(0.0, -0.55, 0.35)).normalized() * 0.190
	_pipe(root, sho_l + cap_ax * 0.070, stub_end, 0.030, 0.026, mat_brass)
	_ball(root, stub_end, 0.038, mat_brass_dk)

	# --- 9. back mast, arching over the crown ----------------------------------
	var mast: Array = [
		Vector3(mir * 0.010, GROUND, 0.300),
		Vector3(mir * -0.016, 0.420, 0.268),
		Vector3(mir * 0.006, 0.815, 0.205),
		Vector3(mir * 0.024, 1.098, 0.118),
		head_c + Vector3(mir * 0.020, head_r * 0.90, 0.150),
		head_c + Vector3(mir * 0.010, head_r * 1.30, -0.020),
		head_c + Vector3(mir * -0.006, head_r * 0.98, -0.152),
	]
	for i in range(mast.size() - 1):
		var a3: Vector3 = mast[i]
		var b3: Vector3 = mast[i + 1]
		var r0: float = lerpf(0.034, 0.021, float(i) / float(mast.size() - 2))
		var r1: float = lerpf(0.034, 0.021, float(i + 1) / float(mast.size() - 2))
		_pipe(root, a3, b3, r0, r1, mat_brass)
	for i in range(mast.size()):
		var t3: float = float(i) / float(mast.size() - 1)
		var rb: float = lerpf(0.044, 0.028, t3)
		_ball(root, mast[i], rb, mat_brass_dk)

	# --- 10. the lens on its swan neck ------------------------------------------
	var mast_tip: Vector3 = mast[6]
	var mast_chest: Vector3 = mast[2]
	var lens_c: Vector3 = mast_tip + Vector3(0.0, -0.088, -0.020)
	_pipe(root, mast_tip, lens_c, 0.016, 0.013, mat_brass)
	var lens_ax: Vector3 = (head_c - lens_c).normalized()
	var rim: TorusMesh = _torus_mesh(0.045, 0.058)
	var rim_m: MeshInstance3D = _add(root, rim, mat_brass)
	rim_m.transform = Transform3D(_basis_y_to(lens_ax), lens_c)
	var glass := CylinderMesh.new()
	glass.top_radius = 0.047
	glass.bottom_radius = 0.047
	glass.height = 0.010
	glass.radial_segments = 18
	var gl_m: MeshInstance3D = _add(root, glass, mat_lens)
	gl_m.transform = Transform3D(_basis_y_to(lens_ax), lens_c)

	# --- 11. shoulder yoke ------------------------------------------------------
	var yoke_a: Vector3 = sho_l + Vector3(0.0, 0.040, 0.030)
	var yoke_b: Vector3 = sho_r + Vector3(0.0, 0.040, 0.030)
	_pipe(root, yoke_a, yoke_b, 0.028, 0.028, mat_brass)
	_ball(root, yoke_a, 0.038, mat_brass_dk)
	_ball(root, yoke_b, 0.038, mat_brass_dk)

	# --- 12. hip girdle ---------------------------------------------------------
	var girdle: Array = []
	var g_ctr: Vector3 = p_hip + Vector3(0.0, 0.032, 0.020)
	for i in range(6):
		var ang3: float = TAU * float(i) / 6.0 + 0.26
		girdle.append(g_ctr + Vector3(cos(ang3) * 0.268 * mir, sin(ang3 * 2.0) * 0.030, sin(ang3) * 0.222))
	for i in range(6):
		var a4: Vector3 = girdle[i]
		var b4: Vector3 = girdle[(i + 1) % 6]
		_pipe(root, a4, b4, 0.024, 0.024, mat_brass)
		_ball(root, a4, 0.033, mat_brass_dk)

	# --- 13. thigh brace on the flesh leg ---------------------------------------
	var br_out: Vector3 = (rt * 0.86 + Vector3(0.0, 0.10, -0.50)).normalized()
	var br_a: Vector3 = hip_r + br_out * 0.118
	var br_b: Vector3 = hip_r.lerp(knee_r, 0.56) + br_out * 0.128
	var br_c: Vector3 = knee_r + br_out * 0.108 + Vector3(0.0, 0.010, 0.0)
	_pipe(root, br_a, br_b, 0.021, 0.021, mat_brass)
	_pipe(root, br_b, br_c, 0.021, 0.019, mat_brass)
	_ball(root, br_a, 0.030, mat_brass_dk)
	_ball(root, br_b, 0.030, mat_brass_dk)
	_ball(root, br_c, 0.028, mat_brass_dk)

	# --- 14. chest and waist bands ----------------------------------------------
	var i_chest: int = int(floor(float(n_spine - 1) * 0.72))
	var i_waist: int = int(floor(float(n_spine - 1) * 0.34))
	var chest_p: Vector3 = spine_pts[i_chest]
	var waist_p: Vector3 = spine_pts[i_waist]
	var band_c: TorusMesh = _torus_mesh(spine_rad[i_chest] * 1.02, spine_rad[i_chest] * 1.02 + 0.024)
	var bc_m: MeshInstance3D = _add(root, band_c, mat_brass)
	bc_m.transform = Transform3D(_basis_y_to(_tangent(spine_pts, i_chest)), chest_p)
	var band_w: TorusMesh = _torus_mesh(spine_rad[i_waist] * 1.02, spine_rad[i_waist] * 1.02 + 0.020)
	var bw_m: MeshInstance3D = _add(root, band_w, mat_brass_dk)
	bw_m.transform = Transform3D(_basis_y_to(_tangent(spine_pts, i_waist)), waist_p)

	# --- 15. flanges at the couplings -------------------------------------------
	var flange_at: Array = [mast[1], mast[2], mast[3], girdle[0], girdle[3], br_b]
	var flange_ax: Array = [
		(mast[2] - mast[0]).normalized(),
		(mast[3] - mast[1]).normalized(),
		(mast[4] - mast[2]).normalized(),
		(girdle[1] - girdle[5]).normalized(),
		(girdle[4] - girdle[2]).normalized(),
		(br_c - br_a).normalized(),
	]
	for i in range(6):
		var fa2: Vector3 = flange_at[i]
		var fx: Vector3 = flange_ax[i]
		var fl: TorusMesh = _torus_mesh(0.030, 0.048)
		var fm2: MeshInstance3D = _add(root, fl, mat_brass_dk)
		fm2.transform = Transform3D(_basis_y_to(fx), fa2)

	# --- 16. valve blocks --------------------------------------------------------
	var valve_at: Array = [
		girdle[1] + rt * 0.028,
		girdle[4] - rt * 0.028,
		mast[2] + Vector3(mir * 0.070, 0.020, 0.010),
		mast[3] + Vector3(mir * -0.072, 0.014, 0.006),
		br_b + br_out * 0.040,
	]
	var valve_ax: Array = [
		(rt * 0.9 + Vector3(0.0, 0.2, 0.4)).normalized(),
		(-rt * 0.9 + Vector3(0.0, 0.2, 0.4)).normalized(),
		(rt + Vector3(0.0, 0.35, 0.20)).normalized(),
		(-rt + Vector3(0.0, 0.30, 0.10)).normalized(),
		br_out,
	]
	for i in range(n_valves):
		var vp: Vector3 = valve_at[i]
		var vx: Vector3 = valve_ax[i]
		var vb: Basis = _basis_y_to(vx)
		var vbody := BoxMesh.new()
		vbody.size = Vector3(0.070, 0.058, 0.062)
		var vm: MeshInstance3D = _add(root, vbody, mat_brass)
		vm.transform = Transform3D(vb, vp)
		var stem := CylinderMesh.new()
		stem.top_radius = 0.010
		stem.bottom_radius = 0.013
		stem.height = 0.058
		stem.radial_segments = 10
		var sm2: MeshInstance3D = _add(root, stem, mat_brass_dk)
		sm2.transform = Transform3D(vb, vp + vx * 0.052)
		var wheel: TorusMesh = _torus_mesh(0.026, 0.040)
		var wm: MeshInstance3D = _add(root, wheel, mat_brass_dk)
		wm.transform = Transform3D(vb, vp + vx * 0.082)

	# --- 17. gears ---------------------------------------------------------------
	var gear_at: Array = [
		hip_r + rt * 0.086 + Vector3(0.0, 0.048, 0.030),
		knee_l - rt * 0.062,
		mast[2] + Vector3(mir * 0.098, 0.108, -0.014),
		hip_l - rt * 0.078 + Vector3(0.0, 0.062, 0.052),
	]
	var gear_ax: Array = [rt, -rt, (rt * 0.30 + Vector3(0.0, 0.0, 1.0)).normalized(), -rt]
	var gear_rad: Array = [0.104, 0.086, 0.092, 0.072]
	for i in range(n_gears):
		var gp: Vector3 = gear_at[i]
		var gx: Vector3 = gear_ax[i]
		var gr: float = gear_rad[i]
		_gear(root, gp, gx, gr, gear_teeth, 0.030, mat_brass, mat_brass_dk)

	# --- 18. coil springs --------------------------------------------------------
	var coil_top: Vector3 = stub_end + Vector3(0.0, -0.020, 0.010)
	var coil_bot: Vector3 = girdle[4] + Vector3(0.0, 0.036, 0.012)
	_coil_beads(root, coil_top, coil_bot, 0.038, 0.0145, 5.0, coil_a, mat_brass_dk)
	_coil_beads(root, br_a + br_out * 0.028, br_b + br_out * 0.030, 0.036, 0.0135, 3.5, coil_b, mat_brass_dk)
	var helix_pts: Array = _helix_points(mast_chest + Vector3(mir * -0.060, -0.030, -0.010), knee_l + Vector3(0.0, 0.070, 0.040), 0.040, 7.0, 46)
	var tube: ArrayMesh = _tube_mesh(helix_pts, 0.0115, 7)
	var tm2: MeshInstance3D = _add(root, tube, mat_brass_dk)
	tm2.transform = Transform3D(Basis(), Vector3.ZERO)

	# --- 19. dusty pink armour plates --------------------------------------------
	var plate_a: Array = [hip_r + Vector3(0.0, -0.020, -0.010), sho_r + Vector3(0.0, -0.030, 0.000), p_sho - rt * 0.070 + Vector3(0.0, 0.010, 0.010), hip_l + Vector3(0.0, -0.010, -0.010), waist_p + Vector3(0.0, 0.040, 0.030)]
	var plate_b: Array = [hip_r.lerp(knee_r, 0.74), elbow_r + Vector3(0.0, 0.020, 0.000), sho_l + Vector3(0.0, -0.030, 0.020), hip_l.lerp(knee_l, 0.78), waist_p + Vector3(0.0, -0.115, 0.030)]
	var plate_out: Array = [
		(rt * 0.80 + Vector3(0.0, 0.16, -0.58)).normalized(),
		(rt * 0.92 + Vector3(0.0, 0.10, -0.38)).normalized(),
		(-rt * 0.62 + Vector3(0.0, 0.66, -0.42)).normalized(),
		(-rt * 0.76 + Vector3(0.0, 0.14, -0.64)).normalized(),
		Vector3(0.0, 0.22, 0.98).normalized(),
	]
	var plate_rad: Array = [0.140, 0.098, 0.132, 0.110, 0.155]
	var plate_arc: Array = [1.08, 1.02, 0.92, 1.00, 0.86]
	for i in range(n_plates):
		var pa2: Vector3 = plate_a[i]
		var pb2: Vector3 = plate_b[i]
		var po: Vector3 = plate_out[i]
		var prd: float = plate_rad[i]
		var parc: float = plate_arc[i]
		var mat_this: StandardMaterial3D = mat_plate if (i % 2) == 0 else mat_plate_lo
		var shell: ArrayMesh = _shell_mesh(pa2, pb2, po, prd, parc, 0.016, 0.86)
		var sh_m: MeshInstance3D = _add(root, shell, mat_this)
		sh_m.transform = Transform3D(Basis(), Vector3.ZERO)
		var ax5: Vector3 = (pb2 - pa2).normalized()
		var u5: Vector3 = (po - ax5 * po.dot(ax5)).normalized()
		var w5: Vector3 = ax5.cross(u5).normalized()
		for k in range(2):
			var sfrac: float = 0.24 if k == 0 else 0.76
			var rr: float = prd * lerpf(1.0, 0.86, sfrac)
			var strap: TorusMesh = _torus_mesh(rr * 0.90, rr + 0.030)
			var st_m: MeshInstance3D = _add(root, strap, mat_strap)
			st_m.transform = Transform3D(_basis_y_to(ax5), pa2.lerp(pb2, sfrac))
		for k in range(3):
			var sf5: float = lerpf(0.18, 0.82, float(k) / 2.0)
			var ang5: float = parc * (-0.62 + 0.62 * float(k))
			var rr2: float = prd * lerpf(1.0, 0.86, sf5) + 0.018
			var rp2: Vector3 = pa2.lerp(pb2, sf5) + (u5 * cos(ang5) + w5 * sin(ang5)) * rr2
			var riv2 := SphereMesh.new()
			riv2.radius = 0.011
			riv2.height = 0.013
			riv2.radial_segments = 8
			riv2.rings = 4
			var rv_m: MeshInstance3D = _add(root, riv2, mat_brass_dk)
			rv_m.transform = Transform3D(Basis(), rp2)

	# --- 20. settle: fit the box, stand on the floor, centre on x/z ---------------
	var box: AABB = _union_aabb(root)
	if box.size.y < 1.36:
		var ku: float = minf(1.36 / maxf(box.size.y, 0.01), minf(1.20 / maxf(box.size.x, 0.01), 1.20 / maxf(box.size.z, 0.01)))
		if ku > 1.0:
			_scale_all(root, ku)
			box = _union_aabb(root)
	var kx: float = 1.20 / maxf(box.size.x, 0.01)
	var kz: float = 1.20 / maxf(box.size.z, 0.01)
	var ky: float = 1.68 / maxf(box.size.y, 0.01)
	var kfit: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kfit < 1.0:
		_scale_all(root, kfit)
		box = _union_aabb(root)
	var centre_v: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-centre_v.x, -box.position.y, -centre_v.z)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cmi: MeshInstance3D = ch
		cmi.transform = Transform3D(cmi.transform.basis, cmi.transform.origin + shift)


# ---------------------------------------------------------------------------
# primitive helpers

static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _basis_y_to(dir_v: Vector3) -> Basis:
	var d: Vector3 = dir_v.normalized()
	if d.length_squared() < 0.0001:
		return Basis()
	var dot_up: float = d.dot(Vector3.UP)
	if dot_up > 0.9999:
		return Basis()
	if dot_up < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	var ax: Vector3 = Vector3.UP.cross(d).normalized()
	var ang: float = acos(clampf(dot_up, -1.0, 1.0))
	return Basis(ax, ang)


static func _limb(root: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.012)
	var capm := CapsuleMesh.new()
	capm.radius = r
	capm.height = maxf(ln + r * 1.05, r * 2.04)
	capm.radial_segments = 14
	capm.rings = 6
	var mi: MeshInstance3D = _add(root, capm, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _pipe(root: Node3D, a: Vector3, b: Vector3, r0: float, r1: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.012)
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = r0
	cyl.top_radius = r1
	cyl.height = ln
	cyl.radial_segments = 14
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _cone(root: Node3D, base_p: Vector3, dir_v: Vector3, h: float, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = dir_v.normalized()
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = r
	cyl.top_radius = 0.0
	cyl.height = h
	cyl.radial_segments = 10
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(d), base_p + d * (h * 0.5))
	return mi


static func _ball(root: Node3D, p: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var sph := SphereMesh.new()
	sph.radius = r
	sph.height = r * 2.0
	sph.radial_segments = 16
	sph.rings = 9
	var mi: MeshInstance3D = _add(root, sph, mat)
	mi.transform = Transform3D(Basis(), p)
	return mi


static func _torus_mesh(inner: float, outer: float) -> TorusMesh:
	var tor := TorusMesh.new()
	tor.inner_radius = maxf(inner, 0.002)
	tor.outer_radius = maxf(outer, inner + 0.004)
	tor.rings = 20
	tor.ring_segments = 10
	return tor


static func _gear(root: Node3D, ctr: Vector3, ax: Vector3, r: float, teeth: int, thick: float, mat: StandardMaterial3D, mat_hub: StandardMaterial3D) -> void:
	var gb: Basis = _basis_y_to(ax)
	var disc := CylinderMesh.new()
	disc.top_radius = r
	disc.bottom_radius = r
	disc.height = thick
	disc.radial_segments = 22
	var dm: MeshInstance3D = _add(root, disc, mat)
	dm.transform = Transform3D(gb, ctr)
	var hub := CylinderMesh.new()
	hub.top_radius = r * 0.27
	hub.bottom_radius = r * 0.27
	hub.height = thick * 2.15
	hub.radial_segments = 12
	var hm: MeshInstance3D = _add(root, hub, mat_hub)
	hm.transform = Transform3D(gb, ctr)
	var tl: float = r * 0.26
	var tw: float = maxf(TAU * r / float(teeth) * 0.50, 0.008)
	for i in range(teeth):
		var ang: float = TAU * float(i) / float(teeth)
		var lp := Vector3(cos(ang) * (r + tl * 0.44), 0.0, sin(ang) * (r + tl * 0.44))
		var tooth := BoxMesh.new()
		tooth.size = Vector3(tl, thick * 0.88, tw)
		var tm: MeshInstance3D = _add(root, tooth, mat)
		tm.transform = Transform3D(gb * Basis(Vector3.UP, -ang), ctr + gb * lp)


static func _helix_points(a: Vector3, b: Vector3, r_helix: float, coils: float, steps: int) -> Array:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.02)
	var ax: Vector3 = d / ln
	var refv: Vector3 = Vector3.UP if absf(ax.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var u: Vector3 = (refv - ax * refv.dot(ax)).normalized()
	var w: Vector3 = ax.cross(u).normalized()
	var pts: Array = []
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var ph: float = t * coils * TAU
		var fade: float = clampf(minf(t, 1.0 - t) * 5.0, 0.25, 1.0)
		pts.append(a + ax * (ln * t) + (u * cos(ph) + w * sin(ph)) * (r_helix * fade))
	return pts


static func _coil_beads(root: Node3D, a: Vector3, b: Vector3, r_helix: float, r_wire: float, coils: float, n: int, mat: StandardMaterial3D) -> void:
	var pts: Array = _helix_points(a, b, r_helix, coils, maxi(n - 1, 2))
	for i in range(pts.size()):
		var p: Vector3 = pts[i]
		_ball(root, p, r_wire, mat)


# ---------------------------------------------------------------------------
# SurfaceTool shapes

static func _quad_n(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, want: Vector3) -> void:
	var nf: Vector3 = (c - a).cross(b - a)
	if nf.dot(want) >= 0.0:
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


static func _tube_mesh(pts: Array, r: float, sides: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = pts.size()
	var us: Array = []
	var ws: Array = []
	var prev_u := Vector3.ZERO
	for i in range(n):
		var pa: Vector3 = pts[maxi(i - 1, 0)]
		var pb: Vector3 = pts[mini(i + 1, n - 1)]
		var tv: Vector3 = pb - pa
		if tv.length() < 0.00001:
			tv = Vector3.UP
		tv = tv.normalized()
		var u: Vector3 = Vector3.ZERO
		if i == 0:
			var refv: Vector3 = Vector3.UP if absf(tv.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
			u = (refv - tv * refv.dot(tv)).normalized()
		else:
			u = (prev_u - tv * prev_u.dot(tv)).normalized()
			if u.length_squared() < 0.0001:
				u = (Vector3.RIGHT - tv * tv.x).normalized()
		prev_u = u
		us.append(u)
		ws.append(tv.cross(u).normalized())
	for i in range(n - 1):
		var pa2: Vector3 = pts[i]
		var pb2: Vector3 = pts[i + 1]
		var ua: Vector3 = us[i]
		var wa: Vector3 = ws[i]
		var ub: Vector3 = us[i + 1]
		var wb: Vector3 = ws[i + 1]
		for j in range(sides):
			var a0: float = TAU * float(j) / float(sides)
			var a1: float = TAU * float(j + 1) / float(sides)
			var q00: Vector3 = pa2 + (ua * cos(a0) + wa * sin(a0)) * r
			var q01: Vector3 = pa2 + (ua * cos(a1) + wa * sin(a1)) * r
			var q10: Vector3 = pb2 + (ub * cos(a0) + wb * sin(a0)) * r
			var q11: Vector3 = pb2 + (ub * cos(a1) + wb * sin(a1)) * r
			var mid: Vector3 = (pa2 + pb2) * 0.5
			var nrm: Vector3 = ((q00 + q01 + q10 + q11) * 0.25 - mid).normalized()
			_quad_n(st, q00, q01, q11, q10, nrm)
	st.generate_normals()
	return st.commit()


static func _shell_mesh(a: Vector3, b: Vector3, outward: Vector3, rad: float, half_ang: float, thick: float, taper: float) -> ArrayMesh:
	# a thin curved armour plate wrapped round the axis a->b, open on the far side
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.02)
	var ax: Vector3 = d / ln
	var u: Vector3 = outward - ax * outward.dot(ax)
	if u.length_squared() < 0.00001:
		u = Vector3.UP - ax * ax.y
	u = u.normalized()
	var w: Vector3 = ax.cross(u).normalized()
	var ns: int = 8
	var na: int = 10
	var outer: Array = []
	var inner: Array = []
	for i in range(ns + 1):
		var s: float = float(i) / float(ns)
		var rr: float = rad * lerpf(1.0, taper, s)
		var arc: float = half_ang * (1.0 - 0.26 * pow(2.0 * s - 1.0, 4.0))
		var ctr: Vector3 = a + ax * (ln * s)
		var row_o: Array = []
		var row_i: Array = []
		for j in range(na + 1):
			var f: float = float(j) / float(na)
			var ph: float = lerpf(-arc, arc, f)
			var rd: Vector3 = u * cos(ph) + w * sin(ph)
			row_o.append(ctr + rd * (rr + thick))
			row_i.append(ctr + rd * rr)
		outer.append(row_o)
		inner.append(row_i)
	for i in range(ns):
		var ro0: Array = outer[i]
		var ro1: Array = outer[i + 1]
		var ri0: Array = inner[i]
		var ri1: Array = inner[i + 1]
		var mid_c: Vector3 = a + ax * (ln * (float(i) + 0.5) / float(ns))
		for j in range(na):
			var o00: Vector3 = ro0[j]
			var o01: Vector3 = ro0[j + 1]
			var o10: Vector3 = ro1[j]
			var o11: Vector3 = ro1[j + 1]
			var n_out: Vector3 = ((o00 + o01 + o10 + o11) * 0.25 - mid_c).normalized()
			_quad_n(st, o00, o01, o11, o10, n_out)
			var i00: Vector3 = ri0[j]
			var i01: Vector3 = ri0[j + 1]
			var i10: Vector3 = ri1[j]
			var i11: Vector3 = ri1[j + 1]
			_quad_n(st, i00, i01, i11, i10, -n_out)
		# side rims
		var e_a0: Vector3 = ro0[0]
		var e_a1: Vector3 = ro1[0]
		var e_b0: Vector3 = ri0[0]
		var e_b1: Vector3 = ri1[0]
		var tan0: Vector3 = (ro0[1] - ro0[0]).normalized()
		_quad_n(st, e_a0, e_a1, e_b1, e_b0, -tan0)
		var f_a0: Vector3 = ro0[na]
		var f_a1: Vector3 = ro1[na]
		var f_b0: Vector3 = ri0[na]
		var f_b1: Vector3 = ri1[na]
		var tan1: Vector3 = (ro0[na] - ro0[na - 1]).normalized()
		_quad_n(st, f_a0, f_a1, f_b1, f_b0, tan1)
	# end caps
	var o_first: Array = outer[0]
	var i_first: Array = inner[0]
	var o_last: Array = outer[ns]
	var i_last: Array = inner[ns]
	for j in range(na):
		var c00: Vector3 = o_first[j]
		var c01: Vector3 = o_first[j + 1]
		var c10: Vector3 = i_first[j]
		var c11: Vector3 = i_first[j + 1]
		_quad_n(st, c00, c01, c11, c10, -ax)
		var d00: Vector3 = o_last[j]
		var d01: Vector3 = o_last[j + 1]
		var d10: Vector3 = i_last[j]
		var d11: Vector3 = i_last[j + 1]
		_quad_n(st, d00, d01, d11, d10, ax)
	st.generate_normals()
	return st.commit()


# ---------------------------------------------------------------------------
# painted surfaces

static func _grid_noise(rng: RandomNumberGenerator, n: int) -> PackedFloat32Array:
	var g := PackedFloat32Array()
	g.resize(n * n)
	for i in range(n * n):
		g[i] = rng.randf()
	return g


static func _samp(g: PackedFloat32Array, n: int, u: float, v: float) -> float:
	var fx: float = u * float(n)
	var fy: float = v * float(n)
	var x0: int = int(floor(fx))
	var y0: int = int(floor(fy))
	var tx: float = fx - float(x0)
	var ty: float = fy - float(y0)
	var sx: float = tx * tx * (3.0 - 2.0 * tx)
	var sy: float = ty * ty * (3.0 - 2.0 * ty)
	var xa: int = posmod(x0, n)
	var xb: int = posmod(x0 + 1, n)
	var ya: int = posmod(y0, n)
	var yb: int = posmod(y0 + 1, n)
	var v00: float = g[ya * n + xa]
	var v10: float = g[ya * n + xb]
	var v01: float = g[yb * n + xa]
	var v11: float = g[yb * n + xb]
	var ra: float = lerpf(v00, v10, sx)
	var rb: float = lerpf(v01, v11, sx)
	return lerpf(ra, rb, sy)


static func _brass_texture(rng: RandomNumberGenerator) -> ImageTexture:
	# lathe banding + patina flecks; near-white so albedo_color carries the hue
	var img: Image = Image.create(TEX_BRASS, TEX_BRASS, false, Image.FORMAT_RGB8)
	var coarse: PackedFloat32Array = _grid_noise(rng, 8)
	var fine: PackedFloat32Array = _grid_noise(rng, 24)
	var phase: float = rng.randf() * TAU
	var bands: float = float(rng.randi_range(9, 16))
	for y in range(TEX_BRASS):
		for x in range(TEX_BRASS):
			var u: float = float(x) / float(TEX_BRASS)
			var v: float = float(y) / float(TEX_BRASS)
			var band: float = 0.055 * sin(v * TAU * bands + phase)
			var lo: float = _samp(coarse, 8, u, v)
			var hi: float = _samp(fine, 24, u, v)
			var patina: float = clampf((lo - 0.66) * 3.0, 0.0, 1.0)
			var val: float = 0.90 + band + (hi - 0.5) * 0.075
			val = lerpf(val, 0.61, patina * 0.55)
			val = clampf(val, 0.40, 1.0)
			var gtint: float = clampf(val * (1.0 - patina * 0.10), 0.0, 1.0)
			var btint: float = clampf(val * (1.0 - patina * 0.20), 0.0, 1.0)
			img.set_pixel(x, y, Color(clampf(val, 0.0, 1.0), gtint, btint))
	return ImageTexture.create_from_image(img)


static func _paint_texture(rng: RandomNumberGenerator) -> ImageTexture:
	# dusty rose paint with scuffs and chips
	var img: Image = Image.create(TEX_PAINT, TEX_PAINT, false, Image.FORMAT_RGB8)
	var blotch: PackedFloat32Array = _grid_noise(rng, 6)
	var speck: PackedFloat32Array = _grid_noise(rng, 32)
	var streak: float = rng.randf_range(0.6, 2.4)
	for y in range(TEX_PAINT):
		for x in range(TEX_PAINT):
			var u: float = float(x) / float(TEX_PAINT)
			var v: float = float(y) / float(TEX_PAINT)
			var lo: float = _samp(blotch, 6, u, v)
			var hi: float = _samp(speck, 32, u, v)
			var scuff: float = clampf((lo - 0.58) * 2.6, 0.0, 1.0)
			var line: float = 0.030 * sin((u * streak + v * 1.7) * TAU * 3.0)
			var val: float = 0.94 + line + (hi - 0.5) * 0.055
			val = lerpf(val, 1.0, scuff * 0.35)
			var chip: float = clampf((hi - 0.90) * 9.0, 0.0, 1.0)
			val = lerpf(val, 0.58, chip * 0.7)
			val = clampf(val, 0.40, 1.0)
			img.set_pixel(x, y, Color(val, clampf(val * 0.985, 0.0, 1.0), clampf(val * 0.975, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


static func _flesh_texture(rng: RandomNumberGenerator) -> ImageTexture:
	var img: Image = Image.create(TEX_FLESH, TEX_FLESH, false, Image.FORMAT_RGB8)
	var soft: PackedFloat32Array = _grid_noise(rng, 5)
	var micro: PackedFloat32Array = _grid_noise(rng, 20)
	for y in range(TEX_FLESH):
		for x in range(TEX_FLESH):
			var u: float = float(x) / float(TEX_FLESH)
			var v: float = float(y) / float(TEX_FLESH)
			var lo: float = _samp(soft, 5, u, v)
			var hi: float = _samp(micro, 20, u, v)
			var val: float = 0.965 + (lo - 0.5) * 0.045 + (hi - 0.5) * 0.022
			val = clampf(val, 0.80, 1.0)
			img.set_pixel(x, y, Color(val, clampf(val * 0.994, 0.0, 1.0), clampf(val * 0.988, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


static func _skin(c: Color, tex: ImageTexture, sc: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(sc, sc, sc)
	m.roughness = 0.52
	m.metallic = 0.0
	m.clearcoat_enabled = true
	m.clearcoat = 0.22
	m.clearcoat_roughness = 0.45
	return m


static func _metal(c: Color, tex: ImageTexture, sc: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(sc, sc, sc)
	m.roughness = rough
	m.metallic = 0.9
	m.metallic_specular = 0.6
	return m


static func _paint(c: Color, tex: ImageTexture, sc: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(sc, sc, sc)
	m.roughness = 0.62
	m.metallic = 0.08
	m.clearcoat_enabled = true
	m.clearcoat = 0.18
	m.clearcoat_roughness = 0.55
	return m


# ---------------------------------------------------------------------------
# profile, frame and settle

static func _torso_r(t: float) -> float:
	var keys: Array = [0.152, 0.136, 0.120, 0.124, 0.146, 0.158, 0.138]
	var f: float = t * 6.0
	var i: int = int(floor(f))
	if i >= 6:
		return keys[6]
	var u: float = f - float(i)
	var va: float = keys[i]
	var vb: float = keys[i + 1]
	return lerpf(va, vb, u)


static func _tangent(pts: Array, i: int) -> Vector3:
	var n: int = pts.size()
	var a: Vector3 = pts[maxi(i - 1, 0)]
	var b: Vector3 = pts[mini(i + 1, n - 1)]
	var d: Vector3 = b - a
	if d.length() < 0.0001:
		return Vector3.UP
	return d.normalized()


static func _scale_all(root: Node3D, k: float) -> void:
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cmi: MeshInstance3D = ch
		var tf: Transform3D = cmi.transform
		cmi.transform = Transform3D(tf.basis.scaled(Vector3(k, k, k)), tf.origin * k)


static func _union_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cmi: MeshInstance3D = ch
		if cmi.mesh == null:
			continue
		var local: AABB = cmi.mesh.get_aabb()
		var wb: AABB = cmi.transform * local
		if first:
			box = wb
			first = false
		else:
			box = box.merge(wb)
	return box
