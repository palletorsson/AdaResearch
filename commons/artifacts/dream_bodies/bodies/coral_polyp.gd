extends RefCounted

## dream_bodies / coral_polyp — one standing reef creature, pebbled and fronded.
##
## Reference: scratchpad/refs/sea_b.png (2048x536 panorama) — a row of upright
## reef bodies printed in matte white, pale grey and dove grey, every square
## millimetre of them covered in dense rounded polyp pebbles like a raspberry;
## tall teardrop torsos that hunch forward, some with a small crested reptile
## head, a beak and one dark eye; branching coral fronds sprouting from the
## backs and shoulders in violet, orchid, teal or yellow, forking again and
## again into soft tubes with rounded club tips; a violet coral crust creeping
## up the foot of the grey bodies; and, standing in the middle of the row, one
## body that is smooth instead and wears thick wavy horizontal stripes in teal
## and white.
##
## Reproduced, and how:
##   1. The hunched teardrop torso — 26..32 SphereMesh segments walked along a
##      direction integrated from a keyed lean angle (heel back, belly upright,
##      shoulders hunched forward) with a seeded sideways bow; each sphere is
##      squashed front-to-back so the body reads as the reference's flattened
##      slab, and the radius profile swells at the belly and pinches to a neck.
##   2. The polyp skin — a 192x192 ImageTexture painted in code: a staggered
##      jittered lattice of pebbles, each shaded as a lit dome with a dark
##      groove between, applied with WORLD triplanar so the pebble field runs
##      unbroken across the whole chain of spheres instead of restarting per
##      mesh. Rim knob SphereMeshes make the silhouette lumpy too.
##   3. Branching coral fronds — a recursive static helper: each branch is 2..3
##      CapsuleMesh sub-segments that bend along the way, then forks into 2 (3
##      at the trunk, by seed) thinner children rolled to a seeded angle, four
##      levels deep, ending in a rounded club SphereMesh. 2..4 fronds rise from
##      shoulders and back out of a swelling bulb, in a seeded accent pair.
##   4. The crested head — SphereMesh skull stretched fore-aft, a PrismMesh
##      beak (apex rotated to point forward) with a smaller PrismMesh lower
##      jaw, 4..6 PrismMesh crest fins swept back over the skull and down the
##      neck, and one dark bead eye per side.
##   5. Hunched forelimbs — CapsuleMesh upper arm and forearm tucked to the
##      chest, a sphere hand and three small bud fingers; one side lifted
##      higher than the other, by seed.
##   6. The foot pad — 9..12 SphereMesh lobes flattened with a scaled basis,
##      spreading onto the floor, longer toward the front where the body leans.
##   7. The coral crust at the base — the lowest torso segments are tinted
##      toward the frond accent, so the colony looks like it is climbing.
##   8. The smooth kind, one seed in four — same silhouette, no pebbles and no
##      knobs, wearing a code-painted wavy stripe texture in teal and white;
##      world triplanar keeps the bands level in y while the wave runs around.
##
## Given up: the black polyp-textured reef wall behind the row, the neighbours
## the creatures lean against, the true relief of the wavy stripes (they are
## painted, not moulded), the open inside of the beak, and the fine pores on
## the frond tubes.

const PEB_TEX: int = 192
const STR_TEX: int = 224
const MAX_MESHES: int = 244

# body: [top, middle, base] greys
const BODY_SCHEMES: Array = [
	["#F2F1EC", "#C9CBCA", "#A9AEB1"],
	["#EDEDEA", "#D2D3D0", "#9DA3A7"],
	["#F6F4EF", "#DAD9D4", "#B4B7B9"],
	["#E7E8E7", "#C2C5C6", "#969CA1"],
]

# fronds: [stem, tip]
const ACCENTS: Array = [
	["#7B3FC4", "#B98AE8"],
	["#B76FD4", "#EBC5F0"],
	["#1F8E9B", "#82D2D4"],
	["#DFA61E", "#F6DF93"],
]


static func describe() -> String:
	return "A standing reef creature whose whole grey body is packed with rounded coral polyps, branching violet fronds sprouting from its shoulders and a small crested head with a beak — or, one seed in four, the smooth kind wearing wavy teal and white stripes."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- kind and palette ---------------------------------------------------
	var striped: bool = (rng.randi_range(0, 3) == 0)
	var scheme: Array = BODY_SCHEMES[rng.randi_range(0, BODY_SCHEMES.size() - 1)]
	var accent: Array = ACCENTS[rng.randi_range(0, ACCENTS.size() - 1)]
	var col_high: Color = _hex(scheme, 0)
	var col_mid: Color = _hex(scheme, 1)
	var col_low: Color = _hex(scheme, 2)
	var col_stem: Color = _hex(accent, 0)
	var col_tip: Color = _hex(accent, 1)
	if striped:
		# the striped body in the reference is flanked by pale violet coral
		var soft: Array = ACCENTS[rng.randi_range(0, 1)]
		col_stem = _hex(soft, 0)
		col_tip = _hex(soft, 1)

	var col_band_a: Color = Color("#1B818F").lerp(Color("#2FA0A2"), rng.randf())
	var col_band_b: Color = Color("#F4F2EA")

	# --- skin texture -------------------------------------------------------
	var tex_body: ImageTexture
	var uv_k: float = 6.4
	if striped:
		tex_body = _stripe_texture(rng, col_band_a, col_band_b, 5, 3)
		uv_k = rng.randf_range(1.75, 2.05)
	else:
		tex_body = _pebble_texture(rng, 9, 10)
		uv_k = rng.randf_range(5.9, 7.0)
	var uv_off := Vector3(rng.randf(), rng.randf(), rng.randf())

	var mat_beak: StandardMaterial3D = _matte(col_high.lerp(Color("#EDE4D2"), 0.35), 0.62)
	var mat_eye: StandardMaterial3D = _matte(Color("#191317"), 0.14)
	var mat_crest: StandardMaterial3D = _matte(col_high.lerp(col_mid, 0.3), 0.68)
	if striped:
		mat_beak = _matte(col_band_b.lerp(Color("#E4DDCB"), 0.3), 0.62)
		mat_crest = _matte(col_band_b, 0.66)

	# --- individual parameters ----------------------------------------------
	var n_body: int = rng.randi_range(26, 32)
	var body_k: float = rng.randf_range(0.92, 1.06)
	var dep: float = rng.randf_range(0.70, 0.86)
	# the first torso sphere must not hang below the pad, or the settle pass
	# lifts the whole creature and leaves the foot hovering
	var y_base: float = _r_profile(0.0) * body_k * 0.95 + 0.012
	var y_top: float = rng.randf_range(1.31, 1.42)
	var lean_a: float = rng.randf_range(-0.20, -0.05)
	var lean_b: float = rng.randf_range(-0.05, 0.06)
	var lean_c: float = rng.randf_range(0.10, 0.24)
	var lean_d: float = rng.randf_range(0.28, 0.48)
	var sway: float = rng.randf_range(-0.17, 0.17)
	var raised_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var n_fronds: int = rng.randi_range(2, 4)
	var lvl: int = 4 if n_fronds <= 3 else 3
	# a three-way trunk fork only when there are few enough fronds to pay for it
	var max_child: int = 3 if n_fronds == 2 else 2
	var n_crest: int = rng.randi_range(4, 6)
	var n_lobes: int = rng.randi_range(9, 12)

	# --- torso: dry run for direction, then a step that lands the neck -------
	var dirs: Array = []
	var rise: float = 0.0
	for i in range(1, n_body):
		var t: float = float(i) / float(n_body - 1)
		var a: float = _lean_angle(t, lean_a, lean_b, lean_c, lean_d)
		var d := Vector3(sway * sin(PI * t) * 0.62, cos(a), -sin(a))
		d = d.normalized()
		dirs.append(d)
		rise += d.y
	var step: float = (y_top - y_base) / maxf(rise, 0.1)

	var pts: Array = []
	var radii: Array = []
	var p := Vector3(0.0, y_base, 0.06)
	pts.append(p)
	radii.append(_r_profile(0.0) * body_k)
	for i in range(1, n_body):
		var t: float = float(i) / float(n_body - 1)
		var d: Vector3 = dirs[i - 1]
		p = p + d * step
		pts.append(p)
		radii.append(_r_profile(t) * body_k)

	# --- torso segments, knobs, back ridge ----------------------------------
	var squash: Basis = Basis().scaled(Vector3(1.0, 1.0, dep))
	var mat_shared: StandardMaterial3D = null
	if striped:
		mat_shared = _skin_mat(Color(1.0, 1.0, 1.0), tex_body, uv_k, uv_off, 0.66)
	for i in range(n_body):
		var t: float = float(i) / float(n_body - 1)
		var q: Vector3 = pts[i]
		var r: float = radii[i]
		var mat_seg: StandardMaterial3D = mat_shared
		if mat_seg == null:
			var base_c: Color = col_low.lerp(col_mid, clampf(t * 2.2, 0.0, 1.0))
			if t > 0.5:
				base_c = col_mid.lerp(col_high, clampf((t - 0.5) * 1.8, 0.0, 1.0))
			# the colony creeping up the foot
			var crust: float = clampf((0.24 - t) / 0.24, 0.0, 1.0)
			base_c = base_c.lerp(col_stem, crust * 0.5)
			mat_seg = _skin_mat(base_c, tex_body, uv_k, uv_off, 0.72)
		var mi: MeshInstance3D = _add(root, _sphere(r, 20, 10), mat_seg)
		mi.transform = Transform3D(squash, q)
		# lumpy rim so the silhouette is pebbled too
		if not striped and i % 2 == 0 and t > 0.06 and t < 0.94:
			var sd: float = 1.0 if (i % 4 == 0) else -1.0
			var wob: float = rng.randf_range(-0.22, 0.22)
			var off := Vector3(sd * cos(wob), rng.randf_range(-0.12, 0.12), sin(wob) * dep)
			off = off.normalized()
			var kr: float = r * rng.randf_range(0.16, 0.24)
			var km: MeshInstance3D = _add(root, _sphere(kr, 10, 6), mat_seg)
			km.transform = Transform3D(Basis(), q + Vector3(off.x * r * 0.92, off.y * r * 0.5, off.z * r * 0.92))

	var p_top: Vector3 = pts[n_body - 1]
	var r_top: float = radii[n_body - 1]

	# --- foot pad spreading onto the floor ----------------------------------
	var pad_mat: StandardMaterial3D = mat_shared
	if pad_mat == null:
		pad_mat = _skin_mat(col_low.lerp(col_stem, 0.42), tex_body, uv_k, uv_off, 0.74)
	var p_foot: Vector3 = pts[0]
	var pad_c := Vector3(p_foot.x * 0.6, 0.0, p_foot.z)
	for k in range(n_lobes):
		var fk: float = float(k) / float(n_lobes)
		var ang: float = fk * TAU + rng.randf_range(-0.14, 0.14)
		var forward: float = 0.5 + 0.5 * cos(ang)
		var reach: float = lerpf(0.115, 0.215, forward) * rng.randf_range(0.86, 1.12) * body_k
		var lr: float = rng.randf_range(0.085, 0.135) * body_k
		var flat: float = rng.randf_range(0.30, 0.42)
		var lb: Basis = Basis(Vector3.UP, ang) * Basis().scaled(Vector3(1.0, flat, 0.72))
		var lm: MeshInstance3D = _add(root, _sphere(lr, 14, 8), pad_mat)
		lm.transform = Transform3D(lb, pad_c + Vector3(-sin(ang) * reach, lr * flat, -cos(ang) * reach))
	var hub: MeshInstance3D = _add(root, _sphere(0.19 * body_k, 18, 9), pad_mat)
	hub.transform = Transform3D(Basis().scaled(Vector3(1.0, 0.44, 0.86)), pad_c + Vector3(0.0, 0.19 * body_k * 0.44, 0.0))

	# --- hunched forelimbs ---------------------------------------------------
	var i_sh: int = int(floor(float(n_body - 1) * 0.64))
	var p_sh: Vector3 = pts[i_sh]
	var r_sh: float = radii[i_sh]
	var mat_limb: StandardMaterial3D = mat_shared
	if mat_limb == null:
		mat_limb = _skin_mat(col_mid.lerp(col_high, 0.25), tex_body, uv_k, uv_off, 0.72)
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var lift: float = 0.055 if sd == raised_side else 0.0
		var sh_p: Vector3 = p_sh + Vector3(sd * r_sh * 0.86, -0.015, -r_sh * 0.2 * dep)
		var elb: Vector3 = sh_p + Vector3(sd * 0.055, -0.145 + lift * 0.45, -0.055)
		var hand: Vector3 = elb + Vector3(-sd * 0.035, -0.015 + lift, -0.105)
		_limb(root, sh_p, elb, 0.05 * body_k, mat_limb)
		_limb(root, elb, hand, 0.038 * body_k, mat_limb)
		var hm: MeshInstance3D = _add(root, _sphere(0.043 * body_k, 12, 7), mat_limb)
		hm.transform = Transform3D(Basis(), hand)
		for c in range(3):
			var fa: float = (float(c) - 1.0) * 0.62
			var fd := Vector3(sin(fa) * 0.7 - sd * 0.2, -0.42, -cos(fa) * 0.8)
			fd = fd.normalized()
			var bm: MeshInstance3D = _add(root, _sphere(0.019 * body_k, 10, 6), mat_limb)
			bm.transform = Transform3D(Basis(), hand + fd * (0.048 * body_k))

	# --- head ---------------------------------------------------------------
	var tang_top: Vector3 = _tangent(pts, n_body - 1)
	var head_yaw: float = deg_to_rad(rng.randf_range(-22.0, 22.0))
	var head_pitch: float = rng.randf_range(-0.34, -0.12)
	var f_head := Vector3(sin(head_yaw) * cos(head_pitch), sin(head_pitch), -cos(head_yaw) * cos(head_pitch))
	f_head = f_head.normalized()
	var u_head: Vector3 = (Vector3.UP - f_head * Vector3.UP.dot(f_head)).normalized()
	var x_head: Vector3 = f_head.cross(u_head).normalized()
	var hb := Basis(x_head, u_head, -f_head)
	var rh: float = 0.088 * body_k
	var h_org: Vector3 = p_top + tang_top * (rh * 0.60) + f_head * (rh * 0.34)

	var mat_head: StandardMaterial3D = mat_shared
	if mat_head == null:
		mat_head = _skin_mat(col_high, tex_body, uv_k * 1.15, uv_off, 0.70)
	var skull: MeshInstance3D = _add(root, _sphere(rh, 22, 12), mat_head)
	skull.transform = Transform3D(hb * Basis().scaled(Vector3(0.92, 0.96, 1.30)), h_org)
	var fill: MeshInstance3D = _add(root, _sphere(r_top * 1.02, 16, 9), mat_head)
	fill.transform = Transform3D(squash, (p_top + h_org) * 0.5)

	# beak: a prism rotated so its apex points forward, extruded vertically
	var beak_b: Basis = hb * Basis(Vector3.RIGHT, -PI * 0.5)
	var beak := PrismMesh.new()
	beak.size = Vector3(0.076 * body_k, 0.155 * body_k, 0.052 * body_k)
	var bkm: MeshInstance3D = _add(root, beak, mat_beak)
	bkm.transform = Transform3D(beak_b, h_org + f_head * (rh * 0.72) - u_head * (rh * 0.14))
	var jaw := PrismMesh.new()
	jaw.size = Vector3(0.058 * body_k, 0.108 * body_k, 0.030 * body_k)
	var jwm: MeshInstance3D = _add(root, jaw, mat_beak)
	var jaw_b: Basis = hb * Basis(Vector3.RIGHT, -PI * 0.5 + 0.16)
	jwm.transform = Transform3D(jaw_b, h_org + f_head * (rh * 0.60) - u_head * (rh * 0.52))

	# crest fins, swept back over the skull and down the neck
	for k in range(n_crest):
		var fk: float = float(k) / float(n_crest - 1)
		var hgt: float = lerpf(0.088, 0.034, fk) * body_k
		var tilt: float = 0.32 + 0.30 * fk
		var fin := PrismMesh.new()
		fin.size = Vector3(0.013 * body_k, hgt, hgt * 0.92)
		var fm: MeshInstance3D = _add(root, fin, mat_crest)
		var zk: float = rh * (0.10 + 1.35 * fk)
		var yk: float = rh * (0.78 - 0.22 * fk)
		fm.transform = Transform3D(hb * Basis(Vector3.RIGHT, tilt), h_org + hb * Vector3(0.0, yk, zk))

	# one dark bead eye per side, so the gaze reads from anywhere in the hall
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var em: MeshInstance3D = _add(root, _sphere(0.0165 * body_k, 12, 7), mat_eye)
		em.transform = Transform3D(Basis(), h_org + hb * Vector3(sd * rh * 0.70, rh * 0.22, -rh * 0.36))

	# --- coral fronds off the shoulders and back -----------------------------
	var mat_bulb: StandardMaterial3D = _matte(col_stem.lerp(col_tip, 0.25), 0.55)
	for k in range(n_fronds):
		var anchor_t: float = 0.0
		var side_sd: float = 1.0 if (k % 2 == 0) else -1.0
		var out_k: float = 0.0
		var back_k: float = 0.0
		if k == 0:
			anchor_t = rng.randf_range(0.68, 0.76)
			out_k = 0.60
			back_k = 0.34
		elif k == 1:
			anchor_t = rng.randf_range(0.62, 0.72)
			out_k = 0.56
			back_k = 0.40
		elif k == 2:
			anchor_t = rng.randf_range(0.46, 0.56)
			out_k = 0.34
			back_k = 0.62
		else:
			anchor_t = rng.randf_range(0.30, 0.40)
			out_k = 0.30
			back_k = 0.68
		var idx: int = int(floor(anchor_t * float(n_body - 1)))
		idx = clampi(idx, 1, n_body - 1)
		var ap: Vector3 = pts[idx]
		var ar: float = radii[idx]
		var base_p: Vector3 = ap + Vector3(side_sd * ar * out_k, ar * 0.10, ar * back_k * dep)
		var dir := Vector3(side_sd * out_k * 0.95, 0.82, back_k * 0.72)
		dir = dir.normalized()
		var bm2: MeshInstance3D = _add(root, _sphere(ar * 0.28, 12, 7), mat_bulb)
		bm2.transform = Transform3D(Basis(), base_p)
		var ln0: float = rng.randf_range(0.185, 0.235) * body_k
		var rad0: float = rng.randf_range(0.040, 0.052) * body_k
		_frond(root, base_p, dir, ln0, rad0, lvl, lvl, max_child, rng, col_stem, col_tip)

	# --- fit inside the 1.25 x 1.25 x 1.7 envelope --------------------------
	var box: AABB = _union_aabb(root)
	var kx: float = 1.22 / maxf(box.size.x, 0.01)
	var kz: float = 1.22 / maxf(box.size.z, 0.01)
	var ky: float = 1.66 / maxf(box.size.y, 0.01)
	var kfit: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kfit < 1.0:
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cm: MeshInstance3D = ch
			var tf: Transform3D = cm.transform
			cm.transform = Transform3D(tf.basis.scaled(Vector3(kfit, kfit, kfit)), tf.origin * kfit)

	# --- measured settle: centre on x/z, seat the lowest point on the floor --
	box = _union_aabb(root)
	var centre: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-centre.x, -box.position.y, -centre.z)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + shift)


# ---------------------------------------------------------------------------
# the recursive coral frond

static func _frond(root: Node3D, base: Vector3, dir: Vector3, ln: float, rad: float, depth: int, lvl_max: int, max_child: int, rng: RandomNumberGenerator, col_stem: Color, col_tip: Color) -> void:
	if depth <= 0:
		return
	if root.get_child_count() >= MAX_MESHES:
		return
	var f: float = 1.0 - float(depth - 1) / maxf(float(lvl_max - 1), 1.0)
	var col: Color = col_stem.lerp(col_tip, clampf(f * 0.85, 0.0, 1.0))
	var mat: StandardMaterial3D = _matte(col, 0.52)

	var d: Vector3 = dir.normalized()
	var side: Vector3 = d.cross(Vector3.UP)
	if side.length() < 0.001:
		side = Vector3.RIGHT
	side = side.normalized()
	var bend := side * rng.randf_range(-0.55, 0.55) + Vector3.UP * rng.randf_range(0.10, 0.55)
	bend = bend.normalized()

	var steps: int = 3 if depth >= lvl_max - 1 else 2
	var p: Vector3 = base
	var seg: float = ln / float(steps)
	for i in range(steps):
		var u: float = float(i + 1) / float(steps)
		var nd: Vector3 = (d + bend * (0.34 / float(steps))).normalized()
		var q: Vector3 = p + nd * seg
		var r_i: float = lerpf(rad, rad * 0.80, u)
		_limb(root, p, q, r_i, mat)
		p = q
		d = nd

	if depth == 1:
		var club: MeshInstance3D = _add(root, _sphere(rad * 1.45, 12, 8), _matte(col_tip, 0.50))
		club.transform = Transform3D(Basis(), p)
		return

	var n_child: int = 2
	if depth == lvl_max and max_child >= 3 and rng.randf() < 0.5:
		n_child = 3
	var spread: float = deg_to_rad(rng.randf_range(34.0, 58.0))
	var roll: float = rng.randf_range(0.0, TAU)
	var e1: Vector3 = d.cross(Vector3.UP)
	if e1.length() < 0.001:
		e1 = Vector3.RIGHT
	e1 = e1.normalized()
	var e2: Vector3 = d.cross(e1).normalized()
	var perp: Vector3 = (e1 * cos(roll) + e2 * sin(roll)).normalized()
	for k in range(n_child):
		var frac: float = 0.0
		if n_child > 1:
			frac = float(k) / float(n_child - 1) - 0.5
		var ang: float = frac * spread * 2.0
		var cd: Vector3 = (d * cos(ang) + perp * sin(ang)).normalized()
		cd = (cd + Vector3.UP * rng.randf_range(0.10, 0.30)).normalized()
		var ck: float = rng.randf_range(0.64, 0.80)
		_frond(root, p, cd, ln * ck, rad * rng.randf_range(0.62, 0.76), depth - 1, lvl_max, max_child, rng, col_stem, col_tip)


# ---------------------------------------------------------------------------
# shape helpers

static func _lean_angle(t: float, a0: float, a1: float, a2: float, a3: float) -> float:
	var keys: Array = [a0, a1, a2, a3]
	var f: float = t * 3.0
	var i: int = int(floor(f))
	if i >= 3:
		return a3
	var u: float = f - float(i)
	var s: float = u * u * (3.0 - 2.0 * u)
	var va: float = keys[i]
	var vb: float = keys[i + 1]
	return lerpf(va, vb, s)


static func _r_profile(t: float) -> float:
	var keys: Array = [0.145, 0.205, 0.243, 0.238, 0.196, 0.132, 0.078]
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


static func _hex(arr: Array, i: int) -> Color:
	var code: String = arr[i]
	return Color(code)


static func _sphere(r: float, seg: int, rings: int) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = seg
	s.rings = rings
	return s


static func _matte(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m


static func _skin_mat(c: Color, tex: ImageTexture, uvs: float, off: Vector3, rough: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = _matte(c, rough)
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(uvs, uvs, uvs)
	m.uv1_offset = off
	return m


static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _limb(root: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.008)
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = maxf(ln + r * 1.7, r * 2.05)
	cap.radial_segments = 12
	cap.rings = 4
	var mi: MeshInstance3D = _add(root, cap, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


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


# ---------------------------------------------------------------------------
# painted skins

static func _pebble_texture(rng: RandomNumberGenerator, cols: int, rows: int) -> ImageTexture:
	# staggered jittered lattice of dome-shaded pebbles, seamless in both axes
	var size: int = PEB_TEX
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGB8)
	var w: float = float(size) / float(cols)
	var h: float = float(size) / float(rows)
	var jx: Array = []
	var jy: Array = []
	var tint: Array = []
	var prad: Array = []
	for c in range(cols * rows):
		jx.append(rng.randf_range(-0.16, 0.16) * w)
		jy.append(rng.randf_range(-0.14, 0.14) * h)
		tint.append(rng.randf_range(0.88, 1.0))
		prad.append(rng.randf_range(0.42, 0.52) * w)
	var groove: float = 0.40
	for y in range(size):
		for x in range(size):
			var px: float = float(x) + 0.5
			var py: float = float(y) + 0.5
			var row_c: int = int(floor(py / h))
			var best: float = 1.0e9
			var bdx: float = 0.0
			var bdy: float = 0.0
			var bi: int = 0
			var brad: float = w * 0.46
			for rr in range(row_c - 1, row_c + 2):
				var rw: int = posmod(rr, rows)
				var off: float = 0.0
				if (rw % 2) == 1:
					off = 0.5 * w
				var col_c: int = int(floor((px - off) / w))
				for cc in range(col_c - 1, col_c + 2):
					var cw: int = posmod(cc, cols)
					var idx: int = rw * cols + cw
					var cx: float = (float(cc) + 0.5) * w + off + jx[idx]
					var cy: float = (float(rr) + 0.5) * h + jy[idx]
					var dx: float = px - cx
					var dy: float = py - cy
					var dd: float = dx * dx + dy * dy
					if dd < best:
						best = dd
						bdx = dx
						bdy = dy
						bi = idx
						brad = prad[idx]
			var rr_safe: float = maxf(brad, 0.001)
			var q: float = sqrt(best) / rr_safe
			var v: float = groove
			if q < 1.0:
				var dome: float = sqrt(maxf(1.0 - q * q, 0.0))
				var lightv: float = -(bdx * 0.55 + bdy * 0.80) / rr_safe
				var tv: float = tint[bi]
				var lit: float = clampf((0.60 + 0.32 * dome + 0.17 * lightv * dome) * tv, 0.28, 1.0)
				var edge: float = clampf((1.0 - q) / 0.16, 0.0, 1.0)
				v = lerpf(groove, lit, edge)
			img.set_pixel(x, y, Color(v, v * 0.995, v * 0.982))
	return ImageTexture.create_from_image(img)


static func _stripe_texture(rng: RandomNumberGenerator, col_a: Color, col_b: Color, bands: int, waves: int) -> ImageTexture:
	# thick wavy horizontal bands; the wave runs along u, the bands stack in v
	var size: int = STR_TEX
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGB8)
	var phase: float = rng.randf_range(0.0, TAU)
	var amp: float = rng.randf_range(0.24, 0.34)
	var duty: float = rng.randf_range(0.24, 0.29)
	for y in range(size):
		var v: float = float(y) / float(size)
		for x in range(size):
			var u: float = float(x) / float(size)
			var wob: float = amp * sin(u * TAU * float(waves) + phase)
			wob += amp * 0.32 * sin(u * TAU * float(waves * 2) + phase * 1.7)
			var s: float = fposmod(v * float(bands) + wob, 1.0)
			var d0: float = absf(s - 0.5)
			var m: float = clampf((duty - d0) / 0.055, 0.0, 1.0)
			var c: Color = col_a.lerp(col_b, m)
			var sh: float = 0.93 + 0.11 * m
			img.set_pixel(x, y, Color(clampf(c.r * sh, 0.0, 1.0), clampf(c.g * sh, 0.0, 1.0), clampf(c.b * sh, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)
