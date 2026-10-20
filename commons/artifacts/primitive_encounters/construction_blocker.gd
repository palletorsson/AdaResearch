extends Node3D
## Building versions of the alignment solids. Metres; root on the floor.
const Kit = preload("geometry.gd")
const Finish = preload("construction_finish.gd")
const WalkablePrism = preload("res://commons/scenes/mapobjects/walkableprism.tscn")
@export_enum("tetrahedron", "pyramid", "wedge", "platform") var kind := "tetrahedron"
@export var platform_size := Vector3.ONE

func _ready() -> void:
	set_meta("construction_definition", "wp" if kind=="wedge" else "structure_2" if kind=="platform" else kind+"_blocker")
	if kind=="wedge":
		# Preserve the original wp mesh AND collision, with a floor-centred adapter.
		# Its embedded -0.5 Z offset is cancelled; this version rises towards +Z.
		var ramp := WalkablePrism.instantiate() as Node3D
		ramp.name="OriginalWP"
		ramp.position=Vector3(0,0.5,0.5)
		add_child(ramp)
		var visible := ramp.get_node("StaticBody3D/prism") as MeshInstance3D
		visible.mesh=Finish.mesh(visible.mesh)
		visible.material_override=Finish.material()
		set_meta("low_join",Vector3(0,0,-1))
		set_meta("high_join",Vector3(0,1,1))
		return
	if kind=="platform":
		Kit.box(self,"Platform",Vector3.UP*platform_size.y/2.0,platform_size,Color("b8b5ab"))
		if platform_size.is_equal_approx(Vector3.ONE):
			# Inset edge marks keep each metre legible without gaps or extra collision.
			var edges := SurfaceTool.new()
			edges.begin(Mesh.PRIMITIVE_TRIANGLES)
			for axis in 3:
				for a in [-1,1]:
					for b in [-1,1]:
						var at := Vector3.ZERO
						at[(axis+1)%3]=a*.496
						at[(axis+2)%3]=b*.496
						at.y+=.5
						var size := Vector3.ONE*.008
						size[axis]=1.0
						var edge := BoxMesh.new()
						edge.size=size
						edges.append_from(edge,0,Transform3D(Basis.IDENTITY,at))
			var joints := MeshInstance3D.new()
			joints.name="MetreJoints"
			joints.mesh=edges.commit()
			joints.material_override=Kit.material(Color("49444b"))
			add_child(joints)
			set_meta("vertex_count",8)
			set_meta("face_count",6)
		return
	var vertices := Kit.tetra()
	var faces: Array = Kit.tetra_faces()
	if kind=="tetrahedron":
		for i in range(vertices.size()): vertices[i]=(vertices[i]+Vector3(0,0.26,-.12971))*1.8
	else:
		vertices=PackedVector3Array([Vector3(-.75,0,-.75),Vector3(.75,0,-.75),Vector3(.75,0,.75),Vector3(-.75,0,.75),Vector3(0,1.3,0)])
		faces=[[0,3,2,1],[0,1,4],[1,2,4],[2,3,4],[3,0,4]]
	var body := Kit.solid(self,"Solid",vertices,faces,Color.WHITE)
	body.mesh=Finish.mesh(body.mesh)
	body.material_override=Finish.material()
	set_meta("vertex_count",vertices.size())
	set_meta("face_count",faces.size())
