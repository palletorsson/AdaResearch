extends RefCounted
## Drawing helpers only. Every film obtains its decisions from the named source.
const WHITE := Color("e9e5dc")
const PINK := Color("ee91b7")
const TEAL := Color("71d5c9")
const GOLD := Color("f0c769")
const BLUE := Color("839ff0")

static func material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.55
	if color.a < 1.0: m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if glow:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 0.6
	return m

static func node(host: Node3D, shape: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = shape
	n.position = at
	n.material_override = mat
	host.add_child(n)
	return n

static func box(host: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return node(host, shape, at, mat)

static func dot(host: Node3D, at: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2.0
	shape.radial_segments = 12
	shape.rings = 6
	return node(host, shape, at, mat)

static func rod(host: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.radial_segments = 8
	shape.rings = 0
	var n := node(host, shape, (a+b)*0.5, mat)
	set_rod(n, a, b)
	return n

static func set_rod(n: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var delta := b-a
	n.visible = delta.length_squared() > 0.000001
	if not n.visible: return
	(n.mesh as CylinderMesh).height = delta.length()
	n.position = (a+b)*0.5
	var y := delta.normalized()
	var seed := Vector3.RIGHT if absf(y.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var z := y.cross(seed).normalized()
	n.basis = Basis(y.cross(z).normalized(), y, z)

static func label(host: Node3D, text: String, at: Vector3, color: Color = WHITE, size: float = 0.003) -> Label3D:
	var n := Label3D.new()
	n.text = text
	n.position = at
	n.font_size = 40
	n.pixel_size = size
	n.modulate = color
	n.outline_size = 4
	n.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	host.add_child(n)
	return n

static func progress(time: float, start: float, stop: float) -> float:
	return smoothstep(0.0, 1.0, clampf((time-start)/maxf(stop-start,0.001),0.0,1.0))

static func wire(host: Node3D, points: PackedVector3Array, edges: Array, mat: Material) -> MeshInstance3D:
	var m := ImmediateMesh.new()
	m.surface_begin(Mesh.PRIMITIVE_LINES)
	for edge in edges:
		m.surface_add_vertex(points[edge[0]])
		m.surface_add_vertex(points[edge[1]])
	m.surface_end()
	return node(host, m, Vector3.ZERO, mat)

static func surface(points: PackedVector3Array, indices: PackedInt32Array) -> ArrayMesh:
	var normals := PackedVector3Array()
	normals.resize(points.size())
	for i in range(0,indices.size(),3):
		var a := indices[i]
		var b := indices[i+1]
		var c := indices[i+2]
		var n := (points[c]-points[a]).cross(points[b]-points[a])
		normals[a] += n
		normals[b] += n
		normals[c] += n
	for i in normals.size(): normals[i] = normals[i].normalized()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

static func grid_indices(nx: int, nz: int) -> PackedInt32Array:
	var indices := PackedInt32Array()
	for z in range(nz-1):
		for x in range(nx-1):
			var a := z*nx+x
			indices.append_array(PackedInt32Array([a,a+1,a+nx,a+1,a+nx+1,a+nx]))
	return indices
