## SmoothSubdivideOp — One pass of Loop subdivision, in place.
##
## Loop subdivision is the standard smoother for triangle meshes:
## every triangle becomes four sub-triangles, and every vertex is
## repositioned by a weighted average of itself and its neighbours.
## After one pass, polygonal seams melt into smooth fillets.
##
## This is the universal *finisher* for the mesh-grammar pipeline:
## works equally well on tube tubes, capped joints, stamped petals,
## metaball blobs, anything triangulated. Tags propagate from the
## original face to all four of its children.
##
## Cost is O(faces × 4) per pass; one pass is usually enough. Two
## passes give 16× face count and visibly rounder forms but ~4×
## render cost.
##
## Params:
##   passes: int = 1 — how many subdivision steps to apply
##   smooth_vertices: bool = true — Loop's repositioning weights
##                                  (false = pure split, no smoothing)
extends MeshRule
class_name SmoothSubdivideOp


func _execute(mesh: MeshData, _selected: PackedInt32Array) -> void:
	# Loop subdivision is intrinsically global — it touches every face.
	# We ignore _selected and operate on the full mesh.
	var passes: int = max(int(params.get("passes", 1)), 0)
	var smooth_vertices: bool = bool(params.get("smooth_vertices", true))
	for _i in range(passes):
		_subdivide_once(mesh, smooth_vertices)


func _subdivide_once(mesh: MeshData, smooth_vertices: bool) -> void:
	var n_old_verts: int = mesh.vertices.size()
	var old_faces: Array = mesh.faces.duplicate(true)
	var old_face_tags: Array = mesh.face_tags.duplicate(true)
	var old_face_metadata: Array = mesh.face_metadata.duplicate(true)
	var old_face_depth: PackedInt32Array = mesh.face_depth.duplicate()

	# Build edge -> midpoint vertex index map. Edge key is (min, max).
	var edge_mid: Dictionary = {}  # "a_b" -> int
	# Also track which faces share each edge for Loop's edge weighting.
	var edge_faces: Dictionary = {}  # "a_b" -> Array[face_idx]
	for fi in range(old_faces.size()):
		var f: PackedInt32Array = old_faces[fi]
		for k in range(3):
			var a: int = f[k]
			var b: int = f[(k + 1) % 3]
			var key := _edge_key(a, b)
			if not edge_faces.has(key):
				edge_faces[key] = []
			(edge_faces[key] as Array).append(fi)

	# Place midpoint vertices. Loop weight: 3/8*(a+b) + 1/8*(c+d) where c,d
	# are the opposite verts of the two adjacent faces. For boundary edges
	# (only one adjacent face), use plain midpoint.
	for key in edge_faces.keys():
		var parts: PackedStringArray = String(key).split("_")
		var a: int = int(parts[0])
		var b: int = int(parts[1])
		var faces_here: Array = edge_faces[key]
		var pos: Vector3
		if smooth_vertices and faces_here.size() == 2:
			var va: Vector3 = mesh.vertices[a]
			var vb: Vector3 = mesh.vertices[b]
			var opp_sum := Vector3.ZERO
			for fi in faces_here:
				var f: PackedInt32Array = old_faces[fi]
				for vi in f:
					if vi != a and vi != b:
						opp_sum += mesh.vertices[vi]
			pos = (va + vb) * (3.0 / 8.0) + opp_sum * (1.0 / 8.0)
		else:
			pos = (mesh.vertices[a] + mesh.vertices[b]) * 0.5
		edge_mid[key] = mesh.add_vertex(pos)

	# Reposition existing vertices using Loop's mask (when smoothing).
	if smooth_vertices:
		# Build vertex -> neighbours map from old faces.
		var v_neighbours: Array = []
		v_neighbours.resize(n_old_verts)
		for i in range(n_old_verts):
			v_neighbours[i] = {}
		for f in old_faces:
			var ff: PackedInt32Array = f
			for k in range(3):
				var a: int = ff[k]
				var b: int = ff[(k + 1) % 3]
				if a < n_old_verts:
					(v_neighbours[a] as Dictionary)[b] = true
				if b < n_old_verts:
					(v_neighbours[b] as Dictionary)[a] = true
		var new_positions: Array = []
		new_positions.resize(n_old_verts)
		for i in range(n_old_verts):
			var nbrs: Dictionary = v_neighbours[i]
			var k: int = nbrs.size()
			if k == 0:
				new_positions[i] = mesh.vertices[i]
				continue
			# Loop's beta weight.
			var beta: float
			if k == 3:
				beta = 3.0 / 16.0
			else:
				beta = 3.0 / (8.0 * float(k))
			var nbr_sum := Vector3.ZERO
			for ni in nbrs.keys():
				nbr_sum += mesh.vertices[ni]
			new_positions[i] = mesh.vertices[i] * (1.0 - float(k) * beta) + nbr_sum * beta
		for i in range(n_old_verts):
			mesh.vertices[i] = new_positions[i]

	# Rebuild faces: each old triangle (a, b, c) becomes 4 new triangles
	# using midpoints (ab, bc, ca).
	mesh.faces.clear()
	mesh.face_tags.clear()
	mesh.face_metadata.clear()
	mesh.face_depth.clear()
	for fi in range(old_faces.size()):
		var f: PackedInt32Array = old_faces[fi]
		var a: int = f[0]
		var b: int = f[1]
		var c: int = f[2]
		var ab: int = edge_mid[_edge_key(a, b)]
		var bc: int = edge_mid[_edge_key(b, c)]
		var ca: int = edge_mid[_edge_key(c, a)]
		var src_tags: PackedStringArray = old_face_tags[fi] if fi < old_face_tags.size() else PackedStringArray()
		var src_md: Dictionary = old_face_metadata[fi] if fi < old_face_metadata.size() else {}
		var src_d: int = old_face_depth[fi] if fi < old_face_depth.size() else 0
		# Four sub-triangles.
		_append_sub(mesh, a, ab, ca, src_tags, src_md, src_d)
		_append_sub(mesh, ab, b, bc, src_tags, src_md, src_d)
		_append_sub(mesh, ca, bc, c, src_tags, src_md, src_d)
		_append_sub(mesh, ab, bc, ca, src_tags, src_md, src_d)
	while mesh.vertex_tags.size() < mesh.vertices.size():
		mesh.vertex_tags.append(PackedStringArray())
	mesh._adjacency_dirty = true


func _append_sub(mesh: MeshData, a: int, b: int, c: int,
		src_tags: PackedStringArray, src_md: Dictionary, src_d: int) -> void:
	var fi: int = mesh.faces.size()
	mesh.faces.append(PackedInt32Array([a, b, c]))
	var tags := PackedStringArray()
	for t in src_tags:
		tags.append(String(t))
	mesh.face_tags.append(tags)
	mesh.face_metadata.append(src_md.duplicate(true))
	mesh.face_depth.append(src_d)


static func _edge_key(a: int, b: int) -> String:
	if a < b:
		return "%d_%d" % [a, b]
	return "%d_%d" % [b, a]
