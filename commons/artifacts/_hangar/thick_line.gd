extends RefCounted
## (no class_name: use it as  const ThickLine := preload("res://commons/artifacts/_hangar/thick_line.gd")  - a new
## class_name is unknown to the global class cache until the editor rescans, and headless runs never do)
## A line you can see across a room. Godot draws PRIMITIVE_LINES / PRIMITIVE_LINE_STRIP one pixel wide at any width,
## so a figure that IS its line (a sine wave, a Lissajous knot, an orbit) vanishes beyond a metre or two (2026-11-09:
## the Foucault pendulum's ink, the Lissajous curve, the sine oscillation's circle and waves). These turn a polyline
## into a tube: a ring of `sides` vertices round each point, carried along the line without twisting (each ring's
## normal is the last one with its along-line part taken out).
##
##   ThickLine.append_tube(im, points, colors, radius)        into an ImmediateMesh, between surface_begin/end calls
##                                                             of its own (one surface per call)
##   ThickLine.append_segments(im, pairs, colors, radius)      the same for PRIMITIVE_LINES data: pairs of points
##                                       (..., radius, sides, radii)  radii: one per pair (a tree: thick trunk, thin
##                                                                    tips); where given it overrides `radius`
##   ThickLine.tube_mesh(points, colors, radius) -> ArrayMesh  a standing mesh, indexed
##
## colors may be empty (white), one colour (the whole line) or one per point.


static func _rings(points: PackedVector3Array, radius: float, sides: int) -> Array:
	var n: int = points.size()
	var ring_pos: Array = []
	var ring_nrm: Array = []
	if n < 2:
		return [ring_pos, ring_nrm]
	var first: Vector3 = points[1] - points[0]
	if first.length_squared() < 1e-14:
		first = Vector3.RIGHT
	first = first.normalized()
	var nrm: Vector3 = first.cross(Vector3.UP if absf(first.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT).normalized()
	for i in n:
		var a: Vector3 = points[maxi(i - 1, 0)]
		var b: Vector3 = points[mini(i + 1, n - 1)]
		var tan: Vector3 = b - a
		if tan.length_squared() > 1e-14:
			tan = tan.normalized()
			nrm = nrm - tan * nrm.dot(tan)
			if nrm.length_squared() < 1e-12:
				nrm = tan.cross(Vector3.UP if absf(tan.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT)
			nrm = nrm.normalized()
		var bin: Vector3 = tan.cross(nrm)
		var pos := PackedVector3Array(); pos.resize(sides)
		var nor := PackedVector3Array(); nor.resize(sides)
		for k in sides:
			var ang: float = TAU * float(k) / float(sides)
			var d: Vector3 = nrm * cos(ang) + bin * sin(ang)
			pos[k] = points[i] + d * radius
			nor[k] = d
		ring_pos.append(pos)
		ring_nrm.append(nor)
	return [ring_pos, ring_nrm]


static func _color_at(colors: PackedColorArray, i: int) -> Color:
	if colors.is_empty():
		return Color.WHITE
	if colors.size() == 1:
		return colors[0]
	return colors[mini(i, colors.size() - 1)]


## One tube for one polyline, as its own surface of `im` (TRIANGLES). Call between clear_surfaces() and the next draw.
static func append_tube(im: ImmediateMesh, points: PackedVector3Array, colors: PackedColorArray, radius: float, sides: int = 6) -> void:
	if points.size() < 2:
		return
	var rings: Array = _rings(points, radius, sides)
	var rp: Array = rings[0]
	var rn: Array = rings[1]
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in points.size() - 1:
		var c0: Color = _color_at(colors, i)
		var c1: Color = _color_at(colors, i + 1)
		for k in sides:
			var k2: int = (k + 1) % sides
			for v in [[i, k, c0], [i, k2, c0], [i + 1, k2, c1], [i, k, c0], [i + 1, k2, c1], [i + 1, k, c1]]:
				im.surface_set_color(v[2])
				im.surface_set_normal((rn[v[0]] as PackedVector3Array)[v[1]])
				im.surface_add_vertex((rp[v[0]] as PackedVector3Array)[v[1]])
	im.surface_end()


## PRIMITIVE_LINES data (point pairs) as short tubes, one surface. colors: one per pair, or one for all, or empty.
## radii: one per pair, or empty (all `radius`).
static func append_segments(im: ImmediateMesh, pairs: PackedVector3Array, colors: PackedColorArray, radius: float, sides: int = 5, radii: PackedFloat32Array = PackedFloat32Array()) -> void:
	if pairs.size() < 2:
		return
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for s in pairs.size() / 2:
		var a: Vector3 = pairs[s * 2]
		var b: Vector3 = pairs[s * 2 + 1]
		var tan: Vector3 = b - a
		if tan.length_squared() < 1e-14:
			continue
		tan = tan.normalized()
		var nrm: Vector3 = tan.cross(Vector3.UP if absf(tan.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT).normalized()
		var bin: Vector3 = tan.cross(nrm)
		var col: Color = _color_at(colors, s)
		var r: float = radii[s] if s < radii.size() else radius
		for k in sides:
			var a0: float = TAU * float(k) / float(sides)
			var a1: float = TAU * float(k + 1) / float(sides)
			var d0: Vector3 = nrm * cos(a0) + bin * sin(a0)
			var d1: Vector3 = nrm * cos(a1) + bin * sin(a1)
			for v in [[a, d0], [a, d1], [b, d1], [a, d0], [b, d1], [b, d0]]:
				im.surface_set_color(col)
				im.surface_set_normal(v[1])
				im.surface_add_vertex(v[0] + v[1] * r)
	im.surface_end()


## A standing indexed tube mesh (for a curve rebuilt now and then, not every frame by ImmediateMesh).
static func tube_mesh(points: PackedVector3Array, colors: PackedColorArray, radius: float, sides: int = 6) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var n: int = points.size()
	if n < 2:
		return mesh
	var rings: Array = _rings(points, radius, sides)
	var verts := PackedVector3Array(); verts.resize(n * sides)
	var norms := PackedVector3Array(); norms.resize(n * sides)
	var cols := PackedColorArray(); cols.resize(n * sides)
	for i in n:
		var rp: PackedVector3Array = rings[0][i]
		var rn: PackedVector3Array = rings[1][i]
		var c: Color = _color_at(colors, i)
		for k in sides:
			verts[i * sides + k] = rp[k]; norms[i * sides + k] = rn[k]; cols[i * sides + k] = c
	var idx := PackedInt32Array(); idx.resize((n - 1) * sides * 6)
	var w: int = 0
	for i in n - 1:
		for k in sides:
			var k2: int = (k + 1) % sides
			var p0: int = i * sides + k; var p1: int = i * sides + k2; var p2: int = (i + 1) * sides + k2; var p3: int = (i + 1) * sides + k
			idx[w] = p0; idx[w + 1] = p1; idx[w + 2] = p2; idx[w + 3] = p0; idx[w + 4] = p2; idx[w + 5] = p3
			w += 6
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
