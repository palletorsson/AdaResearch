## CellInsetOp — Inset a CELL of triangles toward the vertex they share, and open it.
##
## InsetFaceOp shrinks one triangle toward its own middle, so its pores are
## triangles. A cell here is all the triangles round one vertex (six of them on a
## staggered lattice): each triangle keeps only a strip along its outer edge, and
## the strips of one cell close into a ring. The middle is left open: a hexagonal
## pore with a bar of even width round it. This is the pore of a radiolarian shell.
##
## Which vertices are centres:
##   - vertices tagged `centre_tag` (MeshData.create_lathe tags every third wall
##     vertex when its segment count is a multiple of 3, so the cells cover the wall);
##   - if no selected face touches a tagged vertex, centres are chosen here, in
##     vertex order: a vertex becomes a centre when all its faces are selected and
##     none of them is in a cell yet. On an irregular mesh that leaves some
##     triangles whole between the cells.
## A selected face with no centre, or with two, is left as it is.
##
## Params:
##   bar: float = 0.3            — width of the bar: how far the two outer vertices
##                                 are pulled toward the centre (0 = no bar, 1 = closed)
##   bar_end: float = -1.0       — if >= 0, the bar at the LOW end of grade_axis; `bar`
##                                 is then the bar at the high end, so pores grow or
##                                 shrink along the body
##   grade_axis: Vector3 = UP    — the direction the bar is graded along
##   max_fan: int = 8            — a vertex with more faces than this is never chosen
##                                 as a centre here (the pole of a sphere has 16)
##   open: bool = true           — leave the middle open; false keeps it, tagged pore_tag
##   centre_tag: String = "centre"
##   bar_tag: String = "bar"
##   pore_tag: String = "pore"
##
## No class_name, on purpose: readers preload this file, so nothing waits for the
## global class cache to be rebuilt.
extends MeshRule

func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var bar: float = clampf(float(params.get("bar", 0.3)), 0.02, 0.98)
	var bar_end: float = float(params.get("bar_end", -1.0))
	var grade_axis: Vector3 = params.get("grade_axis", Vector3.UP)
	var max_fan: int = int(params.get("max_fan", 8))
	var open: bool = bool(params.get("open", true))
	var centre_tag: String = params.get("centre_tag", "centre")
	var bar_tag: String = params.get("bar_tag", "bar")
	var pore_tag: String = params.get("pore_tag", "pore")

	var chosen: Dictionary = {}
	for fi in selected:
		if fi < mesh.faces.size():
			chosen[fi] = true

	if not _any_centre(mesh, chosen, centre_tag):
		_choose_centres(mesh, chosen, centre_tag, max_fan)

	# The span of the selection along the grade axis, for a graded bar.
	var axis: Vector3 = grade_axis.normalized() if grade_axis.length_squared() > 0.0 else Vector3.UP
	var low: float = INF
	var high: float = -INF
	if bar_end >= 0.0:
		for fi in chosen:
			var h: float = mesh.get_face_centroid(fi).dot(axis)
			low = minf(low, h)
			high = maxf(high, h)

	var gone := PackedInt32Array()
	var strips: Array = []       # [indices, tags, depth]
	var pulled: Dictionary = {}  # Vector2i(centre, outer) -> new vertex index

	var order: Array = chosen.keys()
	order.sort()
	for fi in order:
		var f: PackedInt32Array = mesh.faces[fi]
		var k: int = -1
		var found: int = 0
		for n in range(3):
			if _is_centre(mesh, f[n], centre_tag):
				k = n
				found += 1
		if found != 1:
			continue
		var c: int = f[k]
		var p: int = f[(k + 1) % 3]
		var q: int = f[(k + 2) % 3]

		var width: float = bar
		if bar_end >= 0.0 and high > low:
			var t: float = inverse_lerp(low, high, mesh.get_face_centroid(fi).dot(axis))
			width = clampf(lerpf(bar_end, bar, t), 0.02, 0.98)

		var inner: Array[int] = []
		for v in [p, q]:
			var key := Vector2i(c, v)
			if not pulled.has(key):
				pulled[key] = mesh.add_vertex(mesh.vertices[v].lerp(mesh.vertices[c], width))
			inner.append(pulled[key])

		var depth: int = 0
		if fi < mesh.face_depth.size():
			depth = mesh.face_depth[fi]
		var kept := PackedStringArray()
		if fi < mesh.face_tags.size():
			for tag in mesh.face_tags[fi]:
				if tag.begins_with("zone_"):
					kept.append(tag)

		var bar_tags := PackedStringArray(kept)
		bar_tags.append(bar_tag)
		gone.append(fi)
		strips.append([PackedInt32Array([p, q, inner[1]]), bar_tags, depth + 1])
		strips.append([PackedInt32Array([p, inner[1], inner[0]]), bar_tags, depth + 1])
		if not open:
			var pore_tags := PackedStringArray(kept)
			pore_tags.append(pore_tag)
			strips.append([PackedInt32Array([c, inner[0], inner[1]]), pore_tags, depth + 1])

	if gone.is_empty():
		return
	mesh.remove_faces(gone)
	for s in strips:
		mesh.add_face(s[0], s[1], s[2])
	mesh._adjacency_dirty = true


func _is_centre(mesh: MeshData, v: int, centre_tag: String) -> bool:
	return v < mesh.vertex_tags.size() and mesh.vertex_tags[v].has(centre_tag)


func _any_centre(mesh: MeshData, chosen: Dictionary, centre_tag: String) -> bool:
	for fi in chosen:
		for v in mesh.faces[fi]:
			if _is_centre(mesh, v, centre_tag):
				return true
	return false


## Choose centres in vertex order: a vertex whose faces are all selected and none
## of them already in a cell. Tags them, so a later rule finds the same cells.
func _choose_centres(mesh: MeshData, chosen: Dictionary, centre_tag: String, max_fan: int) -> void:
	var taken: Dictionary = {}
	for v in range(mesh.vertices.size()):
		var fan: PackedInt32Array = mesh.get_vertex_faces(v)
		if fan.size() < 3 or fan.size() > max_fan:
			continue
		var free: bool = true
		for fi in fan:
			if not chosen.has(fi) or taken.has(fi):
				free = false
				break
		if not free:
			continue
		for fi in fan:
			taken[fi] = true
		if v < mesh.vertex_tags.size():
			var tags: PackedStringArray = mesh.vertex_tags[v]
			tags.append(centre_tag)
			mesh.vertex_tags[v] = tags
