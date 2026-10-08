extends "res://commons/artifacts/spine_films/film_stage.gd"
## Geometry helpers owned by the late-film observers. No museum object is edited.
const CHALK := Color("e7e1d7")
const TEAL := Color("67daca")
const PINK := Color("ef9bbd")
const GOLD := Color("e9b969")
const SLATE := Color("4c6177")

func film_group(parent: Node3D = null) -> Node3D:
	var node := Node3D.new()
	(parent if parent != null else display).add_child(node)
	return node

func film_rod_pose(node: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var delta := b-a
	node.position = (a+b)*.5
	if delta.length_squared() > .000001: node.basis = Basis(Quaternion(Vector3.UP,delta.normalized()))*Basis.from_scale(Vector3(1,delta.length(),1))
	node.visible = delta.length_squared() > .000001

func film_unit_rod(colour: Color, parent: Node3D = null, radius := .025) -> MeshInstance3D:
	return add_rod(Vector3.ZERO,Vector3.UP,radius,colour,parent)

func film_triangles(vertices: PackedVector3Array, colour: Color, parent: Node3D = null) -> MeshInstance3D:
	var mesh := ArrayMesh.new()
	if vertices.size() >= 3:
		var normals := PackedVector3Array()
		for i in range(0,vertices.size(),3):
			var normal := (vertices[i+1]-vertices[i]).cross(vertices[i+2]-vertices[i]).normalized()
			for j in 3: normals.append(normal)
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return add_mesh(mesh,colour,Vector3.ZERO,parent)

func film_path(points: PackedVector3Array, colour: Color, parent: Node3D = null, radius := .018) -> Array[MeshInstance3D]:
	var rods: Array[MeshInstance3D] = []
	for i in range(1,points.size()): rods.append(add_rod(points[i-1],points[i],radius,colour,parent))
	return rods

func film_reveal(rods: Array[MeshInstance3D], amount: float) -> void:
	var count := int(ceil(clampf(amount,0,1)*rods.size()))
	for i in rods.size(): rods[i].visible = i<count

func film_arrow(a: Vector3, vector: Vector3, colour: Color, parent: Node3D = null) -> Node3D:
	var group := film_group(parent)
	var length := vector.length()
	if length < .00001: return group
	add_rod(a,a+vector,.025,colour,group)
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0
	mesh.bottom_radius = .09
	mesh.height = .23
	mesh.radial_segments = 12
	mesh.rings = 0
	var tip := add_mesh(mesh,colour,a+vector-vector.normalized()*.10,group)
	tip.basis = Basis(Quaternion(Vector3.UP,vector.normalized()))
	return group

func film_deck() -> void:
	add_box(Vector3(0,-.13,0),Vector3(7.5,.12,4.8),Color("263343"))

func validation() -> Dictionary:
	return {"title":title_text,"duration":duration,"phases":phases.size(),"evidence":evidence.duplicate(true),"source_paths":source_paths.duplicate(),"geometry_nodes":display.get_child_count()}
