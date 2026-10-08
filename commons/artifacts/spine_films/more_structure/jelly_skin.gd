extends "res://commons/artifacts/spine_films/more_structure/structure_stage.gd"
const SOURCE=preload("res://commons/artifacts/jelly_cube/jelly_cube.gd")
var faces: Array[Node3D]=[]
var directions: Array[Vector3]=[]
var points: Array[MeshInstance3D]=[]
var edges: Array[Node3D]=[]
var crown: Node3D
var readout: Label3D
var anchor_position:=Vector3.ZERO
func _build()->void:
	title_text="A yielding body begins with a skin"
	phases.assign(["The cube is six subdivided surfaces", "Separate the faces to see their samples", "Indices join the samples into triangles", "One upper point becomes the attachment"])
	notes.assign(["The original jelly_cube creates this exact BoxMesh, with four subdivisions on each axis.","Faces are separated here only to inspect their data. The museum body is not being torn apart.","Rendering may repeat a position for distinct face normals. These entries are not independent masses.","The original crown selector pins one upper mesh entry. This film exposes the rest mesh and attachment, not a substitute soft-body solver."])
	source_paths.assign(["res://commons/artifacts/jelly_cube/jelly_cube.gd"])
	var source=SOURCE.new();source.anchor="crown";source._create_soft_body();source._configure_anchor()
	var arrays:Array=source._soft_body.mesh.surface_get_arrays(0)
	var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX].duplicate()
	var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL].duplicate()
	var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX].duplicate()
	var anchor:int=source._anchor_index
	anchor_position=vertices[anchor]*7.0+Vector3(0,1.5,0)
	var unique:Dictionary={};var face_lists:Dictionary={}
	for i in vertices.size(): unique[vertices[i].snapped(Vector3.ONE*.00001)]=true
	for i in range(0,indices.size(),3):
		var normal:Vector3=normals[indices[i]]
		if not face_lists.has(normal):face_lists[normal]=PackedVector3Array()
		var triangle:PackedVector3Array=face_lists[normal]
		for j in 3:triangle.append(vertices[indices[i+j]]*7.0)
		face_lists[normal]=triangle
	for normal:Vector3 in face_lists:
		var group:=film_group();group.position=Vector3(0,1.5,0);faces.append(group);directions.append(normal)
		film_triangles(face_lists[normal],Color(CHALK,.78),group)
		var wire:=film_group(group);edges.append(wire)
		var pairs:=PackedVector3Array();var known:Dictionary={}
		var triangles:PackedVector3Array=face_lists[normal]
		for i in range(0,triangles.size(),3):
			for j in 3:
				pairs.append(triangles[i+j]);pairs.append(triangles[i+(j+1)%3])
				known[triangles[i+j].snapped(Vector3.ONE*.00001)]=true
		add_lines(pairs,SLATE,wire)
		for v:Vector3 in known:
			var dot:=add_ball(v,.035,TEAL,group);points.append(dot)
	crown=film_group();add_ball(anchor_position,.105,GOLD,crown)
	add_rod(anchor_position,anchor_position+Vector3(0,.48,0),.022,GOLD,crown)
	add_rod(anchor_position+Vector3(0,.48,0),Vector3(0,anchor_position.y+.48,-1.8),.035,SLATE,crown)
	evidence={"vertices":vertices.size(),"triangles":indices.size()/3,"unique_positions":unique.size(),"faces":face_lists.size(),"subdivisions":source.subdivisions,"anchor_index":anchor,"anchor_position":vertices[anchor],"cube_size":source.cube_size,"actual_pin":source._soft_body.is_point_pinned(anchor),"source_calls":["_create_soft_body","_configure_anchor"],"source_never_entered_tree":true}
	source.free()
	readout=add_label("",Vector3(0,3.78,0),CHALK)
	film_deck();frame_scene(Vector3(0,1.5,0),10.3,.5,.26)
func _draw(time:float)->void:
	var phase:=phase_index(time);var u:=phase_progress(time)
	var spread:=0.0 if phase==0 else (.7*u if phase==1 else (.7 if phase==2 else .7*(1-smoothstep(0,.5,u))))
	for i in faces.size():faces[i].position=Vector3(0,1.5,0)+directions[i]*spread
	for node in points:node.visible=phase>0
	for edge in edges:edge.visible=phase>=2
	crown.visible=phase==3 and u>.5
	readout.text="%d VERTEX ENTRIES / %d POSITIONS / %d TRIANGLES"%[evidence.vertices,evidence.unique_positions,evidence.triangles] if phase<3 else "CROWN ANCHOR / ENTRY %d"%evidence.anchor_index
