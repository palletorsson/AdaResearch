## MarkBillboardAnchorsOp — Emit a 2-triangle alpha-billboard quad per
## tagged role, instead of stamping a full primitive mesh.
##
## The compute-budget version of replace_with_mesh_by_role. Where that op
## bakes 12-50 triangles per stamp (full leaf/diamond/sphere primitive),
## this one bakes a single 2-triangle quad and records the billboard
## metadata (atlas tile, tilt, color) in face_metadata. A runtime
## collector reads those records, builds a MultiMesh, and submits the
## whole population in one draw call.
##
## Cost comparison for 12 stamps:
##   replace_with_mesh_by_role + leaf primitive: ~240 triangles, painted per face
##   mark_billboard_anchors:                       24 triangles, alpha-masked in shader
##
## The quads are oriented:
##   - Local Y axis = role's outward+up direction (same align_radial logic
##     as replace_with_mesh_by_role) so a butterfly wing or flower petal
##     billboard reads correctly from a typical camera angle.
##   - Local X = tangent in the plane perpendicular to the up vector.
##
## Each generated face carries metadata so the runtime collector can find
## it later:
##   face_metadata[fi]["billboard"] = {
##     "atlas": String,      # billboard atlas resource path
##     "tile":  int,          # which atlas tile to sample
##     "size":  Vector2,      # quad world-space size (width, height)
##     "color": Color,        # tint
##     "tilt":  float,        # extra rotation around up axis (degrees)
##   }
##
## Params:
##   role_params: Dictionary{role_name -> {atlas, tile, size, color, tilt,
##                                          align_radial, radial_tilt}}
##   one_per_role: bool = true   # group cluster faces, one anchor per role
##   snap_radial: bool = true    # project to median radius (same as
##                               # replace_with_mesh_by_role's fix)
##   remove_original: bool = true
##   tag_prefix: String = ""
##   default: Dictionary (optional)
extends MeshRule
class_name MarkBillboardAnchorsOp


func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var role_params: Dictionary = params.get("role_params", {})
	var tag_prefix: String = String(params.get("tag_prefix", ""))
	var remove_original: bool = bool(params.get("remove_original", true))
	var default_params: Variant = params.get("default", null)
	var one_per_role: bool = bool(params.get("one_per_role", true))
	var snap_radial: bool = bool(params.get("snap_radial", true))

	# Group faces by role, same shape as replace_with_mesh_by_role.
	var jobs: Array = []
	var role_groups: Dictionary = {}
	for fi in selected:
		if fi >= mesh.faces.size() or fi >= mesh.face_tags.size():
			continue
		var role_key: String = ""
		for raw_tag in mesh.face_tags[fi]:
			var tag := String(raw_tag)
			var key := tag if tag_prefix.is_empty() else (
				tag.substr(tag_prefix.length()) if tag.begins_with(tag_prefix) else "")
			if not key.is_empty() and role_params.has(key):
				role_key = key; break
			if role_params.has(tag):
				role_key = tag; break
		var p: Dictionary = {}
		if not role_key.is_empty():
			p = role_params[role_key]
		elif default_params is Dictionary:
			p = default_params
		else:
			continue
		if one_per_role and not role_key.is_empty():
			if not role_groups.has(role_key):
				role_groups[role_key] = []
			(role_groups[role_key] as Array).append(fi)
		else:
			jobs.append([fi, role_key, p])
	if one_per_role:
		for role_key in role_groups.keys():
			var group: Array = role_groups[role_key]
			if group.is_empty(): continue
			jobs.append([int(group[0]), role_key, role_params[role_key], group])

	# Mesh centre across all selected faces (for align_radial).
	var mesh_centre := Vector3.ZERO
	var n: int = 0
	for fi in selected:
		if fi >= mesh.faces.size(): continue
		var ff := mesh.faces[fi]
		mesh_centre += (mesh.vertices[ff[0]] + mesh.vertices[ff[1]] + mesh.vertices[ff[2]]) / 3.0
		n += 1
	if n > 0:
		mesh_centre /= float(n)

	# Optional radial-snap pre-pass — project clusters to median radius.
	var role_target_radius: Dictionary = {}
	if one_per_role and snap_radial:
		var role_distances: Dictionary = {}
		for job in jobs:
			if job.size() < 4 or not (job[3] is Array): continue
			var rk: String = job[1]
			var parent_role: String = rk
			var us: int = rk.rfind("_")
			if us > 0 and rk.substr(us + 1).is_valid_int():
				parent_role = rk.substr(0, us)
			var grp: Array = job[3]
			var c2 := Vector3.ZERO
			for gi in grp:
				var ff := mesh.faces[int(gi)]
				c2 += (mesh.vertices[ff[0]] + mesh.vertices[ff[1]] + mesh.vertices[ff[2]]) / 3.0
			c2 /= float(grp.size())
			var d: float = (c2 - mesh_centre).length()
			if not role_distances.has(parent_role):
				role_distances[parent_role] = []
			(role_distances[parent_role] as Array).append(d)
		for parent_role in role_distances.keys():
			var arr: Array = role_distances[parent_role]
			arr.sort()
			role_target_radius[parent_role] = arr[arr.size() / 2]

	var to_delete: PackedInt32Array = PackedInt32Array()
	for job in jobs:
		var fi: int = job[0]
		var role_key: String = job[1]
		var p: Dictionary = job[2]
		var centroid: Vector3
		var normal: Vector3
		if job.size() >= 4 and job[3] is Array:
			var group: Array = job[3]
			centroid = Vector3.ZERO
			normal = Vector3.ZERO
			for gi in group:
				var gff := mesh.faces[int(gi)]
				var gv0: Vector3 = mesh.vertices[gff[0]]
				var gv1: Vector3 = mesh.vertices[gff[1]]
				var gv2: Vector3 = mesh.vertices[gff[2]]
				centroid += (gv0 + gv1 + gv2) / 3.0
				var nrm := (gv1 - gv0).cross(gv2 - gv0)
				if nrm.length_squared() > 1e-10:
					normal += nrm.normalized()
			centroid /= float(group.size())
			if normal.length_squared() < 1e-10:
				normal = Vector3.UP
			normal = normal.normalized()
			# Snap radial — same logic as replace_with_mesh_by_role.
			if snap_radial and not role_key.is_empty():
				var parent_role: String = role_key
				var us: int = role_key.rfind("_")
				if us > 0 and role_key.substr(us + 1).is_valid_int():
					parent_role = role_key.substr(0, us)
				if role_target_radius.has(parent_role):
					var radial: Vector3 = centroid - mesh_centre
					radial = radial - normal * radial.dot(normal)
					if radial.length_squared() > 1e-8:
						var tr: float = float(role_target_radius[parent_role])
						centroid = mesh_centre + radial.normalized() * tr
			if remove_original:
				for gi in group:
					to_delete.append(int(gi))
		else:
			var f := mesh.faces[fi]
			var v0: Vector3 = mesh.vertices[f[0]]
			var v1: Vector3 = mesh.vertices[f[1]]
			var v2: Vector3 = mesh.vertices[f[2]]
			var nrm := (v1 - v0).cross(v2 - v0)
			if nrm.length_squared() < 1e-10:
				continue
			normal = nrm.normalized()
			centroid = (v0 + v1 + v2) / 3.0
			if remove_original:
				to_delete.append(fi)
		_emit_billboard(mesh, role_key, p, centroid, normal, fi, mesh_centre)

	if to_delete.size() > 0:
		var sorted := Array(to_delete)
		sorted.sort()
		sorted.reverse()
		mesh.remove_faces(PackedInt32Array(sorted))


# Emit a 2-triangle quad at the anchor with billboard metadata recorded
# on each generated face. Quad is sized + oriented per role params; the
# alpha-test silhouette is left to the runtime shader.
func _emit_billboard(mesh: MeshData, role_key: String, p: Dictionary,
		centroid: Vector3, normal: Vector3, src_face_idx: int,
		mesh_centre: Vector3) -> void:
	var size_raw = p.get("size", [0.3, 0.4])
	var size_x: float = 0.3
	var size_y: float = 0.4
	if size_raw is Array and (size_raw as Array).size() >= 2:
		size_x = float(size_raw[0])
		size_y = float(size_raw[1])
	elif size_raw is Vector2:
		size_x = (size_raw as Vector2).x
		size_y = (size_raw as Vector2).y
	var atlas: String = String(p.get("atlas", ""))
	var tile: int = int(p.get("tile", 0))
	var color_raw = p.get("color", null)
	var tilt: float = float(p.get("tilt", 0.0))
	var align_radial: bool = bool(p.get("align_radial", false))
	var radial_tilt: float = float(p.get("radial_tilt", 0.4))
	var y_offset: float = float(p.get("y_offset", 0.0))

	# Orientation basis. Same logic as replace_with_mesh_by_role for parity.
	var basis: Basis = Basis.IDENTITY
	if align_radial:
		var radial: Vector3 = centroid - mesh_centre
		radial = radial - normal * radial.dot(normal)
		if radial.length_squared() < 1e-8:
			radial = Vector3.RIGHT
		radial = radial.normalized()
		var up: Vector3 = (radial + normal * radial_tilt).normalized()
		var ref: Vector3 = normal if absf(up.dot(normal)) < 0.95 else Vector3.RIGHT
		var u: Vector3 = up.cross(ref).normalized()
		var v: Vector3 = up.cross(u).normalized()
		basis = Basis(v, up, u)
	else:
		var up: Vector3 = normal
		var ref: Vector3 = Vector3.UP if absf(up.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
		var u: Vector3 = up.cross(ref).normalized()
		var v: Vector3 = up.cross(u).normalized()
		basis = Basis(v, up, u)
	if tilt != 0.0:
		basis = basis * Basis(Vector3.UP, deg_to_rad(tilt))

	var origin: Vector3 = centroid + normal * y_offset
	# Quad corners in local space: width along X, height along Y, base at -Y.
	var hx: float = size_x * 0.5
	var v0: Vector3 = origin + basis * Vector3(-hx, 0, 0)
	var v1: Vector3 = origin + basis * Vector3( hx, 0, 0)
	var v2: Vector3 = origin + basis * Vector3( hx, size_y, 0)
	var v3: Vector3 = origin + basis * Vector3(-hx, size_y, 0)
	var i0: int = mesh.add_vertex(v0)
	var i1: int = mesh.add_vertex(v1)
	var i2: int = mesh.add_vertex(v2)
	var i3: int = mesh.add_vertex(v3)

	var inherited_tags: PackedStringArray = PackedStringArray()
	inherited_tags.append("billboard")
	if not role_key.is_empty():
		inherited_tags.append(role_key)
	if src_face_idx < mesh.face_tags.size():
		for t in mesh.face_tags[src_face_idx]:
			inherited_tags.append(String(t))

	var inherited_color: Color = Color.WHITE
	var has_color: bool = false
	if color_raw is Color:
		inherited_color = color_raw
		has_color = true
	elif color_raw is Array and (color_raw as Array).size() >= 3:
		inherited_color = Color(float(color_raw[0]), float(color_raw[1]), float(color_raw[2]))
		has_color = true
	elif src_face_idx < mesh.face_metadata.size():
		var md: Dictionary = mesh.face_metadata[src_face_idx]
		if md.has("color"):
			inherited_color = md["color"]
			has_color = true

	var bb_meta: Dictionary = {
		"atlas": atlas,
		"tile": tile,
		"size": Vector2(size_x, size_y),
		"color": inherited_color,
		"tilt": tilt,
	}
	# Optional DNA-shader override + per-anchor uniform values. Collector
	# groups anchors by (atlas, shader) and binds these as shader params
	# on the resulting MultiMesh material. Lets one config drive the
	# critter_dna_billboard shader (patterns, iridescence, two-tone fills).
	if p.has("shader"):
		bb_meta["shader"] = String(p["shader"])
	if p.has("dna_params") and p["dna_params"] is Dictionary:
		bb_meta["dna_params"] = (p["dna_params"] as Dictionary).duplicate(true)
	# DNA resource path — the collector loads the CritterDNA .tres and
	# auto-populates shader uniforms from its gene fields. Closes the
	# round-trip: a config emits DNA via MeshGrammarExporter, then a
	# different render reads that DNA back to colour the same flower.
	if p.has("dna_resource"):
		bb_meta["dna_resource"] = String(p["dna_resource"])

	# Two triangles forming the quad. Each face carries the billboard
	# metadata + tags so the runtime collector can find them.
	for tri in [[i0, i1, i2], [i0, i2, i3]]:
		var fi: int = mesh.faces.size()
		mesh.faces.append(PackedInt32Array(tri))
		while mesh.face_tags.size() <= fi:
			mesh.face_tags.append(PackedStringArray())
			mesh.face_metadata.append({})
			mesh.face_depth.append(0)
		for t in inherited_tags:
			mesh.face_tags[fi].append(t)
		mesh.face_metadata[fi]["billboard"] = bb_meta.duplicate(true)
		if has_color:
			mesh.face_metadata[fi]["color"] = inherited_color
			mesh.face_metadata[fi]["painted"] = true
	while mesh.vertex_tags.size() < mesh.vertices.size():
		mesh.vertex_tags.append(PackedStringArray())
