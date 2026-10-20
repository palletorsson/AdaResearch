extends RefCounted
## Ordinary museum architecture. These colliders do not pretend to be curved physics.

static func material(colour: Color, glow := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = 0.65
	if glow:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

static func mesh(parent: Node3D, shape: Mesh, at: Vector3, colour: Color, solid := false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = shape
	n.position = at
	n.material_override = material(colour)
	parent.add_child(n)
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		n.add_child(body)
		var c := CollisionShape3D.new()
		c.shape = shape.create_trimesh_shape()
		body.add_child(c)
	return n

static func box(parent: Node3D, at: Vector3, size: Vector3, colour: Color, solid := false) -> MeshInstance3D:
	var s := BoxMesh.new()
	s.size = size
	return mesh(parent,s,at,colour,solid)

static func ball(parent: Node3D, at: Vector3, radius: float, colour: Color) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius=radius; s.height=radius*2; s.radial_segments=32; s.rings=16
	return mesh(parent,s,at,colour)

static func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, colour: Color, solid := false) -> MeshInstance3D:
	var s := CylinderMesh.new()
	s.top_radius=radius; s.bottom_radius=radius; s.height=height; s.radial_segments=40
	return mesh(parent,s,at,colour,solid)

static func tube(parent: Node3D, a: Vector3, b: Vector3, colour: Color, radius := 0.025) -> MeshInstance3D:
	var d := b-a
	var n := cylinder(parent,(a+b)*0.5,radius,maxf(d.length(),0.001),colour)
	var y := d.normalized() if d.length()>0.0001 else Vector3.UP
	var reference := Vector3.RIGHT if absf(y.dot(Vector3.UP))>0.98 else Vector3.UP
	var x := reference.cross(y).normalized()
	n.basis = Basis(x,y,x.cross(y)).orthonormalized()
	return n

static func text(parent: Node3D, words: String, at: Vector3, size := 36, colour := Color(0.92,0.93,0.93)) -> Label3D:
	var n := Label3D.new()
	n.text=words; n.font_size=size; n.pixel_size=0.008
	n.position=at; n.modulate=colour; n.outline_size=0
	parent.add_child(n)
	return n

static func path_mesh(parent: Node3D, paths: Array, colour: Color) -> MeshInstance3D:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for points in paths:
		for i in range(points.size()-1):
			im.surface_add_vertex(points[i]); im.surface_add_vertex(points[i+1])
	im.surface_end()
	var n := MeshInstance3D.new()
	n.mesh=im; n.material_override=material(colour,true)
	parent.add_child(n)
	return n
