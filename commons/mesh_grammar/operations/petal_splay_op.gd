## PetalSplayOp — Generate curved petal surfaces radiating outward from a face.
## Creates flowers, rosettes, anemone forms.
## Inspired by: Marie Fernström orange flowers, LEGO botanical petals.
## Params:
##   count: int = 5            — number of petals
##   length: float = 0.3       — petal length
##   width: float = 0.15       — petal width at base
##   curl: float = 0.3         — backward curl (0 = flat, 1 = strong curl back)
##   twist: float = 0.0        — twist along petal length (radians)
##   thickness: float = 0.01   — petal surface thickness (slight offset for double-sided look)
##   tilt: float = 0.3         — how much petals tilt outward from normal (0 = straight up, 1 = flat)
##   segments: int = 4         — length subdivisions for smooth curl
##   petal_tag: String = "petal"
##   center_tag: String = "petal_center"
extends MeshRule
class_name PetalSplayOp

func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var count: int = params.get("count", 5)
	var length: float = params.get("length", 0.3)
	var width: float = params.get("width", 0.15)
	var curl: float = params.get("curl", 0.3)
	var twist_amount: float = params.get("twist", 0.0)
	var tilt: float = clampf(params.get("tilt", 0.3), 0.0, 1.0)
	var seg: int = params.get("segments", 4)
	var petal_tag: String = params.get("petal_tag", "petal")
	var center_tag: String = params.get("center_tag", "petal_center")

	for face_idx in selected:
		if face_idx >= mesh.faces.size():
			continue

		var normal := mesh.get_face_normal(face_idx)
		var centroid := mesh.get_face_centroid(face_idx)
		var old_depth: int = 0
		if face_idx < mesh.face_depth.size():
			old_depth = mesh.face_depth[face_idx]

		# Build coordinate frame
		var up := normal.normalized()
		var right: Vector3
		if abs(up.dot(Vector3.UP)) < 0.99:
			right = up.cross(Vector3.UP).normalized()
		else:
			right = up.cross(Vector3.RIGHT).normalized()
		var forward := right.cross(up).normalized()

		# Tag the source face as center
		mesh.tag_face(face_idx, center_tag)

		# Generate petals around the face
		for pi in range(count):
			var angle: float = TAU * float(pi) / float(count)

			# Petal direction (radial outward from center, tilted between normal and outward)
			var radial := (right * cos(angle) + forward * sin(angle)).normalized()
			var petal_up := up.lerp(radial, tilt).normalized()
			var petal_right := petal_up.cross(radial).normalized()
			if petal_right.length_squared() < 0.01:
				petal_right = forward

			# Generate petal strip: rows of vertex pairs along the length
			var left_verts: PackedInt32Array = PackedInt32Array()
			var right_verts: PackedInt32Array = PackedInt32Array()

			for si in range(seg + 1):
				var t: float = float(si) / float(seg)

				# Position along petal length with curl
				var curl_angle: float = curl * PI * t * t  # Quadratic curl (more at tip)
				var along: Vector3 = radial * cos(curl_angle) + petal_up * sin(curl_angle)
				var center_pos: Vector3 = centroid + along * length * t

				# Width tapers: widest at ~30%, narrows to tip
				var w: float = width * sin(PI * t) if t > 0.0 else width * 0.3
				# Slight twist
				var twist_angle: float = twist_amount * t
				var side: Vector3 = (petal_right * cos(twist_angle) + petal_up.cross(petal_right).normalized() * sin(twist_angle)) if twist_amount != 0.0 else petal_right

				var left_pos := center_pos - side * w * 0.5
				var right_pos := center_pos + side * w * 0.5

				left_verts.append(mesh.add_vertex(left_pos))
				right_verts.append(mesh.add_vertex(right_pos))

			# Connect into triangle strip
			for si in range(seg):
				# Quad: left[si], right[si], right[si+1], left[si+1]
				mesh.add_face(
					PackedInt32Array([left_verts[si], right_verts[si], right_verts[si + 1]]),
					PackedStringArray([petal_tag]), old_depth + 1)
				mesh.add_face(
					PackedInt32Array([left_verts[si], right_verts[si + 1], left_verts[si + 1]]),
					PackedStringArray([petal_tag]), old_depth + 1)

	mesh._adjacency_dirty = true
