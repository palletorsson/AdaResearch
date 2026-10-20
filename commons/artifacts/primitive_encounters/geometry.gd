extends RefCounted
## Convex teaching solids. Face orientation is checked against the centroid.
static func material(colour: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = 0.48
	return m

static func mesh(vertices: PackedVector3Array, faces: Array) -> ArrayMesh:
	var centre := Vector3.ZERO
	for v in vertices: centre += v
	centre /= vertices.size()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in faces:
		for i in range(1, face.size()-1):
			var a := vertices[face[0]]
			var b := vertices[face[i]]
			var c := vertices[face[i+1]]
			var normal := (b-a).cross(c-a).normalized()
			if normal.dot((a+b+c)/3.0-centre) < 0:
				var swap := b; b=c; c=swap; normal=-normal
			# Godot front faces are clockwise; normals point outwards.
			for v in [a,c,b]:
				st.set_normal(normal)
				st.add_vertex(v)
	return st.commit()

static func solid(parent: Node3D, title: String, vertices: PackedVector3Array, faces: Array, colour: Color, collision: bool = true) -> MeshInstance3D:
	var m := MeshInstance3D.new();m.name=title
	m.mesh=mesh(vertices,faces);m.material_override=material(colour)
	parent.add_child(m)
	if collision:
		var body:=StaticBody3D.new();body.collision_layer=1
		var shape:=ConvexPolygonShape3D.new();shape.points=vertices
		var col:=CollisionShape3D.new();col.shape=shape
		body.add_child(col);m.add_child(body)
	return m

static func box(parent: Node3D, title: String, at: Vector3, size: Vector3, colour: Color, collision: bool = true) -> MeshInstance3D:
	var m:=MeshInstance3D.new();m.name=title;m.position=at
	var b:=BoxMesh.new();b.size=size;m.mesh=b;m.material_override=material(colour)
	parent.add_child(m)
	if collision:
		var body:=StaticBody3D.new();body.collision_layer=1
		var shape:=BoxShape3D.new();shape.size=size
		var col:=CollisionShape3D.new();col.shape=shape
		body.add_child(col);m.add_child(body)
	return m

static func label(parent: Node3D, words: String, at: Vector3, size: int = 30) -> Label3D:
	var l:=Label3D.new();l.text=words;l.position=at;l.font_size=size
	l.pixel_size=0.002;l.modulate=Color("292530");l.outline_size=0
	parent.add_child(l)
	return l

static func tetra() -> PackedVector3Array:
	return PackedVector3Array([Vector3(-0.45,-0.26,-0.26),Vector3(0.45,-0.26,-0.26),Vector3(0,-0.26,0.51942),Vector3(0,0.47485,0)])
static func tetra_faces() -> Array: return [[0,1,2],[0,3,1],[1,3,2],[2,3,0]]
static func wedge(width: float = 0.8, height: float = 0.65, run: float = 0.9) -> PackedVector3Array:
	return PackedVector3Array([Vector3(-width/2,0,-run/2),Vector3(width/2,0,-run/2),Vector3(-width/2,0,run/2),Vector3(width/2,0,run/2),Vector3(-width/2,height,run/2),Vector3(width/2,height,run/2)])
static func wedge_faces() -> Array: return [[0,2,3,1],[2,4,5,3],[0,4,2],[1,3,5],[0,1,5,4]]
