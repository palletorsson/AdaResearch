extends RefCounted

## dream_bodies / porcelain_doll — one renaissance ball-jointed doll, bandage-wrapped,
## in a stiff gold bodice, reaching.
##
## Reference: scratchpad/refs/renaissance_smoke.png (2048x536 panorama) — a crowd of
## bald porcelain dolls pressed together in front of a painted grove: pale pink cloth
## wound in close bands around every limb, ball joints showing at shoulder and elbow,
## painted dark eyes and a small red mouth on smooth egg heads, one figure in a stiff
## gold brocade bodice with a high standing collar, one printed with a red maze, thin
## wires holding the arms out. I build ONE of them, the reaching one.
##
## Reproduced, and how:
##   1. Bald porcelain egg head, tilted — an ellipsoid SphereMesh (r 0.098, h 0.25) on a
##      leaning neck, with a chin sphere and two flattened ears; yaw, roll and pitch all
##      drawn from the seed so the head cocks a different way each time.
##   2. The painted face — dark almond lenses (SphereMesh squashed to 0.52 x 0.28) sunk
##      into the skull so only the paint shows, thin box lash lines and brows, and a
##      three-box red mouth; every mark placed on the true ellipsoid surface by _face_z.
##   3. The wrapping — 51..79 TorusMesh bands threaded along each limb segment, tube
##      centred just proud of the skin, each turned about the limb axis by a precessing
##      phase and slanted 8..15 deg, so the run reads as one spiral with gaps between.
##   4. Visible ball joints — spheres a shade greyer and glossier than the skin, larger
##      than the capsule they interrupt, at shoulder, elbow, wrist, hip, knee and ankle.
##   5. The stiff bodice — a SurfaceTool loft (15 rings x 24) over the torso with two
##      bust lobes, a V-dipped stomacher hem, a gold hem torus and two shoulder caps.
##   6. The high collar — a second loft whose rim height runs with the angle, low at the
##      throat and standing tall behind the neck.
##   7. Brocade — a 256x256 ImageTexture painted in code: brick-offset ogee cells with
##      ring, diamond and dot motifs in bright thread over dark gold, plus a diagonal
##      weave; world triplanar so it runs unbroken across shell, collar and caps.
##   8. Red maze skin — by seed, a binary-maze texture in terracotta on cream replaces
##      the plain porcelain and runs triplanar across the whole body; and either way the
##      porcelain carries a clearcoat gloss. Two or three wires hold the reach up.
##
## Given up: the crowd and the painted grove behind it, the creases and frayed ends of
## real bandage (my bands are clean toruses), the wigged figure with the red hair,
## translucency in the porcelain, the lace at the bodice hem, fingernails, and the tiny
## hinge hardware inside the joints.

const TEX_SIZE: int = 256


static func describe() -> String:
	return "A bald porcelain doll standing in a stiff gold brocade bodice with a high collar, her limbs bound in spiralling pale pink bandage over visible ball joints, one arm reaching out on thin wires."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- variant ------------------------------------------------------------
	var maze_skin: bool = rng.randf() < 0.45
	var reach_side: float = -1.0 if rng.randf() < 0.5 else 1.0
	var free_side: float = -reach_side if rng.randf() < 0.7 else reach_side

	# --- materials ----------------------------------------------------------
	var mat_skin := _porcelain(Color("#F6EAE2"), 0.18)
	if maze_skin:
		mat_skin = _porcelain(Color("#FFFFFF"), 0.24)
		mat_skin.albedo_texture = _maze_texture(rng)
		mat_skin.uv1_triplanar = true
		mat_skin.uv1_world_triplanar = true
		mat_skin.uv1_scale = Vector3(1.9, 1.9, 1.9)
	var mat_head: StandardMaterial3D = mat_skin
	var mat_joint := _porcelain(Color("#E6D8D0"), 0.12)
	var mat_eye := _porcelain(Color("#241C1E"), 0.10)
	var mat_line := _porcelain(Color("#3A2A28"), 0.30)
	var mat_mouth := _porcelain(Color("#B34A44"), 0.22)

	var band_mats: Array = []
	for i in range(4):
		var tone: float = float(i) / 3.0
		var bm := StandardMaterial3D.new()
		bm.albedo_color = Color("#F2CFC9").lerp(Color("#E0AEA8"), tone * rng.randf_range(0.5, 1.0))
		bm.roughness = rng.randf_range(0.62, 0.78)
		bm.metallic = 0.0
		band_mats.append(bm)

	var brocade: ImageTexture = _brocade_texture(rng)
	var mat_gold := StandardMaterial3D.new()
	mat_gold.albedo_color = Color("#FFF3DC")
	mat_gold.albedo_texture = brocade
	mat_gold.uv1_triplanar = true
	mat_gold.uv1_world_triplanar = true
	mat_gold.uv1_scale = Vector3(3.4, 3.4, 3.4)
	mat_gold.metallic = 0.82
	mat_gold.roughness = 0.31
	mat_gold.cull_mode = BaseMaterial3D.CULL_DISABLED

	var mat_trim := StandardMaterial3D.new()
	mat_trim.albedo_color = Color("#D8B054")
	mat_trim.metallic = 0.9
	mat_trim.roughness = 0.24

	var mat_wire := StandardMaterial3D.new()
	mat_wire.albedo_color = Color("#4A4744")
	mat_wire.metallic = 0.85
	mat_wire.roughness = 0.38

	# --- proportions --------------------------------------------------------
	var y_ankle: float = 0.078
	var y_knee: float = rng.randf_range(0.395, 0.435)
	var y_hip: float = rng.randf_range(0.825, 0.870)
	var y_shoulder: float = y_hip + rng.randf_range(0.400, 0.440)
	var lean_x: float = rng.randf_range(-0.055, 0.055)
	var lean_z: float = rng.randf_range(0.010, 0.070)
	var t_base := Vector3(0.0, y_hip, 0.0)
	var t_dir: Vector3 = Vector3(lean_x, 1.0, lean_z).normalized()
	var t_len: float = (y_shoulder - y_hip) / maxf(t_dir.y, 0.5)

	var hip_half: float = rng.randf_range(0.088, 0.104)
	var band_tilt: float = deg_to_rad(rng.randf_range(8.0, 15.0))
	var band_step: float = TAU / rng.randf_range(4.4, 6.6)

	# --- legs ---------------------------------------------------------------
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var is_free: bool = absf(sd - free_side) < 0.5
		var out_k: float = rng.randf_range(0.030, 0.062) if is_free else rng.randf_range(0.0, 0.012)
		var fwd_k: float = rng.randf_range(-0.115, -0.060) if is_free else rng.randf_range(-0.015, 0.020)
		var hip_p := Vector3(sd * hip_half, y_hip - 0.045, 0.004)
		var knee_p := Vector3(sd * (hip_half * 0.90 + out_k * 0.55), y_knee, fwd_k * 0.45 + rng.randf_range(-0.012, 0.012))
		var ankle_p := Vector3(sd * (hip_half * 0.82 + out_k), y_ankle, fwd_k)
		var r_thigh: float = rng.randf_range(0.062, 0.070)
		var r_shin: float = rng.randf_range(0.043, 0.050)

		_limb(root, hip_p, knee_p, r_thigh * 0.86, mat_skin)
		_limb(root, knee_p, ankle_p, r_shin * 0.86, mat_skin)
		_ball(root, hip_p, r_thigh * 1.06, mat_joint)
		_ball(root, knee_p, r_shin * 1.16, mat_joint)
		_ball(root, ankle_p, r_shin * 0.92, mat_joint)

		var n_thigh: int = rng.randi_range(7, 10)
		var n_shin: int = rng.randi_range(6, 9)
		# the wrap tapers, but never below the capsule under it or the band vanishes
		_wrap(root, hip_p, knee_p, r_thigh, r_thigh * 0.90, n_thigh, 0.0060, band_tilt, rng.randf_range(0.0, TAU), band_step, band_mats)
		_wrap(root, knee_p, ankle_p, r_shin * 1.05, r_shin * 0.94, n_shin, 0.0052, band_tilt, rng.randf_range(0.0, TAU), band_step, band_mats)

		# foot: a turned-out block, sole flat on the floor
		var foot_yaw: float = sd * rng.randf_range(0.12, 0.34)
		var fb: Basis = Basis(Vector3.UP, foot_yaw)
		var box := BoxMesh.new()
		box.size = Vector3(0.076, 0.050, 0.180)
		var foot_c: Vector3 = ankle_p + fb * Vector3(0.0, 0.0, -0.052)
		var fm: MeshInstance3D = _add(root, box, mat_skin)
		fm.transform = Transform3D(fb, Vector3(foot_c.x, 0.025, foot_c.z))
		var toe := SphereMesh.new()
		toe.radius = 0.038
		toe.height = 0.062
		var tm: MeshInstance3D = _add(root, toe, mat_skin)
		tm.transform = Transform3D(_scale_local(fb, Vector3(1.0, 0.72, 1.0)), Vector3(foot_c.x, 0.028, foot_c.z) + fb * Vector3(0.0, 0.0, -0.080))

	# --- torso --------------------------------------------------------------
	var n_torso: int = rng.randi_range(7, 9)
	for i in range(n_torso):
		var u: float = float(i) / float(n_torso - 1)
		var p: Vector3 = t_base + t_dir * (t_len * u)
		var r: float = _torso_profile(u) * rng.randf_range(0.97, 1.03)
		var sph := SphereMesh.new()
		sph.radius = r
		sph.height = r * 2.0
		var mi: MeshInstance3D = _add(root, sph, mat_skin)
		mi.transform = Transform3D(_scale_local(Basis(), Vector3(1.0, 0.92, 0.70)), p)

	# hip wrapping, below the bodice hem
	var n_hipband: int = rng.randi_range(4, 6)
	for i in range(n_hipband):
		var u: float = lerpf(0.02, 0.24, float(i) / float(maxi(n_hipband - 1, 1)))
		var p: Vector3 = t_base + t_dir * (t_len * u)
		var rr: float = _torso_profile(u) * 1.02
		var tor := TorusMesh.new()
		tor.outer_radius = rr + 0.012
		tor.inner_radius = rr - 0.004
		tor.rings = 22
		tor.ring_segments = 7
		var tb: Basis = _basis_y_to(t_dir) * Basis(Vector3.UP, float(i) * band_step) * Basis(Vector3.RIGHT, band_tilt * 0.6)
		var mi: MeshInstance3D = _add(root, tor, band_mats[i % band_mats.size()])
		mi.transform = Transform3D(_scale_local(tb, Vector3(1.0, 1.0, 0.74)), p)

	# --- arms ---------------------------------------------------------------
	var p_chest: Vector3 = t_base + t_dir * (t_len * 0.94)
	var r_chest: float = _torso_profile(0.94)
	var reach_up: float = rng.randf_range(0.02, 0.10)
	var reach_out: float = rng.randf_range(0.10, 0.17)
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var reaching: bool = absf(sd - reach_side) < 0.5
		var shoulder := p_chest + Vector3(sd * (r_chest * 1.05), 0.014, -0.004)
		var elbow: Vector3
		var wrist: Vector3
		if reaching:
			elbow = shoulder + Vector3(sd * reach_out, -0.085 + reach_up * 0.4, -0.150 - reach_up * 0.3)
			wrist = elbow + Vector3(sd * rng.randf_range(-0.02, 0.05), 0.020 + reach_up, -0.235)
		else:
			elbow = shoulder + Vector3(sd * rng.randf_range(0.055, 0.090), -0.225, rng.randf_range(-0.02, 0.03))
			wrist = elbow + Vector3(-sd * rng.randf_range(0.02, 0.07), -0.125, -0.165)
		var r_up: float = rng.randf_range(0.046, 0.053)
		var r_fore: float = rng.randf_range(0.035, 0.041)

		_limb(root, shoulder, elbow, r_up * 0.84, mat_skin)
		_limb(root, elbow, wrist, r_fore * 0.84, mat_skin)
		_ball(root, shoulder, r_up * 1.22, mat_joint)
		_ball(root, elbow, r_fore * 1.30, mat_joint)
		_ball(root, wrist, r_fore * 0.98, mat_joint)

		var n_up: int = rng.randi_range(5, 8)
		var n_fore: int = rng.randi_range(5, 8)
		_wrap(root, shoulder, elbow, r_up, r_up * 0.92, n_up, 0.0050, band_tilt, rng.randf_range(0.0, TAU), band_step, band_mats)
		_wrap(root, elbow, wrist, r_fore * 1.04, r_fore * 0.94, n_fore, 0.0042, band_tilt, rng.randf_range(0.0, TAU), band_step, band_mats)

		# hand and fingers
		var f_dir: Vector3 = (wrist - elbow).normalized()
		var f_right: Vector3 = f_dir.cross(Vector3.UP)
		if f_right.length() < 0.05:
			f_right = Vector3.RIGHT
		f_right = f_right.normalized()
		var f_up: Vector3 = f_right.cross(f_dir).normalized()
		var hand_c: Vector3 = wrist + f_dir * 0.042
		var hs := SphereMesh.new()
		hs.radius = 0.040
		hs.height = 0.080
		var hm: MeshInstance3D = _add(root, hs, mat_skin)
		hm.transform = Transform3D(_scale_local(Basis(f_right, f_up, -f_dir), Vector3(1.0, 0.62, 0.90)), hand_c)
		var n_fing: int = 4 if reaching else 3
		for k in range(n_fing):
			var spread: float = (float(k) - float(n_fing - 1) * 0.5) * rng.randf_range(0.16, 0.26)
			var curl: float = rng.randf_range(0.10, 0.55) if reaching else rng.randf_range(0.55, 1.05)
			var fd: Vector3 = (f_dir * cos(spread) + f_right * sin(spread) - f_up * curl * 0.55).normalized()
			var ln: float = rng.randf_range(0.052, 0.072)
			_tapered_cyl(root, hand_c + fd * 0.026, hand_c + fd * (0.026 + ln), 0.011, 0.008, mat_skin)
		var thumb_d: Vector3 = (f_dir * 0.55 - f_right * sd * 0.75 - f_up * 0.30).normalized()
		_tapered_cyl(root, hand_c + thumb_d * 0.024, hand_c + thumb_d * 0.070, 0.012, 0.009, mat_skin)

	# --- neck and head ------------------------------------------------------
	var p_top: Vector3 = t_base + t_dir * t_len
	var head_yaw: float = rng.randf_range(-0.36, 0.36)
	var head_roll: float = rng.randf_range(0.10, 0.30) * (-1.0 if rng.randf() < 0.5 else 1.0)
	var head_pitch: float = rng.randf_range(-0.14, 0.07)
	var hb: Basis = Basis(Vector3.UP, head_yaw) * Basis(Vector3.FORWARD, head_roll) * Basis(Vector3.RIGHT, head_pitch)
	var neck_top: Vector3 = p_top + hb * Vector3(0.0, 0.085, 0.0)
	_tapered_cyl(root, p_top - Vector3(0.0, 0.02, 0.0), neck_top, 0.052, 0.043, mat_skin)
	var n_neckband: int = rng.randi_range(1, 3)
	_wrap(root, p_top + Vector3(0.0, 0.005, 0.0), neck_top, 0.060, 0.051, n_neckband, 0.0034, band_tilt * 0.5, rng.randf_range(0.0, TAU), band_step, band_mats)

	var rx: float = 0.098
	var ry: float = 0.125
	var rz: float = 0.098
	var h_org: Vector3 = neck_top + hb * Vector3(0.0, ry * 0.86, -0.006)
	var egg := SphereMesh.new()
	egg.radius = rx
	egg.height = ry * 2.0
	egg.radial_segments = 32
	egg.rings = 20
	var em: MeshInstance3D = _add(root, egg, mat_head)
	em.transform = Transform3D(hb, h_org)
	var chin := SphereMesh.new()
	chin.radius = 0.058
	chin.height = 0.104
	var cm: MeshInstance3D = _add(root, chin, mat_head)
	cm.transform = Transform3D(_scale_local(hb, Vector3(1.0, 0.92, 1.02)), h_org + hb * Vector3(0.0, -0.078, -0.028))
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var ear := SphereMesh.new()
		ear.radius = 0.030
		ear.height = 0.058
		var erm: MeshInstance3D = _add(root, ear, mat_head)
		erm.transform = Transform3D(_scale_local(hb * Basis(Vector3.UP, sd * 0.35), Vector3(0.34, 1.0, 0.86)), h_org + hb * Vector3(sd * rx * 0.93, -0.010, 0.008))

	# painted face — eyes, lash lines, brows, mouth
	var eye_x: float = 0.040
	var eye_y: float = 0.020
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var ez: float = _face_z(rx, ry, rz, eye_x, eye_y) * 0.965
		var eye := SphereMesh.new()
		eye.radius = 0.027
		eye.height = 0.054
		var eyb: Basis = _scale_local(hb * Basis(Vector3.UP, sd * 0.22), Vector3(1.0, 0.50, 0.26))
		var eym: MeshInstance3D = _add(root, eye, mat_eye)
		eym.transform = Transform3D(eyb, h_org + hb * Vector3(sd * eye_x, eye_y, ez))
		var lash := BoxMesh.new()
		lash.size = Vector3(0.050, 0.0055, 0.004)
		var lz: float = _face_z(rx, ry, rz, eye_x, eye_y + 0.013) * 0.985
		var lm: MeshInstance3D = _add(root, lash, mat_line)
		lm.transform = Transform3D(hb * Basis(Vector3.FORWARD, -sd * 0.16), h_org + hb * Vector3(sd * eye_x, eye_y + 0.013, lz))
		var brow := BoxMesh.new()
		brow.size = Vector3(0.046, 0.0045, 0.004)
		var bz: float = _face_z(rx, ry, rz, eye_x, eye_y + 0.046) * 0.985
		var bwm: MeshInstance3D = _add(root, brow, mat_line)
		bwm.transform = Transform3D(hb * Basis(Vector3.FORWARD, -sd * 0.24), h_org + hb * Vector3(sd * eye_x * 1.02, eye_y + 0.046, bz))
	var mouth_w: float = rng.randf_range(0.016, 0.022)
	for k in range(3):
		var kx: float = (float(k) - 1.0) * mouth_w
		var ky: float = -0.052 + (0.004 if k == 1 else 0.0)
		var mz: float = _face_z(rx, ry, rz, absf(kx), ky) * 0.985
		var lip := BoxMesh.new()
		lip.size = Vector3(mouth_w * 1.25, 0.0060, 0.005)
		var mm: MeshInstance3D = _add(root, lip, mat_mouth)
		mm.transform = Transform3D(hb * Basis(Vector3.FORWARD, -float(k - 1) * 0.30), h_org + hb * Vector3(kx, ky, mz))
	var nose := SphereMesh.new()
	nose.radius = 0.019
	nose.height = 0.038
	var nz: float = _face_z(rx, ry, rz, 0.0, -0.018) * 0.92
	var nm: MeshInstance3D = _add(root, nose, mat_head)
	nm.transform = Transform3D(_scale_local(hb, Vector3(0.72, 1.30, 0.90)), h_org + hb * Vector3(0.0, -0.018, nz))

	# --- the stiff bodice ----------------------------------------------------
	var u_hem: float = rng.randf_range(0.24, 0.32)
	var u_top: float = rng.randf_range(1.00, 1.07)
	var bust: float = rng.randf_range(0.026, 0.044)
	var v_dip: float = rng.randf_range(0.045, 0.080)
	var n_ring: int = 15
	var n_rad: int = 24
	var rings_arr: Array = []
	var centres: Array = []
	for k in range(n_ring):
		var t: float = float(k) / float(n_ring - 1)
		var u: float = lerpf(u_hem, u_top, t)
		var c: Vector3 = t_base + t_dir * (t_len * u)
		var base_r: float = _torso_profile(u) + 0.016
		var ring: Array = []
		for j in range(n_rad):
			var th: float = float(j) / float(n_rad) * TAU
			var lobe_a: float = _lobe(th, 0.52, 0.46)
			var lobe_b: float = _lobe(th, -0.52, 0.46)
			var vert: float = exp(-pow((t - 0.68) / 0.17, 2.0))
			var extra: float = bust * vert * maxf(lobe_a, lobe_b)
			var er_x: float = base_r * 1.02 + extra
			var er_z: float = base_r * 0.74 + extra * 1.35
			var dip: float = -v_dip * pow(maxf(0.0, cos(th)), 2.0) * maxf(0.0, 1.0 - t * 3.0)
			ring.append(c + Vector3(sin(th) * er_x, dip, -cos(th) * er_z))
		rings_arr.append(ring)
		centres.append(c)
	var shell: ArrayMesh = _loft(rings_arr, centres)
	var sm: MeshInstance3D = _add(root, shell, mat_gold)
	sm.transform = Transform3D(Basis(), Vector3.ZERO)

	# hem trim
	var hem_c: Vector3 = t_base + t_dir * (t_len * u_hem)
	var hem_r: float = _torso_profile(u_hem) + 0.018
	var hem := TorusMesh.new()
	hem.outer_radius = hem_r + 0.011
	hem.inner_radius = hem_r - 0.003
	hem.rings = 26
	hem.ring_segments = 8
	var hmm: MeshInstance3D = _add(root, hem, mat_trim)
	hmm.transform = Transform3D(_scale_local(_basis_y_to(t_dir), Vector3(1.02, 1.0, 0.76)), hem_c)

	# shoulder caps
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var cap := SphereMesh.new()
		cap.radius = 0.070
		cap.height = 0.120
		var cpm: MeshInstance3D = _add(root, cap, mat_gold)
		cpm.transform = Transform3D(_scale_local(Basis(Vector3.FORWARD, sd * 0.28), Vector3(1.0, 0.86, 0.90)), p_chest + Vector3(sd * (r_chest * 1.02), 0.030, -0.004))

	# --- high standing collar ------------------------------------------------
	var collar_h: float = rng.randf_range(0.085, 0.135)
	var n_crow: int = 6
	var c_rings: Array = []
	var c_centres: Array = []
	var collar_base: Vector3 = p_top + Vector3(0.0, 0.005, 0.0)
	for k in range(n_crow):
		var f: float = float(k) / float(n_crow - 1)
		var rad_x: float = lerpf(0.098, 0.168, f)
		var rad_z: float = lerpf(0.084, 0.146, f)
		var ring: Array = []
		for j in range(n_rad):
			var th: float = float(j) / float(n_rad) * TAU
			var hfac: float = 0.48 + 0.52 * (0.5 - 0.5 * cos(th))
			var yy: float = collar_h * f * hfac
			ring.append(collar_base + Vector3(sin(th) * rad_x, yy, -cos(th) * rad_z) + t_dir * (collar_h * f * 0.25))
		c_rings.append(ring)
		c_centres.append(collar_base + Vector3(0.0, collar_h * f * 0.5, 0.0))
	var collar: ArrayMesh = _loft(c_rings, c_centres)
	var clm: MeshInstance3D = _add(root, collar, mat_gold)
	clm.transform = Transform3D(Basis(), Vector3.ZERO)

	# --- thin wire supports --------------------------------------------------
	var n_wire: int = rng.randi_range(2, 3)
	var anchors: Array = []
	# the wires meet the reaching arm where the elbow and the wrist actually landed
	anchors.append(p_chest + Vector3(reach_side * (r_chest * 1.05 + reach_out), -0.071 + reach_up * 0.4, -0.154 - reach_up * 0.3))
	anchors.append(p_chest + Vector3(reach_side * (r_chest * 1.05 + reach_out), -0.051 + reach_up * 1.4, -0.389 - reach_up * 0.3))
	anchors.append(p_top + Vector3(-reach_side * 0.05, 0.02, 0.06))
	for i in range(n_wire):
		var a: Vector3 = anchors[i % anchors.size()]
		var foot_x: float = a.x * rng.randf_range(0.55, 0.95) + rng.randf_range(-0.06, 0.06)
		var foot_z: float = clampf(a.z * rng.randf_range(0.45, 0.85), -0.36, 0.30)
		if i == 2:
			foot_z = rng.randf_range(0.20, 0.30)
		var b := Vector3(foot_x, 0.006, foot_z)
		_tapered_cyl(root, b, a, 0.0038, 0.0028, mat_wire)
		var clip := SphereMesh.new()
		clip.radius = 0.010
		clip.height = 0.020
		var cim: MeshInstance3D = _add(root, clip, mat_wire)
		cim.transform = Transform3D(Basis(), a)

	# --- settle: fit, centre, stand on the floor -----------------------------
	var box_a: AABB = _union_aabb(root)
	var kx_f: float = 1.20 / maxf(box_a.size.x, 0.001)
	var kz_f: float = 1.20 / maxf(box_a.size.z, 0.001)
	var ky_f: float = 1.68 / maxf(box_a.size.y, 0.001)
	var kfit: float = minf(1.0, minf(kx_f, minf(kz_f, ky_f)))
	if kfit < 1.0:
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var mi2: MeshInstance3D = ch
			var tf: Transform3D = mi2.transform
			mi2.transform = Transform3D(tf.basis.scaled(Vector3(kfit, kfit, kfit)), tf.origin * kfit)
		box_a = _union_aabb(root)
	var centre: Vector3 = box_a.position + box_a.size * 0.5
	var shift := Vector3(-centre.x, -box_a.position.y, -centre.z)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var mi3: MeshInstance3D = ch
		mi3.transform = Transform3D(mi3.transform.basis, mi3.transform.origin + shift)


# ---------------------------------------------------------------------------
# shape helpers

static func _torso_profile(u: float) -> float:
	# hips wide, waist pinched, ribs and shoulder girdle wide again
	var keys: Array = [0.148, 0.132, 0.112, 0.108, 0.122, 0.134, 0.126]
	var f: float = clampf(u, 0.0, 1.0) * 6.0
	var i: int = int(floor(f))
	if i >= 6:
		return keys[6]
	var s: float = f - float(i)
	var va: float = keys[i]
	var vb: float = keys[i + 1]
	return lerpf(va, vb, s * s * (3.0 - 2.0 * s))


static func _lobe(th: float, centre_a: float, width: float) -> float:
	var d: float = th - centre_a
	while d > PI:
		d -= TAU
	while d < -PI:
		d += TAU
	return exp(-pow(d / width, 2.0))


static func _face_z(rx: float, ry: float, rz: float, x: float, y: float) -> float:
	var q: float = 1.0 - (x * x) / (rx * rx) - (y * y) / (ry * ry)
	return -rz * sqrt(maxf(q, 0.05))


static func _scale_local(b: Basis, s: Vector3) -> Basis:
	# Basis.scaled() scales in PARENT space; every squash here (a ring flattened in its
	# own plane, an eye flattened against its own face) has to run on the local axes
	return Basis(b.x * s.x, b.y * s.y, b.z * s.z)


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


static func _porcelain(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	m.clearcoat_enabled = true
	m.clearcoat = 0.85
	m.clearcoat_roughness = 0.10
	return m


static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _ball(root: Node3D, p: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var sph := SphereMesh.new()
	sph.radius = r
	sph.height = r * 2.0
	sph.radial_segments = 20
	sph.rings = 12
	var mi: MeshInstance3D = _add(root, sph, mat)
	mi.transform = Transform3D(Basis(), p)
	return mi


static func _limb(root: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.01)
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = ln + r * 1.7
	cap.radial_segments = 16
	var mi: MeshInstance3D = _add(root, cap, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _tapered_cyl(root: Node3D, a: Vector3, b: Vector3, r0: float, r1: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.005)
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = r0
	cyl.top_radius = r1
	cyl.height = ln
	cyl.radial_segments = 10
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _wrap(root: Node3D, a: Vector3, b: Vector3, r0: float, r1: float, n: int, proud: float, tilt: float, phase0: float, step: float, mats: Array) -> void:
	# bandage: a run of rings along the limb, each turned a little further round the
	# axis and slanted, so the gaps between them read as one continuous spiral
	if n <= 0:
		return
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.01)
	var dir: Vector3 = d / ln
	var base: Basis = _basis_y_to(dir)
	for i in range(n):
		var t: float = (float(i) + 0.5) / float(n)
		var r: float = lerpf(r0, r1, t)
		var tube: float = r * 0.055 + proud
		# bite into the skin so no daylight shows under the band, stand 1.3 tubes proud
		var inner: float = maxf(r * 0.86 - tube * 0.7, 0.003)
		var tor := TorusMesh.new()
		tor.outer_radius = inner + tube * 2.0
		tor.inner_radius = inner
		tor.rings = 18
		tor.ring_segments = 7
		var ph: float = phase0 + float(i) * step
		var bb: Basis = base * Basis(Vector3.UP, ph) * Basis(Vector3.RIGHT, tilt)
		var mi: MeshInstance3D = _add(root, tor, mats[i % mats.size()])
		mi.transform = Transform3D(bb, a + dir * (ln * t))


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


static func _loft(rings: Array, centres: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(rings.size() - 1):
		var r0: Array = rings[k]
		var r1: Array = rings[k + 1]
		var c0: Vector3 = centres[k]
		var c1: Vector3 = centres[k + 1]
		var inside: Vector3 = (c0 + c1) * 0.5
		var m: int = r0.size()
		for j in range(m):
			var j2: int = (j + 1) % m
			_quad_out(st, r0[j], r0[j2], r1[j2], r1[j], inside)
	st.generate_normals()
	return st.commit()


# ---------------------------------------------------------------------------
# textures painted in code

static func _brocade_texture(rng: RandomNumberGenerator) -> ImageTexture:
	var img: Image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	var cell: float = 64.0
	var ground := Vector3(0.44, 0.33, 0.13)
	var thread := Vector3(0.90, 0.76, 0.38)
	var mid := Vector3(0.66, 0.52, 0.22)
	for y in range(TEX_SIZE):
		for x in range(TEX_SIZE):
			var row_i: int = int(floor(float(y) / cell))
			var off: float = cell * 0.5 if (posmod(row_i, 2) == 1) else 0.0
			var nx: float = fposmod(float(x) - off, cell) / cell - 0.5
			var ny: float = fposmod(float(y), cell) / cell - 0.5
			var rr: float = sqrt(nx * nx * 1.55 + ny * ny)
			var v: Vector3 = ground
			if absf(rr - 0.305) < 0.052:
				v = thread
			elif rr < 0.095:
				v = thread
			elif (absf(nx) + absf(ny)) < 0.155:
				v = mid.lerp(thread, 0.55)
			elif absf(rr - 0.44) < 0.030:
				v = mid
			var w_up: int = 1 if posmod(x + y, 9) < 2 else 0
			var w_dn: int = 1 if posmod(x - y, 11) < 2 else 0
			var weave: float = 1.0 + 0.055 * float(w_up) - 0.035 * float(w_dn)
			var grain: float = rng.randf_range(0.975, 1.025)
			img.set_pixel(x, y, Color(clampf(v.x * weave * grain, 0.0, 1.0), clampf(v.y * weave * grain, 0.0, 1.0), clampf(v.z * weave * grain, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


static func _maze_texture(rng: RandomNumberGenerator) -> ImageTexture:
	# binary maze: every cell keeps one of its two walls, so the print reads as a
	# rectilinear labyrinth with dead ends, printed terracotta on cream
	var img: Image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	var ground := Color(0.94, 0.86, 0.83)
	for y in range(TEX_SIZE):
		for x in range(TEX_SIZE):
			img.set_pixel(x, y, ground)
	var cells: int = rng.randi_range(7, 10)
	var step: int = int(floor(float(TEX_SIZE) / float(cells)))
	var thick: int = maxi(2, int(floor(float(step) * 0.14)))
	var ink := Color(0.71, 0.24, 0.19)
	for cy in range(cells):
		for cx in range(cells):
			var x0: int = cx * step
			var y0: int = cy * step
			if rng.randf() < 0.5:
				_v_line(img, x0 + step, y0, y0 + step, thick, ink)
			else:
				_h_line(img, x0, x0 + step, y0 + step, thick, ink)
			if rng.randf() < 0.22:
				_h_line(img, x0, x0 + int(float(step) * 0.6), y0, thick, ink)
	return ImageTexture.create_from_image(img)


static func _h_line(img: Image, x0: int, x1: int, y: int, thick: int, c: Color) -> void:
	for x in range(x0, x1 + thick):
		for k in range(thick):
			img.set_pixel(posmod(x, TEX_SIZE), posmod(y + k, TEX_SIZE), c)


static func _v_line(img: Image, x: int, y0: int, y1: int, thick: int, c: Color) -> void:
	for y in range(y0, y1 + thick):
		for k in range(thick):
			img.set_pixel(posmod(x + k, TEX_SIZE), posmod(y, TEX_SIZE), c)


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
