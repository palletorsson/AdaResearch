extends RefCounted

## dream_bodies / hadid_shell — one standing Zaha-Hadid parametric shell.
##
## Reference: scratchpad/refs/hadid.png (2048x536 panorama) — a row of tall white
## parametric bodies at night: thick matte-white shells riddled with smooth
## organic holes like bone or coral lattice, each shell twisting and folding
## around its own hollow, violet light spilling out of the cavities, and one
## body carrying a section of fine dark woven mesh instead of white shell.
##
## Reproduced, and how:
##   1. The shell itself — a lofted open cross-section swept up a leaning,
##      swaying spine (46 rings x 30 columns). Each ring is an arc, not a
##      circle: lobed radius, squashed to an oval, its angular phase twisting
##      up to 1.5 rad over the height, so the surface folds past itself.
##   2. Organic holes — a seeded field of 24 wobbling blobs over the (v,u)
##      parameter grid removes whole clusters of quads; a per-row rescue keeps
##      every ring structurally continuous so the lattice never falls apart.
##   3. Rounded hole rims — every boundary edge of the surviving lattice gets a
##      half-tube of triangles swept from the outer skin, out through the hole,
##      to the inner skin. Outer skin, inner skin and rim meet with matching
##      normals, so the lip reads as a thick moulded edge, not a cut.
##   4. Violet from inside — the inner skin carries a faint violet emission
##      (strongest low down, where the cavity is deepest), the rims a fainter
##      one so light appears to bleed around each hole, and 10-14 emissive
##      cores float in the hollow, glimpsed through the perforations.
##   5. The curled lips — both open ends of every arc hook inward over the last
##      15% of the section, the two curls seeded independently, so the shell
##      closes on itself asymmetrically.
##   6. A second folding blade — a perforated trough sweeps 120-195 deg around
##      the body from hip to shoulder, bulging away at mid-span, its own
##      lattice and rims built by the same loft.
##   7. The dark mesh section — one window in the white shell is left open and
##      filled with a fine woven grid, 15 warp ribbons over 26 weft ribbons at
##      different offsets from the mid-surface, dark and slightly metallic.
##   8. Bone surface — a 192x192 texture painted in code (four periodic bands
##      plus grain), triplanar so it runs unbroken across shell, blade and the
##      smooth swellings that fuse over the lattice.
##
## Given up: the true nested double-shell (this is one skin with thickness, not
## a shell inside a shell), the neighbouring bodies leaning on each other, the
## city and its floodlights, and the sharp faceted creases where the reference's
## panels meet — here every fold is smooth.

const TEX_SIZE: int = 192
const PLINTH_TOP: float = 0.05

# radius and angular span of the swept section, keyed base -> top
const RAD_KEYS: Array = [0.215, 0.248, 0.202, 0.146, 0.188, 0.216, 0.166, 0.092]
const SPAN_KEYS: Array = [300.0, 332.0, 288.0, 250.0, 300.0, 340.0, 302.0, 262.0]

# scheme: [outer white, inner white, glow violet, rim violet, dark mesh, plinth]
const SCHEMES: Array = [
	["#F4F3F6", "#DCD4EC", "#8B5CF0", "#A97BF2", "#2A2730", "#C9CCC8"],
	["#F6F2EC", "#E4DAE8", "#7C4DE0", "#B085EE", "#2B2830", "#CBCAC4"],
	["#EFF1F6", "#D6D2EE", "#9A5AE8", "#C08CF0", "#26262E", "#C6C9CC"],
	["#F7F5F2", "#E0D6EA", "#6F5AE8", "#9E86F0", "#312C34", "#CCC9C4"],
]


static func describe() -> String:
	return "A tall white parametric shell twisting around its own hollow, its bone lattice bored through with rounded organic holes that bleed violet light, one window filled with fine dark mesh."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var scheme: Array = SCHEMES[rng.randi_range(0, SCHEMES.size() - 1)]
	var col_out: Color = _c(scheme, 0)
	var col_in: Color = _c(scheme, 1)
	var col_glow: Color = _c(scheme, 2)
	var col_rim: Color = _c(scheme, 3)
	var col_dark: Color = _c(scheme, 4)
	var col_plinth: Color = _c(scheme, 5)

	var bone: ImageTexture = _bone_texture(rng)

	# ---- materials ---------------------------------------------------------
	var mat_out := StandardMaterial3D.new()
	mat_out.albedo_color = col_out
	mat_out.roughness = 0.62
	mat_out.metallic = 0.0
	mat_out.albedo_texture = bone
	mat_out.uv1_triplanar = true
	mat_out.uv1_scale = Vector3(1.7, 1.7, 1.7)
	mat_out.clearcoat_enabled = true
	mat_out.clearcoat = 0.18
	mat_out.clearcoat_roughness = 0.5

	var mat_in := StandardMaterial3D.new()
	mat_in.albedo_color = col_in.darkened(0.10)
	mat_in.roughness = 0.55
	mat_in.metallic = 0.0
	mat_in.albedo_texture = bone
	mat_in.uv1_triplanar = true
	mat_in.uv1_scale = Vector3(1.7, 1.7, 1.7)
	mat_in.emission_enabled = true
	mat_in.emission = col_glow
	mat_in.emission_energy_multiplier = 1.30

	var mat_rim := StandardMaterial3D.new()
	mat_rim.albedo_color = col_out.lerp(col_in, 0.22)
	mat_rim.roughness = 0.44
	mat_rim.metallic = 0.0
	mat_rim.albedo_texture = bone
	mat_rim.uv1_triplanar = true
	mat_rim.uv1_scale = Vector3(2.4, 2.4, 2.4)
	mat_rim.emission_enabled = true
	mat_rim.emission = col_rim
	mat_rim.emission_energy_multiplier = 0.26

	var mat_core := StandardMaterial3D.new()
	mat_core.albedo_color = col_glow.darkened(0.45)
	mat_core.roughness = 0.70
	mat_core.metallic = 0.0
	mat_core.emission_enabled = true
	mat_core.emission = col_glow
	mat_core.emission_energy_multiplier = 2.30

	var mat_dark := StandardMaterial3D.new()
	mat_dark.albedo_color = col_dark
	mat_dark.roughness = 0.36
	mat_dark.metallic = 0.35
	mat_dark.cull_mode = BaseMaterial3D.CULL_DISABLED

	var mat_plinth := StandardMaterial3D.new()
	mat_plinth.albedo_color = col_plinth
	mat_plinth.roughness = 0.86
	mat_plinth.metallic = 0.0

	# ---- this individual ---------------------------------------------------
	var nv: int = 46
	var nu: int = 30
	var body_h: float = rng.randf_range(1.34, 1.46)
	var lean_dir: float = rng.randf_range(0.0, TAU)
	var lean_amt: float = rng.randf_range(0.09, 0.16)
	var sway_amt: float = rng.randf_range(0.030, 0.070)
	var sway_ph: float = rng.randf_range(0.0, PI)
	var twist: float = rng.randf_range(-1.5, 1.5)
	var phase0: float = rng.randf_range(0.0, TAU)
	var squash: float = rng.randf_range(0.74, 0.90)
	var lobe_a: float = rng.randf_range(0.0, TAU)
	var lobe_b: float = rng.randf_range(0.0, TAU)
	var girth: float = rng.randf_range(0.94, 1.06)
	var curl_hi: float = rng.randf_range(0.85, 1.45)
	var curl_lo: float = rng.randf_range(0.30, 0.95)
	var thick: float = rng.randf_range(0.023, 0.030)

	# ---- main shell surface ------------------------------------------------
	var axis := PackedVector3Array()
	axis.resize(nv)
	var lat := Vector3(cos(lean_dir), 0.0, sin(lean_dir))
	var lat2 := Vector3(-sin(lean_dir), 0.0, cos(lean_dir))
	for i in range(nv):
		var v: float = float(i) / float(nv - 1)
		var sm: float = v * v * (3.0 - 2.0 * v)
		var off: float = lean_amt * sm
		var sw: float = sway_amt * sin(PI * v * 1.7 + sway_ph)
		axis[i] = Vector3(0.0, body_h * v, 0.0) + lat * off + lat2 * sw

	var pts := PackedVector3Array()
	pts.resize(nv * nu)
	for i in range(nv):
		var v: float = float(i) / float(nv - 1)
		var c: Vector3 = axis[i]
		var tang: Vector3 = _spine_tangent(axis, i)
		var fr: Array = _frame(tang)
		var b1: Vector3 = fr[0]
		var b2: Vector3 = fr[1]
		var rad: float = _key(RAD_KEYS, v) * girth
		var spanv: float = deg_to_rad(_key(SPAN_KEYS, v))
		var ph: float = phase0 + twist * v + 0.34 * sin(PI * v * 2.3)
		for j in range(nu):
			var u: float = float(j) / float(nu - 1)
			var a: float = ph - spanv * 0.5 + spanv * u
			var rr: float = rad * (1.0 + 0.17 * cos(2.0 * (a - lobe_a)) + 0.07 * sin(3.0 * a + lobe_b) + 0.045 * sin(5.0 * a + v * 4.0))
			if u > 0.85:
				var cs: float = (u - 0.85) / 0.15
				a += curl_hi * cs * cs
				rr *= lerpf(1.0, 0.52, cs * cs)
			elif u < 0.13:
				var cs2: float = (0.13 - u) / 0.13
				a -= curl_lo * cs2 * cs2
				rr *= lerpf(1.0, 0.66, cs2 * cs2)
			pts[i * nu + j] = c + b1 * (cos(a) * rr) + b2 * (sin(a) * rr * squash)

	var nrm: PackedVector3Array = _grid_normals(pts, nv, nu, axis)

	# ---- hole field --------------------------------------------------------
	var blobs: Array = _make_blobs(rng, 24, 0.035, 0.085)
	var keep: PackedByteArray = _keep_grid(blobs, nv, nu, 2, 6)

	# ---- the dark mesh window ---------------------------------------------
	var wv0: float = rng.randf_range(0.27, 0.36)
	var wv1: float = wv0 + rng.randf_range(0.24, 0.33)
	var wu0: float = rng.randf_range(0.05, 0.10)
	if rng.randf() < 0.5:
		wu0 = rng.randf_range(0.62, 0.68)
	var wu1: float = wu0 + rng.randf_range(0.24, 0.30)
	var cu: int = nu - 1
	var cv: int = nv - 1
	for i in range(cv):
		var v: float = (float(i) + 0.5) / float(cv)
		if v < wv0 or v > wv1:
			continue
		for j in range(cu):
			var u: float = (float(j) + 0.5) / float(cu)
			if u >= wu0 and u <= wu1:
				keep[i * cu + j] = 0

	# ---- emit the shell ----------------------------------------------------
	_emit_shell(root, pts, nrm, keep, nv, nu, thick, 12, mat_out, mat_in, mat_rim)

	# ---- the woven panel ---------------------------------------------------
	var fi0: float = wv0 * float(nv - 1) - 0.5
	var fi1: float = wv1 * float(nv - 1) + 0.5
	var fj0: float = wu0 * float(nu - 1) - 0.4
	var fj1: float = wu1 * float(nu - 1) + 0.4
	_emit_weave(root, pts, nrm, nv, nu, fi0, fi1, fj0, fj1, 15, 26, 0.18, 0.13, thick * 0.42, thick * 0.10, mat_dark)

	# ---- the folding blade -------------------------------------------------
	var nvb: int = 30
	var nub: int = 13
	var bdir: float = 1.0
	if rng.randf() < 0.5:
		bdir = -1.0
	var a_start: float = rng.randf_range(0.0, TAU)
	var a_end: float = a_start + bdir * rng.randf_range(2.1, 3.4)
	var w_lo: float = rng.randf_range(0.08, 0.16)
	var w_hi: float = rng.randf_range(0.72, 0.83)
	var bulge: float = rng.randf_range(0.10, 0.18)
	var b_tw: float = rng.randf_range(-1.2, 1.2)
	var b_span: float = deg_to_rad(rng.randf_range(120.0, 170.0))

	var b_cen := PackedVector3Array()
	b_cen.resize(nvb)
	var b_ref := PackedVector3Array()
	b_ref.resize(nvb)
	for i in range(nvb):
		var w: float = float(i) / float(nvb - 1)
		var vv: float = lerpf(w_lo, w_hi, w)
		var fidx: float = vv * float(nv - 1)
		var i_lo: int = int(floor(fidx))
		var i_hi: int = mini(i_lo + 1, nv - 1)
		var ft: float = fidx - float(i_lo)
		var ca: Vector3 = axis[i_lo].lerp(axis[i_hi], ft)
		var tang: Vector3 = _spine_tangent(axis, i_lo)
		var fr: Array = _frame(tang)
		var b1: Vector3 = fr[0]
		var b2: Vector3 = fr[1]
		var rad: float = _key(RAD_KEYS, vv) * girth
		var arc: float = sin(PI * clampf(w, 0.0, 1.0))
		var push: float = rad * 1.05 + bulge * pow(maxf(arc, 0.0), 0.7)
		var ang: float = lerpf(a_start, a_end, w) + 0.30 * sin(PI * w * 1.6)
		var bob: float = 0.055 * sin(PI * w * 2.1 + sway_ph)
		b_ref[i] = ca
		b_cen[i] = ca + b1 * (cos(ang) * push) + b2 * (sin(ang) * push * squash) + Vector3(0.0, bob, 0.0)

	var b_pts: PackedVector3Array = _tube_grid(b_cen, b_ref, nvb, nub, b_span, b_tw, 0.042, 0.092, 1.45)
	var b_nrm: PackedVector3Array = _grid_normals(b_pts, nvb, nub, b_cen)
	var b_blobs: Array = _make_blobs(rng, 11, 0.045, 0.105)
	var b_keep: PackedByteArray = _keep_grid(b_blobs, nvb, nub, 1, 4)
	_emit_shell(root, b_pts, b_nrm, b_keep, nvb, nub, thick * 0.78, 6, mat_out, mat_in, mat_rim)

	# ---- violet cores in the hollow ---------------------------------------
	var n_cores: int = rng.randi_range(10, 14)
	for k in range(n_cores):
		var t: float = rng.randf_range(0.05, 0.90)
		var idx: int = clampi(int(floor(t * float(nv - 1))), 0, nv - 1)
		var c: Vector3 = axis[idx]
		var fr: Array = _frame(_spine_tangent(axis, idx))
		var b1: Vector3 = fr[0]
		var b2: Vector3 = fr[1]
		var rad: float = _key(RAD_KEYS, t) * girth
		var oa: float = rng.randf_range(0.0, TAU)
		var orr: float = rad * rng.randf_range(0.0, 0.26)
		var rc: float = rad * rng.randf_range(0.24, 0.44)
		var sph := SphereMesh.new()
		sph.radius = rc
		sph.height = rc * 2.0
		sph.radial_segments = 14
		sph.rings = 8
		var cm: MeshInstance3D = _add(root, sph, mat_core)
		var stretch: float = rng.randf_range(1.1, 1.9)
		var bs: Basis = Basis().scaled(Vector3(1.0, stretch, 1.0))
		cm.transform = Transform3D(bs, c + b1 * (cos(oa) * orr) + b2 * (sin(oa) * orr))

	# ---- smooth swellings fused over the lattice ---------------------------
	var n_knob: int = rng.randi_range(5, 8)
	for k in range(n_knob):
		var gi: int = rng.randi_range(1, nv - 6)
		var gj: int = rng.randi_range(1, nu - 3)
		if keep[mini(gi, cv - 1) * cu + mini(gj, cu - 1)] == 0:
			continue
		var p: Vector3 = pts[gi * nu + gj]
		var n: Vector3 = nrm[gi * nu + gj]
		var rk: float = rng.randf_range(0.048, 0.095)
		var sph := SphereMesh.new()
		sph.radius = rk
		sph.height = rk * 2.0
		sph.radial_segments = 16
		sph.rings = 9
		var km: MeshInstance3D = _add(root, sph, mat_out)
		var bs: Basis = _basis_y_to(n).scaled(Vector3(rng.randf_range(0.9, 1.5), 0.46, rng.randf_range(0.9, 1.5)))
		km.transform = Transform3D(bs, p)

	# ---- pads where the shell meets the ground -----------------------------
	var n_pad: int = 3
	for k in range(n_pad):
		var gj: int = int(floor(lerpf(2.0, float(nu - 3), float(k) / float(maxi(n_pad - 1, 1)))))
		var p: Vector3 = pts[gj]
		var rp: float = rng.randf_range(0.048, 0.078)
		var sph := SphereMesh.new()
		sph.radius = rp
		sph.height = rp * 2.0
		sph.radial_segments = 16
		sph.rings = 8
		var pm: MeshInstance3D = _add(root, sph, mat_out)
		var bs: Basis = Basis().scaled(Vector3(1.35, 0.42, 1.35))
		pm.transform = Transform3D(bs, Vector3(p.x, rp * 0.30, p.z))

	# ---- settle: fit, ground, centre, plinth -------------------------------
	var box: AABB = _union_aabb(root)
	var wmax: float = maxf(box.size.x, box.size.z)
	var kfit: float = 1.0
	if wmax > 1.20:
		kfit = minf(kfit, 1.20 / maxf(wmax, 0.01))
	var h_avail: float = 1.68 - PLINTH_TOP
	if box.size.y > h_avail:
		kfit = minf(kfit, h_avail / maxf(box.size.y, 0.01))
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
	plinth.size = Vector3(minf(1.20, box.size.x + 0.10), PLINTH_TOP, minf(1.20, box.size.z + 0.10))
	var plm: MeshInstance3D = _add(root, plinth, mat_plinth)
	plm.transform = Transform3D(Basis(), Vector3(0.0, PLINTH_TOP * 0.5, 0.0))


# ---------------------------------------------------------------------------
# lattice construction

static func _emit_shell(root: Node3D, pts: PackedVector3Array, nrm: PackedVector3Array, keep: PackedByteArray, nv: int, nu: int, thick: float, bands: int, mat_out: StandardMaterial3D, mat_in: StandardMaterial3D, mat_rim: StandardMaterial3D) -> void:
	var cv: int = nv - 1
	var cu: int = nu - 1
	var hh: float = thick * 0.5
	for b in range(bands):
		var i0: int = int(floor(float(b) * float(cv) / float(bands)))
		var i1: int = int(floor(float(b + 1) * float(cv) / float(bands)))
		if b == bands - 1:
			i1 = cv
		if i1 <= i0:
			continue
		var so := SurfaceTool.new()
		so.begin(Mesh.PRIMITIVE_TRIANGLES)
		var si := SurfaceTool.new()
		si.begin(Mesh.PRIMITIVE_TRIANGLES)
		var sr := SurfaceTool.new()
		sr.begin(Mesh.PRIMITIVE_TRIANGLES)
		var n_skin: int = 0
		var n_rim: int = 0
		for i in range(i0, i1):
			for j in range(cu):
				if keep[i * cu + j] == 0:
					continue
				n_skin += 1
				var p00: Vector3 = pts[i * nu + j]
				var p01: Vector3 = pts[i * nu + j + 1]
				var p10: Vector3 = pts[(i + 1) * nu + j]
				var p11: Vector3 = pts[(i + 1) * nu + j + 1]
				var n00: Vector3 = nrm[i * nu + j]
				var n01: Vector3 = nrm[i * nu + j + 1]
				var n10: Vector3 = nrm[(i + 1) * nu + j]
				var n11: Vector3 = nrm[(i + 1) * nu + j + 1]
				var nc: Vector3 = (n00 + n01 + n11 + n10).normalized()
				_quad_face(so, p00 + n00 * hh, p01 + n01 * hh, p11 + n11 * hh, p10 + n10 * hh, nc)
				_quad_face(si, p00 - n00 * hh, p01 - n01 * hh, p11 - n11 * hh, p10 - n10 * hh, -nc)
				# rim on any edge whose neighbour cell is gone
				if j == 0 or keep[i * cu + j - 1] == 0:
					_rim(sr, p00, n00, _ortho(p00 - p01, n00), p10, n10, _ortho(p10 - p11, n10), hh)
					n_rim += 1
				if j == cu - 1 or keep[i * cu + j + 1] == 0:
					_rim(sr, p01, n01, _ortho(p01 - p00, n01), p11, n11, _ortho(p11 - p10, n11), hh)
					n_rim += 1
				if i == 0 or keep[(i - 1) * cu + j] == 0:
					_rim(sr, p00, n00, _ortho(p00 - p10, n00), p01, n01, _ortho(p01 - p11, n01), hh)
					n_rim += 1
				if i == cv - 1 or keep[(i + 1) * cu + j] == 0:
					_rim(sr, p10, n10, _ortho(p10 - p00, n10), p11, n11, _ortho(p11 - p01, n11), hh)
					n_rim += 1
		if n_skin == 0:
			continue
		so.generate_normals()
		si.generate_normals()
		_add(root, so.commit(), mat_out)
		var band_in: StandardMaterial3D = mat_in.duplicate() as StandardMaterial3D
		var bf: float = float(b) / float(maxi(bands - 1, 1))
		band_in.emission_energy_multiplier = mat_in.emission_energy_multiplier * lerpf(1.40, 0.60, bf)
		_add(root, si.commit(), band_in)
		if n_rim > 0:
			sr.generate_normals()
			_add(root, sr.commit(), mat_rim)


static func _rim(st: SurfaceTool, pa: Vector3, na: Vector3, ea: Vector3, pb: Vector3, nb: Vector3, eb: Vector3, hh: float) -> void:
	var segs: int = 3
	for k in range(segs):
		var t0: float = float(k) / float(segs)
		var t1: float = float(k + 1) / float(segs)
		var a0: float = PI * t0
		var a1: float = PI * t1
		var da0: Vector3 = na * cos(a0) + ea * sin(a0)
		var da1: Vector3 = na * cos(a1) + ea * sin(a1)
		var db0: Vector3 = nb * cos(a0) + eb * sin(a0)
		var db1: Vector3 = nb * cos(a1) + eb * sin(a1)
		var want: Vector3 = (da0 + da1 + db0 + db1).normalized()
		_quad_face(st, pa + da0 * hh, pa + da1 * hh, pb + db1 * hh, pb + db0 * hh, want)


static func _emit_weave(root: Node3D, pts: PackedVector3Array, nrm: PackedVector3Array, nv: int, nu: int, fi0: float, fi1: float, fj0: float, fj1: float, n_warp: int, n_weft: int, warp_w: float, weft_w: float, lift_a: float, lift_b: float, mat: StandardMaterial3D) -> void:
	var sw := SurfaceTool.new()
	sw.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps_v: int = 26
	for k in range(n_warp):
		var fj: float = lerpf(fj0, fj1, float(k) / float(maxi(n_warp - 1, 1)))
		for s in range(steps_v):
			var t0: float = float(s) / float(steps_v)
			var t1: float = float(s + 1) / float(steps_v)
			var ia: float = lerpf(fi0, fi1, t0)
			var ib: float = lerpf(fi0, fi1, t1)
			var q00: Vector3 = _sample(pts, nrm, nv, nu, ia, fj - warp_w, lift_a)
			var q01: Vector3 = _sample(pts, nrm, nv, nu, ia, fj + warp_w, lift_a)
			var q11: Vector3 = _sample(pts, nrm, nv, nu, ib, fj + warp_w, lift_a)
			var q10: Vector3 = _sample(pts, nrm, nv, nu, ib, fj - warp_w, lift_a)
			var want: Vector3 = _sample_n(nrm, nv, nu, ia, fj)
			_quad_face(sw, q00, q01, q11, q10, want)
	sw.generate_normals()
	_add(root, sw.commit(), mat)

	var sf := SurfaceTool.new()
	sf.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps_u: int = 16
	for k in range(n_weft):
		var fi: float = lerpf(fi0, fi1, float(k) / float(maxi(n_weft - 1, 1)))
		for s in range(steps_u):
			var t0: float = float(s) / float(steps_u)
			var t1: float = float(s + 1) / float(steps_u)
			var ja: float = lerpf(fj0, fj1, t0)
			var jb: float = lerpf(fj0, fj1, t1)
			var q00: Vector3 = _sample(pts, nrm, nv, nu, fi - weft_w, ja, lift_b)
			var q01: Vector3 = _sample(pts, nrm, nv, nu, fi + weft_w, ja, lift_b)
			var q11: Vector3 = _sample(pts, nrm, nv, nu, fi + weft_w, jb, lift_b)
			var q10: Vector3 = _sample(pts, nrm, nv, nu, fi - weft_w, jb, lift_b)
			var want: Vector3 = _sample_n(nrm, nv, nu, fi, ja)
			_quad_face(sf, q00, q01, q11, q10, want)
	sf.generate_normals()
	_add(root, sf.commit(), mat)


static func _make_blobs(rng: RandomNumberGenerator, n: int, rmin: float, rmax: float) -> Array:
	var blobs: Array = []
	for k in range(n):
		var vc: float = rng.randf_range(-0.06, 1.06)
		var uc: float = rng.randf_range(-0.06, 1.06)
		var grow: float = lerpf(0.78, 1.28, clampf(vc, 0.0, 1.0))
		var rv: float = rng.randf_range(rmin, rmax) * grow
		var ru: float = rv * rng.randf_range(1.1, 2.1)
		var wob: float = rng.randf_range(0.12, 0.34)
		var lobes: float = float(rng.randi_range(2, 4))
		var lph: float = rng.randf_range(0.0, TAU)
		blobs.append([vc, uc, rv, ru, wob, lobes, lph])
	return blobs


static func _keep_grid(blobs: Array, nv: int, nu: int, floor_rows: int, min_row: int) -> PackedByteArray:
	var cv: int = nv - 1
	var cu: int = nu - 1
	var keep := PackedByteArray()
	keep.resize(cv * cu)
	var dist := PackedFloat32Array()
	dist.resize(cv * cu)
	for i in range(cv):
		var v: float = (float(i) + 0.5) / float(cv)
		for j in range(cu):
			var u: float = (float(j) + 0.5) / float(cu)
			var best: float = 9.0
			for bl in blobs:
				var bb: Array = bl
				var vc: float = bb[0]
				var uc: float = bb[1]
				var rv: float = bb[2]
				var ru: float = bb[3]
				var wob: float = bb[4]
				var lobes: float = bb[5]
				var lph: float = bb[6]
				var dvv: float = (v - vc) / maxf(rv, 0.001)
				var duu: float = (u - uc) / maxf(ru, 0.001)
				var d: float = sqrt(dvv * dvv + duu * duu)
				var th: float = 1.0 + wob * sin(lobes * atan2(dvv, duu) + lph)
				var m: float = d - th
				if m < best:
					best = m
			dist[i * cu + j] = best
			if best > 0.0:
				keep[i * cu + j] = 1
			else:
				keep[i * cu + j] = 0
	for i in range(mini(floor_rows, cv)):
		for j in range(cu):
			keep[i * cu + j] = 1
	# no ring may be cut through: rescue the least-buried cells of a thin row
	for i in range(cv):
		var cnt: int = 0
		for j in range(cu):
			if keep[i * cu + j] == 1:
				cnt += 1
		while cnt < min_row:
			var bestj: int = -1
			var bestd: float = -99999.0
			for j in range(cu):
				if keep[i * cu + j] == 1:
					continue
				var dd: float = dist[i * cu + j]
				if dd > bestd:
					bestd = dd
					bestj = j
			if bestj < 0:
				break
			keep[i * cu + bestj] = 1
			cnt += 1
	return keep


static func _tube_grid(cen: PackedVector3Array, refp: PackedVector3Array, nvb: int, nub: int, span: float, tw: float, rb_lo: float, rb_hi: float, flat: float) -> PackedVector3Array:
	var pts := PackedVector3Array()
	pts.resize(nvb * nub)
	for i in range(nvb):
		var w: float = float(i) / float(nvb - 1)
		var c: Vector3 = cen[i]
		var tang: Vector3 = _spine_tangent(cen, i)
		var outw: Vector3 = c - refp[i]
		outw = outw - tang * outw.dot(tang)
		if outw.length() < 0.000001:
			outw = Vector3.UP - tang * Vector3.UP.dot(tang)
		outw = outw.normalized()
		var side: Vector3 = tang.cross(outw).normalized()
		var arc: float = maxf(sin(PI * clampf(w, 0.0, 1.0)), 0.0)
		var rb: float = lerpf(rb_lo, rb_hi, pow(arc, 0.6))
		var ph: float = tw * w
		for j in range(nub):
			var u: float = float(j) / float(nub - 1)
			var a: float = ph - span * 0.5 + span * u
			var rr: float = rb * (1.0 + 0.14 * cos(2.0 * a) + 0.06 * sin(3.0 * a + w * 5.0))
			if u > 0.86:
				var es: float = (u - 0.86) / 0.14
				a += 0.95 * es * es
				rr *= lerpf(1.0, 0.58, es * es)
			pts[i * nub + j] = c + outw * (cos(a) * rr * flat) + side * (sin(a) * rr)
	return pts


static func _grid_normals(pts: PackedVector3Array, nv: int, nu: int, ax: PackedVector3Array) -> PackedVector3Array:
	var out := PackedVector3Array()
	out.resize(nv * nu)
	for i in range(nv):
		for j in range(nu):
			var ia: int = maxi(i - 1, 0)
			var ib: int = mini(i + 1, nv - 1)
			var ja: int = maxi(j - 1, 0)
			var jb: int = mini(j + 1, nu - 1)
			var dv: Vector3 = pts[ib * nu + j] - pts[ia * nu + j]
			var du: Vector3 = pts[i * nu + jb] - pts[i * nu + ja]
			var n: Vector3 = dv.cross(du)
			var outward: Vector3 = pts[i * nu + j] - ax[i]
			if n.length() < 0.000001:
				n = outward
			if n.length() < 0.000001:
				n = Vector3.UP
			n = n.normalized()
			if n.dot(outward) < 0.0:
				n = -n
			out[i * nu + j] = n
	return out


static func _sample(pts: PackedVector3Array, nrm: PackedVector3Array, nv: int, nu: int, fi: float, fj: float, lift: float) -> Vector3:
	var p: Vector3 = _bilinear(pts, nv, nu, fi, fj)
	var n: Vector3 = _sample_n(nrm, nv, nu, fi, fj)
	return p + n * lift


static func _sample_n(nrm: PackedVector3Array, nv: int, nu: int, fi: float, fj: float) -> Vector3:
	var n: Vector3 = _bilinear(nrm, nv, nu, fi, fj)
	if n.length() < 0.000001:
		return Vector3.UP
	return n.normalized()


static func _bilinear(arr: PackedVector3Array, nv: int, nu: int, fi: float, fj: float) -> Vector3:
	var ci: float = clampf(fi, 0.0, float(nv - 1) - 0.0005)
	var cj: float = clampf(fj, 0.0, float(nu - 1) - 0.0005)
	var i: int = int(floor(ci))
	var j: int = int(floor(cj))
	var ti: float = ci - float(i)
	var tj: float = cj - float(j)
	var a: Vector3 = arr[i * nu + j]
	var b: Vector3 = arr[i * nu + j + 1]
	var c: Vector3 = arr[(i + 1) * nu + j]
	var d: Vector3 = arr[(i + 1) * nu + j + 1]
	return a.lerp(b, tj).lerp(c.lerp(d, tj), ti)


# ---------------------------------------------------------------------------
# small helpers

static func _quad_face(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, want: Vector3) -> void:
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


static func _ortho(d: Vector3, n: Vector3) -> Vector3:
	var e: Vector3 = d - n * d.dot(n)
	if e.length() < 0.000001:
		return Vector3.ZERO
	return e.normalized()


static func _spine_tangent(pl: PackedVector3Array, i: int) -> Vector3:
	var n: int = pl.size()
	var a: Vector3 = pl[maxi(i - 1, 0)]
	var b: Vector3 = pl[mini(i + 1, n - 1)]
	var d: Vector3 = b - a
	if d.length() < 0.000001:
		return Vector3.UP
	return d.normalized()


static func _frame(t: Vector3) -> Array:
	var tt: Vector3 = t.normalized()
	var ref := Vector3(0.0, 0.0, 1.0)
	if absf(tt.dot(ref)) > 0.9:
		ref = Vector3(1.0, 0.0, 0.0)
	var b1: Vector3 = ref.cross(tt).normalized()
	var b2: Vector3 = tt.cross(b1).normalized()
	return [b1, b2]


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


static func _key(keys: Array, t: float) -> float:
	var n: int = keys.size() - 1
	var f: float = clampf(t, 0.0, 1.0) * float(n)
	var i: int = int(floor(f))
	if i >= n:
		var last: float = keys[n]
		return last
	var u: float = f - float(i)
	var s: float = u * u * (3.0 - 2.0 * u)
	var va: float = keys[i]
	var vb: float = keys[i + 1]
	return lerpf(va, vb, s)


static func _c(scheme: Array, i: int) -> Color:
	var code: String = scheme[i]
	return Color(code)


static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _bone_texture(rng: RandomNumberGenerator) -> ImageTexture:
	# plaster / bone: four seamless bands plus fine grain, near white so
	# albedo_color tints it and triplanar runs it across every primitive
	var img: Image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	var p1: float = rng.randf_range(0.0, TAU)
	var p2: float = rng.randf_range(0.0, TAU)
	var p3: float = rng.randf_range(0.0, TAU)
	var p4: float = rng.randf_range(0.0, TAU)
	for y in range(TEX_SIZE):
		var fy: float = float(y) / float(TEX_SIZE)
		for x in range(TEX_SIZE):
			var fx: float = float(x) / float(TEX_SIZE)
			var val: float = 0.945
			val += 0.024 * sin(TAU * 3.0 * fx + TAU * 2.0 * fy + p1)
			val += 0.016 * sin(TAU * 7.0 * fx - TAU * 5.0 * fy + p2)
			val += 0.011 * sin(TAU * 13.0 * fy + TAU * 2.0 * fx + p3)
			val += 0.008 * sin(TAU * 19.0 * fx + TAU * 11.0 * fy + p4)
			val += rng.randf_range(-0.010, 0.010)
			var g: float = clampf(val, 0.62, 1.0)
			img.set_pixel(x, y, Color(g * 0.995, g * 0.988, g))
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
		var wb: AABB = cm.transform * cm.mesh.get_aabb()
		if first:
			box = wb
			first = false
		else:
			box = box.merge(wb)
	return box
