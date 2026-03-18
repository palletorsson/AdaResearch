## InsetFaceOp — Shrink a face inward, creating a border ring.
## The original face is replaced by a smaller inner face + 3 border quads.
## Params:
##   amount: float = 0.3         — fraction toward centroid (0=no inset, 1=point)
##   inner_tag: String = "inset"
##   border_tag: String = "inset_border"
extends MeshRule
class_name InsetFaceOp

func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var amount: float = clampf(params.get("amount", 0.3), 0.01, 0.99)
	var inner_tag: String = params.get("inner_tag", "inset")
	var border_tag: String = params.get("border_tag", "inset_border")

	var sorted: Array = Array(selected)
	sorted.sort()
	sorted.reverse()

	for face_idx in sorted:
		if face_idx >= mesh.faces.size():
			continue

		var f := mesh.faces[face_idx]
		var v0: Vector3 = mesh.vertices[f[0]]
		var v1: Vector3 = mesh.vertices[f[1]]
		var v2: Vector3 = mesh.vertices[f[2]]
		var centroid := (v0 + v1 + v2) / 3.0
		var old_depth: int = 0
		if face_idx < mesh.face_depth.size():
			old_depth = mesh.face_depth[face_idx]
		
		# Preserve zone tags from original face
		var inherited_tags := PackedStringArray()
		if face_idx < mesh.face_tags.size():
			for t in mesh.face_tags[face_idx]:
				if t.begins_with("zone_"):
					inherited_tags.append(t)

		# Inner vertices (lerp toward centroid)
		var iv0 := v0.lerp(centroid, amount)
		var iv1 := v1.lerp(centroid, amount)
		var iv2 := v2.lerp(centroid, amount)

		var ni0 := mesh.add_vertex(iv0)
		var ni1 := mesh.add_vertex(iv1)
		var ni2 := mesh.add_vertex(iv2)

		# Remove original
		mesh.remove_faces(PackedInt32Array([face_idx]))

		# Build tags with zone inheritance
		var inner_tags := PackedStringArray([inner_tag])
		inner_tags.append_array(inherited_tags)
		var border_tags := PackedStringArray([border_tag])
		border_tags.append_array(inherited_tags)

		# Inner face
		mesh.add_face(PackedInt32Array([ni0, ni1, ni2]),
			inner_tags, old_depth + 1)

		# 3 border quads (each as 2 tris)
		_add_border_quad(mesh, f[0], f[1], ni1, ni0, border_tags, old_depth + 1)
		_add_border_quad(mesh, f[1], f[2], ni2, ni1, border_tags, old_depth + 1)
		_add_border_quad(mesh, f[2], f[0], ni0, ni2, border_tags, old_depth + 1)

func _add_border_quad(mesh: MeshData, a: int, b: int, c: int, d: int,
		tags, depth: int) -> void:
	var tag_array: PackedStringArray
	if tags is String:
		tag_array = PackedStringArray([tags])
	else:
		tag_array = tags
	mesh.add_face(PackedInt32Array([a, b, c]), tag_array, depth)
	mesh.add_face(PackedInt32Array([a, c, d]), tag_array, depth)
