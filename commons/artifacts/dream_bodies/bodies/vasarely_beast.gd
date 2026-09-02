extends RefCounted

## dream_bodies / vasarely_beast — one smooth CG animal wearing a quad wireframe.
##
## Reference: scratchpad/refs/vasarely.png (2048x536 panorama) — a rank of smooth
## sinuous creatures rendered as CG surfaces: rounded organic bodies with long
## necks and tails that arch, bend and pass through holes in themselves, in
## lilac, lime green and pale grey, every surface covered in a fine quad
## wireframe grid, one body carrying a dark speckled patch.
##
## Reproduced, and how:
##   1. ONE CONTINUOUS TUBE. Tail tip and snout are the two ends of a single
##      25-point Catmull-Rom spine swept by SurfaceTool with parallel-transport
##      frames — no joins, exactly like a subdivision surface. It is cut into 32
##      MeshInstance chunks only so colour can block along it.
##   2. THE ARCH. The spine rises out of the tail, swells at the haunch, arches
##      over the back, dips at the saddle, then rises through a thin neck and
##      curls forward over itself into a blunt lowered head.
##   3. A HOLE IN ITSELF. The descending head tip and the top of the back leave a
##      ~18 cm slot; the tail is routed up the outside of the rump, over the
##      back and THROUGH that slot, its lime tip resting inside the neck loop
##      with ~5 cm clearance on every side. The tail's own sweep to the floor
##      leaves a second hole between it and the rump.
##   4. VARYING RADIUS. A 25-key profile: 28 mm at the tail tip, 178 mm at the
##      haunch, 72 mm through the neck, a small skull swell, 30 mm at the snout.
##      Both ends close with a measured quarter-circle taper, so nothing is capped
##      flat.
##   5. THREE STUBBY LEGS. Two front columns off the shoulder and one rear column
##      off the haunch, offset to the side opposite the tail — a tripod that is a
##      lean, not a stance. Each is its own tapered tube with a forward toe.
##   6. THE QUAD GRID. A 256x256 ImageTexture painted in code (anti-aliased dark
##      lattice on near-white, faint per-cell tint), run through uv1_triplanar so
##      one unbroken ~1 cm grid crosses body, legs, sail and head. Every gridded
##      surface is an ArrayMesh built in root-local coordinates with an identity
##      transform, so the lattice never breaks at a chunk seam.
##   7. PALETTE AND BLOCKING. Lilac / lime / pale grey by seed, hard-edged colour
##      blocks the way the reference blocks them: a second colour from the
##      shoulder forward, a lime tail tip, sometimes one contrasting lower leg.
##   8. THE SPECKLED PATCH. On some seeds two chunks of the haunch wear a dark
##      stippled skin — its own painted texture, grid still faintly under it.
##   9. ONE LATERAL SAIL. A single lime fin off one shoulder, built as a closed
##      SurfaceTool slab that tapers to zero thickness at every free edge. One
##      side only: the asymmetry is the gesture.
##
## Given up: true smooth blends where tail, legs and sail meet the body (separate
## meshes intersect, they do not fuse); the neighbouring creatures and the way
## they lean on each other; the sharp CG specular of the render; any subdivision
## crease. The grid is painted, not modelled — read it from a metre, not a
## hand's width.

const TEX: int = 256
const CAP_N: int = 4
const N_SAMP: int = 116
const RING: int = 20
const CHUNKS: int = 32
const LEG_SAMP: int = 30
const LEG_CHUNKS: int = 4
const LEG_RING: int = 14

# [body, block, tail tip / accent, sail, dark patch]
const SCHEMES: Array = [
	["#B79AE2", "#C9B4EE", "#B7D944", "#B7D944", "#3E4A3C"],
	["#B4D63F", "#C9E267", "#B79AE2", "#C0A6E8", "#39423A"],
	["#B7C2C5", "#CCD5D7", "#B4D63F", "#B79AE2", "#3C4348"],
	["#C0A6E8", "#B7C2C5", "#C7E262", "#C7E262", "#42403A"],
	["#A9CF3E", "#B7C2C5", "#C9B4EE", "#B79AE2", "#37413B"],
	["#C6CFD1", "#B79AE2", "#B4D63F", "#B4D63F", "#3A3F43"],
]


static func describe() -> String:
	return "A smooth lilac-and-lime creature under a fine quad wireframe, arching over three stubby legs while its tail sweeps to the floor and threads back through the hole under its own lowered head."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var scheme: Array = SCHEMES[rng.randi_range(0, SCHEMES.size() - 1)]
	var col_body: Color = Color(str(scheme[0]))
	var col_block: Color = Color(str(scheme[1]))
	var col_tip: Color = Color(str(scheme[2]))
	var col_sail: Color = Color(str(scheme[3]))
	var col_patch: Color = Color(str(scheme[4]))

	# --- individual parameters ---------------------------------------------
	var body_k: float = rng.randf_range(0.95, 1.02)
	var arch: float = rng.randf_range(-0.035, 0.055)
	var head_lift: float = rng.randf_range(-0.03, 0.03)
	var sway_amp: float = rng.randf_range(0.014, 0.052)
	var sway_w: float = rng.randf_range(1.1, 2.3)
	var sway_ph: float = rng.randf_range(0.0, TAU)
	var flip: float = 1.0 if rng.randf() < 0.5 else -1.0
	var sail_side: float = -flip
	var has_patch: bool = rng.randf() < 0.55
	var patch_a: float = rng.randf_range(0.50, 0.58)
	var patch_b: float = patch_a + rng.randf_range(0.06, 0.11)
	var two_tone: bool = rng.randf() < 0.7
	var split_t: float = rng.randf_range(0.78, 0.90) if two_tone else 2.0
	var grid_cells: int = 4
	var grid_k: float = rng.randf_range(19.0, 27.0)
	var accent_leg: int = rng.randi_range(0, 2)
	var has_accent_leg: bool = rng.randf() < 0.5
	var yaw: float = rng.randf_range(-0.26, 0.26)
	var sail_len: float = rng.randf_range(0.24, 0.33) * body_k

	# --- skins ---------------------------------------------------------------
	var tex_grid: ImageTexture = _skin_texture(grid_cells, 2.5, 0.50, 1.0, 0, rng)
	var mat_body: StandardMaterial3D = _skin(col_body, tex_grid, grid_k)
	var mat_block: StandardMaterial3D = _skin(col_block, tex_grid, grid_k)
	var mat_tip: StandardMaterial3D = _skin(col_tip, tex_grid, grid_k)
	var mat_sail: StandardMaterial3D = _skin(col_sail, tex_grid, grid_k)
	var mat_patch: StandardMaterial3D = mat_body
	if has_patch:
		var tex_speck: ImageTexture = _skin_texture(grid_cells, 2.0, 0.34, 0.46, 2400, rng)
		mat_patch = _skin(col_patch, tex_speck, grid_k * 1.35)
		mat_patch.roughness = 0.78
		mat_patch.clearcoat = 0.05
	var mat_eye: StandardMaterial3D = _flat(Color("#2E2838"), 0.16)
	var mat_nose: StandardMaterial3D = _flat(col_body.darkened(0.45), 0.55)

	# --- the one spine: index 0 = tail tip, index 24 = snout -----------------
	var ctrl: Array = [
		Vector3(-0.02, 1.31, -0.20),
		Vector3(-0.01, 1.24, -0.08),
		Vector3(0.02, 1.24, 0.06),
		Vector3(0.09, 1.17, 0.20),
		Vector3(0.19, 1.00, 0.34),
		Vector3(0.28, 0.78, 0.44),
		Vector3(0.32, 0.54, 0.50),
		Vector3(0.30, 0.30, 0.52),
		Vector3(0.24, 0.16, 0.47),
		Vector3(0.13, 0.11, 0.38),
		Vector3(0.04, 0.20, 0.34),
		Vector3(0.00, 0.40, 0.36),
		Vector3(0.00, 0.62, 0.35),
		Vector3(0.00, 0.82, 0.26),
		Vector3(0.00, 0.96, 0.10),
		Vector3(0.00, 1.01, -0.06),
		Vector3(0.00, 0.97, -0.20),
		Vector3(0.00, 0.92, -0.30),
		Vector3(0.00, 0.97, -0.38),
		Vector3(0.00, 1.15, -0.42),
		Vector3(0.00, 1.34, -0.40),
		Vector3(0.00, 1.45, -0.30),
		Vector3(0.00, 1.48, -0.17),
		Vector3(0.00, 1.43, -0.06),
		Vector3(0.00, 1.36, -0.02),
	]
	var radk: Array = [
		0.028, 0.036, 0.043, 0.052, 0.062, 0.072, 0.082, 0.092, 0.100, 0.106,
		0.115, 0.132, 0.158, 0.178, 0.176, 0.164, 0.148, 0.132, 0.120, 0.098,
		0.080, 0.072, 0.090, 0.072, 0.030,
	]
	ctrl[15] = (ctrl[15] as Vector3) + Vector3(0.0, arch, 0.0)
	ctrl[14] = (ctrl[14] as Vector3) + Vector3(0.0, arch * 0.6, 0.0)
	ctrl[16] = (ctrl[16] as Vector3) + Vector3(0.0, arch * 0.6, 0.0)
	for i in range(20, 25):
		ctrl[i] = (ctrl[i] as Vector3) + Vector3(0.0, head_lift, 0.0)
	var n_ctrl: int = ctrl.size()
	for i in range(n_ctrl):
		var t: float = float(i) / float(n_ctrl - 1)
		var p: Vector3 = ctrl[i]
		var wob: float = sway_amp * sin(PI * t) * sin(sway_w * TAU * t + sway_ph)
		ctrl[i] = Vector3((p.x + wob) * flip, p.y, p.z) * body_k

	var base_pts: Array = _spline(ctrl, N_SAMP)
	var pts: Array = base_pts.duplicate()
	var rad: Array = []
	for i in range(N_SAMP):
		var t: float = float(i) / float(N_SAMP - 1)
		rad.append(_key(radk, t) * body_k)
	_round_end(pts, rad, true)
	_round_end(pts, rad, false)
	var frames: Array = _frames(pts)

	# --- body chunks ---------------------------------------------------------
	var b: Array = _bounds(pts.size(), CHUNKS)
	var mats: Array = []
	for c in range(CHUNKS):
		var mid: int = int((int(b[c]) + int(b[c + 1])) / 2)
		var tb: float = clampf(float(mid - CAP_N) / float(N_SAMP - 1), 0.0, 1.0)
		var m: StandardMaterial3D = mat_body
		if tb < 0.085:
			m = mat_tip
		elif has_patch and tb >= patch_a and tb <= patch_b:
			m = mat_patch
		elif tb > split_t:
			m = mat_block
		mats.append(m)
	_emit_chunks(root, pts, rad, frames, RING, CHUNKS, mats)

	# --- legs ----------------------------------------------------------------
	var legs: Array = [
		[0.712, 1.0, 0.108],
		[0.712, -1.0, 0.108],
		[0.556, -1.0, 0.128],
	]
	for li in range(legs.size()):
		var spec: Array = legs[li]
		var tb: float = float(spec[0])
		var sgn: float = float(spec[1]) * flip
		var r_top: float = float(spec[2]) * body_k
		var si: int = _idx(tb)
		var pc: Vector3 = pts[si]
		var rr: float = float(rad[si])
		var fr: Array = frames[si]
		var tv: Vector3 = fr[0]
		var lat: Vector3 = _lat(tv)
		var dors: Vector3 = _dors(tv, lat)
		var hip: Vector3 = pc + lat * (sgn * 0.55 * rr)
		var root_p: Vector3 = pc + lat * (sgn * 0.28 * rr) - dors * (0.22 * rr)
		var lc: Array = [
			root_p,
			Vector3(hip.x + sgn * 0.020, 0.72 * body_k, hip.z - 0.03 * body_k),
			Vector3(hip.x + sgn * 0.042, 0.50 * body_k, hip.z - 0.05 * body_k),
			Vector3(hip.x + sgn * 0.050, 0.30 * body_k, hip.z - 0.02 * body_k),
			Vector3(hip.x + sgn * 0.050, 0.125 * body_k, hip.z - 0.03 * body_k),
			Vector3(hip.x + sgn * 0.050, 0.055 * body_k, hip.z - 0.115 * body_k),
		]
		var lk: Array = [r_top, r_top * 0.84, r_top * 0.69, r_top * 0.56, r_top * 0.51, r_top * 0.44]
		var lpts: Array = _spline(lc, LEG_SAMP)
		var lrad: Array = []
		for i in range(LEG_SAMP):
			lrad.append(_key(lk, float(i) / float(LEG_SAMP - 1)))
		_round_end(lpts, lrad, true)
		var lfr: Array = _frames(lpts)
		var lmats: Array = []
		for c in range(LEG_CHUNKS):
			var m: StandardMaterial3D = mat_body
			if has_accent_leg and li == accent_leg and c >= LEG_CHUNKS - 2:
				m = mat_tip
			lmats.append(m)
		_emit_chunks(root, lpts, lrad, lfr, LEG_RING, LEG_CHUNKS, lmats)

	# --- one lateral shoulder sail -------------------------------------------
	var nu: int = 18
	var nv: int = 7
	var sail_th: float = 0.021 * body_k
	var grid: Array = []
	var snrm: Array = []
	var sthk: Array = []
	for i in range(nu + 1):
		var u: float = float(i) / float(nu)
		var tb: float = lerpf(0.665, 0.805, u)
		var si: int = _idx(tb)
		var fr: Array = frames[si]
		var tv: Vector3 = fr[0]
		var pc: Vector3 = pts[si]
		var rr: float = float(rad[si])
		var lat: Vector3 = _lat(tv)
		var dors: Vector3 = _dors(tv, lat)
		var root_p: Vector3 = pc + lat * (sail_side * 0.52 * rr) + dors * (0.60 * rr)
		var out_d: Vector3 = (lat * (sail_side * 0.86) + dors * 0.50).normalized()
		var sw: float = maxf(sin(PI * (0.055 + 0.89 * u)), 0.0)
		var ln: float = sail_len * pow(sw, 0.68)
		var row: Array = []
		var hrow: Array = []
		for j in range(nv + 1):
			var v: float = float(j) / float(nv)
			row.append(root_p + out_d * (ln * v) - tv * (0.075 * body_k * v * v))
			var edge: float = maxf(sin(PI * u), 0.0)
			hrow.append(sail_th * pow(1.0 - v, 0.5) * pow(edge, 0.45))
		grid.append(row)
		sthk.append(hrow)
		snrm.append(out_d.cross(tv).normalized())
	for panel in range(3):
		var i0: int = panel * 6
		var i1: int = i0 + 6
		_add(root, _sail_panel(grid, snrm, sthk, i0, i1, nv), mat_sail)

	# --- head ----------------------------------------------------------------
	var hi: int = _idx(0.917)
	var hp: Vector3 = pts[hi]
	var hr: float = float(rad[hi])
	var hfr: Array = frames[hi]
	var ht: Vector3 = hfr[0]
	var hlat: Vector3 = _lat(ht)
	var hdors: Vector3 = _dors(ht, hlat)
	var head_mat: StandardMaterial3D = mat_block if two_tone else mat_body
	var chin_i: int = _idx(0.958)
	var chin_fr: Array = frames[chin_i]
	var chin_t: Vector3 = chin_fr[0]
	var chin_p: Vector3 = pts[chin_i]
	var chin: Vector3 = chin_p - _dors(chin_t, _lat(chin_t)) * (0.032 * body_k)
	_add(root, _ball(chin, 0.048 * body_k, 14, 9), head_mat)
	for s in range(2):
		var sgn: float = -1.0 if s == 0 else 1.0
		var cheek: Vector3 = hp + hlat * (sgn * 0.64 * hr) + ht * (0.22 * hr) - hdors * (0.09 * hr)
		_add(root, _ball(cheek, 0.56 * hr, 14, 9), head_mat)
		var out_e: Vector3 = (hlat * (sgn * 0.76) + hdors * 0.52 + ht * 0.38).normalized()
		var eye_p: Vector3 = cheek + out_e * (0.49 * hr)
		var eye := SphereMesh.new()
		eye.radius = 0.017 * body_k
		eye.height = 0.034 * body_k
		eye.radial_segments = 14
		eye.rings = 8
		var em: MeshInstance3D = _add(root, eye, mat_eye)
		em.transform = Transform3D(Basis(), eye_p)
		var ni: int = _idx(0.978)
		var nfr: Array = frames[ni]
		var nt: Vector3 = nfr[0]
		var np: Vector3 = pts[ni]
		var nr: float = float(rad[ni])
		var nl: Vector3 = _lat(nt)
		var nose_p: Vector3 = np + nl * (sgn * 0.70 * nr) - _dors(nt, nl) * (0.68 * nr)
		var nose := SphereMesh.new()
		nose.radius = 0.0085 * body_k
		nose.height = 0.017 * body_k
		nose.radial_segments = 10
		nose.rings = 6
		var nm: MeshInstance3D = _add(root, nose, mat_nose)
		nm.transform = Transform3D(Basis(), nose_p)

	# --- measured settle: yaw, fit, floor, centre ----------------------------
	_premul(root, Transform3D(Basis(Vector3.UP, yaw), Vector3.ZERO))
	var box: AABB = _union_aabb(root)
	var kfit: float = 1.0
	kfit = minf(kfit, 1.2 / maxf(box.size.x, 0.001))
	kfit = minf(kfit, 1.2 / maxf(box.size.z, 0.001))
	kfit = minf(kfit, 1.68 / maxf(box.size.y, 0.001))
	if box.size.y * kfit < 1.06:
		var grow: float = 1.06 / maxf(box.size.y * kfit, 0.001)
		grow = minf(grow, 1.2 / maxf(box.size.x * kfit, 0.001))
		grow = minf(grow, 1.2 / maxf(box.size.z * kfit, 0.001))
		if grow > 1.0:
			kfit *= grow
	if absf(kfit - 1.0) > 0.0005:
		_premul(root, Transform3D(Basis().scaled(Vector3(kfit, kfit, kfit)), Vector3.ZERO))
		box = _union_aabb(root)
	var ctr: Vector3 = box.position + box.size * 0.5
	_premul(root, Transform3D(Basis(), Vector3(-ctr.x, -box.position.y, -ctr.z)))


# ---------------------------------------------------------------------------
# materials and scene plumbing

static func _skin(c: Color, tex: ImageTexture, k: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(k, k, k)
	m.roughness = 0.48
	m.metallic = 0.0
	m.clearcoat_enabled = true
	m.clearcoat = 0.22
	m.clearcoat_roughness = 0.45
	return m


static func _flat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m


static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _premul(root: Node3D, m: Transform3D) -> void:
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = m * cm.transform


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
# curves

static func _catmull(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, u: float) -> Vector3:
	var u2: float = u * u
	var u3: float = u2 * u
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u3)


static func _spline(ctrl: Array, n: int) -> Array:
	var m: int = ctrl.size()
	var out: Array = []
	for i in range(n):
		var t: float = float(i) / float(n - 1)
		var f: float = t * float(m - 1)
		var seg: int = int(floor(f))
		if seg > m - 2:
			seg = m - 2
		var u: float = f - float(seg)
		var p0: Vector3 = ctrl[maxi(seg - 1, 0)]
		var p1: Vector3 = ctrl[seg]
		var p2: Vector3 = ctrl[mini(seg + 1, m - 1)]
		var p3: Vector3 = ctrl[mini(seg + 2, m - 1)]
		out.append(_catmull(p0, p1, p2, p3, u))
	return out


static func _key(keys: Array, t: float) -> float:
	# Catmull-Rom on scalars: a smoothstep ladder flattens at every key and reads
	# as ribbing along a long swept tube.
	var m: int = keys.size()
	if m < 2:
		return float(keys[0])
	var f: float = clampf(t, 0.0, 1.0) * float(m - 1)
	var i: int = clampi(int(floor(f)), 0, m - 2)
	var u: float = f - float(i)
	var k0: float = float(keys[maxi(i - 1, 0)])
	var k1: float = float(keys[i])
	var k2: float = float(keys[mini(i + 1, m - 1)])
	var k3: float = float(keys[mini(i + 2, m - 1)])
	var u2: float = u * u
	var u3: float = u2 * u
	var r: float = 0.5 * ((2.0 * k1) + (-k0 + k2) * u + (2.0 * k0 - 5.0 * k1 + 4.0 * k2 - k3) * u2 + (-k0 + 3.0 * k1 - 3.0 * k2 + k3) * u3)
	return maxf(r, 0.004)


static func _round_end(pts: Array, radii: Array, at_end: bool) -> void:
	var n: int = pts.size()
	var idx: int = n - 1 if at_end else 0
	var other: int = n - 2 if at_end else 1
	var base: Vector3 = pts[idx]
	var away: Vector3 = base - (pts[other] as Vector3)
	if away.length() < 0.000001:
		away = Vector3.UP
	var d: Vector3 = away.normalized()
	var r: float = float(radii[idx])
	var phis: Array = [32.0, 58.0, 78.0, 90.0]
	for k in range(phis.size()):
		var ph: float = deg_to_rad(float(phis[k]))
		var p: Vector3 = base + d * (r * sin(ph))
		var rr: float = maxf(r * cos(ph), 0.0035)
		if at_end:
			pts.append(p)
			radii.append(rr)
		else:
			pts.insert(0, p)
			radii.insert(0, rr)


static func _frames(pts: Array) -> Array:
	var n: int = pts.size()
	var tans: Array = []
	for i in range(n):
		var a: Vector3 = pts[maxi(i - 1, 0)]
		var bq: Vector3 = pts[mini(i + 1, n - 1)]
		var d: Vector3 = bq - a
		if d.length() < 0.000001:
			d = Vector3.FORWARD
		tans.append(d.normalized())
	var t0: Vector3 = tans[0]
	var refv: Vector3 = Vector3.RIGHT
	if absf(t0.dot(refv)) > 0.9:
		refv = Vector3.UP
	var nrm: Vector3 = (refv - t0 * t0.dot(refv)).normalized()
	var out: Array = []
	for i in range(n):
		var tv: Vector3 = tans[i]
		var proj: Vector3 = nrm - tv * tv.dot(nrm)
		if proj.length() < 0.00001:
			proj = Vector3.UP - tv * tv.dot(Vector3.UP)
		if proj.length() < 0.00001:
			proj = Vector3.RIGHT - tv * tv.dot(Vector3.RIGHT)
		nrm = proj.normalized()
		out.append([tv, nrm, tv.cross(nrm).normalized()])
	return out


static func _bounds(n_pts: int, n_chunks: int) -> Array:
	var out: Array = []
	for c in range(n_chunks + 1):
		out.append(int(round(float(c) * float(n_pts - 1) / float(n_chunks))))
	return out


static func _idx(t: float) -> int:
	return CAP_N + clampi(int(round(clampf(t, 0.0, 1.0) * float(N_SAMP - 1))), 0, N_SAMP - 1)


static func _lat(tv: Vector3) -> Vector3:
	var l: Vector3 = tv.cross(Vector3.UP)
	if l.length() < 0.001:
		l = tv.cross(Vector3.FORWARD)
	if l.length() < 0.001:
		return Vector3.RIGHT
	return l.normalized()


static func _dors(tv: Vector3, lat: Vector3) -> Vector3:
	var d: Vector3 = lat.cross(tv)
	if d.length() < 0.001:
		return Vector3.UP
	d = d.normalized()
	if d.y < 0.0:
		d = -d
	return d


# ---------------------------------------------------------------------------
# surfaces

static func _quad_n(st: SurfaceTool, a: Vector3, bq: Vector3, c: Vector3, d: Vector3, want: Vector3) -> void:
	var nf: Vector3 = (c - a).cross(bq - a)
	if nf.dot(want) >= 0.0:
		st.add_vertex(a)
		st.add_vertex(bq)
		st.add_vertex(c)
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(d)
	else:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(bq)
		st.add_vertex(a)
		st.add_vertex(d)
		st.add_vertex(c)


static func _tri_n(st: SurfaceTool, a: Vector3, bq: Vector3, c: Vector3, want: Vector3) -> void:
	var nf: Vector3 = (c - a).cross(bq - a)
	if nf.dot(want) >= 0.0:
		st.add_vertex(a)
		st.add_vertex(bq)
		st.add_vertex(c)
	else:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(bq)


static func _tube(pts: Array, radii: Array, frames: Array, i0: int, i1: int, seg: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	for i in range(i0, i1 + 1):
		var fr: Array = frames[i]
		var c: Vector3 = pts[i]
		var nv: Vector3 = fr[1]
		var bv: Vector3 = fr[2]
		var r: float = float(radii[i])
		var ring: Array = []
		for j in range(seg):
			var a: float = TAU * float(j) / float(seg)
			ring.append(c + (nv * cos(a) + bv * sin(a)) * r)
		rings.append(ring)
	for k in range(rings.size() - 1):
		var r0: Array = rings[k]
		var r1: Array = rings[k + 1]
		var axis: Vector3 = ((pts[i0 + k] as Vector3) + (pts[i0 + k + 1] as Vector3)) * 0.5
		for j in range(seg):
			var j2: int = (j + 1) % seg
			var a0: Vector3 = r0[j]
			var a1: Vector3 = r0[j2]
			var b0: Vector3 = r1[j]
			var b1: Vector3 = r1[j2]
			var mid: Vector3 = (a0 + a1 + b0 + b1) * 0.25
			var want: Vector3 = mid - axis
			if want.length() < 0.00001:
				want = Vector3.UP
			_quad_n(st, a0, a1, b1, b0, want.normalized())
	st.generate_normals()
	return st.commit()


static func _emit_chunks(root: Node3D, pts: Array, radii: Array, frames: Array, seg: int, n_chunks: int, mats: Array) -> void:
	var b: Array = _bounds(pts.size(), n_chunks)
	for c in range(n_chunks):
		var i0: int = int(b[c])
		var i1: int = int(b[c + 1])
		if i1 <= i0:
			continue
		_add(root, _tube(pts, radii, frames, i0, i1, seg), mats[c])


static func _sph(u: float, v: float) -> Vector3:
	return Vector3(sin(v) * cos(u), cos(v), sin(v) * sin(u))


static func _ball(c: Vector3, r: float, su: int, sv: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(sv):
		var v0: float = PI * float(i) / float(sv)
		var v1: float = PI * float(i + 1) / float(sv)
		for j in range(su):
			var u0: float = TAU * float(j) / float(su)
			var u1: float = TAU * float(j + 1) / float(su)
			var p00: Vector3 = c + _sph(u0, v0) * r
			var p10: Vector3 = c + _sph(u1, v0) * r
			var p11: Vector3 = c + _sph(u1, v1) * r
			var p01: Vector3 = c + _sph(u0, v1) * r
			if i == 0:
				_tri_n(st, p00, p11, p01, (p11 + p01) * 0.5 - c)
			elif i == sv - 1:
				_tri_n(st, p00, p10, p11, (p00 + p10) * 0.5 - c)
			else:
				var mid: Vector3 = (p00 + p10 + p11 + p01) * 0.25
				_quad_n(st, p00, p10, p11, p01, (mid - c).normalized())
	st.generate_normals()
	return st.commit()


static func _sail_panel(grid: Array, nrms: Array, thick: Array, i0: int, i1: int, nv: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(i0, i1):
		var ra: Array = grid[i]
		var rb: Array = grid[i + 1]
		var ha: Array = thick[i]
		var hb: Array = thick[i + 1]
		var na: Vector3 = nrms[i]
		var nb: Vector3 = nrms[i + 1]
		for j in range(nv):
			var a0: Vector3 = ra[j]
			var a1: Vector3 = ra[j + 1]
			var b0: Vector3 = rb[j]
			var b1: Vector3 = rb[j + 1]
			var fa0: Vector3 = a0 + na * float(ha[j])
			var fa1: Vector3 = a1 + na * float(ha[j + 1])
			var fb0: Vector3 = b0 + nb * float(hb[j])
			var fb1: Vector3 = b1 + nb * float(hb[j + 1])
			var ka0: Vector3 = a0 - na * float(ha[j])
			var ka1: Vector3 = a1 - na * float(ha[j + 1])
			var kb0: Vector3 = b0 - nb * float(hb[j])
			var kb1: Vector3 = b1 - nb * float(hb[j + 1])
			_quad_n(st, fa0, fa1, fb1, fb0, na)
			_quad_n(st, ka0, ka1, kb1, kb0, -na)
	st.generate_normals()
	return st.commit()


# ---------------------------------------------------------------------------
# painted skins

static func _skin_texture(cells: int, line_w: float, ink: float, base_v: float, speck: int, rng: RandomNumberGenerator) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	img.fill(Color(base_v, base_v, base_v))
	var cell: float = float(TEX) / float(cells)
	var tint: Array = []
	for i in range(cells * cells):
		tint.append(rng.randf_range(0.972, 1.0))
	for y in range(TEX):
		for x in range(TEX):
			var px: float = float(x) + 0.5
			var py: float = float(y) + 0.5
			var cx: int = int(floor(px / cell))
			var cy: int = int(floor(py / cell))
			var fx: float = px - float(cx) * cell
			var fy: float = py - float(cy) * cell
			var d: float = minf(minf(fx, cell - fx), minf(fy, cell - fy))
			var amt: float = clampf((line_w - d) / 1.15, 0.0, 1.0)
			var bv: float = base_v * float(tint[posmod(cy, cells) * cells + posmod(cx, cells)])
			var v: float = lerpf(bv, ink, amt)
			img.set_pixel(x, y, Color(v, v, v))
	for i in range(speck):
		var sx: int = rng.randi_range(0, TEX - 1)
		var sy: int = rng.randi_range(0, TEX - 1)
		var sv: float = rng.randf_range(0.58, 1.0)
		img.set_pixel(sx, sy, Color(sv, sv, sv))
		if rng.randf() < 0.45:
			var s2: float = sv * 0.88
			img.set_pixel(posmod(sx + 1, TEX), sy, Color(s2, s2, s2))
		if rng.randf() < 0.45:
			var s3: float = sv * 0.88
			img.set_pixel(sx, posmod(sy + 1, TEX), Color(s3, s3, s3))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

