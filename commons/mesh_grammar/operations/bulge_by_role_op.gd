## BulgeByRoleOp — Bulge faces with role-specific amount and direction.
##
## Companion morphology op to extrude_by_role. Where extrude pushes the
## entire face along its normal (creating side walls), bulge displaces
## the face's centroid along its normal without adding side walls — a
## smoother, rounded deformation.
##
## Best paired with extrude_by_role: petals extruded outward then bulged
## convex; stamens extruded then bulged into rounded tips; sepals only
## bulged (slight rounding) without extrusion.
##
## Params:
##   role_params: Dictionary{role_name -> {amount, direction}}
##     amount: float — displacement along normal (positive = outward,
##                     negative = inward)
##     direction: Vector3 (optional) — override for non-normal bulge
##                     (e.g. [0, 1, 0] always pushes upward)
##   tag_prefix: String = ""
##   default: Dictionary (optional)
extends MeshRule
class_name BulgeByRoleOp


func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var role_params: Dictionary = params.get("role_params", {})
	var tag_prefix: String = String(params.get("tag_prefix", ""))
	var default_params: Variant = params.get("default", null)

	# Group displacements per vertex to avoid double-counting when a vertex
	# is shared by faces with different roles.
	var vertex_disp: Dictionary = {}  # vertex_idx -> Vector3
	var vertex_count: Dictionary = {}  # vertex_idx -> int

	for fi in selected:
		if fi >= mesh.faces.size():
			continue
		# Find role for this face.
		var role_key: String = ""
		if fi < mesh.face_tags.size():
			for raw_tag in mesh.face_tags[fi]:
				var tag := String(raw_tag)
				var key := tag if tag_prefix.is_empty() else (
					tag.substr(tag_prefix.length()) if tag.begins_with(tag_prefix) else "")
				if not key.is_empty() and role_params.has(key):
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
			continue

		var amount: float = float(p.get("amount", 0.1))
		var dir_raw = p.get("direction", null)
		var f := mesh.faces[fi]
		var v0: Vector3 = mesh.vertices[f[0]]
		var v1: Vector3 = mesh.vertices[f[1]]
		var v2: Vector3 = mesh.vertices[f[2]]
		var normal := (v1 - v0).cross(v2 - v0)
		if normal.length_squared() < 1e-10:
			continue
		normal = normal.normalized()
		var dir: Vector3 = normal
		if dir_raw is Array and dir_raw.size() >= 3:
			dir = Vector3(float(dir_raw[0]), float(dir_raw[1]), float(dir_raw[2])).normalized()
		elif dir_raw is Vector3:
			dir = (dir_raw as Vector3).normalized()

		var disp: Vector3 = dir * amount
		for vi in f:
			if not vertex_disp.has(vi):
				vertex_disp[vi] = Vector3.ZERO
				vertex_count[vi] = 0
			vertex_disp[vi] = (vertex_disp[vi] as Vector3) + disp
			vertex_count[vi] = (vertex_count[vi] as int) + 1

	# Apply averaged displacements.
	for vi in vertex_disp.keys():
		var avg: Vector3 = (vertex_disp[vi] as Vector3) / float(vertex_count[vi] as int)
		mesh.vertices[vi] = mesh.vertices[vi] + avg
