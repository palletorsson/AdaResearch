extends "res://commons/artifacts/spine_films/film_stage.gd"
const G = preload("res://commons/artifacts/spine_films/early/geometry.gd")
const SOURCE = "res://commons/primitives/animatedcubebuilder/animatedcubebuilder.gd"
var source: Node3D
var corners: Array[MeshInstance3D] = []
var edges: Array[MeshInstance3D] = []
var faces: Array[MeshInstance3D] = []
var seam: MeshInstance3D
var initial: Array
var figure: Node3D

func _build() -> void:
	title_text = "The diagonal was already there"
	phases = ["EIGHT CORNERS", "TWELVE EDGES", "TWO TRIANGLES PER SIDE", "ONE CORNER LEAVES THE PLANE"]
	notes = ["The cube builder stores eight positions.", "Its edge list joins pairs of positions.", "The front uses [4, 5, 7] and [5, 6, 7].", "Corner 6 moves. The face list and diagonal 5-7 stay unchanged."]
	source_paths = [SOURCE]
	source = load(SOURCE).new()
	initial = source.vertices.duplicate()
	source.create_triangle_meshes()
	figure = Node3D.new(); display.add_child(figure); figure.position.y = 1.35; figure.scale = Vector3.ONE*2.2
	for p: Vector3 in initial: corners.append(G.sphere(figure,p,.035,G.PINK))
	for e: Array in source.edges: edges.append(G.line(figure,initial[e[0]],initial[e[1]],G.WHITE,.012))
	for i in source.triangles.size():
		var colour := G.BLUE if i==4 else (G.PINK if i==5 else Color(.50,.65,.74,.16))
		faces.append(G.mesh(figure,source.triangle_meshes[i].mesh,colour))
	seam = G.line(figure,initial[5],initial[7],G.GOLD,.019)
	G.box(display,Vector3(0,.14,0),Vector3(3.7,.18,3.4),Color("263b50"))
	G.label(display,"5 - 7 / unchanged connection",Vector3(0,.36,1.95),G.GOLD,.16)
	frame_scene(Vector3(0,1.35,0),7.6,.48,.25)
	evidence = {"corners":initial.size(),"edges":source.edges.size(),"triangles":source.triangles.size(),"front_indices":source.triangles.slice(4,6),"displaced_corner":6,"displacement":[0,0,.55],"method":"create_triangle_meshes / _update_triangle_mesh"}

func _draw(time: float) -> void:
	var p := phase_index(time); var u := phase_progress(time)
	var amount := smoothstep(.10,.70,u) if p==3 else 0.0
	source.vertices[6] = initial[6]+Vector3(0,0,.55)*amount
	for i in corners.size():
		corners[i].position = source.vertices[i]
		corners[i].visible = p>0 or i<=int(u*8)
	for i in edges.size():
		var pair: Array = source.edges[i]
		G.line_pose(edges[i],source.vertices[pair[0]],source.vertices[pair[1]])
		edges[i].visible = p>=2 or (p==1 and i<=int(u*12))
	for i in faces.size():
		source._update_triangle_mesh(i)
		faces[i].mesh = source.triangle_meshes[i].mesh
		faces[i].visible = p>=3 or (p==2 and i<=int(u*12))
	seam.visible = p>=2

func validation() -> Dictionary:
	return {"passed":initial.size()==8 and source.triangles.size()==12 and source.triangles[4]==[4,5,7] and source.triangles[5]==[5,6,7],"evidence":evidence}

func _exit_tree() -> void:
	if is_instance_valid(source): source.free()
