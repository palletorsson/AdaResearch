extends RefCounted

## dream_bodies / pink_scaffold — one standing shard of the constructivist thicket.
##
## Reference: scratchpad/refs/tatlin_lava.png (2048x536 panorama) — a wall-wide
## jam of big flat angular plates in dusty pink and chalk white, torn polygonal
## outlines, a few pierced by round bolt holes, skewered and interpenetrating in
## a dense thicket, with thin signal-orange tubular struts triangulating through
## and around them and running on past their joints, all against black.
##
## Reproduced, and how:
##   1. Torn angular plates — an ArrayMesh per plate: a 5..9 vertex polygon with
##      jittered angles and radii, one or two vertices pulled in to 30..48% for a
##      concave tear, sometimes one pulled out to 1.7..2.5x for a blade spike.
##      The outline is sampled by exact ray/edge intersection so the sides stay
##      dead straight, then extruded 20..38 mm with flat-shaded caps and walls.
##   2. Bolt holes — about a quarter of the plates are built as a ring instead of
##      a fan: an inner circle of the same angular samples gives a real punched
##      hole with its own inner wall.
##   3. The thicket — a leaning axis (13..23 cm of horizontal drift at the top,
##      random azimuth) with a node cloud whose radius falls 0.27 -> 0.085 m as it
##      rises; plate size falls with height too, so the mass leans AND thins.
##   4. Skewering — 45% of plates sit on a strut, at 22..78% along it, with their
##      normal within 52 deg of the strut axis, so the tube passes bodily through
##      the sheet; the rest lean on nodes at near-vertical planes.
##   5. Orange triangulation — struts are drawn on a node graph: a nearest
##      neighbour pass for connectivity, then random mutually-near triples added
##      as complete triangles. 12..20 mm CylinderMesh, and each one overshoots
##      its joints by up to 13 cm so the tubes carry on past the frame.
##   6. Welded joints — a small orange sphere at every node of degree three or
##      more, up to twenty of them.
##   7. Asymmetry — a free-standing outrigger of 4..6 low nodes pushed out to one
##      side, wired into the main graph as a leaning tube tripod with almost no
##      plates on it, the way the reference lets one orange armature stand clear.
##   8. Matte enamel — a 128x128 grain texture painted in code (fine speckle,
##      faint brush streaks, scuff dots) run triplanar so it crosses plate and
##      tube alike; pink/white split and shades chosen per seed.
##
## Given up: the wall-scale scene (this is one standing tangle, not the row), the
## black ground and spotlight, the folded and creased plates of the reference
## (mine are flat), and the plates that actually cut notches into each other.

const TEX_SIZE: int = 128

const PINKS: Array = ["#B8748C", "#C4869B", "#A96579", "#CB93A6", "#B26E86"]
const WHITES: Array = ["#F1EFEB", "#E6E3DD", "#F6F4F1"]
const ORANGES: Array = ["#F07E1E", "#E96F18", "#F58A26"]


static func describe() -> String:
	return "A leaning constructivist thicket of torn dusty-pink and white plates skewered together and triangulated by thin signal-orange tubes that run on past their joints."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- individual parameters ---------------------------------------------
	var height: float = rng.randf_range(1.42, 1.54)
	var lean_az: float = rng.randf_range(0.0, TAU)
	var lean_amt: float = rng.randf_range(0.11, 0.19)
	var lean := Vector2(cos(lean_az) * lean_amt, sin(lean_az) * lean_amt)
	var white_frac: float = rng.randf_range(0.28, 0.50)
	var n_plates: int = rng.randi_range(22, 42)
	var n_ground: int = rng.randi_range(4, 6)
	var n_spine: int = rng.randi_range(18, 26)
	var n_out: int = rng.randi_range(4, 6)
	var strut_target: int = rng.randi_range(38, 56)
	var out_az: float = lean_az + rng.randf_range(1.8, 4.5)

	var code_p: String = PINKS[rng.randi_range(0, PINKS.size() - 1)]
	var code_p2: String = PINKS[rng.randi_range(0, PINKS.size() - 1)]
	var code_w: String = WHITES[rng.randi_range(0, WHITES.size() - 1)]
	var code_o: String = ORANGES[rng.randi_range(0, ORANGES.size() - 1)]
	var col_pink: Color = Color(code_p)
	var col_pink2: Color = Color(code_p2)
	var col_white: Color = Color(code_w)
	var col_orange: Color = Color(code_o)

	var tex_plate: ImageTexture = _enamel_texture(rng, 0.026, 26, 34)
	var tex_tube: ImageTexture = _enamel_texture(rng, 0.014, 12, 10)
	var mat_tube: StandardMaterial3D = _enamel(col_orange, tex_tube, 2.4, 0.42)
	var mat_knob: StandardMaterial3D = _enamel(col_orange.lightened(0.06), tex_tube, 3.0, 0.40)

	# --- node cloud ---------------------------------------------------------
	var nodes: Array = []
	for i in range(n_ground):
		var ga: float = float(i) / float(n_ground) * TAU + rng.randf_range(-0.45, 0.45)
		var gr: float = rng.randf_range(0.13, 0.28)
		nodes.append(Vector3(cos(ga) * gr, rng.randf_range(0.03, 0.11), sin(ga) * gr))
	for i in range(n_spine):
		var u: float = float(i + 1) / float(n_spine)
		var t: float = pow(u, 1.18)
		var rad: float = lerpf(0.27, 0.085, pow(t, 0.75)) * rng.randf_range(0.32, 1.06)
		var na: float = rng.randf_range(0.0, TAU)
		var c: Vector3 = _axis_pt(t, height, lean)
		var ny: float = maxf(c.y + rng.randf_range(-0.06, 0.06), 0.04)
		nodes.append(Vector3(c.x + cos(na) * rad, ny, c.z + sin(na) * rad))
	for i in range(n_out):
		var f: float = float(i) / float(maxi(n_out - 1, 1))
		var oa: float = out_az + rng.randf_range(-0.55, 0.55)
		var orad: float = lerpf(0.30, 0.20, f) * rng.randf_range(0.85, 1.15)
		var oy: float = lerpf(0.05, 0.72, f) * rng.randf_range(0.85, 1.15)
		nodes.append(Vector3(cos(oa) * orad, maxf(oy, 0.03), sin(oa) * orad))

	var n_nodes: int = nodes.size()

	# --- strut graph: nearest neighbour spine, then triangles ---------------
	var seen: Dictionary = {}
	var edge_list: Array = []
	for i in range(n_nodes):
		var pa: Vector3 = nodes[i]
		var best: int = -1
		var best_d: float = 1.0e9
		for j in range(n_nodes):
			if j == i:
				continue
			var pb: Vector3 = nodes[j]
			var d: float = (pb - pa).length()
			if d < best_d:
				best_d = d
				best = j
		if best >= 0:
			_push_edge(seen, edge_list, i, best)
	var tries: int = 0
	while edge_list.size() < strut_target and tries < 1200:
		tries += 1
		var ia: int = rng.randi_range(0, n_nodes - 1)
		var ib: int = rng.randi_range(0, n_nodes - 1)
		var ic: int = rng.randi_range(0, n_nodes - 1)
		if ia == ib or ib == ic or ia == ic:
			continue
		var qa: Vector3 = nodes[ia]
		var qb: Vector3 = nodes[ib]
		var qc: Vector3 = nodes[ic]
		var d0: float = (qb - qa).length()
		var d1: float = (qc - qb).length()
		var d2: float = (qa - qc).length()
		if d0 < 0.13 or d0 > 0.62 or d1 < 0.13 or d1 > 0.62 or d2 < 0.13 or d2 > 0.62:
			continue
		_push_edge(seen, edge_list, ia, ib)
		_push_edge(seen, edge_list, ib, ic)
		_push_edge(seen, edge_list, ic, ia)
	# deterministic fill so the thicket is never sparse, whatever the seed threw
	for i in range(n_nodes):
		if edge_list.size() >= 32:
			break
		var fa: Vector3 = nodes[i]
		for j in range(i + 1, n_nodes):
			if edge_list.size() >= 32:
				break
			var fb: Vector3 = nodes[j]
			var fd: float = (fb - fa).length()
			if fd >= 0.13 and fd <= 0.62:
				_push_edge(seen, edge_list, i, j)
	if edge_list.size() > 58:
		edge_list.resize(58)

	# --- draw the struts ----------------------------------------------------
	var degree: Array = []
	for i in range(n_nodes):
		degree.append(0)
	for k in range(edge_list.size()):
		var e: Vector2i = edge_list[k]
		var pa: Vector3 = nodes[e.x]
		var pb: Vector3 = nodes[e.y]
		degree[e.x] = int(degree[e.x]) + 1
		degree[e.y] = int(degree[e.y]) + 1
		var dir: Vector3 = (pb - pa).normalized()
		var ext_a: float = 0.0
		var ext_b: float = 0.0
		if rng.randf() < 0.62:
			ext_a = rng.randf_range(0.015, 0.13)
		if rng.randf() < 0.62:
			ext_b = rng.randf_range(0.015, 0.13)
		var r_tube: float = rng.randf_range(0.006, 0.010)
		_strut(root, pa - dir * ext_a, pb + dir * ext_b, r_tube, mat_tube)

	# --- welded joints ------------------------------------------------------
	var knobs: int = 0
	for i in range(n_nodes):
		if knobs >= 20:
			break
		if int(degree[i]) < 3:
			continue
		var p: Vector3 = nodes[i]
		var sph := SphereMesh.new()
		var kr: float = rng.randf_range(0.011, 0.017)
		sph.radius = kr
		sph.height = kr * 2.0
		sph.radial_segments = 12
		sph.rings = 6
		var mi: MeshInstance3D = _add(root, sph, mat_knob)
		mi.transform = Transform3D(Basis(), p)
		knobs += 1

	# --- plates -------------------------------------------------------------
	for i in range(n_plates):
		var pick: float = pow(rng.randf(), 1.45)
		var idx: int = mini(int(floor(pick * float(n_nodes))), n_nodes - 1)
		var pos: Vector3 = nodes[idx]
		var nrm := Vector3(1.0, 0.0, 0.0)
		var on_edge: bool = rng.randf() < 0.45 and edge_list.size() > 0
		if on_edge:
			var e: Vector2i = edge_list[rng.randi_range(0, edge_list.size() - 1)]
			var pa: Vector3 = nodes[e.x]
			var pb: Vector3 = nodes[e.y]
			var f: float = rng.randf_range(0.22, 0.78)
			pos = pa.lerp(pb, f)
			var dir: Vector3 = (pb - pa).normalized()
			var perp: Vector3 = dir.cross(Vector3.UP)
			if perp.length() < 0.02:
				perp = dir.cross(Vector3.RIGHT)
			perp = perp.normalized()
			var tilt: float = deg_to_rad(rng.randf_range(18.0, 52.0))
			nrm = (dir * cos(tilt) + perp * sin(tilt)).normalized()
			nrm = nrm.rotated(dir, rng.randf_range(0.0, TAU))
		else:
			pos = pos + Vector3(rng.randf_range(-0.05, 0.05), rng.randf_range(-0.07, 0.07), rng.randf_range(-0.05, 0.05))
			var ele: float = deg_to_rad(rng.randf_range(-38.0, 38.0))
			if rng.randf() < 0.16:
				var sgn: float = 1.0 if rng.randf() < 0.5 else -1.0
				ele = deg_to_rad(rng.randf_range(52.0, 86.0)) * sgn
			var az: float = rng.randf_range(0.0, TAU)
			nrm = Vector3(cos(ele) * cos(az), sin(ele), cos(ele) * sin(az)).normalized()

		var t_h: float = clampf(pos.y / maxf(height, 0.01), 0.0, 1.0)
		var r0: float = rng.randf_range(0.115, 0.325) * lerpf(1.04, 0.60, t_h)
		var thick: float = rng.randf_range(0.020, 0.038)
		var hole_r: float = 0.0
		if rng.randf() < 0.28:
			hole_r = r0 * rng.randf_range(0.07, 0.13)
		var mesh: ArrayMesh = _plate_mesh(rng, r0, thick, hole_r)

		var is_white: bool = rng.randf() < white_frac
		var base: Color = col_white if is_white else col_pink.lerp(col_pink2, rng.randf())
		var shade: float = rng.randf_range(-0.05, 0.06)
		var tinted: Color = base.lightened(maxf(shade, 0.0)) if shade >= 0.0 else base.darkened(-shade)
		var rough: float = rng.randf_range(0.46, 0.60)
		var mat: StandardMaterial3D = _enamel(tinted, tex_plate, rng.randf_range(1.1, 1.9), rough)
		var mi: MeshInstance3D = _add(root, mesh, mat)
		mi.transform = Transform3D(_basis_z_to(nrm, rng.randf_range(0.0, TAU)), pos)

	_settle(root)


# ---------------------------------------------------------------------------
# gesture helpers

static func _axis_pt(t: float, height: float, lean: Vector2) -> Vector3:
	var k: float = pow(clampf(t, 0.0, 1.0), 1.25)
	return Vector3(lean.x * k, height * t, lean.y * k)


static func _push_edge(seen: Dictionary, edge_list: Array, a: int, b: int) -> void:
	if a == b:
		return
	var lo: int = mini(a, b)
	var hi: int = maxi(a, b)
	var key: String = str(lo) + "_" + str(hi)
	if seen.has(key):
		return
	seen[key] = true
	edge_list.append(Vector2i(lo, hi))


# ---------------------------------------------------------------------------
# geometry

static func _plate_mesh(rng: RandomNumberGenerator, r0: float, thick: float, hole_r: float) -> ArrayMesh:
	var n_v: int = rng.randi_range(5, 9)
	var span: float = TAU / float(n_v)
	var angs: Array = []
	var rads: Array = []
	for i in range(n_v):
		angs.append(float(i) * span + rng.randf_range(-0.30, 0.30) * span)
		rads.append(r0 * rng.randf_range(0.62, 1.25))
	var n_notch: int = rng.randi_range(1, 2)
	for k in range(n_notch):
		var idx: int = rng.randi_range(0, n_v - 1)
		rads[idx] = float(rads[idx]) * rng.randf_range(0.30, 0.48)
	if rng.randf() < 0.34 and r0 < 0.22:
		var sp: int = rng.randi_range(0, n_v - 1)
		rads[sp] = float(rads[sp]) * rng.randf_range(1.7, 2.5)

	# sample the outline by exact ray/edge intersection so the sides stay straight
	var sub: int = 3
	var ring: Array = []
	for i in range(n_v):
		var i2: int = (i + 1) % n_v
		var a0: float = float(angs[i])
		var a1: float = float(angs[i2])
		if a1 <= a0:
			a1 += TAU
		var ra: float = float(rads[i])
		var rb: float = float(rads[i2])
		var pa := Vector2(cos(a0) * ra, sin(a0) * ra)
		var pb := Vector2(cos(a1) * rb, sin(a1) * rb)
		var seg: Vector2 = pb - pa
		for j in range(sub):
			var f: float = float(j) / float(sub)
			var th: float = lerpf(a0, a1, f)
			var d := Vector2(cos(th), sin(th))
			var den: float = d.x * seg.y - d.y * seg.x
			var rr: float = 0.0
			if absf(den) < 1.0e-7:
				rr = lerpf(ra, rb, f)
			else:
				rr = (pa.x * pb.y - pa.y * pb.x) / den
			rr = clampf(rr, r0 * 0.10, minf(r0 * 3.2, 0.34))
			ring.append(Vector2(d.x * rr, d.y * rr))

	var count: int = ring.size()
	var hz: float = thick * 0.5
	var use_hole: bool = hole_r > 0.0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var z_up := Vector3(0.0, 0.0, 1.0)
	var z_dn := Vector3(0.0, 0.0, -1.0)
	for k in range(count):
		var k2: int = (k + 1) % count
		var o0: Vector2 = ring[k]
		var o1: Vector2 = ring[k2]
		var of0 := Vector3(o0.x, o0.y, hz)
		var of1 := Vector3(o1.x, o1.y, hz)
		var ob0 := Vector3(o0.x, o0.y, -hz)
		var ob1 := Vector3(o1.x, o1.y, -hz)
		if use_hole:
			var d0: Vector2 = o0.normalized()
			var d1: Vector2 = o1.normalized()
			var if0 := Vector3(d0.x * hole_r, d0.y * hole_r, hz)
			var if1 := Vector3(d1.x * hole_r, d1.y * hole_r, hz)
			var ib0 := Vector3(d0.x * hole_r, d0.y * hole_r, -hz)
			var ib1 := Vector3(d1.x * hole_r, d1.y * hole_r, -hz)
			_quad_dir(st, if0, if1, of1, of0, z_up)
			_quad_dir(st, ib0, ib1, ob1, ob0, z_dn)
			var inward := Vector3(-(d0.x + d1.x), -(d0.y + d1.y), 0.0).normalized()
			_quad_dir(st, if0, if1, ib1, ib0, inward)
		else:
			_tri_dir(st, Vector3(0.0, 0.0, hz), of0, of1, z_up)
			_tri_dir(st, Vector3(0.0, 0.0, -hz), ob0, ob1, z_dn)
		var outward := Vector3(o0.x + o1.x, o0.y + o1.y, 0.0).normalized()
		_quad_dir(st, of0, of1, ob1, ob0, outward)
	st.generate_normals()
	return st.commit()


static func _tri_dir(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, outward: Vector3) -> void:
	var nf: Vector3 = (c - a).cross(b - a)
	if nf.dot(outward) >= 0.0:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)
	else:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)


static func _quad_dir(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, outward: Vector3) -> void:
	var nf: Vector3 = (c - a).cross(b - a)
	if nf.dot(outward) >= 0.0:
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


static func _strut(root: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.01)
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = r
	cyl.top_radius = r
	cyl.height = ln
	cyl.radial_segments = 10
	cyl.rings = 1
	var mi: MeshInstance3D = _add(root, cyl, mat)
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


static func _basis_z_to(nrm: Vector3, roll: float) -> Basis:
	var z: Vector3 = nrm.normalized()
	var ref: Vector3 = Vector3.UP
	if absf(z.dot(ref)) > 0.95:
		ref = Vector3.RIGHT
	var x: Vector3 = ref.cross(z).normalized()
	var y: Vector3 = z.cross(x).normalized()
	return Basis(x, y, z) * Basis(Vector3(0.0, 0.0, 1.0), roll)


static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


# ---------------------------------------------------------------------------
# surface

static func _enamel(c: Color, tex: ImageTexture, uv: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(uv, uv, uv)
	m.roughness = rough
	m.metallic = 0.0
	m.specular = 0.35
	return m


static func _enamel_texture(rng: RandomNumberGenerator, grain: float, streaks: int, scuffs: int) -> ImageTexture:
	var img: Image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	for y in range(TEX_SIZE):
		for x in range(TEX_SIZE):
			var v: float = clampf(0.965 + rng.randf_range(-grain, grain), 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v, v))
	for s in range(streaks):
		var yy: int = rng.randi_range(0, TEX_SIZE - 1)
		var amp: float = rng.randf_range(-0.055, 0.040)
		var x0: int = rng.randi_range(0, TEX_SIZE - 1)
		var ln: int = rng.randi_range(24, TEX_SIZE)
		for k in range(ln):
			var xx: int = posmod(x0 + k, TEX_SIZE)
			var fade: float = sin(PI * float(k) / float(ln))
			var c: Color = img.get_pixel(xx, yy)
			var v: float = clampf(c.r + amp * fade, 0.0, 1.0)
			img.set_pixel(xx, yy, Color(v, v, v))
	for s in range(scuffs):
		var cx: int = rng.randi_range(0, TEX_SIZE - 1)
		var cy: int = rng.randi_range(0, TEX_SIZE - 1)
		var rr: int = rng.randi_range(1, 3)
		var dark: float = rng.randf_range(0.06, 0.15)
		for dy in range(-rr, rr + 1):
			for dx in range(-rr, rr + 1):
				var dd: float = sqrt(float(dx * dx + dy * dy))
				if dd > float(rr):
					continue
				var xx: int = posmod(cx + dx, TEX_SIZE)
				var yy: int = posmod(cy + dy, TEX_SIZE)
				var fall: float = 1.0 - dd / float(rr + 1)
				var c: Color = img.get_pixel(xx, yy)
				var v: float = clampf(c.r - dark * fall, 0.0, 1.0)
				img.set_pixel(xx, yy, Color(v, v, v))
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------------------
# measured settle: fit the box, centre on x/z, stand on y = 0

static func _settle(root: Node3D) -> void:
	var box: AABB = _union_aabb(root)
	if box.size.x <= 0.0 and box.size.y <= 0.0 and box.size.z <= 0.0:
		return
	var kx: float = 1.20 / maxf(box.size.x, 0.0001)
	var kz: float = 1.20 / maxf(box.size.z, 0.0001)
	var ky: float = 1.68 / maxf(box.size.y, 0.0001)
	var kfit: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kfit < 1.0:
		_scale_children(root, kfit)
		box = _union_aabb(root)
	if box.size.y < 1.30:
		var ux: float = 1.20 / maxf(box.size.x, 0.0001)
		var uz: float = 1.20 / maxf(box.size.z, 0.0001)
		var uy: float = 1.62 / maxf(box.size.y, 0.0001)
		var kup: float = minf(uy, minf(ux, uz))
		if kup > 1.0:
			_scale_children(root, kup)
			box = _union_aabb(root)
	var centre: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-centre.x, -box.position.y, -centre.z)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + shift)


static func _scale_children(root: Node3D, k: float) -> void:
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		var tf: Transform3D = cm.transform
		cm.transform = Transform3D(tf.basis.scaled(Vector3(k, k, k)), tf.origin * k)


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
