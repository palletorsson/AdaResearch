extends RefCounted
class_name MeshFactory

## MeshFactory — static fabrication helpers that produce REAL ArrayMesh
## geometry from simple specs. The project's "mesh factory": instead of
## assembling a prop from stacked primitive BoxMesh/CylinderMesh nodes,
## a profile is swept into a single solid mesh with proper sloped faces.
##
## extrude_profile() sweeps a 2D cross-section (in the Z-Y plane) along the
## X axis into a closed solid: flat-shaded side faces + two end caps.
## Normals are forced OUTWARD (away from the cross-section centroid) so the
## result lights correctly regardless of winding order; pair it with a
## double-sided material if you want it watertight from both sides.

# outline : points (z, y) tracing the cross-section perimeter in order.
# length  : extent along X, centred on the origin.
# uv_tile : world length one texture tile spans along X (for striping).
static func extrude_profile(outline: PackedVector2Array, length: float, uv_tile: float = 1.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = outline.size()
	if n < 3 or length <= 0.0:
		return st.commit()
	var hx: float = length * 0.5

	# Cross-section centroid (used to force outward normals).
	var cz: float = 0.0
	var cy: float = 0.0
	for p in outline:
		cz += p.x
		cy += p.y
	var cen := Vector2(cz / float(n), cy / float(n))

	# Perimeter cumulative length for the side-face V coordinate.
	var cum := PackedFloat32Array()
	cum.resize(n)
	var perim: float = 0.0
	for i in range(n):
		cum[i] = perim
		perim += outline[i].distance_to(outline[(i + 1) % n])
	if perim <= 0.0:
		perim = 1.0

	var u_span: float = length / maxf(0.001, uv_tile)

	# ── Side faces: one quad per perimeter edge, spanning -hx..+hx in X.
	for i in range(n):
		var a := outline[i]
		var b := outline[(i + 1) % n]
		var va: float = cum[i] / perim
		var vb: float = (cum[i] + a.distance_to(b)) / perim
		# Outward normal: perpendicular to the edge, flipped to point away
		# from the centroid (robust for any winding on a convex profile).
		var edge := b - a
		var perp := Vector2(edge.y, -edge.x)
		if perp.length() < 0.0001:
			continue
		perp = perp.normalized()
		var mid := (a + b) * 0.5
		if perp.dot(mid - cen) < 0.0:
			perp = -perp
		var nrm := Vector3(0.0, perp.y, perp.x)
		var a_back := Vector3(-hx, a.y, a.x)
		var a_front := Vector3(hx, a.y, a.x)
		var b_back := Vector3(-hx, b.y, b.x)
		var b_front := Vector3(hx, b.y, b.x)
		_tri(st, nrm, a_back, Vector2(0.0, va), a_front, Vector2(u_span, va), b_front, Vector2(u_span, vb))
		_tri(st, nrm, a_back, Vector2(0.0, va), b_front, Vector2(u_span, vb), b_back, Vector2(0.0, vb))

	# ── End caps: triangle fan from the centroid at each X extreme.
	var cen3_f := Vector3(hx, cen.y, cen.x)
	var cen3_b := Vector3(-hx, cen.y, cen.x)
	for i in range(n):
		var a := outline[i]
		var b := outline[(i + 1) % n]
		# Front cap (+X outward normal).
		_tri(st, Vector3(1.0, 0.0, 0.0),
			cen3_f, Vector2(0.5, 0.5),
			Vector3(hx, b.y, b.x), Vector2(0.5 + b.x, 0.5 + b.y),
			Vector3(hx, a.y, a.x), Vector2(0.5 + a.x, 0.5 + a.y))
		# Back cap (-X outward normal).
		_tri(st, Vector3(-1.0, 0.0, 0.0),
			cen3_b, Vector2(0.5, 0.5),
			Vector3(-hx, a.y, a.x), Vector2(0.5 + a.x, 0.5 + a.y),
			Vector3(-hx, b.y, b.x), Vector2(0.5 + b.x, 0.5 + b.y))

	return st.commit()


# A symmetric Jersey / K-rail barrier cross-section in the Z-Y plane:
# wide foot, vertical toe, steep lower slope, gentler upper slope, narrow
# crown. Returns the perimeter outline (bottom-right -> up -> across the
# top -> down the left -> across the base).
static func jersey_outline(base_width: float, top_width: float, height: float) -> PackedVector2Array:
	var bh: float = base_width * 0.5
	var th: float = top_width * 0.5
	var mh: float = lerpf(bh, th, 0.45)      # shoulder half-width
	return PackedVector2Array([
		Vector2(bh, 0.0),
		Vector2(bh, height * 0.07),
		Vector2(mh, height * 0.32),
		Vector2(th, height * 0.62),
		Vector2(th, height),
		Vector2(-th, height),
		Vector2(-th, height * 0.62),
		Vector2(-mh, height * 0.32),
		Vector2(-bh, height * 0.07),
		Vector2(-bh, 0.0),
	])


# Like extrude_profile, but the cross-section is in the X-Y plane and is
# swept along Z (depth). The big faces (the profile itself) face +Z (front)
# and -Z (back); the swept perimeter forms the thin edges. Good for flat
# slabs whose silhouette IS the front view — e.g. a chamfered utility block.
static func extrude_profile_z(outline: PackedVector2Array, depth: float, uv_tile: float = 1.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = outline.size()
	if n < 3 or depth <= 0.0:
		return st.commit()
	var hz: float = depth * 0.5
	var cx: float = 0.0
	var cy: float = 0.0
	for p in outline:
		cx += p.x
		cy += p.y
	var cen := Vector2(cx / float(n), cy / float(n))
	var cum := PackedFloat32Array()
	cum.resize(n)
	var perim: float = 0.0
	for i in range(n):
		cum[i] = perim
		perim += outline[i].distance_to(outline[(i + 1) % n])
	if perim <= 0.0:
		perim = 1.0
	var u_span: float = depth / maxf(0.001, uv_tile)
	# Swept edge faces.
	for i in range(n):
		var a := outline[i]
		var b := outline[(i + 1) % n]
		var va: float = cum[i] / perim
		var vb: float = (cum[i] + a.distance_to(b)) / perim
		var edge := b - a
		var perp := Vector2(edge.y, -edge.x)
		if perp.length() < 0.0001:
			continue
		perp = perp.normalized()
		var mid := (a + b) * 0.5
		if perp.dot(mid - cen) < 0.0:
			perp = -perp
		var nrm := Vector3(perp.x, perp.y, 0.0)
		_tri(st, nrm, Vector3(a.x, a.y, -hz), Vector2(0.0, va), Vector3(a.x, a.y, hz), Vector2(u_span, va), Vector3(b.x, b.y, hz), Vector2(u_span, vb))
		_tri(st, nrm, Vector3(a.x, a.y, -hz), Vector2(0.0, va), Vector3(b.x, b.y, hz), Vector2(u_span, vb), Vector3(b.x, b.y, -hz), Vector2(0.0, vb))
	# Caps: the profile at +Z (front) and -Z (back), with normalized UVs so a
	# front decal/texture maps cleanly across the silhouette.
	var minx := outline[0].x
	var maxx := outline[0].x
	var miny := outline[0].y
	var maxy := outline[0].y
	for p in outline:
		minx = minf(minx, p.x)
		maxx = maxf(maxx, p.x)
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	var sx: float = maxf(0.001, maxx - minx)
	var sy: float = maxf(0.001, maxy - miny)
	for i in range(n):
		var a := outline[i]
		var b := outline[(i + 1) % n]
		var ua := Vector2((a.x - minx) / sx, 1.0 - (a.y - miny) / sy)
		var ub := Vector2((b.x - minx) / sx, 1.0 - (b.y - miny) / sy)
		var uc := Vector2((cen.x - minx) / sx, 1.0 - (cen.y - miny) / sy)
		_tri(st, Vector3(0, 0, 1), Vector3(cen.x, cen.y, hz), uc, Vector3(a.x, a.y, hz), ua, Vector3(b.x, b.y, hz), ub)
		_tri(st, Vector3(0, 0, -1), Vector3(cen.x, cen.y, -hz), uc, Vector3(b.x, b.y, -hz), ub, Vector3(a.x, a.y, -hz), ua)
	return st.commit()


# A rectangle in X-Y (origin at bottom-centre) with the top-right corner
# sliced at 45° by `chamfer`. The futuristic-fuse-box silhouette.
static func chamfer_rect_outline(width: float, height: float, chamfer: float) -> PackedVector2Array:
	var hw: float = width * 0.5
	var ch: float = clampf(chamfer, 0.0, minf(width, height) * 0.8)
	return PackedVector2Array([
		Vector2(-hw, 0.0),
		Vector2(hw, 0.0),
		Vector2(hw, height - ch),
		Vector2(hw - ch, height),
		Vector2(-hw, height),
	])


# A rectangle (origin bottom-centre) with ALL FOUR corners cut at 45° by
# `bevel` — the sci-fi cargo-crate front silhouette. Sweep it with
# extrude_profile_z for a body with cleanly bevelled top/bottom/side edges.
static func bevel_rect_outline(width: float, height: float, bevel: float) -> PackedVector2Array:
	var hw: float = width * 0.5
	var bv: float = clampf(bevel, 0.0, minf(width, height) * 0.45)
	return PackedVector2Array([
		Vector2(-hw + bv, 0.0),
		Vector2(hw - bv, 0.0),
		Vector2(hw, bv),
		Vector2(hw, height - bv),
		Vector2(hw - bv, height),
		Vector2(-hw + bv, height),
		Vector2(-hw, height - bv),
		Vector2(-hw, bv),
	])


static func _tri(st: SurfaceTool, nrm: Vector3,
		p0: Vector3, uv0: Vector2, p1: Vector3, uv1: Vector2, p2: Vector3, uv2: Vector2) -> void:
	st.set_normal(nrm); st.set_uv(uv0); st.add_vertex(p0)
	st.set_normal(nrm); st.set_uv(uv1); st.add_vertex(p1)
	st.set_normal(nrm); st.set_uv(uv2); st.add_vertex(p2)
