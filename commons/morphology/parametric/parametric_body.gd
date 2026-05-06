# parametric_body.gd — Base class for parametric-surface body recipes
# (Klein bottle, Möbius strip, supershape, etc.). Not SDF-based — these
# are surfaces-first, generated as an ArrayMesh from a (u, v) → (x, y, z)
# lambda sampled on a grid.
#
# Shares the body_recipe interface so form_editor / form_studio can use
# the same code path:
#   recipe.dna = {...}
#   recipe.build()
#   var body: Node3D = recipe.build_mesh_body(materials)
#
# Subclasses override _surface(u, v) -> Vector3 and set the u/v ranges.

extends RefCounted

var dna: Dictionary = {}

# U and V sampling ranges — subclasses set these in _setup().
var u_min: float = 0.0
var u_max: float = TAU
var v_min: float = 0.0
var v_max: float = TAU
var num_u: int = 48
var num_v: int = 48
var close_u: bool = true   # wrap faces around U direction
var close_v: bool = true


func build() -> void:
	_setup()


## Subclass override — map (u, v) ∈ their ranges to a 3D point.
func _surface(_u: float, _v: float) -> Vector3:
	return Vector3.ZERO


## Subclass override — read DNA, set u/v ranges, resolution, close flags.
func _setup() -> void:
	pass


func build_mesh_body(materials: Dictionary = {}) -> Node3D:
	build()
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()

	# Sample grid
	for i in num_u + 1:
		var u: float = lerp(u_min, u_max, float(i) / float(num_u))
		for j in num_v + 1:
			var v: float = lerp(v_min, v_max, float(j) / float(num_v))
			verts.append(_surface(u, v))
			normals.append(Vector3.UP)  # placeholder — computed from faces below

	var stride: int = num_v + 1
	# Build quads (as two triangles) with optional wrap in U/V
	for i in num_u:
		for j in num_v:
			var i2: int = (i + 1) if i + 1 <= num_u else 0
			var j2: int = (j + 1) if j + 1 <= num_v else 0
			var a: int = i * stride + j
			var b: int = i2 * stride + j
			var c: int = i2 * stride + j2
			var d: int = i * stride + j2
			# Triangle 1: a, b, c ; Triangle 2: a, c, d
			indices.append_array([a, b, c, a, c, d])

	# Recompute normals from face geometry
	_compute_normals(verts, indices, normals)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat: Material = materials.get("body", materials.get("default", null))
	if mat == null:
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = Color(0.85, 0.8, 0.7)
		fallback.roughness = 0.5
		fallback.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat = fallback
	else:
		# Parametric surfaces are single-sided — disable backface cull so
		# both sides show. Clone StandardMaterial3D to set cull_mode safely.
		if mat is StandardMaterial3D:
			var m2: StandardMaterial3D = (mat as StandardMaterial3D).duplicate()
			m2.cull_mode = BaseMaterial3D.CULL_DISABLED
			mat = m2
	mi.material_override = mat

	var root := Node3D.new()
	root.add_child(mi)
	return root


static func _compute_normals(verts: PackedVector3Array, indices: PackedInt32Array,
		out_normals: PackedVector3Array) -> void:
	# Reset normals
	for i in out_normals.size():
		out_normals[i] = Vector3.ZERO
	# Accumulate per-face normals
	var n: int = indices.size() / 3
	for k in n:
		var ia: int = indices[k * 3]
		var ib: int = indices[k * 3 + 1]
		var ic: int = indices[k * 3 + 2]
		var a: Vector3 = verts[ia]
		var b: Vector3 = verts[ib]
		var c: Vector3 = verts[ic]
		var face_n: Vector3 = (b - a).cross(c - a)
		if face_n.length_squared() > 1e-12:
			face_n = face_n.normalized()
		out_normals[ia] = out_normals[ia] + face_n
		out_normals[ib] = out_normals[ib] + face_n
		out_normals[ic] = out_normals[ic] + face_n
	for i in out_normals.size():
		var nn: Vector3 = out_normals[i]
		if nn.length_squared() > 1e-12:
			out_normals[i] = nn.normalized()
		else:
			out_normals[i] = Vector3.UP
