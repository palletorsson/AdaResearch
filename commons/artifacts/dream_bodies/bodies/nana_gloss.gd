extends RefCounted

## dream_bodies / nana_gloss — one dancing Nana, glossy, painted, mid-step.
##
## Reference: scratchpad/refs/saint_phalle.png (2048x536 panorama) — a crowd of
## Niki de Saint Phalle Nanas in a palm garden: enormous hips and thighs under a
## tiny round featureless head, thick tapering arms flung out, bodies moulded from
## nothing but overlapping ovoids and finished in a super-gloss white ground that
## carries flat painted pattern — a black maze/meander on the leftmost figure,
## a dark red mosaic of grout-lined cells on the big central back, and elsewhere
## scattered primary blobs, hearts, stripes and black contour marks.
##
## Reproduced, and how:
##   1. Ovoid body — a 26-link chain of squashed SphereMesh ellipsoids from crotch
##      to neck, radii keyed hips(widest) -> waist -> chest -> neck, with separate
##      belly, buttock and hip-shelf ovoids so the silhouette bulges the way the
##      reference does rather than tapering like a torso.
##   2. The dance — contrapposto built into the chain: pelvis rolls one way,
##      shoulders the other, the mass shifts over the standing leg, and the stack
##      twists about Y toward the raised arm. One arm is thrown up above the head,
##      the other flung down and out; one leg is lifted forward and out to the side.
##   3. Thick tapering limbs — every limb is a chain of overlapping spheres
##      (thigh 0.16 m at the hip), so the joins read as one poured glossy volume.
##   4. Small round head — a barely-ovoid sphere on the neck ovoid, no face beyond
##      two painted dots on some seeds, plus a bun at the back of the skull.
##   5. Painted skin — the ground is a 160x160 ImageTexture drawn pixel by pixel
##      in code and chosen by seed: a nested rectangular MEANDER labyrinth, a
##      jittered-Voronoi MOSAIC of dark red cells in white grout, or scattered
##      primary BLOBS with implicit-function hearts and black contour arcs. It is
##      applied with world triplanar so one pattern runs unbroken across the whole
##      chain of primitives, and a second, louder texture (stripes or blobs) is
##      painted onto one arm and one thigh the way the reference paints panels.
##   6. Super gloss — every skin material is roughness 0.08, clearcoat 1.0,
##      clearcoat_roughness 0.03. Enamel, not plaster.
##   7. Flat paint that is really geometry — 10..16 primary discs sit proud of the
##      surface by 2 mm, some on a slightly larger black disc for a contour, and
##      one heart (two lobes + a downward PrismMesh) is laid on the belly or hip.
##   8. A seed is an individual — pattern kind and phase, palette, hip width, bust,
##      head size, which arm rises, which leg lifts, lean, twist, stature.
##
## Given up: the crowd (this is one figure alone), the palm garden and plinth wall,
## the mirrored/silver figure's crumpled foil surface, the pattern following the
## body's own contours (triplanar is a projection, not a paint job), and the
## painted faces some Nanas carry.

const TEX: int = 160
const PLINTH_TOP: float = 0.055

const K_MAZE: int = 0
const K_MOSAIC: int = 1
const K_BLOBS: int = 2
const K_STRIPES: int = 3

# bold flat primaries, straight off the reference
const PRIMARIES: Array = [
	"#1B4FCF", "#F2C500", "#D9262C", "#1E9E4A", "#101010", "#C81E78", "#22B3C4",
]
const MOSAIC_BASES: Array = ["#5A122E", "#4A1030", "#5E1620", "#241A46"]


static func describe() -> String:
	return "A dancing Nana with enormous hips and a tiny round head, one arm thrown up and one leg lifted, her super-gloss white body painted with maze lines, mosaic cells and primary blobs."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- who this one is -----------------------------------------------------
	var kind: int = rng.randi_range(0, 2)
	var alt_kind: int = K_STRIPES
	if kind == K_BLOBS and rng.randf() < 0.5:
		alt_kind = K_MAZE
	elif kind != K_BLOBS and rng.randf() < 0.42:
		alt_kind = K_BLOBS
	var body_k: float = rng.randf_range(0.94, 1.02)
	var hip_w: float = rng.randf_range(0.96, 1.13)
	var bust: float = rng.randf_range(0.90, 1.16)
	var head_r: float = rng.randf_range(0.098, 0.118)
	var raise_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var hand_lift: float = rng.randf_range(0.95, 1.03)
	var arm_drop: float = rng.randf_range(0.94, 1.06)
	var twist: float = deg_to_rad(rng.randf_range(4.0, 12.0)) * raise_side
	var hip_roll: float = deg_to_rad(rng.randf_range(3.0, 7.0)) * raise_side
	var sh_roll: float = deg_to_rad(rng.randf_range(-9.0, -3.0)) * raise_side
	var leg_out: float = rng.randf_range(0.24, 0.31)
	var leg_fwd: float = rng.randf_range(0.36, 0.46)
	var n_dot: int = rng.randi_range(10, 16)
	var has_eyes: bool = rng.randf() < 0.5
	var head_yaw: float = deg_to_rad(rng.randf_range(-16.0, 16.0))

	# --- painted skins -------------------------------------------------------
	var tex_main: ImageTexture = _make_tex(kind, rng)
	var tex_alt: ImageTexture = _make_tex(alt_kind, rng)
	var mat_skin: StandardMaterial3D = _gloss_tex(tex_main, _tex_uv(kind), rng)
	var mat_alt: StandardMaterial3D = _gloss_tex(tex_alt, _tex_uv(alt_kind), rng)
	var mat_black: StandardMaterial3D = _gloss_flat(Color("#101010"))
	var flats: Array[StandardMaterial3D] = []
	for i in range(PRIMARIES.size()):
		flats.append(_gloss_flat(Color(str(PRIMARIES[i]))))
	var mat_plinth := StandardMaterial3D.new()
	mat_plinth.albedo_color = Color("#C8CBC4")
	mat_plinth.roughness = 0.82
	mat_plinth.metallic = 0.0

	# which limbs wear the loud panel
	var alt_arm: float = 1.0 if rng.randf() < 0.5 else -1.0
	var alt_leg: float = 1.0 if rng.randf() < 0.5 else -1.0

	# --- the ovoid chain, crotch to neck -------------------------------------
	var n_seg: int = 26
	var y_lo: float = 0.60
	var y_hi: float = 1.30
	var rx_keys: Array = [0.195, 0.300 * hip_w, 0.326 * hip_w, 0.246, 0.222, 0.240, 0.204, 0.088]
	var rz_keys: Array = [0.170, 0.236 * hip_w, 0.252 * hip_w, 0.208, 0.196, 0.206, 0.176, 0.082]
	var zo_keys: Array = [0.022, 0.040, 0.030, -0.006, -0.032, -0.020, 0.000, 0.006]

	var t_c: Array[Vector3] = []
	var t_b: Array[Basis] = []
	var t_rx: Array[float] = []
	var t_rz: Array[float] = []
	for i in range(n_seg):
		var t: float = float(i) / float(n_seg - 1)
		var rx: float = _key(rx_keys, t)
		var rz: float = _key(rz_keys, t)
		var zo: float = _key(zo_keys, t)
		var xo: float = raise_side * (0.032 * pow(1.0 - t, 1.6) - 0.024 * pow(t, 1.8))
		var yq: float = lerpf(y_lo, y_hi, t)
		var roll_a: float = lerpf(hip_roll, sh_roll, t)
		var bs: Basis = Basis(Vector3.UP, twist * t) * Basis(Vector3.BACK, roll_a)
		var c := Vector3(xo, yq, zo)
		t_c.append(c)
		t_b.append(bs)
		t_rx.append(rx)
		t_rz.append(rz)
		_ellipsoid(root, mat_skin, c, Vector3(rx, 0.056, rz), bs)

	# belly, buttocks, hip shelves — the bulges the chain alone will not give
	var i_belly: int = int(floor(float(n_seg - 1) * 0.34))
	var c_belly: Vector3 = t_c[i_belly]
	_ellipsoid(root, mat_skin, c_belly + Vector3(0.0, -0.01, -0.070), Vector3(0.196, 0.150, 0.176), Basis())
	var i_hip: int = int(floor(float(n_seg - 1) * 0.14))
	var c_hip: Vector3 = t_c[i_hip]
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		_ellipsoid(root, mat_skin, c_hip + Vector3(sd * 0.130 * hip_w, 0.012, 0.130), Vector3(0.185, 0.160, 0.180), Basis())
		_ellipsoid(root, mat_skin, c_hip + Vector3(sd * 0.196 * hip_w, -0.030, 0.010), Vector3(0.140, 0.145, 0.170), Basis())

	# breasts
	var i_bust: int = int(floor(float(n_seg - 1) * 0.72))
	var c_bust: Vector3 = t_c[i_bust]
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		var br: float = 0.112 * bust
		var bp: Vector3 = c_bust + Vector3(sd * 0.118, -0.012, -0.128)
		_ellipsoid(root, mat_skin, bp, Vector3(br, br * 0.96, br * 1.06), Basis())
		_ellipsoid(root, mat_black, bp + Vector3(sd * 0.012, 0.004, -br * 0.92), Vector3(0.026, 0.026, 0.020), Basis())

	# --- head ----------------------------------------------------------------
	var c_neck: Vector3 = t_c[n_seg - 1]
	var head_c: Vector3 = c_neck + Vector3(raise_side * 0.006, 0.118, -0.012)
	var head_b: Basis = Basis(Vector3.UP, head_yaw) * Basis(Vector3.BACK, sh_roll * 0.8)
	_ellipsoid(root, mat_skin, head_c, Vector3(head_r, head_r * 1.07, head_r * 1.02), head_b)
	_ellipsoid(root, mat_skin, head_c + head_b * Vector3(0.0, 0.052, 0.082), Vector3(0.046, 0.044, 0.044), Basis())
	if has_eyes:
		for s_i in range(2):
			var sd: float = -1.0 if s_i == 0 else 1.0
			var ep: Vector3 = head_c + head_b * Vector3(sd * head_r * 0.40, head_r * 0.20, -head_r * 0.92)
			_ellipsoid(root, mat_black, ep, Vector3(0.019, 0.024, 0.010), head_b)

	# --- arms ----------------------------------------------------------------
	var i_sh: int = int(floor(float(n_seg - 1) * 0.90))
	var c_sh: Vector3 = t_c[i_sh]
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		var mat_arm: StandardMaterial3D = mat_alt if sd == alt_arm else mat_skin
		var sh := c_sh + Vector3(sd * 0.186, 0.006, 0.004)
		if sd == raise_side:
			var el := sh + Vector3(sd * 0.150, 0.100 * hand_lift, -0.040)
			var wr := el + Vector3(sd * 0.075, 0.110 * hand_lift, 0.030)
			var hd := wr + Vector3(sd * 0.024, 0.040 * hand_lift, 0.006)
			_chain(root, mat_arm, sh, el, 0.090, 0.068, 8)
			_chain(root, mat_arm, el, wr, 0.068, 0.052, 7)
			_chain(root, mat_arm, wr, hd, 0.052, 0.046, 4)
			_ellipsoid(root, mat_arm, hd + Vector3(sd * 0.006, 0.028, 0.0), Vector3(0.056, 0.060, 0.044), Basis(Vector3.BACK, -sd * 0.25))
		else:
			var el2 := sh + Vector3(sd * 0.160, -0.155 * arm_drop, -0.052)
			var wr2 := el2 + Vector3(sd * 0.078, -0.150 * arm_drop, 0.028)
			var hd2 := wr2 + Vector3(sd * 0.026, -0.072 * arm_drop, -0.008)
			_chain(root, mat_arm, sh, el2, 0.090, 0.068, 8)
			_chain(root, mat_arm, el2, wr2, 0.068, 0.052, 7)
			_chain(root, mat_arm, wr2, hd2, 0.052, 0.046, 4)
			_ellipsoid(root, mat_arm, hd2 + Vector3(sd * 0.010, -0.032, -0.004), Vector3(0.058, 0.064, 0.044), Basis(Vector3.BACK, sd * 0.30))

	# --- legs ----------------------------------------------------------------
	var stand: float = raise_side
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		var mat_leg: StandardMaterial3D = mat_alt if sd == alt_leg else mat_skin
		var hip_j := Vector3(sd * 0.168 * hip_w, 0.690, 0.020)
		if sd == stand:
			var knee := Vector3(sd * 0.152, 0.372, -0.008)
			var ankle := Vector3(sd * 0.142, 0.104, 0.014)
			_chain(root, mat_leg, hip_j, knee, 0.164 * hip_w, 0.104, 9)
			_chain(root, mat_leg, knee, ankle, 0.104, 0.062, 8)
			_ellipsoid(root, mat_leg, Vector3(sd * 0.142, 0.056, -0.046), Vector3(0.078, 0.056, 0.118), Basis(Vector3.UP, sd * 0.16))
		else:
			var knee2 := Vector3(sd * leg_out, 0.548, -leg_fwd * 0.52)
			var ankle2 := Vector3(sd * (leg_out + 0.030), 0.362, -leg_fwd)
			var toe := Vector3(sd * (leg_out + 0.036), 0.310, -leg_fwd - 0.086)
			_chain(root, mat_leg, hip_j, knee2, 0.164 * hip_w, 0.106, 9)
			_chain(root, mat_leg, knee2, ankle2, 0.106, 0.064, 8)
			_ellipsoid(root, mat_leg, toe, Vector3(0.070, 0.052, 0.086), Basis(Vector3.RIGHT, -0.45))

	# --- flat paint that is really geometry ----------------------------------
	for _d in range(n_dot):
		var iq: int = rng.randi_range(2, n_seg - 4)
		var ang: float = rng.randf_range(-2.55, 2.55)
		var rx2: float = t_rx[iq]
		var rz2: float = t_rz[iq]
		var bs2: Basis = t_b[iq]
		var loc := Vector3(rx2 * sin(ang), 0.0, rz2 * cos(ang))
		var nrm: Vector3 = (bs2 * Vector3(sin(ang) / rx2, 0.0, cos(ang) / rz2)).normalized()
		var pos: Vector3 = t_c[iq] + bs2 * loc + Vector3(0.0, rng.randf_range(-0.020, 0.020), 0.0)
		var rr: float = rng.randf_range(0.042, 0.086)
		var col_i: int = rng.randi_range(0, flats.size() - 1)
		if rng.randf() < 0.42:
			_disc(root, mat_black, pos + nrm * 0.001, nrm, rr * 1.24, 0.010)
		_disc(root, flats[col_i], pos + nrm * 0.004, nrm, rr, 0.011)

	# one heart, laid on the belly or a hip
	var i_heart: int = i_belly if rng.randf() < 0.6 else i_hip + 2
	i_heart = clampi(i_heart, 2, n_seg - 4)
	var face_back: float = 0.0 if rng.randf() < 0.7 else PI
	var ha: float = rng.randf_range(-0.9, 0.9) + face_back
	var hrx: float = t_rx[i_heart]
	var hrz: float = t_rz[i_heart]
	var hbs: Basis = t_b[i_heart]
	var hnrm: Vector3 = (hbs * Vector3(sin(ha) / hrx, 0.0, cos(ha) / hrz)).normalized()
	var hpos: Vector3 = t_c[i_heart] + hbs * Vector3(hrx * sin(ha), 0.0, hrz * cos(ha))
	var heart_mat: StandardMaterial3D = flats[2] if rng.randf() < 0.6 else flats[0]
	_heart(root, heart_mat, hpos + hnrm * 0.004, hnrm, rng.randf_range(0.115, 0.165))

	# --- stature, then the measured settle -----------------------------------
	_rescale(root, body_k, Vector3.ZERO)

	var box: AABB = _union_aabb(root)
	var kx: float = 1.20 / maxf(box.size.x, 0.001)
	var kz: float = 1.20 / maxf(box.size.z, 0.001)
	var ky: float = (1.68 - PLINTH_TOP) / maxf(box.size.y, 0.001)
	var kfit: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kfit < 1.0:
		_rescale(root, kfit, Vector3.ZERO)
		box = _union_aabb(root)

	var centre: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-centre.x, PLINTH_TOP - box.position.y, -centre.z)
	_shift(root, shift)
	box = _union_aabb(root)
	if box.position.y < 0.0:
		_shift(root, Vector3(0.0, -box.position.y, 0.0))
		box = _union_aabb(root)

	var plinth := BoxMesh.new()
	plinth.size = Vector3(minf(1.20, box.size.x + 0.10), PLINTH_TOP, minf(1.20, box.size.z + 0.10))
	var pm: MeshInstance3D = _add(root, plinth, mat_plinth)
	pm.transform = Transform3D(Basis(), Vector3(0.0, PLINTH_TOP * 0.5, 0.0))


# ---------------------------------------------------------------------------
# geometry helpers

static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _ellipsoid(root: Node3D, mat: StandardMaterial3D, c: Vector3, r: Vector3, b: Basis) -> MeshInstance3D:
	var sph := SphereMesh.new()
	sph.radius = 1.0
	sph.height = 2.0
	sph.radial_segments = 22
	sph.rings = 12
	var mi: MeshInstance3D = _add(root, sph, mat)
	# NOTE Basis.scaled() is diag * B (parent frame), which on a sphere cancels the
	# rotation outright. The squash has to happen in the ellipsoid's OWN frame.
	mi.transform = Transform3D(b * _diag(r), c)
	return mi


static func _diag(r: Vector3) -> Basis:
	return Basis(Vector3(r.x, 0.0, 0.0), Vector3(0.0, r.y, 0.0), Vector3(0.0, 0.0, r.z))


static func _chain(root: Node3D, mat: StandardMaterial3D, a: Vector3, b: Vector3, r0: float, r1: float, n: int) -> void:
	var steps: int = maxi(n, 2)
	for i in range(steps):
		var t: float = float(i) / float(steps - 1)
		var p: Vector3 = a.lerp(b, t)
		var r: float = lerpf(r0, r1, t)
		_ellipsoid(root, mat, p, Vector3(r, r, r), Basis())


static func _disc(root: Node3D, mat: StandardMaterial3D, p: Vector3, nrm: Vector3, r: float, th: float) -> void:
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = th
	cyl.radial_segments = 20
	cyl.rings = 1
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(nrm), p)


static func _heart(root: Node3D, mat: StandardMaterial3D, p: Vector3, nrm: Vector3, s: float) -> void:
	var zc: Vector3 = nrm.normalized()
	var yc: Vector3 = Vector3.UP - zc * Vector3.UP.dot(zc)
	if yc.length() < 0.001:
		yc = Vector3.FORWARD - zc * Vector3.FORWARD.dot(zc)
	yc = yc.normalized()
	var xc: Vector3 = yc.cross(zc).normalized()
	var hb := Basis(xc, yc, zc)
	var th: float = 0.014
	for sgn in [-1.0, 1.0]:
		var sf: float = sgn
		var lobe: Vector3 = p + hb * Vector3(sf * s * 0.29, s * 0.30, 0.0)
		var sph := SphereMesh.new()
		sph.radius = 1.0
		sph.height = 2.0
		sph.radial_segments = 18
		sph.rings = 10
		var mi: MeshInstance3D = _add(root, sph, mat)
		mi.transform = Transform3D(hb * _diag(Vector3(s * 0.36, s * 0.34, th)), lobe)
	var pr := PrismMesh.new()
	pr.size = Vector3(s * 1.16, s * 0.86, th * 2.0)
	var pmi: MeshInstance3D = _add(root, pr, mat)
	pmi.transform = Transform3D(hb * Basis(Vector3.BACK, PI), p + hb * Vector3(0.0, s * 0.02, 0.0))


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
	if n <= 0:
		return float(keys[0])
	var f: float = clampf(t, 0.0, 1.0) * float(n)
	var i: int = int(floor(f))
	if i >= n:
		return float(keys[n])
	var u: float = f - float(i)
	var sm: float = u * u * (3.0 - 2.0 * u)
	var a: float = float(keys[i])
	var b: float = float(keys[i + 1])
	return lerpf(a, b, sm)


static func _rescale(root: Node3D, k: float, pivot: Vector3) -> void:
	if absf(k - 1.0) < 0.0001:
		return
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		var tf: Transform3D = cm.transform
		cm.transform = Transform3D(tf.basis.scaled(Vector3(k, k, k)), pivot + (tf.origin - pivot) * k)


static func _shift(root: Node3D, v: Vector3) -> void:
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + v)


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
# materials

static func _gloss_flat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.06
	m.metallic = 0.0
	m.clearcoat_enabled = true
	m.clearcoat = 1.0
	m.clearcoat_roughness = 0.03
	return m


static func _gloss_tex(tex: ImageTexture, uv: float, rng: RandomNumberGenerator) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 1.0, 1.0)
	m.albedo_texture = tex
	m.roughness = 0.08
	m.metallic = 0.0
	m.clearcoat_enabled = true
	m.clearcoat = 1.0
	m.clearcoat_roughness = 0.03
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 1.6
	m.uv1_scale = Vector3(uv, uv, uv)
	m.uv1_offset = Vector3(rng.randf(), rng.randf(), rng.randf())
	return m


static func _tex_uv(kind: int) -> float:
	if kind == K_MOSAIC:
		return 1.85
	if kind == K_BLOBS:
		return 1.15
	if kind == K_STRIPES:
		return 1.30
	return 1.50


# ---------------------------------------------------------------------------
# painted skins — every pixel drawn in code

static func _make_tex(kind: int, rng: RandomNumberGenerator) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	if kind == K_MOSAIC:
		var base_i: int = rng.randi_range(0, MOSAIC_BASES.size() - 1)
		_paint_mosaic(img, rng, Color(str(MOSAIC_BASES[base_i])))
	elif kind == K_BLOBS:
		_paint_blobs(img, rng)
	elif kind == K_STRIPES:
		_paint_stripes(img, rng)
	else:
		_paint_maze(img, rng)
	return ImageTexture.create_from_image(img)


static func _put(img: Image, x: int, y: int, c: Color) -> void:
	img.set_pixel(posmod(x, TEX), posmod(y, TEX), c)


static func _fill(img: Image, c: Color) -> void:
	for y in range(TEX):
		for x in range(TEX):
			img.set_pixel(x, y, c)


# --- maze / meander ---------------------------------------------------------

static func _rot_put(img: Image, ox: int, oy: int, s: int, rot: int, x: int, y: int, c: Color) -> void:
	var rx: int = x
	var ry: int = y
	if rot == 1:
		rx = s - 1 - y
		ry = x
	elif rot == 2:
		rx = s - 1 - x
		ry = s - 1 - y
	elif rot == 3:
		rx = y
		ry = s - 1 - x
	_put(img, ox + rx, oy + ry, c)


static func _cell_bar(img: Image, ox: int, oy: int, s: int, rot: int, x0: int, y0: int, x1: int, y1: int, th: int, c: Color) -> void:
	var xa: int = mini(x0, x1)
	var xb: int = maxi(x0, x1) + th
	var ya: int = mini(y0, y1)
	var yb: int = maxi(y0, y1) + th
	for y in range(ya, yb):
		for x in range(xa, xb):
			if x < 0 or y < 0 or x >= s or y >= s:
				continue
			_rot_put(img, ox, oy, s, rot, x, y, c)


static func _paint_maze(img: Image, rng: RandomNumberGenerator) -> void:
	_fill(img, Color(0.965, 0.960, 0.950))
	var ink := Color(0.055, 0.050, 0.055)
	var s: int = 32
	var cells: int = TEX / s
	var th: int = 3
	var gap: int = 6
	for cy in range(cells):
		for cx in range(cells):
			var ox: int = cx * s
			var oy: int = cy * s
			var rot: int = rng.randi_range(0, 3)
			var rings: int = rng.randi_range(2, 3)
			for j in range(rings):
				var d: int = 1 + j * (th + gap)
				var e: int = s - 1 - d - th
				if e - d < th * 2:
					break
				if j % 2 == 0:
					_cell_bar(img, ox, oy, s, rot, d, d, d, e, th, ink)
					_cell_bar(img, ox, oy, s, rot, d, d, e, d, th, ink)
					_cell_bar(img, ox, oy, s, rot, e, d, e, maxi(d, e - gap), th, ink)
				else:
					_cell_bar(img, ox, oy, s, rot, e, d, e, e, th, ink)
					_cell_bar(img, ox, oy, s, rot, d, e, e, e, th, ink)
					_cell_bar(img, ox, oy, s, rot, d, mini(e, d + gap), d, e, th, ink)
			# the seam line between cells, so the labyrinth reads continuous
			if rng.randf() < 0.7:
				_cell_bar(img, ox, oy, s, rot, 0, s - th, s - th, s - th, th, ink)


# --- mosaic -----------------------------------------------------------------

static func _paint_mosaic(img: Image, rng: RandomNumberGenerator, base: Color) -> void:
	var cols: int = 13
	var rows: int = 16
	var cw: float = float(TEX) / float(cols)
	var chh: float = float(TEX) / float(rows)
	var jx: Array = []
	var jy: Array = []
	var tint: Array = []
	for i in range(cols * rows):
		jx.append(rng.randf_range(-0.30, 0.30))
		jy.append(rng.randf_range(-0.22, 0.22))
		tint.append(rng.randf_range(0.78, 1.22))
	var grout := Color(0.955, 0.950, 0.945)
	for y in range(TEX):
		for x in range(TEX):
			var px: float = float(x) + 0.5
			var py: float = float(y) + 0.5
			var c0: int = int(floor(px / cw))
			var r0: int = int(floor(py / chh))
			var d1: float = 1.0e9
			var d2: float = 1.0e9
			var best: int = 0
			for rr in range(r0 - 1, r0 + 2):
				var rw: int = posmod(rr, rows)
				for cc in range(c0 - 1, c0 + 2):
					var cwp: int = posmod(cc, cols)
					var idx: int = rw * cols + cwp
					var gx: float = (float(cc) + 0.5 + float(jx[idx])) * cw
					var gy: float = (float(rr) + 0.5 + float(jy[idx])) * chh
					var dx: float = px - gx
					var dy: float = (py - gy) * 1.10
					var dd: float = dx * dx + dy * dy
					if dd < d1:
						d2 = d1
						d1 = dd
						best = idx
					elif dd < d2:
						d2 = dd
			var edge: float = sqrt(maxf(d2, 0.0)) - sqrt(maxf(d1, 0.0))
			if edge < 2.6:
				img.set_pixel(x, y, grout)
			else:
				var k: float = float(tint[best])
				var shade: float = clampf(k * (0.90 + 0.16 * clampf(edge / 7.0, 0.0, 1.0)), 0.45, 1.45)
				img.set_pixel(x, y, Color(clampf(base.r * shade, 0.0, 1.0), clampf(base.g * shade, 0.0, 1.0), clampf(base.b * shade, 0.0, 1.0)))


# --- blobs, hearts, contour marks -------------------------------------------

static func _blob(img: Image, cx: float, cy: float, a: float, b: float, ang: float, c: Color) -> void:
	var ca: float = cos(ang)
	var sa: float = sin(ang)
	var rad: int = int(ceil(maxf(a, b))) + 2
	for y in range(-rad, rad + 1):
		for x in range(-rad, rad + 1):
			var dx: float = float(x)
			var dy: float = float(y)
			var u: float = (dx * ca + dy * sa) / maxf(a, 0.5)
			var v: float = (-dx * sa + dy * ca) / maxf(b, 0.5)
			if u * u + v * v <= 1.0:
				_put(img, int(round(cx)) + x, int(round(cy)) + y, c)


static func _heart_px(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	var rad: int = int(ceil(r * 1.40)) + 2
	for y in range(-rad, rad + 1):
		for x in range(-rad, rad + 1):
			var xf: float = float(x) / r
			var yf: float = -float(y) / r
			var q: float = xf * xf + yf * yf - 1.0
			if q * q * q - xf * xf * (yf * yf * yf) <= 0.0:
				_put(img, int(round(cx)) + x, int(round(cy)) + y, c)


static func _ring(img: Image, cx: float, cy: float, r: float, th: float, a0: float, a1: float, c: Color) -> void:
	var steps: int = int(ceil((a1 - a0) * r * 2.2)) + 6
	for i in range(steps):
		var t: float = float(i) / float(steps - 1)
		var ang: float = lerpf(a0, a1, t)
		var bx: float = cx + cos(ang) * r
		var by: float = cy + sin(ang) * r
		var ti: int = int(ceil(th))
		for y in range(-ti, ti + 1):
			for x in range(-ti, ti + 1):
				if float(x * x + y * y) <= th * th:
					_put(img, int(round(bx)) + x, int(round(by)) + y, c)


static func _paint_blobs(img: Image, rng: RandomNumberGenerator) -> void:
	_fill(img, Color(0.968, 0.964, 0.955))
	var ink := Color(0.055, 0.050, 0.055)
	var n: int = rng.randi_range(16, 22)
	for i in range(n):
		var cx: float = rng.randf_range(0.0, float(TEX))
		var cy: float = rng.randf_range(0.0, float(TEX))
		var col_i: int = rng.randi_range(0, PRIMARIES.size() - 1)
		var c: Color = Color(str(PRIMARIES[col_i]))
		var a: float = rng.randf_range(9.0, 24.0)
		var b: float = a * rng.randf_range(0.45, 1.0)
		var ang: float = rng.randf_range(0.0, PI)
		if rng.randf() < 0.35:
			_blob(img, cx, cy, a + 2.5, b + 2.5, ang, ink)
		_blob(img, cx, cy, a, b, ang, c)
	var n_h: int = rng.randi_range(2, 4)
	for i in range(n_h):
		var hx: float = rng.randf_range(0.0, float(TEX))
		var hy: float = rng.randf_range(0.0, float(TEX))
		var hr: float = rng.randf_range(10.0, 18.0)
		var hc: Color = Color(str(PRIMARIES[2])) if rng.randf() < 0.6 else Color(str(PRIMARIES[5]))
		_heart_px(img, hx, hy, hr + 2.0, ink)
		_heart_px(img, hx, hy, hr, hc)
	var n_a: int = rng.randi_range(3, 6)
	for i in range(n_a):
		var ax: float = rng.randf_range(0.0, float(TEX))
		var ay: float = rng.randf_range(0.0, float(TEX))
		var ar: float = rng.randf_range(14.0, 34.0)
		var a0: float = rng.randf_range(0.0, TAU)
		_ring(img, ax, ay, ar, rng.randf_range(1.6, 3.2), a0, a0 + rng.randf_range(1.2, 3.4), ink)


# --- stripes ----------------------------------------------------------------

static func _paint_stripes(img: Image, rng: RandomNumberGenerator) -> void:
	var pal: Array = []
	var bands: int = rng.randi_range(5, 8)
	for i in range(bands):
		if rng.randf() < 0.34:
			pal.append(Color(0.968, 0.964, 0.955))
		else:
			var ci: int = rng.randi_range(0, PRIMARIES.size() - 1)
			pal.append(Color(str(PRIMARIES[ci])))
	var bw: float = float(TEX) / float(bands)
	var amp: float = rng.randf_range(3.0, 13.0)
	var freq: float = float(rng.randi_range(1, 3)) * TAU / float(TEX)
	var ink := Color(0.055, 0.050, 0.055)
	for y in range(TEX):
		var wob: float = amp * sin(float(y) * freq)
		for x in range(TEX):
			var u: float = float(x) + wob
			var bi: int = posmod(int(floor(u / bw)), bands)
			var frac: float = u / bw - floor(u / bw)
			var c: Color = pal[bi]
			if frac < 0.055 or frac > 0.945:
				c = ink
			img.set_pixel(x, y, c)
