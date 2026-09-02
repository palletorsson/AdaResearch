extends RefCounted

## dream_bodies / kruger_suit — one hooded printed-suit body, half-kneeling, head
## down, with a flat cut-out shape leaning behind it.
##
## Reference: scratchpad/refs/outterbridge_kruger.png (2048x536 panorama) — a row
## of bodies in full-body zentai suits printed with graphics: navy covered in big
## white block letters at every angle, fine orange-and-white stripes, yellow with
## white brush slashes, a black-and-white maze knit, one bare white body. They sit,
## kneel and lean on each other in front of flat magenta and yellow cut-out shapes
## — big soft blobs and folded planes standing on the floor like stage flats.
##
## Reproduced, and how:
##   1. The pose does the work. One knee down and forward on the floor, the other
##      leg planted with the knee up, the torso bowed over it, the head tucked so
##      the crown of the hood is the frontmost point of the body. Nothing faces the
##      viewer. Braced arm straight from shoulder to a splayed hand flat on the
##      floor; the free hand rests on the raised knee. Which side braces, the lean,
##      the twist and the depth of the head tuck all come from the seed.
##   2. The suit as ONE printed skin. Every body primitive shares a triplanar
##      world-mapped material, so the pattern crosses the ~75 spheres and capsules
##      unbroken — the seam is where fabric would seam, not where a mesh ends.
##   3. Four suit prints painted in code, chosen by seed: (a) big white block
##      glyphs — L T I E H F O C A U, each drawn from 1-4 rectangles, stamped at
##      random size and angle with edge wrap, on a woven navy ground; (b) fine
##      orange-and-white stripes with a slow wave; (c) white brush slashes with
##      tapered ragged ends on yellow; (d) a black-on-white greek-key maze, three
##      cell motifs at four rotations over an 8x8 lattice.
##   4. The blank hood-head. An ellipsoid skull inside a slightly larger hood
##      shell, a two-ball point falling back off the crown, a torus collar at the
##      neck. No eyes, no mouth, no nose — the reference bodies have no faces.
##   5. Fabric creases. Flattened capsules laid tangentially at every joint, along
##      the spine, over the lap and around the hood, in a darker tint of the same
##      printed texture so the folds carry the print.
##   6. The cut-out — one thin extruded ArrayMesh polygon standing just behind the
##      figure, 1.1-1.35 m, magenta or yellow, matte: either a lobed soft blob
##      (three harmonics over a circle) or a superellipse panel with one or two
##      corners radially clipped and a vertical crease folding it out of plane.
##   7. Shoes. Flat dark ellipsoid soles — the kneeling foot lies instep-down and
##      trailing, the planted foot flat and forward.
##   8. Scale and settle. A measured fit pass keeps the group inside 1.25 x 1.25 m
##      and under 1.7 m; the statue is centred on x=0,z=0 and settled so its lowest
##      vertex sits on y=0.
##
## Given up: the group (four or five bodies leaning into each other), the bare
## white body among them, the second and third cut-outs stacked in depth, the brick
## wall behind, and any suggestion that the printed letters spell actual words.

const TEX: int = 256

# glyph strokes in unit space: [u0, v0, u1, v1]
const GLYPHS: Array = [
	[[0.0, 0.0, 0.26, 1.0], [0.0, 0.0, 0.92, 0.26]],
	[[0.0, 0.74, 1.0, 1.0], [0.37, 0.0, 0.63, 1.0]],
	[[0.37, 0.0, 0.63, 1.0]],
	[[0.0, 0.0, 0.26, 1.0], [0.0, 0.74, 1.0, 1.0], [0.0, 0.38, 0.86, 0.62], [0.0, 0.0, 1.0, 0.26]],
	[[0.0, 0.0, 0.26, 1.0], [0.74, 0.0, 1.0, 1.0], [0.0, 0.37, 1.0, 0.63]],
	[[0.0, 0.0, 0.26, 1.0], [0.0, 0.74, 1.0, 1.0], [0.0, 0.40, 0.82, 0.64]],
	[[0.0, 0.0, 0.26, 1.0], [0.74, 0.0, 1.0, 1.0], [0.0, 0.74, 1.0, 1.0], [0.0, 0.0, 1.0, 0.26]],
	[[0.0, 0.0, 0.26, 1.0], [0.0, 0.74, 1.0, 1.0], [0.0, 0.0, 1.0, 0.26]],
	[[0.0, 0.0, 0.26, 1.0], [0.74, 0.0, 1.0, 1.0], [0.0, 0.74, 1.0, 1.0], [0.0, 0.40, 1.0, 0.62]],
	[[0.0, 0.22, 0.26, 1.0], [0.74, 0.22, 1.0, 1.0], [0.0, 0.0, 1.0, 0.26]],
]

# greek-key cell motifs, unit cell space
const MAZE_MOTIFS: Array = [
	[[0.08, 0.08, 0.92, 0.24], [0.76, 0.08, 0.92, 0.92], [0.24, 0.76, 0.92, 0.92], [0.24, 0.40, 0.40, 0.92], [0.24, 0.40, 0.62, 0.56]],
	[[0.08, 0.42, 0.92, 0.58], [0.18, 0.58, 0.34, 0.92], [0.50, 0.58, 0.66, 0.92], [0.34, 0.08, 0.50, 0.42], [0.66, 0.08, 0.82, 0.42]],
	[[0.08, 0.08, 0.24, 0.92], [0.08, 0.76, 0.60, 0.92], [0.44, 0.30, 0.60, 0.92], [0.44, 0.30, 0.92, 0.46], [0.76, 0.08, 0.92, 0.46]],
]


static func describe() -> String:
	return "A hooded figure in a graphic-printed body suit, half-kneeling with one arm braced on the floor and the head tucked down, a flat magenta or yellow cut-out shape leaning behind it."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- the print -----------------------------------------------------------
	var suit_kind: int = rng.randi_range(0, 3)
	var suit_tex: ImageTexture = null
	var uv_k: float = 1.4
	var shoe_col: Color = Color("#22242C")
	if suit_kind == 0:
		suit_tex = _tex_letters(rng)
		uv_k = 1.30
		shoe_col = Color("#1B2033")
	elif suit_kind == 1:
		suit_tex = _tex_stripes(rng)
		uv_k = 2.10
		shoe_col = Color("#E8E3D8")
	elif suit_kind == 2:
		suit_tex = _tex_slashes(rng)
		uv_k = 1.55
		shoe_col = Color("#2A2A24")
	else:
		suit_tex = _tex_maze(rng)
		uv_k = 1.70
		shoe_col = Color("#23242A")

	var cut_yellow: bool = false
	if suit_kind != 2:
		cut_yellow = rng.randf() < 0.45
	var cut_col: Color = Color("#E7C433") if cut_yellow else Color("#C93C9C")

	var mat_suit: StandardMaterial3D = _print_mat(suit_tex, Color(1.0, 1.0, 1.0), uv_k, 0.58)
	var mat_fold: StandardMaterial3D = _print_mat(suit_tex, Color(0.84, 0.85, 0.90), uv_k, 0.64)
	var mat_hood: StandardMaterial3D = _print_mat(suit_tex, Color(0.96, 0.96, 0.99), uv_k, 0.54)
	var mat_shoe: StandardMaterial3D = _flat_mat(shoe_col, 0.44, true)
	var mat_cut: StandardMaterial3D = _flat_mat(cut_col, 0.90, false)
	mat_cut.cull_mode = BaseMaterial3D.CULL_DISABLED

	# --- this individual -----------------------------------------------------
	var braced: float = 1.0 if rng.randf() < 0.5 else -1.0
	var body_k: float = rng.randf_range(0.95, 1.06)
	var lean_x: float = rng.randf_range(-0.05, 0.05)
	var twist: float = deg_to_rad(rng.randf_range(-11.0, 13.0))
	var bow: float = rng.randf_range(0.03, 0.07)
	var head_drop: float = rng.randf_range(0.82, 1.14)
	var n_spine: int = rng.randi_range(11, 14)
	var cut_kind: int = rng.randi_range(0, 1)
	var cut_h: float = rng.randf_range(1.12, 1.34)
	var cut_yaw: float = deg_to_rad(rng.randf_range(-17.0, 17.0))
	var cut_tilt: float = deg_to_rad(rng.randf_range(3.0, 9.0))
	var cut_x: float = rng.randf_range(-0.13, 0.13)

	# --- spine ---------------------------------------------------------------
	var p_hip := Vector3(0.0, 0.50 * body_k, 0.12)
	var p_sh := Vector3(lean_x, 1.00 * body_k, -0.13)
	var pts: Array = []
	for i in range(n_spine):
		var t: float = float(i) / float(n_spine - 1)
		var q: Vector3 = p_hip.lerp(p_sh, t)
		q.z -= bow * sin(PI * t)
		q.x += sin(twist) * 0.07 * t * t
		pts.append(q)
	var spacing: float = (p_sh - p_hip).length() / float(n_spine - 1)

	for i in range(n_spine):
		var t: float = float(i) / float(n_spine - 1)
		var w: Vector2 = _torso_w(t)
		var tang: Vector3 = _tangent(pts, i)
		var bs: Basis = _basis_y_to(tang) * Basis(Vector3.UP, twist * t)
		var ctr: Vector3 = pts[i]
		_ball(root, ctr, Vector3(w.x * body_k, spacing * 1.10, w.y * body_k), bs, mat_suit)

	var p_top: Vector3 = pts[n_spine - 1]
	var w_top: Vector2 = _torso_w(1.0)

	# pelvis block and thigh roots
	_ball(root, p_hip + Vector3(0.0, -0.035, 0.01), Vector3(0.175 * body_k, 0.105, 0.145 * body_k), Basis(), mat_suit)
	for sgn in [-1.0, 1.0]:
		var sf: float = sgn
		_ball(root, p_hip + Vector3(sf * 0.125, -0.05, 0.02), Vector3(0.085, 0.085, 0.100), Basis(), mat_suit)

	# shoulder caps
	var sh_off: float = w_top.x * 0.92 * body_k
	for sgn in [-1.0, 1.0]:
		var sf: float = sgn
		_ball(root, p_top + Vector3(sf * sh_off, 0.005, 0.0), Vector3(0.078, 0.070, 0.086), Basis(), mat_suit)
	_ball(root, p_top + Vector3(0.0, -0.03, 0.03), Vector3(w_top.x * 0.98 * body_k, 0.075, 0.105), Basis(), mat_suit)

	# creases down the back
	for i in range(4):
		var fi: float = float(i)
		var t: float = 0.24 + fi * 0.19
		var w: Vector2 = _torso_w(t)
		var q: Vector3 = _curve_at(pts, t)
		var tang: Vector3 = Vector3(0.0, 1.0, 0.0)
		var side_a: Vector3 = q + Vector3(-w.x * 0.55, 0.0, w.y * 0.86)
		var side_b: Vector3 = q + Vector3(w.x * 0.55, 0.012, w.y * 0.80)
		_limb(root, side_a, side_b, 0.019, 0.40, mat_fold)

	# --- neck, head, hood ----------------------------------------------------
	var neck_base: Vector3 = p_top + Vector3(0.0, 0.045, 0.005)
	var head_dir := Vector3(sin(twist) * 0.34, -sin(head_drop), -cos(head_drop)).normalized()
	var head_ctr: Vector3 = neck_base + head_dir * (0.175 * body_k)
	var up_ref := Vector3(0.0, 1.0, 0.0)
	var hz: Vector3 = head_dir
	var hx: Vector3 = up_ref.cross(hz).normalized()
	if hx.length() < 0.001:
		hx = Vector3(1.0, 0.0, 0.0)
	var hy: Vector3 = hz.cross(hx).normalized()
	var head_bs := Basis(hx, hy, hz)

	_limb(root, neck_base + Vector3(0.0, -0.03, 0.0), neck_base + head_dir * 0.09, 0.058 * body_k, 1.0, mat_suit)
	var collar := TorusMesh.new()
	collar.inner_radius = 0.062 * body_k
	collar.outer_radius = 0.090 * body_k
	collar.rings = 24
	collar.ring_segments = 10
	var col_mi: MeshInstance3D = _add(root, collar, mat_fold)
	col_mi.transform = Transform3D(_basis_y_to(head_dir), neck_base + head_dir * 0.02)

	# skull, then the hood shell over it
	_ball(root, head_ctr, Vector3(0.092, 0.104, 0.116) * body_k, head_bs, mat_hood)
	_ball(root, head_ctr - head_dir * 0.022, Vector3(0.104, 0.116, 0.122) * body_k, head_bs, mat_hood)
	_ball(root, head_ctr - head_dir * 0.075, Vector3(0.100, 0.112, 0.110) * body_k, head_bs, mat_hood)
	var peak_dir: Vector3 = (-head_dir + Vector3(0.0, 0.85, 0.0)).normalized()
	_ball(root, head_ctr - head_dir * 0.10 + peak_dir * 0.055, Vector3(0.082, 0.068, 0.090) * body_k, head_bs, mat_hood)
	_ball(root, head_ctr - head_dir * 0.10 + peak_dir * 0.115, Vector3(0.055, 0.044, 0.062) * body_k, head_bs, mat_hood)
	for i in range(3):
		var fi: float = float(i)
		var ang: float = -0.7 + fi * 0.7
		var ca: Vector3 = head_ctr + head_bs * Vector3(-0.10 * cos(ang), 0.09 * sin(ang), -0.075)
		var cb: Vector3 = head_ctr + head_bs * Vector3(0.10 * cos(ang), 0.09 * sin(ang), -0.075)
		_limb(root, ca, cb, 0.014, 0.42, mat_fold)

	# --- legs: one knee down and forward, one planted with the knee up -------
	var sd: float = braced
	var hip_a: Vector3 = p_hip + Vector3(sd * 0.135, -0.02, 0.02)
	var knee_a := Vector3(sd * 0.158, 0.098, -0.155)
	var ank_a := Vector3(sd * 0.168, 0.078, 0.205)
	var toe_a := Vector3(sd * 0.168, 0.058, 0.330)
	var hip_b: Vector3 = p_hip + Vector3(-sd * 0.135, -0.02, 0.02)
	var knee_b := Vector3(-sd * 0.212, 0.470 * body_k, -0.255)
	var ank_b := Vector3(-sd * 0.212, 0.090, -0.295)
	var toe_b := Vector3(-sd * 0.212, 0.058, -0.415)

	_limb(root, hip_a, knee_a, 0.088 * body_k, 0.92, mat_suit)
	_ball(root, knee_a, Vector3(0.078, 0.074, 0.082), Basis(), mat_suit)
	_limb(root, knee_a, ank_a, 0.072 * body_k, 0.92, mat_suit)
	_ball(root, ank_a, Vector3(0.062, 0.055, 0.062), Basis(), mat_suit)
	_ball(root, (ank_a + toe_a) * 0.5 + Vector3(0.0, -0.008, 0.0), Vector3(0.055, 0.033, 0.082), Basis(), mat_shoe)
	_ball(root, toe_a + Vector3(0.0, -0.004, 0.01), Vector3(0.050, 0.028, 0.036), Basis(), mat_shoe)

	_limb(root, hip_b, knee_b, 0.090 * body_k, 0.92, mat_suit)
	_ball(root, knee_b, Vector3(0.082, 0.080, 0.084), Basis(), mat_suit)
	_limb(root, knee_b, ank_b, 0.070 * body_k, 0.92, mat_suit)
	_ball(root, ank_b, Vector3(0.060, 0.055, 0.060), Basis(), mat_suit)
	_ball(root, (ank_b + toe_b) * 0.5 + Vector3(0.0, -0.018, 0.0), Vector3(0.056, 0.032, 0.086), Basis(), mat_shoe)
	_ball(root, toe_b + Vector3(0.0, -0.012, -0.012), Vector3(0.050, 0.026, 0.038), Basis(), mat_shoe)

	# knee and lap creases
	_limb(root, knee_a + Vector3(-0.06, 0.03, -0.03), knee_a + Vector3(0.06, 0.04, -0.04), 0.016, 0.40, mat_fold)
	_limb(root, knee_b + Vector3(-0.06, 0.045, -0.05), knee_b + Vector3(0.06, 0.030, -0.05), 0.016, 0.40, mat_fold)
	_limb(root, ank_a + Vector3(-0.05, 0.03, 0.01), ank_a + Vector3(0.05, 0.03, 0.01), 0.014, 0.40, mat_fold)
	_limb(root, ank_b + Vector3(-0.05, 0.03, 0.0), ank_b + Vector3(0.05, 0.03, 0.0), 0.014, 0.40, mat_fold)
	for i in range(3):
		var fi: float = float(i)
		var f: float = fi / 2.0
		var ca: Vector3 = hip_a.lerp(knee_a, 0.25 + f * 0.30) + Vector3(0.0, 0.055, 0.0)
		var cb: Vector3 = hip_b.lerp(knee_b, 0.25 + f * 0.30) + Vector3(0.0, 0.055, 0.0)
		_limb(root, ca, cb, 0.016, 0.38, mat_fold)

	# --- arms ----------------------------------------------------------------
	var b_sh: Vector3 = p_top + Vector3(sd * sh_off, 0.0, 0.005)
	var b_el: Vector3 = b_sh + Vector3(sd * 0.105, -0.275, -0.115)
	var b_ha := Vector3(sd * (0.295 + rng.randf_range(-0.02, 0.04)), 0.062, -0.245 + rng.randf_range(-0.05, 0.04))
	_limb(root, b_sh, b_el, 0.062 * body_k, 0.94, mat_suit)
	_ball(root, b_el, Vector3(0.058, 0.058, 0.060), Basis(), mat_suit)
	_limb(root, b_el, b_ha, 0.050 * body_k, 0.94, mat_suit)
	_ball(root, b_ha, Vector3(0.046, 0.044, 0.046), Basis(), mat_suit)
	_limb(root, b_el + Vector3(-0.04, 0.035, -0.02), b_el + Vector3(0.04, 0.045, -0.02), 0.014, 0.40, mat_fold)
	var b_dir := Vector3(sd * 0.20, -0.12, -1.0).normalized()
	_hand(root, b_ha, b_dir, Vector3(1.0, 0.0, 0.0), 0.16, mat_suit)

	var f_sh: Vector3 = p_top + Vector3(-sd * sh_off, 0.0, 0.005)
	var f_el: Vector3 = f_sh + Vector3(-sd * 0.085, -0.235, -0.115)
	var f_ha: Vector3 = knee_b + Vector3(-sd * 0.005, 0.062, -0.030)
	_limb(root, f_sh, f_el, 0.060 * body_k, 0.94, mat_suit)
	_ball(root, f_el, Vector3(0.056, 0.056, 0.058), Basis(), mat_suit)
	_limb(root, f_el, f_ha, 0.048 * body_k, 0.94, mat_suit)
	_ball(root, f_ha, Vector3(0.044, 0.042, 0.044), Basis(), mat_suit)
	_limb(root, f_el + Vector3(-0.04, 0.03, -0.025), f_el + Vector3(0.04, 0.04, -0.025), 0.014, 0.40, mat_fold)
	var f_dir := Vector3(-sd * 0.10, -0.55, -0.83).normalized()
	_hand(root, f_ha, f_dir, Vector3(1.0, 0.0, 0.0), 0.62, mat_suit)

	# --- the cut-out standing behind -----------------------------------------
	var cut_thick: float = rng.randf_range(0.028, 0.044)
	var cut_mesh: ArrayMesh = _cutout_mesh(rng, cut_kind, cut_h, cut_thick)
	var cut_bs: Basis = Basis(Vector3.UP, cut_yaw) * Basis(Vector3.RIGHT, cut_tilt)
	var cut_mi: MeshInstance3D = _add(root, cut_mesh, mat_cut)
	cut_mi.transform = Transform3D(cut_bs, Vector3(cut_x, cut_h * 0.5, 0.455))
	var cut_box: AABB = cut_mi.transform * cut_mesh.get_aabb()
	cut_mi.transform = Transform3D(cut_bs, cut_mi.transform.origin + Vector3(0.0, -cut_box.position.y, 0.0))

	# --- fit, centre, settle -------------------------------------------------
	var box: AABB = _union_aabb(root)
	var kx: float = 1.22 / maxf(box.size.x, 0.001)
	var kz: float = 1.22 / maxf(box.size.z, 0.001)
	var ky: float = 1.66 / maxf(box.size.y, 0.001)
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
	sph.radial_segments = 18
	sph.rings = 10
	var mi: MeshInstance3D = _add(root, sph, mat)
	mi.transform = Transform3D(bs * Basis.from_scale(half), ctr)
	return mi


static func _limb(root: Node3D, a: Vector3, b: Vector3, r: float, flat: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.008)
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = ln + r * 2.0
	cap.radial_segments = 14
	cap.rings = 6
	var mi: MeshInstance3D = _add(root, cap, mat)
	var bs: Basis = _basis_y_to(d) * Basis.from_scale(Vector3(1.0, 1.0, flat))
	mi.transform = Transform3D(bs, (a + b) * 0.5)
	return mi


static func _hand(root: Node3D, wrist: Vector3, dir: Vector3, side_hint: Vector3, curl: float, mat: StandardMaterial3D) -> void:
	var bz: Vector3 = dir.normalized()
	var bx: Vector3 = side_hint - bz * side_hint.dot(bz)
	if bx.length() < 0.001:
		bx = Vector3(0.0, 0.0, 1.0) - bz * bz.z
	bx = bx.normalized()
	var by: Vector3 = bz.cross(bx).normalized()
	var hb := Basis(bx, by, bz)
	var palm: Vector3 = wrist + bz * 0.052
	_ball(root, palm, Vector3(0.058, 0.026, 0.058), hb, mat)
	for i in range(4):
		var fi: float = float(i)
		var spread: float = (fi - 1.5) * 0.30
		var fd: Vector3 = (bz * cos(spread) + bx * sin(spread) - by * curl).normalized()
		var a: Vector3 = palm + bz * 0.030 + bx * (fi - 1.5) * 0.024
		var b: Vector3 = a + fd * (0.062 - absf(fi - 1.5) * 0.008)
		_limb(root, a, b, 0.013, 0.85, mat)


static func _curve_at(pts: Array, t: float) -> Vector3:
	var n: int = pts.size()
	var f: float = clampf(t, 0.0, 1.0) * float(n - 1)
	var i: int = int(floor(f))
	if i >= n - 1:
		return pts[n - 1]
	var u: float = f - float(i)
	var a: Vector3 = pts[i]
	var b: Vector3 = pts[i + 1]
	return a.lerp(b, u)


static func _torso_w(t: float) -> Vector2:
	var kx: Array = [0.150, 0.144, 0.148, 0.164, 0.180, 0.172]
	var kz: Array = [0.120, 0.113, 0.110, 0.120, 0.128, 0.114]
	var f: float = clampf(t, 0.0, 1.0) * 5.0
	var i: int = int(floor(f))
	if i >= 5:
		var lx: float = kx[5]
		var lz: float = kz[5]
		return Vector2(lx, lz)
	var u: float = f - float(i)
	var s: float = u * u * (3.0 - 2.0 * u)
	var xa: float = kx[i]
	var xb: float = kx[i + 1]
	var za: float = kz[i]
	var zb: float = kz[i + 1]
	return Vector2(lerpf(xa, xb, s), lerpf(za, zb, s))


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
# the flat cut-out

static func _cutout_mesh(rng: RandomNumberGenerator, kind: int, h: float, thick: float) -> ArrayMesh:
	var n: int = 76
	var a_h: float = h * 0.5
	var a_w: float = h * rng.randf_range(0.46, 0.62) * 0.5
	var outline: Array = []
	if kind == 0:
		var p1: float = rng.randf_range(0.0, TAU)
		var p2: float = rng.randf_range(0.0, TAU)
		var p3: float = rng.randf_range(0.0, TAU)
		var a1: float = rng.randf_range(0.10, 0.21)
		var a2: float = rng.randf_range(0.08, 0.17)
		var a3: float = rng.randf_range(0.04, 0.11)
		for i in range(n):
			var th: float = TAU * float(i) / float(n)
			var rr: float = 1.0 + a1 * sin(th + p1) + a2 * sin(2.0 * th + p2) + a3 * sin(3.0 * th + p3)
			outline.append(Vector2(cos(th) * a_w * rr, sin(th) * a_h * rr))
	else:
		var e: float = rng.randf_range(3.2, 6.0)
		for i in range(n):
			var th: float = TAU * float(i) / float(n)
			var cth: float = cos(th)
			var sth: float = sin(th)
			var den: float = pow(absf(cth), e) + pow(absf(sth), e)
			var rr: float = pow(maxf(den, 0.0001), -1.0 / e)
			outline.append(Vector2(cth * rr * a_w, sth * rr * a_h))
		var n_clip: int = rng.randi_range(1, 2)
		for c in range(n_clip):
			var ca: float = rng.randf_range(0.0, TAU)
			var cd := Vector2(cos(ca), sin(ca))
			var far: float = 0.0
			for i in range(n):
				var pv: Vector2 = outline[i]
				far = maxf(far, pv.dot(cd))
			var lim: float = far * rng.randf_range(0.62, 0.80)
			for i in range(n):
				var pv: Vector2 = outline[i]
				var dv: float = pv.dot(cd)
				if dv > lim and dv > 0.0001:
					outline[i] = pv * (lim / dv)

	var fold_d: float = 0.0
	var crease: float = 0.0
	if kind == 1:
		fold_d = rng.randf_range(0.06, 0.13)
		crease = rng.randf_range(-0.35, 0.35) * a_w
	else:
		fold_d = rng.randf_range(0.02, 0.05)

	var rings: Array = [0.0, 0.30, 0.58, 0.80, 1.0]
	var grid_f: Array = []
	var grid_b: Array = []
	for k in range(rings.size()):
		var fr: float = rings[k]
		var row_f: Array = []
		var row_b: Array = []
		for i in range(n):
			var pv: Vector2 = outline[i]
			var ux: float = pv.x * fr
			var uy: float = pv.y * fr
			var zf: float = _fold_z(ux, a_w, kind, fold_d, crease)
			row_f.append(Vector3(ux, uy, zf))
			row_b.append(Vector3(ux, uy, zf + thick))
		grid_f.append(row_f)
		grid_b.append(row_b)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mid_z: float = _fold_z(0.0, a_w, kind, fold_d, crease) + thick * 0.5
	var core := Vector3(0.0, 0.0, mid_z)
	for k in range(rings.size() - 1):
		var f0: Array = grid_f[k]
		var f1: Array = grid_f[k + 1]
		var b0: Array = grid_b[k]
		var b1: Array = grid_b[k + 1]
		for i in range(n):
			var j: int = (i + 1) % n
			var fa: Vector3 = f0[i]
			var fb: Vector3 = f0[j]
			var fc: Vector3 = f1[j]
			var fd2: Vector3 = f1[i]
			var ba: Vector3 = b0[i]
			var bb: Vector3 = b0[j]
			var bc: Vector3 = b1[j]
			var bd: Vector3 = b1[i]
			if k == 0:
				_tri_out(st, fa, fc, fd2, fa + Vector3(0.0, 0.0, thick))
				_tri_out(st, ba, bc, bd, ba - Vector3(0.0, 0.0, thick))
			else:
				_quad_out(st, fa, fb, fc, fd2, (fa + fb + fc + fd2) * 0.25 + Vector3(0.0, 0.0, thick))
				_quad_out(st, ba, bb, bc, bd, (ba + bb + bc + bd) * 0.25 - Vector3(0.0, 0.0, thick))
	var last_f: Array = grid_f[rings.size() - 1]
	var last_b: Array = grid_b[rings.size() - 1]
	for i in range(n):
		var j: int = (i + 1) % n
		var ra: Vector3 = last_f[i]
		var rb: Vector3 = last_f[j]
		var rc: Vector3 = last_b[j]
		var rd: Vector3 = last_b[i]
		_quad_out(st, ra, rb, rc, rd, core)
	st.generate_normals()
	return st.commit()


static func _fold_z(ux: float, a_w: float, kind: int, fold_d: float, crease: float) -> float:
	if kind == 1:
		return -fold_d * absf(ux - crease) / maxf(a_w, 0.001)
	var q: float = clampf(absf(ux) / maxf(a_w, 0.001), 0.0, 1.0)
	return -fold_d * (1.0 - q * q)


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


# ---------------------------------------------------------------------------
# materials

static func _print_mat(tex: ImageTexture, tint: Color, uv_k: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 1.0
	m.uv1_scale = Vector3(uv_k, uv_k, uv_k)
	m.roughness = rough
	m.metallic = 0.0
	return m


static func _flat_mat(c: Color, rough: float, glossy: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	if glossy:
		m.clearcoat_enabled = true
		m.clearcoat = 0.4
		m.clearcoat_roughness = 0.3
	return m


# ---------------------------------------------------------------------------
# the four prints, painted in code

static func _px(img: Image, x: int, y: int, c: Color) -> void:
	img.set_pixel(posmod(x, TEX), posmod(y, TEX), c)


static func _tex_letters(rng: RandomNumberGenerator) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var ground := Color("#28304E")
	for y in range(TEX):
		for x in range(TEX):
			var fx: float = float(x)
			var fy: float = float(y)
			var weave: float = 0.024 * sin(fx * 1.55) * sin(fy * 1.85) + 0.018 * sin((fx + fy) * 0.62)
			img.set_pixel(x, y, Color(clampf(ground.r + weave, 0.0, 1.0), clampf(ground.g + weave, 0.0, 1.0), clampf(ground.b + weave * 1.2, 0.0, 1.0)))
	var ink := Color("#EFEDE3")
	var n: int = rng.randi_range(17, 23)
	for k in range(n):
		var gi: int = rng.randi_range(0, GLYPHS.size() - 1)
		var strokes: Array = GLYPHS[gi]
		var s: float = rng.randf_range(48.0, 102.0)
		var cx: float = rng.randf_range(0.0, float(TEX))
		var cy: float = rng.randf_range(0.0, float(TEX))
		var ang: float = rng.randf_range(-PI, PI)
		var shade: float = rng.randf_range(0.93, 1.0)
		_stamp_glyph(img, strokes, cx, cy, s, ang, Color(ink.r * shade, ink.g * shade, ink.b * shade))
	return ImageTexture.create_from_image(img)


static func _stamp_glyph(img: Image, strokes: Array, cx: float, cy: float, s: float, ang: float, ink: Color) -> void:
	var w: float = s * 0.74
	var hd: float = sqrt(w * w + s * s) * 0.5 + 2.0
	var ca: float = cos(ang)
	var sa: float = sin(ang)
	var x0: int = int(floor(cx - hd))
	var x1: int = int(ceil(cx + hd))
	var y0: int = int(floor(cy - hd))
	var y1: int = int(ceil(cy + hd))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var dx: float = float(x) + 0.5 - cx
			var dy: float = float(y) + 0.5 - cy
			var lu: float = (dx * ca + dy * sa) / w + 0.5
			var lv: float = (-dx * sa + dy * ca) / s + 0.5
			if lu < 0.0 or lu > 1.0 or lv < 0.0 or lv > 1.0:
				continue
			var hit: bool = false
			for sk in strokes:
				var rc: Array = sk
				var u0: float = rc[0]
				var v0: float = rc[1]
				var u1: float = rc[2]
				var v1: float = rc[3]
				if lu >= u0 and lu <= u1 and lv >= v0 and lv <= v1:
					hit = true
					break
			if hit:
				_px(img, x, y, ink)


static func _tex_stripes(rng: RandomNumberGenerator) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var warm := Color("#E4602F")
	var pale := Color("#F2EEE2")
	var bands: float = float(rng.randi_range(19, 26))
	var phase: float = rng.randf_range(0.0, TAU)
	var wave: float = rng.randf_range(3.0, 7.0)
	for y in range(TEX):
		var fy: float = float(y)
		var off: float = wave * sin(fy * 0.055 + phase) + 1.6 * sin(fy * 0.17 + phase * 0.5)
		for x in range(TEX):
			var fx: float = float(x)
			var v: float = sin((fx + off) * TAU * bands / float(TEX))
			var m: float = clampf(v * 5.0 + 0.35, 0.0, 1.0)
			var shade: float = 1.0 - 0.035 * sin(fy * 0.9 + fx * 0.3)
			var c: Color = pale.lerp(warm, m)
			img.set_pixel(x, y, Color(clampf(c.r * shade, 0.0, 1.0), clampf(c.g * shade, 0.0, 1.0), clampf(c.b * shade, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


static func _tex_slashes(rng: RandomNumberGenerator) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var ground := Color("#E2CB3B")
	for y in range(TEX):
		for x in range(TEX):
			var fx: float = float(x)
			var fy: float = float(y)
			var weave: float = 0.022 * sin(fx * 1.7) * sin(fy * 1.4)
			img.set_pixel(x, y, Color(clampf(ground.r + weave, 0.0, 1.0), clampf(ground.g + weave, 0.0, 1.0), clampf(ground.b + weave * 0.6, 0.0, 1.0)))
	var chalk := Color("#F6F3E8")
	var base_a: float = rng.randf_range(0.0, PI)
	var n: int = rng.randi_range(13, 19)
	for k in range(n):
		var cx: float = rng.randf_range(0.0, float(TEX))
		var cy: float = rng.randf_range(0.0, float(TEX))
		var ang: float = base_a + rng.randf_range(-0.45, 0.45)
		var ln: float = rng.randf_range(72.0, 178.0)
		var hw: float = rng.randf_range(5.0, 11.5)
		var ph1: float = rng.randf_range(0.0, TAU)
		var ph2: float = rng.randf_range(0.0, TAU)
		var shade: float = rng.randf_range(0.90, 1.0)
		_stamp_slash(img, cx, cy, ang, ln, hw, ph1, ph2, Color(chalk.r * shade, chalk.g * shade, chalk.b * shade))
	return ImageTexture.create_from_image(img)


static func _stamp_slash(img: Image, cx: float, cy: float, ang: float, ln: float, hw: float, ph1: float, ph2: float, ink: Color) -> void:
	var ca: float = cos(ang)
	var sa: float = sin(ang)
	var hd: float = ln * 0.5 + hw + 4.0
	var x0: int = int(floor(cx - hd))
	var x1: int = int(ceil(cx + hd))
	var y0: int = int(floor(cy - hd))
	var y1: int = int(ceil(cy + hd))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var dx: float = float(x) + 0.5 - cx
			var dy: float = float(y) + 0.5 - cy
			var lu: float = (dx * ca + dy * sa) / (ln * 0.5)
			var lv: float = -dx * sa + dy * ca
			if lu < -1.0 or lu > 1.0:
				continue
			var taper: float = 1.0 - 0.62 * pow(absf(lu), 3.0)
			var jit: float = 1.5 * sin(lu * 19.0 + ph1) + 0.9 * sin(lu * 43.0 + ph2)
			var edge: float = hw * taper + jit
			if absf(lv) > edge:
				continue
			if absf(lv) > edge - 1.6 and sin(lu * 61.0 + ph2 * 2.0) < -0.35:
				continue
			_px(img, x, y, ink)


static func _tex_maze(rng: RandomNumberGenerator) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var pale := Color("#F1EFE8")
	var ink := Color("#232429")
	var cells: int = 8
	var cell: int = TEX / cells
	var motif: Array = []
	var turn: Array = []
	for c in range(cells * cells):
		motif.append(rng.randi_range(0, MAZE_MOTIFS.size() - 1))
		turn.append(rng.randi_range(0, 3))
	for y in range(TEX):
		for x in range(TEX):
			var cxi: int = x / cell
			var cyi: int = y / cell
			var idx: int = cyi * cells + cxi
			var mi: int = motif[idx]
			var rt: int = turn[idx]
			var u: float = float(x - cxi * cell) / float(cell)
			var v: float = float(y - cyi * cell) / float(cell)
			for r in range(rt):
				var nu: float = v
				var nv: float = 1.0 - u
				u = nu
				v = nv
			var rects: Array = MAZE_MOTIFS[mi]
			var hit: bool = false
			for sk in rects:
				var rc: Array = sk
				var u0: float = rc[0]
				var v0: float = rc[1]
				var u1: float = rc[2]
				var v1: float = rc[3]
				if u >= u0 and u <= u1 and v >= v0 and v <= v1:
					hit = true
					break
			var fx: float = float(x)
			var fy: float = float(y)
			var weave: float = 0.02 * sin(fx * 1.9) * sin(fy * 1.6)
			var c: Color = ink if hit else pale
			img.set_pixel(x, y, Color(clampf(c.r + weave, 0.0, 1.0), clampf(c.g + weave, 0.0, 1.0), clampf(c.b + weave, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)
