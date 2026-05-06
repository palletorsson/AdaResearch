## BulgeOp — Soft organic extrusion that pushes a face cluster outward
## with smooth blending to neighbors. Creates dome/nodule shapes.
## Inspired by: ceramic nodule spheres, budding growths.
## Params:
##   height: float = 0.3       — how far the center bulges outward
##   ring_depth: int = 1       — how many neighbor rings to include in smoothing
##   smoothing: float = 0.7    — falloff factor per ring (0=sharp, 1=full)
##   top_tag: String = "bulge_tip"
##   body_tag: String = "bulge_body"
extends MeshRule
class_name BulgeOp

func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var height: float = params.get("height", 0.3)
	var ring_depth: int = params.get("ring_depth", 1)
	var smoothing: float = clampf(params.get("smoothing", 0.7), 0.0, 1.0)
	var top_tag: String = params.get("top_tag", "bulge_tip")
	var body_tag: String = params.get("body_tag", "bulge_body")

	# For each selected face, gather its N-ring neighborhood and
	# displace vertices with distance-based falloff.
	# Track which vertices have already been displaced to handle overlapping bulges.
	var displaced: Dictionary = {}  # vert_idx -> accumulated displacement

	for face_idx in selected:
		if face_idx >= mesh.faces.size():
			continue

		var center_normal := mesh.get_face_normal(face_idx)
		var center_centroid := mesh.get_face_centroid(face_idx)

		# Gather ring neighborhood
		var ring := mesh.get_face_ring(face_idx, ring_depth)

		# Collect all unique vertices in the ring, with their ring distance
		var vert_ring_dist: Dictionary = {}  # vert_idx -> min ring distance (0 = center face)

		# Center face vertices get distance 0
		var center_face := mesh.faces[face_idx]
		for vi in center_face:
			vert_ring_dist[vi] = 0

		# BFS to assign ring distances to vertices
		if ring_depth > 0:
			var face_dist: Dictionary = {face_idx: 0}
			var frontier: PackedInt32Array = PackedInt32Array([face_idx])
			for d in range(ring_depth):
				var next_frontier: PackedInt32Array = PackedInt32Array()
				for fi in frontier:
					for neighbor in mesh.get_face_neighbors(fi):
						if not face_dist.has(neighbor):
							face_dist[neighbor] = d + 1
							next_frontier.append(neighbor)
							# Assign vertex distances
							var nf := mesh.faces[neighbor]
							for vi in nf:
								if not vert_ring_dist.has(vi):
									vert_ring_dist[vi] = d + 1
								else:
									vert_ring_dist[vi] = mini(vert_ring_dist[vi], d + 1)
				frontier = next_frontier

		# Displace vertices with falloff
		var max_dist := ring_depth + 1  # +1 to avoid div by zero
		for vi in vert_ring_dist:
			var dist: int = vert_ring_dist[vi]
			# Falloff: center = full height, outer ring = smoothing^dist
			var factor: float = pow(smoothing, float(dist))
			var displacement: Vector3 = center_normal * height * factor

			if displaced.has(vi):
				# Blend with existing displacement (take max magnitude)
				var existing: Vector3 = displaced[vi]
				if displacement.length() > existing.length():
					displaced[vi] = displacement
			else:
				displaced[vi] = displacement

		# Tag faces
		mesh.tag_face(face_idx, top_tag)
		for fi in ring:
			if fi != face_idx:
				mesh.tag_face(fi, body_tag)

	# Apply all displacements
	for vi in displaced:
		if vi >= 0 and vi < mesh.vertices.size():
			mesh.vertices[vi] += displaced[vi]

	mesh._adjacency_dirty = true
