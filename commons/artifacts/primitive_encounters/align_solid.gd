extends Node3D
const Kit=preload("geometry.gd")
const Piece=preload("piece.gd")
const Finish=preload("construction_finish.gd")
@export_enum("tetrahedron","wedge") var kind: String="tetrahedron"
var vertices: PackedVector3Array
var faces: Array
var handle: XRToolsPickable
var shell: MeshInstance3D
var target: MeshInstance3D
var solid_body: XRToolsPickable
var label: Label3D
var complete:=false
var moving_index:=3
var target_position:=Vector3.ZERO
var previous:=Vector3.INF
var instruction: Label3D
var guides: Node3D
var edges: Array = []
var edge_bodies: Array[MeshInstance3D] = []
var ready_to_close := false
signal completed()
func _ready() -> void:
	# The handheld wedge is the wp's 1:1:2 proportions at 55 percent size.
	vertices=Kit.tetra() if kind=="tetrahedron" else Kit.wedge(.55,.55,1.1)
	faces=Kit.tetra_faces() if kind=="tetrahedron" else Kit.wedge_faces()
	moving_index=3 if kind=="tetrahedron" else 5
	target_position=vertices[moving_index]+Vector3.UP*1.15
	handle=Piece.new();handle.name="LooseVertex"
	handle.position=target_position+Vector3(0.48,0.23,0.12)
	var s:=SphereMesh.new();s.radius=0.065;s.height=0.13
	var m:=MeshInstance3D.new();m.mesh=s;m.material_override=Kit.material(Color("d74282"));handle.add_child(m)
	var c:=CollisionShape3D.new();var shape:=SphereShape3D.new();shape.radius=0.085;c.shape=shape;handle.add_child(c)
	handle.dropped.connect(_released);add_child(handle)
	target=MeshInstance3D.new();target.name="TargetRing"
	var ring:=TorusMesh.new();ring.inner_radius=0.085;ring.outer_radius=0.105
	var ring_material := Kit.material(Color("a7f0d5"))
	ring_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.no_depth_test=true
	target.mesh=ring;target.position=target_position;target.rotation.x=PI/2
	target.material_override=ring_material;add_child(target)
	shell=MeshInstance3D.new();shell.name="UnfinishedSurface";shell.position.y=1.15
	var mat:=Kit.material(Color(0.74,0.66,0.84,0.62));mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED;shell.material_override=mat;add_child(shell)
	label=Kit.label(self,"TETRAHEDRON" if kind=="tetrahedron" else "WEDGE",Vector3(0,0.015,1.1),33)
	label.rotation.x=-PI/2
	guides=Node3D.new();guides.name="CornersAndEdges";add_child(guides)
	for i in range(vertices.size()):
		if i==moving_index: continue
		var marker:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=.032;sphere.height=.064
		marker.mesh=sphere;marker.position=vertices[i]+Vector3.UP*1.15
		marker.material_override=Kit.material(Color("9ad9e5"));guides.add_child(marker)
	var seen: Dictionary={}
	for face in faces:
		for i in range(face.size()):
			var a: int=face[i];var b: int=face[(i+1)%face.size()]
			var key := "%d:%d"%[mini(a,b),maxi(a,b)]
			if seen.has(key): continue
			seen[key]=true;edges.append([a,b])
			var edge:=MeshInstance3D.new();var cylinder:=CylinderMesh.new()
			cylinder.top_radius=.009;cylinder.bottom_radius=.009;cylinder.height=1;cylinder.radial_segments=6
			edge.mesh=cylinder;edge.material_override=Kit.material(Color("dce5e7"))
			guides.add_child(edge);edge_bodies.append(edge)
	Kit.box(self,"InstructionBack",Vector3(0,2.05,-.8),Vector3(1.9,.7,.055),Color("292d31"),false)
	instruction=Kit.label(self,"",Vector3(0,2.05,-.765),28)
	instruction.name="Instruction";instruction.modulate=Color("f0e9d9");instruction.no_depth_test=false
	_update_instruction(false)
func _process(_delta: float) -> void:
	if complete:return
	var p:=to_local(handle.global_position)-Vector3.UP*1.15
	if p.is_equal_approx(previous):return
	previous=p;var current:=vertices.duplicate();current[moving_index]=p
	shell.mesh=Kit.mesh(current,faces)
	for i in range(edges.size()):
		var a: Vector3=current[edges[i][0]]+Vector3.UP*1.15
		var b: Vector3=current[edges[i][1]]+Vector3.UP*1.15
		var edge: MeshInstance3D=edge_bodies[i]
		edge.position=(a+b)*.5;edge.scale=Vector3(1,maxf(a.distance_to(b),.001),1)
		if a.distance_squared_to(b)>.000001: edge.quaternion=Quaternion(Vector3.UP,a.direction_to(b))
	var near := handle.global_position.distance_to(to_global(target_position))<0.12
	target.scale=Vector3.ONE*(1.2 if near else 1.0)
	if near!=ready_to_close:
		ready_to_close=near;_update_instruction(near)

func _update_instruction(near: bool) -> void:
	var title := "TETRAHEDRON / 4 VERTICES / 4 FACES" if kind=="tetrahedron" else "WEDGE / 6 VERTICES / 5 FACES"
	var action := "Release here to complete the solid." if near else "Grab the pink corner. Bring it to the ring."
	if complete: action="Pick up the solid.\nIts larger striped version can block a path." if kind=="tetrahedron" else "Pick up the solid.\nThe same profile becomes the walking ramp."
	instruction.text=title+"\n"+action
func _released(_body: Node) -> void:
	if complete or handle.global_position.distance_to(to_global(target_position))>0.12:return
	finish.call_deferred()
func finish() -> void:
	if complete:return
	complete=true;handle.visible=false;handle.collision_layer=0;handle.collision_mask=0
	target.hide();shell.hide();guides.hide()
	solid_body=Piece.new();solid_body.name="CompletedSolid";solid_body.floats=false
	solid_body.freeze=false;solid_body.release_mode=XRToolsPickable.ReleaseMode.UNFROZEN
	solid_body.position.y=1.15
	var visible := Kit.solid(solid_body,"Surface",vertices,faces,Color.WHITE,false)
	visible.mesh=Finish.mesh(visible.mesh,.10);visible.material_override=Finish.material()
	var shape:=ConvexPolygonShape3D.new();shape.points=vertices
	var col:=CollisionShape3D.new();col.shape=shape;solid_body.add_child(col)
	add_child(solid_body);label.text="TETRAHEDRON / COMPLETE" if kind=="tetrahedron" else "WEDGE / COMPLETE"
	_update_instruction(false)
	completed.emit()
