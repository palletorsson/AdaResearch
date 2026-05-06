## TubeBranchOp — Grow a cylindrical tube from a face outward along its normal.
## Creates coral fingers, tentacles, tree branches.
## Inspired by: coral ceramic sculptures, LEGO botanical stems.
## Params:
##   length: float = 0.5         — tube length
##   start_radius: float = -1.0  — tube radius at base (-1 = auto from face size)
##   end_radius: float = -1.0    — tube radius at tip (-1 = start_radius * 0.7)
##   segments: int = 6           — tube cross-section segments
##   rings: int = 4              — tube length subdivisions
##   curve_amount: float = 0.0   — random curve offset (0 = straight)
##   twist: float = 0.0          — twist in radians along length
##   tip_tag: String = "branch_tip"
##   stem_tag: String = "branch_stem"
extends MeshRule
class_name TubeBranchOp

func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var length: float = params.get("length", 0.5)
	var start_radius: float = params.get("start_radius", -1.0)
	var end_radius: float = params.get("end_radius", -1.0)
	var seg: int = params.get("segments", 6)
	var rings: int = params.get("rings", 4)
	var curve_amount: float = params.get("curve_amount", 0.0)
	var twist: float = params.get("twist", 0.0)
	var tip_tag: String = params.get("tip_tag", "branch_tip")
	var stem_tag: String = params.get("stem_tag", "branch_stem")

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# Process in reverse to avoid index invalidation during face removal
	var sorted: Array = Array(selected)
	sorted.sort()
	sorted.reverse()

	for face_idx in sorted:
		if face_idx >= mesh.faces.size():
			continue

		var f := mesh.faces[face_idx]
		var normal := mesh.get_face_normal(face_idx)
		var centroid := mesh.get_face_centroid(face_idx)
		var area := mesh.get_face_area(face_idx)
		var old_depth: int = 0
		if face_idx < mesh.face_depth.size():
			old_depth = mesh.face_depth[face_idx]

		# Auto-compute radius from face area
		var r_start := start_radius
		if r_start < 0:
			r_start = sqrt(area / PI) * 0.8
		var r_end := end_radius
		if r_end < 0:
			r_end = r_start * 0.7

		# Build a coordinate frame from the normal
		var up := normal.normalized()
		var right: Vector3
		if abs(up.dot(Vector3.UP)) < 0.99:
			right = up.cross(Vector3.UP).normalized()
		else:
			right = up.cross(Vector3.RIGHT).normalized()
		var forward := right.cross(up).normalized()

		# Generate curve offset for organic look
		var curve_offset := Vector3.ZERO
		if curve_amount > 0:
			curve_offset = (right * rng.randf_range(-1.0, 1.0) +
				forward * rng.randf_range(-1.0, 1.0)).normalized() * curve_amount

		# Remove original face
		mesh.remove_faces(PackedInt32Array([face_idx]))

		# Generate tube rings
		var ring_verts: Array[PackedInt32Array] = []
		for ri in range(rings + 1):
			var t := float(ri) / float(rings)
			var radius := lerpf(r_start, r_end, t)
			var center := centroid + up * length * t + curve_offset * t * t
			var twist_angle := twist * t

			var ring := PackedInt32Array()
			for si in range(seg):
				var angle := TAU * float(si) / float(seg) + twist_angle
				var offset := (right * cos(angle) + forward * sin(angle)) * radius
				var vi := mesh.add_vertex(center + offset)
				ring.append(vi)
			ring_verts.append(ring)

		# Connect rings with faces
		for ri in range(rings):
			var r0 := ring_verts[ri]
			var r1 := ring_verts[ri + 1]
			for si in range(seg):
				var s_next := (si + 1) % seg
				# Quad as 2 triangles
				mesh.add_face(
					PackedInt32Array([r0[si], r0[s_next], r1[s_next]]),
					PackedStringArray([stem_tag]), old_depth + 1)
				mesh.add_face(
					PackedInt32Array([r0[si], r1[s_next], r1[si]]),
					PackedStringArray([stem_tag]), old_depth + 1)

		# Cap the tip with a fan of triangles
		var tip_ring := ring_verts[rings]
		var tip_center := centroid + up * length + curve_offset
		var tip_vi := mesh.add_vertex(tip_center)
		for si in range(seg):
			var s_next := (si + 1) % seg
			mesh.add_face(
				PackedInt32Array([tip_ring[si], tip_ring[s_next], tip_vi]),
				PackedStringArray([tip_tag]), old_depth + 1)

		# Optionally connect base ring to original face edges
		# For now, the base ring sits at the face centroid position
		# which creates a smooth join with the parent surface

	mesh._adjacency_dirty = true
