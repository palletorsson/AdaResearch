@tool
extends RefCounted
class_name MeshKit

## MeshKit — procedural geometry that survives close inspection.
##
## The corpus builds its props from BoxMesh / CylinderMesh / SphereMesh at default
## segment counts. That costs rubric item 3: hard edges that catch no highlight,
## faceted barrels, and normal maps that silently do nothing because the mesh has
## no tangents. This kit is the replacement set. Everything is static, procedural
## and allocation-only — no _process, no shaders, no external files.
##
## CALLING IT
##   const MK := preload("res://commons/render/mesh_kit.gd")
##   var m: ArrayMesh = MK.bevel_box(Vector3(0.4, 0.1, 0.3), 0.008)
## or via the global class name:
##   var m: ArrayMesh = MeshKit.bevel_box(Vector3(0.4, 0.1, 0.3), 0.008)
## Both work. `preload` is the safer habit in this repo.
##
## WHAT YOU GET ON EVERY MESH THIS FILE RETURNS
##   * correct winding (Godot front faces are CLOCKWISE seen from outside — that is,
##     cross(b - a, c - a) points AGAINST the surface normal). Verified against
##     commons/artifacts/gradient_descent_well/gradient_descent_well.gd:345.
##   * authored normals — flat where the surface is flat, smooth where it curves,
##     tangent-continuous across the fillet/face seam so there is no shading crease.
##   * UVs in WORLD UNITS times `uv_scale`, so a detail_normal tiles at the same
##     texel density on a 0.1 m knob and a 3 m wall. uv_scale = 1.0 means one UV
##     unit per metre.
##   * TANGENTS. Always. A normal-mapped mesh with no tangents is a silent no-op.
##   * an index buffer (SurfaceTool.index) so the vertex count stays honest.
##
## VR BUDGET (R2). Defaults are the cheap setting. Measured triangle counts:
##   bevel_box  segments=1 ->  44 tris   segments=2 -> 108   segments=3 -> 204
##   cylinder   radial=24, cap_bevel=0 ->  96 tris   with cap_bevel -> 192
##   capsule    radial=24, rings=6 -> 576 tris
##   rounded_panel corner_segments=3, bevel=0 -> 64 tris
## Raise radial_segments to 32-48 only for objects over ~1 m across.
##
## GEOMETRY CONVENTIONS
##   * every mesh is centred on its own origin. Sit it on a floor with
##     position.y = size.y * 0.5, not by eyeballing.
##   * lathed shapes spin around +Y. Panels face +Z.
##   * a returned ArrayMesh has ONE surface and NO material. Assign with
##     `mesh.surface_set_material(0, mat)` — that leaves both `material_override`
##     and `set_surface_override_material()` free for highlight/pickup systems.

const EPS: float = 1.0e-6

## Below this a bevel is not worth building: its corner triangles would be small
## enough to trip the degeneracy guard in _tri and leave pinholes. 0.01 mm.
const MIN_BEVEL: float = 1.0e-5

# ---------------------------------------------------------------------------
# Low-level emit. Winding is decided here, once, so no builder can get it wrong.
# ---------------------------------------------------------------------------

## Emit one triangle. Vertex order is auto-corrected against the supplied normals,
## so callers may pass a, b, c in whichever order reads clearest.
static func _tri(st: SurfaceTool,
		pa: Vector3, pb: Vector3, pc: Vector3,
		na: Vector3, nb: Vector3, nc: Vector3,
		ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	var geo: Vector3 = (pb - pa).cross(pc - pa)
	# Degenerate: pole rows on a sphere patch, zero-width strips at a collapsed
	# radius, faces that vanished when a bevel ate the whole half-extent.
	if geo.length_squared() < 1.0e-18:
		return
	var ref: Vector3 = na + nb + nc
	if ref.length_squared() < EPS:
		ref = na
	# Godot front faces are clockwise seen from outside: the geometric cross
	# product must OPPOSE the surface normal. If it agrees, swap b and c.
	if geo.dot(ref) > 0.0:
		st.set_normal(na)
		st.set_uv(ua)
		st.add_vertex(pa)
		st.set_normal(nc)
		st.set_uv(uc)
		st.add_vertex(pc)
		st.set_normal(nb)
		st.set_uv(ub)
		st.add_vertex(pb)
	else:
		st.set_normal(na)
		st.set_uv(ua)
		st.add_vertex(pa)
		st.set_normal(nb)
		st.set_uv(ub)
		st.add_vertex(pb)
		st.set_normal(nc)
		st.set_uv(uc)
		st.add_vertex(pc)


## Emit a quad as two triangles. p0..p3 walk around the quad in either direction.
static func _quad(st: SurfaceTool,
		p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
		n0: Vector3, n1: Vector3, n2: Vector3, n3: Vector3,
		u0: Vector2, u1: Vector2, u2: Vector2, u3: Vector2) -> void:
	_tri(st, p0, p1, p2, n0, n1, n2, u0, u1, u2)
	_tri(st, p0, p2, p3, n0, n2, n3, u0, u2, u3)


## Normalize, or fall back if the vector is degenerate. Vector3.normalized()
## returns ZERO on a zero vector, which would silently produce black shading.
static func _norm3(v: Vector3, fallback: Vector3) -> Vector3:
	if v.length_squared() < EPS:
		return fallback
	return v.normalized()


static func _norm2(v: Vector2, fallback: Vector2) -> Vector2:
	if v.length_squared() < EPS:
		return fallback
	return v.normalized()


static func _mul3(a: Vector3, b: Vector3) -> Vector3:
	return Vector3(a.x * b.x, a.y * b.y, a.z * b.z)


## Generate tangents, weld, commit. Every builder ends here.
static func _finish(st: SurfaceTool) -> ArrayMesh:
	st.generate_tangents()
	st.index()
	return st.commit() as ArrayMesh


# ===========================================================================
# BEVELLED BOX
# ===========================================================================

## A box with a chamfer of `bevel` metres on all twelve edges and eight corners.
##
## The six flat faces keep their own hard normal — they stay FLAT. The chamfer is
## the Minkowski sum of the inset box with a sphere of radius `bevel`, so at
## `smooth_bevel = true` its normals are exactly tangent to the flat faces at the
## seam: the highlight rolls around the edge with no shading crease. At
## `smooth_bevel = false` the chamfer is a flat facet and reads as a crisp
## machined edge with a hard specular line. Both are correct hard-surface looks;
## smooth is the better default for a 1-10 mm bevel.
##
## `bevel` is clamped to the smallest half-extent, so an over-large value rounds
## the box off rather than turning it inside out.
##
## size:         full extents in metres. Mesh is centred on the origin.
## bevel:        chamfer radius in metres. 0.005-0.015 is the useful band.
## segments:     chamfer subdivisions. 1 = 44 tris total, 2 = 108, 3 = 204.
## smooth_bevel: true = rounded chamfer shading, false = flat machined facet.
## uv_scale:     UV units per metre.
static func bevel_box(size: Vector3, bevel: float = 0.01, segments: int = 1,
		smooth_bevel: bool = true, uv_scale: float = 1.0) -> ArrayMesh:
	var half := Vector3(
		maxf(absf(size.x) * 0.5, EPS),
		maxf(absf(size.y) * 0.5, EPS),
		maxf(absf(size.z) * 0.5, EPS))
	var lim: float = minf(minf(half.x, half.y), half.z)
	var b: float = clampf(bevel, 0.0, lim)
	if b < MIN_BEVEL:
		# Snap to a clean, watertight plain box rather than a hairline chamfer.
		b = 0.0
	var seg: int = maxi(1, segments)
	var inner: Vector3 = half - Vector3(b, b, b)
	inner = Vector3(maxf(inner.x, 0.0), maxf(inner.y, 0.0), maxf(inner.z, 0.0))

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# --- the six flat faces, inset by the bevel -----------------------------
	# Each row is [face normal, u axis, v axis]. v points "down" in image space.
	var faces: Array = [
		[Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(0, -1, 0)],
		[Vector3(-1, 0, 0), Vector3(0, 0, -1), Vector3(0, -1, 0)],
		[Vector3(0, 1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)],
		[Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, -1)],
		[Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(0, -1, 0)],
		[Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, -1, 0)],
	]
	for fi in range(faces.size()):
		var row: Array = faces[fi]
		var n: Vector3 = row[0]
		var ua: Vector3 = row[1]
		var va: Vector3 = row[2]
		var centre: Vector3 = _mul3(n, half)
		var eu: float = absf(ua.x) * inner.x + absf(ua.y) * inner.y + absf(ua.z) * inner.z
		var ev: float = absf(va.x) * inner.x + absf(va.y) * inner.y + absf(va.z) * inner.z
		var c00: Vector3 = centre - ua * eu - va * ev
		var c10: Vector3 = centre + ua * eu - va * ev
		var c11: Vector3 = centre + ua * eu + va * ev
		var c01: Vector3 = centre - ua * eu + va * ev
		_quad(st, c00, c10, c11, c01, n, n, n, n,
			Vector2(-eu, -ev) * uv_scale, Vector2(eu, -ev) * uv_scale,
			Vector2(eu, ev) * uv_scale, Vector2(-eu, ev) * uv_scale)

	if b > 0.0:
		# --- twelve edge fillets --------------------------------------------
		# Each quadrant of each axis. d0 -> d1 is a 90 degree sweep; `run` is the
		# axis the edge travels along.
		var ax := Vector3(1, 0, 0)
		var ay := Vector3(0, 1, 0)
		var az := Vector3(0, 0, 1)
		var edges: Array = [
			# vertical edges, arc in XZ
			[ax, az, ay], [az, -ax, ay], [-ax, -az, ay], [-az, ax, ay],
			# edges along X, arc in YZ
			[ay, az, ax], [az, -ay, ax], [-ay, -az, ax], [-az, ay, ax],
			# edges along Z, arc in XY
			[ax, ay, az], [ay, -ax, az], [-ax, -ay, az], [-ay, ax, az],
		]
		for ei in range(edges.size()):
			var erow: Array = edges[ei]
			var e0: Vector3 = erow[0]
			var e1: Vector3 = erow[1]
			var erun: Vector3 = erow[2]
			_emit_box_edge(st, e0, e1, erun, inner, b, seg, smooth_bevel, uv_scale)

		# --- eight corner patches -------------------------------------------
		for sx: float in [-1.0, 1.0]:
			for sy: float in [-1.0, 1.0]:
				for sz: float in [-1.0, 1.0]:
					_emit_box_corner(st, sx, sy, sz, inner, b, seg,
						smooth_bevel, uv_scale)

	return _finish(st)


## One edge fillet: a 90 degree strip sweeping from face direction d0 to d1,
## extruded along `run`. The arc angles match the corner patches exactly, so the
## seams are watertight and the normals agree across them.
static func _emit_box_edge(st: SurfaceTool, d0: Vector3, d1: Vector3, run: Vector3,
		inner: Vector3, b: float, seg: int, smooth: bool, uv_scale: float) -> void:
	var base: Vector3 = _mul3(d0, inner) + _mul3(d1, inner)
	var er: float = absf(run.x) * inner.x + absf(run.y) * inner.y + absf(run.z) * inner.z
	for k in range(seg):
		var t0: float = (float(k) / float(seg)) * (PI * 0.5)
		var t1: float = (float(k + 1) / float(seg)) * (PI * 0.5)
		var n0: Vector3 = d0 * cos(t0) + d1 * sin(t0)
		var n1: Vector3 = d0 * cos(t1) + d1 * sin(t1)
		var q0: Vector3 = n0
		var q1: Vector3 = n1
		if not smooth:
			var flat: Vector3 = _norm3(n0 + n1, n0)
			q0 = flat
			q1 = flat
		var p00: Vector3 = base - run * er + n0 * b
		var p10: Vector3 = base - run * er + n1 * b
		var p11: Vector3 = base + run * er + n1 * b
		var p01: Vector3 = base + run * er + n0 * b
		var u0: float = b * t0 * uv_scale
		var u1: float = b * t1 * uv_scale
		var v0: float = -er * uv_scale
		var v1: float = er * uv_scale
		_quad(st, p00, p10, p11, p01, q0, q1, q1, q0,
			Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1))


## One corner: a spherical octant. Parameterised so that its three boundary arcs
## reproduce the three adjacent edge fillets angle for angle. The phi = 90 row
## collapses to the pole and _tri drops the degenerate half of those quads.
static func _emit_box_corner(st: SurfaceTool, sx: float, sy: float, sz: float,
		inner: Vector3, b: float, seg: int, smooth: bool, uv_scale: float) -> void:
	var centre := Vector3(sx * inner.x, sy * inner.y, sz * inner.z)
	for i in range(seg):
		var phi0: float = (float(i) / float(seg)) * (PI * 0.5)
		var phi1: float = (float(i + 1) / float(seg)) * (PI * 0.5)
		for j in range(seg):
			var th0: float = (float(j) / float(seg)) * (PI * 0.5)
			var th1: float = (float(j + 1) / float(seg)) * (PI * 0.5)
			var d00: Vector3 = _octant_dir(sx, sy, sz, phi0, th0)
			var d01: Vector3 = _octant_dir(sx, sy, sz, phi0, th1)
			var d11: Vector3 = _octant_dir(sx, sy, sz, phi1, th1)
			var d10: Vector3 = _octant_dir(sx, sy, sz, phi1, th0)
			var q00: Vector3 = d00
			var q01: Vector3 = d01
			var q11: Vector3 = d11
			var q10: Vector3 = d10
			if not smooth:
				var flat: Vector3 = _norm3(d00 + d01 + d11 + d10, d00)
				q00 = flat
				q01 = flat
				q11 = flat
				q10 = flat
			_quad(st,
				centre + d00 * b, centre + d01 * b, centre + d11 * b, centre + d10 * b,
				q00, q01, q11, q10,
				Vector2(b * th0, b * phi0) * uv_scale,
				Vector2(b * th1, b * phi0) * uv_scale,
				Vector2(b * th1, b * phi1) * uv_scale,
				Vector2(b * th0, b * phi1) * uv_scale)


static func _octant_dir(sx: float, sy: float, sz: float, phi: float, th: float) -> Vector3:
	var cp: float = cos(phi)
	return Vector3(sx * cp * cos(th), sy * sin(phi), sz * cp * sin(th))


# ===========================================================================
# LATHE — the engine behind cylinder, cone, capsule and tube
# ===========================================================================

## Revolve a 2D profile around +Y.
##
## `profile` is an Array of Vector4(radius, y, normal_r, normal_y) walked in order.
## Consecutive entries make one quad strip. To put a HARD crease in the surface,
## append the same (radius, y) twice with two different normals — the zero-area
## strip between them is dropped automatically. To keep it smooth, just let the
## normal rotate. A radius of 0 collapses the strip to a triangle fan, which is
## how flat caps and poles are made.
##
## Normals need not be unit length; they are normalised per vertex after the
## radial sweep.
static func lathe(profile: Array, radial_segments: int = 24,
		uv_scale: float = 1.0) -> ArrayMesh:
	var rs: int = maxi(3, radial_segments)
	var n: int = profile.size()
	if n < 2:
		push_warning("MeshKit.lathe: profile needs at least 2 points, got %d" % n)
		return ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# u is arc length at the widest radius, v is arc length along the profile.
	# Both in metres, so texel density stays even across the whole shape.
	var r_ref: float = 0.0
	for i in range(n):
		var pv: Vector4 = profile[i]
		r_ref = maxf(r_ref, pv.x)
	if r_ref < EPS:
		r_ref = 1.0
	var vs := PackedFloat32Array()
	vs.resize(n)
	vs[0] = 0.0
	for i in range(1, n):
		var pp: Vector4 = profile[i - 1]
		var pc: Vector4 = profile[i]
		vs[i] = vs[i - 1] + Vector2(pc.x - pp.x, pc.y - pp.y).length()

	for i in range(n - 1):
		var pa: Vector4 = profile[i]
		var pb: Vector4 = profile[i + 1]
		var va: float = vs[i] * uv_scale
		var vb: float = vs[i + 1] * uv_scale
		for j in range(rs):
			var t0: float = TAU * float(j) / float(rs)
			var t1: float = TAU * float(j + 1) / float(rs)
			var c0: float = cos(t0)
			var s0: float = sin(t0)
			var c1: float = cos(t1)
			var s1: float = sin(t1)
			var p00 := Vector3(pa.x * c0, pa.y, pa.x * s0)
			var p01 := Vector3(pa.x * c1, pa.y, pa.x * s1)
			var p11 := Vector3(pb.x * c1, pb.y, pb.x * s1)
			var p10 := Vector3(pb.x * c0, pb.y, pb.x * s0)
			var n00: Vector3 = _norm3(Vector3(pa.z * c0, pa.w, pa.z * s0), Vector3.UP)
			var n01: Vector3 = _norm3(Vector3(pa.z * c1, pa.w, pa.z * s1), Vector3.UP)
			var n11: Vector3 = _norm3(Vector3(pb.z * c1, pb.w, pb.z * s1), Vector3.UP)
			var n10: Vector3 = _norm3(Vector3(pb.z * c0, pb.w, pb.z * s0), Vector3.UP)
			var u0: float = t0 * r_ref * uv_scale
			var u1: float = t1 * r_ref * uv_scale
			_quad(st, p00, p01, p11, p10, n00, n01, n11, n10,
				Vector2(u0, va), Vector2(u1, va), Vector2(u1, vb), Vector2(u0, vb))

	return _finish(st)


## Centre of a circle of radius r tangent to two planes meeting at `corner`,
## whose outward normals are n0 and n1. The exact fillet, not an approximation.
static func _fillet_centre(corner: Vector2, n0: Vector2, n1: Vector2, r: float) -> Vector2:
	var denom: float = 1.0 + n0.dot(n1)
	if absf(denom) < EPS:
		return corner
	return corner - (n0 + n1) * (r / denom)


## Append a corner to a lathe profile: a tangent arc of radius r if r > 0,
## otherwise the same point twice with both normals, which is a hard crease.
static func _append_fillet(profile: Array, corner: Vector2, n0: Vector2, n1: Vector2,
		r: float, segments: int) -> void:
	if r < MIN_BEVEL:
		profile.append(Vector4(corner.x, corner.y, n0.x, n0.y))
		profile.append(Vector4(corner.x, corner.y, n1.x, n1.y))
		return
	var seg: int = maxi(1, segments)
	var c: Vector2 = _fillet_centre(corner, n0, n1, r)
	var a0: float = atan2(n0.y, n0.x)
	var a1: float = atan2(n1.y, n1.x)
	# Always take the short way round, so the arc never wraps the wrong side.
	var d: float = a1 - a0
	while d > PI:
		d -= TAU
	while d < -PI:
		d += TAU
	for k in range(seg + 1):
		var a: float = a0 + d * (float(k) / float(seg))
		var nk := Vector2(cos(a), sin(a))
		var p: Vector2 = c + nk * r
		profile.append(Vector4(p.x, p.y, nk.x, nk.y))


# ===========================================================================
# CYLINDER / CONE
# ===========================================================================

## A truncated cone (or a cylinder when both radii match), smooth around the
## barrel and flat across the caps, with an optional tangent fillet where the two
## meet. That fillet is what stops a "cylinder" reading as a stamped tin can: it
## catches a bright rim highlight the same way a real turned part does.
##
## Side normals are tilted by the true slope, so a cone shades correctly rather
## than like a cylinder that happens to be narrower at the top.
##
## radius_bottom / radius_top: metres. Either may be 0 for a cone point.
## height:          full height. Centred on the origin, spins around +Y.
## radial_segments: 24 is the cheap default. Use 32-48 above ~1 m diameter.
## cap_bevel:       fillet radius where the barrel meets a cap. 0 = hard edge.
##                  Clamped to half the height and half the relevant radius.
## bevel_segments:  subdivisions in that fillet. 1 is enough under ~10 mm.
## caps:            false leaves both ends open (for stacking segments).
static func cone(radius_bottom: float, radius_top: float, height: float,
		radial_segments: int = 24, cap_bevel: float = 0.0,
		bevel_segments: int = 1, caps: bool = true,
		uv_scale: float = 1.0) -> ArrayMesh:
	var hh: float = maxf(absf(height), EPS) * 0.5
	var rb: float = maxf(radius_bottom, 0.0)
	var rt: float = maxf(radius_top, 0.0)
	var bseg: int = maxi(1, bevel_segments)
	var bb: float = clampf(cap_bevel, 0.0, minf(hh * 0.5, rb * 0.5))
	var bt: float = clampf(cap_bevel, 0.0, minf(hh * 0.5, rt * 0.5))
	# Outward side normal in the (radius, y) profile plane, tilted by the slope.
	var ns: Vector2 = _norm2(Vector2(hh * 2.0, rb - rt), Vector2(1.0, 0.0))

	var prof: Array = []
	if caps and rb > EPS:
		prof.append(Vector4(0.0, -hh, 0.0, -1.0))
	_append_fillet(prof, Vector2(rb, -hh), Vector2(0.0, -1.0), ns, bb, bseg)
	_append_fillet(prof, Vector2(rt, hh), ns, Vector2(0.0, 1.0), bt, bseg)
	if caps and rt > EPS:
		prof.append(Vector4(0.0, hh, 0.0, 1.0))
	return lathe(prof, radial_segments, uv_scale)


## A cylinder. Same as cone() with one radius. See cone() for the arguments.
static func cylinder(radius: float, height: float, radial_segments: int = 24,
		cap_bevel: float = 0.0, bevel_segments: int = 1, caps: bool = true,
		uv_scale: float = 1.0) -> ArrayMesh:
	return cone(radius, radius, height, radial_segments, cap_bevel,
		bevel_segments, caps, uv_scale)


# ===========================================================================
# CAPSULE
# ===========================================================================

## A capsule: two hemispheres and a barrel, smooth all the way through with no
## seam at the equator (the hemisphere normal is horizontal exactly where it
## meets the barrel).
##
## `height` is the TOTAL height including both caps, matching Godot's CapsuleMesh,
## and is clamped to at least 2 * radius. At exactly 2 * radius you get a sphere.
##
## radial_segments: 24 default. rings: subdivisions per hemisphere, 6 default.
## radial=24, rings=6 costs 576 triangles — well under Godot's CapsuleMesh, whose
## defaults are 64 x 8.
static func capsule(radius: float, height: float, radial_segments: int = 24,
		rings: int = 6, uv_scale: float = 1.0) -> ArrayMesh:
	var r: float = maxf(radius, EPS)
	var mid: float = maxf(absf(height) - 2.0 * r, 0.0)
	var mh: float = mid * 0.5
	var rg: int = maxi(2, rings)

	var prof: Array = []
	for k in range(rg + 1):
		var a: float = -PI * 0.5 + (PI * 0.5) * (float(k) / float(rg))
		var ca: float = cos(a)
		var sa: float = sin(a)
		prof.append(Vector4(r * ca, -mh + r * sa, ca, sa))
	var top_start: int = 0
	if mid < EPS:
		top_start = 1
	for k in range(top_start, rg + 1):
		var a2: float = (PI * 0.5) * (float(k) / float(rg))
		var ca2: float = cos(a2)
		var sa2: float = sin(a2)
		prof.append(Vector4(r * ca2, mh + r * sa2, ca2, sa2))
	return lathe(prof, radial_segments, uv_scale)


# ===========================================================================
# TUBE / RING
# ===========================================================================

## A hollow tube — the shape of a bezel, a lens rim, a pipe collar, a washer.
## Outer wall, inner wall and two annular faces, with an optional fillet on all
## four rims.
##
## outer_radius / inner_radius: metres. inner is clamped below outer. An inner
##   radius of 0 has no hole to rim, so it forwards to cylinder().
## edge_bevel: fillet radius on each of the four rims. 0 = hard edges.
static func tube(outer_radius: float, inner_radius: float, height: float,
		radial_segments: int = 24, edge_bevel: float = 0.0,
		bevel_segments: int = 1, uv_scale: float = 1.0) -> ArrayMesh:
	var ro: float = maxf(outer_radius, EPS)
	var ri: float = clampf(inner_radius, 0.0, ro - EPS)
	if ri < EPS:
		# No hole: filleting an inner rim of radius 0 would leave a gap.
		return cylinder(ro, height, radial_segments, edge_bevel, bevel_segments,
			true, uv_scale)
	var hh: float = maxf(absf(height), EPS) * 0.5
	var wall: float = ro - ri
	var bseg: int = maxi(1, bevel_segments)
	var b: float = clampf(edge_bevel, 0.0, minf(hh * 0.5, wall * 0.25))
	if b < MIN_BEVEL:
		b = 0.0

	var up := Vector2(0.0, 1.0)
	var down := Vector2(0.0, -1.0)
	var outw := Vector2(1.0, 0.0)
	var inw := Vector2(-1.0, 0.0)

	# Walk the section once round: top face outward, down the outer wall, across
	# the bottom, up the inner wall, closing exactly where it started. The top
	# face starts at ri + b because that is where the inner rim fillet lands.
	var prof: Array = []
	prof.append(Vector4(ri + b, hh, 0.0, 1.0))
	_append_fillet(prof, Vector2(ro, hh), up, outw, b, bseg)
	_append_fillet(prof, Vector2(ro, -hh), outw, down, b, bseg)
	_append_fillet(prof, Vector2(ri, -hh), down, inw, b, bseg)
	_append_fillet(prof, Vector2(ri, hh), inw, up, b, bseg)
	return lathe(prof, radial_segments, uv_scale)


# ===========================================================================
# ROUNDED PANEL / PLATE
# ===========================================================================

## A plate with rounded corners and an optional bevel around both faces —
## a plaque, a sign backing, a control panel, a lid.
##
## The plate is centred on the origin and faces +Z. size.x = width,
## size.y = height, size.z = thickness. The straight sides stay dead flat (their
## normal is constant along the run) while the corner arcs shade smoothly, which
## is the correct read for a milled plate.
##
## corner_radius:   in-plane rounding, clamped to the smaller half-extent.
## corner_segments: subdivisions per corner. 3 is the cheap default.
## bevel:           chamfer around the front and back faces. Raises corner_radius
##                  to at least this value so the offset outline cannot invert.
## uv_scale:        UV units per metre. Face UVs are planar, wall UVs are
##                  (outline arc length, section arc length).
static func rounded_panel(size: Vector3, corner_radius: float = 0.02,
		corner_segments: int = 3, bevel: float = 0.0,
		bevel_segments: int = 1, uv_scale: float = 1.0) -> ArrayMesh:
	var hx: float = maxf(absf(size.x) * 0.5, EPS)
	var hy: float = maxf(absf(size.y) * 0.5, EPS)
	var hz: float = maxf(absf(size.z) * 0.5, EPS)
	var cs: int = maxi(1, corner_segments)
	var bseg: int = maxi(1, bevel_segments)
	var lim: float = minf(hx, hy)
	var b: float = clampf(bevel, 0.0, minf(hz * 0.5, lim * 0.5))
	if b < MIN_BEVEL:
		b = 0.0
	# A face bevel implies a corner at least that round, or the inward offset of
	# the outline turns the corners inside out.
	var r: float = maxf(clampf(corner_radius, 0.0, lim), b)

	# --- outline: positions and outward 2D normals, walked once around -------
	# Corner k contributes cs + 1 samples. The last sample of one corner and the
	# first of the next share a normal, so the straight run between them is flat.
	var centres: Array = [
		Vector2(hx - r, hy - r), Vector2(-hx + r, hy - r),
		Vector2(-hx + r, -hy + r), Vector2(hx - r, -hy + r),
	]
	var starts: Array = [0.0, PI * 0.5, PI, PI * 1.5]
	var out_p := PackedVector2Array()
	var out_n := PackedVector2Array()
	for ci in range(4):
		var cc: Vector2 = centres[ci]
		var a0: float = starts[ci]
		for k in range(cs + 1):
			var a: float = a0 + (PI * 0.5) * (float(k) / float(cs))
			var nn := Vector2(cos(a), sin(a))
			out_n.append(nn)
			out_p.append(cc + nn * r)
	var oc: int = out_p.size()

	# Cumulative outline arc length gives the wall's u coordinate.
	var ou := PackedFloat32Array()
	ou.resize(oc + 1)
	ou[0] = 0.0
	for i in range(oc):
		var nxt: Vector2 = out_p[(i + 1) % oc]
		ou[i + 1] = ou[i] + (nxt - out_p[i]).length()

	# --- section: (inward offset, z, normal_offset, normal_z) ---------------
	# Same idea as a lathe profile, but swept along the outline instead of a circle.
	var sect: Array = []
	if b > EPS:
		# Back face -> outer wall.
		for k in range(bseg + 1):
			var ab: float = -PI * 0.5 + (PI * 0.5) * (float(k) / float(bseg))
			var nb := Vector2(cos(ab), sin(ab))
			sect.append(Vector4(-b + b * nb.x, -hz + b + b * nb.y, nb.x, nb.y))
		# Outer wall -> front face.
		for k in range(bseg + 1):
			var af: float = (PI * 0.5) * (float(k) / float(bseg))
			var nf := Vector2(cos(af), sin(af))
			sect.append(Vector4(-b + b * nf.x, hz - b + b * nf.y, nf.x, nf.y))
	else:
		sect.append(Vector4(0.0, -hz, 0.0, -1.0))
		sect.append(Vector4(0.0, -hz, 1.0, 0.0))
		sect.append(Vector4(0.0, hz, 1.0, 0.0))
		sect.append(Vector4(0.0, hz, 0.0, 1.0))

	var sc: int = sect.size()
	var sv := PackedFloat32Array()
	sv.resize(sc)
	sv[0] = 0.0
	for i in range(1, sc):
		var s0: Vector4 = sect[i - 1]
		var s1: Vector4 = sect[i]
		sv[i] = sv[i - 1] + Vector2(s1.x - s0.x, s1.y - s0.y).length()

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# --- sweep the section around the outline -------------------------------
	for i in range(sc - 1):
		var sa: Vector4 = sect[i]
		var sb: Vector4 = sect[i + 1]
		for j in range(oc):
			var j1: int = (j + 1) % oc
			var pa: Vector2 = out_p[j]
			var pb: Vector2 = out_p[j1]
			var na: Vector2 = out_n[j]
			var nb2: Vector2 = out_n[j1]
			var q00 := Vector3(pa.x + na.x * sa.x, pa.y + na.y * sa.x, sa.y)
			var q10 := Vector3(pb.x + nb2.x * sa.x, pb.y + nb2.y * sa.x, sa.y)
			var q11 := Vector3(pb.x + nb2.x * sb.x, pb.y + nb2.y * sb.x, sb.y)
			var q01 := Vector3(pa.x + na.x * sb.x, pa.y + na.y * sb.x, sb.y)
			var m00: Vector3 = _norm3(Vector3(na.x * sa.z, na.y * sa.z, sa.w), Vector3.BACK)
			var m10: Vector3 = _norm3(Vector3(nb2.x * sa.z, nb2.y * sa.z, sa.w), Vector3.BACK)
			var m11: Vector3 = _norm3(Vector3(nb2.x * sb.z, nb2.y * sb.z, sb.w), Vector3.BACK)
			var m01: Vector3 = _norm3(Vector3(na.x * sb.z, na.y * sb.z, sb.w), Vector3.BACK)
			_quad(st, q00, q10, q11, q01, m00, m10, m11, m01,
				Vector2(ou[j], sv[i]) * uv_scale, Vector2(ou[j + 1], sv[i]) * uv_scale,
				Vector2(ou[j + 1], sv[i + 1]) * uv_scale, Vector2(ou[j], sv[i + 1]) * uv_scale)

	# --- the two flat faces, as fans over the inward-offset outline ---------
	# A rounded rectangle is convex, so a centre fan is always valid.
	var face_off: float = 0.0
	if b > EPS:
		face_off = -b
	for side in range(2):
		var z: float = hz
		var fn := Vector3(0, 0, 1)
		if side == 1:
			z = -hz
			fn = Vector3(0, 0, -1)
		var mid := Vector3(0, 0, z)
		for j in range(oc):
			var j1b: int = (j + 1) % oc
			var pa2: Vector2 = out_p[j] + out_n[j] * face_off
			var pb2: Vector2 = out_p[j1b] + out_n[j1b] * face_off
			_tri(st, mid, Vector3(pa2.x, pa2.y, z), Vector3(pb2.x, pb2.y, z),
				fn, fn, fn,
				Vector2.ZERO,
				Vector2(pa2.x, -pa2.y) * uv_scale,
				Vector2(pb2.x, -pb2.y) * uv_scale)

	return _finish(st)


# ===========================================================================
# TANGENTS — for meshes this kit did not build
# ===========================================================================

## True if `surface` carries a tangent array. Use it to assert before shipping a
## normal-mapped material: a normal map on a tangentless mesh is a silent no-op.
static func has_tangents(mesh: Mesh, surface: int = 0) -> bool:
	if mesh == null or surface < 0 or surface >= mesh.get_surface_count():
		return false
	var arrays: Array = mesh.surface_get_arrays(surface)
	if arrays.size() <= Mesh.ARRAY_TANGENT:
		return false
	var t: Variant = arrays[Mesh.ARRAY_TANGENT]
	return typeof(t) == TYPE_PACKED_FLOAT32_ARRAY and (t as PackedFloat32Array).size() > 0


## Return an ArrayMesh copy of `source` with tangents generated.
##
## Pass surface = -1 (the default) to convert every surface; a surface index
## converts just that one. Per-surface materials are carried across.
##
## Generating tangents needs UVs and normals. If a surface has neither, this
## warns LOUDLY and copies the surface through untouched rather than pretending
## it worked — the failure mode this project keeps rediscovering is the quiet one.
## Returns null only if `source` is null or the index is out of range.
static func with_tangents(source: Mesh, surface: int = -1) -> ArrayMesh:
	if source == null:
		push_warning("MeshKit.with_tangents: source is null")
		return null
	var count: int = source.get_surface_count()
	if count == 0:
		push_warning("MeshKit.with_tangents: source has no surfaces")
		return null
	var first: int = 0
	var last: int = count - 1
	if surface >= 0:
		if surface >= count:
			push_warning("MeshKit.with_tangents: surface %d of %d out of range"
				% [surface, count])
			return null
		first = surface
		last = surface

	var out := ArrayMesh.new()
	for s in range(first, last + 1):
		var arrays: Array = source.surface_get_arrays(s)
		var prim: int = source.surface_get_primitive_type(s)
		var mat: Material = source.surface_get_material(s)
		var uv_raw: Variant = arrays[Mesh.ARRAY_TEX_UV]
		var nrm_raw: Variant = arrays[Mesh.ARRAY_NORMAL]
		var has_uv: bool = typeof(uv_raw) == TYPE_PACKED_VECTOR2_ARRAY
		if has_uv:
			has_uv = (uv_raw as PackedVector2Array).size() > 0
		var has_nrm: bool = typeof(nrm_raw) == TYPE_PACKED_VECTOR3_ARRAY
		if has_nrm:
			has_nrm = (nrm_raw as PackedVector3Array).size() > 0
		var ok: bool = has_uv and has_nrm and prim == Mesh.PRIMITIVE_TRIANGLES
		if not ok:
			var missing: String = "a non-triangle primitive"
			if not has_uv:
				missing = "no UVs"
			elif not has_nrm:
				missing = "no normals"
			push_warning("MeshKit.with_tangents: surface %d has %s. Tangents CANNOT be generated; any normal map on it will do NOTHING." % [s, missing])
			out.add_surface_from_arrays(prim, arrays)
		else:
			var st := SurfaceTool.new()
			st.create_from(source, s)
			st.generate_tangents()
			var tmp: ArrayMesh = st.commit() as ArrayMesh
			if tmp != null and tmp.get_surface_count() > 0:
				out.add_surface_from_arrays(tmp.surface_get_primitive_type(0),
					tmp.surface_get_arrays(0))
			else:
				out.add_surface_from_arrays(prim, arrays)
		if mat != null and out.get_surface_count() > 0:
			out.surface_set_material(out.get_surface_count() - 1, mat)
	return out


## Give an existing MeshInstance3D tangents in place, keeping its surface override
## materials. This is the one-line rescue for a node already built from BoxMesh or
## CylinderMesh: MeshKit.ensure_tangents(mi) and its normal map starts working.
## Returns true if the mesh was replaced.
static func ensure_tangents(mi: MeshInstance3D) -> bool:
	if mi == null or mi.mesh == null:
		return false
	var src: Mesh = mi.mesh
	var count: int = src.get_surface_count()
	var already: bool = count > 0
	for s in range(count):
		if not has_tangents(src, s):
			already = false
			break
	if already:
		return false
	var overrides: Array = []
	for s in range(count):
		overrides.append(mi.get_surface_override_material(s))
	var converted: ArrayMesh = with_tangents(src, -1)
	if converted == null:
		return false
	mi.mesh = converted
	for s in range(mini(overrides.size(), converted.get_surface_count())):
		var om: Material = overrides[s]
		if om != null:
			mi.set_surface_override_material(s, om)
	return true


# ===========================================================================
# UTILITY
# ===========================================================================

## Wrap a mesh in a MeshInstance3D. The material goes on the MESH surfaces, not
## on material_override and not on a surface override slot, so both of those stay
## free for highlight and pickup systems that swap them.
static func make_instance(mesh: ArrayMesh, mat: Material = null,
		node_name: String = "Mesh") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	if mesh != null and mat != null:
		for s in range(mesh.get_surface_count()):
			mesh.surface_set_material(s, mat)
	mi.mesh = mesh
	return mi


## The common case in one call: a bevelled box as a ready node.
static func box_instance(size: Vector3, mat: Material = null, bevel: float = 0.01,
		node_name: String = "Box") -> MeshInstance3D:
	return make_instance(bevel_box(size, bevel), mat, node_name)


## The other common case: a bevel-capped cylinder as a ready node.
static func cylinder_instance(radius: float, height: float, mat: Material = null,
		cap_bevel: float = 0.006, radial_segments: int = 24,
		node_name: String = "Cylinder") -> MeshInstance3D:
	return make_instance(cylinder(radius, height, radial_segments, cap_bevel),
		mat, node_name)


## Triangle count across every surface. Cheap. Use it to keep a VR budget honest.
static func tri_count(mesh: Mesh) -> int:
	if mesh == null:
		return 0
	var total: int = 0
	for s in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(s)
		var idx: Variant = arrays[Mesh.ARRAY_INDEX]
		if typeof(idx) == TYPE_PACKED_INT32_ARRAY and (idx as PackedInt32Array).size() > 0:
			total += int(float((idx as PackedInt32Array).size()) / 3.0)
			continue
		var vtx: Variant = arrays[Mesh.ARRAY_VERTEX]
		if typeof(vtx) == TYPE_PACKED_VECTOR3_ARRAY:
			total += int(float((vtx as PackedVector3Array).size()) / 3.0)
	return total
