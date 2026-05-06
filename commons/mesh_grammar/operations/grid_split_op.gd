## GridSplitOp — Subdivide selected faces into an m x n grid of sub-quads.
## General-purpose grid subdivision for structured surface decomposition.
## Works on triangular faces by first finding quad pairs, or by splitting
## individual triangles into a grid pattern.
##
## Params:
##   rows: int = 2          — number of vertical divisions
##   cols: int = 2          — number of horizontal divisions
##   tag_prefix: String = "grid"  — tags become "{prefix}_{row}_{col}"
##   row_tags: Array = []   — optional per-row tags (e.g., zone names)
##   col_tags: Array = []   — optional per-col tags (e.g., bay names)
extends MeshRule
class_name GridSplitOp


func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var rows: int = params.get("rows", 2)
	var cols: int = params.get("cols", 2)
	var tag_prefix: String = params.get("tag_prefix", "grid")
	var row_tags: Array = params.get("row_tags", [])
	var col_tags: Array = params.get("col_tags", [])

	if rows < 1 or cols < 1:
		return

	# Process in reverse to avoid index invalidation
	var sorted: Array = Array(selected)
	sorted.sort()
	sorted.reverse()

	for face_idx in sorted:
		if face_idx >= mesh.faces.size():
			continue

		var f := mesh.faces[face_idx]
		if f.size() != 3:
			continue

		var v0: Vector3 = mesh.vertices[f[0]]
		var v1: Vector3 = mesh.vertices[f[1]]
		var v2: Vector3 = mesh.vertices[f[2]]

		var old_depth: int = 0
		if face_idx < mesh.face_depth.size():
			old_depth = mesh.face_depth[face_idx]
		
		# Preserve zone tags from original face
		var inherited_tags := PackedStringArray()
		if face_idx < mesh.face_tags.size():
			for t in mesh.face_tags[face_idx]:
				if t.begins_with("zone_"):
					inherited_tags.append(t)

		# Get face normal for consistent orientation
		var normal := mesh.get_face_normal(face_idx)

		# For a triangle, we create a grid by parameterizing along two edges.
		# Edge0: v0 -> v1 (u axis)
		# Edge1: v0 -> v2 (v axis)
		# This creates a triangular grid, but we fill only the valid triangle region.

		# Create vertex grid (rows+1 x cols+1 within the triangle)
		var vert_indices: Array = []  # [row][col] -> vertex index

		for r in range(rows + 1):
			var row_verts: Array = []
			var t_v: float = float(r) / float(rows)

			for c in range(cols + 1):
				var t_u: float = float(c) / float(cols)

				# Bilinear interpolation within the triangle
				# For rectangular subdivision, we need to define a quad region
				# Use the triangle as a parametric surface: P = v0 + t_u*(v1-v0) + t_v*(v2-v0)
				# But clamp to triangle: t_u + t_v <= 1
				# For facade use, we typically work with quads (pairs of triangles)

				var pos: Vector3
				if t_u + t_v <= 1.0 + 0.001:
					pos = v0 + t_u * (v1 - v0) + t_v * (v2 - v0)
				else:
					# Mirror point for quad completion: v1 + v2 - v0
					var v3 := v1 + v2 - v0
					pos = v3 + (1.0 - t_u) * (v2 - v3) + (1.0 - t_v) * (v1 - v3)

				var vi := mesh.add_vertex(pos)
				row_verts.append(vi)

			vert_indices.append(row_verts)

		# Remove original face
		mesh.remove_faces(PackedInt32Array([face_idx]))

		# Create sub-faces as quads (each split into 2 triangles)
		for r in range(rows):
			for c in range(cols):
				# Skip cells outside the triangle region
				var center_u := (float(c) + 0.5) / float(cols)
				var center_v := (float(r) + 0.5) / float(rows)
				if center_u + center_v > 1.0 + 0.1:
					continue

				var i00: int = vert_indices[r][c]
				var i10: int = vert_indices[r][c + 1]
				var i01: int = vert_indices[r + 1][c]
				var i11: int = vert_indices[r + 1][c + 1]

				# Build tags for this cell (preserving zone tags)
				var cell_tags := PackedStringArray()
				cell_tags.append("%s_%d_%d" % [tag_prefix, r, c])
				cell_tags.append_array(inherited_tags)
				if r < row_tags.size():
					cell_tags.append(str(row_tags[r]))
				if c < col_tags.size():
					cell_tags.append(str(col_tags[c]))

				# Two triangles per quad cell
				mesh.add_face(PackedInt32Array([i00, i10, i11]), cell_tags, old_depth + 1)
				mesh.add_face(PackedInt32Array([i00, i11, i01]), cell_tags, old_depth + 1)


## Create a flat quad seed mesh suitable for grid splitting.
## Returns a MeshData with a single quad (2 triangles) at the given size.
static func create_flat_quad(width: float, height: float) -> MeshData:
	var hw := width / 2.0
	var hh := height / 2.0
	return MeshData.from_arrays(
		[Vector3(-hw, -hh, 0), Vector3(hw, -hh, 0),
		 Vector3(hw, hh, 0), Vector3(-hw, hh, 0)],
		[[0, 1, 2], [0, 2, 3]]
	)


## Create a flat quad seed mesh with explicit corners for facade use.
## Bottom-left at origin, extends right (width) and up (height).
static func create_facade_quad(width: float, height: float) -> MeshData:
	return MeshData.from_arrays(
		[Vector3(0, 0, 0), Vector3(width, 0, 0),
		 Vector3(width, height, 0), Vector3(0, height, 0)],
		[[0, 1, 2], [0, 2, 3]]
	)
