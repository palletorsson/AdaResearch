## ProfileExtrudeOp — Extrude selected faces along a 2D profile curve.
## Creates stepped/curved molding profiles (cornices, moldings, bands).
## The profile is an Array of Vector2 points where x = depth (along normal)
## and y = height offset (along face's "up" direction).
##
## Params:
##   profile: Array[Vector2] = []     — profile curve points
##   profile_name: String = ""        — use a preset profile by name
##   scale: float = 1.0               — scale the profile
##   tag: String = "molding"          — tag for generated faces
extends MeshRule
class_name ProfileExtrudeOp

## Preset molding profiles (classical architectural profiles)
## Each profile is a sequence of (depth, height) offsets
const PROFILES := {
	"fascia": [
		Vector2(0.0, 0.0), Vector2(0.02, 0.0), Vector2(0.02, 1.0), Vector2(0.0, 1.0)
	],
	"ovolo": [
		Vector2(0.0, 0.0), Vector2(0.03, 0.0), Vector2(0.05, 0.2),
		Vector2(0.06, 0.5), Vector2(0.05, 0.8), Vector2(0.03, 1.0), Vector2(0.0, 1.0)
	],
	"cavetto": [
		Vector2(0.0, 0.0), Vector2(0.05, 0.0), Vector2(0.04, 0.3),
		Vector2(0.02, 0.6), Vector2(0.0, 1.0)
	],
	"cyma_recta": [
		Vector2(0.0, 0.0), Vector2(0.04, 0.0), Vector2(0.06, 0.15),
		Vector2(0.06, 0.35), Vector2(0.04, 0.5), Vector2(0.02, 0.65),
		Vector2(0.02, 0.85), Vector2(0.04, 1.0), Vector2(0.0, 1.0)
	],
	"cyma_reversa": [
		Vector2(0.0, 0.0), Vector2(0.02, 0.0), Vector2(0.02, 0.15),
		Vector2(0.04, 0.35), Vector2(0.06, 0.5), Vector2(0.04, 0.65),
		Vector2(0.02, 0.85), Vector2(0.04, 1.0), Vector2(0.0, 1.0)
	],
	"torus": [
		Vector2(0.0, 0.0), Vector2(0.02, 0.0), Vector2(0.04, 0.15),
		Vector2(0.05, 0.35), Vector2(0.05, 0.65), Vector2(0.04, 0.85),
		Vector2(0.02, 1.0), Vector2(0.0, 1.0)
	],
	"dentil": [
		Vector2(0.0, 0.0), Vector2(0.04, 0.0), Vector2(0.04, 0.4),
		Vector2(0.01, 0.4), Vector2(0.01, 0.6), Vector2(0.04, 0.6),
		Vector2(0.04, 1.0), Vector2(0.0, 1.0)
	],
	"stepped": [
		Vector2(0.0, 0.0), Vector2(0.06, 0.0), Vector2(0.06, 0.33),
		Vector2(0.04, 0.33), Vector2(0.04, 0.66), Vector2(0.02, 0.66),
		Vector2(0.02, 1.0), Vector2(0.0, 1.0)
	],
	"art_deco_stepped": [
		Vector2(0.0, 0.0), Vector2(0.08, 0.0), Vector2(0.08, 0.2),
		Vector2(0.06, 0.2), Vector2(0.06, 0.4), Vector2(0.04, 0.4),
		Vector2(0.04, 0.6), Vector2(0.06, 0.6), Vector2(0.06, 0.8),
		Vector2(0.08, 0.8), Vector2(0.08, 1.0), Vector2(0.0, 1.0)
	]
}


func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var profile_name: String = params.get("profile_name", "")
	var profile: Array = params.get("profile", [])
	var scale_factor: float = params.get("scale", 1.0)
	var tag: String = params.get("tag", "molding")

	# Load preset profile if name given
	if profile.is_empty() and profile_name != "" and PROFILES.has(profile_name):
		profile = PROFILES[profile_name]

	if profile.size() < 2:
		return

	# Apply scale to profile
	var scaled_profile: Array[Vector2] = []
	for p in profile:
		scaled_profile.append(Vector2(p.x * scale_factor, p.y))

	# Process in reverse to avoid index invalidation
	var sorted: Array = Array(selected)
	sorted.sort()
	sorted.reverse()

	for face_idx in sorted:
		if face_idx >= mesh.faces.size():
			continue

		_extrude_face_with_profile(mesh, face_idx, scaled_profile, tag)


func _extrude_face_with_profile(mesh: MeshData, face_idx: int,
		profile: Array[Vector2], tag: String) -> void:
	var f := mesh.faces[face_idx]
	var v0: Vector3 = mesh.vertices[f[0]]
	var v1: Vector3 = mesh.vertices[f[1]]
	var v2: Vector3 = mesh.vertices[f[2]]

	var normal := mesh.get_face_normal(face_idx)
	var centroid := mesh.get_face_centroid(face_idx)

	# Determine face "up" direction (perpendicular to normal and longest edge)
	var edge01 := (v1 - v0).normalized()
	var up := normal.cross(edge01).normalized()
	if up.y < 0:
		up = -up

	# Face height (extent along up direction)
	var dots: Array[float] = []
	for vi in f:
		dots.append(mesh.vertices[vi].dot(up))
	var face_height: float = dots.max() - dots.min()
	if face_height < 0.001:
		face_height = 1.0

	var old_depth: int = 0
	if face_idx < mesh.face_depth.size():
		old_depth = mesh.face_depth[face_idx]

	# For each segment in the profile, create a quad strip
	# Profile x = depth along normal, y = fractional height along face
	var prev_verts: PackedInt32Array = PackedInt32Array()

	# Get the face's edge vertices ordered by height
	# For a triangle, we interpolate along edges at each profile height
	for pi in range(profile.size()):
		var p: Vector2 = profile[pi]
		var depth := p.x
		var height_frac := p.y

		# Create vertices at this profile point for each face vertex
		var new_verts := PackedInt32Array()
		for vi_idx in range(f.size()):
			var base_pos: Vector3 = mesh.vertices[f[vi_idx]]
			# Offset along normal by depth and shift along up by height fraction
			var offset_pos: Vector3 = base_pos + normal * depth + up * (height_frac * face_height - (mesh.vertices[f[vi_idx]].dot(up) - dots.min()))
			var new_vi := mesh.add_vertex(offset_pos)
			new_verts.append(new_vi)

		# Connect to previous profile ring
		if not prev_verts.is_empty() and prev_verts.size() == new_verts.size():
			for ei in range(new_verts.size()):
				var next_ei := (ei + 1) % new_verts.size()
				var a := prev_verts[ei]
				var b := prev_verts[next_ei]
				var c := new_verts[next_ei]
				var d := new_verts[ei]
				mesh.add_face(PackedInt32Array([a, b, c]),
					PackedStringArray([tag]), old_depth + 1)
				mesh.add_face(PackedInt32Array([a, c, d]),
					PackedStringArray([tag]), old_depth + 1)

		prev_verts = new_verts

	# Remove original face
	mesh.remove_faces(PackedInt32Array([face_idx]))


## Get a preset profile by name.
static func get_profile(name: String) -> Array:
	return PROFILES.get(name, [])


## Get all available preset profile names.
static func get_profile_names() -> Array[String]:
	var result: Array[String] = []
	for key in PROFILES.keys():
		result.append(key)
	return result
