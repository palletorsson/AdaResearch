extends Node3D
## Presentation of the existing source mesh. Coplanar triangle diagonals are
## removed from the edge display; the object's vertices are never moved.
const Kit = preload("res://commons/artifacts/ignorance_gallery/gallery_kit.gd")
var body: XRToolsPickable
var geometry: Dictionary
var edge_material: StandardMaterial3D
var lamp: OmniLight3D

func setup(pickable: XRToolsPickable) -> void:
	body=pickable
	var surface := body.get_child(0) as MeshInstance3D
	surface.name="Faces"
	geometry=topology(surface.mesh)
	# The old generators disagree about winding. Give the carried study outward
	# normals and Godot's clockwise front faces, preserving all source triangles.
	var flat := SurfaceTool.new()
	flat.begin(Mesh.PRIMITIVE_TRIANGLES)
	for triangle in geometry.triangles:
		var a: Vector3=geometry.vertices[triangle[0]]
		var b: Vector3=geometry.vertices[triangle[1]]
		var c: Vector3=geometry.vertices[triangle[2]]
		var normal := (b-a).cross(c-a).normalized()
		if normal.dot((a+b+c)/3.0-geometry.center)<0: normal=-normal
		if (b-a).cross(c-a).dot(normal)>0:
			var swap := b;b=c;c=swap
		for vertex in [a,b,c]:
			flat.set_normal(normal);flat.add_vertex(vertex)
	surface.mesh=flat.commit()
	var finish := Kit.material(Color("e7ded0"))
	finish.roughness=.48
	finish.metallic=.05
	finish.emission_enabled=true
	finish.emission=Color("e7ded0")
	finish.emission_energy_multiplier=.035
	surface.material_override=finish
	# One batched mesh for actual polyhedron edges and their endpoints. Cylinders
	# remain legible in stereo, unlike one-pixel wireframe rendering.
	var outline := SurfaceTool.new()
	outline.begin(Mesh.PRIMITIVE_TRIANGLES)
	for edge in geometry.edges:
		var a: Vector3=surface.transform*geometry.vertices[edge.x]
		var b: Vector3=surface.transform*geometry.vertices[edge.y]
		var cylinder := CylinderMesh.new()
		cylinder.top_radius=.006;cylinder.bottom_radius=.006
		cylinder.radial_segments=8;cylinder.rings=1;cylinder.height=a.distance_to(b)
		var y := (b-a).normalized()
		var reference := Vector3.RIGHT if absf(y.dot(Vector3.UP))>.95 else Vector3.UP
		var x := reference.cross(y).normalized()
		outline.append_from(cylinder,0,Transform3D(Basis(x,y,x.cross(y)),(a+b)*.5))
	var joint := SphereMesh.new()
	joint.radius=.012;joint.height=.024;joint.radial_segments=8;joint.rings=3
	for vertex in geometry.vertices:
		outline.append_from(joint,0,Transform3D(Basis.IDENTITY,surface.transform*vertex))
	var edges := MeshInstance3D.new()
	edges.name="EdgesAndVertices";edges.mesh=outline.commit()
	edge_material=Kit.material(Color("826b4b"))
	edge_material.roughness=.4
	edge_material.emission_enabled=true
	edge_material.emission=Color("ffd49d")
	edge_material.emission_energy_multiplier=.16
	edges.material_override=edge_material
	body.add_child(edges)
	lamp=OmniLight3D.new()
	lamp.name="CarriedLight";lamp.light_color=Color("ffdfba")
	lamp.light_energy=1.7;lamp.omni_range=2.6;lamp.shadow_enabled=false
	lamp.hide();body.add_child(lamp)
	body.picked_up.connect(_held)
	body.dropped.connect(_released)
	set_meta("vertices",geometry.vertices.size())
	set_meta("edges",geometry.edges.size())
	set_meta("faces",geometry.planes.size())
	# Keep every label and light inside the existing named editor part.
	var group := body.get_parent() as Node3D
	Kit.block(group,Vector3(.99,.42,.025),Vector3(0,.56,.574),Color("262531"),false).name="ReadingPlate"
	var name_label := Kit.label(group,String(body.get_meta("solid_type")).to_upper(),Vector3(0,.68,.591),.00165)
	name_label.modulate=Color("fff0db")
	var counts := "%d vertices   /   %d edges\n%d %s faces"%[geometry.vertices.size(),geometry.edges.size(),geometry.planes.size(),"square" if geometry.planes.size()==6 else "pentagonal" if geometry.planes.size()==12 else "triangular"]
	Kit.label(group,counts,Vector3(0,.55,.591),.0011).modulate=Color("fff0db")
	Kit.label(group,"PICK UP / TURN / COMPARE",Vector3(0,.41,.591),.0009).modulate=Color("e9bf82")

func _held(_object: Node3D) -> void:
	edge_material.emission_energy_multiplier=1.6
	lamp.show()

func _released(_object: Node3D) -> void:
	edge_material.emission_energy_multiplier=.16
	lamp.hide()

static func topology(mesh: Mesh) -> Dictionary:
	var vertices: Array[Vector3]=[]
	var triangles: Array[Vector3i]=[]
	var seen := {}
	# Weld the duplicated face vertices and discard double-sided duplicates.
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var mapping: Array[int]=[]
		for vertex: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
			var found := -1
			for j in vertices.size():
				if vertex.distance_squared_to(vertices[j])<0.0000000001: found=j;break
			if found<0: found=vertices.size();vertices.append(vertex)
			mapping.append(found)
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
		if indices.is_empty(): indices=PackedInt32Array(range(mapping.size()))
		for i in range(0,indices.size(),3):
			var ids := [mapping[indices[i]],mapping[indices[i+1]],mapping[indices[i+2]]]
			var sorted := ids.duplicate();sorted.sort()
			var key := str(sorted)
			if seen.has(key): continue
			seen[key]=true
			triangles.append(Vector3i(ids[0],ids[1],ids[2]))
	var center := Vector3.ZERO
	for vertex in vertices: center+=vertex
	center/=vertices.size()
	var planes: Array[Plane]=[]
	var face_vertices: Array=[]
	var adjacency := {}
	for triangle in triangles:
		var a := vertices[triangle.x];var b := vertices[triangle.y];var c := vertices[triangle.z]
		var normal := (b-a).cross(c-a).normalized()
		if normal.dot((a+b+c)/3.0-center)<0: normal=-normal
		var plane := Plane(normal,normal.dot(a))
		var face := -1
		for j in planes.size():
			if planes[j].normal.dot(normal)>.99999 and absf(planes[j].d-plane.d)<.00001: face=j;break
		if face<0: face=planes.size();planes.append(plane);face_vertices.append([])
		for i in 3:
			var index: int=triangle[i]
			if not face_vertices[face].has(index): face_vertices[face].append(index)
			var other: int=triangle[(i+1)%3]
			var edge := Vector2i(mini(index,other),maxi(index,other))
			if not adjacency.has(edge): adjacency[edge]=[]
			adjacency[edge].append(face)
	var edges: Array[Vector2i]=[]
	for edge in adjacency:
		var faces: Array=adjacency[edge]
		if faces.size()!=2 or faces[0]!=faces[1]: edges.append(edge)
	return {"vertices":vertices,"triangles":triangles,"planes":planes,"face_vertices":face_vertices,"edges":edges,"adjacency":adjacency,"center":center}
