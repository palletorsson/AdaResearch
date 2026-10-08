extends RefCounted

## dream_bodies / tatlin_red — one constructivist tower of red steel and torn paper.
##
## Reference: scratchpad/refs/tatlin.png (2048x536 panorama) — a black stage filled
## with Russian-constructivist scaffolds: thin RED steel bars triangulating in space,
## welded into irregular leaning towers, with big flat WHITE, GREY and CREAM-TAN
## planes — torn angular polygons, several of them folded — skewered through the
## frames and leaning against them. Hard raking light, one red panel far right.
##
## Reproduced, and how:
##   1. The triangulated tower — 7..9 rings of 2..4 jittered nodes on a shrinking,
##      twisting, LEANING axis; ring edges plus nearest and second-nearest rising
##      edges to the ring above, so nearly every cell closes as a triangle.
##   2. Flat bar stock — struts are BoxMesh 18..30 mm wide x 11..18 mm thick with a
##      random roll about their own axis, so the frame flashes edge-on and face-on
##      as you walk round; one strut in four is a round CylinderMesh rod instead.
##   3. Members that continue past their joints — a third of the bars overshoot
##      their end node by 30..130 mm, the frayed loose ends of the reference.
##   4. Long skip-level diagonals, splayed legs down to bolt plates on the floor,
##      and 4..6 free spears that leave the frame and end in air, two of them
##      lifting off the top ring.
##   5. Torn planes — 7..12 thin extruded ArrayMesh polygons, 5..9 sided with
##      jittered radii, elongated vertically, 0.36..0.80 m across, flat-shaded
##      (smooth group -1) so every facet takes its own hard light.
##   6. Folded sheets — a crease down each panel's local Y with an extra outline
##      vertex inserted where the outline crosses it, so the dihedral stays sharp.
##   7. Skewered and leaning — panels are anchored on frame nodes and pass straight
##      through the bars; two or three sit their bottom edge on the floor and lean
##      back at 18..40 degrees, as the big sheets do behind the scaffolds.
##   8. Surface — matte enamel (code-painted mottle + chip texture, triplanar) on
##      the red, matte paper (fibre noise, flecks, faint fold streaks) on the
##      panels; busy nodes get gusset cubes where the welds pile up.
##
## Given up: the black stage and its cast shadows, the neighbouring scaffolds that
## crowd the panorama, sheets that CURL rather than fold, and the faint white wall
## drawings behind the installation.
##
## AXES (dna)
##   monument — what becomes of the tower itself: "tower" one leaning frame as built,
##     "twinned" a second frame growing inverted out of its own top, "brigade" the one
##     tower dissolved into a crowd of small towers on the floor, "collapse" the frame
##     sagging into a wide wreck half drowned in a poured red pool, "exploded" every
##     member hovering apart along its own outward normal.
##   sheet — what the torn planes ARE: "torn" thin paper polygons as built, "thread"
##     only their outlines left as sagging cord, "bloom" each plane opened into a paper
##     flower on a red bud, "slab" the paper fossilised into thick stone monoliths.

const TEX_SIZE: int = 128

# [bar red, deep red, bright red, shadow red]
const RED_SETS: Array = [
	["#C4382C", "#A82A21", "#D8564A", "#8C1F19"],
	["#CF4433", "#B32E22", "#E2645A", "#96241B"],
	["#B93028", "#9E221C", "#CD4C42", "#7C1A15"],
]

# [paper white, cream, grey card, kraft tan]
const PAPER_SETS: Array = [
	["#F4F1EA", "#E7E0CE", "#CBC8C1", "#C7B393"],
	["#F7F5F0", "#DFD8C6", "#BFBCB4", "#BFAA88"],
	["#EFEDE6", "#E4DBC5", "#D4D1C9", "#D0BE9E"],
]


static func axes() -> Dictionary:
	return {
		"monument": ["tower", "twinned", "brigade", "collapse", "exploded"],
		"sheet": ["torn", "thread", "bloom", "slab"],
	}


static func describe() -> String:
	return "A leaning constructivist tower of thin red steel bars triangulating in space, with torn white and cream paper planes skewered through the frame and leaning on the floor."


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var monument: String = String(opts.get("monument", "tower"))
	var sheet_mode: String = String(opts.get("sheet", "torn"))

	# member budgets — a cloned monument must still fit inside the 260-mesh contract
	var edge_cap: int = 84
	var gusset_cap: int = 18
	var spear_cap: int = 6
	var spear_reach: float = 0.48
	var sheet_reach: float = 0.33
	var sheet_budget: int = 80
	var clones: int = 0
	if monument == "twinned":
		edge_cap = 44
		gusset_cap = 8
		spear_cap = 4
		sheet_budget = 40
		clones = 1
	elif monument == "brigade":
		edge_cap = 18
		gusset_cap = 4
		spear_cap = 3
		sheet_budget = 22
		clones = 3
	elif monument == "collapse":
		spear_reach = 0.78
		sheet_reach = 0.62
	var per_sheet: int = 1
	if sheet_mode == "thread":
		per_sheet = 14
	elif sheet_mode == "bloom":
		per_sheet = 7
	var sheet_cap: int = clampi(int(float(sheet_budget) / float(per_sheet)), 2, 12)

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var reds: Array = RED_SETS[rng.randi_range(0, RED_SETS.size() - 1)]
	var papers: Array = PAPER_SETS[rng.randi_range(0, PAPER_SETS.size() - 1)]

	var enamel_tex: ImageTexture = _enamel_texture(rng)
	var paper_tex: ImageTexture = _paper_texture(rng)

	var mat_red_a: StandardMaterial3D = _enamel(Color(reds[0]), enamel_tex)
	var mat_red_b: StandardMaterial3D = _enamel(Color(reds[1]), enamel_tex)
	var mat_red_c: StandardMaterial3D = _enamel(Color(reds[2]), enamel_tex)
	var mat_red_d: StandardMaterial3D = _enamel(Color(reds[3]), enamel_tex)
	var reds_mat: Array = [mat_red_a, mat_red_b, mat_red_c]

	var sheet_mats: Array = [
		_paper_mat(Color(papers[0]), paper_tex),
		_paper_mat(Color(papers[0]), paper_tex),
		_paper_mat(Color(papers[1]), paper_tex),
		_paper_mat(Color(papers[1]), paper_tex),
		_paper_mat(Color(papers[2]), paper_tex),
		_paper_mat(Color(papers[3]), paper_tex),
	]
	var mat_red_sheet: StandardMaterial3D = _paper_mat(Color(reds[0]), paper_tex)
	# fossil stone, for the slab sheets — dead weight where the paper was
	var mat_stone: StandardMaterial3D = _paper_mat(Color(papers[2]).darkened(0.38), paper_tex)
	mat_stone.roughness = 1.0
	mat_stone.uv1_scale = Vector3(0.85, 0.85, 0.85)

	# --- the individual --------------------------------------------------------
	var levels: int = rng.randi_range(6, 8)
	var y_base: float = rng.randf_range(0.11, 0.18)
	var h_top: float = rng.randf_range(1.32, 1.46)
	var lean_dir: float = rng.randf_range(0.0, TAU)
	var lean_amt: float = rng.randf_range(0.10, 0.23)
	var r_base: float = rng.randf_range(0.25, 0.33)
	var r_top: float = rng.randf_range(0.07, 0.14)
	var twist: float = rng.randf_range(-0.55, 0.55)
	var bar_w: float = rng.randf_range(0.019, 0.029)
	var bar_t: float = rng.randf_range(0.011, 0.017)
	var rod_r: float = rng.randf_range(0.008, 0.013)

	# --- nodes -----------------------------------------------------------------
	var nodes: Array = []
	var level_start: Array = []
	var level_count: Array = []
	for k in range(levels + 1):
		var kk: int = int(k)
		var t: float = float(kk) / float(levels)
		var cy: float = y_base + (h_top - y_base) * pow(t, 0.97)
		var drift: float = lean_amt * t * t
		var cx: float = cos(lean_dir) * drift
		var cz: float = sin(lean_dir) * drift
		var n_here: int = 4
		if kk == levels:
			n_here = 2
		elif kk > 0:
			n_here = rng.randi_range(3, 4)
		level_start.append(nodes.size())
		level_count.append(n_here)
		var a0: float = twist * t * TAU + rng.randf_range(-0.35, 0.35)
		for j in range(n_here):
			var ang: float = a0 + float(j) * TAU / float(n_here) + rng.randf_range(-0.22, 0.22)
			var rr: float = lerpf(r_base, r_top, pow(t, 0.85)) * rng.randf_range(0.76, 1.22)
			var yj: float = rng.randf_range(-0.04, 0.04)
			nodes.append(Vector3(cx + cos(ang) * rr, cy + yj, cz + sin(ang) * rr))

	# --- the tower gives way: the higher a node stood, the further it slumps --------
	if monument == "collapse":
		var flow_a: float = lean_dir + rng.randf_range(-0.7, 0.7)
		var spread: float = rng.randf_range(1.65, 2.20)
		for i in range(nodes.size()):
			var ni: int = int(i)
			var pn: Vector3 = nodes[ni]
			var tn: float = clampf(pn.y / maxf(h_top, 0.02), 0.0, 1.0)
			var sag: float = pow(tn, 1.25)
			var kout: float = 1.0 + (spread - 1.0) * sag
			var nx: float = pn.x * kout + cos(flow_a) * 0.34 * sag
			var nz: float = pn.z * kout + sin(flow_a) * 0.34 * sag
			var ny: float = pn.y * (1.0 - 0.74 * sag) + 0.015 * sag
			nodes[ni] = Vector3(nx, maxf(ny, 0.012), nz)

	var n_nodes: int = nodes.size()
	var deg: Array = []
	for i in range(n_nodes):
		deg.append(0)

	# --- edges: rings, rising pairs, skip diagonals -----------------------------
	var edges: Array = []
	var seen := {}
	for k in range(levels + 1):
		var s: int = int(level_start[k])
		var c: int = int(level_count[k])
		if c == 2:
			_push_edge(edges, seen, deg, s, s + 1)
		elif c >= 3:
			for j in range(c):
				var jn: int = (int(j) + 1) % c
				_push_edge(edges, seen, deg, s + int(j), s + jn)

	for k in range(levels):
		var s0: int = int(level_start[k])
		var c0: int = int(level_count[k])
		var s1: int = int(level_start[k + 1])
		var c1: int = int(level_count[k + 1])
		for a in range(c0):
			var ia: int = s0 + int(a)
			var pa: Vector3 = nodes[ia]
			var best: int = -1
			var second: int = -1
			var db: float = 1.0e9
			var ds: float = 1.0e9
			for b in range(c1):
				var ib: int = s1 + int(b)
				var pb: Vector3 = nodes[ib]
				var dd: float = (pb - pa).length()
				if dd < db:
					ds = db
					second = best
					db = dd
					best = ib
				elif dd < ds:
					ds = dd
					second = ib
			if best >= 0:
				_push_edge(edges, seen, deg, ia, best)
			if second >= 0 and rng.randf() < 0.70:
				_push_edge(edges, seen, deg, ia, second)
		# every upper node must be carried by something below it
		for b2 in range(c1):
			var iu: int = s1 + int(b2)
			var pu: Vector3 = nodes[iu]
			var bestd: int = -1
			var dbd: float = 1.0e9
			for a2 in range(c0):
				var il: int = s0 + int(a2)
				var pl: Vector3 = nodes[il]
				var dl: float = (pu - pl).length()
				if dl < dbd:
					dbd = dl
					bestd = il
			if bestd >= 0:
				_push_edge(edges, seen, deg, iu, bestd)

	var n_skip: int = rng.randi_range(3, 6)
	for i in range(n_skip):
		if levels < 2:
			break
		var k: int = rng.randi_range(0, levels - 2)
		var ia2: int = int(level_start[k]) + rng.randi_range(0, int(level_count[k]) - 1)
		var ib2: int = int(level_start[k + 2]) + rng.randi_range(0, int(level_count[k + 2]) - 1)
		_push_edge(edges, seen, deg, ia2, ib2)

	while edges.size() > edge_cap:
		edges.remove_at(edges.size() - 1)

	# --- struts ----------------------------------------------------------------
	for e in edges:
		var pair: Array = e
		var ia3: int = int(pair[0])
		var ib3: int = int(pair[1])
		var a3: Vector3 = nodes[ia3]
		var b3: Vector3 = nodes[ib3]
		var d3: Vector3 = b3 - a3
		if d3.length() < 0.02:
			continue
		var dir3: Vector3 = d3.normalized()
		if rng.randf() < 0.34:
			b3 = b3 + dir3 * rng.randf_range(0.03, 0.13)
		if rng.randf() < 0.16:
			a3 = a3 - dir3 * rng.randf_range(0.03, 0.10)
		a3 = Vector3(a3.x, maxf(a3.y, 0.006), a3.z)
		b3 = Vector3(b3.x, maxf(b3.y, 0.006), b3.z)
		var mat_s: StandardMaterial3D = reds_mat[rng.randi_range(0, 2)]
		if rng.randf() < 0.16:
			mat_s = mat_red_d
		if rng.randf() < 0.74:
			var kw: float = rng.randf_range(0.85, 1.2)
			_bar(root, a3, b3, bar_w * kw, bar_t * kw, rng.randf_range(0.0, TAU), mat_s)
		else:
			_rod(root, a3, b3, rod_r * rng.randf_range(0.85, 1.2), mat_s)

	# --- legs down to the floor, with bolt plates -------------------------------
	var c_base: int = int(level_count[0])
	for j in range(c_base):
		var ib4: int = int(level_start[0]) + int(j)
		var top_p: Vector3 = nodes[ib4]
		var splay: float = rng.randf_range(1.04, 1.28)
		var foot := Vector3(top_p.x * splay, 0.008, top_p.z * splay)
		var mat_l: StandardMaterial3D = reds_mat[rng.randi_range(0, 2)]
		_bar(root, foot, top_p, bar_w * 1.15, bar_t * 1.15, rng.randf_range(0.0, TAU), mat_l)
		var pad := BoxMesh.new()
		var pw: float = rng.randf_range(0.055, 0.082)
		pad.size = Vector3(pw, 0.011, pw * rng.randf_range(0.7, 1.0))
		var pm: MeshInstance3D = _add(root, pad, mat_red_d)
		pm.transform = Transform3D(Basis(Vector3.UP, rng.randf_range(0.0, TAU)), Vector3(foot.x, 0.006, foot.z))

	# --- free spears, leaving the frame ----------------------------------------
	var n_spear: int = rng.randi_range(4, 6)
	n_spear = mini(n_spear, spear_cap)
	for i in range(n_spear):
		var ii: int = int(i)
		var src: int = rng.randi_range(0, n_nodes - 1)
		var up_bias: float = rng.randf_range(-0.3, 1.0)
		if ii < 2:
			src = rng.randi_range(int(level_start[levels - 1]), n_nodes - 1)
			up_bias = rng.randf_range(0.7, 1.25)
		var a5: Vector3 = nodes[src]
		var ang5: float = rng.randf_range(0.0, TAU)
		var ln5: float = rng.randf_range(0.20, 0.46)
		if ii < 2:
			ln5 = rng.randf_range(0.28, 0.50)
		var d5: Vector3 = Vector3(cos(ang5) * 0.8, up_bias, sin(ang5) * 0.8).normalized()
		var b5: Vector3 = a5 + d5 * ln5
		var hb: float = sqrt(b5.x * b5.x + b5.z * b5.z)
		if hb > spear_reach:
			var kh: float = spear_reach / hb
			b5 = Vector3(b5.x * kh, b5.y, b5.z * kh)
		b5 = Vector3(b5.x, clampf(b5.y, 0.02, 1.62), b5.z)
		var mat_sp: StandardMaterial3D = reds_mat[rng.randi_range(0, 2)]
		_bar(root, a5, b5, bar_w * rng.randf_range(0.8, 1.05), bar_t, rng.randf_range(0.0, TAU), mat_sp)

	# --- gusset cubes where the welds pile up -----------------------------------
	var nubs: int = 0
	for i in range(n_nodes):
		var idx: int = int(i)
		if nubs >= gusset_cap:
			break
		if int(deg[idx]) < 4:
			continue
		if rng.randf() < 0.25:
			continue
		nubs += 1
		var np: Vector3 = nodes[idx]
		var sg: float = rng.randf_range(0.030, 0.047)
		var gb := BoxMesh.new()
		gb.size = Vector3(sg, sg * rng.randf_range(0.5, 0.9), sg * rng.randf_range(0.7, 1.1))
		var gm: MeshInstance3D = _add(root, gb, mat_red_d)
		var gbasis: Basis = Basis(Vector3.UP, rng.randf_range(0.0, TAU)) * Basis(Vector3.RIGHT, rng.randf_range(-0.7, 0.7))
		gm.transform = Transform3D(gbasis, np)

	# --- the pour: a solid red pool the wreck lies half inside --------------------
	if monument == "collapse":
		var pool_r: float = rng.randf_range(0.46, 0.62)
		for i in range(4):
			var ri: int = int(i)
			var fr: float = float(ri) / 4.0
			var rr2: float = pool_r * (1.0 - 0.19 * fr)
			var cyl := CylinderMesh.new()
			cyl.top_radius = rr2 * 0.93
			cyl.bottom_radius = rr2
			cyl.height = 0.030
			cyl.radial_segments = 18
			cyl.rings = 1
			var mat_p: StandardMaterial3D = mat_red_d
			if ri % 2 == 1:
				mat_p = mat_red_b
			var pmi: MeshInstance3D = _add(root, cyl, mat_p)
			var poy: float = 0.015 + float(ri) * 0.026
			pmi.transform = Transform3D(Basis(Vector3.UP, rng.randf_range(0.0, TAU)), Vector3(rng.randf_range(-0.03, 0.03), poy, rng.randf_range(-0.03, 0.03)))
		var tongues: int = rng.randi_range(5, 8)
		for i in range(tongues):
			var ta: float = rng.randf_range(0.0, TAU)
			var tb := BoxMesh.new()
			tb.size = Vector3(rng.randf_range(0.07, 0.17), 0.022, rng.randf_range(0.16, 0.42))
			var tmi: MeshInstance3D = _add(root, tb, mat_red_d)
			var td: float = pool_r * rng.randf_range(0.55, 0.98)
			tmi.transform = Transform3D(Basis(Vector3.UP, PI * 0.5 - ta), Vector3(cos(ta) * td, 0.011, sin(ta) * td))

	# --- torn planes, skewered and leaning --------------------------------------
	var n_sheets: int = rng.randi_range(7, 12)
	n_sheets = mini(n_sheets, sheet_cap)
	var red_sheet_at: int = rng.randi_range(0, n_sheets - 1)
	for i in range(n_sheets):
		var si: int = int(i)
		var leaner: bool = si < 3 and rng.randf() < 0.75
		var anchor: Vector3 = nodes[rng.randi_range(0, n_nodes - 1)]
		var oang: float = rng.randf_range(0.0, TAU)
		var orad: float = rng.randf_range(0.02, 0.24)
		var px: float = anchor.x + cos(oang) * orad
		var pz: float = anchor.z + sin(oang) * orad
		var horiz: float = sqrt(px * px + pz * pz)
		if horiz > sheet_reach:
			var kc: float = sheet_reach / horiz
			px *= kc
			pz *= kc
			horiz = sheet_reach
		var rad: float = clampf(0.46 - 0.55 * horiz, 0.18, 0.40)
		var sx: float = rng.randf_range(0.62, 0.92)
		var sy: float = rng.randf_range(1.02, 1.42)
		var py: float = anchor.y + rng.randf_range(-0.14, 0.10)
		if leaner:
			py = rad * sy * rng.randf_range(0.88, 1.02)
		py = minf(py, 1.58 - rad * sy * 0.9)
		py = maxf(py, rad * sy * 0.32)

		var n_v: int = rng.randi_range(5, 9)
		var thick: float = rng.randf_range(0.005, 0.010)
		var fold: float = 0.0
		if rng.randf() < 0.55:
			fold = rng.randf_range(0.10, 0.30)
		var mesh: ArrayMesh = null
		if sheet_mode == "slab":
			var nv_s: int = rng.randi_range(4, 6)
			var th_s: float = rng.randf_range(0.085, 0.185)
			mesh = _sheet_mesh(rng, rad * 1.16, nv_s, th_s, 0.0, sx * 1.10, sy * 0.86)
		elif sheet_mode != "thread" and sheet_mode != "bloom":
			mesh = _sheet_mesh(rng, rad, n_v, thick, fold, sx, sy)

		var face_yaw: float = rng.randf_range(0.0, TAU)
		var tilt_x: float = deg_to_rad(rng.randf_range(-32.0, 32.0))
		if leaner:
			var sgn: float = 1.0 if rng.randf() < 0.5 else -1.0
			tilt_x = deg_to_rad(rng.randf_range(18.0, 40.0)) * sgn
		var roll_z: float = deg_to_rad(rng.randf_range(-24.0, 24.0))
		var sb: Basis = Basis(Vector3.UP, face_yaw) * Basis(Vector3.RIGHT, tilt_x) * Basis(Vector3.FORWARD, roll_z)

		var mat_sheet: StandardMaterial3D = sheet_mats[rng.randi_range(0, sheet_mats.size() - 1)]
		if si == red_sheet_at:
			mat_sheet = mat_red_sheet
		if mesh != null:
			var mat_use: StandardMaterial3D = mat_sheet
			if sheet_mode == "slab":
				mat_use = mat_stone
			var sm: MeshInstance3D = _add(root, mesh, mat_use)
			var tf: Transform3D = Transform3D(sb, Vector3(px, py, pz))
			var wb: AABB = tf * mesh.get_aabb()
			if wb.position.y < 0.004:
				tf.origin.y += 0.004 - wb.position.y
			sm.transform = tf
		elif sheet_mode == "thread":
			_thread_sheet(root, rng, Vector3(px, py, pz), sb, rad, n_v, sx, sy, mat_sheet)
		else:
			_bloom_sheet(root, rng, Vector3(px, py, pz), sb, rad, sx, sy, mat_sheet, mat_red_c)

	# --- every member drifts off along its own outward normal --------------------
	if monument == "exploded":
		var eb: AABB = _union_aabb(root)
		var ec: Vector3 = eb.position + eb.size * 0.5
		var blast: float = rng.randf_range(1.55, 2.05)
		for ch3 in root.get_children():
			if not (ch3 is MeshInstance3D):
				continue
			var em: MeshInstance3D = ch3
			var etf: Transform3D = em.transform
			var rel: Vector3 = etf.origin - ec
			var flat := Vector3(rel.x, 0.0, rel.z)
			var outv := Vector3(1.0, 0.0, 0.0)
			if flat.length() > 0.004:
				outv = flat.normalized()
			else:
				var ra: float = rng.randf_range(0.0, TAU)
				outv = Vector3(cos(ra), 0.0, sin(ra))
			var kick: float = rng.randf_range(0.05, 0.17)
			var ax := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
			if ax.length() < 0.02:
				ax = Vector3.UP
			var tumble: Basis = Basis(ax.normalized(), rng.randf_range(-0.42, 0.42))
			em.transform = Transform3D(tumble * etf.basis, ec + rel * blast + outv * kick)

	# --- the monument doubles, or breaks into a crowd of itself -------------------
	if clones > 0:
		var originals: Array = []
		for ch4 in root.get_children():
			if ch4 is MeshInstance3D:
				originals.append(ch4)
		var n_unit: int = originals.size()
		var use_clones: int = mini(clones, maxi(0, int(252.0 / float(maxi(n_unit, 1))) - 1))
		if use_clones > 0 and monument == "twinned":
			var pv := Vector3(cos(lean_dir) * lean_amt, h_top * rng.randf_range(0.80, 0.94), sin(lean_dir) * lean_amt)
			var flip: Basis = Basis(Vector3.UP, rng.randf_range(0.0, TAU)) * Basis(Vector3.RIGHT, PI)
			_clone_all(root, originals, Transform3D(flip, pv - flip * pv))
		elif use_clones > 0:
			var slots: int = use_clones + 1
			var base_a: float = rng.randf_range(0.0, TAU)
			var xf0 := Transform3D()
			for i in range(slots):
				var isl: int = int(i)
				var ang_s: float = base_a + float(isl) * TAU / float(slots) + rng.randf_range(-0.32, 0.32)
				var rad_s: float = rng.randf_range(0.24, 0.48)
				var k_s: float = rng.randf_range(0.34, 0.58)
				if isl == 0:
					rad_s = rng.randf_range(0.0, 0.12)
					k_s = rng.randf_range(0.52, 0.72)
				var bs: Basis = Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(k_s, k_s, k_s))
				var xfi := Transform3D(bs, Vector3(cos(ang_s) * rad_s, 0.0, sin(ang_s) * rad_s))
				if isl == 0:
					xf0 = xfi
				else:
					_clone_all(root, originals, xfi)
			for o2 in originals:
				var so: MeshInstance3D = o2
				so.transform = xf0 * so.transform

	# --- measured settle: floor it, centre it, fit it ---------------------------
	var box: AABB = _union_aabb(root)
	var w_now: float = maxf(box.size.x, box.size.z)
	var kfit: float = 1.0
	if w_now > 1.2:
		kfit = minf(kfit, 1.2 / w_now)
	if box.size.y > 1.68:
		kfit = minf(kfit, 1.68 / box.size.y)
	if kfit < 1.0:
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cm: MeshInstance3D = ch
			var ctf: Transform3D = cm.transform
			cm.transform = Transform3D(ctf.basis.scaled(Vector3(kfit, kfit, kfit)), ctf.origin * kfit)
		box = _union_aabb(root)
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
# graph helper

static func _push_edge(edges: Array, seen: Dictionary, deg: Array, a: int, b: int) -> void:
	if a == b:
		return
	var lo: int = mini(a, b)
	var hi: int = maxi(a, b)
	var key: int = lo * 8192 + hi
	if seen.has(key):
		return
	seen[key] = true
	edges.append([lo, hi])
	deg[lo] = int(deg[lo]) + 1
	deg[hi] = int(deg[hi]) + 1


# ---------------------------------------------------------------------------
# members

static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _bar(root: Node3D, a: Vector3, b: Vector3, w: float, t: float, roll: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.02)
	var bx := BoxMesh.new()
	bx.size = Vector3(w, ln, t)
	var mi: MeshInstance3D = _add(root, bx, mat)
	mi.transform = Transform3D(_basis_y_to(d) * Basis(Vector3.UP, roll), (a + b) * 0.5)
	return mi


static func _rod(root: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.02)
	var cy := CylinderMesh.new()
	cy.top_radius = r
	cy.bottom_radius = r
	cy.height = ln
	cy.radial_segments = 8
	cy.rings = 1
	var mi: MeshInstance3D = _add(root, cy, mat)
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


# ---------------------------------------------------------------------------
# the sheet, unravelled — its outline left behind as sagging cord

static func _thread_sheet(root: Node3D, rng: RandomNumberGenerator, org: Vector3, sb: Basis, rad: float, n_v: int, sx: float, sy: float, mat: StandardMaterial3D) -> void:
	var pts: Array = []
	var a0: float = rng.randf_range(0.0, TAU)
	for i in range(n_v):
		var iv: int = int(i)
		var f: float = float(iv) / float(n_v)
		var ang: float = a0 + f * TAU + rng.randf_range(-0.24, 0.24)
		var rr: float = rad * rng.randf_range(0.55, 1.02)
		var loc := Vector3(cos(ang) * rr * sx, sin(ang) * rr * sy, rng.randf_range(-0.035, 0.035))
		pts.append(org + sb * loc)
	var thr: float = rng.randf_range(0.0035, 0.0065)
	var m: int = pts.size()
	for i in range(m):
		var ia: int = int(i)
		var pa: Vector3 = pts[ia]
		var pb: Vector3 = pts[(ia + 1) % m]
		_rod(root, pa, pb, thr, mat)
	var chords: int = rng.randi_range(1, 2)
	for i in range(chords):
		var i1: int = rng.randi_range(0, m - 1)
		var i2: int = (i1 + rng.randi_range(2, maxi(2, m - 2))) % m
		var q1: Vector3 = pts[i1]
		var q2: Vector3 = pts[i2]
		var mid: Vector3 = (q1 + q2) * 0.5 + Vector3(0.0, -rng.randf_range(0.02, 0.09), 0.0)
		_rod(root, q1, mid, thr * 0.8, mat)
		_rod(root, mid, q2, thr * 0.8, mat)


# ---------------------------------------------------------------------------
# the sheet, opened — a paper flower on a red bud

static func _bloom_sheet(root: Node3D, rng: RandomNumberGenerator, org: Vector3, sb: Basis, rad: float, sx: float, sy: float, mat: StandardMaterial3D, core_mat: StandardMaterial3D) -> void:
	var petals: int = rng.randi_range(4, 6)
	var plen: float = rad * rng.randf_range(0.66, 1.00)
	var pitch: float = deg_to_rad(rng.randf_range(26.0, 64.0))
	var yaw0: float = rng.randf_range(0.0, TAU)
	var span: float = plen * 1.45 * maxf(sy, 0.4) * 0.62
	for i in range(petals):
		var ip: int = int(i)
		var yaw: float = yaw0 + float(ip) * TAU / float(petals) + rng.randf_range(-0.16, 0.16)
		var fold_p: float = rng.randf_range(0.10, 0.28)
		var pm: ArrayMesh = _sheet_mesh(rng, plen, 4, 0.005, fold_p, 0.42 * sx, 1.45 * sy)
		var tip: float = -pitch + rng.randf_range(-0.20, 0.20)
		var pb: Basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, tip)
		var loc: Vector3 = pb * Vector3(0.0, span, 0.0)
		var mi: MeshInstance3D = _add(root, pm, mat)
		mi.transform = Transform3D(sb * pb, org + sb * loc)
	var core := SphereMesh.new()
	var cr: float = rad * rng.randf_range(0.11, 0.17)
	core.radius = cr
	core.height = cr * 2.0
	core.radial_segments = 10
	core.rings = 6
	var cmi: MeshInstance3D = _add(root, core, core_mat)
	cmi.transform = Transform3D(Basis(), org)


# ---------------------------------------------------------------------------
# a second body, made of the first one's own parts

static func _clone_all(root: Node3D, originals: Array, xf: Transform3D) -> void:
	for o in originals:
		var src: MeshInstance3D = o
		var mi := MeshInstance3D.new()
		mi.mesh = src.mesh
		mi.material_override = src.material_override
		root.add_child(mi)
		mi.transform = xf * src.transform


# ---------------------------------------------------------------------------
# torn, folded sheet

static func _sheet_mesh(rng: RandomNumberGenerator, rad: float, n_v: int, thick: float, fold: float, sx: float, sy: float) -> ArrayMesh:
	var outline: Array = []
	var a0: float = rng.randf_range(0.0, TAU)
	for i in range(n_v):
		var f: float = float(i) / float(n_v)
		var ang: float = a0 + f * TAU + rng.randf_range(-0.24, 0.24)
		var rr: float = rad * rng.randf_range(0.50, 0.86)
		if rng.randf() < 0.34:
			rr = rad * rng.randf_range(0.90, 1.0)
		outline.append(Vector2(cos(ang) * rr * sx, sin(ang) * rr * sy))

	# insert a vertex where the outline crosses the crease at x = 0
	var pts: Array = []
	var n: int = outline.size()
	for i in range(n):
		var i2: int = (int(i) + 1) % n
		var p: Vector2 = outline[i]
		var q: Vector2 = outline[i2]
		pts.append(p)
		if (p.x < 0.0 and q.x > 0.0) or (p.x > 0.0 and q.x < 0.0):
			var tc: float = p.x / (p.x - q.x)
			pts.append(Vector2(0.0, lerpf(p.y, q.y, tc)))

	var mid: Array = []
	for i in range(pts.size()):
		var pp: Vector2 = pts[i]
		var zz: float = fold * maxf(0.0, pp.x)
		mid.append(Vector3(pp.x, pp.y, zz))

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var m: int = mid.size()
	var half := Vector3(0.0, 0.0, thick * 0.5)
	var cen := Vector3.ZERO
	for i in range(m):
		var i3: int = (int(i) + 1) % m
		var va: Vector3 = mid[i]
		var vb: Vector3 = mid[i3]
		var tri_mid: Vector3 = (va + vb + cen) / 3.0
		_tri_out(st, cen + half, va + half, vb + half, tri_mid)
		_tri_out(st, cen - half, va - half, vb - half, tri_mid)
		var inside: Vector3 = (va + vb) * 0.25
		_quad_out(st, va + half, vb + half, vb - half, va - half, inside)
	st.generate_normals()
	return st.commit()


static func _tri_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, inside: Vector3) -> void:
	var nf: Vector3 = (c - a).cross(b - a)
	var centroid: Vector3 = (a + b + c) / 3.0
	if nf.dot(centroid - inside) >= 0.0:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)
	else:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)


static func _quad_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, inside: Vector3) -> void:
	var nf: Vector3 = (c - a).cross(b - a)
	var centroid: Vector3 = (a + b + c + d) * 0.25
	if nf.dot(centroid - inside) >= 0.0:
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


# ---------------------------------------------------------------------------
# surfaces

static func _enamel(c: Color, tex: ImageTexture) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(3.0, 3.0, 3.0)
	m.roughness = 0.52
	m.metallic = 0.0
	m.clearcoat_enabled = true
	m.clearcoat = 0.18
	m.clearcoat_roughness = 0.55
	return m


static func _paper_mat(c: Color, tex: ImageTexture) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(1.7, 1.7, 1.7)
	m.roughness = 0.95
	m.metallic = 0.0
	return m


static func _grid(rng: RandomNumberGenerator, n: int) -> PackedFloat32Array:
	var g := PackedFloat32Array()
	g.resize(n * n)
	for i in range(n * n):
		g[int(i)] = rng.randf()
	return g


static func _sample(g: PackedFloat32Array, n: int, u: float, v: float) -> float:
	var fx: float = u * float(n)
	var fy: float = v * float(n)
	var x0: int = int(floor(fx))
	var y0: int = int(floor(fy))
	var tx: float = fx - float(x0)
	var ty: float = fy - float(y0)
	var s_x: float = tx * tx * (3.0 - 2.0 * tx)
	var s_y: float = ty * ty * (3.0 - 2.0 * ty)
	var i00: float = g[posmod(y0, n) * n + posmod(x0, n)]
	var i10: float = g[posmod(y0, n) * n + posmod(x0 + 1, n)]
	var i01: float = g[posmod(y0 + 1, n) * n + posmod(x0, n)]
	var i11: float = g[posmod(y0 + 1, n) * n + posmod(x0 + 1, n)]
	var ra: float = lerpf(i00, i10, s_x)
	var rb: float = lerpf(i01, i11, s_x)
	return lerpf(ra, rb, s_y)


static func _enamel_texture(rng: RandomNumberGenerator) -> ImageTexture:
	# matte enamel: broad roll mottle, fine grain, a few chips. Near-white so the
	# albedo_color carries the hue.
	var img: Image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	var g_a: PackedFloat32Array = _grid(rng, 8)
	var g_b: PackedFloat32Array = _grid(rng, 24)
	for y in range(TEX_SIZE):
		var v: float = float(y) / float(TEX_SIZE)
		for x in range(TEX_SIZE):
			var u: float = float(x) / float(TEX_SIZE)
			var n1: float = _sample(g_a, 8, u, v)
			var n2: float = _sample(g_b, 24, u, v)
			var val: float = 0.90 + 0.09 * n1 + 0.05 * (n2 - 0.5)
			if rng.randf() < 0.0035:
				val -= rng.randf_range(0.10, 0.24)
			val = clampf(val, 0.42, 1.0)
			img.set_pixel(x, y, Color(val, val * 0.995, val * 0.985))
	return ImageTexture.create_from_image(img)


static func _paper_texture(rng: RandomNumberGenerator) -> ImageTexture:
	# matte card: fibre noise, a soft cloud, faint fold streaks, dark flecks.
	var img: Image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	var g_a: PackedFloat32Array = _grid(rng, 32)
	var g_b: PackedFloat32Array = _grid(rng, 6)
	var ph: float = rng.randf_range(0.0, TAU)
	for y in range(TEX_SIZE):
		var v: float = float(y) / float(TEX_SIZE)
		for x in range(TEX_SIZE):
			var u: float = float(x) / float(TEX_SIZE)
			var fine: float = _sample(g_a, 32, u, v)
			var soft: float = _sample(g_b, 6, u, v)
			var streak: float = pow(maxf(0.0, sin(u * TAU * 2.0 + ph)), 14.0)
			var val: float = 0.94 + 0.05 * (fine - 0.5) + 0.05 * (soft - 0.5) - 0.06 * streak
			if rng.randf() < 0.002:
				val -= rng.randf_range(0.08, 0.20)
			val = clampf(val, 0.5, 1.0)
			img.set_pixel(x, y, Color(val, val, val * 0.995))
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
