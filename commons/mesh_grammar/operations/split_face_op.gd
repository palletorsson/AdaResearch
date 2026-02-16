## SplitFaceOp — Subdivide selected faces into smaller faces.
## Params:
##   pattern: String = "midpoint"
##     "midpoint" — split triangle into 4 via edge midpoints (Loop-style)
##     "fan"      — split from centroid into 3 triangles
##   center_tag: String = "split_center"
##   corner_tag: String = "split_corner"
extends MeshRule
class_name SplitFaceOp

func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var pattern: String = params.get("pattern", "midpoint")
	var center_tag: String = params.get("center_tag", "split_center")
	var corner_tag: String = params.get("corner_tag", "split_corner")

	match pattern:
		"midpoint":
			_split_midpoint(mesh, selected, center_tag, corner_tag)
		"fan":
			_split_fan(mesh, selected, center_tag)
		_:
			_split_midpoint(mesh, selected, center_tag, corner_tag)

func _split_midpoint(mesh: MeshData, selected: PackedInt32Array,
		center_tag: String, corner_tag: String) -> void:
	# Cache midpoint vertices to share across adjacent faces
	var midpoint_cache: Dictionary = {}  # "min_max" -> vertex index

	# First pass: create all midpoints
	for face_idx in selected:
		if face_idx >= mesh.faces.size():
			continue
		var f := mesh.faces[face_idx]
		for ei in range(3):
			var e := MeshData._edge_key(f[ei], f[(ei + 1) % 3])
			var key := "%d_%d" % [e.x, e.y]
			if not midpoint_cache.has(key):
				var mid: Vector3 = (mesh.vertices[e.x] + mesh.vertices[e.y]) * 0.5
				midpoint_cache[key] = mesh.add_vertex(mid)

	# Second pass: replace faces (reverse order)
	var sorted: Array = Array(selected)
	sorted.sort()
	sorted.reverse()

	for face_idx in sorted:
		if face_idx >= mesh.faces.size():
			continue
		var f := mesh.faces[face_idx]
		var old_depth: int = 0
		if face_idx < mesh.face_depth.size():
			old_depth = mesh.face_depth[face_idx]

		# Get midpoint indices
		var e01 := MeshData._edge_key(f[0], f[1])
		var e12 := MeshData._edge_key(f[1], f[2])
		var e20 := MeshData._edge_key(f[2], f[0])
		var m01: int = midpoint_cache["%d_%d" % [e01.x, e01.y]]
		var m12: int = midpoint_cache["%d_%d" % [e12.x, e12.y]]
		var m20: int = midpoint_cache["%d_%d" % [e20.x, e20.y]]

		# Remove original face
		mesh.remove_faces(PackedInt32Array([face_idx]))

		# 3 corner triangles
		mesh.add_face(PackedInt32Array([f[0], m01, m20]),
			PackedStringArray([corner_tag]), old_depth + 1)
		mesh.add_face(PackedInt32Array([m01, f[1], m12]),
			PackedStringArray([corner_tag]), old_depth + 1)
		mesh.add_face(PackedInt32Array([m20, m12, f[2]]),
			PackedStringArray([corner_tag]), old_depth + 1)

		# 1 center triangle
		mesh.add_face(PackedInt32Array([m01, m12, m20]),
			PackedStringArray([center_tag]), old_depth + 1)

func _split_fan(mesh: MeshData, selected: PackedInt32Array,
		center_tag: String) -> void:
	var sorted: Array = Array(selected)
	sorted.sort()
	sorted.reverse()

	for face_idx in sorted:
		if face_idx >= mesh.faces.size():
			continue
		var f := mesh.faces[face_idx]
		var centroid := mesh.get_face_centroid(face_idx)
		var old_depth: int = 0
		if face_idx < mesh.face_depth.size():
			old_depth = mesh.face_depth[face_idx]

		var ci := mesh.add_vertex(centroid)

		mesh.remove_faces(PackedInt32Array([face_idx]))

		# 3 fan triangles
		for ei in range(3):
			mesh.add_face(
				PackedInt32Array([f[ei], f[(ei + 1) % 3], ci]),
				PackedStringArray([center_tag]), old_depth + 1)
