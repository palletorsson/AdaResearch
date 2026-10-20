extends Node3D
## A reusable bolted chevron bay. Geometry only; no structural-load simulation.
@export var span := 5.1
@export var rise := 5.0
var members: Array[Node3D] = []

func _ready() -> void:
	var steel := material(Color("8e5142"),0.65)
	var dark := material(Color("303239"),0.75)
	var ends := [Vector3(-span/2,0.20,0),Vector3(0,rise+0.20,0),Vector3(span/2,0.20,0)]
	for pair in [[0,1],[1,2],[2,0]]:
		members.append(beam(ends[pair[0]],ends[pair[1]],steel))
	for at in ends:
		box(self,at+Vector3(0,0,.16),Vector3(.48,.43,.035),dark)
		for x in [-.15,.15]:
			for y in [-.12,.12]:
				var bolt := MeshInstance3D.new()
				var head := CylinderMesh.new()
				head.top_radius=.025;head.bottom_radius=.025;head.height=.035;head.radial_segments=6
				bolt.mesh=head;bolt.material_override=dark
				bolt.position=at+Vector3(x,y,.20);bolt.rotation.x=PI/2;add_child(bolt)
	for x in [-span/2,span/2]: box(self,Vector3(x,.025,0),Vector3(.55,.05,.65),dark)

func beam(a: Vector3, b: Vector3, mat: Material) -> Node3D:
	var body := StaticBody3D.new()
	body.name="SteelMember"+str(members.size()+1)
	body.collision_layer=1;body.collision_mask=0
	body.transform=Transform3D(Basis(Quaternion(Vector3.UP,(b-a).normalized())),(a+b)/2)
	add_child(body)
	var length := a.distance_to(b)
	box(body,Vector3.ZERO,Vector3(.025,length,.24),mat)
	for z in [-.125,.125]: box(body,Vector3(0,0,z),Vector3(.24,length,.028),mat)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new();shape.size=Vector3(.24,length,.278)
	collision.shape=shape;body.add_child(collision)
	return body

static func box(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new();var mesh := BoxMesh.new();mesh.size=size
	node.mesh=mesh;node.material_override=mat;node.position=at;parent.add_child(node)
	return node

static func material(colour: Color, metal := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new();mat.albedo_color=colour;mat.metallic=metal;mat.roughness=.72
	return mat
