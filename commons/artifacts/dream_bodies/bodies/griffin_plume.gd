extends RefCounted

## dream_bodies / griffin_plume — one enamelled bird-beast out of the dark garden.
##
## Reference: scratchpad/refs/anim5.png (4096x1072 panorama) — a crowd of ornate
## bird-beasts standing in a black-green garden. Long serpentine necks, small
## heads with hooked beaks, and skins made of LARGE OVERLAPPING EYE-SPOT SCALES
## (each an oval with a paler centre inside a dark rim) in old gold, rose pink,
## violet and sage. Feather fans break out behind the head, at the shoulders and
## along the tail. Everything painted, enamelled, jewel-like against the dark.
##
## Reproduced, and how:
##   1. Eye-spot skin — a 256x256 ImageTexture drawn in code: 4x5 offset rows of
##      overlapping ovals, painted back to front so they shingle, each with a
##      dark rim, a mid-tone body, an inner dark ring and a pale centre. Carried
##      on albedo_texture with WORLD triplanar so the pattern runs unbroken
##      across the whole sphere chain; uv1_scale shrinks the scales on the neck,
##      the belly and the legs.
##   2. The S-curved spine — 22..26 SphereMesh segments integrated from a keyed
##      lean profile: body near horizontal, neck sweeping back, then forward
##      again into the head; fat at the ribs, thin at the neck, plus a lateral
##      sway so the neck leans off the body's axis.
##   3. Hooked beak — a SurfaceTool sweep: nine six-sided rings tapering to a
##      tip, a keeled culmen, and the last third dropped by s^2.3 into a hook.
##      A shorter lower mandible comes out of the same function, closed.
##   4. Raised scale plates — nine flattened ellipsoids over shoulder and back,
##      each with its own pale centre boss, so the eye-spots exist as relief and
##      not only as paint.
##   5. Plume fans — nineteen blades: a fan behind the skull, one fan at each
##      shoulder, six sickle plumes off the tail base. Each is an ArrayMesh leaf
##      with a folded raised rachis, serrated edges, a curl and a twist,
##      vertex-coloured base to tip in the scheme's contrasting colour.
##   6. Long tail to the floor — 16..20 spheres pitching down and yawing to one
##      side, clamped to the plinth so the last third lies along it.
##   7. Two stubby thick legs — thigh / shank / tarsus capsules with a bird's
##      backward ankle, a foot ball, three forward toes and one back, cone claws,
##      one foot set forward of the other.
##   8. Palette by seed — old gold, rose, violet or sage body against a
##      contrasting plume colour, everything under clearcoat enamel.
##
## Given up: the garden itself and the crowding (this one stands alone), the fine
## filament down between the big scales, the wings and second heads some of the
## reference beasts carry, and the open beaks.

const TEX_SIZE: int = 256
const PLINTH_TOP: float = 0.05

# [body_lo, body_hi, belly, plate, plume_a, plume_b, beak, claw, eye_ring]
const SCHEMES: Array = [
	["#B8913F", "#D8BA6C", "#E8D9A8", "#C6A75A", "#8E6FA8", "#D2A0C0", "#E4A15C", "#5A4526", "#EADFC0"],
	["#B4536E", "#D4869C", "#EAC0CC", "#C2687F", "#7E6BA6", "#C9A9DA", "#E9C24E", "#5E2A3A", "#F0D6DE"],
	["#7C6AAE", "#A08FC9", "#D6CEE8", "#8A78BA", "#B7864F", "#DCC078", "#D98A6A", "#3A2E58", "#E3DAF0"],
	["#8B9A62", "#AFBB86", "#DCE2C0", "#97A46C", "#C0708C", "#E0A9BC", "#DDB055", "#3E4626", "#E9EED6"],
]


static func describe() -> String:
	return "An enamelled garden bird-beast plated in overlapping eye-spot scales, its serpentine neck leaning into a hooked beak, with plume fans at the head, shoulders and tail and a long tail curling down onto the plinth."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var scheme: Array = SCHEMES[rng.randi_range(0, SCHEMES.size() - 1)]
	var col_lo: Color = _c(scheme, 0)
	var col_hi: Color = _c(scheme, 1)
	var col_belly: Color = _c(scheme, 2)
	var col_plate: Color = _c(scheme, 3)
	var col_plume_a: Color = _c(scheme, 4)
	var col_plume_b: Color = _c(scheme, 5)
	var col_beak: Color = _c(scheme, 6)
	var col_claw: Color = _c(scheme, 7)
	var col_ring: Color = _c(scheme, 8)

	var skin_tex: ImageTexture = _eyespot_texture(rng)

	var mat_belly: StandardMaterial3D = _skin(col_belly, skin_tex, 7.5, 0.34)
	var mat_plate: StandardMaterial3D = _enamel(col_plate, 0.22)
	var mat_boss: StandardMaterial3D = _enamel(col_belly.lightened(0.12), 0.16)
	var mat_beak: StandardMaterial3D = _enamel(col_beak, 0.15)
	mat_beak.metallic = 0.24
	var mat_claw: StandardMaterial3D = _enamel(col_claw, 0.30)
	var mat_ring: StandardMaterial3D = _enamel(col_ring, 0.20)
	var mat_brow: StandardMaterial3D = _enamel(col_plate.darkened(0.12), 0.26)
	var mat_eye: StandardMaterial3D = _enamel(Color("#140E1A"), 0.06)
	mat_eye.emission_enabled = true
	mat_eye.emission = Color("#3C2A50")
	mat_eye.emission_energy_multiplier = 0.30
	var mat_leg: StandardMaterial3D = _skin(col_lo.lerp(col_beak, 0.40), skin_tex, 12.0, 0.38)
	var mat_plume := StandardMaterial3D.new()
	mat_plume.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	mat_plume.vertex_color_use_as_albedo = true
	mat_plume.roughness = 0.40
	mat_plume.metallic = 0.06
	mat_plume.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_plume.clearcoat_enabled = true
	mat_plume.clearcoat = 0.45
	mat_plume.clearcoat_roughness = 0.25
	var mat_plinth := StandardMaterial3D.new()
	mat_plinth.albedo_color = Color("#2B2C27")
	mat_plinth.roughness = 0.90

	# --- this individual ----------------------------------------------------
	var n_spine: int = rng.randi_range(22, 26)
	var body_k: float = rng.randf_range(0.94, 1.08)
	var y_hip: float = 0.62
	var y_head_base: float = rng.randf_range(1.31, 1.39)
	var lean_sign: float = 1.0 if rng.randf() < 0.5 else -1.0
	var lean: float = lean_sign * rng.randf_range(0.10, 0.19)
	var head_turn: float = -lean_sign * rng.randf_range(0.16, 0.44)
	var head_dip: float = rng.randf_range(0.34, 0.62)
	var tail_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var n_tail: int = rng.randi_range(16, 20)
	var forward_foot: float = 1.0 if rng.randf() < 0.5 else -1.0
	var a_keys: Array = [
		rng.randf_range(1.34, 1.48),
		rng.randf_range(1.02, 1.18),
		rng.randf_range(0.46, 0.66),
		rng.randf_range(-0.52, -0.34),
		rng.randf_range(-0.34, -0.18),
		rng.randf_range(0.46, 0.68),
		rng.randf_range(0.84, 1.06),
	]
	var r_keys: Array = [0.150, 0.172, 0.176, 0.150, 0.098, 0.070, 0.062]

	# --- spine: dry run for direction, then scaled so the head lands ---------
	var dirs: Array = []
	var rise: float = 0.0
	for i in range(1, n_spine):
		var t: float = float(i) / float(n_spine - 1)
		var ang: float = _key_curve(t, a_keys)
		var d := Vector3(lean * 1.6 * sin(PI * t), cos(ang), -sin(ang)).normalized()
		dirs.append(d)
		rise += d.y
	var step: float = (y_head_base - y_hip) / maxf(rise, 0.1)

	var pts: Array = []
	var radii: Array = []
	var p := Vector3(0.0, y_hip, 0.20)
	pts.append(p)
	radii.append(_key_curve(0.0, r_keys) * body_k)
	for i in range(1, n_spine):
		var t: float = float(i) / float(n_spine - 1)
		var d: Vector3 = dirs[i - 1]
		p = p + d * step
		pts.append(p)
		radii.append(_key_curve(t, r_keys) * body_k)

	# --- body, belly, raised plates -----------------------------------------
	for i in range(n_spine):
		var t: float = float(i) / float(n_spine - 1)
		var q: Vector3 = pts[i]
		var r: float = radii[i]
		var tang: Vector3 = _tangent(pts, i)
		var down: Vector3 = _perp_down(tang)
		var mat_seg: StandardMaterial3D = _skin(col_lo.lerp(col_hi, t), skin_tex, lerpf(3.2, 6.4, t), 0.30)
		var sph := SphereMesh.new()
		sph.radius = r
		sph.height = r * 2.0
		sph.radial_segments = 20
		sph.rings = 12
		var mi: MeshInstance3D = _add(root, sph, mat_seg)
		mi.transform = Transform3D(_basis_y_to(tang), q)
		if t <= 0.44:
			var bel := SphereMesh.new()
			bel.radius = r * 0.78
			bel.height = r * 1.56
			bel.radial_segments = 16
			bel.rings = 8
			var bm: MeshInstance3D = _add(root, bel, mat_belly)
			bm.transform = Transform3D(_basis_y_to(tang), q + down * (r * 0.42))

	# nine raised eye-spot plates over shoulder and back
	var plate_rows: int = 3
	var plate_cols: int = 3
	for pr in range(plate_rows):
		var tp: float = lerpf(0.12, 0.46, float(pr) / float(plate_rows - 1))
		var ip: int = int(floor(tp * float(n_spine - 1)))
		var qp: Vector3 = pts[ip]
		var rp: float = radii[ip]
		var tgp: Vector3 = _tangent(pts, ip)
		var up_v: Vector3 = -_perp_down(tgp)
		var side_v: Vector3 = tgp.cross(up_v).normalized()
		for pc in range(plate_cols):
			var aa: float = lerpf(-0.85, 0.85, float(pc) / float(plate_cols - 1))
			var nrm: Vector3 = (up_v * cos(aa) + side_v * sin(aa)).normalized()
			var at: Vector3 = qp + nrm * (rp * 0.90)
			var pl := SphereMesh.new()
			pl.radius = 0.052 * body_k
			pl.height = 0.104 * body_k
			pl.radial_segments = 16
			pl.rings = 8
			var plm: MeshInstance3D = _add(root, pl, mat_plate)
			# Basis.scaled() squashes along the WORLD axes; multiply instead so the
			# flattening happens along the plate's own axes
			var pb: Basis = _basis_y_to(nrm) * Basis().scaled(Vector3(1.35, 0.34, 1.05))
			plm.transform = Transform3D(pb, at)
			var bo := SphereMesh.new()
			bo.radius = 0.020 * body_k
			bo.height = 0.040 * body_k
			bo.radial_segments = 12
			bo.rings = 6
			var bom: MeshInstance3D = _add(root, bo, mat_boss)
			bom.transform = Transform3D(_basis_y_to(nrm) * Basis().scaled(Vector3(1.0, 0.45, 1.0)), at + nrm * (0.012 * body_k))

	var p_hip: Vector3 = pts[0]
	var r_hip: float = radii[0]

	# --- tail, curving down onto the plinth ---------------------------------
	var tail_pts: Array = []
	var tail_dirs: Array = []
	var tail_p: Vector3 = p_hip
	var tail_len: float = 0.68 * body_k
	var tail_step: float = tail_len / float(n_tail)
	for i in range(1, n_tail + 1):
		var s: float = float(i) / float(n_tail)
		var pitch: float = -0.30 - 1.05 * pow(s, 0.85)
		var yaw: float = tail_side * 1.35 * pow(s, 1.7)
		var d := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)).normalized()
		tail_p = tail_p + d * tail_step
		var tr: float = lerpf(r_hip * 0.86, 0.024, pow(s, 0.80))
		var ty: float = maxf(tail_p.y, PLINTH_TOP + tr)
		tail_p = Vector3(tail_p.x, ty, tail_p.z)
		tail_pts.append(tail_p)
		tail_dirs.append(d)
		var mat_t: StandardMaterial3D = _skin(col_lo.lerp(col_hi, 0.35 + 0.5 * s), skin_tex, lerpf(3.6, 9.0, s), 0.30)
		var sph := SphereMesh.new()
		sph.radius = tr
		sph.height = tr * 2.0
		sph.radial_segments = 16
		sph.rings = 10
		var mi: MeshInstance3D = _add(root, sph, mat_t)
		mi.transform = Transform3D(_basis_y_to(d), tail_p)
		if i % 4 == 0 and s < 0.62:
			var up_t: Vector3 = -_perp_down(d)
			var bmp := SphereMesh.new()
			bmp.radius = tr * 0.42
			bmp.height = tr * 0.84
			bmp.radial_segments = 12
			bmp.rings = 6
			var bpm: MeshInstance3D = _add(root, bmp, mat_plate)
			bpm.transform = Transform3D(_basis_y_to(up_t) * Basis().scaled(Vector3(1.3, 0.4, 1.0)), tail_p + up_t * (tr * 0.88))

	# --- legs ----------------------------------------------------------------
	var i_leg: int = int(floor(float(n_spine - 1) * 0.26))
	var p_leg: Vector3 = pts[i_leg]
	var r_leg: float = radii[i_leg]
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var fwd: float = -0.055 if sd == forward_foot else 0.030
		var hip := p_leg + Vector3(sd * (r_leg * 0.62), -r_leg * 0.52, 0.01)
		var y_ank: float = PLINTH_TOP + 0.215
		var y_knee: float = lerpf(hip.y, y_ank, 0.50)
		var knee := Vector3(hip.x + sd * 0.014, y_knee, hip.z - 0.085 + fwd * 0.5)
		var ankle := Vector3(hip.x + sd * 0.004, y_ank, hip.z + 0.055 + fwd * 0.5)
		var foot := Vector3(ankle.x, PLINTH_TOP + 0.030, ankle.z - 0.050 + fwd)
		_limb(root, hip, knee, 0.066 * body_k, mat_leg)
		_limb(root, knee, ankle, 0.048 * body_k, mat_leg)
		_limb(root, ankle, foot, 0.034 * body_k, mat_leg)
		var ball := SphereMesh.new()
		ball.radius = 0.036 * body_k
		ball.height = 0.072 * body_k
		ball.radial_segments = 14
		ball.rings = 8
		var bl: MeshInstance3D = _add(root, ball, mat_leg)
		bl.transform = Transform3D(Basis().scaled(Vector3(1.0, 0.72, 1.0)), foot)
		for toe_i in range(4):
			var ta: float = 2.30 if toe_i == 3 else (float(toe_i) - 1.0) * 0.52
			var tdir := Vector3(sin(ta) * 0.9 + sd * 0.10, -0.10, -cos(ta)).normalized()
			var toe_len: float = 0.075 if toe_i < 3 else 0.055
			var toe_end: Vector3 = foot + tdir * toe_len
			toe_end = Vector3(toe_end.x, PLINTH_TOP + 0.018, toe_end.z)
			_limb(root, foot, toe_end, 0.017 * body_k, mat_leg)
			var cdir: Vector3 = (tdir + Vector3(0.0, -0.35, 0.0)).normalized()
			_cone(root, toe_end + cdir * 0.010, cdir, 0.040, 0.011, mat_claw)

	# --- head ----------------------------------------------------------------
	var p_head_base: Vector3 = pts[n_spine - 1]
	var r_neck_end: float = radii[n_spine - 1]
	var tang_end: Vector3 = _tangent(pts, n_spine - 1)
	var f_head: Vector3 = (tang_end.rotated(Vector3.UP, head_turn) + Vector3(0.0, -head_dip, 0.0)).normalized()
	var u_head: Vector3 = (Vector3.UP - f_head * Vector3.UP.dot(f_head)).normalized()
	var r_head: Vector3 = f_head.cross(u_head).normalized()
	var hb := Basis(r_head, u_head, -f_head)
	var rh: float = 0.088 * body_k
	var h_org: Vector3 = p_head_base + f_head * (rh * 0.42) + u_head * (rh * 0.24)

	var mat_head: StandardMaterial3D = _skin(col_hi, skin_tex, 9.0, 0.28)
	var skull := SphereMesh.new()
	skull.radius = rh
	skull.height = rh * 2.0
	skull.radial_segments = 20
	skull.rings = 12
	var sk: MeshInstance3D = _add(root, skull, mat_head)
	sk.transform = Transform3D(hb * Basis().scaled(Vector3(0.90, 0.88, 1.22)), h_org)

	var filler := SphereMesh.new()
	filler.radius = r_neck_end * 1.02
	filler.height = r_neck_end * 2.04
	filler.radial_segments = 16
	filler.rings = 10
	var fm: MeshInstance3D = _add(root, filler, mat_head)
	fm.transform = Transform3D(hb, h_org - f_head * (rh * 0.42) - u_head * (rh * 0.34))

	var beak_len: float = 0.235 * body_k
	var upper: ArrayMesh = _beak(beak_len, 0.072 * body_k, 0.086 * body_k, 0.058 * body_k, 0.26, false)
	var um: MeshInstance3D = _add(root, upper, mat_beak)
	um.transform = Transform3D(hb, h_org + hb * Vector3(0.0, -0.010 * body_k, -rh * 0.72))
	var lower: ArrayMesh = _beak(beak_len * 0.82, 0.062 * body_k, 0.040 * body_k, 0.020 * body_k, 0.0, true)
	var lm: MeshInstance3D = _add(root, lower, mat_beak)
	lm.transform = Transform3D(hb, h_org + hb * Vector3(0.0, -0.045 * body_k, -rh * 0.70))

	for si in range(2):
		var sg: float = -1.0 if si == 0 else 1.0
		var eye_at: Vector3 = h_org + hb * Vector3(sg * rh * 0.76, rh * 0.22, -rh * 0.38)
		var eye := SphereMesh.new()
		eye.radius = 0.019 * body_k
		eye.height = 0.038 * body_k
		eye.radial_segments = 12
		eye.rings = 8
		var em: MeshInstance3D = _add(root, eye, mat_eye)
		em.transform = Transform3D(Basis(), eye_at)
		var ring := TorusMesh.new()
		ring.inner_radius = 0.019 * body_k
		ring.outer_radius = 0.030 * body_k
		ring.rings = 16
		ring.ring_segments = 8
		var rm: MeshInstance3D = _add(root, ring, mat_ring)
		rm.transform = Transform3D(_basis_y_to(r_head * sg), eye_at - r_head * sg * (0.004 * body_k))
		var brow := SphereMesh.new()
		brow.radius = 0.030 * body_k
		brow.height = 0.060 * body_k
		brow.radial_segments = 12
		brow.rings = 6
		var brm: MeshInstance3D = _add(root, brow, mat_brow)
		brm.transform = Transform3D(_basis_y_to(u_head + r_head * sg * 0.55) * Basis().scaled(Vector3(1.25, 0.42, 0.95)), h_org + hb * Vector3(sg * rh * 0.62, rh * 0.60, -rh * 0.30))
		var nos := SphereMesh.new()
		nos.radius = 0.010 * body_k
		nos.height = 0.020 * body_k
		nos.radial_segments = 10
		nos.rings = 6
		var nm: MeshInstance3D = _add(root, nos, mat_eye)
		nm.transform = Transform3D(hb * Basis().scaled(Vector3(0.9, 0.6, 1.6)), h_org + hb * Vector3(sg * 0.025 * body_k, 0.010 * body_k, -rh * 0.72 - 0.042 * body_k))

	# --- plume fans ----------------------------------------------------------
	# fan behind the skull
	var n_head_fan: int = 5
	for k in range(n_head_fan):
		var fr: float = float(k) / float(n_head_fan - 1)
		var aa: float = lerpf(-0.30, 0.95, fr)
		var pdir: Vector3 = (u_head * cos(aa) - f_head * sin(aa) + r_head * (fr - 0.5) * 0.55).normalized()
		var at: Vector3 = h_org - f_head * (rh * 0.85) + u_head * (rh * 0.30) + r_head * ((fr - 0.5) * rh * 0.9)
		var pl: float = lerpf(0.175, 0.115, absf(fr - 0.45) * 1.7) * body_k
		_plume(root, at, pdir, r_head, pl, 0.052 * body_k, -0.028, 0.30 * (fr - 0.5), col_plume_a, col_plume_b.lightened(0.10), mat_plume)

	# shoulder fans
	var i_sh: int = int(floor(float(n_spine - 1) * 0.46))
	var p_sh: Vector3 = pts[i_sh]
	var r_sh: float = radii[i_sh]
	var tg_sh: Vector3 = _tangent(pts, i_sh)
	var up_sh: Vector3 = -_perp_down(tg_sh)
	var side_sh: Vector3 = tg_sh.cross(up_sh).normalized()
	var back_sh: Vector3 = -tg_sh
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var n_blade: int = 4
		for k in range(n_blade):
			var fr: float = float(k) / float(n_blade - 1)
			var aa: float = lerpf(-0.18, 1.20, fr)
			var pdir: Vector3 = (up_sh * cos(aa) + side_sh * (sd * sin(aa)) + back_sh * 0.62).normalized()
			var at: Vector3 = p_sh + up_sh * (r_sh * 0.42) + side_sh * (sd * r_sh * 0.80) - tg_sh * (r_sh * 0.10)
			var pl: float = lerpf(0.30, 0.20, fr) * body_k
			var face: Vector3 = (side_sh * sd + up_sh * 0.25).normalized()
			_plume(root, at, pdir, face, pl, 0.085 * body_k, 0.045 * sd, 0.22 * sd, col_plume_a, col_plume_b, mat_plume)

	# tail sickle plumes
	var n_tail_plume: int = 6
	for k in range(n_tail_plume):
		var fr: float = float(k) / float(n_tail_plume - 1)
		var idx: int = int(floor(lerpf(1.0, 7.0, fr)))
		var at_t: Vector3 = tail_pts[idx]
		var dt: Vector3 = tail_dirs[idx]
		var up_t: Vector3 = -_perp_down(dt)
		var side_t: Vector3 = dt.cross(up_t).normalized()
		var swing: float = (float(k % 2) - 0.5) * 0.70
		var pdir: Vector3 = (up_t * 0.92 - dt * 0.42 + side_t * swing).normalized()
		var at: Vector3 = at_t + up_t * 0.045
		var pl: float = lerpf(0.29, 0.17, fr) * body_k
		var face: Vector3 = (side_t + up_t * 0.15).normalized()
		_plume(root, at, pdir, face, pl, 0.078 * body_k, 0.070, -0.26 * signf(swing + 0.001), col_plume_b, col_plume_a.lightened(0.14), mat_plume)

	# --- measured settle: fit, centre on x/z, stand on the floor -------------
	var box: AABB = _union_aabb(root)
	var top_y: float = box.position.y + box.size.y
	var kx: float = 1.18 / maxf(box.size.x, 0.001)
	var kz: float = 1.18 / maxf(box.size.z, 0.001)
	var ky: float = 1.64 / maxf(top_y, 0.001)
	var kfit: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kfit < 1.0:
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cm: MeshInstance3D = ch
			var tf: Transform3D = cm.transform
			cm.transform = Transform3D(tf.basis.scaled(Vector3(kfit, kfit, kfit)), tf.origin * kfit)
		box = _union_aabb(root)
	var ctr: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-ctr.x, PLINTH_TOP - box.position.y, -ctr.z)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + shift)
	box = _union_aabb(root)

	var plinth := BoxMesh.new()
	plinth.size = Vector3(clampf(box.size.x + 0.10, 0.45, 1.20), PLINTH_TOP, clampf(box.size.z + 0.10, 0.45, 1.20))
	var pm: MeshInstance3D = _add(root, plinth, mat_plinth)
	pm.transform = Transform3D(Basis(), Vector3(0.0, PLINTH_TOP * 0.5, 0.0))


# ---------------------------------------------------------------------------
# curves and frames

static func _key_curve(t: float, keys: Array) -> float:
	var n: int = keys.size() - 1
	var f: float = clampf(t, 0.0, 1.0) * float(n)
	var i: int = int(floor(f))
	if i >= n:
		var last_v: float = keys[n]
		return last_v
	var u: float = f - float(i)
	var s: float = u * u * (3.0 - 2.0 * u)
	var va: float = keys[i]
	var vb: float = keys[i + 1]
	return lerpf(va, vb, s)


static func _tangent(pts: Array, i: int) -> Vector3:
	var n: int = pts.size()
	var a: Vector3 = pts[maxi(i - 1, 0)]
	var b: Vector3 = pts[mini(i + 1, n - 1)]
	var d: Vector3 = b - a
	if d.length() < 0.0001:
		return Vector3.UP
	return d.normalized()


static func _perp_down(tang: Vector3) -> Vector3:
	var t: Vector3 = tang.normalized()
	var d: Vector3 = Vector3.DOWN - t * Vector3.DOWN.dot(t)
	if d.length() < 0.0005:
		d = Vector3.FORWARD - t * Vector3.FORWARD.dot(t)
	return d.normalized()


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


static func _blade_basis(dir: Vector3, face: Vector3) -> Basis:
	var yv: Vector3 = dir.normalized()
	var zv: Vector3 = face - yv * face.dot(yv)
	if zv.length() < 0.0005:
		zv = Vector3.FORWARD - yv * Vector3.FORWARD.dot(yv)
	if zv.length() < 0.0005:
		zv = Vector3.RIGHT - yv * Vector3.RIGHT.dot(yv)
	zv = zv.normalized()
	var xv: Vector3 = yv.cross(zv).normalized()
	return Basis(xv, yv, zv)


# ---------------------------------------------------------------------------
# materials and primitives

static func _c(scheme: Array, i: int) -> Color:
	var code: String = scheme[i]
	return Color(code)


static func _enamel(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.10
	m.clearcoat_enabled = true
	m.clearcoat = 0.70
	m.clearcoat_roughness = 0.16
	return m


static func _skin(c: Color, tex: ImageTexture, k: float, rough: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = _enamel(c, rough)
	m.metallic = 0.14
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 1.6
	m.uv1_scale = Vector3(k, k, k)
	return m


static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _limb(root: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.01)
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = ln + r * 2.0
	cap.radial_segments = 14
	cap.rings = 6
	var mi: MeshInstance3D = _add(root, cap, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _cone(root: Node3D, base: Vector3, dir: Vector3, h: float, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = dir.normalized()
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = r
	cyl.top_radius = 0.0
	cyl.height = h
	cyl.radial_segments = 10
	cyl.rings = 1
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(d), base + d * (h * 0.5))
	return mi


static func _plume(root: Node3D, at: Vector3, dir: Vector3, face: Vector3, ln: float, wid: float, curl: float, twist: float, c0: Color, c1: Color, mat: StandardMaterial3D) -> MeshInstance3D:
	var m: ArrayMesh = _plume_mesh(ln, wid, curl, twist, c0, c1)
	var mi: MeshInstance3D = _add(root, m, mat)
	mi.transform = Transform3D(_blade_basis(dir, face), at)
	return mi


# ---------------------------------------------------------------------------
# SurfaceTool geometry

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


static func _beak(ln: float, w0: float, h0: float, hook: float, keel: float, lower: bool) -> ArrayMesh:
	# swept six-sided profile along -Z, tapering to a tip, the last third hooked down
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 9
	var rings: Array = []
	var cents: Array = []
	for k in range(n):
		var s: float = 0.94 * float(k) / float(n - 1)
		var drop: float = hook * pow(s, 2.3)
		var cc := Vector3(0.0, -drop, -ln * s)
		var hw: float = w0 * 0.5 * pow(1.0 - s * 0.96, 0.70)
		var hh: float = h0 * 0.5 * pow(1.0 - s * 0.96, 0.52)
		var topy: float = hh * (1.0 + keel * (1.0 - s))
		var ring: Array = []
		if lower:
			ring = [
				cc + Vector3(0.0, hh * 0.90, 0.0),
				cc + Vector3(hw, hh * 0.34, 0.0),
				cc + Vector3(hw * 0.74, -hh * 0.92, 0.0),
				cc + Vector3(0.0, -hh * 1.06, 0.0),
				cc + Vector3(-hw * 0.74, -hh * 0.92, 0.0),
				cc + Vector3(-hw, hh * 0.34, 0.0),
			]
		else:
			ring = [
				cc + Vector3(0.0, topy, 0.0),
				cc + Vector3(hw * 0.90, hh * 0.30, 0.0),
				cc + Vector3(hw * 0.58, -hh * 0.86, 0.0),
				cc + Vector3(0.0, -hh, 0.0),
				cc + Vector3(-hw * 0.58, -hh * 0.86, 0.0),
				cc + Vector3(-hw * 0.90, hh * 0.30, 0.0),
			]
		rings.append(ring)
		cents.append(cc)
	var tip := Vector3(0.0, -hook * 1.10, -ln)

	# flat base cap
	st.set_smooth_group(-1)
	var base_ring: Array = rings[0]
	var base_c: Vector3 = cents[0]
	var in_base: Vector3 = base_c + Vector3(0.0, 0.0, -ln * 0.25)
	for j in range(6):
		var ba: Vector3 = base_ring[j]
		var bb: Vector3 = base_ring[(j + 1) % 6]
		_tri_out(st, base_c, ba, bb, in_base)

	# smooth shaft
	st.set_smooth_group(0)
	for k in range(n - 1):
		var ra: Array = rings[k]
		var rb: Array = rings[k + 1]
		var ins: Vector3 = (cents[k] + cents[k + 1]) * 0.5
		for j in range(6):
			var j2: int = (j + 1) % 6
			var pa: Vector3 = ra[j]
			var pb: Vector3 = ra[j2]
			var pc: Vector3 = rb[j2]
			var pd: Vector3 = rb[j]
			_quad_out(st, pa, pb, pc, pd, ins)

	# tip fan
	var last_ring: Array = rings[n - 1]
	var in_tip: Vector3 = cents[n - 1]
	for j in range(6):
		var ta: Vector3 = last_ring[j]
		var tb: Vector3 = last_ring[(j + 1) % 6]
		_tri_out(st, ta, tb, tip, in_tip)

	st.generate_normals()
	return st.commit()


static func _strip_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, ca: Color, cb: Color) -> void:
	st.set_color(ca)
	st.add_vertex(a)
	st.set_color(ca)
	st.add_vertex(b)
	st.set_color(cb)
	st.add_vertex(c)
	st.set_color(ca)
	st.add_vertex(a)
	st.set_color(cb)
	st.add_vertex(c)
	st.set_color(cb)
	st.add_vertex(d)


static func _plume_mesh(ln: float, wid: float, curl: float, twist: float, c0: Color, c1: Color) -> ArrayMesh:
	# one feather blade along +Y, folded along a raised rachis, curling toward +Z
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 11
	var lft: Array = []
	var ctr: Array = []
	var rgt: Array = []
	var cls: Array = []
	for k in range(n + 1):
		var s: float = float(k) / float(n)
		# quill-width at the root, a point at the tip, serrated barbs between
		var edge: float = maxf(sin(PI * pow(s, 0.55)), 0.16 * (1.0 - s))
		var serr: float = 1.0 - 0.16 * (1.0 - cos(s * PI * 6.0))
		var hw: float = wid * 0.5 * edge * serr
		var tw: float = twist * s
		var ax := Vector3(cos(tw), 0.0, sin(tw))
		var nx := Vector3(-sin(tw), 0.0, cos(tw))
		var base := Vector3(0.0, ln * s, curl * s * s)
		var lift: float = wid * 0.16 * edge
		ctr.append(base + nx * lift)
		lft.append(base - ax * hw)
		rgt.append(base + ax * hw)
		cls.append(c0.lerp(c1, pow(s, 0.75)))
	for k in range(n):
		var ca: Color = cls[k]
		var cb: Color = cls[k + 1]
		var l0: Vector3 = lft[k]
		var l1: Vector3 = lft[k + 1]
		var c_0: Vector3 = ctr[k]
		var c_1: Vector3 = ctr[k + 1]
		var r0: Vector3 = rgt[k]
		var r1: Vector3 = rgt[k + 1]
		_strip_quad(st, l0, c_0, c_1, l1, ca, cb)
		_strip_quad(st, c_0, r0, r1, c_1, ca, cb)
	st.generate_normals()
	return st.commit()


# ---------------------------------------------------------------------------
# the eye-spot skin, painted in code

static func _eyespot_texture(rng: RandomNumberGenerator) -> ImageTexture:
	var cols: int = 4
	var rows: int = 5
	var img: Image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	img.fill(Color(0.22, 0.19, 0.17))
	var w: float = float(TEX_SIZE) / float(cols)
	var h: float = float(TEX_SIZE) / float(rows)
	var rx: float = w * 0.62
	var ry: float = h * 0.70
	var phase: float = rng.randf_range(0.0, 1.0)
	# painted back to front: the upper rows land last and shingle over the lower
	for ri in range(rows - 1, -1, -1):
		for ci in range(cols):
			var off: float = 0.5 * w if (ri % 2) == 1 else 0.0
			var cx: float = (float(ci) + 0.5) * w + off + phase * w
			var cy: float = (float(ri) + 0.5) * h
			var tint: float = rng.randf_range(0.90, 1.02)
			var warm: float = rng.randf_range(-0.05, 0.05)
			_paint_eyespot(img, cx, cy, rx, ry, tint, warm)
	return ImageTexture.create_from_image(img)


static func _paint_eyespot(img: Image, cx: float, cy: float, rx: float, ry: float, tint: float, warm: float) -> void:
	var x0: int = int(floor(cx - rx)) - 1
	var x1: int = int(ceil(cx + rx)) + 1
	var y0: int = int(floor(cy - ry)) - 1
	var y1: int = int(ceil(cy + ry)) + 1
	for yy in range(y0, y1 + 1):
		for xx in range(x0, x1 + 1):
			var dx: float = (float(xx) + 0.5 - cx) / rx
			var dy: float = (float(yy) + 0.5 - cy) / ry
			var dd: float = sqrt(dx * dx + dy * dy)
			if dd > 1.0:
				continue
			var v: float = 0.0
			if dd > 0.90:
				v = 0.24
			elif dd > 0.80:
				v = lerpf(0.24, 0.62, (0.90 - dd) / 0.10)
			elif dd > 0.46:
				v = 0.70 + 0.18 * ((0.80 - dd) / 0.34) - 0.09 * dy
			elif dd > 0.36:
				v = 0.58 + 0.12 * ((0.46 - dd) / 0.10)
			else:
				v = 0.94 + 0.06 * (1.0 - dd / 0.36)
			v += 0.018 * float((xx * 5 + yy * 11) % 3) - 0.018
			v = clampf(v * tint, 0.0, 1.0)
			var cr: float = clampf(v * (1.0 + warm), 0.0, 1.0)
			var cg: float = clampf(v * (1.0 - absf(warm) * 0.3), 0.0, 1.0)
			var cb: float = clampf(v * (1.0 - warm), 0.0, 1.0)
			img.set_pixel(posmod(xx, TEX_SIZE), posmod(yy, TEX_SIZE), Color(cr, cg, cb))


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
