## SurfaceScatterOp — Scatter small sub-meshes across selected face surfaces.
## Creates organic surface texture, nodule details, barnacle-like growth.
## Params:
##   shape: String = "sphere"     — "sphere", "cube", "spike"
##   density: float = 0.5         — probability per face (0-1)
##   min_size: float = 0.02       — minimum decoration size
##   max_size: float = 0.05       — maximum decoration size
##   offset: float = 0.0          — outward offset from surface along normal
##   align_to_normal: bool = true — orient decoration along face normal
##   seed_value: int = -1         — random seed (-1 = random)
##   scatter_tag: String = "scatter"
extends MeshRule
class_name SurfaceScatterOp

func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var shape: String = params.get("shape", "sphere")
	var density: float = clampf(params.get("density", 0.5), 0.0, 1.0)
	var min_size: float = params.get("min_size", 0.02)
	var max_size: float = params.get("max_size", 0.05)
	var offset_amount: float = params.get("offset", 0.0)
	var align: bool = params.get("align_to_normal", true)
	var seed_val: int = params.get("seed_value", -1)
	var scatter_tag: String = params.get("scatter_tag", "scatter")

	var rng := RandomNumberGenerator.new()
	if seed_val >= 0:
		rng.seed = seed_val
	else:
		rng.randomize()

	for face_idx in selected:
		if face_idx >= mesh.faces.size():
			continue
		if rng.randf() > density:
			continue

		var f := mesh.faces[face_idx]
		var v0: Vector3 = mesh.vertices[f[0]]
		var v1: Vector3 = mesh.vertices[f[1]]
		var v2: Vector3 = mesh.vertices[f[2]]
		var normal := mesh.get_face_normal(face_idx)

		# Random point on triangle (barycentric coordinates)
		var u: float = rng.randf()
		var v: float = rng.randf()
		if u + v > 1.0:
			u = 1.0 - u
			v = 1.0 - v
		var w: float = 1.0 - u - v
		var pos: Vector3 = v0 * w + v1 * u + v2 * v + normal * offset_amount

		var size: float = rng.randf_range(min_size, max_size)

		match shape:
			"sphere":
				_add_sphere(mesh, pos, size, scatter_tag)
			"cube":
				_add_cube(mesh, pos, size, scatter_tag)
			"spike":
				_add_spike(mesh, pos, size, normal if align else Vector3.UP, scatter_tag)
			_:
				_add_sphere(mesh, pos, size, scatter_tag)

	mesh._adjacency_dirty = true

func _add_sphere(mesh: MeshData, center: Vector3, radius: float, tag: String) -> void:
	# Minimal icosahedron-based sphere (low poly for scatter)
	var t: float = (1.0 + sqrt(5.0)) / 2.0
	var base_verts: Array[Vector3] = [
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)
	]
	var ico_faces: Array = [
		[0,11,5],[0,5,1],[0,1,7],[0,7,10],[0,10,11],
		[1,5,9],[5,11,4],[11,10,2],[10,7,6],[7,1,8],
		[3,9,4],[3,4,2],[3,2,6],[3,6,8],[3,8,9],
		[4,9,5],[2,4,11],[6,2,10],[8,6,7],[9,8,1]
	]
	# Normalize and scale
	var vi_offset: int = mesh.vertices.size()
	for v in base_verts:
		mesh.add_vertex(center + v.normalized() * radius)
	for f in ico_faces:
		mesh.add_face(
			PackedInt32Array([f[0] + vi_offset, f[1] + vi_offset, f[2] + vi_offset]),
			PackedStringArray([tag]))

func _add_cube(mesh: MeshData, center: Vector3, size: float, tag: String) -> void:
	var s := size * 0.5
	var vi := mesh.vertices.size()
	mesh.add_vertex(center + Vector3(-s, -s, s))
	mesh.add_vertex(center + Vector3(s, -s, s))
	mesh.add_vertex(center + Vector3(s, s, s))
	mesh.add_vertex(center + Vector3(-s, s, s))
	mesh.add_vertex(center + Vector3(-s, -s, -s))
	mesh.add_vertex(center + Vector3(s, -s, -s))
	mesh.add_vertex(center + Vector3(s, s, -s))
	mesh.add_vertex(center + Vector3(-s, s, -s))
	var cube_faces := [
		[0,1,2],[0,2,3],[5,4,7],[5,7,6],[4,0,3],[4,3,7],
		[1,5,6],[1,6,2],[3,2,6],[3,6,7],[4,5,1],[4,1,0]]
	for f in cube_faces:
		mesh.add_face(PackedInt32Array([f[0]+vi, f[1]+vi, f[2]+vi]), PackedStringArray([tag]))

func _add_spike(mesh: MeshData, base: Vector3, height: float,
		direction: Vector3, tag: String) -> void:
	# Triangular spike pointing along direction
	var up := direction.normalized()
	var right: Vector3
	if abs(up.dot(Vector3.UP)) < 0.99:
		right = up.cross(Vector3.UP).normalized()
	else:
		right = up.cross(Vector3.RIGHT).normalized()
	var forward := right.cross(up).normalized()

	var r := height * 0.2  # Base radius
	var tip := mesh.add_vertex(base + up * height)
	var b0 := mesh.add_vertex(base + right * r)
	var b1 := mesh.add_vertex(base + forward * r)
	var b2 := mesh.add_vertex(base - right * r)

	mesh.add_face(PackedInt32Array([b0, b1, tip]), PackedStringArray([tag]))
	mesh.add_face(PackedInt32Array([b1, b2, tip]), PackedStringArray([tag]))
	mesh.add_face(PackedInt32Array([b2, b0, tip]), PackedStringArray([tag]))
	mesh.add_face(PackedInt32Array([b0, b2, b1]), PackedStringArray([tag]))  # base cap
