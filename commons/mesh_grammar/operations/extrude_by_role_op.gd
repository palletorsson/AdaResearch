## ExtrudeByRoleOp — Extrude faces with role-specific distance / scale.
##
## First MORPHOLOGY op in the unified vocabulary. Where ExtrudeFaceOp pushes
## all selected faces uniformly, this one looks up each face's tag against
## a per-role config dict and extrudes accordingly. Petals splay outward
## with positive distance and scale > 1. Stamens spike up with large
## distance and scale << 1. Sepals curl in with negative distance.
## Pistil domes by extruding with scale just below 1.
##
## Tag prefix is configurable so this works for flower / insect / bird
## grammars (or any other tag-prefixed system).
##
## Internally calls the same per-face logic as ExtrudeFaceOp but with
## role-derived params. Faces that don't match any role pass through.
##
## Params:
##   role_params: Dictionary{role_name -> {distance, scale, top_tag, side_tag}}
##     e.g. {"flower_petal": {"distance": 0.35, "scale": 1.15},
##           "flower_stamen": {"distance": 0.9, "scale": 0.25},
##           "flower_pistil": {"distance": 0.3, "scale": 0.9},
##           "flower_sepal": {"distance": -0.15, "scale": 0.95}}
##   tag_prefix: String = ""
##     If set, role keys are matched without the prefix.
##   default: Dictionary (optional)
##     Params for faces with no matching role. If omitted, faces pass through.
extends MeshRule
class_name ExtrudeByRoleOp


func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var role_params: Dictionary = params.get("role_params", {})
	var tag_prefix: String = String(params.get("tag_prefix", ""))
	var default_params: Variant = params.get("default", null)
	var min_area: float = params.get("min_area", 0.001)

	# Process in reverse so face index changes don't invalidate later picks.
	var sorted: Array = Array(selected)
	sorted.sort()
	sorted.reverse()

	for face_idx in sorted:
		if face_idx >= mesh.faces.size():
			continue
		# Find the matching role for this face.
		var role_key: String = ""
		if face_idx < mesh.face_tags.size():
			for raw_tag in mesh.face_tags[face_idx]:
				var tag := String(raw_tag)
				var key := tag if tag_prefix.is_empty() else (
					tag.substr(tag_prefix.length()) if tag.begins_with(tag_prefix) else "")
				if key.is_empty():
					continue
				if role_params.has(key):
					role_key = key
					break
				if role_params.has(tag):
					role_key = tag
					break
		var p: Dictionary = {}
		if not role_key.is_empty():
			p = role_params[role_key]
		elif default_params is Dictionary:
			p = default_params
		else:
			continue  # no role, no default — pass through
		_extrude_one_face(mesh, face_idx, p, min_area, role_key)


# Per-face extrude logic. Lifted from ExtrudeFaceOp but with role-tagged
# outputs so downstream paint_by_tag / hide_by_rule see the new top + side
# faces with names like "flower_petal_top" / "flower_petal_side".
func _extrude_one_face(mesh: MeshData, face_idx: int, p: Dictionary,
		min_area: float, role_key: String) -> void:
	var distance: float = float(p.get("distance", 0.4))
	var scale_factor: float = float(p.get("scale", 1.0))
	var top_tag: String = String(p.get("top_tag",
		(role_key + "_top") if not role_key.is_empty() else "extruded_top"))
	var side_tag: String = String(p.get("side_tag",
		(role_key + "_side") if not role_key.is_empty() else "extruded_side"))

	var f := mesh.faces[face_idx]
	var v0: Vector3 = mesh.vertices[f[0]]
	var v1: Vector3 = mesh.vertices[f[1]]
	var v2: Vector3 = mesh.vertices[f[2]]
	var normal := (v1 - v0).cross(v2 - v0)
	var area2: float = normal.length()
	if area2 < min_area:
		return
	normal = normal / area2

	var centroid := (v0 + v1 + v2) / 3.0
	var top_v0: Vector3 = centroid.lerp(v0, scale_factor) + normal * distance
	var top_v1: Vector3 = centroid.lerp(v1, scale_factor) + normal * distance
	var top_v2: Vector3 = centroid.lerp(v2, scale_factor) + normal * distance

	var inherited_color: Variant = null
	if face_idx < mesh.face_metadata.size():
		var md: Dictionary = mesh.face_metadata[face_idx]
		if md.has("color"):
			inherited_color = md["color"]

	var inherited_role_tag: String = ""
	if face_idx < mesh.face_tags.size():
		for raw_tag in mesh.face_tags[face_idx]:
			var tag := String(raw_tag)
			if not role_key.is_empty() and (tag == role_key or tag.ends_with(role_key)):
				inherited_role_tag = tag
				break

	var ti0 := mesh.add_vertex(top_v0)
	var ti1 := mesh.add_vertex(top_v1)
	var ti2 := mesh.add_vertex(top_v2)

	# Remove original face.
	mesh.remove_faces(PackedInt32Array([face_idx]))

	# Top face.
	var top_idx: int = mesh.faces.size()
	mesh.faces.append(PackedInt32Array([ti0, ti1, ti2]))
	_extend_metadata(mesh, top_idx)
	mesh.face_tags[top_idx].append(top_tag)
	if not inherited_role_tag.is_empty():
		mesh.face_tags[top_idx].append(inherited_role_tag)
	if inherited_color != null:
		mesh.face_metadata[top_idx]["color"] = inherited_color
		mesh.face_metadata[top_idx]["painted"] = true

	# Side faces (one quad = 2 triangles per edge).
	_add_side_quad(mesh, f[0], f[1], ti0, ti1, side_tag, inherited_role_tag, inherited_color)
	_add_side_quad(mesh, f[1], f[2], ti1, ti2, side_tag, inherited_role_tag, inherited_color)
	_add_side_quad(mesh, f[2], f[0], ti2, ti0, side_tag, inherited_role_tag, inherited_color)


func _add_side_quad(mesh: MeshData, b0: int, b1: int, t0: int, t1: int,
		side_tag: String, role_tag: String, color: Variant) -> void:
	# Two triangles forming the side wall between (b0,b1) and (t0,t1).
	var i0: int = mesh.faces.size()
	mesh.faces.append(PackedInt32Array([b0, b1, t1]))
	_extend_metadata(mesh, i0)
	mesh.face_tags[i0].append(side_tag)
	if not role_tag.is_empty():
		mesh.face_tags[i0].append(role_tag)
	if color != null:
		mesh.face_metadata[i0]["color"] = color
		mesh.face_metadata[i0]["painted"] = true

	var i1: int = mesh.faces.size()
	mesh.faces.append(PackedInt32Array([b0, t1, t0]))
	_extend_metadata(mesh, i1)
	mesh.face_tags[i1].append(side_tag)
	if not role_tag.is_empty():
		mesh.face_tags[i1].append(role_tag)
	if color != null:
		mesh.face_metadata[i1]["color"] = color
		mesh.face_metadata[i1]["painted"] = true


func _extend_metadata(mesh: MeshData, face_idx: int) -> void:
	while mesh.face_tags.size() <= face_idx:
		mesh.face_tags.append(PackedStringArray())
	while mesh.face_metadata.size() <= face_idx:
		mesh.face_metadata.append({})
	while mesh.face_depth.size() <= face_idx:
		mesh.face_depth.append(0)
