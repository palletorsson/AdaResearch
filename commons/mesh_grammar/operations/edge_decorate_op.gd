## EdgeDecorateOp — Place small sub-meshes (spheres, caps, rivets) along edges.
## Creates riveted vessel edges, coral tip beads, scallop bolts.
## Inspired by: riveted copper vessel, coral finger tips.
## Params:
##   shape: String = "sphere"    — "sphere", "cap", "cube"
##   size: float = 0.03          — radius/size of each decoration
##   spacing: float = 0.1        — distance between decorations along edge
##   offset: float = 0.0         — outward offset from edge (along face normal)
##   segments: int = 6           — sphere/cap resolution
##   boundary_only: bool = true  — only decorate boundary edges (mesh edges with 1 face)
##   decor_tag: String = "decor"
extends MeshRule
class_name EdgeDecorateOp

func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var shape: String = params.get("shape", "sphere")
	var size: float = params.get("size", 0.03)
	var edge_spacing: float = params.get("spacing", 0.1)
	var offset: float = params.get("offset", 0.0)
	var seg: int = params.get("segments", 6)
	var boundary_only: bool = params.get("boundary_only", true)
	var decor_tag: String = params.get("decor_tag", "decor")

	# Collect edges from selected faces
	var edges_to_decorate: Dictionary = {}  # edge_key -> {"pos_a": Vector3, "pos_b": Vector3, "normal": Vector3}

	for face_idx in selected:
		if face_idx >= mesh.faces.size():
			continue
		var face_normal := mesh.get_face_normal(face_idx)
		var edges := mesh.get_face_edges(face_idx)
		for edge in edges:
			if boundary_only:
				var ef := mesh.get_edge_faces(edge)
				if ef.size() != 1:
					continue
			var key := "%d_%d" % [edge.x, edge.y]
			if not edges_to_decorate.has(key):
				edges_to_decorate[key] = {
					"pos_a": mesh.vertices[edge.x],
					"pos_b": mesh.vertices[edge.y],
					"normal": face_normal
				}

	# Place decorations along each edge
	for key in edges_to_decorate:
		var edge_data: Dictionary = edges_to_decorate[key]
		var a: Vector3 = edge_data["pos_a"]
		var b: Vector3 = edge_data["pos_b"]
		var normal: Vector3 = edge_data["normal"]
		var edge_length := a.distance_to(b)

		if edge_length < 0.001:
			continue

		var count := maxi(1, int(edge_length / edge_spacing))
		for i in range(count + 1):
			var t: float = float(i) / float(count)
			var pos: Vector3 = a.lerp(b, t) + normal * offset

			match shape:
				"sphere":
					_add_icosphere(mesh, pos, size, seg, decor_tag)
				"cap":
					_add_hemisphere(mesh, pos, size, normal, seg, decor_tag)
				"cube":
					_add_cube(mesh, pos, size, decor_tag)
				_:
					_add_icosphere(mesh, pos, size, seg, decor_tag)

	mesh._adjacency_dirty = true

func _add_icosphere(mesh: MeshData, center: Vector3, radius: float,
		segments: int, tag: String) -> void:
	# Simple UV sphere
	var rings := segments
	var segs := segments * 2
	var ring_verts: Array[PackedInt32Array] = []

	for i in range(rings + 1):
		var phi: float = PI * float(i) / float(rings)
		var ring := PackedInt32Array()
		for j in range(segs):
			var theta: float = TAU * float(j) / float(segs)
			var x := radius * sin(phi) * cos(theta)
			var y := radius * cos(phi)
			var z := radius * sin(phi) * sin(theta)
			ring.append(mesh.add_vertex(center + Vector3(x, y, z)))
		ring_verts.append(ring)

	for i in range(rings):
		for j in range(segs):
			var j_next := (j + 1) % segs
			if i > 0:
				mesh.add_face(
					PackedInt32Array([ring_verts[i][j], ring_verts[i + 1][j], ring_verts[i][j_next]]),
					PackedStringArray([tag]))
			if i < rings - 1:
				mesh.add_face(
					PackedInt32Array([ring_verts[i][j_next], ring_verts[i + 1][j], ring_verts[i + 1][j_next]]),
					PackedStringArray([tag]))

func _add_hemisphere(mesh: MeshData, center: Vector3, radius: float,
		up: Vector3, segments: int, tag: String) -> void:
	var right: Vector3
	if abs(up.dot(Vector3.UP)) < 0.99:
		right = up.cross(Vector3.UP).normalized()
	else:
		right = up.cross(Vector3.RIGHT).normalized()
	var forward := right.cross(up).normalized()

	var rings := segments / 2 + 1
	var segs := segments * 2
	var ring_verts: Array[PackedInt32Array] = []

	for i in range(rings + 1):
		var phi: float = (PI * 0.5) * float(i) / float(rings)  # 0 to PI/2
		var ring := PackedInt32Array()
		for j in range(segs):
			var theta: float = TAU * float(j) / float(segs)
			var r := radius * cos(phi)
			var h := radius * sin(phi)
			var pos := center + (right * cos(theta) + forward * sin(theta)) * r + up * h
			ring.append(mesh.add_vertex(pos))
		ring_verts.append(ring)

	for i in range(rings):
		for j in range(segs):
			var j_next := (j + 1) % segs
			mesh.add_face(
				PackedInt32Array([ring_verts[i][j], ring_verts[i + 1][j], ring_verts[i][j_next]]),
				PackedStringArray([tag]))
			if i < rings - 1:
				mesh.add_face(
					PackedInt32Array([ring_verts[i][j_next], ring_verts[i + 1][j], ring_verts[i + 1][j_next]]),
					PackedStringArray([tag]))

func _add_cube(mesh: MeshData, center: Vector3, size: float, tag: String) -> void:
	var s := size * 0.5
	var v := [
		mesh.add_vertex(center + Vector3(-s, -s, s)),
		mesh.add_vertex(center + Vector3(s, -s, s)),
		mesh.add_vertex(center + Vector3(s, s, s)),
		mesh.add_vertex(center + Vector3(-s, s, s)),
		mesh.add_vertex(center + Vector3(-s, -s, -s)),
		mesh.add_vertex(center + Vector3(s, -s, -s)),
		mesh.add_vertex(center + Vector3(s, s, -s)),
		mesh.add_vertex(center + Vector3(-s, s, -s)),
	]
	var cube_faces := [
		[v[0],v[1],v[2]], [v[0],v[2],v[3]],
		[v[5],v[4],v[7]], [v[5],v[7],v[6]],
		[v[4],v[0],v[3]], [v[4],v[3],v[7]],
		[v[1],v[5],v[6]], [v[1],v[6],v[2]],
		[v[3],v[2],v[6]], [v[3],v[6],v[7]],
		[v[4],v[5],v[1]], [v[4],v[1],v[0]],
	]
	for f in cube_faces:
		mesh.add_face(PackedInt32Array(f), PackedStringArray([tag]))
