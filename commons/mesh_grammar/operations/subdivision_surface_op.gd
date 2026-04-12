## SubdivisionSurfaceOp — Loop-style subdivision surface.
## Splits each triangle into 4 via edge midpoints, then smooths vertex positions
## by averaging with neighbors. Multiple iterations produce progressively smoother
## surfaces (like Blender's Subdivision Surface modifier).
##
## Params:
##   iterations: int = 1      — number of subdivide+smooth passes
##   smoothing: float = 0.5   — how much to blend toward neighbor average (0=no smooth, 1=full)
##   tag: String = "subdivided"
extends "res://commons/mesh_grammar/mesh_rule.gd"
class_name SubdivisionSurfaceOp


func _execute(mesh, selected: PackedInt32Array) -> void:
	var iterations: int = int(params.get("iterations", 1))
	var smoothing: float = clampf(params.get("smoothing", 0.5), 0.0, 1.0)
	var tag: String = params.get("tag", "subdivided")

	for _iter in iterations:
		# After first iteration, select ALL faces (not just original selection)
		var faces_to_split: PackedInt32Array
		if _iter == 0:
			faces_to_split = selected
		else:
			faces_to_split = PackedInt32Array()
			for fi in mesh.face_count():
				faces_to_split.append(fi)

		# ── Step 1: Midpoint split (same as SplitFaceOp) ───────
		var midpoint_cache: Dictionary = {}

		for face_idx in faces_to_split:
			if face_idx >= mesh.faces.size():
				continue
			var f: PackedInt32Array = mesh.faces[face_idx]
			for ei in range(3):
				var e: Vector2i = _edge_key(f[ei], f[(ei + 1) % 3])
				var key: String = "%d_%d" % [e.x, e.y]
				if not midpoint_cache.has(key):
					var mid: Vector3 = (mesh.vertices[e.x] + mesh.vertices[e.y]) * 0.5
					midpoint_cache[key] = mesh.add_vertex(mid)

		var sorted: Array = Array(faces_to_split)
		sorted.sort()
		sorted.reverse()

		for face_idx in sorted:
			if face_idx >= mesh.faces.size():
				continue
			var f: PackedInt32Array = mesh.faces[face_idx]
			var old_depth: int = 0
			if face_idx < mesh.face_depth.size():
				old_depth = mesh.face_depth[face_idx]

			var e01: Vector2i = _edge_key(f[0], f[1])
			var e12: Vector2i = _edge_key(f[1], f[2])
			var e20: Vector2i = _edge_key(f[2], f[0])
			var m01: int = int(midpoint_cache["%d_%d" % [e01.x, e01.y]])
			var m12: int = int(midpoint_cache["%d_%d" % [e12.x, e12.y]])
			var m20: int = int(midpoint_cache["%d_%d" % [e20.x, e20.y]])

			mesh.remove_faces(PackedInt32Array([face_idx]))

			var t := PackedStringArray([tag])
			mesh.add_face(PackedInt32Array([f[0], m01, m20]), t, old_depth + 1)
			mesh.add_face(PackedInt32Array([m01, f[1], m12]), t, old_depth + 1)
			mesh.add_face(PackedInt32Array([m20, m12, f[2]]), t, old_depth + 1)
			mesh.add_face(PackedInt32Array([m01, m12, m20]), t, old_depth + 1)

		# ── Step 2: Smooth (Laplacian-like vertex averaging) ───
		if smoothing < 0.01:
			continue

		mesh._adjacency_dirty = true
		mesh._ensure_adjacency()

		# Build vertex neighbor map
		var vert_count: int = mesh.vertex_count()
		var new_positions: PackedVector3Array = PackedVector3Array()
		new_positions.resize(vert_count)

		for vi in vert_count:
			var pos: Vector3 = mesh.vertices[vi]
			# Find all neighboring vertices via shared faces
			var neighbor_set: Dictionary = {}
			var v_faces: PackedInt32Array = mesh.get_vertex_faces(vi)
			for fi in v_faces:
				if fi >= mesh.faces.size():
					continue
				var f: PackedInt32Array = mesh.faces[fi]
				for fvi in f:
					if fvi != vi:
						neighbor_set[fvi] = true

			if neighbor_set.is_empty():
				new_positions[vi] = pos
				continue

			# Average neighbor positions
			var avg := Vector3.ZERO
			var count: int = 0
			for nvi in neighbor_set:
				avg += mesh.vertices[nvi]
				count += 1
			avg /= float(count)

			# Blend toward average
			new_positions[vi] = pos.lerp(avg, smoothing)

		# Apply smoothed positions
		for vi in vert_count:
			mesh.vertices[vi] = new_positions[vi]


static func _edge_key(v0: int, v1: int) -> Vector2i:
	return Vector2i(mini(v0, v1), maxi(v0, v1))
