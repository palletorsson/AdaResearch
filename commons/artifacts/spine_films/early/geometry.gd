extends RefCounted
const WHITE := Color("eee9df")
const INK := Color("171b24")
const PINK := Color("ed82ab")
const BLUE := Color("7db6d5")
const GOLD := Color("d7b16b")

static func material(c: Color, flat: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.48
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if flat: m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if c.a < 1.0: m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

static func mesh(parent: Node, resource: Mesh, c: Color) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = resource
	n.material_override = material(c)
	parent.add_child(n)
	return n

static func box(parent: Node, at: Vector3, size: Vector3, c: Color) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	var n := mesh(parent, m, c)
	n.position = at
	return n

static func sphere(parent: Node, at: Vector3, radius: float, c: Color) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 12
	m.rings = 6
	var n := mesh(parent, m, c)
	n.position = at
	return n

static func line(parent: Node, a: Vector3, b: Vector3, c: Color, radius: float = 0.016) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.height = 1.0
	m.top_radius = radius
	m.bottom_radius = radius
	m.radial_segments = 8
	m.rings = 1
	var n := mesh(parent, m, c)
	line_pose(n, a, b)
	return n

static func line_pose(n: Node3D, a: Vector3, b: Vector3) -> void:
	var d := b - a
	n.visible = d.length() > 0.0001
	if not n.visible: return
	n.transform = Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())).scaled_local(Vector3(1, d.length(), 1)), (a + b) * 0.5)

static func face(parent: Node, vertices: PackedVector3Array, c: Color) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, vertices.size(), 3):
		var normal := (vertices[i+1] - vertices[i]).cross(vertices[i+2] - vertices[i]).normalized()
		for j in range(3):
			st.set_normal(normal)
			st.add_vertex(vertices[i+j])
	return mesh(parent, st.commit(), c)

static func label(parent: Node, text: String, at: Vector3, c: Color = WHITE, height: float = 0.13) -> Label3D:
	var n := Label3D.new()
	n.text = text
	n.position = at
	n.font_size = 42
	n.pixel_size = height / 42.0
	n.modulate = c
	n.outline_size = 0
	n.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(n)
	return n

static func frame(parent: Node, size: Vector3, c: Color) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	for axis in range(3):
		for a in [-1,1]:
			for b in [-1,1]:
				var v := Vector3.ZERO
				v[(axis+1)%3] = float(a)*size[(axis+1)%3]*0.5
				v[(axis+2)%3] = float(b)*size[(axis+2)%3]*0.5
				var w := v
				v[axis] = -size[axis]*0.5
				w[axis] = size[axis]*0.5
				line(n,v,w,c,0.009)
	return n

static func blend(t: float, start: float, end: float) -> float:
	return smoothstep(start, end, t)
