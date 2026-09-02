extends RefCounted

## dream_bodies / lava_bloom — one flowering bough lifted out of a lava forest.
##
## Reference: scratchpad/refs/lava_forest.png (2048x536 panorama) — a hillside of
## black molten rope-like roots and branches, matte and knotted, smothered in
## dense sprays of FLAT rounded petals in saturated yellow, magenta-pink and
## white, with small round sage-green leaves threaded between them.
##
## Reproduced, and how:
##   1. Molten rope wood — a recursive static helper (_grow, 5 levels) walks a
##      chain of 2..5 CapsuleMesh segments per branch whose direction is pushed
##      sideways every step by a perpendicular that ROTATES as it rises, so the
##      limb writhes instead of arcing; squashed knuckle spheres sit on the
##      joints of the lower three levels and each fork thins the wood by a third.
##   2. The knotted black surface — a 128x128 ImageTexture of domain-warped
##      periodic value noise, ridged (1 - |2n-1|) into thin rope highlights, hung
##      on uv1_world_triplanar so one swirl runs unbroken across the whole chain
##      of primitives; matte, roughness 0.92, no clearcoat.
##   3. The root tangle — 4..6 short chains leaving the base outward and down,
##      each clamped to rest ON the plinth, giving the bough the reference's
##      lava-crust footing.
##   4. Blossom sprays — 9..12 clusters at branch tips, each a tiny throat sphere
##      plus 5..8 FLAT petals: ArrayMesh rounded lobes (sine half-width profile,
##      bowed along the length and cupped across it, vertex-colour base-to-tip
##      gradient, double sided), scattered on a small sphere around the tip and
##      tilted at random angles, so the cluster reads as one blob of petals.
##   5. Palette by seed — one of five schemes, each a dominant colour with a
##      minority second (gold/pink, magenta/white, white/magenta, gold/white,
##      pink/gold); 2..3 clusters of the crown take the second colour.
##   6. Round green leaves — 6..10 nodes on the outer branches, each a hair-thin
##      stem carrying two flattened SphereMesh discs splayed apart.
##   7. A gesture — the trunk leans, the crown is weighted to the leaning side,
##      and about a third of the sprays hang downward as the reference's racemes
##      do; the tips that get no blossom stay bare black twigs.
##   8. Fit — a measured horizontal gather, then a uniform scale about the plinth
##      top to a seeded 1.40..1.62 m, then the settle pass.
##
## Given up: the FOREST (this is one bough, not a hillside), the ground mat of
## fallen leaves, the individual five-petalled florets inside each spray, and the
## reference's depth haze.

const TEX_SIZE: int = 128
const PETAL_TEX: int = 64
const PLINTH_TOP: float = 0.055
const MAX_MESH: int = 242
const HALF_SPAN: float = 0.53

# [dominant, second, throat, leaf]
const SCHEMES: Array = [
	["#E7C11B", "#D673BE", "#F4E5A6", "#5C9E72"],
	["#D671BE", "#F2ECE6", "#F7DCEE", "#569569"],
	["#F1EBE2", "#D06FB8", "#F6E3EE", "#63A87C"],
	["#E3B814", "#F1ECE4", "#F7ECB0", "#4F9268"],
	["#DE7FC6", "#E7C11B", "#F8DDEF", "#5EA274"],
]

const WOOD_HEXES: Array = ["#4A454F", "#433F4A", "#514A57"]


static func describe() -> String:
	return "One bough of the lava forest: a black molten trunk writhing up through five forks, its root tangle crusted on the plinth, smothered near the top in flat-petalled sprays of gold, magenta and white with small round green leaves between them."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var scheme: Array = SCHEMES[rng.randi_range(0, SCHEMES.size() - 1)]
	var col_main: Color = Color(str(scheme[0]))
	var col_second: Color = Color(str(scheme[1]))
	var col_throat: Color = Color(str(scheme[2]))
	var col_leaf: Color = Color(str(scheme[3]))
	var col_wood: Color = Color(str(WOOD_HEXES[rng.randi_range(0, WOOD_HEXES.size() - 1)]))

	# --- materials ----------------------------------------------------------
	var wood_tex: ImageTexture = _wood_texture(rng)
	var mat_wood := StandardMaterial3D.new()
	mat_wood.albedo_color = col_wood
	mat_wood.albedo_texture = wood_tex
	mat_wood.roughness = 0.92
	mat_wood.metallic = 0.0
	mat_wood.uv1_triplanar = true
	mat_wood.uv1_world_triplanar = true
	mat_wood.uv1_scale = Vector3(3.4, 3.4, 3.4)

	var mat_knot := StandardMaterial3D.new()
	mat_knot.albedo_color = col_wood.darkened(0.18)
	mat_knot.albedo_texture = wood_tex
	mat_knot.roughness = 0.95
	mat_knot.metallic = 0.0
	mat_knot.uv1_triplanar = true
	mat_knot.uv1_world_triplanar = true
	mat_knot.uv1_scale = Vector3(4.6, 4.6, 4.6)

	var mat_stem := StandardMaterial3D.new()
	mat_stem.albedo_color = col_leaf.darkened(0.55)
	mat_stem.roughness = 0.8

	var leaf_tex: ImageTexture = _soft_texture(rng, 0.0)
	var mat_leaf := StandardMaterial3D.new()
	mat_leaf.albedo_color = col_leaf
	mat_leaf.albedo_texture = leaf_tex
	mat_leaf.roughness = 0.52
	mat_leaf.clearcoat_enabled = true
	mat_leaf.clearcoat = 0.28
	mat_leaf.clearcoat_roughness = 0.4

	var mat_throat := StandardMaterial3D.new()
	mat_throat.albedo_color = col_throat
	mat_throat.roughness = 0.45

	var mat_plinth := StandardMaterial3D.new()
	mat_plinth.albedo_color = Color("#C7CAC4")
	mat_plinth.roughness = 0.88

	var petal_tex: ImageTexture = _soft_texture(rng, 0.16)

	# --- individual parameters ---------------------------------------------
	var lean_roll: float = rng.randf_range(0.0, TAU)
	var lean_amt: float = rng.randf_range(0.13, 0.26)
	var trunk_len: float = rng.randf_range(0.40, 0.48)
	var trunk_rad: float = rng.randf_range(0.066, 0.082)
	var n_roots: int = rng.randi_range(4, 6)
	var target_h: float = rng.randf_range(1.40, 1.62)
	var n_cluster_want: int = rng.randi_range(9, 12)
	var n_leaf_nodes: int = rng.randi_range(6, 10)
	var second_count: int = rng.randi_range(2, 3)

	var ctx: Dictionary = {
		"root": root,
		"rng": rng,
		"count": 0,
		"branches": 0,
		"max_branches": rng.randi_range(23, 27),
		"mat_wood": mat_wood,
		"mat_knot": mat_knot,
		"tips": [],
		"leaf_spots": [],
		"segs": [5, 4, 3, 3, 2],
		"gnarl": rng.randf_range(0.30, 0.46),
		"twist": rng.randf_range(0.55, 1.10),
		"taper": rng.randf_range(0.74, 0.84),
		"up_pull": rng.randf_range(0.16, 0.30),
		"floor_y": PLINTH_TOP,
	}

	var lean_dir := Vector3(cos(lean_roll) * lean_amt, 1.0, sin(lean_roll) * lean_amt).normalized()
	var base := Vector3(-lean_dir.x * 0.10, PLINTH_TOP, -lean_dir.z * 0.10)

	# --- root tangle --------------------------------------------------------
	for i in range(n_roots):
		var a: float = float(i) / float(n_roots) * TAU + rng.randf_range(-0.35, 0.35)
		var out_v := Vector3(cos(a), 0.0, sin(a)).normalized()
		var rp: Vector3 = base + out_v * (trunk_rad * 0.55) + Vector3(0.0, trunk_rad * 0.7, 0.0)
		var rd: Vector3 = (out_v * 1.0 + Vector3.DOWN * rng.randf_range(0.30, 0.70)).normalized()
		var rr: float = trunk_rad * rng.randf_range(0.52, 0.74)
		for s in range(3):
			if not _can(ctx):
				break
			var f: float = float(s) / 3.0
			var side: Vector3 = _perp(rd, a * 2.0 + f * 3.0)
			rd = (rd + side * 0.34 + out_v * 0.16).normalized()
			var seg: float = rng.randf_range(0.075, 0.115)
			var nxt: Vector3 = rp + rd * seg
			var r_here: float = lerpf(rr, rr * 0.45, f)
			var y_min: float = PLINTH_TOP + r_here * 0.85
			if nxt.y < y_min:
				nxt = Vector3(nxt.x, y_min, nxt.z)
				rd = Vector3(rd.x, maxf(rd.y, 0.0), rd.z).normalized()
			_limb(ctx, rp, nxt, r_here, mat_wood)
			if s == 0 and _can(ctx):
				_knot(ctx, rp, rd, r_here * 1.35, mat_knot)
			rp = nxt

	# --- the bough ----------------------------------------------------------
	_grow(ctx, base, lean_dir, trunk_len, trunk_rad, 0, 4, rng.randf_range(0.0, TAU))

	# --- blossom clusters ---------------------------------------------------
	var tips: Array = ctx["tips"]
	var order: Array = []
	for i in range(tips.size()):
		order.append(i)
	for i in range(order.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = int(order[i])
		order[i] = order[j]
		order[j] = tmp
	var n_cluster: int = mini(n_cluster_want, order.size())
	for c in range(n_cluster):
		if not _can(ctx):
			break
		var tip: Array = tips[int(order[c])]
		var t_pos: Vector3 = tip[0]
		var t_dir: Vector3 = tip[1]
		var use_second: bool = c < second_count
		var col_base: Color = col_second if use_second else col_main
		var mat_petal := StandardMaterial3D.new()
		mat_petal.albedo_color = col_base
		mat_petal.albedo_texture = petal_tex
		mat_petal.vertex_color_use_as_albedo = true
		mat_petal.roughness = 0.48
		mat_petal.metallic = 0.0
		mat_petal.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat_petal.clearcoat_enabled = true
		mat_petal.clearcoat = 0.22
		mat_petal.clearcoat_roughness = 0.35
		_cluster(ctx, t_pos, t_dir, mat_petal, mat_throat, rng)

	# --- round leaves -------------------------------------------------------
	var spots: Array = ctx["leaf_spots"]
	var sorder: Array = []
	for i in range(spots.size()):
		sorder.append(i)
	for i in range(sorder.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = int(sorder[i])
		sorder[i] = sorder[j]
		sorder[j] = tmp
	var n_leaf: int = mini(n_leaf_nodes, sorder.size())
	for c in range(n_leaf):
		if not _can(ctx):
			break
		var spot: Array = spots[int(sorder[c])]
		var s_pos: Vector3 = spot[0]
		var s_dir: Vector3 = spot[1]
		var s_rad: float = float(spot[2])
		var out_v: Vector3 = _perp(s_dir, rng.randf_range(0.0, TAU))
		var stem_d: Vector3 = (out_v * 0.85 + Vector3.UP * rng.randf_range(-0.25, 0.55)).normalized()
		var stem_a: Vector3 = s_pos + out_v * (s_rad * 0.7)
		var stem_b: Vector3 = stem_a + stem_d * rng.randf_range(0.030, 0.058)
		_tapered_cyl(ctx, stem_a, stem_b, 0.0042, 0.0030, mat_stem)
		for k in range(2):
			if not _can(ctx):
				break
			var sgn: float = -1.0 if k == 0 else 1.0
			var side: Vector3 = _perp(stem_d, rng.randf_range(0.0, TAU))
			var lf_d: Vector3 = (stem_d * 0.55 + side * sgn * 0.85).normalized()
			var lr: float = rng.randf_range(0.021, 0.032)
			var disc := SphereMesh.new()
			disc.radius = lr
			disc.height = lr * 2.0
			disc.radial_segments = 12
			disc.rings = 6
			var lm: MeshInstance3D = _add(ctx, disc, mat_leaf)
			var lb: Basis = _basis_y_to(lf_d) * Basis(Vector3(1.06, 0.0, 0.0), Vector3(0.0, 0.11, 0.0), Vector3(0.0, 0.0, 0.92))
			lm.transform = Transform3D(lb, stem_b + lf_d * (lr * 0.75))

	# --- fit height, gather the crown in, clamp, centre, plinth, settle -----
	var pivot := Vector3(0.0, PLINTH_TOP, 0.0)
	var box: AABB = _union_aabb(root)
	var k_h: float = (target_h - PLINTH_TOP) / maxf(box.size.y, 0.01)
	_scale_about(root, pivot, k_h)

	box = _union_aabb(root)
	var span: float = maxf(box.size.x, box.size.z)
	if span > HALF_SPAN * 2.0:
		var g: float = (HALF_SPAN * 2.0) / maxf(span, 0.01)
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cm: MeshInstance3D = ch
			var o: Vector3 = cm.transform.origin
			cm.transform = Transform3D(cm.transform.basis, Vector3(o.x * g, o.y, o.z * g))
		box = _union_aabb(root)

	var k_x: float = 1.22 / maxf(box.size.x, 0.01)
	var k_z: float = 1.22 / maxf(box.size.z, 0.01)
	var kfit: float = minf(1.0, minf(k_x, k_z))
	if kfit < 1.0:
		_scale_about(root, pivot, kfit)

	box = _union_aabb(root)
	var centre: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-centre.x, PLINTH_TOP - box.position.y, -centre.z)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + shift)

	box = _union_aabb(root)
	var plinth := BoxMesh.new()
	plinth.size = Vector3(minf(1.22, box.size.x + 0.10), PLINTH_TOP, minf(1.22, box.size.z + 0.10))
	var pm: MeshInstance3D = _add_forced(root, plinth, mat_plinth)
	pm.transform = Transform3D(Basis(), Vector3(0.0, PLINTH_TOP * 0.5, 0.0))

	# measured settle: nothing below y = 0
	var final_box: AABB = _union_aabb(root)
	if final_box.position.y < 0.0:
		var lift: float = -final_box.position.y
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cm: MeshInstance3D = ch
			cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + Vector3(0.0, lift, 0.0))


# ---------------------------------------------------------------------------
# growth

static func _grow(ctx: Dictionary, base: Vector3, dir: Vector3, ln: float, rad: float, level: int, max_level: int, phase: float) -> void:
	var rng: RandomNumberGenerator = ctx["rng"]
	ctx["branches"] = int(ctx["branches"]) + 1
	var segs: Array = ctx["segs"]
	var n_seg: int = int(segs[mini(level, segs.size() - 1)])
	var d: Vector3 = dir.normalized()
	var p: Vector3 = base
	var seg_len: float = ln / float(n_seg)
	var gnarl: float = float(ctx["gnarl"])
	var twist: float = float(ctx["twist"])
	var taper: float = float(ctx["taper"])
	var up_pull: float = float(ctx["up_pull"])
	var floor_y: float = float(ctx["floor_y"])

	for s in range(n_seg):
		if not _can(ctx):
			return
		var f: float = float(s) / float(n_seg)
		var ang: float = phase + f * twist * TAU
		var side: Vector3 = _perp(d, ang)
		var pull: float = up_pull * (1.0 - float(level) / float(max_level + 2))
		d = (d + side * gnarl + Vector3.UP * pull).normalized()
		var r_here: float = lerpf(rad, rad * taper, f)
		var nxt: Vector3 = p + d * seg_len
		if nxt.y < floor_y + r_here:
			nxt = Vector3(nxt.x, floor_y + r_here, nxt.z)
			d = (nxt - p).normalized()
		_limb(ctx, p, nxt, r_here, ctx["mat_wood"])
		if level <= 2 and s % 2 == 1 and _can(ctx):
			_knot(ctx, nxt, d, r_here * 1.34, ctx["mat_knot"])
		if level >= 2 and rng.randf() < 0.55:
			var spots: Array = ctx["leaf_spots"]
			spots.append([nxt, d, r_here])
		p = nxt

	var rad_end: float = rad * taper
	var tips: Array = ctx["tips"]
	if level >= max_level or int(ctx["branches"]) >= int(ctx["max_branches"]):
		tips.append([p, d, rad_end])
		return

	# levels 0..2 always fork, so the crown always carries at least eight tips
	var n_child: int = 2
	if level == 0:
		n_child = 3 if rng.randf() < 0.35 else 2
	elif level == 3:
		n_child = 2 if rng.randf() < 0.75 else 1

	var roll: float = rng.randf_range(0.0, TAU)
	var fork: float = deg_to_rad(rng.randf_range(20.0, 38.0)) * (1.0 if n_child > 1 else 0.45)
	for c in range(n_child):
		if int(ctx["branches"]) >= int(ctx["max_branches"]):
			tips.append([p, d, rad_end])
			return
		var a2: float = fork * rng.randf_range(0.72, 1.28)
		var ax: Vector3 = _perp(d, roll + float(c) * TAU / float(n_child))
		var cd: Vector3 = (d * cos(a2) + ax * sin(a2)).normalized()
		cd = (cd + Vector3.UP * 0.14).normalized()
		var c_len: float = ln * rng.randf_range(0.62, 0.80)
		var c_rad: float = rad_end * rng.randf_range(0.60, 0.74)
		_grow(ctx, p, cd, c_len, c_rad, level + 1, max_level, rng.randf_range(0.0, TAU))


static func _cluster(ctx: Dictionary, centre: Vector3, out_dir: Vector3, mat_petal: StandardMaterial3D, mat_throat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	var c_rad: float = rng.randf_range(0.048, 0.076)
	var droop: float = -0.55 if rng.randf() < 0.34 else 0.22
	var n_pet: int = rng.randi_range(5, 8)

	var throat := SphereMesh.new()
	throat.radius = c_rad * 0.30
	throat.height = c_rad * 0.60
	throat.radial_segments = 10
	throat.rings = 6
	var tm: MeshInstance3D = _add(ctx, throat, mat_throat)
	tm.transform = Transform3D(Basis(), centre)

	for i in range(n_pet):
		if not _can(ctx):
			return
		var u: Vector3 = _rand_dir(rng)
		var bias: Vector3 = (u + out_dir * 0.55 + Vector3.UP * droop).normalized()
		var off: Vector3 = bias * (c_rad * rng.randf_range(0.20, 1.0))
		var pdir: Vector3 = (bias * 0.72 + _rand_dir(rng) * 0.48).normalized()
		var nrm: Vector3 = _perp(pdir, rng.randf_range(0.0, TAU))
		var bx: Vector3 = pdir.cross(nrm).normalized()
		var pl: float = c_rad * rng.randf_range(0.72, 1.10)
		var pw: float = pl * rng.randf_range(0.62, 0.92)
		var shade: float = rng.randf_range(0.80, 1.0)
		var c_low := Color(0.70 * shade, 0.68 * shade, 0.66 * shade)
		var c_hi := Color(1.0 * shade, 0.99 * shade, 0.97 * shade)
		var mesh: ArrayMesh = _petal(pl, pw, pl * rng.randf_range(0.10, 0.22), pw * rng.randf_range(0.06, 0.18), c_low, c_hi)
		var mi: MeshInstance3D = _add(ctx, mesh, mat_petal)
		mi.transform = Transform3D(Basis(bx, pdir, nrm), centre + off)


# ---------------------------------------------------------------------------
# mesh helpers

static func _can(ctx: Dictionary) -> bool:
	return int(ctx["count"]) < MAX_MESH


static func _add(ctx: Dictionary, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	ctx["count"] = int(ctx["count"]) + 1
	return _add_forced(ctx["root"], mesh, mat)


static func _add_forced(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _limb(ctx: Dictionary, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.006)
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = ln + r * 2.0
	cap.radial_segments = 10
	cap.rings = 3
	var mi: MeshInstance3D = _add(ctx, cap, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _tapered_cyl(ctx: Dictionary, a: Vector3, b: Vector3, r0: float, r1: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.006)
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = r0
	cyl.top_radius = r1
	cyl.height = ln
	cyl.radial_segments = 8
	cyl.rings = 1
	var mi: MeshInstance3D = _add(ctx, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _knot(ctx: Dictionary, at: Vector3, d: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var sph := SphereMesh.new()
	sph.radius = r
	sph.height = r * 2.0
	sph.radial_segments = 10
	sph.rings = 6
	var mi: MeshInstance3D = _add(ctx, sph, mat)
	var kb: Basis = _basis_y_to(d) * Basis(Vector3(1.16, 0.0, 0.0), Vector3(0.0, 0.70, 0.0), Vector3(0.0, 0.0, 0.94))
	mi.transform = Transform3D(kb, at)
	return mi


static func _petal(ln: float, wd: float, bow: float, cup: float, c_low: Color, c_hi: Color) -> ArrayMesh:
	# a flat rounded lobe: base at the origin, growing along +Y, face normal +Z
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nu: int = 6
	var nv: int = 4
	var grid: Array = []
	for i in range(nu + 1):
		var u: float = float(i) / float(nu)
		var shape: float = sin(PI * clampf(u * 0.90 + 0.10, 0.0, 1.0))
		var hw: float = wd * 0.5 * pow(shape, 0.55)
		var row: Array = []
		for j in range(nv + 1):
			var vv: float = float(j) / float(nv) * 2.0 - 1.0
			var x: float = vv * hw
			var y: float = u * ln
			var z: float = bow * sin(PI * u * 0.85) + cup * (vv * vv)
			row.append(Vector3(x, y, z))
		grid.append(row)
	for i in range(nu):
		var u0: float = float(i) / float(nu)
		var u1: float = float(i + 1) / float(nu)
		var c0: Color = c_low.lerp(c_hi, u0)
		var c1: Color = c_low.lerp(c_hi, u1)
		var row0: Array = grid[i]
		var row1: Array = grid[i + 1]
		for j in range(nv):
			var v0: float = float(j) / float(nv)
			var v1: float = float(j + 1) / float(nv)
			var p00: Vector3 = row0[j]
			var p01: Vector3 = row0[j + 1]
			var p10: Vector3 = row1[j]
			var p11: Vector3 = row1[j + 1]
			st.set_color(c0)
			st.set_uv(Vector2(v0, u0))
			st.add_vertex(p00)
			st.set_color(c1)
			st.set_uv(Vector2(v0, u1))
			st.add_vertex(p10)
			st.set_color(c1)
			st.set_uv(Vector2(v1, u1))
			st.add_vertex(p11)
			st.set_color(c0)
			st.set_uv(Vector2(v0, u0))
			st.add_vertex(p00)
			st.set_color(c1)
			st.set_uv(Vector2(v1, u1))
			st.add_vertex(p11)
			st.set_color(c0)
			st.set_uv(Vector2(v1, u0))
			st.add_vertex(p01)
	st.generate_normals()
	return st.commit()


static func _perp(d: Vector3, ang: float) -> Vector3:
	if d.length() < 0.00001:
		return Vector3.RIGHT
	var dn: Vector3 = d.normalized()
	var ref: Vector3 = Vector3.UP if absf(dn.y) < 0.9 else Vector3.RIGHT
	var e1: Vector3 = ref.cross(dn)
	if e1.length() < 0.0001:
		e1 = Vector3.FORWARD.cross(dn)
	if e1.length() < 0.0001:
		return Vector3.RIGHT
	e1 = e1.normalized()
	var e2: Vector3 = dn.cross(e1).normalized()
	var out_v: Vector3 = e1 * cos(ang) + e2 * sin(ang)
	if out_v.length() < 0.0001:
		return e1
	return out_v.normalized()


static func _rand_dir(rng: RandomNumberGenerator) -> Vector3:
	var z: float = rng.randf_range(-1.0, 1.0)
	var a: float = rng.randf_range(0.0, TAU)
	var r: float = sqrt(maxf(1.0 - z * z, 0.0))
	return Vector3(r * cos(a), z, r * sin(a))


static func _basis_y_to(dir: Vector3) -> Basis:
	if dir.length() < 0.00001:
		return Basis()
	var d: Vector3 = dir.normalized()
	var dot_up: float = d.dot(Vector3.UP)
	if dot_up > 0.9999:
		return Basis()
	if dot_up < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	var ax: Vector3 = Vector3.UP.cross(d).normalized()
	var ang: float = acos(clampf(dot_up, -1.0, 1.0))
	return Basis(ax, ang)


static func _scale_about(root: Node3D, pivot: Vector3, k: float) -> void:
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		var tf: Transform3D = cm.transform
		cm.transform = Transform3D(tf.basis.scaled(Vector3(k, k, k)), pivot + (tf.origin - pivot) * k)


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
# textures painted in code

static func _lattice(rng: RandomNumberGenerator, n: int) -> PackedFloat32Array:
	var a := PackedFloat32Array()
	a.resize(n * n)
	for i in range(n * n):
		a[i] = rng.randf()
	return a


static func _vnoise(lat: PackedFloat32Array, n: int, x: float, y: float) -> float:
	var xi: int = int(floor(x))
	var yi: int = int(floor(y))
	var fx: float = x - float(xi)
	var fy: float = y - float(yi)
	var sx: float = fx * fx * (3.0 - 2.0 * fx)
	var sy: float = fy * fy * (3.0 - 2.0 * fy)
	var x0: int = posmod(xi, n)
	var x1: int = posmod(xi + 1, n)
	var y0: int = posmod(yi, n)
	var y1: int = posmod(yi + 1, n)
	var v00: float = lat[y0 * n + x0]
	var v10: float = lat[y0 * n + x1]
	var v01: float = lat[y1 * n + x0]
	var v11: float = lat[y1 * n + x1]
	var ta: float = lerpf(v00, v10, sx)
	var tb: float = lerpf(v01, v11, sx)
	return lerpf(ta, tb, sy)


static func _fbm(lat: PackedFloat32Array, n: int, x: float, y: float, oct: int) -> float:
	var v: float = 0.0
	var amp: float = 0.5
	var fr: float = 1.0
	var norm: float = 0.0
	for o in range(oct):
		v += amp * _vnoise(lat, n, x * fr, y * fr)
		norm += amp
		amp *= 0.5
		fr *= 2.0
	return v / maxf(norm, 0.0001)


static func _wood_texture(rng: RandomNumberGenerator) -> ImageTexture:
	# domain-warped periodic value noise, ridged into molten rope highlights;
	# the warp field is periodic too, so the whole thing still tiles
	var n: int = 8
	var lat_a: PackedFloat32Array = _lattice(rng, n)
	var lat_b: PackedFloat32Array = _lattice(rng, n)
	var lat_c: PackedFloat32Array = _lattice(rng, n)
	var warp: float = rng.randf_range(0.9, 1.5)
	var img: Image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	for y in range(TEX_SIZE):
		for x in range(TEX_SIZE):
			var u: float = float(x) / float(TEX_SIZE) * float(n)
			var v: float = float(y) / float(TEX_SIZE) * float(n)
			var wx: float = _fbm(lat_b, n, u, v, 2) - 0.5
			var wy: float = _fbm(lat_c, n, u, v, 2) - 0.5
			var s: float = _fbm(lat_a, n, u + wx * warp * 2.0, v + wy * warp * 2.0, 3)
			var ridge: float = 1.0 - absf(s * 2.0 - 1.0)
			var g: float = 0.34 + 0.62 * pow(clampf(ridge, 0.0, 1.0), 1.7)
			var cool: float = 0.03 * (s - 0.5)
			img.set_pixel(x, y, Color(clampf(g - cool, 0.0, 1.0), clampf(g - cool * 0.4, 0.0, 1.0), clampf(g + cool, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


static func _soft_texture(rng: RandomNumberGenerator, base_dark: float) -> ImageTexture:
	# near-white mottle so albedo_color carries the hue; v runs along the petal
	var n: int = 4
	var lat: PackedFloat32Array = _lattice(rng, n)
	var img: Image = Image.create(PETAL_TEX, PETAL_TEX, false, Image.FORMAT_RGB8)
	for y in range(PETAL_TEX):
		for x in range(PETAL_TEX):
			var u: float = float(x) / float(PETAL_TEX)
			var v: float = float(y) / float(PETAL_TEX)
			var m: float = _fbm(lat, n, u * float(n), v * float(n), 3)
			var g: float = 0.90 + 0.12 * m
			var dark: float = lerpf(1.0 - base_dark, 1.0, clampf(v * 2.4, 0.0, 1.0))
			g = clampf(g * dark, 0.0, 1.0)
			img.set_pixel(x, y, Color(g, g * 0.998, g * 0.99))
	return ImageTexture.create_from_image(img)
