extends Node3D
## A repeated rectangular portal. Each piece is cut by the common union of
## openings, then trimmed against previous outers to expose clean module joints.
const Cube=preload("res://algorithms/primitives/booleans/booleanHollowCube.tscn")
var spec: Dictionary={}
var ready_mesh:=false
var failed:=false

static func make(value: Dictionary) -> Node3D:
	var n=load("res://commons/modular/portal_piece.gd").new();n.spec=value.duplicate(true);return n

func pose(value: Dictionary) -> Transform3D:
	var a: Array=value.at;var r: Array=value.rot
	return Transform3D(Basis.from_euler(Vector3(deg_to_rad(r[0]),deg_to_rad(r[1]),deg_to_rad(r[2]))),Vector3(a[0],a[1],a[2]))

func box(size: Vector3,frame: Transform3D,material: Material) -> CSGBox3D:
	var n:=CSGBox3D.new();n.size=size;n.transform=frame;n.material=material;return n

func _ready() -> void:
	var original: Node=Cube.instantiate();var subtraction: int=original.get_node("outer/inner").operation;original.free()
	var index: int=int(spec.get("index",0));var poses: Array=spec.poses
	var depth: float=float(spec.get("depth",1.35));var width: float=float(spec.get("width",1.6));var height: float=float(spec.get("headroom",2.8));var wall: float=float(spec.get("wall",.35))
	var outside:=StandardMaterial3D.new();outside.albedo_color=Color("48434d") if index%2 else Color("28242e");outside.metallic=.2;outside.roughness=.55
	var inside:=StandardMaterial3D.new();inside.albedo_color=Color("e1ede8");inside.roughness=.7
	var boolean:=CSGCombiner3D.new();boolean.name="PortalMinusSharedOpenings";add_child(boolean)
	var outer_size:=Vector3(width+2*wall,height+2*wall,depth)
	boolean.add_child(box(outer_size,Transform3D.IDENTITY,outside))
	var inverse: Transform3D=pose(poses[index]).affine_inverse()
	if index>0:
		var trim:=CSGCombiner3D.new();trim.operation=subtraction;boolean.add_child(trim)
		for i in index:trim.add_child(box(outer_size,inverse*pose(poses[i]),outside))
	var openings:=CSGCombiner3D.new();openings.operation=subtraction;boolean.add_child(openings)
	for value in poses:openings.add_child(box(Vector3(width,height,depth+.5),inverse*pose(value),inside))
	set_meta("source_artifact","boolean_tunnel");set_meta("portal_index",index);set_meta("shared_openings",poses.size());set_meta("outer_size",outer_size)
	for frame in 120:
		await get_tree().process_frame
		var meshes: Array=boolean.get_meshes()
		if frame>=3 and meshes.size()==2 and meshes[1]!=null:
			var mesh:=MeshInstance3D.new();mesh.name="PortalResult";mesh.mesh=meshes[1];mesh.transform=meshes[0];boolean.free();add_child(mesh)
			var body:=StaticBody3D.new();var hit:=CollisionShape3D.new();hit.shape=mesh.mesh.create_trimesh_shape();hit.transform=mesh.transform;body.add_child(hit);add_child(body)
			if bool(spec.get("mark",false)):
				var marker:=MeshInstance3D.new();marker.name="OrientationCorner";var cube:=BoxMesh.new();cube.size=Vector3(wall*.6,wall*.6,.04);marker.mesh=cube
				var pink:=StandardMaterial3D.new();pink.albedo_color=Color("ee6cae");pink.emission_enabled=true;pink.emission=Color("9a285e");pink.emission_energy_multiplier=.3;marker.material_override=pink
				marker.position=Vector3(-width/2-wall/2,height/2+wall/2,depth/2+.025);add_child(marker)
			ready_mesh=true;return
	failed=true;push_error("Portal Boolean did not finish: "+str(index))

func prepare_editor_preview() -> void:
	while not ready_mesh and not failed:await get_tree().process_frame
