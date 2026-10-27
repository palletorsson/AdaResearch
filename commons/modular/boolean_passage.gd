extends Node3D
## Boolean Tunnel lineage: one swept outer solid minus one continuous swept bore.
## The original hollow-cube scene supplies opening defaults and the subtraction rule.
const HollowCube=preload("res://algorithms/primitives/booleans/booleanHollowCube.tscn")
const Sweep=preload("res://commons/modular/mod_sweep.gd")
var spec: Dictionary={}
var ready_mesh:=false
var result_mesh: MeshInstance3D
var solid_materials: Array[StandardMaterial3D]=[]

static func make(value: Dictionary) -> Node3D:
	var node=load("res://commons/modular/boolean_passage.gd").new()
	node.spec=value.duplicate(true)
	var point: Array=value.path[0];node.position=Vector3(point[0],point[1],point[2])
	node.set_meta("sweep_path",value.path)
	node.set_meta("source_artifact","boolean_tunnel")
	return node

func profile(left: float,bottom: float,right: float,top: float) -> Array:
	return [[left,bottom],[right,bottom],[right,top],[left,top]]

func operand(path: Array,polygon: Array,material: Material,origin: Vector3) -> CSGMesh3D:
	var raw: Node3D=Sweep.make({"path":path,"profile":polygon,"collide":false})
	var mesh: Mesh=raw.get_node("Surface").mesh
	var node:=CSGMesh3D.new();node.mesh=mesh;node.material=material
	node.position=raw.position-origin;raw.free();return node

func _ready() -> void:
	var original: Node=HollowCube.instantiate()
	var source_outer: CSGBox3D=original.get_node("outer")
	var source_hole: CSGBox3D=original.get_node("outer/inner")
	var source_operation: int=source_hole.operation
	var path: Array=spec.path.duplicate(true)
	var origin:=Vector3(path[0][0],path[0][1],path[0][2])
	var width: float=float(spec.get("width",source_hole.size.x))
	var height: float=float(spec.get("headroom",source_hole.size.y))
	var wall: float=float(spec.get("wall",(source_outer.size.y-source_hole.size.y)/2))
	var wall_x: float=float(spec.get("wall_x",wall))
	# Preserve the original black / pink / cyan palette, but use smooth study
	# materials: its per-triangle wire shader becomes unreadably dense after CSG.
	var exterior:=StandardMaterial3D.new();exterior.albedo_color=Color("24212c");exterior.metallic=.35;exterior.roughness=.5
	var interior:=StandardMaterial3D.new();interior.albedo_color=Color("dce9e6");interior.roughness=.7
	set_meta("source_operation",original.get_node("outer/inner").operation)
	original.free()
	solid_materials=[exterior,interior]
	var boolean:=CSGCombiner3D.new();boolean.name="OuterMinusContinuousBore";add_child(boolean)
	var outer:=operand(path,profile(-width/2-wall_x,-wall,width/2+wall_x,height+wall),exterior,origin)
	outer.name="OuterSolid";boolean.add_child(outer)
	var bore: Array=path.duplicate(true)
	var first:=Vector3(bore[0][0],bore[0][1],bore[0][2]);var second:=Vector3(bore[1][0],bore[1][1],bore[1][2])
	var last:=Vector3(bore[-1][0],bore[-1][1],bore[-1][2]);var previous:=Vector3(bore[-2][0],bore[-2][1],bore[-2][2])
	first+=(first-second).normalized()*.5;last+=(last-previous).normalized()*.5
	bore[0]=[first.x,first.y,first.z];bore[-1]=[last.x,last.y,last.z]
	var inner:=operand(bore,profile(-width/2,0,width/2,height),interior,origin)
	inner.name="ContinuousBore";inner.operation=source_operation;boolean.add_child(inner)
	set_meta("boolean_operands",2);set_meta("bore_points",path.size())
	# Godot CSG owns the subtraction. Freeze its actual result into one mesh and
	# collider, so export and native contact use the exact same Boolean surface.
	for frame in 120:
		await get_tree().process_frame
		var meshes: Array=boolean.get_meshes()
		if frame>=3 and meshes.size()==2 and meshes[1]!=null:
			result_mesh=MeshInstance3D.new();result_mesh.name="BooleanResult";result_mesh.mesh=meshes[1];result_mesh.transform=meshes[0]
			boolean.free();add_child(result_mesh)
			var body:=StaticBody3D.new();body.name="BooleanCollision"
			var hit:=CollisionShape3D.new();hit.shape=result_mesh.mesh.create_trimesh_shape();hit.transform=result_mesh.transform
			var physics:=PhysicsMaterial.new();physics.friction=.25;physics.bounce=0;body.physics_material_override=physics
			body.add_child(hit);add_child(body);ready_mesh=true
			set_xray(bool(spec.get("xray",true)));return
	push_error("Boolean passage did not produce a mesh")

func set_xray(enabled: bool) -> void:
	if solid_materials.is_empty():return
	solid_materials[0].transparency=BaseMaterial3D.TRANSPARENCY_ALPHA if enabled else BaseMaterial3D.TRANSPARENCY_DISABLED
	solid_materials[0].albedo_color.a=.12 if enabled else 1.0

func prepare_editor_preview() -> void:
	while not ready_mesh:await get_tree().process_frame
