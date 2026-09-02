extends RefCounted

## dream_bodies / mosaic_body — one half-kneeling figure skinned in mosaic tesserae.
##
## Reference: scratchpad/refs/pompeii_mosaic.png (2048x536 panorama) — a huddle of
## smooth, faceless humanoids sitting and leaning on one another, every body sheathed
## in irregular flat tiles with pale grout between them: violet, terracotta on cream,
## green shot with blue, silver glitter, black-and-white. The heads are smooth hoods
## with a shallow nose ridge and no eyes or mouth; the tiling runs unbroken over the
## shoulders, down the spine and across the thighs, and a few tiles stand proud.
##
## Reproduced, and how:
##   1. ONE figure lifted out of the huddle, half-kneeling — right knee down on the
##      floor with the shin laid back, left knee up with the foot planted forward,
##      the torso leaning forward and rolling toward the reaching side.
##   2. The gesture of the group: the left hand is braced flat on its own raised knee
##      and the right arm reaches out over the shoulder of a companion who is not
##      there. Both elbows come from a two-bone reach solve, so the hand actually
##      lands on the knee whatever lean the seed dealt.
##   3. Mosaic skin — a 192x192 ImageTexture painted in code: a wrapped, jittered
##      Voronoi lattice with an F2-F1 grout line, tile colour dealt per cell from a
##      weighted palette deck, per-tile brightness 0.88..1.10, a shallow dome shade
##      and a bevel gradient inside each tile so the tesserae read as thick glass.
##   4. Grout that crosses the joints — world triplanar UVs, so one lattice runs over
##      the sphere/capsule seams instead of restarting inside every primitive.
##   5. Five palettes off the reference (violet, terracotta-on-cream, green-blue,
##      silver glitter, black-and-white), each with its own deck weights, grout
##      colour, metallic and glitter density; a second accent-heavy deck paints a
##      colour FIELD across chest, one thigh, one arm and the floor slab, the way the
##      green figure carries a blue back and the cream one carries red patches.
##   6. Actual raised tesserae — 33..56 thin flat boxes laid on shoulders, spine,
##      hips, thighs, upper arms and hood, each snapped to the surface normal with a
##      random yaw, so the skin reads as tiled rather than printed.
##   7. A smooth hood head — egg skull, cranium, jaw, a flattened brow band and a low
##      nose ridge, no eyes, no mouth; a torus collar marks the hood rim.
##   8. The floor it kneels on: a SurfaceTool slab with an irregular chipped outline,
##      tiled in the accent field — a broken piece of mosaic pavement.
##
## Given up: the huddle itself (neighbours, overlapping arms, the hands resting on
## other shoulders), the garden behind them, the true polygon-by-polygon shard cuts
## of real smalti (the lattice is Voronoi, not hand-nipped), and the mirror-glass
## specular of the silver figure, which stands in as metallic plus painted speckle.

const TEX_SIZE: int = 192
const GROUND: float = 0.055
const N_SPINE: int = 11
const R_SPINE: Array = [0.148, 0.132, 0.114, 0.104, 0.106, 0.118, 0.134, 0.146, 0.148, 0.130, 0.094]
const SX: Array = [1.14, 1.10, 1.06, 1.04, 1.08, 1.16, 1.26, 1.34, 1.38, 1.22, 1.00]
const SZ: Array = [0.90, 0.88, 0.84, 0.82, 0.80, 0.78, 0.78, 0.76, 0.74, 0.78, 0.90]

# tiles: [light, mid, dark, accent, pale]
const SCHEMES: Array = [
	{
		"tiles": ["#C0A3E4", "#9A6BCB", "#6E4098", "#D9C4E8", "#F4EEF7"],
		"main": [8, 6, 3, 2, 2], "patch": [2, 2, 2, 6, 6],
		"grout": "#F0EAF3", "glitter": 0.0, "metal": 0.0, "rough": 0.28,
	},
	{
		"tiles": ["#EBD3B8", "#C8663F", "#9A3A20", "#F3E5D3", "#FBF4EA"],
		"main": [8, 4, 2, 5, 3], "patch": [3, 8, 4, 3, 2],
		"grout": "#F6EEE2", "glitter": 0.0, "metal": 0.0, "rough": 0.32,
	},
	{
		"tiles": ["#3E9E74", "#2E7D5B", "#3A6FB0", "#1F4A80", "#CFE6DA"],
		"main": [7, 6, 3, 1, 2], "patch": [2, 2, 7, 4, 2],
		"grout": "#E9F1EA", "glitter": 0.0, "metal": 0.05, "rough": 0.26,
	},
	{
		"tiles": ["#C6CBD2", "#9BA3AE", "#767E8A", "#E8EDF2", "#FFFFFF"],
		"main": [7, 5, 3, 4, 2], "patch": [4, 3, 2, 6, 4],
		"grout": "#EDEFF2", "glitter": 0.055, "metal": 0.45, "rough": 0.18,
	},
	{
		"tiles": ["#141418", "#F2F1EB", "#3B3B42", "#D8D6CE", "#FFFFFF"],
		"main": [8, 5, 3, 2, 1], "patch": [3, 8, 2, 3, 2],
		"grout": "#EFEDE6", "glitter": 0.0, "metal": 0.0, "rough": 0.24,
	},
]


static func describe() -> String:
	return "A half-kneeling faceless figure sheathed in code-painted mosaic tesserae with pale grout, one hand braced on its raised knee and the other reaching over an absent companion's shoulder."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var scheme: Dictionary = SCHEMES[rng.randi_range(0, SCHEMES.size() - 1)]
	var tiles: Array = scheme["tiles"]
	var w_main: Array = scheme["main"]
	var w_patch: Array = scheme["patch"]
	var grout: Color = Color(str(scheme["grout"]))
	var glitter: float = float(scheme["glitter"])
	var metal: float = float(scheme["metal"])
	var rough: float = float(scheme["rough"])

	# --- individual parameters ---------------------------------------------
	var body_k: float = rng.randf_range(0.94, 1.08)
	var lean_fwd: float = deg_to_rad(rng.randf_range(9.0, 19.0))
	var lean_side: float = deg_to_rad(rng.randf_range(3.0, 9.0))
	var twist: float = deg_to_rad(rng.randf_range(-7.0, 15.0))
	var head_yaw: float = deg_to_rad(rng.randf_range(10.0, 26.0))
	var head_pitch: float = deg_to_rad(rng.randf_range(0.0, 9.0))
	var reach_out: float = rng.randf_range(0.30, 0.38)
	var reach_drop: float = rng.randf_range(0.18, 0.28)
	var patch_lo: int = rng.randi_range(4, 6)
	var patch_hi: int = patch_lo + rng.randi_range(2, 4)
	var tex_scale: float = rng.randf_range(2.05, 2.60)
	var n_cells: int = rng.randi_range(13, 16)

	# --- textures and materials ---------------------------------------------
	var deck_main: Array = _deck(tiles, w_main)
	var deck_patch: Array = _deck(tiles, w_patch)
	var tex_skin: ImageTexture = _mosaic_texture(rng, n_cells, deck_main, grout, glitter, 1.18, 0.40)
	var tex_patch: ImageTexture = _mosaic_texture(rng, n_cells - 3, deck_patch, grout, glitter, 0.86, 0.44)

	var mat_skin: StandardMaterial3D = _skin_mat(tex_skin, tex_scale, rough, metal)
	var mat_field: StandardMaterial3D = _skin_mat(tex_patch, tex_scale * 0.86, rough, metal)
	var mat_slab: StandardMaterial3D = _skin_mat(tex_patch, tex_scale * 1.35, 0.62, 0.0)

	var tile_mats: Array = []
	for i in range(tiles.size()):
		var hexs: String = str(tiles[i])
		tile_mats.append(_flat_mat(Color(hexs), rough * 0.8, metal))
	var deck_idx: Array = _deck_index(w_main)

	# --- spine: pelvis to neck base, leaning ---------------------------------
	var pelvis := Vector3(0.0, 0.540 + GROUND, 0.02)
	var spine_len: float = 0.555
	var pts: Array = []
	var frames: Array = []
	var radii: Array = []
	var p: Vector3 = pelvis
	for i in range(N_SPINE):
		var t: float = float(i) / float(N_SPINE - 1)
		var fb: Basis = _spine_basis(t, lean_fwd, lean_side, twist)
		pts.append(p)
		frames.append(fb)
		var r0: float = R_SPINE[i]
		radii.append(r0 * rng.randf_range(0.97, 1.04))
		if i < N_SPINE - 1:
			p = p + fb.y * (spine_len / float(N_SPINE - 1))

	for i in range(N_SPINE):
		var q: Vector3 = pts[i]
		var fb: Basis = frames[i]
		var r: float = radii[i]
		var sxv: float = SX[i]
		var szv: float = SZ[i]
		var sph := SphereMesh.new()
		sph.radius = r
		sph.height = r * 2.0
		sph.radial_segments = 22
		sph.rings = 12
		var use_field: bool = i >= patch_lo and i <= patch_hi
		var mat_seg: StandardMaterial3D = mat_field if use_field else mat_skin
		var mi: MeshInstance3D = _add(root, sph, mat_seg)
		mi.transform = Transform3D(_scaled(fb, Vector3(sxv, 1.0, szv)), q)

	# --- pelvis, hips, glutes -----------------------------------------------
	var fb0: Basis = frames[0]
	var hip_r := Vector3(0.115, 0.513 + GROUND, 0.038)
	var hip_l := Vector3(-0.115, 0.513 + GROUND, 0.038)
	_ball(root, pelvis + Vector3(0.0, -0.06, 0.05), 0.125, Vector3(1.18, 0.92, 0.92), fb0, mat_skin)
	_ball(root, hip_r + Vector3(0.02, -0.03, 0.02), 0.100, Vector3(1.0, 0.94, 0.94), fb0, mat_skin)
	_ball(root, hip_l + Vector3(-0.02, -0.03, 0.02), 0.100, Vector3(1.0, 0.94, 0.94), fb0, mat_skin)

	# --- legs ----------------------------------------------------------------
	var knee_r := Vector3(0.152, 0.082 + GROUND, -0.012)
	var ankle_r := Vector3(0.152, 0.069 + GROUND, 0.330)
	var toe_r := Vector3(0.152, 0.059 + GROUND, 0.428)
	var knee_l := Vector3(-0.180, 0.465 + GROUND, -0.350)
	var ankle_l := Vector3(-0.192, 0.117 + GROUND, -0.288)
	var heel_l := Vector3(-0.188, 0.055 + GROUND, -0.240)
	var toe_l := Vector3(-0.198, 0.052 + GROUND, -0.398)

	var mat_thigh_r: StandardMaterial3D = mat_skin
	var mat_thigh_l: StandardMaterial3D = mat_field if rng.randf() < 0.55 else mat_skin

	_limb(root, hip_r, knee_r, 0.096, mat_thigh_r)
	_ball(root, knee_r, 0.080, Vector3(1.0, 1.0, 1.0), Basis(), mat_skin)
	_limb(root, knee_r, ankle_r, 0.066, mat_skin)
	_ball(root, ankle_r, 0.060, Vector3(1.0, 1.0, 1.0), Basis(), mat_skin)
	_limb(root, ankle_r, toe_r, 0.056, mat_skin)

	_limb(root, hip_l, knee_l, 0.096, mat_thigh_l)
	_ball(root, knee_l, 0.086, Vector3(1.0, 1.0, 1.0), Basis(), mat_skin)
	_limb(root, knee_l, ankle_l, 0.066, mat_skin)
	_ball(root, ankle_l, 0.058, Vector3(1.0, 1.0, 1.0), Basis(), mat_skin)
	_limb(root, heel_l, toe_l, 0.052, mat_skin)
	_ball(root, heel_l, 0.050, Vector3(1.0, 1.0, 1.0), Basis(), mat_skin)

	# --- shoulders and arms --------------------------------------------------
	var i_sh: int = 8
	var p_sh: Vector3 = pts[i_sh]
	var fb_sh: Basis = frames[i_sh]
	var r_sh: float = radii[i_sh]
	var half_w: float = r_sh * SX[i_sh] * 0.86
	var sh_r: Vector3 = p_sh + fb_sh * Vector3(half_w, 0.030, 0.0)
	var sh_l: Vector3 = p_sh + fb_sh * Vector3(-half_w, 0.030, 0.0)
	var mat_yoke: StandardMaterial3D = mat_field if patch_lo <= i_sh and i_sh <= patch_hi else mat_skin
	_limb(root, sh_l, sh_r, 0.062, mat_yoke)
	_ball(root, sh_r, 0.086, Vector3(1.0, 1.0, 1.0), Basis(), mat_skin)
	_ball(root, sh_l, 0.086, Vector3(1.0, 1.0, 1.0), Basis(), mat_skin)

	var upper_len: float = 0.300
	var fore_len: float = 0.278

	# right arm: reaching forward over an absent shoulder
	var target_r: Vector3 = sh_r + fb_sh * Vector3(0.055, -reach_drop, -reach_out)
	var pole_r: Vector3 = (fb_sh * Vector3(0.85, -0.25, 0.45)).normalized()
	var chain_r: Array = _arm_chain(sh_r, target_r, upper_len, fore_len, pole_r)
	var elbow_r: Vector3 = chain_r[0]
	var wrist_r: Vector3 = chain_r[1]
	var mat_arm_r: StandardMaterial3D = mat_field if rng.randf() < 0.45 else mat_skin
	_limb(root, sh_r, elbow_r, 0.062, mat_arm_r)
	_ball(root, elbow_r, 0.055, Vector3(1.0, 1.0, 1.0), Basis(), mat_skin)
	_limb(root, elbow_r, wrist_r, 0.049, mat_skin)
	var fwd_r: Vector3 = (wrist_r - elbow_r).normalized()
	_hand(root, wrist_r, fwd_r, (fb_sh * Vector3(0.15, 1.0, 0.1)).normalized(), mat_skin, rng)

	# left arm: hand braced flat on the raised knee
	var target_l: Vector3 = knee_l + Vector3(0.005, 0.128, 0.066)
	var pole_l: Vector3 = Vector3(-0.90, -0.10, 0.42).normalized()
	var chain_l: Array = _arm_chain(sh_l, target_l, upper_len, fore_len, pole_l)
	var elbow_l: Vector3 = chain_l[0]
	var wrist_l: Vector3 = chain_l[1]
	_limb(root, sh_l, elbow_l, 0.062, mat_skin)
	_ball(root, elbow_l, 0.055, Vector3(1.0, 1.0, 1.0), Basis(), mat_skin)
	_limb(root, elbow_l, wrist_l, 0.049, mat_skin)
	var brace_target: Vector3 = knee_l + Vector3(0.0, 0.075, -0.055)
	var fwd_l: Vector3 = (brace_target - wrist_l).normalized()
	_hand(root, wrist_l, fwd_l, Vector3(-0.12, 0.98, 0.15).normalized(), mat_skin, rng)

	# --- hooded head, no face ------------------------------------------------
	var neck_base: Vector3 = pts[N_SPINE - 1]
	var fb_n: Basis = frames[N_SPINE - 1]
	var hb: Basis = fb_n * Basis(Vector3.UP, head_yaw) * Basis(Vector3.RIGHT, -head_pitch)
	var h_c: Vector3 = neck_base + fb_n.y * 0.185
	_limb(root, neck_base + fb_n.y * 0.01, h_c - hb.y * 0.085, 0.062, mat_skin)
	_ball(root, h_c, 0.108, Vector3(0.90, 1.18, 1.00), hb, mat_skin)
	_ball(root, h_c + hb * Vector3(0.0, 0.020, 0.052), 0.084, Vector3(1.02, 0.96, 0.92), hb, mat_skin)
	_ball(root, h_c + hb * Vector3(0.0, -0.020, -0.050), 0.080, Vector3(0.96, 1.00, 0.74), hb, mat_skin)
	_ball(root, h_c + hb * Vector3(0.0, -0.078, -0.028), 0.062, Vector3(0.98, 0.82, 1.06), hb, mat_skin)
	_ball(root, h_c + hb * Vector3(0.0, 0.012, -0.080), 0.056, Vector3(1.32, 0.44, 0.50), hb, mat_skin)
	_ball(root, h_c + hb * Vector3(0.0, -0.022, -0.096), 0.030, Vector3(0.62, 1.35, 0.72), hb, mat_skin)
	var collar := TorusMesh.new()
	collar.inner_radius = 0.064
	collar.outer_radius = 0.094
	collar.rings = 26
	collar.ring_segments = 12
	var cm: MeshInstance3D = _add(root, collar, mat_field)
	cm.transform = Transform3D(fb_n, neck_base + fb_n.y * 0.045)

	# --- raised tesserae -----------------------------------------------------
	var n_torso: int = rng.randi_range(16, 24)
	for k in range(n_torso):
		var i: int = rng.randi_range(1, N_SPINE - 2)
		var ang: float = rng.randf_range(-PI, PI)
		var fb: Basis = frames[i]
		var r: float = radii[i]
		var sxv: float = SX[i]
		var szv: float = SZ[i]
		var lx: float = cos(ang) * sxv * r
		var lz: float = sin(ang) * szv * r
		var ly: float = rng.randf_range(-0.035, 0.035)
		var pos: Vector3 = pts[i] + fb * Vector3(lx, ly, lz)
		var nrm: Vector3 = (fb * Vector3(cos(ang) / sxv, 0.18, sin(ang) / szv)).normalized()
		var mt: StandardMaterial3D = tile_mats[int(deck_idx[rng.randi_range(0, deck_idx.size() - 1)])]
		_plate(root, pos, nrm, fb.y, rng.randf_range(0.036, 0.058), rng.randf_range(0.032, 0.052), rng.randf_range(-PI, PI), mt)

	_limb_plates(root, hip_r, knee_r, 0.098, rng.randi_range(4, 7), rng, tile_mats, deck_idx)
	_limb_plates(root, hip_l, knee_l, 0.098, rng.randi_range(4, 7), rng, tile_mats, deck_idx)
	_limb_plates(root, sh_r, elbow_r, 0.062, rng.randi_range(2, 4), rng, tile_mats, deck_idx)
	_limb_plates(root, sh_l, elbow_l, 0.062, rng.randi_range(2, 4), rng, tile_mats, deck_idx)
	_limb_plates(root, knee_l, ankle_l, 0.068, rng.randi_range(2, 4), rng, tile_mats, deck_idx)

	var n_head: int = rng.randi_range(3, 6)
	for k in range(n_head):
		var ang: float = rng.randf_range(-PI, PI)
		var lift: float = rng.randf_range(-0.02, 0.075)
		var rr: float = 0.106 * sqrt(maxf(1.0 - (lift / 0.128) * (lift / 0.128), 0.05))
		var loc := Vector3(cos(ang) * rr * 0.90, lift, sin(ang) * rr)
		var pos: Vector3 = h_c + hb * loc
		var nrm: Vector3 = (hb * Vector3(cos(ang) / 0.90, lift * 3.0, sin(ang))).normalized()
		var mt: StandardMaterial3D = tile_mats[int(deck_idx[rng.randi_range(0, deck_idx.size() - 1)])]
		_plate(root, pos, nrm, hb.y, rng.randf_range(0.030, 0.044), rng.randf_range(0.028, 0.040), rng.randf_range(-PI, PI), mt)

	# --- individual size, then the floor slab --------------------------------
	_scale_children(root, body_k, Vector3(0.0, GROUND, 0.0))

	var box: AABB = _union_aabb(root)
	var mid: Vector3 = box.position + box.size * 0.5
	var slab_rx: float = clampf(box.size.x * 0.5 + 0.12, 0.26, 0.52)
	var slab_rz: float = clampf(box.size.z * 0.5 + 0.08, 0.26, 0.56)
	var slab: ArrayMesh = _slab_mesh(rng, slab_rx, slab_rz, GROUND, rng.randi_range(11, 16))
	var sm: MeshInstance3D = _add(root, slab, mat_slab)
	sm.transform = Transform3D(Basis(), Vector3(mid.x, 0.0, mid.z))

	_settle(root)


# ---------------------------------------------------------------------------
# pose helpers

static func _spine_basis(t: float, fwd: float, side: float, twist: float) -> Basis:
	var e: float = t * t * (3.0 - 2.0 * t)
	var b := Basis(Vector3.UP, twist * e)
	b = b * Basis(Vector3.RIGHT, -fwd * e)
	b = b * Basis(Vector3.FORWARD, side * e)
	return b


static func _arm_chain(a: Vector3, target: Vector3, l1: float, l2: float, pole: Vector3) -> Array:
	var reach: float = (l1 + l2) * 0.985
	var d: Vector3 = target - a
	var dist: float = maxf(d.length(), 0.001)
	var dir: Vector3 = d / dist
	var b: Vector3 = target
	if dist > reach:
		dist = reach
		b = a + dir * reach
	var x: float = (dist * dist + l1 * l1 - l2 * l2) / (2.0 * dist)
	var h: float = sqrt(maxf(l1 * l1 - x * x, 0.0))
	var pd: Vector3 = pole - dir * pole.dot(dir)
	if pd.length() < 0.0001:
		pd = Vector3.UP - dir * Vector3.UP.dot(dir)
	var elbow: Vector3 = a + dir * x + pd.normalized() * h
	return [elbow, b]


static func _hand(root: Node3D, wrist: Vector3, fwd: Vector3, palm_n: Vector3, mat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	var f: Vector3 = fwd.normalized()
	var n: Vector3 = palm_n - f * palm_n.dot(f)
	if n.length() < 0.0001:
		n = Vector3.UP - f * Vector3.UP.dot(f)
	n = n.normalized()
	var s: Vector3 = f.cross(n).normalized()
	var hb := Basis(s, n, -f)
	var palm := BoxMesh.new()
	palm.size = Vector3(0.086, 0.030, 0.098)
	var pm: MeshInstance3D = _add(root, palm, mat)
	pm.transform = Transform3D(hb, wrist + f * 0.052)
	for k in range(4):
		var fan: float = (float(k) - 1.5) * 0.19
		var root_p: Vector3 = wrist + f * 0.096 + s * ((float(k) - 1.5) * 0.024)
		var dirf: Vector3 = (f * cos(fan) + s * sin(fan) - n * 0.16).normalized()
		var ln: float = 0.074 - absf(float(k) - 1.4) * 0.008 + rng.randf_range(-0.006, 0.006)
		_limb(root, root_p, root_p + dirf * ln, 0.0135, mat)
	var thumb_p: Vector3 = wrist + f * 0.040 + s * 0.042
	var thumb_d: Vector3 = (f * 0.55 + s * rng.randf_range(0.70, 0.92) - n * 0.20).normalized()
	_limb(root, thumb_p, thumb_p + thumb_d * 0.058, 0.0155, mat)


static func _limb_plates(root: Node3D, a: Vector3, b: Vector3, r: float, count: int, rng: RandomNumberGenerator, tile_mats: Array, deck_idx: Array) -> void:
	var d: Vector3 = b - a
	if d.length() < 0.001:
		return
	var fb: Basis = _basis_y_to(d)
	for k in range(count):
		var t: float = rng.randf_range(0.18, 0.86)
		var ang: float = rng.randf_range(-PI, PI)
		var base: Vector3 = a.lerp(b, t)
		var loc := Vector3(cos(ang) * r, 0.0, sin(ang) * r)
		var pos: Vector3 = base + fb * loc
		var nrm: Vector3 = (fb * Vector3(cos(ang), 0.12, sin(ang))).normalized()
		var mt: StandardMaterial3D = tile_mats[int(deck_idx[rng.randi_range(0, deck_idx.size() - 1)])]
		_plate(root, pos, nrm, fb.y, rng.randf_range(0.032, 0.050), rng.randf_range(0.028, 0.046), rng.randf_range(-PI, PI), mt)


static func _plate(root: Node3D, pos: Vector3, nrm: Vector3, up_hint: Vector3, w: float, h: float, yaw: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var ny: Vector3 = nrm.normalized()
	var t_ref: Vector3 = up_hint - ny * up_hint.dot(ny)
	if t_ref.length() < 0.0001:
		t_ref = Vector3.FORWARD - ny * Vector3.FORWARD.dot(ny)
	var nz: Vector3 = t_ref.normalized()
	var nx: Vector3 = ny.cross(nz).normalized()
	var th: float = 0.0075
	var box := BoxMesh.new()
	box.size = Vector3(w, th, h)
	var mi: MeshInstance3D = _add(root, box, mat)
	mi.transform = Transform3D(Basis(nx, ny, nz) * Basis(Vector3.UP, yaw), pos + ny * (th * 0.30))
	return mi


# ---------------------------------------------------------------------------
# primitive helpers

static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _ball(root: Node3D, pos: Vector3, r: float, sc: Vector3, orient: Basis, mat: StandardMaterial3D) -> MeshInstance3D:
	var sph := SphereMesh.new()
	sph.radius = r
	sph.height = r * 2.0
	sph.radial_segments = 20
	sph.rings = 11
	var mi: MeshInstance3D = _add(root, sph, mat)
	mi.transform = Transform3D(_scaled(orient, sc), pos)
	return mi


static func _limb(root: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.005)
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = maxf(ln + r * 1.7, r * 2.01)
	cap.radial_segments = 18
	cap.rings = 6
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
	var ax: Vector3 = Vector3.UP.cross(d).normalized()
	var ang: float = acos(clampf(dot_up, -1.0, 1.0))
	return Basis(ax, ang)


static func _scaled(b: Basis, sc: Vector3) -> Basis:
	return Basis(b.x * sc.x, b.y * sc.y, b.z * sc.z)


static func _skin_mat(tex: ImageTexture, uv: float, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 1.0, 1.0)
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(uv, uv, uv)
	m.roughness = rough
	m.metallic = metal
	m.clearcoat_enabled = true
	m.clearcoat = 0.55
	m.clearcoat_roughness = 0.15
	return m


static func _flat_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = maxf(rough, 0.08)
	m.metallic = metal
	m.clearcoat_enabled = true
	m.clearcoat = 0.75
	m.clearcoat_roughness = 0.10
	return m


static func _deck(tiles: Array, weights: Array) -> Array:
	var out: Array = []
	for i in range(tiles.size()):
		var wgt: int = int(weights[i])
		var hexs: String = str(tiles[i])
		for k in range(wgt):
			out.append(Color(hexs))
	if out.is_empty():
		out.append(Color(1.0, 1.0, 1.0))
	return out


static func _deck_index(weights: Array) -> Array:
	var out: Array = []
	for i in range(weights.size()):
		var wgt: int = int(weights[i])
		for k in range(wgt):
			out.append(i)
	if out.is_empty():
		out.append(0)
	return out


# ---------------------------------------------------------------------------
# the mosaic texture: wrapped jittered Voronoi, F2-F1 grout

static func _mosaic_texture(rng: RandomNumberGenerator, cells: int, deck: Array, grout: Color, glitter: float, ax: float, jit: float) -> ImageTexture:
	var sz: int = TEX_SIZE
	var n: int = maxi(cells, 6)
	var cw: float = float(sz) / float(n)
	var count: int = n * n
	var cx := PackedFloat32Array()
	var cy := PackedFloat32Array()
	var cr := PackedFloat32Array()
	var cg := PackedFloat32Array()
	var cb := PackedFloat32Array()
	cx.resize(count)
	cy.resize(count)
	cr.resize(count)
	cg.resize(count)
	cb.resize(count)
	for j in range(n):
		for i in range(n):
			var idx: int = j * n + i
			cx[idx] = (float(i) + 0.5 + rng.randf_range(-jit, jit)) * cw
			cy[idx] = (float(j) + 0.5 + rng.randf_range(-jit, jit)) * cw
			var col: Color = deck[rng.randi_range(0, deck.size() - 1)]
			var bright: float = rng.randf_range(0.88, 1.10)
			cr[idx] = clampf(col.r * bright, 0.0, 1.0)
			cg[idx] = clampf(col.g * bright, 0.0, 1.0)
			cb[idx] = clampf(col.b * bright, 0.0, 1.0)

	var gw: float = cw * 0.23
	var phase: float = rng.randf_range(0.0, 90.0)
	var img: Image = Image.create(sz, sz, false, Image.FORMAT_RGB8)
	for y in range(sz):
		var py: float = float(y) + 0.5
		var cj: int = int(floor(py / cw))
		for x in range(sz):
			var px: float = float(x) + 0.5
			var ci: int = int(floor(px / cw))
			var d1: float = 1.0e9
			var d2: float = 1.0e9
			var best: int = 0
			var bdy: float = 0.0
			for jj in range(cj - 1, cj + 2):
				var wj: int = posmod(jj, n)
				var oy: float = float(jj - wj) * cw
				for ii in range(ci - 1, ci + 2):
					var wi: int = posmod(ii, n)
					var ox: float = float(ii - wi) * cw
					var idx: int = wj * n + wi
					var dx: float = (px - (cx[idx] + ox)) * ax
					var dy: float = py - (cy[idx] + oy)
					var dd: float = sqrt(dx * dx + dy * dy)
					if dd < d1:
						d2 = d1
						d1 = dd
						best = idx
						bdy = dy
					elif dd < d2:
						d2 = dd
			var e: float = clampf((d2 - d1) / gw, 0.0, 1.0)
			var s: float = e * e * (3.0 - 2.0 * e)
			var dome: float = 1.07 - 0.17 * clampf(d1 / (cw * 0.78), 0.0, 1.0) - 0.11 * clampf(bdy / cw, -1.0, 1.0)
			var r_v: float = clampf(cr[best] * dome, 0.0, 1.0)
			var g_v: float = clampf(cg[best] * dome, 0.0, 1.0)
			var b_v: float = clampf(cb[best] * dome, 0.0, 1.0)
			if glitter > 0.0:
				var hv: float = sin(float(x) * 12.9898 + float(y) * 78.233 + phase) * 43758.5453
				var hf: float = hv - floor(hv)
				if hf < glitter:
					r_v = clampf(r_v + 0.45, 0.0, 1.0)
					g_v = clampf(g_v + 0.45, 0.0, 1.0)
					b_v = clampf(b_v + 0.45, 0.0, 1.0)
			img.set_pixel(x, y, Color(lerpf(grout.r, r_v, s), lerpf(grout.g, g_v, s), lerpf(grout.b, b_v, s)))
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------------------
# the chipped floor slab

static func _slab_mesh(rng: RandomNumberGenerator, rx: float, rz: float, h: float, sides: int) -> ArrayMesh:
	var n: int = maxi(sides, 7)
	var ring: Array = []
	for k in range(n):
		var a: float = TAU * float(k) / float(n) + rng.randf_range(-0.10, 0.10)
		var j: float = rng.randf_range(0.84, 1.03)
		ring.append(Vector3(cos(a) * rx * j, 0.0, sin(a) * rz * j))
	var inside := Vector3(0.0, h * 0.5, 0.0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var top_c := Vector3(0.0, h, 0.0)
	var bot_c := Vector3(0.0, 0.0, 0.0)
	for k in range(n):
		var a0: Vector3 = ring[k]
		var a1: Vector3 = ring[(k + 1) % n]
		var t0 := Vector3(a0.x, h, a0.z)
		var t1 := Vector3(a1.x, h, a1.z)
		_tri_out(st, top_c, t0, t1, inside)
		_tri_out(st, bot_c, a0, a1, inside)
		_tri_out(st, a0, a1, t1, inside)
		_tri_out(st, a0, t1, t0, inside)
	st.generate_normals()
	return st.commit()


static func _tri_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, inside: Vector3) -> void:
	var nf: Vector3 = (c - a).cross(b - a)
	var cen: Vector3 = (a + b + c) / 3.0
	if nf.dot(cen - inside) >= 0.0:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)
	else:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)


# ---------------------------------------------------------------------------
# measurement, fit and settle

static func _union_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var mi: MeshInstance3D = ch
		if mi.mesh == null:
			continue
		var wb: AABB = mi.transform * mi.mesh.get_aabb()
		if first:
			box = wb
			first = false
		else:
			box = box.merge(wb)
	return box


static func _scale_children(root: Node3D, k: float, pivot: Vector3) -> void:
	if absf(k - 1.0) < 0.0005:
		return
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var mi: MeshInstance3D = ch
		var tf: Transform3D = mi.transform
		mi.transform = Transform3D(tf.basis.scaled(Vector3(k, k, k)), pivot + (tf.origin - pivot) * k)


static func _shift_children(root: Node3D, off: Vector3) -> void:
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var mi: MeshInstance3D = ch
		mi.transform = Transform3D(mi.transform.basis, mi.transform.origin + off)


static func _settle(root: Node3D) -> void:
	var box: AABB = _union_aabb(root)
	var kx: float = 1.20 / maxf(box.size.x, 0.001)
	var kz: float = 1.20 / maxf(box.size.z, 0.001)
	var ky: float = 1.68 / maxf(box.size.y, 0.001)
	var kfit: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kfit < 1.0:
		_scale_children(root, kfit, Vector3.ZERO)
		box = _union_aabb(root)
	var mid: Vector3 = box.position + box.size * 0.5
	var off := Vector3(-mid.x, 0.0, -mid.z)
	if box.position.y < 0.0:
		off.y = -box.position.y
	_shift_children(root, off)
