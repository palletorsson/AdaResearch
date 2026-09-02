extends RefCounted

## dream_bodies / batik_beast — one soft-cloth animal-headed figure, hand on hip.
##
## Reference: scratchpad/refs/batik_hybrid.png (2048x536 panorama) — a crowd of
## life-size soft sculptures: human bodies sewn into tight fabric bodysuits with
## long-muzzled horse / deer heads, big leaf ears and painted bead eyes. The
## cloth is printed with batik swirls, whorls, stripes and paisley in violet,
## sage green, slate grey, sand and pink; the muzzles are left pale cream; every
## body is stuffed-toy soft with its seams showing, and several figures stand
## with a hand planted on the hip.
##
## Reproduced, and how:
##   1. Stuffed-toy softness — every mass is a squashed SphereMesh, and limbs are
##      short chains of overlapping balls (thigh, shin, upper arm, forearm,
##      fingers) so nothing has a hard edge. The torso is 14 balls on a leaning
##      spine with a keyed width / depth profile: soft belly, rounded shoulders.
##   2. Hand on hip — the seed picks a side; that elbow flares out and back while
##      the wrist lands just outside the hip, cutting the triangular void that
##      reads from every angle. The other arm hangs with a soft finger curl.
##   3. Contrapposto — weight goes on the opposite leg, the spine drifts over it,
##      the free knee steps forward and turns out, and the shoulders take a small
##      counter-twist against the hips.
##   4. The animal head — a squashed cranium plus a swept ArrayMesh muzzle (nine
##      rings, elliptical section, taller than wide at the base) curving down to
##      a pale snout ball with two nostrils.
##   5. Leaf ears — ArrayMesh pillow blades: a mid-surface widest just before
##      mid-length, cupped toward the front, with a thickness that closes to zero
##      at the rim so the edge reads as sewn, and a smaller inner blade inside.
##   6. Painted eyes — a cream patch flattened onto the side of the skull, a
##      near-black glossy bead, and a small white highlight.
##   7. Batik print — a 192x192 ImageTexture painted in code over a woven ground.
##      The seed picks curling swirls, vertical stripes or long vines, all under
##      wax-crackle hairlines; carried triplanar so the print runs unbroken
##      across the ball chains, and at a finer scale on the head cloth.
##   8. Stitched seams — running stitches in thread colour down the centre front,
##      over each shoulder and arm, down each outer leg, over the crown, and
##      along the top of the muzzle.
##
## Given up: the crowd (this is one figure), the neighbouring figures' hands
## resting on each other, the real fabric's stretch wrinkles gathering at the
## joints (stuffing rings stand in for them), and the printed-on inner-ear and
## cheek markings that some of the reference heads carry.

const TEX: int = 192

# ground, ink, accent, muzzle, thread, ear inner
const SCHEMES: Array = [
	["#A24CAE", "#DCA6E4", "#F2D6EE", "#F1E2E6", "#5A2663", "#E2A8CE"],
	["#7FB86C", "#EDF4E4", "#CFE4BC", "#F0F2E4", "#3B6634", "#DCE9C8"],
	["#6E7683", "#E4E8EC", "#B9C2CB", "#EDEEF0", "#2F3640", "#C9CFD8"],
	["#C4A067", "#F4E6C8", "#E0CBA0", "#F5EBD8", "#674E24", "#EAD8B0"],
	["#D79FB2", "#F7E5EC", "#EFCBD8", "#F8EFEF", "#74414F", "#F2D2DC"],
	["#8E7FC4", "#E6DEF4", "#C6BCE6", "#EFEAF2", "#3E3168", "#D8CCEC"],
]


static func describe() -> String:
	return "A soft cloth figure in a batik-printed bodysuit, standing with one hand on its hip under a long-muzzled animal head with big leaf ears and painted bead eyes."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var si: int = rng.randi_range(0, SCHEMES.size() - 1)
	var sch: Array = SCHEMES[si]
	var col_ground: Color = _hex(sch, 0)
	var col_ink: Color = _hex(sch, 1)
	var col_accent: Color = _hex(sch, 2)
	var col_muzzle: Color = _hex(sch, 3)
	var col_thread: Color = _hex(sch, 4)
	var col_ear: Color = _hex(sch, 5)

	var kind: int = rng.randi_range(0, 2)
	var print_tex: ImageTexture = _batik_texture(rng, kind, col_ground, col_ink, col_accent)
	var pale_tex: ImageTexture = _weave_texture(col_muzzle)
	var print_k: float = rng.randf_range(2.0, 2.9)

	var mat_cloth: StandardMaterial3D = _cloth(print_tex, print_k)
	var mat_head: StandardMaterial3D = _cloth(print_tex, print_k * 1.55)
	var mat_pale: StandardMaterial3D = _cloth(pale_tex, 7.0)
	var mat_ear: StandardMaterial3D = _flat(col_ear, 0.95)
	var mat_thread: StandardMaterial3D = _flat(col_thread, 0.88)
	var mat_dark: StandardMaterial3D = _flat(col_thread.darkened(0.55), 0.6)
	var mat_bead := StandardMaterial3D.new()
	mat_bead.albedo_color = Color("#161018")
	mat_bead.roughness = 0.18
	mat_bead.metallic = 0.0
	mat_bead.clearcoat_enabled = true
	mat_bead.clearcoat = 0.8
	var mat_spark: StandardMaterial3D = _flat(Color("#FBFBF6"), 0.25)
	mat_spark.emission_enabled = true
	mat_spark.emission = Color("#FFFFFF")
	mat_spark.emission_energy_multiplier = 0.18

	# --- the individual -------------------------------------------------------
	var body_k: float = rng.randf_range(0.95, 1.06)
	var belly: float = rng.randf_range(0.95, 1.15)
	var y_hip: float = rng.randf_range(0.845, 0.878)
	var y_sh: float = y_hip + rng.randf_range(0.352, 0.386)
	var hip_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var stand_side: float = -hip_side
	var lean: float = rng.randf_range(0.048, 0.098) * stand_side
	var twist: float = deg_to_rad(rng.randf_range(-8.0, 8.0)) * hip_side
	var head_yaw: float = deg_to_rad(rng.randf_range(-27.0, 27.0))
	var head_pitch: float = deg_to_rad(rng.randf_range(-6.0, 10.0))
	var ear_out: float = deg_to_rad(rng.randf_range(21.0, 39.0))
	var ear_back: float = deg_to_rad(rng.randf_range(6.0, 27.0))
	var ear_len: float = rng.randf_range(0.130, 0.152)
	var muzzle_len: float = rng.randf_range(0.222, 0.258)

	# --- torso ----------------------------------------------------------------
	var n_t: int = 14
	var spine: Array = []
	var girth: Array = []
	for i in range(n_t):
		var t: float = float(i) / float(n_t - 1)
		var y: float = lerpf(y_hip, y_sh, t)
		var x: float = lean * (0.85 * t * t - 0.12) + lean * 0.22 * sin(t * PI)
		var z: float = 0.013 * sin(t * PI) - 0.012 * t
		spine.append(Vector3(x, y, z))
		var hx: float = _key(t, [0.150, 0.153, 0.150, 0.159, 0.180, 0.186]) * body_k
		var hz: float = _key(t, [0.120, 0.133 * belly, 0.130 * belly, 0.117, 0.110, 0.104]) * body_k
		girth.append(Vector2(hx, hz))

	for i in range(n_t):
		var t: float = float(i) / float(n_t - 1)
		var q: Vector3 = spine[i]
		var g: Vector2 = girth[i]
		var tang: Vector3 = _tangent(spine, i)
		var bs: Basis = _basis_y_to(tang) * Basis(Vector3.UP, twist * t)
		_ball(root, q, Vector3(g.x, 0.058 * body_k, g.y), bs, mat_cloth)

	var p_hip: Vector3 = spine[0]
	var p_top: Vector3 = spine[n_t - 1]
	var bs_top: Basis = Basis(Vector3.UP, twist)

	# hip cheeks and shoulder caps, the two soft corners of the silhouette
	for k in range(2):
		var sd: float = -1.0 if k == 0 else 1.0
		_ball(root, p_hip + Vector3(sd * 0.078 * body_k, -0.030, 0.006), Vector3(0.098, 0.086, 0.115) * body_k, Basis(), mat_cloth)
		_ball(root, p_top + bs_top * Vector3(sd * 0.128 * body_k, -0.006, 0.0), Vector3(0.086, 0.074, 0.098) * body_k, bs_top, mat_cloth)

	# --- legs -----------------------------------------------------------------
	var leg_pts: Array = []
	for k in range(2):
		var sd: float = -1.0 if k == 0 else 1.0
		var free: float = 0.0 if sd == stand_side else 1.0
		var out_k: float = free * rng.randf_range(0.020, 0.048)
		var fwd_k: float = free * rng.randf_range(0.030, 0.078)
		var bend_k: float = free * rng.randf_range(0.014, 0.030)
		var hip_p: Vector3 = p_hip + Vector3(sd * 0.104 * body_k, -0.046, 0.004)
		var ankle_p := Vector3(hip_p.x + sd * (0.006 + out_k), 0.104, -0.006 - fwd_k)
		var mid_p: Vector3 = (hip_p + ankle_p) * 0.5
		var knee_p: Vector3 = mid_p + Vector3(sd * 0.008, 0.014, -0.026 - bend_k)
		_soft_chain(root, hip_p, knee_p, 0.090 * body_k, 0.070 * body_k, 5, 1.02, mat_cloth)
		_soft_chain(root, knee_p, ankle_p, 0.070 * body_k, 0.050 * body_k, 5, 1.02, mat_cloth)
		_ball(root, knee_p, Vector3(0.074, 0.070, 0.076) * body_k, Basis(), mat_cloth)
		# foot: heel, arch, toe, sole flat on y = 0
		var toe_p := Vector3(ankle_p.x + sd * 0.004, 0.046, ankle_p.z - 0.110)
		var heel_p := Vector3(ankle_p.x, 0.050, ankle_p.z + 0.030)
		_ball(root, heel_p, Vector3(0.050, 0.050, 0.056), Basis(), mat_cloth)
		_ball(root, (heel_p + toe_p) * 0.5, Vector3(0.052, 0.047, 0.066), Basis(), mat_cloth)
		_ball(root, toe_p, Vector3(0.049, 0.046, 0.058), Basis(), mat_cloth)
		# stuffing rings at knee and ankle
		_ring(root, knee_p + Vector3(0.0, -0.006, 0.0), 0.062 * body_k, 0.010, Basis(Vector3.RIGHT, 0.12), mat_cloth)
		_ring(root, ankle_p, 0.046 * body_k, 0.009, Basis(Vector3.RIGHT, 0.10), mat_cloth)
		leg_pts.append([hip_p, knee_p, ankle_p, sd])

	# --- arms -----------------------------------------------------------------
	for k in range(2):
		var sd: float = -1.0 if k == 0 else 1.0
		var on_hip: bool = sd == hip_side
		var sh_p: Vector3 = p_top + bs_top * Vector3(sd * 0.166 * body_k, -0.014, 0.004)
		var elbow_p := Vector3.ZERO
		var wrist_p := Vector3.ZERO
		var curl_dir := Vector3.ZERO
		var hand_dir := Vector3.ZERO
		if on_hip:
			elbow_p = sh_p + Vector3(sd * rng.randf_range(0.128, 0.152), -0.214, rng.randf_range(0.050, 0.078))
			wrist_p = Vector3(p_hip.x + sd * 0.150 * body_k, y_hip + rng.randf_range(0.052, 0.086), -0.028)
			hand_dir = (Vector3(-sd * 0.30, -0.72, -0.62)).normalized()
			curl_dir = (Vector3(-sd * 0.86, -0.18, 0.48)).normalized()
		else:
			elbow_p = sh_p + Vector3(sd * rng.randf_range(0.032, 0.056), -0.228, rng.randf_range(-0.022, 0.004))
			wrist_p = elbow_p + Vector3(sd * rng.randf_range(0.038, 0.066), -0.218, rng.randf_range(0.018, 0.044))
			hand_dir = (Vector3(sd * 0.10, -0.96, 0.24)).normalized()
			curl_dir = (Vector3(-sd * 0.42, -0.10, -0.90)).normalized()
		_ball(root, sh_p + Vector3(0.0, 0.012, 0.0), Vector3(0.074, 0.072, 0.080) * body_k, Basis(), mat_cloth)
		_soft_chain(root, sh_p, elbow_p, 0.064 * body_k, 0.051 * body_k, 4, 1.0, mat_cloth)
		_ball(root, elbow_p, Vector3(0.055, 0.053, 0.056) * body_k, Basis(), mat_cloth)
		_soft_chain(root, elbow_p, wrist_p, 0.051 * body_k, 0.040 * body_k, 4, 1.0, mat_cloth)
		_ring(root, wrist_p, 0.040 * body_k, 0.008, _basis_y_to(wrist_p - elbow_p), mat_cloth)
		_hand(root, wrist_p, hand_dir, Vector3(sd, 0.0, 0.0), curl_dir, 0.052 * body_k, mat_cloth)
		# the shoulder-to-elbow seam, riding the outer face of the sleeve
		var l_dir: Vector3 = (elbow_p - sh_p).normalized()
		var away := Vector3(sd * 0.86, 0.34, 0.10)
		away = (away - l_dir * away.dot(l_dir)).normalized()
		var arm_line: Array = []
		for i in range(6):
			var t: float = float(i) / 5.0
			var q: Vector3 = _lerp3(sh_p + Vector3(0.0, 0.030, 0.0), elbow_p, t)
			var rr: float = lerpf(0.074, 0.052, t) * body_k
			arm_line.append(q + away * rr)
		_seam(root, arm_line, 0.0056, 0.60, mat_thread)

	# --- neck and head --------------------------------------------------------
	var neck_dir := Vector3(sin(head_yaw) * 0.16, 1.0, -0.06).normalized()
	var neck_base: Vector3 = p_top + Vector3(0.0, 0.030, 0.004)
	for i in range(3):
		var t: float = float(i) / 2.0
		var c: Vector3 = neck_base + neck_dir * (t * 0.090)
		var r: float = lerpf(0.066, 0.056, t) * body_k
		_ball(root, c, Vector3(r, 0.040, r * 0.94), _basis_y_to(neck_dir), mat_cloth)
	_ring(root, neck_base + neck_dir * 0.052, 0.058 * body_k, 0.012, _basis_y_to(neck_dir), mat_head)

	var hb: Basis = Basis(Vector3.UP, head_yaw) * Basis(Vector3.RIGHT, head_pitch)
	var h_org: Vector3 = neck_base + neck_dir * 0.108 + Vector3(0.0, 0.048, 0.0)

	_ball(root, h_org + hb * Vector3(0.0, 0.008, 0.014), Vector3(0.092, 0.096, 0.104) * body_k, hb, mat_head)
	_ball(root, h_org + hb * Vector3(0.0, -0.030, -0.052), Vector3(0.080, 0.072, 0.086) * body_k, hb, mat_head)
	_ball(root, h_org + hb * Vector3(0.0, -0.020, -0.086), Vector3(0.070, 0.062, 0.064) * body_k, hb, mat_pale)

	# muzzle: a swept elliptical tube curving down and forward
	var mz_n: int = 9
	var mz_pts: Array = []
	var mz_rad: Array = []
	for i in range(mz_n):
		var t: float = float(i) / float(mz_n - 1)
		var mz: float = lerpf(-0.052, -0.052 - muzzle_len, t)
		var my: float = lerpf(-0.018, -0.086, t) - 0.020 * sin(PI * t)
		mz_pts.append(Vector3(0.0, my, mz))
		var rw: float = lerpf(0.068, 0.040, pow(t, 0.85)) * body_k
		var rh: float = lerpf(0.077, 0.043, pow(t, 0.78)) * body_k
		mz_rad.append(Vector2(rw, rh))
	var muzzle_mesh: ArrayMesh = _swept_tube(mz_pts, mz_rad, 14)
	var mz_mi: MeshInstance3D = _add(root, muzzle_mesh, mat_pale)
	mz_mi.transform = Transform3D(hb, h_org)

	var tip_local: Vector3 = mz_pts[mz_n - 1]
	var snout_p: Vector3 = h_org + hb * (tip_local + Vector3(0.0, -0.004, -0.014))
	_ball(root, snout_p, Vector3(0.046, 0.040, 0.038) * body_k, hb, mat_pale)
	for k in range(2):
		var sd: float = -1.0 if k == 0 else 1.0
		_ball(root, snout_p + hb * Vector3(sd * 0.019, 0.000, -0.034), Vector3(0.011, 0.014, 0.009), hb, mat_dark)
	# mouth line, a dark stitched crease sunk into the underside of the muzzle
	var mouth_pts: Array = []
	for i in range(6):
		var t: float = float(i) / 5.0
		var u: float = lerpf(0.40, 0.99, t)
		var mp: Vector3 = _curve_at(mz_pts, u)
		var rr: Vector2 = _rad_at(mz_rad, u)
		mouth_pts.append(h_org + hb * (mp + Vector3(0.0, -rr.y * 0.94, 0.0)))
	_seam(root, mouth_pts, 0.0055, 0.72, mat_dark)

	# eyes, set proud of the skull so the bead reads from every angle
	for k in range(2):
		var sd: float = -1.0 if k == 0 else 1.0
		var eye_local := Vector3(sd * 0.078, 0.014, -0.050)
		var nrm: Vector3 = (hb * Vector3(sd * 0.88, 0.20, -0.44)).normalized()
		var eye_p: Vector3 = h_org + hb * eye_local + nrm * 0.008
		_ball(root, eye_p, Vector3(0.038, 0.012, 0.032), _basis_y_to(nrm), mat_pale)
		var bead_p: Vector3 = eye_p + nrm * 0.016
		_ball(root, bead_p, Vector3(0.021, 0.020, 0.019), _basis_y_to(nrm), mat_bead)
		_ball(root, bead_p + nrm * 0.014 + hb * Vector3(0.0, 0.008, -0.007), Vector3(0.006, 0.006, 0.006), Basis(), mat_spark)

	# ears: leaf blades, cupped forward
	for k in range(2):
		var sd: float = -1.0 if k == 0 else 1.0
		var base_p: Vector3 = h_org + hb * Vector3(sd * 0.060, 0.080, 0.030)
		var ey_e: Vector3 = (hb * Vector3(sd * sin(ear_out), cos(ear_out) * cos(ear_back), sin(ear_back))).normalized()
		var want: Vector3 = hb * Vector3(sd * 0.32, 0.0, -0.95)
		var ez_e: Vector3 = (want - ey_e * want.dot(ey_e)).normalized()
		var ex_e: Vector3 = ey_e.cross(ez_e).normalized()
		var eb := Basis(ex_e, ey_e, ez_e)
		_ball(root, base_p, Vector3(0.038, 0.034, 0.034), eb, mat_head)
		var blade: ArrayMesh = _leaf_blade(ear_len, 0.078 * body_k, 0.011, 0.030, -0.016, 9, 6)
		var bl_mi: MeshInstance3D = _add(root, blade, mat_head)
		bl_mi.transform = Transform3D(eb, base_p)
		var inner: ArrayMesh = _leaf_blade(ear_len * 0.70, 0.050 * body_k, 0.006, 0.024, -0.010, 7, 5)
		var in_mi: MeshInstance3D = _add(root, inner, mat_ear)
		in_mi.transform = Transform3D(eb, base_p + ez_e * 0.011 + ey_e * (ear_len * 0.10))

	# --- stitched seams -------------------------------------------------------
	var front_pts: Array = []
	for i in range(10):
		var t: float = float(i) / 9.0
		var q: Vector3 = _curve_at(spine, t)
		var g: Vector2 = Vector2(_key(t, [0.150, 0.153, 0.150, 0.159, 0.180, 0.186]), _key(t, [0.120, 0.133 * belly, 0.130 * belly, 0.117, 0.110, 0.104])) * body_k
		var fr: Vector3 = Basis(Vector3.UP, twist * t) * Vector3(0.0, 0.0, -1.0)
		front_pts.append(q + fr * (g.y + 0.004))
	_seam(root, front_pts, 0.0058, 0.66, mat_thread)

	for k in range(2):
		var sd: float = -1.0 if k == 0 else 1.0
		var lp: Array = leg_pts[k]
		var l_hip: Vector3 = lp[0]
		var l_knee: Vector3 = lp[1]
		var l_ankle: Vector3 = lp[2]
		var leg_line: Array = []
		for i in range(7):
			var t: float = float(i) / 6.0
			var q: Vector3 = _lerp3(l_hip, l_knee, clampf(t * 2.0, 0.0, 1.0)) if t < 0.5 else _lerp3(l_knee, l_ankle, clampf((t - 0.5) * 2.0, 0.0, 1.0))
			var r: float = lerpf(0.092, 0.052, t) * body_k
			leg_line.append(q + Vector3(sd * (r + 0.004), 0.0, 0.0))
		_seam(root, leg_line, 0.0058, 0.62, mat_thread)

	var crown_pts: Array = []
	for i in range(7):
		var t: float = float(i) / 6.0
		var ang: float = lerpf(0.98, -1.02, t)
		var cy: float = 0.008 + 0.106 * cos(ang) * body_k
		var cz: float = 0.014 + 0.115 * sin(ang) * body_k
		crown_pts.append(h_org + hb * Vector3(0.0, cy, cz))
	_seam(root, crown_pts, 0.0056, 0.62, mat_thread)

	var mz_seam: Array = []
	for i in range(6):
		var t: float = float(i) / 5.0
		var u: float = lerpf(0.10, 0.98, t)
		var mp: Vector3 = _curve_at(mz_pts, u)
		var rr: Vector2 = _rad_at(mz_rad, u)
		mz_seam.append(h_org + hb * (mp + Vector3(0.0, rr.y * 0.96, 0.0)))
	_seam(root, mz_seam, 0.0050, 0.60, mat_thread)

	# --- fit, centre, settle --------------------------------------------------
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
	var shift := Vector3(-mid.x, 0.0, -mid.z)
	if box.position.y < 0.0:
		shift.y = -box.position.y
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + shift)


# ---------------------------------------------------------------------------
# shape helpers

static func _hex(sch: Array, i: int) -> Color:
	var code: String = sch[i]
	return Color(code)


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
	sph.radial_segments = 20
	sph.rings = 11
	var mi: MeshInstance3D = _add(root, sph, mat)
	mi.transform = Transform3D(bs * Basis.from_scale(half), ctr)
	return mi


static func _ring(root: Node3D, ctr: Vector3, rad: float, thick: float, bs: Basis, mat: StandardMaterial3D) -> MeshInstance3D:
	var tor := TorusMesh.new()
	tor.inner_radius = maxf(rad - thick, 0.004)
	tor.outer_radius = rad + thick
	tor.rings = 16
	tor.ring_segments = 8
	var mi: MeshInstance3D = _add(root, tor, mat)
	mi.transform = Transform3D(bs, ctr)
	return mi


static func _soft_chain(root: Node3D, a: Vector3, b: Vector3, r0: float, r1: float, n: int, along: float, mat: StandardMaterial3D) -> void:
	var d: Vector3 = b - a
	var bs: Basis = _basis_y_to(d)
	for i in range(n):
		var t: float = float(i) / float(maxi(n - 1, 1))
		var r: float = lerpf(r0, r1, t)
		var c: Vector3 = a + d * t
		_ball(root, c, Vector3(r, r * along, r * 0.96), bs, mat)


static func _hand(root: Node3D, wrist: Vector3, dir: Vector3, out_hint: Vector3, curl_dir: Vector3, r: float, mat: StandardMaterial3D) -> void:
	var bz: Vector3 = dir.normalized()
	var bx: Vector3 = out_hint - bz * out_hint.dot(bz)
	if bx.length() < 0.001:
		bx = Vector3(1.0, 0.0, 0.0) - bz * bz.x
	bx = bx.normalized()
	var by: Vector3 = bz.cross(bx).normalized()
	var hb := Basis(bx, by, bz)
	var palm: Vector3 = wrist + bz * (r * 1.05)
	_ball(root, palm, Vector3(r * 1.00, r * 0.52, r * 0.88), hb, mat)
	var cd: Vector3 = curl_dir.normalized()
	for i in range(4):
		var fi: float = float(i)
		var spread: float = (fi - 1.5) * 0.26
		var fd: Vector3 = (bz * cos(spread) + bx * sin(spread) + cd * 0.55).normalized()
		var fa: Vector3 = palm + bz * (r * 0.72) + bx * ((fi - 1.5) * r * 0.50)
		var fb: Vector3 = fa + fd * (r * 1.30 - absf(fi - 1.5) * r * 0.16)
		_soft_chain(root, fa, fb, r * 0.30, r * 0.24, 2, 1.0, mat)
	var td: Vector3 = (bz * 0.42 - bx * 0.82 + cd * 0.34).normalized()
	var ta: Vector3 = palm - bx * (r * 0.82) + bz * (r * 0.06)
	_soft_chain(root, ta, ta + td * (r * 1.00), r * 0.34, r * 0.26, 2, 1.0, mat)


static func _dash(root: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> void:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.005)
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = ln + r * 2.0
	cap.radial_segments = 6
	cap.rings = 2
	var mi: MeshInstance3D = _add(root, cap, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)


static func _seam(root: Node3D, pts: Array, r: float, frac: float, mat: StandardMaterial3D) -> void:
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var m: Vector3 = (a + b) * 0.5
		var h: Vector3 = (b - a) * (frac * 0.5)
		_dash(root, m - h, m + h, r, mat)


static func _lerp3(a: Vector3, b: Vector3, t: float) -> Vector3:
	var q: Vector3 = a.lerp(b, clampf(t, 0.0, 1.0))
	return q


static func _key(t: float, keys: Array) -> float:
	var n: int = keys.size()
	var f: float = clampf(t, 0.0, 1.0) * float(n - 1)
	var i: int = int(floor(f))
	if i >= n - 1:
		var last: float = keys[n - 1]
		return last
	var u: float = f - float(i)
	var s: float = u * u * (3.0 - 2.0 * u)
	var va: float = keys[i]
	var vb: float = keys[i + 1]
	return lerpf(va, vb, s)


static func _curve_at(pts: Array, t: float) -> Vector3:
	var n: int = pts.size()
	var f: float = clampf(t, 0.0, 1.0) * float(n - 1)
	var i: int = int(floor(f))
	if i >= n - 1:
		var tail: Vector3 = pts[n - 1]
		return tail
	var u: float = f - float(i)
	var a: Vector3 = pts[i]
	var b: Vector3 = pts[i + 1]
	return a.lerp(b, u)


static func _rad_at(radii: Array, t: float) -> Vector2:
	var n: int = radii.size()
	var f: float = clampf(t, 0.0, 1.0) * float(n - 1)
	var i: int = int(floor(f))
	if i >= n - 1:
		var tail: Vector2 = radii[n - 1]
		return tail
	var u: float = f - float(i)
	var a: Vector2 = radii[i]
	var b: Vector2 = radii[i + 1]
	return a.lerp(b, u)


static func _tangent(pts: Array, i: int) -> Vector3:
	var n: int = pts.size()
	var a: Vector3 = pts[maxi(i - 1, 0)]
	var b: Vector3 = pts[mini(i + 1, n - 1)]
	var d: Vector3 = b - a
	if d.length() < 0.00001:
		return Vector3.UP
	return d.normalized()


static func _basis_y_to(dir: Vector3) -> Basis:
	var d: Vector3 = dir.normalized()
	if d.length() < 0.5:
		return Basis()
	var dot_up: float = d.dot(Vector3.UP)
	if dot_up > 0.9999:
		return Basis()
	if dot_up < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	var ax: Vector3 = Vector3.UP.cross(d).normalized()
	var ang: float = acos(clampf(dot_up, -1.0, 1.0))
	return Basis(ax, ang)


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
# ArrayMesh pieces

static func _quad_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, inside: Vector3) -> void:
	var nf: Vector3 = (c - a).cross(b - a)
	var ctr: Vector3 = (a + b + c + d) * 0.25
	if nf.dot(ctr - inside) >= 0.0:
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
	var nf: Vector3 = (c - a).cross(b - a)
	var ctr: Vector3 = (a + b + c) / 3.0
	if nf.dot(ctr - inside) >= 0.0:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)
	else:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)


static func _swept_tube(pts: Array, radii: Array, sides: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = pts.size()
	var rings: Array = []
	for i in range(n):
		var c: Vector3 = pts[i]
		var tang: Vector3 = _tangent(pts, i)
		var up_ref := Vector3.UP
		if absf(tang.dot(up_ref)) > 0.94:
			up_ref = Vector3(0.0, 0.0, -1.0)
		var ex: Vector3 = tang.cross(up_ref).normalized()
		var ey: Vector3 = ex.cross(tang).normalized()
		var rr: Vector2 = radii[i]
		var ring: Array = []
		for j in range(sides):
			var ang: float = TAU * float(j) / float(sides)
			ring.append(c + ex * (cos(ang) * rr.x) + ey * (sin(ang) * rr.y))
		rings.append(ring)
	for i in range(n - 1):
		var r0: Array = rings[i]
		var r1: Array = rings[i + 1]
		var pa: Vector3 = pts[i]
		var pb: Vector3 = pts[i + 1]
		var inside: Vector3 = (pa + pb) * 0.5
		for j in range(sides):
			var j2: int = (j + 1) % sides
			var a0: Vector3 = r0[j]
			var a1: Vector3 = r0[j2]
			var b1: Vector3 = r1[j2]
			var b0: Vector3 = r1[j]
			_quad_out(st, a0, a1, b1, b0, inside)
	var last: Array = rings[n - 1]
	var tip_c: Vector3 = pts[n - 1]
	var back_c: Vector3 = pts[n - 2]
	for j in range(sides):
		var j2: int = (j + 1) % sides
		var e0: Vector3 = last[j]
		var e1: Vector3 = last[j2]
		_tri_out(st, tip_c, e0, e1, back_c)
	st.generate_normals()
	return st.commit()


static func _leaf_blade(ln: float, wid: float, thick: float, cup: float, bend: float, rows: int, cols: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grid_f: Array = []
	var grid_b: Array = []
	var grid_m: Array = []
	for i in range(rows + 1):
		var u: float = lerpf(0.02, 0.995, float(i) / float(rows))
		var w: float = wid * pow(sin(PI * u), 0.55) * (1.0 - 0.10 * u)
		var row_f: Array = []
		var row_b: Array = []
		var row_m: Array = []
		for j in range(cols + 1):
			var v: float = -1.0 + 2.0 * float(j) / float(cols)
			var px: float = w * v
			var py: float = ln * u
			var pz: float = cup * (v * v) * (0.35 + 0.65 * u) + bend * u * u
			var mid := Vector3(px, py, pz)
			var th: float = thick * sqrt(maxf(0.0, 1.0 - v * v)) * pow(sin(PI * u), 0.45)
			row_m.append(mid)
			row_f.append(mid + Vector3(0.0, 0.0, th))
			row_b.append(mid - Vector3(0.0, 0.0, th))
		grid_f.append(row_f)
		grid_b.append(row_b)
		grid_m.append(row_m)
	for i in range(rows):
		var f0: Array = grid_f[i]
		var f1: Array = grid_f[i + 1]
		var b0: Array = grid_b[i]
		var b1: Array = grid_b[i + 1]
		var m0: Array = grid_m[i]
		var m1: Array = grid_m[i + 1]
		for j in range(cols):
			var qa: Vector3 = m0[j]
			var qb: Vector3 = m1[j + 1]
			var inside: Vector3 = (qa + qb) * 0.5
			var fa: Vector3 = f0[j]
			var fb: Vector3 = f0[j + 1]
			var fc: Vector3 = f1[j + 1]
			var fd: Vector3 = f1[j]
			_quad_out(st, fa, fb, fc, fd, inside)
			var ba: Vector3 = b0[j]
			var bb: Vector3 = b0[j + 1]
			var bc: Vector3 = b1[j + 1]
			var bd: Vector3 = b1[j]
			_quad_out(st, ba, bb, bc, bd, inside)
	st.generate_normals()
	return st.commit()


# ---------------------------------------------------------------------------
# materials and painted cloth

static func _cloth(tex: ImageTexture, k: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 1.0, 1.0)
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(k, k, k)
	m.uv1_triplanar_sharpness = 1.2
	m.roughness = 0.95
	m.metallic = 0.0
	return m


static func _flat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m


static func _weave_texture(base: Color) -> ImageTexture:
	var img: Image = Image.create(64, 64, false, Image.FORMAT_RGB8)
	for y in range(64):
		for x in range(64):
			var wv: float = 0.960 + 0.040 * (sin(float(x) * PI * 0.5) * 0.5 + sin(float(y) * PI * 0.5) * 0.5)
			var slub: float = 1.0 + 0.014 * sin(float(x) * 0.37 + float(y) * 0.11)
			var k: float = wv * slub
			img.set_pixel(x, y, Color(clampf(base.r * k, 0.0, 1.0), clampf(base.g * k, 0.0, 1.0), clampf(base.b * k, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


static func _batik_texture(rng: RandomNumberGenerator, kind: int, ground: Color, ink: Color, accent: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	for y in range(TEX):
		for x in range(TEX):
			var wv: float = 0.966 + 0.034 * (sin(float(x) * PI * 0.5) * 0.5 + sin(float(y) * PI * 0.5) * 0.5)
			img.set_pixel(x, y, Color(clampf(ground.r * wv, 0.0, 1.0), clampf(ground.g * wv, 0.0, 1.0), clampf(ground.b * wv, 0.0, 1.0)))
	if kind == 0:
		_paint_swirls(img, rng, ink, accent)
	elif kind == 1:
		_paint_stripes(img, rng, ink, accent)
	else:
		_paint_vines(img, rng, ink, accent)
	_paint_crackle(img, rng, ground.darkened(0.34))
	return ImageTexture.create_from_image(img)


static func _dot(img: Image, cx: float, cy: float, r: float, col: Color, soft: float) -> void:
	var ri: int = int(ceil(r + soft)) + 1
	var bx: int = int(floor(cx))
	var by: int = int(floor(cy))
	for yy in range(by - ri, by + ri + 1):
		for xx in range(bx - ri, bx + ri + 1):
			var dx: float = float(xx) + 0.5 - cx
			var dy: float = float(yy) + 0.5 - cy
			var d: float = sqrt(dx * dx + dy * dy)
			var a: float = clampf((r - d) / maxf(soft, 0.001), 0.0, 1.0)
			if a <= 0.0:
				continue
			var px: int = posmod(xx, TEX)
			var py: int = posmod(yy, TEX)
			var was: Color = img.get_pixel(px, py)
			img.set_pixel(px, py, was.lerp(col, a))


static func _paint_swirls(img: Image, rng: RandomNumberGenerator, ink: Color, accent: Color) -> void:
	var cols: int = 3
	var rows: int = 3
	var cw: float = float(TEX) / float(cols)
	var chh: float = float(TEX) / float(rows)
	for gy in range(rows):
		for gx in range(cols):
			var cx: float = (float(gx) + 0.5) * cw + rng.randf_range(-0.16, 0.16) * cw
			var cy: float = (float(gy) + 0.5) * chh + rng.randf_range(-0.16, 0.16) * chh
			var th0: float = rng.randf_range(0.0, TAU)
			var spin: float = 1.0 if rng.randf() < 0.5 else -1.0
			var big: float = cw * rng.randf_range(0.32, 0.44)
			var turns: float = rng.randf_range(1.30, 1.90)
			var steps: int = 46
			for s in range(steps + 1):
				var f: float = float(s) / float(steps)
				var th: float = th0 + spin * f * TAU * turns
				var rad: float = big * (0.10 + 0.90 * pow(1.0 - f, 0.82))
				var px: float = cx + cos(th) * rad
				var py: float = cy + sin(th) * rad
				var tw: float = lerpf(cw * 0.095, cw * 0.020, pow(f, 0.7))
				_dot(img, px, py, tw, ink, 1.4)
			var nd: int = rng.randi_range(4, 7)
			for k in range(nd):
				var ang: float = rng.randf_range(0.0, TAU)
				var rr: float = big * rng.randf_range(0.95, 1.30)
				_dot(img, cx + cos(ang) * rr, cy + sin(ang) * rr, cw * rng.randf_range(0.018, 0.040), accent, 1.2)


static func _hspan(img: Image, cx: float, row: int, hw: float, col: Color, soft: float) -> void:
	var ri: int = int(ceil(hw + soft)) + 1
	var bx: int = int(floor(cx))
	var py: int = posmod(row, TEX)
	for xx in range(bx - ri, bx + ri + 1):
		var dx: float = absf(float(xx) + 0.5 - cx)
		var a: float = clampf((hw - dx) / maxf(soft, 0.001), 0.0, 1.0)
		if a <= 0.0:
			continue
		var px: int = posmod(xx, TEX)
		var was: Color = img.get_pixel(px, py)
		img.set_pixel(px, py, was.lerp(col, a))


static func _paint_stripes(img: Image, rng: RandomNumberGenerator, ink: Color, accent: Color) -> void:
	var n: int = rng.randi_range(7, 11)
	var pitch: float = float(TEX) / float(n)
	for k in range(n):
		var cx: float = (float(k) + rng.randf_range(0.18, 0.82)) * pitch
		var hw: float = pitch * rng.randf_range(0.055, 0.150)
		var col: Color = ink if (k % 2 == 0) else accent
		var wob_a: float = rng.randf_range(0.8, 2.6)
		var wob_f: float = float(rng.randi_range(1, 3))
		var ph: float = rng.randf_range(0.0, TAU)
		for y in range(TEX):
			var fy: float = float(y)
			var wob: float = wob_a * sin(TAU * wob_f * fy / float(TEX) + ph)
			_hspan(img, cx + wob, y, hw, col, 1.1)
	var m: int = rng.randi_range(5, 9)
	for k in range(m):
		var cx: float = rng.randf_range(0.0, float(TEX))
		var fk: float = float(k)
		for y in range(TEX):
			var fy: float = float(y)
			var wob: float = 1.2 * sin(TAU * 2.0 * fy / float(TEX) + fk)
			_hspan(img, cx + wob, y, 0.85, accent, 1.0)


static func _paint_vines(img: Image, rng: RandomNumberGenerator, ink: Color, accent: Color) -> void:
	var n: int = rng.randi_range(4, 6)
	for k in range(n):
		var x0: float = rng.randf_range(0.0, float(TEX))
		var amp: float = float(TEX) * rng.randf_range(0.06, 0.14)
		var freq: float = float(rng.randi_range(1, 2))
		var ph: float = rng.randf_range(0.0, TAU)
		var steps: int = 170
		for s in range(steps + 1):
			var f: float = float(s) / float(steps)
			var py: float = f * float(TEX)
			var px: float = x0 + amp * sin(TAU * freq * f + ph) + amp * 0.38 * sin(TAU * freq * 2.0 * f + ph * 1.7)
			var tw: float = 2.3 + 1.5 * sin(PI * f * 3.0)
			_dot(img, px, py, tw, ink, 1.3)
		var nh: int = rng.randi_range(3, 5)
		for h in range(nh):
			var f: float = (float(h) + 0.5) / float(nh)
			var py: float = f * float(TEX)
			var px: float = x0 + amp * sin(TAU * freq * f + ph) + amp * 0.38 * sin(TAU * freq * 2.0 * f + ph * 1.7)
			var out_s: float = 1.0 if rng.randf() < 0.5 else -1.0
			var hook_r: float = float(TEX) * rng.randf_range(0.035, 0.062)
			var hsteps: int = 22
			var a0: float = rng.randf_range(0.0, TAU)
			for s in range(hsteps + 1):
				var g: float = float(s) / float(hsteps)
				var ang: float = a0 + out_s * g * TAU * 0.85
				var rad: float = hook_r * (0.15 + 0.85 * (1.0 - g))
				var qx: float = px + out_s * hook_r * 0.9 + cos(ang) * rad
				var qy: float = py + sin(ang) * rad
				_dot(img, qx, qy, lerpf(2.0, 0.9, g), ink, 1.2)
			_dot(img, px + out_s * hook_r * 1.6, py + hook_r * 0.5, hook_r * 0.22, accent, 1.2)


static func _paint_crackle(img: Image, rng: RandomNumberGenerator, col: Color) -> void:
	var n: int = rng.randi_range(11, 17)
	for k in range(n):
		var x: float = rng.randf_range(0.0, float(TEX))
		var y: float = rng.randf_range(0.0, float(TEX))
		var ang: float = rng.randf_range(0.0, TAU)
		var steps: int = rng.randi_range(18, 42)
		for s in range(steps):
			ang += rng.randf_range(-0.34, 0.34)
			x += cos(ang) * 2.3
			y += sin(ang) * 2.3
			_dot(img, x, y, 0.95, col, 1.0)
