extends RefCounted
const Kit = preload("res://commons/artifacts/spine_films/middle/film_kit.gd")

static func triangles(points: PackedVector3Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in points: st.add_vertex(p)
	st.generate_normals()
	return st.commit()

static func wire(host: Node3D, mesh: Mesh, tint: Color) -> MeshInstance3D:
	var faces := mesh.get_faces()
	var lines := PackedVector3Array()
	for i in range(0, faces.size(), 3):
		lines.append_array(PackedVector3Array([faces[i],faces[i+1],faces[i+1],faces[i+2],faces[i+2],faces[i]]))
	var out := ImmediateMesh.new()
	if not lines.is_empty():
		out.surface_begin(Mesh.PRIMITIVE_LINES)
		for p in lines: out.surface_add_vertex(p)
		out.surface_end()
	return Kit.node(host,out,Vector3.ZERO,Kit.material(tint,true))

static func caption(host: Node3D, text: String, at: Vector3, tint: Color = Kit.WHITE) -> Label3D:
	return Kit.label(host,text,at,tint,.005)

static func path_pairs(points: PackedVector3Array, count: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in range(1,mini(count,points.size())): out.append_array(PackedVector3Array([points[i-1],points[i]]))
	return out
