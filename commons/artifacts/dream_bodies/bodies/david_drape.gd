extends RefCounted

## dream_bodies / david_drape — one neoclassical figure in a heavy robe, mid-twist,
## one bare arm flung up.
##
## Reference: scratchpad/refs/david_pole.png (2048x536 panorama) — a Jacques-Louis
## David crowd rebuilt as a frieze: muscular ivory bodies buried in enormous matte
## velvet robes (lilac-pink, deep violet, sage green, olive-gold, and one in broad
## blue-and-white stripes), bare arms and shoulders, dark curly hair, every figure
## leaning hard off its own axis, one kneeling, bare feet on the ground.
##
## Reproduced, and how:
##   1. The lean and the twist — ONE leaning axis serves both flesh and cloth
##      (_axis_y): a contrapposto S (hips pushed one way, chest forward, shoulders
##      the other) plus a 20-38 deg shoulder yaw against the hips, so the robe
##      leans with the body instead of standing beside it.
##   2. The cloth IS the subject — five or six swept panels built with SurfaceTool from a
##      keyed vertical radius profile with three sine harmonics in theta whose
##      phase drifts with height, so folds spiral as they fall; fold amplitude
##      grows toward the hem, where the profile flares and pools on the floor.
##   3. Deep shadow between folds — there are no lights, so the shading is baked
##      as vertex colour from the fold value itself (crest 1.30, valley 0.30),
##      times a floor-ward ambient darkening and one soft key lobe. Roughness 0.87.
##   4. Layers, not a cone — a pale chemise, the closed robe whose top edge rides
##      high over the covered shoulder and drops to the chest on the bare side,
##      and two or three over-drape sectors offset outward with a cowl dip and
##      hems at different heights. Every layer shares the fold phase, so the
##      layers nest instead of shearing through each other.
##   5. The swirl that shows the leg — an angular hem-lift lobe hauls the mantle
##      up over the pushing-off rear leg (bare heel raised, toes down), and a
##      second lobe bulges the cloth over the knee.
##   6. Bare arm and shoulder — deltoid, biceps bulge, elbow, forearm, hand and
##      five fingers in capsules and spheres, flung up and out, its shoulder left
##      uncovered by the robe's low edge on that side.
##   7. Curly hair — 30-40 small spheres on a golden-angle spiral over the upper
##      skull with the face cone skipped, plus four hanging three-bead locks.
##   8. The striped robe — one seed in five paints broad seamless 45 deg
##      blue-and-white bands into a 256px texture and runs them over the drapery
##      with uv1_triplanar, so the stripes cross panel edges unbroken.
##   9. Loose falling folds — three free sheets (a swag caught on the raised arm
##      whose end tucks back into the mantle, a fall from the gripping hand, and
##      a short cowl slung across the chest) swept along a gravity-swing curve
##      with cross folds and a ragged lower edge. Each is anchored ON the robe
##      surface: the robe's radius grows downward, so a sheet that merely hangs
##      is swallowed by the flare below it.
##
## Given up: the crowd itself (this is one figure, not the frieze), David's faces,
## fingers that actually grip cloth instead of passing through it, the dotted
## blue-grey robe and the grey leggings, and any cloth simulation — every fold
## here is an analytic sine.

const TEX: int = 128
const TEX_S: int = 256
const FOLD_D: float = 0.185

# [main, shadow, lining]
const ROBES: Array = [
	["#D6A2C6", "#8E5F86", "#EFD6E8"],
	["#7B4A9E", "#3E2058", "#B48ECB"],
	["#7FB98A", "#41704D", "#CDE3C8"],
	["#B79B3C", "#6A5417", "#E6D28E"],
	["#EDEFF0", "#8CA3BA", "#4E86C0"],
]
const SKIN: Array = ["#EADCC8", "#C6A78C"]
const HAIR: Array = ["#221917", "#3D2B23"]

# robe radius, evenly keyed over y = 0 .. 1.42. The top three keys carry ~12 mm
# more than the flare would give, because the cloth has to clear the shoulders.
const RKEY: Array = [0.408, 0.372, 0.342, 0.316, 0.290, 0.264, 0.240, 0.224, 0.214]
# torso, evenly keyed over the pelvis-to-shoulder span
const TORSO_R: Array = [0.150, 0.158, 0.152, 0.129, 0.133, 0.152, 0.151, 0.130]
const TORSO_X: Array = [1.16, 1.20, 1.16, 1.03, 1.10, 1.22, 1.34, 1.40]
const TORSO_Z: Array = [0.80, 0.82, 0.80, 0.74, 0.76, 0.80, 0.76, 0.66]


static func describe() -> String:
	return "A neoclassical figure caught mid-twist with one bare arm flung up, buried in a heavy matte-velvet robe whose swept folds spiral from the shoulder down to a hem pooling on the floor."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# ---- palette -----------------------------------------------------------
	var robe_i: int = rng.randi_range(0, ROBES.size() - 1)
	var striped: bool = robe_i == 4
	var pal: Array = ROBES[robe_i]
	var col_robe: Color = _hex(pal, 0)
	var col_shade: Color = _hex(pal, 1)
	var col_line: Color = _hex(pal, 2)
	var sash_i: int = (robe_i + rng.randi_range(1, ROBES.size() - 1)) % ROBES.size()
	var sash_pal: Array = ROBES[sash_i]
	var col_sash: Color = _hex(sash_pal, 0)
	if sash_i == 4:
		col_sash = Color("#B79B3C")
	var col_skin: Color = _hex(SKIN, 0).lerp(_hex(SKIN, 1), rng.randf_range(0.05, 0.35))
	var col_hair: Color = _hex(HAIR, 0).lerp(_hex(HAIR, 1), rng.randf_range(0.0, 0.6))

	# ---- textures ----------------------------------------------------------
	var velvet: ImageTexture = _noise_tex(rng, 16, 0.855, 1.0, 0.030, 0.85)
	var skin_tex: ImageTexture = _noise_tex(rng, 10, 0.935, 1.0, 0.010, 0.35)
	var cloth_tex: ImageTexture = velvet
	var cloth_albedo: Color = col_robe
	if striped:
		cloth_tex = _stripe_tex(rng, Color(0.965, 0.970, 0.968), Color("#4E86C0"))
		cloth_albedo = Color(1.0, 1.0, 1.0)

	var mat_skin: StandardMaterial3D = _matte(col_skin, 0.62)
	mat_skin.albedo_texture = skin_tex
	mat_skin.uv1_triplanar = true
	mat_skin.uv1_scale = Vector3(2.6, 2.6, 2.6)
	var mat_hair: StandardMaterial3D = _matte(col_hair, 0.48)
	var mat_nail: StandardMaterial3D = _matte(col_skin.lightened(0.12), 0.5)

	# ---- gesture -----------------------------------------------------------
	var s_h: float = rng.randf_range(0.96, 1.03)
	var y_sh: float = 1.335 * s_h
	var y_hip: float = 0.885 * s_h
	var arm_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var lean_z: float = rng.randf_range(-0.25, -0.16)
	var lean_x: float = arm_side * rng.randf_range(-0.02, 0.09)
	var hip_push: float = -arm_side * rng.randf_range(0.045, 0.085)
	var arch: float = rng.randf_range(0.040, 0.085)
	var twist: float = -arm_side * deg_to_rad(rng.randf_range(20.0, 38.0))
	var ax: Array = [y_sh, lean_x, lean_z, hip_push, arch]

	var th_cov: float = -arm_side * PI * 0.5 + rng.randf_range(-0.32, 0.32)
	var th_key: float = th_cov + PI * 0.72
	var stance: float = rng.randf_range(0.24, 0.33) * s_h
	var th_leg: float = arm_side * rng.randf_range(0.14, 0.34)

	var fp: Array = [
		float(rng.randi_range(5, 6)),
		float(rng.randi_range(8, 10)),
		float(rng.randi_range(13, 16)),
		rng.randf_range(0.0, TAU),
		rng.randf_range(0.0, TAU),
		rng.randf_range(0.0, TAU),
		rng.randf_range(0.9, 1.9) * (1.0 if rng.randf() < 0.5 else -1.0),
	]
	# radial lobes, five floats each: amp, theta, y centre, y width, lobe power.
	# knee (shows the pushing leg), the mantle's swing, and a shoulder swell that
	# keeps the covered deltoid and upper arm from breaking through the cloth.
	var bg: Array = [
		rng.randf_range(0.045, 0.070), th_leg, 0.46 * s_h, 0.24, 5.0,
		rng.randf_range(0.030, 0.055), th_cov, 0.62 * s_h, 0.45, 2.0,
		0.055 * s_h, th_cov, y_sh, 0.16 * s_h, 3.0,
	]
	var lin_base: Color = col_robe
	if striped:
		lin_base = Color(0.86, 0.90, 0.94)
	var lin_ratio: Color = _ratio(col_line, lin_base)

	_body(root, rng, mat_skin, mat_hair, mat_nail, col_hair, s_h, y_sh, y_hip, arm_side, twist, stance, ax)
	_robe(root, rng, cloth_tex, cloth_albedo, col_robe, col_shade, col_line, col_sash, lin_ratio, striped, s_h, y_sh, y_hip, arm_side, twist, th_cov, th_key, th_leg, ax, fp, bg)

	# ---- fit, centre, settle ----------------------------------------------
	var box: AABB = _union_aabb(root)
	var k_w: float = 1.23 / maxf(box.size.x, 0.01)
	var k_d: float = 1.23 / maxf(box.size.z, 0.01)
	var k_h: float = 1.66 / maxf(box.size.y, 0.01)
	var kf: float = minf(1.0, minf(k_w, minf(k_d, k_h)))
	kf = maxf(kf, 0.66)
	if kf < 0.999:
		var pivot := Vector3(0.0, box.position.y, 0.0)
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cm: MeshInstance3D = ch
			var tf: Transform3D = cm.transform
			cm.transform = Transform3D(tf.basis.scaled(Vector3(kf, kf, kf)), pivot + (tf.origin - pivot) * kf)
		box = _union_aabb(root)

	# measured settle: nothing may hang below the floor, and x/z ride on centre
	var centre: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-centre.x, 0.0, -centre.z)
	if box.position.y < 0.0:
		shift.y = -box.position.y
	for ch2 in root.get_children():
		if not (ch2 is MeshInstance3D):
			continue
		var cm2: MeshInstance3D = ch2
		cm2.transform = Transform3D(cm2.transform.basis, cm2.transform.origin + shift)


# ---------------------------------------------------------------------------
# the flesh

static func _body(root: Node3D, rng: RandomNumberGenerator, mat_skin: StandardMaterial3D, mat_hair: StandardMaterial3D, mat_nail: StandardMaterial3D, col_hair: Color, s_h: float, y_sh: float, y_hip: float, arm_side: float, twist: float, stance: float, ax: Array) -> void:
	var sb := Basis(Vector3.UP, twist)
	var y_t0: float = y_hip - 0.075
	var y_t1: float = y_sh + 0.015

	# torso chain
	var n_tor: int = 13
	for i in range(n_tor):
		var tv: float = float(i) / float(n_tor - 1)
		var yy: float = lerpf(y_t0, y_t1, tv)
		var cen: Vector3 = _axis_y(yy, ax)
		var tw: float = twist * (tv * tv * (3.0 - 2.0 * tv))
		var rr: float = _key(tv, TORSO_R) * s_h
		var kx: float = _key(tv, TORSO_X)
		var kz: float = _key(tv, TORSO_Z)
		_ell(root, rr, Vector3(kx, 1.0, kz), tw, cen, mat_skin)

	var sh_c: Vector3 = _axis_y(y_sh, ax)
	var chest_c: Vector3 = _axis_y(y_sh - 0.155 * s_h, ax)
	var hip_c: Vector3 = _axis_y(y_hip, ax)

	# pectorals and collarbones
	for si in range(2):
		var sd: float = -1.0 if si == 0 else 1.0
		var pec: Vector3 = chest_c + sb * Vector3(sd * 0.078 * s_h, 0.012 * s_h, -0.115 * s_h)
		_ell(root, 0.070 * s_h, Vector3(1.25, 0.86, 0.66), twist, pec, mat_skin)
		var cl_a: Vector3 = sh_c + sb * Vector3(sd * 0.020 * s_h, -0.028 * s_h, -0.070 * s_h)
		var cl_b: Vector3 = sh_c + sb * Vector3(sd * 0.150 * s_h, -0.042 * s_h, -0.048 * s_h)
		_cap(root, cl_a, cl_b, 0.024 * s_h, mat_skin)

	# neck
	var head_yaw: float = twist * 0.55 + deg_to_rad(rng.randf_range(-16.0, 16.0))
	var head_pitch: float = deg_to_rad(rng.randf_range(8.0, 22.0))
	var f_head := Vector3(sin(head_yaw) * cos(head_pitch), sin(head_pitch), -cos(head_yaw) * cos(head_pitch)).normalized()
	var u_head: Vector3 = (Vector3.UP - f_head * Vector3.UP.dot(f_head)).normalized()
	var r_hd: Vector3 = f_head.cross(u_head).normalized()
	var hb := Basis(r_hd, u_head, -f_head)
	var head_c: Vector3 = sh_c + Vector3(0.0, 0.158 * s_h, 0.0) + f_head * (0.026 * s_h)
	var neck_a: Vector3 = sh_c + Vector3(0.0, 0.005 * s_h, -0.010 * s_h)
	var neck_b: Vector3 = head_c - u_head * (0.070 * s_h)
	_cap(root, neck_a, _lerp_v(neck_a, neck_b, 0.55), 0.052 * s_h, mat_skin)
	_cap(root, _lerp_v(neck_a, neck_b, 0.45), neck_b, 0.046 * s_h, mat_skin)

	# skull, jaw, brow, nose, ears
	var r_hh: float = 0.090 * s_h
	_ell_b(root, r_hh, Vector3(0.95, 1.06, 1.00), hb, head_c, mat_skin)
	_ell_b(root, r_hh * 0.72, Vector3(0.94, 0.80, 1.02), hb, head_c + hb * Vector3(0.0, -0.052 * s_h, -0.024 * s_h), mat_skin)
	_ell_b(root, r_hh * 0.44, Vector3(1.05, 0.70, 0.90), hb, head_c + hb * Vector3(0.0, -0.070 * s_h, -0.056 * s_h), mat_skin)
	_ell_b(root, r_hh * 0.60, Vector3(1.30, 0.42, 0.72), hb, head_c + hb * Vector3(0.0, 0.030 * s_h, -0.074 * s_h), mat_skin)
	_ell_b(root, r_hh * 0.24, Vector3(0.82, 1.15, 1.30), hb, head_c + hb * Vector3(0.0, -0.010 * s_h, -0.088 * s_h), mat_skin)
	for si2 in range(2):
		var sd2: float = -1.0 if si2 == 0 else 1.0
		_ell_b(root, r_hh * 0.30, Vector3(0.36, 1.15, 0.85), hb, head_c + hb * Vector3(sd2 * 0.086 * s_h, -0.004 * s_h, 0.012 * s_h), mat_skin)

	# curly hair cap on a golden-angle spiral, face cone skipped
	var n_hair: int = rng.randi_range(30, 40)
	var ga: float = PI * (3.0 - sqrt(5.0))
	var hair_ph: float = rng.randf_range(0.0, TAU)
	for hi in range(n_hair):
		var fi: float = (float(hi) + 0.5) / float(n_hair)
		var cz: float = 1.0 - fi * 1.30
		var sr: float = sqrt(maxf(0.0, 1.0 - cz * cz))
		var an: float = ga * float(hi) + hair_ph
		var dl := Vector3(sr * cos(an), cz, sr * sin(an))
		if dl.z < -0.34 and dl.y < 0.30:
			continue
		var cr: float = rng.randf_range(0.020, 0.033) * s_h
		var stretch := Vector3(dl.x * 0.95, dl.y * 1.06, dl.z)
		var hp: Vector3 = head_c + hb * (stretch * (r_hh * 0.97) + stretch.normalized() * (cr * 0.42))
		var mh: StandardMaterial3D = _matte(col_hair.lightened(rng.randf_range(0.0, 0.16)), 0.46)
		_ell(root, cr, Vector3(1.0, 0.86, 1.0), 0.0, hp, mh)
	# four hanging locks at the nape
	for lk in range(4):
		var la: float = float(lk) / 3.0
		var base_d := Vector3(lerpf(-0.72, 0.72, la), -0.22, 0.72).normalized()
		var lp: Vector3 = head_c + hb * (base_d * (r_hh * 0.98))
		var fall: Vector3 = (hb * Vector3(base_d.x * 0.35, -1.0, base_d.z * 0.45)).normalized()
		for lb in range(3):
			var lr: float = rng.randf_range(0.017, 0.026) * s_h
			lp = lp + fall * (lr * 1.45) + hb * Vector3(0.0, 0.0, 0.004)
			_ell(root, lr, Vector3(1.0, 0.92, 1.0), 0.0, lp, mat_hair)

	# hips
	_ell(root, 0.152 * s_h, Vector3(1.24, 0.86, 0.84), twist * 0.15, hip_c + Vector3(0.0, -0.030 * s_h, 0.0), mat_skin)
	_ell(root, 0.132 * s_h, Vector3(1.20, 0.82, 0.88), 0.0, hip_c + Vector3(0.0, -0.090 * s_h, 0.010 * s_h), mat_skin)

	# legs: support leg under the lean, rear leg pushing off with the heel up
	var sup_x: float = -arm_side * 0.078 * s_h
	var trl_x: float = arm_side * 0.086 * s_h
	var sup_hip: Vector3 = hip_c + Vector3(sup_x, -0.060 * s_h, -0.010 * s_h)
	var sup_knee := Vector3(hip_c.x + sup_x * 1.12, 0.452 * s_h, hip_c.z * 0.32 - 0.055 * s_h)
	var sup_ank := Vector3(sup_knee.x + sup_x * 0.06, 0.078 * s_h, sup_knee.z + 0.038 * s_h)
	var sup_ball := sup_ank + Vector3(0.0, -0.030 * s_h, -0.098 * s_h)
	_cap(root, sup_hip, sup_knee, 0.086 * s_h, mat_skin)
	_cap(root, sup_knee, sup_ank, 0.060 * s_h, mat_skin)
	_foot(root, sup_ank, sup_ball, s_h, mat_skin, mat_nail)

	var trl_hip: Vector3 = hip_c + Vector3(trl_x, -0.060 * s_h, 0.022 * s_h)
	var trl_knee := Vector3(hip_c.x + trl_x * 1.10, 0.498 * s_h, hip_c.z * 0.42 + 0.128 * s_h)
	var trl_ank := Vector3(trl_knee.x + trl_x * 0.10, 0.122 * s_h, trl_knee.z + stance * 0.62)
	var trl_ball := trl_ank + Vector3(0.0, -0.072 * s_h, 0.070 * s_h)
	_cap(root, trl_hip, trl_knee, 0.084 * s_h, mat_skin)
	_cap(root, trl_knee, trl_ank, 0.058 * s_h, mat_skin)
	_foot(root, trl_ank, trl_ball, s_h, mat_skin, mat_nail)

	# bare arm, flung up and out
	var sh_a: Vector3 = sh_c + sb * Vector3(arm_side * 0.172 * s_h, 0.006 * s_h, -0.010 * s_h)
	var elb_a: Vector3 = sh_a + sb * Vector3(arm_side * 0.200 * s_h, 0.058 * s_h, -0.050 * s_h)
	var wri_a: Vector3 = elb_a + sb * Vector3(arm_side * 0.052 * s_h, 0.096 * s_h, -0.104 * s_h)
	_ell(root, 0.072 * s_h, Vector3(1.05, 1.02, 0.94), twist, sh_a, mat_skin)
	_cap(root, sh_a, _lerp_v(sh_a, elb_a, 0.55), 0.056 * s_h, mat_skin)
	_ell(root, 0.052 * s_h, Vector3(1.0, 1.35, 1.0), 0.0, _lerp_v(sh_a, elb_a, 0.42), mat_skin)
	_cap(root, _lerp_v(sh_a, elb_a, 0.45), elb_a, 0.048 * s_h, mat_skin)
	_ell(root, 0.046 * s_h, Vector3(1.0, 1.0, 1.0), 0.0, elb_a, mat_skin)
	_cap(root, elb_a, _lerp_v(elb_a, wri_a, 0.55), 0.046 * s_h, mat_skin)
	_cap(root, _lerp_v(elb_a, wri_a, 0.45), wri_a, 0.036 * s_h, mat_skin)
	_hand(root, wri_a, (wri_a - elb_a).normalized(), sb * Vector3(arm_side, 0.0, 0.0), s_h, 1.0, mat_skin, mat_nail)

	# covered arm, hand down at the front of the hip gripping the drape
	var sh_b: Vector3 = sh_c + sb * Vector3(-arm_side * 0.172 * s_h, -0.012 * s_h, -0.006 * s_h)
	var elb_b: Vector3 = sh_b + Vector3(-arm_side * 0.056 * s_h, -0.192 * s_h, -0.058 * s_h)
	var wri_b: Vector3 = elb_b + Vector3(arm_side * 0.024 * s_h, -0.158 * s_h, -0.118 * s_h)
	_ell(root, 0.070 * s_h, Vector3(1.05, 1.02, 0.94), twist, sh_b, mat_skin)
	_cap(root, sh_b, elb_b, 0.052 * s_h, mat_skin)
	_ell(root, 0.044 * s_h, Vector3(1.0, 1.0, 1.0), 0.0, elb_b, mat_skin)
	_cap(root, elb_b, wri_b, 0.042 * s_h, mat_skin)
	_hand(root, wri_b, (wri_b - elb_b).normalized(), Vector3(arm_side, 0.0, 0.0), s_h, 0.8, mat_skin, mat_nail)


static func _foot(root: Node3D, ank: Vector3, ball: Vector3, s_h: float, mat: StandardMaterial3D, mat_nail: StandardMaterial3D) -> void:
	_cap(root, ank, ball, 0.046 * s_h, mat)
	_ell(root, 0.048 * s_h, Vector3(0.92, 0.86, 1.05), 0.0, ank + Vector3(0.0, -0.018 * s_h, (ank.z - ball.z) * 0.30), mat)
	var fwd: Vector3 = (ball - ank).normalized()
	var side := Vector3(-fwd.z, 0.0, fwd.x).normalized()
	for ti in range(3):
		var tf2: float = float(ti) - 1.0
		var tp: Vector3 = ball + fwd * (0.030 * s_h) + side * (tf2 * 0.024 * s_h) + Vector3(0.0, -0.012 * s_h, 0.0)
		_ell(root, 0.017 * s_h, Vector3(1.0, 0.86, 1.35), 0.0, tp, mat_nail)


static func _hand(root: Node3D, wrist: Vector3, fwd: Vector3, side_in: Vector3, s_h: float, open_k: float, mat: StandardMaterial3D, mat_nail: StandardMaterial3D) -> void:
	var side: Vector3 = (side_in - fwd * side_in.dot(fwd)).normalized()
	var nrm: Vector3 = fwd.cross(side).normalized()
	var palm: Vector3 = wrist + fwd * (0.048 * s_h)
	# (side, nrm, fwd) is right-handed: fwd x side = nrm, so the determinant stays +1
	_ell_b(root, 0.048 * s_h, Vector3(1.10, 0.52, 0.98), Basis(side, nrm, fwd), palm, mat)
	for fi in range(4):
		var ff: float = float(fi) / 3.0
		var spread: float = (ff - 0.5) * 0.78 * open_k
		var dirf: Vector3 = (fwd + side * spread * 0.55 + nrm * (0.10 * open_k)).normalized()
		var ln: float = lerpf(0.052, 0.040, absf(ff - 0.45) * 1.6) * s_h * (0.75 + 0.45 * open_k)
		var a: Vector3 = palm + fwd * (0.034 * s_h) + side * ((ff - 0.5) * 0.052 * s_h)
		var b: Vector3 = a + dirf * ln
		var c: Vector3 = b + (dirf + nrm * 0.35 * open_k).normalized() * (ln * 0.75)
		_cap(root, a, b, 0.013 * s_h, mat)
		_cap(root, b, c, 0.011 * s_h, mat_nail)
	var th_dir: Vector3 = (fwd * 0.55 - side * 0.80 * open_k - nrm * 0.25).normalized()
	var ta: Vector3 = palm - side * (0.036 * s_h)
	_cap(root, ta, ta + th_dir * (0.056 * s_h), 0.015 * s_h, mat)


# ---------------------------------------------------------------------------
# the cloth

static func _robe(root: Node3D, rng: RandomNumberGenerator, tex: ImageTexture, albedo: Color, col_robe: Color, col_shade: Color, col_line: Color, col_sash: Color, lin: Color, striped: bool, s_h: float, y_sh: float, y_hip: float, arm_side: float, twist: float, th_cov: float, th_key: float, th_leg: float, ax: Array, fp: Array, bg: Array) -> void:
	var tri: float = 2.05 if striped else 3.4
	var c_under: Color = col_line
	var c_deep: Color = col_robe.lerp(col_shade, 0.26)
	if striped:
		c_under = Color(0.86, 0.88, 0.90)
		c_deep = Color(0.87, 0.90, 0.93)
	var mat_main: StandardMaterial3D = _cloth(albedo, tex, tri)
	var mat_under: StandardMaterial3D = _cloth(c_under, tex, tri * 1.15)
	var mat_deep: StandardMaterial3D = _cloth(c_deep, tex, tri)
	var mat_sash: StandardMaterial3D = _cloth(col_sash, tex, tri * 1.3)

	var hem_ph: float = rng.randf_range(0.0, TAU)
	var lift_a: float = rng.randf_range(0.18, 0.30) * s_h

	# 1 — chemise, nested exactly under the robe (same fold field, minus 55 mm)
	var chem: Dictionary = _spec()
	chem["nth"] = 48
	chem["ny"] = 9
	chem["yhi"] = 1.00 * s_h
	chem["ylo"] = 0.90 * s_h
	chem["thcov"] = th_cov
	chem["hemw"] = 0.018 * s_h
	chem["roff"] = -0.055 * s_h
	chem["thick"] = 0.008
	chem["phem"] = hem_ph
	chem["keyth"] = th_key
	chem["sh"] = s_h
	_add(root, _sweep(chem, fp, ax, bg, lin), mat_under)

	# 2 — the robe: closed, high over the covered shoulder, chest-low on the bare side
	var main: Dictionary = _spec()
	main["nth"] = 66
	main["ny"] = 14
	main["yhi"] = 1.300 * s_h
	main["ylo"] = 1.000 * s_h
	main["thcov"] = th_cov
	main["hemw"] = 0.034 * s_h
	main["lifta"] = lift_a
	main["liftt"] = th_leg
	main["phem"] = hem_ph
	main["keyth"] = th_key
	main["thick"] = 0.013
	main["sh"] = s_h
	_add(root, _sweep(main, fp, ax, bg, lin), mat_main)

	# 3..5 — over-drape sectors: cowled, offset outward, hems at different heights
	var n_over: int = rng.randi_range(2, 3)
	var over_defs: Array = [
		[th_cov, deg_to_rad(196.0), 0.028, 1.24, 0.030, 0.060, 1.285, 1.02, 40],
		[th_cov + 1.10, deg_to_rad(132.0), 0.054, 1.34, 0.300, 0.110, 1.245, 1.05, 34],
		[th_cov - 1.52, deg_to_rad(96.0), 0.064, 1.30, 0.520, 0.085, 1.190, 0.99, 28],
	]
	for oi in range(n_over):
		var od: Array = over_defs[oi]
		var ov: Dictionary = _spec()
		ov["th0"] = float(od[0]) - float(od[1]) * 0.5
		ov["span"] = float(od[1])
		ov["nth"] = int(od[8])
		ov["ny"] = 12
		ov["ybot"] = float(od[4]) * s_h
		ov["yhi"] = float(od[6]) * s_h
		ov["ylo"] = float(od[7]) * s_h
		ov["thcov"] = th_cov
		ov["dip"] = float(od[5]) * s_h
		ov["hemw"] = 0.030 * s_h
		ov["roff"] = float(od[2]) * s_h
		ov["foldk"] = float(od[3])
		ov["thick"] = 0.014
		ov["wrap"] = false
		ov["phem"] = hem_ph + float(oi) * 1.7
		ov["keyth"] = th_key
		ov["sh"] = s_h
		if oi == 0:
			ov["lifta"] = lift_a * 0.75
			ov["liftt"] = th_leg
		var mo: StandardMaterial3D = mat_main if oi != 1 else mat_deep
		_add(root, _sweep(ov, fp, ax, bg, lin), mo)

	# 6 — the sash, a spiral band from the covered shoulder to the far hip
	var sash_dir: float = 1.0 if arm_side > 0.0 else -1.0
	var sash: Dictionary = _spec()
	sash["th0"] = th_cov - 0.30 * sash_dir
	sash["span"] = 5.55 * sash_dir
	sash["nth"] = 56
	sash["ny"] = 4
	sash["yhi"] = 1.295 * s_h
	sash["ylo"] = 0.860 * s_h
	sash["thcov"] = th_cov
	sash["band"] = 0.105 * s_h
	sash["spiral"] = true
	sash["roff"] = 0.076 * s_h
	# foldk matches the over-drapes so the band rides their folds instead of
	# hovering over them; roff then clears every layer by a constant 22 mm
	sash["foldk"] = 1.30
	sash["thick"] = 0.011
	sash["wrap"] = false
	sash["keyth"] = th_key
	sash["sh"] = s_h
	_add(root, _sweep(sash, fp, ax, bg, lin), mat_sash)

	# cinched belt biting into the folds
	var y_belt: float = y_hip + 0.080 * s_h
	var c_belt: Vector3 = _axis_y(y_belt, ax)
	var r_belt: float = _robe_base(y_belt / s_h) * s_h
	var tor := TorusMesh.new()
	tor.inner_radius = r_belt - 0.030 * s_h
	tor.outer_radius = r_belt + 0.002 * s_h
	tor.rings = 32
	tor.ring_segments = 10
	var tm: MeshInstance3D = _add(root, tor, mat_sash)
	tm.transform = Transform3D(Basis(Vector3.UP, twist * 0.4) * Basis().scaled(Vector3(1.0, 1.0, 0.90)), c_belt)
	var knot_d := Vector3(sin(th_cov + PI), 0.0, cos(th_cov + PI))
	var knot_p: Vector3 = c_belt + knot_d * (r_belt - 0.010 * s_h)
	_ell(root, 0.040 * s_h, Vector3(1.15, 0.86, 0.90), 0.0, knot_p, mat_sash)
	for ci in range(2):
		var cf: float = -1.0 if ci == 0 else 1.0
		var ce: Vector3 = knot_p + Vector3(cf * 0.036 * s_h, -0.150 * s_h, 0.010 * s_h)
		_cap(root, knot_p, ce, 0.016 * s_h, mat_sash)

	# Loose falling folds. The robe's radius GROWS downward (0.21 at the shoulder
	# to 0.42 at the hem), so a sheet that simply hangs is swallowed by the mass
	# below it. Each of these is anchored ON the robe surface and either swings
	# out faster than the flare, or is short enough to end above it — except the
	# arm swag, whose last third is meant to tuck back into the mantle.
	var sh_c: Vector3 = _axis_y(y_sh, ax)
	var sb := Basis(Vector3.UP, twist)
	var arm_anchor: Vector3 = sh_c + sb * Vector3(arm_side * 0.26 * s_h, 0.040 * s_h, -0.030 * s_h)
	var falls: Array = [
		{
			"top": arm_anchor,
			"drop": 0.72 * s_h,
			"swing": Vector3(arm_side * 0.07, 0.0, 0.30) * s_h,
			"side": Vector3(cos(th_cov), 0.0, -sin(th_cov)),
			"w0": 0.20 * s_h, "w1": 0.34 * s_h, "nf": 4.0, "amp": 0.040 * s_h,
			"ph": hem_ph, "thick": 0.012, "ns": 15, "nw": 11, "twk": 1.6,
			"keyth": th_key, "lin": lin,
		},
		{
			"top": _axis_y(1.02 * s_h, ax) + Vector3(-arm_side * 0.10 * s_h, 0.0, -0.278 * s_h),
			"drop": 0.62 * s_h,
			"swing": Vector3(-arm_side * 0.05, 0.0, -0.085) * s_h,
			"side": Vector3(1.0, 0.0, 0.22),
			"w0": 0.15 * s_h, "w1": 0.26 * s_h, "nf": 3.0, "amp": 0.036 * s_h,
			"ph": hem_ph + 2.1, "thick": 0.012, "ns": 13, "nw": 9, "twk": -1.2,
			"keyth": th_key, "lin": lin,
		},
		{
			"top": _axis_y(1.26 * s_h, ax) + Vector3(arm_side * 0.03 * s_h, 0.0, -0.252 * s_h),
			"drop": 0.36 * s_h,
			"swing": Vector3(-arm_side * 0.05, 0.0, -0.085) * s_h,
			"side": Vector3(1.0, 0.0, 0.10),
			"w0": 0.30 * s_h, "w1": 0.42 * s_h, "nf": 5.0, "amp": 0.045 * s_h,
			"ph": hem_ph + 4.3, "thick": 0.013, "ns": 12, "nw": 13, "twk": 1.1,
			"keyth": th_key, "lin": lin,
		},
	]
	for fi2 in range(falls.size()):
		var fd: Dictionary = falls[fi2]
		var mf: StandardMaterial3D = mat_main if fi2 != 1 else mat_deep
		_add(root, _fall(fd), mf)


# ---------------------------------------------------------------------------
# sweep machinery

static func _spec() -> Dictionary:
	return {
		"th0": 0.0, "span": TAU, "nth": 48, "ny": 10,
		"ybot": 0.0, "yhi": 1.2, "ylo": 1.0, "thcov": 0.0,
		"dip": 0.0, "hemw": 0.02, "lifta": 0.0, "liftt": 0.0,
		"rs": 1.0, "roff": 0.0, "foldk": 1.0, "thick": 0.012,
		"band": 0.0, "spiral": false, "wrap": true, "phem": 0.0,
		"keyth": 0.0, "sh": 1.0,
	}


static func _sweep(spec: Dictionary, fp: Array, ax: Array, bg: Array, lin: Color) -> ArrayMesh:
	var th0: float = float(spec["th0"])
	var span: float = float(spec["span"])
	var n_th: int = int(spec["nth"])
	var n_y: int = int(spec["ny"])
	var y_bot: float = float(spec["ybot"])
	var y_hi: float = float(spec["yhi"])
	var y_lo: float = float(spec["ylo"])
	var th_cov: float = float(spec["thcov"])
	var dip: float = float(spec["dip"])
	var hem_w: float = float(spec["hemw"])
	var lift_a: float = float(spec["lifta"])
	var lift_t: float = float(spec["liftt"])
	var r_scale: float = float(spec["rs"])
	var r_off: float = float(spec["roff"])
	var fold_k: float = float(spec["foldk"])
	var thick: float = float(spec["thick"])
	var band: float = float(spec["band"])
	var spiral: bool = bool(spec["spiral"])
	var wrap: bool = bool(spec["wrap"])
	var ph_hem: float = float(spec["phem"])
	var key_th: float = float(spec["keyth"])
	var sh: float = float(spec["sh"])

	var outer: Array = []
	var inner: Array = []
	var cols: Array = []
	for k in range(n_y + 1):
		var fy: float = float(k) / float(n_y)
		var ro: Array = []
		var ri: Array = []
		var rc: Array = []
		for j in range(n_th + 1):
			var ft: float = float(j) / float(n_th)
			var th: float = th0 + span * ft
			var y_t: float = 0.0
			if spiral:
				y_t = lerpf(y_hi, y_lo, ft)
			else:
				var cw: float = 0.5 + 0.5 * cos(th - th_cov)
				var cs: float = cw * cw * (3.0 - 2.0 * cw)
				y_t = lerpf(y_lo, y_hi, cs) - dip * pow(sin(PI * ft), 1.4)
			var y_b: float = 0.0
			if band > 0.0:
				y_b = maxf(y_t - band, 0.010)
			else:
				var lift: float = 0.0
				var dl: float = cos(th - lift_t)
				if dl > 0.0:
					lift = lift_a * pow(dl, 3.0)
				y_b = y_bot + lift + hem_w * (0.5 + 0.5 * sin(7.0 * th + ph_hem))
			var y_top: float = maxf(y_t, y_b + 0.05)
			var yy: float = lerpf(y_b, y_top, pow(fy, 0.88))
			var cen: Vector3 = _axis_y(yy, ax)
			var w: float = _fold_w(yy, th, fp)
			var fa: float = _fold_amp(yy / sh)
			var rb: float = _robe_base(yy / sh) * sh * r_scale
			var rr: float = rb * (1.0 + fold_k * fa * FOLD_D * w) + r_off + _bulge(yy, th, bg)
			var dir := Vector3(sin(th), 0.0, cos(th))
			var po: Vector3 = cen + dir * rr
			var pi2: Vector3 = cen + dir * maxf(rr - thick, 0.03)
			po.y = maxf(po.y, 0.004)
			pi2.y = maxf(pi2.y, 0.004)
			ro.append(po)
			ri.append(pi2)
			var ao: float = lerpf(0.64, 1.0, clampf(yy / (0.86 * sh), 0.0, 1.0))
			var keyl: float = 0.86 + 0.30 * maxf(0.0, cos(th - key_th))
			var sd: float = clampf((1.0 + 0.40 * w) * ao * keyl, 0.30, 1.30)
			rc.append(Color(sd, sd, sd, 1.0))
		outer.append(ro)
		inner.append(ri)
		cols.append(rc)
	return _emit_shell(outer, inner, cols, wrap, lin)


static func _fall(spec: Dictionary) -> ArrayMesh:
	var top: Vector3 = spec["top"]
	var drop: float = float(spec["drop"])
	var swing: Vector3 = spec["swing"]
	var side_in: Vector3 = spec["side"]
	var w0: float = float(spec["w0"])
	var w1: float = float(spec["w1"])
	var nf: float = float(spec["nf"])
	var amp: float = float(spec["amp"])
	var ph: float = float(spec["ph"])
	var thick: float = float(spec["thick"])
	var ns: int = int(spec["ns"])
	var nw: int = int(spec["nw"])
	var twk: float = float(spec["twk"])
	var key_th: float = float(spec["keyth"])
	var lin: Color = spec["lin"]
	var key_dir := Vector3(sin(key_th), 0.0, cos(key_th))

	var outer: Array = []
	var inner: Array = []
	var cols: Array = []
	for k in range(ns + 1):
		var fs: float = float(k) / float(ns)
		var ro: Array = []
		var ri: Array = []
		var rc: Array = []
		for j in range(nw + 1):
			var fw: float = float(j) / float(nw)
			var s: float = fs * (0.84 + 0.16 * (0.5 + 0.5 * sin(4.3 * fw + ph)))
			var tang: Vector3 = (Vector3(0.0, -drop, 0.0) + swing * (2.0 * s)).normalized()
			var acr: Vector3 = (side_in - tang * side_in.dot(tang)).normalized()
			var nrm: Vector3 = tang.cross(acr).normalized()
			var base_p: Vector3 = top + Vector3(0.0, -drop * s, 0.0) + swing * (s * s)
			var wid: float = lerpf(w0, w1, s)
			var wv: float = sin(nf * PI * fw + ph + twk * s)
			var off: float = amp * (0.30 + 0.70 * s) * wv
			var po: Vector3 = base_p + acr * ((fw - 0.5) * wid) + nrm * off
			po.y = maxf(po.y, 0.006)
			var pi2: Vector3 = po - nrm * thick
			pi2.y = maxf(pi2.y, 0.004)
			ro.append(po)
			ri.append(pi2)
			var ao: float = lerpf(0.60, 1.0, clampf(po.y / 0.90, 0.0, 1.0))
			var keyl: float = 0.88 + 0.26 * maxf(0.0, nrm.dot(key_dir))
			var sd: float = clampf((1.0 + 0.42 * wv) * ao * keyl, 0.30, 1.30)
			rc.append(Color(sd, sd, sd, 1.0))
		outer.append(ro)
		inner.append(ri)
		cols.append(rc)
	return _emit_shell(outer, inner, cols, false, lin)


static func _emit_shell(outer: Array, inner: Array, cols: Array, wrap: bool, lin: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	var nk: int = outer.size() - 1
	var row0: Array = outer[0]
	var nj: int = row0.size() - 1
	for k in range(nk):
		var oa: Array = outer[k]
		var ob: Array = outer[k + 1]
		var ia: Array = inner[k]
		var ib: Array = inner[k + 1]
		var ca: Array = cols[k]
		var cb: Array = cols[k + 1]
		for j in range(nj):
			var p0: Vector3 = oa[j]
			var p1: Vector3 = oa[j + 1]
			var p2: Vector3 = ob[j + 1]
			var p3: Vector3 = ob[j]
			var q0: Vector3 = ia[j]
			var q1: Vector3 = ia[j + 1]
			var q2: Vector3 = ib[j + 1]
			var q3: Vector3 = ib[j]
			var c0: Color = ca[j]
			var c1: Color = ca[j + 1]
			var c2: Color = cb[j + 1]
			var c3: Color = cb[j]
			_quad(st, p0, p1, p2, p3, c0, c1, c2, c3, (q0 + q1 + q2 + q3) * 0.25)
			_quad(st, q0, q1, q2, q3, _mulc(c0, lin), _mulc(c1, lin), _mulc(c2, lin), _mulc(c3, lin), (p0 + p1 + p2 + p3) * 0.25)
	st.set_smooth_group(-1)
	# hem rim
	var ob0: Array = outer[0]
	var ib0: Array = inner[0]
	var ob1: Array = outer[1]
	var cb0: Array = cols[0]
	for j2 in range(nj):
		var e0: Vector3 = ob0[j2]
		var e1: Vector3 = ob0[j2 + 1]
		var e2: Vector3 = ib0[j2 + 1]
		var e3: Vector3 = ib0[j2]
		var ref0: Vector3 = ob1[j2]
		var ref1: Vector3 = ob1[j2 + 1]
		var cc: Color = _mulf(cb0[j2], 0.74)
		_quad(st, e0, e1, e2, e3, cc, cc, cc, cc, (ref0 + ref1) * 0.5)
	# top rim
	var obn: Array = outer[nk]
	var ibn: Array = inner[nk]
	var obm: Array = outer[nk - 1]
	var cbn: Array = cols[nk]
	for j3 in range(nj):
		var f0: Vector3 = obn[j3]
		var f1: Vector3 = obn[j3 + 1]
		var f2: Vector3 = ibn[j3 + 1]
		var f3: Vector3 = ibn[j3]
		var rf0: Vector3 = obm[j3]
		var rf1: Vector3 = obm[j3 + 1]
		var cd: Color = _mulf(cbn[j3], 0.80)
		_quad(st, f0, f1, f2, f3, cd, cd, cd, cd, (rf0 + rf1) * 0.5)
	# free side rims
	if not wrap:
		for k2 in range(nk):
			var ga0: Array = outer[k2]
			var ga1: Array = outer[k2 + 1]
			var ha0: Array = inner[k2]
			var ha1: Array = inner[k2 + 1]
			var cr0: Array = cols[k2]
			var la0: Vector3 = ga0[0]
			var la1: Vector3 = ga1[0]
			var lb1: Vector3 = ha1[0]
			var lb0: Vector3 = ha0[0]
			var lr0: Vector3 = ga0[1]
			var lr1: Vector3 = ga1[1]
			var ce: Color = _mulf(cr0[0], 0.76)
			_quad(st, la0, la1, lb1, lb0, ce, ce, ce, ce, (lr0 + lr1) * 0.5)
			var ra0: Vector3 = ga0[nj]
			var ra1: Vector3 = ga1[nj]
			var rb1: Vector3 = ha1[nj]
			var rb0: Vector3 = ha0[nj]
			var rr0: Vector3 = ga0[nj - 1]
			var rr1: Vector3 = ga1[nj - 1]
			var cf: Color = _mulf(cr0[nj], 0.76)
			_quad(st, ra0, ra1, rb1, rb0, cf, cf, cf, cf, (rr0 + rr1) * 0.5)
	st.generate_normals()
	return st.commit()


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, ca: Color, cb: Color, cc: Color, cd: Color, inside: Vector3) -> void:
	var nf: Vector3 = (c - a).cross(b - a)
	var cen: Vector3 = (a + b + c + d) * 0.25
	if nf.dot(cen - inside) >= 0.0:
		st.set_color(ca)
		st.add_vertex(a)
		st.set_color(cb)
		st.add_vertex(b)
		st.set_color(cc)
		st.add_vertex(c)
		st.set_color(ca)
		st.add_vertex(a)
		st.set_color(cc)
		st.add_vertex(c)
		st.set_color(cd)
		st.add_vertex(d)
	else:
		st.set_color(ca)
		st.add_vertex(a)
		st.set_color(cc)
		st.add_vertex(c)
		st.set_color(cb)
		st.add_vertex(b)
		st.set_color(ca)
		st.add_vertex(a)
		st.set_color(cd)
		st.add_vertex(d)
		st.set_color(cc)
		st.add_vertex(c)


# ---------------------------------------------------------------------------
# fields

static func _axis_y(y: float, ax: Array) -> Vector3:
	var y_sh: float = ax[0]
	var lx: float = ax[1]
	var lz: float = ax[2]
	var hp: float = ax[3]
	var arc: float = ax[4]
	var u: float = clampf(y / maxf(y_sh, 0.01), 0.0, 1.35)
	var f: float = 0.0
	if u <= 1.0:
		f = u * u * (3.0 - 2.0 * u)
	else:
		f = 1.0 + (u - 1.0) * 0.55
	var s1: float = sin(PI * clampf(u, 0.0, 1.0))
	return Vector3(lx * f + hp * s1, y, lz * f + arc * s1)


static func _fold_w(y: float, th: float, fp: Array) -> float:
	var n1: float = fp[0]
	var n2: float = fp[1]
	var n3: float = fp[2]
	var p1: float = fp[3]
	var p2: float = fp[4]
	var p3: float = fp[5]
	var tw: float = fp[6]
	return 0.56 * sin(n1 * th + p1 + tw * y) + 0.30 * sin(n2 * th + p2 - tw * 0.62 * y) + 0.14 * sin(n3 * th + p3 + tw * 1.35 * y)


static func _fold_amp(y: float) -> float:
	var v: float = clampf(y / 1.34, 0.0, 1.0)
	return lerpf(1.06, 0.34, pow(v, 0.85))


static func _robe_base(y: float) -> float:
	return _key(y / 1.42, RKEY)


static func _bulge(y: float, th: float, bg: Array) -> float:
	var total: float = 0.0
	var n: int = bg.size() / 5
	for i in range(n):
		var amp: float = bg[i * 5 + 0]
		var t0: float = bg[i * 5 + 1]
		var yc: float = bg[i * 5 + 2]
		var yw: float = bg[i * 5 + 3]
		var kk: float = bg[i * 5 + 4]
		var d: float = cos(th - t0)
		if d <= 0.0:
			continue
		var lobe: float = pow(d, kk)
		var dy: float = (y - yc) / maxf(yw, 0.01)
		total += amp * lobe * exp(-dy * dy)
	return total


static func _key(v: float, keys: Array) -> float:
	var n: int = keys.size()
	if n <= 1:
		return float(keys[0])
	var f: float = clampf(v, 0.0, 1.0) * float(n - 1)
	var i: int = int(floor(f))
	if i >= n - 1:
		return float(keys[n - 1])
	var u: float = f - float(i)
	var a: float = keys[i]
	var b: float = keys[i + 1]
	return lerpf(a, b, u)


# ---------------------------------------------------------------------------
# small helpers

static func _lerp_v(a: Vector3, b: Vector3, t: float) -> Vector3:
	# named to keep every helper underscored; only build() and describe() are exposed
	return a + (b - a) * t


static func _hex(arr: Array, i: int) -> Color:
	var code: String = arr[i]
	return Color(code)


static func _ratio(a: Color, b: Color) -> Color:
	return Color(
		clampf(a.r / maxf(b.r, 0.06), 0.30, 1.35) * 0.72,
		clampf(a.g / maxf(b.g, 0.06), 0.30, 1.35) * 0.72,
		clampf(a.b / maxf(b.b, 0.06), 0.30, 1.35) * 0.72,
		1.0)


static func _mulc(a: Color, b: Color) -> Color:
	return Color(a.r * b.r, a.g * b.g, a.b * b.b, 1.0)


static func _mulf(a: Color, f: float) -> Color:
	return Color(a.r * f, a.g * f, a.b * f, 1.0)


static func _matte(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m


static func _cloth(c: Color, tex: ImageTexture, tri: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.87
	m.metallic = 0.0
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(tri, tri, tri)
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _ell(root: Node3D, r: float, sc: Vector3, tw: float, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	return _ell_b(root, r, sc, Basis(Vector3.UP, tw), pos, mat)


static func _ell_b(root: Node3D, r: float, sc: Vector3, bs: Basis, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var sph := SphereMesh.new()
	sph.radius = r
	sph.height = r * 2.0
	sph.radial_segments = 20
	sph.rings = 10
	var mi: MeshInstance3D = _add(root, sph, mat)
	mi.transform = Transform3D(bs * Basis().scaled(sc), pos)
	return mi


static func _cap(root: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.008)
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = ln + r * 2.0
	cap.radial_segments = 14
	cap.rings = 5
	var mi: MeshInstance3D = _add(root, cap, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _basis_y_to(dir: Vector3) -> Basis:
	var d: Vector3 = dir.normalized()
	var dot_up: float = d.dot(Vector3.UP)
	if dot_up > 0.9999:
		return Basis()
	if dot_up < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	var axv: Vector3 = Vector3.UP.cross(d).normalized()
	var ang: float = acos(clampf(dot_up, -1.0, 1.0))
	return Basis(axv, ang)


static func _noise_tex(rng: RandomNumberGenerator, n: int, lo: float, hi: float, streak_a: float, streak_f: float) -> ImageTexture:
	var lat: Array = []
	for i in range(n * n):
		lat.append(rng.randf_range(lo, hi))
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var cell: float = float(TEX) / float(n)
	for y in range(TEX):
		for x in range(TEX):
			var fx: float = float(x) / cell
			var fy: float = float(y) / cell
			var x0: int = int(floor(fx))
			var y0: int = int(floor(fy))
			var tx: float = fx - float(x0)
			var ty: float = fy - float(y0)
			var sx: float = tx * tx * (3.0 - 2.0 * tx)
			var sy: float = ty * ty * (3.0 - 2.0 * ty)
			var va: float = lat[posmod(y0, n) * n + posmod(x0, n)]
			var vb: float = lat[posmod(y0, n) * n + posmod(x0 + 1, n)]
			var vc: float = lat[posmod(y0 + 1, n) * n + posmod(x0, n)]
			var vd: float = lat[posmod(y0 + 1, n) * n + posmod(x0 + 1, n)]
			var ab: float = lerpf(va, vb, sx)
			var cdv: float = lerpf(vc, vd, sx)
			var v: float = lerpf(ab, cdv, sy)
			var nap: float = 1.0 - streak_a + streak_a * (0.5 + 0.5 * sin(float(x) * streak_f + v * 7.0))
			var vv: float = clampf(v * nap, 0.0, 1.0)
			img.set_pixel(x, y, Color(vv, vv * 0.997, vv * 0.993))
	return ImageTexture.create_from_image(img)


static func _stripe_tex(rng: RandomNumberGenerator, ca: Color, cb: Color) -> ImageTexture:
	var img: Image = Image.create(TEX_S, TEX_S, false, Image.FORMAT_RGB8)
	var ns: int = rng.randi_range(4, 6)
	var per: float = float(TEX_S) / float(ns)
	var sgn: float = 1.0 if rng.randf() < 0.5 else -1.0
	var ph: float = rng.randf_range(0.0, per)
	var edge: float = 0.075
	for y in range(TEX_S):
		for x in range(TEX_S):
			var u: float = fposmod(float(x) + sgn * float(y) + ph, per) / per
			var m: float = smoothstep(0.0, edge, u) * (1.0 - smoothstep(0.5 - edge, 0.5, u))
			var mot: float = 0.955 + 0.045 * sin(float(x) * 0.8 + float(y) * 0.37)
			var col: Color = ca.lerp(cb, m)
			img.set_pixel(x, y, Color(clampf(col.r * mot, 0.0, 1.0), clampf(col.g * mot, 0.0, 1.0), clampf(col.b * mot, 0.0, 1.0)))
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
