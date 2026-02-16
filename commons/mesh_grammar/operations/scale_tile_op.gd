## ScaleTileOp — Place overlapping scale/leaf shapes on selected faces.
## Creates pinecone, artichoke, dragon-scale textures.
## Inspired by: thistle pod ceramics, artichoke structures.
## Each selected face gets a thin quad tilted outward like a scale.
## Params:
##   scale_length: float = 0.12   — length of each scale
##   scale_width: float = 0.08    — width of each scale
##   tilt_degrees: float = 30.0   — outward tilt angle from surface
##   overlap: float = 0.3         — how much scales overlap (0 = none, 1 = full)
##   pointed: bool = true         — if true, scales taper to a point (triangle); else quad
##   scale_tag: String = "scale"
extends MeshRule
class_name ScaleTileOp

func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var scale_length: float = params.get("scale_length", 0.12)
	var scale_width: float = params.get("scale_width", 0.08)
	var tilt_deg: float = params.get("tilt_degrees", 30.0)
	var overlap: float = params.get("overlap", 0.3)
	var pointed: bool = params.get("pointed", true)
	var scale_tag: String = params.get("scale_tag", "scale")

	var tilt_rad: float = deg_to_rad(tilt_deg)

	for face_idx in selected:
		if face_idx >= mesh.faces.size():
			continue

		var normal := mesh.get_face_normal(face_idx)
		var centroid := mesh.get_face_centroid(face_idx)
		var old_depth: int = 0
		if face_idx < mesh.face_depth.size():
			old_depth = mesh.face_depth[face_idx]

		# Radial direction: from mesh center outward through this face
		var mesh_center := mesh.get_bounding_box().get_center()
		var radial := (centroid - mesh_center)
		if radial.length_squared() < 0.001:
			radial = normal
		radial = radial.normalized()

		# "Up" direction on the surface — project radial onto face plane
		var face_up := (radial - normal * radial.dot(normal))
		if face_up.length_squared() < 0.001:
			# Fallback: use any tangent
			if abs(normal.dot(Vector3.UP)) < 0.99:
				face_up = Vector3.UP - normal * normal.dot(Vector3.UP)
			else:
				face_up = Vector3.FORWARD - normal * normal.dot(Vector3.FORWARD)
		face_up = face_up.normalized()
		var face_right := normal.cross(face_up).normalized()

		# Scale base sits on the face, tip tilts outward along normal
		var tilt_dir := (face_up * cos(tilt_rad) + normal * sin(tilt_rad)).normalized()

		# Base position (shifted slightly inward for overlap)
		var base_pos := centroid - face_up * scale_length * overlap * 0.5

		# Create the scale geometry
		var half_w := scale_width * 0.5
		var bl := mesh.add_vertex(base_pos - face_right * half_w)
		var br := mesh.add_vertex(base_pos + face_right * half_w)

		if pointed:
			# Pointed scale: triangle
			var tip := mesh.add_vertex(base_pos + tilt_dir * scale_length)
			mesh.add_face(PackedInt32Array([bl, br, tip]),
				PackedStringArray([scale_tag]), old_depth + 1)
		else:
			# Quad scale: rectangle tilted outward
			var tip_pos := base_pos + tilt_dir * scale_length
			var tl := mesh.add_vertex(tip_pos - face_right * half_w * 0.6)
			var tr := mesh.add_vertex(tip_pos + face_right * half_w * 0.6)
			mesh.add_face(PackedInt32Array([bl, br, tr]),
				PackedStringArray([scale_tag]), old_depth + 1)
			mesh.add_face(PackedInt32Array([bl, tr, tl]),
				PackedStringArray([scale_tag]), old_depth + 1)

	mesh._adjacency_dirty = true
