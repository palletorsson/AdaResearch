extends RefCounted
## Module: a field — a surface where a function of space crosses zero (Palle, 26 Oct: "continue";
## the operator the main track's last step was waiting for: isosurfaces and booleans are one idea).
## The function is a small tree of signed distances and their combinations. The surface is found by
## marching tetrahedra: each grid cube is cut into six tetrahedra about its main diagonal (the same
## cut in every cube, so neighbours agree on every shared face), and a tetrahedron has no ambiguous
## case — one vertex per cell (surface nets) folded where two sheets of surface met in a cell, so the
## gyroid came out non-manifold. Vertices are welded per grid edge: one closed body. Each triangle is
## turned to face away from its tetrahedron's outside corners — judged on the MIDPOINTS of the edges
## it crosses, a proxy that never collapses (a box face on a grid plane puts crossings ON grid points,
## and a zero-area triangle has no side) — then reversed for Godot, which winds front faces clockwise. probe_field.gd asserts every mesh against the field that made it.
##
##   {"op": "field", "fn": f, "box": [sx, sy, sz], "center": [x, y, z], "res": cells,
##    "color": hex, "alpha": a, "collide": true}
##   f = {"sphere": r, "at": [x, y, z]} | {"box": [hx, hy, hz], "at"} | {"torus": [R, r], "at"}
##     | {"cylinder": [r, half_height], "at"} | {"gyroid": scale, "thickness": t, "at"}
##     | {"metaballs": [[x, y, z, r], ...]} | {"terrain": freq, "amp": a, "base": y}
##     | {"blobs": freq, "threshold": t} | {"plane": [nx, ny, nz], "d": d}
##     | {"capsule": [[x, y, z], [x, y, z]], "r": r}
##     | {"union": [f, ...]} | {"intersect": [f, ...]} | {"subtract": [body, cutter], "k": smooth}
##     | {"smooth_union": [f, g, ...], "k": k}
## The field is intersected with its sampling box (half a cell inside), so a surface the box cuts is
## capped: one closed body, and the same function decides the samples and the normals.

const CORNERS := [Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0),
	Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(0, 1, 1), Vector3(1, 1, 1)]
## six tetrahedra about the diagonal 0-7 (Kuhn): the same cut in every cube, so shared faces agree
const TETS := [[0, 1, 3, 7], [0, 3, 2, 7], [0, 2, 6, 7], [0, 6, 4, 7], [0, 4, 5, 7], [0, 5, 1, 7]]


static func value(f: Dictionary, p: Vector3) -> float:
	if f.has("union"):
		var m := INF
		for g in f["union"]:
			m = minf(m, value(g, p))
		return m
	if f.has("intersect"):
		var m2 := -INF
		for g in f["intersect"]:
			m2 = maxf(m2, value(g, p))
		return m2
	if f.has("subtract"):
		var parts: Array = f["subtract"]
		var a: float = value(parts[0], p)
		var c: float = value(parts[1], p)   # the cutter's OWN distance: max(a, -c), or -smin(-a, c, k)
		var k: float = float(f.get("k", 0.0))
		return maxf(a, -c) if k <= 0.0 else -_smin(-a, c, k)
	if f.has("smooth_union"):
		# folded over any number of parts: a body grown along a network melts at every joint
		var pp: Array = f["smooth_union"]
		var k2: float = float(f.get("k", 0.1))
		var acc: float = value(pp[0], p)
		for gi in range(1, pp.size()):
			acc = _smin(acc, value(pp[gi], p), k2)
		return acc
	if f.has("capsule"):
		# a segment with a radius: the distance to the segment, less r
		var seg: Array = f["capsule"]
		var a2: Vector3 = _v3(seg[0])
		var ab: Vector3 = _v3(seg[1]) - a2
		var t: float = clampf((p - a2).dot(ab) / maxf(ab.length_squared(), 1e-12), 0.0, 1.0)
		return p.distance_to(a2 + ab * t) - float(f.get("r", 0.05))
	var q: Vector3 = p - _v3(f.get("at", null))
	if f.has("sphere"):
		return q.length() - float(f["sphere"])
	if f.has("box"):
		return box_sdf(q, _v3(f["box"]))
	if f.has("torus"):
		var tr: Array = f["torus"]
		return Vector2(Vector2(q.x, q.z).length() - float(tr[0]), q.y).length() - float(tr[1])
	if f.has("cylinder"):
		var cy: Array = f["cylinder"]
		var dx: float = Vector2(q.x, q.z).length() - float(cy[0])
		var dy: float = absf(q.y) - float(cy[1])
		return minf(maxf(dx, dy), 0.0) + Vector2(maxf(dx, 0.0), maxf(dy, 0.0)).length()
	if f.has("gyroid"):
		var s: float = float(f["gyroid"])
		var g: float = sin(s * q.x) * cos(s * q.y) + sin(s * q.y) * cos(s * q.z) + sin(s * q.z) * cos(s * q.x)
		return absf(g) / s - float(f.get("thickness", 0.05))
	if f.has("metaballs"):
		var sum := 0.0
		for b in f["metaballs"]:
			var c2 := Vector3(float(b[0]), float(b[1]), float(b[2]))
			sum += float(b[3]) * float(b[3]) / maxf(p.distance_squared_to(c2), 1e-6)
		return 1.0 - sum
	if f.has("terrain"):
		var fr: float = float(f["terrain"])
		return q.y - (float(f.get("base", 0.3)) + float(f.get("amp", 0.2)) * (noise3(q.x * fr, 0.0, q.z * fr) * 2.0 - 1.0))
	if f.has("blobs"):
		var fb: float = float(f["blobs"])
		return float(f.get("threshold", 0.5)) - noise3(q.x * fb, q.y * fb, q.z * fb)
	if f.has("plane"):
		return q.dot(_v3(f["plane"]).normalized()) - float(f.get("d", 0.0))
	return 1.0


## the field as meshed: intersected with the sampling box, half a cell inside
static func capped(f: Dictionary, center: Vector3, half: Vector3, cs: float, p: Vector3) -> float:
	return maxf(value(f, p), box_sdf(p - center, half - Vector3.ONE * cs * 0.5))


static func box_sdf(q: Vector3, h: Vector3) -> float:
	var d: Vector3 = q.abs() - h
	return Vector3(maxf(d.x, 0.0), maxf(d.y, 0.0), maxf(d.z, 0.0)).length() + minf(maxf(d.x, maxf(d.y, d.z)), 0.0)


static func noise3(x: float, y: float, z: float) -> float:
	var ix := floorf(x)
	var iy := floorf(y)
	var iz := floorf(z)
	var fx := x - ix
	var fy := y - iy
	var fz := z - iz
	var ux := fx * fx * (3.0 - 2.0 * fx)
	var uy := fy * fy * (3.0 - 2.0 * fy)
	var uz := fz * fz * (3.0 - 2.0 * fz)
	var x00 := lerpf(_hash(ix, iy, iz), _hash(ix + 1, iy, iz), ux)
	var x10 := lerpf(_hash(ix, iy + 1, iz), _hash(ix + 1, iy + 1, iz), ux)
	var x01 := lerpf(_hash(ix, iy, iz + 1), _hash(ix + 1, iy, iz + 1), ux)
	var x11 := lerpf(_hash(ix, iy + 1, iz + 1), _hash(ix + 1, iy + 1, iz + 1), ux)
	return lerpf(lerpf(x00, x10, uy), lerpf(x01, x11, uy), uz)


static func _hash(x: float, y: float, z: float) -> float:
	var h: float = sin(x * 127.1 + y * 311.7 + z * 74.7) * 43758.5453
	return h - floorf(h)


static func _smin(a: float, b: float, k: float) -> float:
	var h: float = maxf(k - absf(a - b), 0.0) / k
	return minf(a, b) - h * h * k * 0.25


static func _v3(v: Variant) -> Vector3:
	if v is Array and (v as Array).size() >= 3:
		return Vector3(float(v[0]), float(v[1]), float(v[2]))
	return Vector3.ZERO


## the mesh state shared by the tetrahedra: samples, welded vertices and triangles
class Net:
	var vals: PackedFloat32Array
	var origin: Vector3
	var cs: float
	var sx: int
	var sy: int
	var npts: int
	var weld := {}
	var verts: Array = []
	var mids: Array = []   # the midpoint of each vertex's grid edge: the proxy the winding is judged on
	var tris: Array = []

	func point(g: int) -> Vector3:
		var i: int = g % sx
		var r: int = g / sx
		return origin + Vector3(i, r % sy, r / sy) * cs

	## the vertex where the grid edge ga-gb crosses zero, made once and shared
	func cross(ga: int, gb: int) -> int:
		var key: int = mini(ga, gb) * npts + maxi(ga, gb)
		if weld.has(key):
			return weld[key]
		var va: float = vals[ga]
		var vb: float = vals[gb]
		weld[key] = verts.size()
		verts.append(point(ga).lerp(point(gb), va / (va - vb)))
		mids.append((point(ga) + point(gb)) * 0.5)
		return weld[key]

	## a triangle turned to face away from the tetrahedron's outside corners, emitted for Godot
	func face(a: int, b: int, c: int, outside: Vector3) -> void:
		var pa: Vector3 = mids[a]
		var n: Vector3 = (mids[b] - pa).cross(mids[c] - pa)
		var toward: Vector3 = outside - (pa + mids[b] + mids[c]) / 3.0
		# textbook-outward (b-a)x(c-a) is counter-clockwise from outside; Godot's front faces are
		# clockwise, so an outward triangle is emitted a, c, b
		if n.dot(toward) >= 0.0:
			tris.append_array([a, c, b])
		else:
			tris.append_array([a, b, c])


static func build(expr: Dictionary) -> Node3D:
	var f: Dictionary = expr.get("fn", {"sphere": 0.4})
	var size: Vector3 = _v3(expr.get("box", [1.2, 1.2, 1.2]))
	var center: Vector3 = _v3(expr["center"]) if expr.has("center") else Vector3(0, size.y * 0.5, 0)
	var res: int = clampi(int(expr.get("res", 28)), 6, 64)
	var cs: float = maxf(size.x, maxf(size.y, size.z)) / res
	var nx: int = maxi(2, int(ceil(size.x / cs)))
	var ny: int = maxi(2, int(ceil(size.y / cs)))
	var nz: int = maxi(2, int(ceil(size.z / cs)))
	var half := Vector3(nx, ny, nz) * cs * 0.5
	var net := Net.new()
	net.origin = center - half
	net.cs = cs
	net.sx = nx + 1
	net.sy = ny + 1
	net.npts = net.sx * net.sy * (nz + 1)
	net.vals.resize(net.npts)
	for k in nz + 1:
		for j in net.sy:
			for i in net.sx:
				var v: float = capped(f, center, half, cs, net.origin + Vector3(i, j, k) * cs)
				net.vals[i + net.sx * (j + net.sy * k)] = v if v != 0.0 else 1e-9   # no vertex sits exactly on a grid point
	for k in nz:
		for j in ny:
			for i in nx:
				var ids: Array = []
				var n_in := 0
				for c in CORNERS:
					var g: int = (i + int(c.x)) + net.sx * ((j + int(c.y)) + net.sy * (k + int(c.z)))
					ids.append(g)
					if net.vals[g] < 0.0:
						n_in += 1
				if n_in == 0 or n_in == 8:
					continue
				for tet in TETS:
					var ins: Array = []
					var outs: Array = []
					for t in tet:
						if net.vals[ids[t]] < 0.0:
							ins.append(ids[t])
						else:
							outs.append(ids[t])
					if ins.is_empty() or outs.is_empty():
						continue
					var out_c := Vector3.ZERO
					for g2 in outs:
						out_c += net.point(g2)
					out_c /= outs.size()
					if ins.size() == 1:
						net.face(net.cross(ins[0], outs[0]), net.cross(ins[0], outs[1]), net.cross(ins[0], outs[2]), out_c)
					elif ins.size() == 3:
						net.face(net.cross(outs[0], ins[0]), net.cross(outs[0], ins[1]), net.cross(outs[0], ins[2]), out_c)
					else:
						# two in (a, b), two out (c, d): the crossings run a-c, a-d, b-d, b-c around the quad;
						# fanned across the diagonal a-c / b-d
						var ac: int = net.cross(ins[0], outs[0])
						var ad: int = net.cross(ins[0], outs[1])
						var bd: int = net.cross(ins[1], outs[1])
						var bc: int = net.cross(ins[1], outs[0])
						net.face(ac, ad, bd, out_c)
						net.face(ac, bd, bc, out_c)
	var verts := PackedVector3Array(net.verts)
	var tris := PackedInt32Array(net.tris)
	# normals: the field's own gradient, outward
	var normals := PackedVector3Array()
	var h: float = cs * 0.5
	for v in verts:
		var gx: float = capped(f, center, half, cs, v + Vector3(h, 0, 0)) - capped(f, center, half, cs, v - Vector3(h, 0, 0))
		var gy: float = capped(f, center, half, cs, v + Vector3(0, h, 0)) - capped(f, center, half, cs, v - Vector3(0, h, 0))
		var gz: float = capped(f, center, half, cs, v + Vector3(0, 0, h)) - capped(f, center, half, cs, v - Vector3(0, 0, h))
		normals.append(Vector3(gx, gy, gz).normalized())
	var root := Node3D.new()
	root.name = "field"
	var mi := MeshInstance3D.new()
	mi.name = "surface"
	if tris.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_INDEX] = tris
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mi.mesh = am
	var mat := StandardMaterial3D.new()
	var col := Color(str(expr.get("color", "f3ecdd")))
	col.a = float(expr.get("alpha", 1.0))
	mat.albedo_color = col
	if col.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.6
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED   # a facet folded where a wall is thin is still drawn, lit by the gradient
	mi.material_override = mat
	mi.set_meta("field", {"fn": f, "center": center, "half": half, "cell": cs})
	root.add_child(mi)
	if bool(expr.get("collide", false)) and mi.mesh != null:
		# collision support: the surface itself, so a body can stand where the field is solid
		var body := StaticBody3D.new()
		body.name = "ground"
		body.set_meta("modular_body", "static")
		var shape := CollisionShape3D.new()
		shape.shape = mi.mesh.create_trimesh_shape()
		body.add_child(shape)
		root.add_child(body)
	return root
