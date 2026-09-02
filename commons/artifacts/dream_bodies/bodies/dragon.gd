extends RefCounted

## dream_bodies / dragon — one pastel ceramic garden dragon, rearing.
##
## Reference: scratchpad/refs/dragon.png (2048x536 panorama) — a row of glazed
## ceramic dragons in lavender, teal-to-blue, cream-pink and periwinkle, each
## standing on its hind legs with the forelegs held up in front of the chest,
## the neck rising in an S to an open toothed jaw, ridged bat wings folded up
## and back, hexagonal scale skins with a lighter belly, and a tail that rests
## on the ground and curls up at the tip.
##
## Reproduced, and how:
##   1. The rearing S-spine — 16..22 SphereMesh segments placed along a curve
##      integrated from a keyed lean angle (hips lean forward, chest straightens,
##      neck leans back, head tips forward); radii shrink hips -> neck.
##   2. Hexagonal scales — a 128x128 ImageTexture drawn in code (pointy-top hex
##      lattice, per-cell glaze mottle, groove between scales), tinted per
##      segment so the body carries the reference's top-to-bottom colour drift.
##   3. The pale belly — a second chain of smaller spheres hung on the front of
##      the spine in the belly colour, coarser scale texture.
##   4. Dorsal ridge — a cone (CylinderMesh, top_radius 0) on the back of every
##      body and tail segment, cream glaze.
##   5. Head with open jaw — SphereMesh skull, two tapered-box jaws built with
##      SurfaceTool (flat smooth group), the lower one hinged open 22..34 deg,
##      cone teeth along both jaw edges, glazed dark eyes, two-segment horns,
##      PrismMesh ear frills.
##   6. Bat wings — one arm bone + 5..7 tapering rib cylinders with knob tips,
##      and a SurfaceTool membrane fan (6 rings x 4 sub-steps per sector,
##      scalloped trailing edge, corrugated 4 mm ripple, vertex-colour pastel
##      gradient, alpha 0.7, double sided).
##   7. Hind legs and raised forelegs — CapsuleMesh thigh/shin/foot and
##      upper-arm/forearm with a sphere hand, cone claws; one arm raised higher
##      and one foot forward, chosen by seed.
##   8. Curled tail — 14..18 spheres continuing the chain backward, resting on
##      the plinth, curling up and to one side at the tip.
##
## Given up: the raised wave ridges moulded ON the wing membranes (only a colour
## band + shallow corrugation stands in for them), the neighbouring dragons
## touching each other, the garden, and the shoulder frill / mane spikes.

const TEX_SIZE: int = 128
const PLINTH_TOP: float = 0.06

# scheme: [hips colour, neck colour, belly, accent, wing inner, wing mid, wing outer, rib]
const SCHEMES: Array = [
	["#A98BD8", "#C4A8E6", "#EEDDF2", "#F4EBDF", "#B9A3E8", "#DCC1EA", "#F1C9DE", "#EAC7E0"],
	["#7FA5DC", "#74CFC2", "#E2F1DB", "#F4EBDF", "#9AD9C9", "#CDEBD1", "#C6BDE8", "#E4F0DC"],
	["#EBD9CF", "#F3E6DE", "#FAF2EC", "#E8C9D5", "#F2CCDC", "#E5C6E6", "#C9C4EA", "#F6E3EA"],
	["#A78FD8", "#86A8E6", "#DAD8F1", "#F4EBDF", "#A9C3EE", "#C4BBEC", "#E6C2E2", "#DDE4F4"],
]


static func describe() -> String:
	return "A glazed pastel ceramic garden dragon rearing on its hind legs, forelegs raised, jaw open, hexagon-scaled with translucent ridged bat wings and a curled tail."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var scheme: Array = SCHEMES[rng.randi_range(0, SCHEMES.size() - 1)]
	var col_hip: Color = _c(scheme, 0)
	var col_neck: Color = _c(scheme, 1)
	var col_belly: Color = _c(scheme, 2)
	var col_accent: Color = _c(scheme, 3)
	var wing_cols: Array = [_c(scheme, 4), _c(scheme, 5), _c(scheme, 6)]
	var col_rib: Color = _c(scheme, 7)

	var scale_tex: ImageTexture = _scale_texture(rng, 10, 12, 0.86)
	var belly_tex: ImageTexture = _scale_texture(rng, 6, 8, 0.90)
	var mat_accent: StandardMaterial3D = _glaze(col_accent, 0.32)
	var mat_belly: StandardMaterial3D = _glaze(col_belly, 0.30)
	mat_belly.albedo_texture = belly_tex
	mat_belly.uv1_scale = Vector3(1.0, 1.0, 1.0)
	var mat_eye: StandardMaterial3D = _glaze(Color("#3A2450"), 0.08)
	mat_eye.emission_enabled = true
	mat_eye.emission = Color("#7A4CC0")
	mat_eye.emission_energy_multiplier = 0.35
	var mat_rib: StandardMaterial3D = _glaze(col_rib, 0.30)
	var mat_plinth := StandardMaterial3D.new()
	mat_plinth.albedo_color = Color("#C9CFC6")
	mat_plinth.roughness = 0.85

	# --- individual parameters ---------------------------------------------
	var n_spine: int = rng.randi_range(16, 22)
	var body_k: float = rng.randf_range(0.92, 1.08)
	var lean_x: float = rng.randf_range(-0.12, 0.12)
	var y_hip: float = 0.47
	var y_head_base: float = rng.randf_range(1.38, 1.44)
	var bend_a: float = rng.randf_range(0.55, 0.80)
	var bend_b: float = rng.randf_range(-0.35, -0.15)
	var bend_c: float = rng.randf_range(0.35, 0.60)
	var head_yaw: float = deg_to_rad(rng.randf_range(-14.0, 14.0))
	var jaw_open: float = deg_to_rad(rng.randf_range(22.0, 34.0))
	var raised_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var forward_foot: float = 1.0 if rng.randf() < 0.5 else -1.0
	var tail_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var tail_curl: float = rng.randf_range(2.9, 3.5)
	var n_tail: int = rng.randi_range(14, 18)
	var n_ribs: int = rng.randi_range(5, 7)
	var spread_l: float = deg_to_rad(rng.randf_range(95.0, 120.0))
	var spread_r: float = deg_to_rad(rng.randf_range(95.0, 120.0))
	var wing_lift: float = rng.randf_range(0.20, 0.28)

	# --- spine: dry run for direction, then scaled to land the head ----------
	var dirs: Array = []
	var rise: float = 0.0
	for i in range(1, n_spine):
		var t: float = float(i) / float(n_spine - 1)
		var a: float = _spine_angle(t, bend_a, bend_b, bend_c)
		var d: Vector3 = Vector3(lean_x * 0.35 * sin(PI * t), cos(a), -sin(a)).normalized()
		dirs.append(d)
		rise += d.y
	var step: float = (y_head_base - y_hip) / maxf(rise, 0.1)

	var pts: Array = []
	var radii: Array = []
	var p := Vector3(0.0, y_hip, 0.08)
	pts.append(p)
	radii.append(_r_profile(0.0) * body_k)
	for i in range(1, n_spine):
		var t: float = float(i) / float(n_spine - 1)
		var d: Vector3 = dirs[i - 1]
		p = p + d * step
		pts.append(p)
		radii.append(_r_profile(t) * body_k)

	# body segments, belly plates, dorsal ridge
	for i in range(n_spine):
		var t: float = float(i) / float(n_spine - 1)
		var q: Vector3 = pts[i]
		var r: float = radii[i]
		var tang: Vector3 = _tangent(pts, i)
		var front := Vector3(0.0, tang.z, -tang.y).normalized()
		var mat_body: StandardMaterial3D = _glaze(col_hip.lerp(col_neck, t), 0.24)
		mat_body.albedo_texture = scale_tex
		mat_body.uv1_scale = Vector3(2.0, 1.0, 1.0)
		var sph := SphereMesh.new()
		sph.radius = r
		sph.height = r * 2.0
		var mi: MeshInstance3D = _add(root, sph, mat_body)
		mi.transform = Transform3D(_basis_y_to(tang), q)
		if t <= 0.78:
			var bel := SphereMesh.new()
			bel.radius = r * 0.74
			bel.height = r * 1.48
			var bm: MeshInstance3D = _add(root, bel, mat_belly)
			bm.transform = Transform3D(_basis_y_to(tang), q + front * (r * 0.52))
		var spike_h: float = r * (0.55 if t < 0.5 else 0.7)
		_cone(root, q - front * (r * 0.92), -front, spike_h, r * 0.16, mat_accent)

	var p_hip: Vector3 = pts[0]
	var r_hip: float = radii[0]
	var p_head_base: Vector3 = pts[n_spine - 1]
	var r_neck_end: float = radii[n_spine - 1]

	# --- tail ---------------------------------------------------------------
	var tail_p: Vector3 = p_hip
	var tail_r: float = r_hip * 0.8
	var tail_len: float = 0.84 * body_k
	var tail_last_dir := Vector3(0.0, 0.0, 1.0)
	for i in range(1, n_tail + 1):
		var s: float = float(i) / float(n_tail)
		var e: float = -0.7 + tail_curl * pow(s, 1.3)
		var sway: float = tail_side * 0.22 * sin(PI * s) * cos(0.5 * PI * s)
		var d: Vector3 = Vector3(sway, sin(e), cos(e)).normalized()
		tail_last_dir = d
		tail_p = tail_p + d * (tail_len / float(n_tail))
		tail_r = lerpf(r_hip * 0.8, 0.028, pow(s, 0.85))
		var ty: float = maxf(tail_p.y, PLINTH_TOP + tail_r)
		tail_p = Vector3(tail_p.x, ty, tail_p.z)
		var mat_tail: StandardMaterial3D = _glaze(col_hip.darkened(0.08 * s), 0.24)
		mat_tail.albedo_texture = scale_tex
		mat_tail.uv1_scale = Vector3(2.0, 1.0, 1.0)
		var sph := SphereMesh.new()
		sph.radius = tail_r
		sph.height = tail_r * 2.0
		var mi: MeshInstance3D = _add(root, sph, mat_tail)
		mi.transform = Transform3D(_basis_y_to(d), tail_p)
		if i % 2 == 0 and s < 0.9:
			var up_ish := Vector3(0.0, -d.z, d.y).normalized()
			if up_ish.y < 0.0:
				up_ish = -up_ish
			_cone(root, tail_p + up_ish * (tail_r * 0.9), up_ish, tail_r * 0.7, tail_r * 0.18, mat_accent)
	_cone(root, tail_p + tail_last_dir * (tail_r * 0.6), tail_last_dir, 0.075, 0.03, mat_accent)

	# --- hind legs ----------------------------------------------------------
	var mat_leg: StandardMaterial3D = _glaze(col_hip.lerp(col_neck, 0.1), 0.26)
	mat_leg.albedo_texture = scale_tex
	mat_leg.uv1_scale = Vector3(1.0, 1.0, 1.0)
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var fwd: float = 0.045 if sd == forward_foot else -0.02
		var hip := p_hip + Vector3(sd * 0.13 * body_k, -0.05, 0.02)
		var knee := hip + Vector3(sd * 0.05, -0.14, -0.13 + fwd * 0.4)
		var ankle := knee + Vector3(sd * 0.02, -0.17, 0.10 + fwd * 0.3)
		ankle = Vector3(ankle.x, PLINTH_TOP + 0.05, ankle.z)
		var toe := ankle + Vector3(0.0, -0.005, -0.15)
		_limb(root, hip, knee, 0.078 * body_k, mat_leg)
		_limb(root, knee, ankle, 0.056 * body_k, mat_leg)
		_limb(root, ankle, toe, 0.045, mat_leg)
		for c in range(3):
			var ang: float = (float(c) - 1.0) * 0.5
			var cd: Vector3 = Vector3(sin(ang) * 0.9, -0.35, -cos(ang)).normalized()
			_cone(root, toe + cd * 0.035 + Vector3(0.0, -0.01, 0.0), cd, 0.055, 0.012, mat_accent)

	# --- forelegs, raised ---------------------------------------------------
	var i_chest: int = int(floor(float(n_spine - 1) * 0.42))
	var p_chest: Vector3 = pts[i_chest]
	var r_chest: float = radii[i_chest]
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var lift: float = 0.07 if sd == raised_side else 0.0
		var shoulder := p_chest + Vector3(sd * (r_chest * 0.85), 0.02, -r_chest * 0.25)
		var elbow := shoulder + Vector3(sd * 0.05, -0.16 + lift * 0.3, -0.07)
		var hand := elbow + Vector3(-sd * 0.03, 0.05 + lift, -0.16)
		_limb(root, shoulder, elbow, 0.052 * body_k, mat_leg)
		_limb(root, elbow, hand, 0.040 * body_k, mat_leg)
		var hs := SphereMesh.new()
		hs.radius = 0.046
		hs.height = 0.092
		var hm: MeshInstance3D = _add(root, hs, mat_leg)
		hm.transform = Transform3D(Basis(), hand)
		for c in range(3):
			var ang: float = (float(c) - 1.0) * 0.55
			var cd: Vector3 = Vector3(sin(ang) * 0.8 - sd * 0.15, -0.75, -cos(ang) * 0.7).normalized()
			_cone(root, hand + cd * 0.045, cd, 0.05, 0.011, mat_accent)

	# --- head ---------------------------------------------------------------
	var f_head: Vector3 = Vector3(sin(head_yaw), -0.24, -cos(head_yaw)).normalized()
	var u_head: Vector3 = (Vector3.UP - f_head * Vector3.UP.dot(f_head)).normalized()
	var r_head: Vector3 = f_head.cross(u_head).normalized()
	var hb := Basis(r_head, u_head, -f_head)
	var rh: float = 0.105 * body_k
	var h_org: Vector3 = p_head_base + f_head * (rh * 0.35) + u_head * (rh * 0.1)
	var mat_head: StandardMaterial3D = _glaze(col_neck, 0.24)
	mat_head.albedo_texture = scale_tex
	mat_head.uv1_scale = Vector3(1.5, 1.0, 1.0)
	var skull := SphereMesh.new()
	skull.radius = rh
	skull.height = rh * 1.9
	var sm: MeshInstance3D = _add(root, skull, mat_head)
	sm.transform = Transform3D(hb, h_org)
	# neck-to-skull filler so the chain does not show a gap under the jaw
	var filler := SphereMesh.new()
	filler.radius = r_neck_end * 0.9
	filler.height = r_neck_end * 1.8
	var fm: MeshInstance3D = _add(root, filler, mat_head)
	fm.transform = Transform3D(hb, p_head_base + f_head * (rh * 0.05) - u_head * (rh * 0.35))

	var mat_jaw: StandardMaterial3D = _glaze(col_neck.lerp(col_belly, 0.35), 0.28)
	var jaw_l: float = 0.24 * body_k
	var upper: ArrayMesh = _tapered_box(0.16 * body_k, 0.10 * body_k, 0.09 * body_k, 0.045 * body_k, jaw_l, -0.02)
	var um: MeshInstance3D = _add(root, upper, mat_jaw)
	um.transform = Transform3D(hb, h_org + hb * Vector3(0.0, -0.025, 0.02))
	var jb: Basis = hb * Basis(Vector3.RIGHT, -jaw_open)
	var lower: ArrayMesh = _tapered_box(0.14 * body_k, 0.05 * body_k, 0.075 * body_k, 0.03 * body_k, jaw_l * 0.92, 0.0)
	var lm: MeshInstance3D = _add(root, lower, mat_jaw)
	var hinge: Vector3 = h_org + hb * Vector3(0.0, -0.025 - 0.05 * body_k, 0.02)
	lm.transform = Transform3D(jb, hinge)
	# teeth: upper jaw hangs them down, lower jaw points them up
	var n_teeth: int = 5
	for k in range(n_teeth):
		var fz: float = lerpf(0.07, jaw_l - 0.02, float(k) / float(n_teeth - 1))
		var wq: float = lerpf(0.16 * body_k, 0.09 * body_k, fz / jaw_l) * 0.44
		var yq: float = -0.025 - lerpf(0.05 * body_k, 0.0225 * body_k, fz / jaw_l) - 0.02 * (fz / jaw_l)
		for sgn in [-1.0, 1.0]:
			var sgf: float = sgn
			var tp: Vector3 = h_org + hb * Vector3(sgf * wq, yq + 0.01, 0.02 - fz)
			_cone(root, tp, -u_head, 0.032, 0.008, mat_accent)
		if k < n_teeth - 1:
			var fz2: float = fz + 0.02
			var wq2: float = lerpf(0.14 * body_k, 0.075 * body_k, fz2 / jaw_l) * 0.42
			var yq2: float = lerpf(0.025 * body_k, 0.015 * body_k, fz2 / jaw_l)
			for sgn in [-1.0, 1.0]:
				var sgf: float = sgn
				var tp2: Vector3 = hinge + jb * Vector3(sgf * wq2, yq2 - 0.008, -fz2)
				_cone(root, tp2, jb * Vector3.UP, 0.028, 0.007, mat_accent)
	# eyes
	for sgn in [-1.0, 1.0]:
		var sgf: float = sgn
		var eye := SphereMesh.new()
		eye.radius = 0.021
		eye.height = 0.042
		var em: MeshInstance3D = _add(root, eye, mat_eye)
		em.transform = Transform3D(Basis(), h_org + hb * Vector3(sgf * rh * 0.72, rh * 0.30, -rh * 0.55))
	# horns, two segments each, bending back
	var horn_back: float = rng.randf_range(0.35, 0.6)
	for sgn in [-1.0, 1.0]:
		var sgf: float = sgn
		var base_p: Vector3 = h_org + hb * Vector3(sgf * rh * 0.45, rh * 0.75, rh * 0.15)
		var d1: Vector3 = (hb * Vector3(sgf * 0.25, 0.85, horn_back)).normalized()
		var mid_p: Vector3 = base_p + d1 * 0.09
		var d2: Vector3 = (hb * Vector3(sgf * 0.3, 0.55, horn_back + 0.35)).normalized()
		var tip_p: Vector3 = mid_p + d2 * 0.08
		_tapered_cyl(root, base_p, mid_p, 0.022, 0.013, mat_accent)
		_tapered_cyl(root, mid_p, tip_p, 0.013, 0.0, mat_accent)
	# ear frills
	for sgn in [-1.0, 1.0]:
		var sgf: float = sgn
		var frill := PrismMesh.new()
		frill.size = Vector3(0.03, 0.10, 0.06)
		var frm: MeshInstance3D = _add(root, frill, mat_accent)
		var fb: Basis = hb * Basis(Vector3.FORWARD, sgf * 0.9) * Basis(Vector3.RIGHT, 0.5)
		frm.transform = Transform3D(fb, h_org + hb * Vector3(sgf * rh * 0.95, rh * 0.25, rh * 0.25))

	# --- wings --------------------------------------------------------------
	var i_sh: int = int(floor(float(n_spine - 1) * 0.58))
	var p_sh: Vector3 = pts[i_sh]
	var r_sh: float = radii[i_sh]
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var spread: float = spread_l if side_i == 0 else spread_r
		var s_pt := p_sh + Vector3(sd * (r_sh * 0.7), r_sh * 0.3, r_sh * 0.4)
		var w_pt := s_pt + Vector3(sd * 0.16, wing_lift, 0.10)
		_tapered_cyl(root, s_pt, w_pt, 0.030, 0.024, mat_rib)
		var e1 := Vector3(sd * 0.62, 0.68, 0.38).normalized()
		var e2 := Vector3(sd * 0.08, -0.30, 0.95)
		e2 = (e2 - e1 * e1.dot(e2)).normalized()
		var nrm: Vector3 = e1.cross(e2).normalized()
		var rib_dirs: Array = []
		var rib_lens: Array = []
		for k in range(n_ribs):
			var fr: float = float(k) / float(n_ribs - 1)
			var th: float = fr * spread
			var rd: Vector3 = (e1 * cos(th) + e2 * sin(th)).normalized()
			var ln: float = lerpf(0.46, 0.27, pow(fr, 1.4))
			if k == 0:
				ln = 0.40
			ln *= body_k
			rib_dirs.append(rd)
			rib_lens.append(ln)
			var tip: Vector3 = w_pt + rd * ln
			_tapered_cyl(root, w_pt, tip, 0.012, 0.006, mat_rib)
			var knob := SphereMesh.new()
			knob.radius = 0.014
			knob.height = 0.028
			var km: MeshInstance3D = _add(root, knob, mat_accent)
			km.transform = Transform3D(Basis(), tip)
		# closing pseudo-rib back to the shoulder
		rib_dirs.append((s_pt - w_pt).normalized())
		rib_lens.append((s_pt - w_pt).length())
		var membrane: ArrayMesh = _membrane(w_pt, rib_dirs, rib_lens, nrm, wing_cols, n_ribs)
		var mat_wing := StandardMaterial3D.new()
		mat_wing.albedo_color = Color(1.0, 1.0, 1.0, 0.7)
		mat_wing.vertex_color_use_as_albedo = true
		mat_wing.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat_wing.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat_wing.roughness = 0.35
		mat_wing.clearcoat_enabled = true
		mat_wing.clearcoat = 0.5
		var wm: MeshInstance3D = _add(root, membrane, mat_wing)
		wm.transform = Transform3D(Basis(), Vector3.ZERO)

	# --- fit, centre, plinth ------------------------------------------------
	var box: AABB = _union_aabb(root)
	var kx: float = 1.16 / maxf(box.size.x, 0.01)
	var kz: float = 1.16 / maxf(box.size.z, 0.01)
	var ky: float = (1.70 - PLINTH_TOP) / maxf(box.size.y, 0.01)
	var kfit: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kfit < 1.0:
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cm: MeshInstance3D = ch
			var tf: Transform3D = cm.transform
			var pivot := Vector3(0.0, PLINTH_TOP, 0.0)
			cm.transform = Transform3D(tf.basis.scaled(Vector3(kfit, kfit, kfit)), pivot + (tf.origin - pivot) * kfit)
		box = _union_aabb(root)
	var centre: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-centre.x, 0.0, -centre.z)
	if box.position.y < 0.0:
		shift.y = -box.position.y
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + shift)
	var plinth := BoxMesh.new()
	plinth.size = Vector3(minf(1.2, box.size.x + 0.08), PLINTH_TOP, minf(1.2, box.size.z + 0.08))
	var pm: MeshInstance3D = _add(root, plinth, mat_plinth)
	pm.transform = Transform3D(Basis(), Vector3(0.0, PLINTH_TOP * 0.5, 0.0))


# ---------------------------------------------------------------------------
# shape helpers

static func _spine_angle(t: float, a0: float, a1: float, a2: float) -> float:
	# lean from vertical toward the front (-Z); keyed hips -> chest -> neck -> head
	var keys: Array = [a0, a0 * 0.35, a1, a2]
	var f: float = t * 3.0
	var i: int = int(floor(f))
	if i >= 3:
		return a2
	var u: float = f - float(i)
	var s: float = u * u * (3.0 - 2.0 * u)
	var va: float = keys[i]
	var vb: float = keys[i + 1]
	return lerpf(va, vb, s)


static func _r_profile(t: float) -> float:
	var keys: Array = [0.175, 0.19, 0.20, 0.155, 0.115, 0.095, 0.088]
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


static func _c(scheme: Array, i: int) -> Color:
	var code: String = scheme[i]
	return Color(code)


static func _glaze(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	m.clearcoat_enabled = true
	m.clearcoat = 0.65
	m.clearcoat_roughness = 0.2
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
	cap.height = ln + r * 1.6
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
	cyl.radial_segments = 12
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _cone(root: Node3D, base: Vector3, dir: Vector3, h: float, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = dir.normalized()
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = r
	cyl.top_radius = 0.0
	cyl.height = h
	cyl.radial_segments = 10
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(d), base + d * (h * 0.5))
	return mi


static func _quad_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, inside: Vector3) -> void:
	# emit a quad whose Godot front face (clockwise) points away from `inside`
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


static func _tapered_box(w0: float, h0: float, w1: float, h1: float, ln: float, drop: float) -> ArrayMesh:
	# back face at z = 0 (w0 x h0), front face at z = -ln (w1 x h1), front centre lowered by `drop`
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var hw0: float = w0 * 0.5
	var hh0: float = h0 * 0.5
	var hw1: float = w1 * 0.5
	var hh1: float = h1 * 0.5
	var b0 := Vector3(-hw0, hh0, 0.0)
	var b1 := Vector3(hw0, hh0, 0.0)
	var b2 := Vector3(hw0, -hh0, 0.0)
	var b3 := Vector3(-hw0, -hh0, 0.0)
	var f0 := Vector3(-hw1, hh1 + drop, -ln)
	var f1 := Vector3(hw1, hh1 + drop, -ln)
	var f2 := Vector3(hw1, -hh1 + drop, -ln)
	var f3 := Vector3(-hw1, -hh1 + drop, -ln)
	var inside := Vector3(0.0, drop * 0.5, -ln * 0.5)
	_quad_out(st, b0, b1, b2, b3, inside)
	_quad_out(st, f0, f1, f2, f3, inside)
	_quad_out(st, b0, b1, f1, f0, inside)
	_quad_out(st, b3, b2, f2, f3, inside)
	_quad_out(st, b1, b2, f2, f1, inside)
	_quad_out(st, b0, b3, f3, f0, inside)
	st.generate_normals()
	return st.commit()


static func _membrane(w: Vector3, rib_dirs: Array, rib_lens: Array, nrm: Vector3, cols: Array, n_real: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: int = 6
	var subs: int = 4
	var waves: float = 4.0
	var n_sect: int = rib_dirs.size() - 1
	for i in range(n_sect):
		var da: Vector3 = rib_dirs[i]
		var db: Vector3 = rib_dirs[i + 1]
		var la: float = rib_lens[i]
		var lb: float = rib_lens[i + 1]
		var scallop: float = 0.16 if i < n_real - 1 else 0.0
		var grid: Array = []
		for k in range(rings + 1):
			var row: Array = []
			var f: float = float(k) / float(rings)
			for j in range(subs + 1):
				var fr: float = float(j) / float(subs)
				var d: Vector3 = (da * (1.0 - fr) + db * fr).normalized()
				var ln: float = lerpf(la, lb, fr) * (1.0 - scallop * f * sin(PI * fr))
				var ripple: float = 0.004 * sin(f * PI * waves) * (0.3 + 0.7 * f)
				row.append(w + d * (ln * f) + nrm * ripple)
			grid.append(row)
		for k in range(rings):
			var f0: float = float(k) / float(rings)
			var f1: float = float(k + 1) / float(rings)
			var c0: Color = _wing_col(cols, f0, waves)
			var c1: Color = _wing_col(cols, f1, waves)
			var row0: Array = grid[k]
			var row1: Array = grid[k + 1]
			for j in range(subs):
				var p00: Vector3 = row0[j]
				var p01: Vector3 = row0[j + 1]
				var p10: Vector3 = row1[j]
				var p11: Vector3 = row1[j + 1]
				if k == 0:
					st.set_color(c0)
					st.add_vertex(p00)
					st.set_color(c1)
					st.add_vertex(p10)
					st.set_color(c1)
					st.add_vertex(p11)
				else:
					st.set_color(c0)
					st.add_vertex(p00)
					st.set_color(c1)
					st.add_vertex(p10)
					st.set_color(c1)
					st.add_vertex(p11)
					st.set_color(c0)
					st.add_vertex(p00)
					st.set_color(c1)
					st.add_vertex(p11)
					st.set_color(c0)
					st.add_vertex(p01)
	st.generate_normals()
	return st.commit()


static func _wing_col(cols: Array, f: float, waves: float) -> Color:
	var ca: Color = cols[0]
	var cb: Color = cols[1]
	var cc: Color = cols[2]
	var base: Color = ca.lerp(cb, clampf(f * 2.0, 0.0, 1.0)) if f < 0.5 else cb.lerp(cc, clampf((f - 0.5) * 2.0, 0.0, 1.0))
	var band: float = 1.0 + 0.07 * sin(f * PI * waves)
	return Color(clampf(base.r * band, 0.0, 1.0), clampf(base.g * band, 0.0, 1.0), clampf(base.b * band, 0.0, 1.0), 1.0)


static func _scale_texture(rng: RandomNumberGenerator, cols: int, rows: int, fill: float) -> ImageTexture:
	# pointy-top hexagon lattice, seamless; near-white so albedo_color tints it
	var img: Image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	var w: float = float(TEX_SIZE) / float(cols)
	var h: float = float(TEX_SIZE) / float(rows)
	var tints: Array = []
	for c in range(cols * rows):
		tints.append(Vector3(rng.randf_range(0.90, 1.0), rng.randf_range(0.90, 1.0), rng.randf_range(0.90, 1.0)))
	var groove: float = 0.60
	for y in range(TEX_SIZE):
		for x in range(TEX_SIZE):
			var px: float = float(x) + 0.5
			var py: float = float(y) + 0.5
			var row_c: int = int(floor(py / h))
			var best_d: float = 1.0e9
			var best_dx: float = 0.0
			var best_dy: float = 0.0
			var best_i: int = 0
			for rr in range(row_c - 1, row_c + 2):
				var rw: int = posmod(rr, rows)
				var off: float = 0.5 * w if (rw % 2) == 1 else 0.0
				var cy: float = (float(rr) + 0.5) * h
				var col_c: int = int(floor((px - off) / w))
				for cc in range(col_c - 1, col_c + 2):
					var cx: float = (float(cc) + 0.5) * w + off
					var dx: float = px - cx
					var dy: float = py - cy
					var dd: float = dx * dx + dy * dy
					if dd < best_d:
						best_d = dd
						best_dx = dx
						best_dy = dy
						best_i = rw * cols + posmod(cc, cols)
			var ndy: float = best_dy * (0.866 * w / h)
			var hd: float = maxf(absf(best_dx), maxf(absf(best_dx * 0.5 + ndy * 0.866), absf(best_dx * 0.5 - ndy * 0.866))) / (w * 0.5)
			var edge: float = clampf((fill + 0.05 - hd) / 0.09, 0.0, 1.0)
			var shade: float = 0.80 + 0.14 * (1.0 - hd) - 0.10 * (ndy / (w * 0.5))
			shade = clampf(shade, 0.6, 1.0)
			var tint: Vector3 = tints[best_i]
			var r_v: float = lerpf(groove, tint.x * shade, edge)
			var g_v: float = lerpf(groove, tint.y * shade, edge)
			var b_v: float = lerpf(groove, tint.z * shade, edge)
			img.set_pixel(x, y, Color(r_v, g_v, b_v))
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
