extends Node3D
## Sparse, floor-local construction cells. Static geometry is batched by kind;
## collision is retained separately, while tc remains a real moving body.
const Cube = preload("res://commons/artifacts/primitive_encounters/platform_block.tscn")
const Wedge = preload("res://commons/artifacts/primitive_encounters/wedge_blocker.tscn")
const Carrier = preload("res://commons/void/trials/transformation/suspended_carrier.gd")
const Steel = preload("res://commons/void/steel_module.gd")
const Rotary = preload("res://commons/void/rotating_platform.gd")
var items: Array = []
var carriers: Dictionary = {}

func _ready() -> void:
	for kind in ["cube","slab","wedge","truss","deck","support","collar"]:
		var cells := items.filter(func(p): return p.kind==kind)
		if cells.is_empty(): continue
		var source: Node3D
		if kind in ["truss","deck","support","collar"]:
			source = Steel.new()
			source.kind = kind
		else:
			source = (Wedge if kind=="wedge" else Cube).instantiate()
		if kind=="slab": source.platform_size=Vector3(1,.25,1)
		add_child(source)
		var body := StaticBody3D.new()
		body.name = kind.capitalize()+"Collision"
		add_child(body)
		for mesh_node in source.find_children("*","MeshInstance3D",true,false):
			var mesh_transform: Transform3D = source.global_transform.affine_inverse()*mesh_node.global_transform
			var batch := MultiMeshInstance3D.new()
			batch.name=kind.capitalize()+mesh_node.name
			batch.multimesh=MultiMesh.new()
			batch.multimesh.transform_format=MultiMesh.TRANSFORM_3D
			batch.multimesh.mesh=mesh_node.mesh
			batch.material_override=mesh_node.material_override
			batch.multimesh.instance_count=cells.size()
			add_child(batch)
			for i in cells.size(): batch.multimesh.set_instance_transform(i,_pose(cells[i])*mesh_transform)
		for cell in cells:
			for original in source.find_children("*","CollisionShape3D",true,false):
				var shape := CollisionShape3D.new()
				shape.name=cell.id
				shape.shape=original.shape
				shape.transform=_pose(cell)*source.global_transform.affine_inverse()*original.global_transform
				body.add_child(shape)
		source.free()
	for cell in items:
		if cell.kind=="rotating_platform":
			var rotary := Rotary.new()
			rotary.name=cell.id
			rotary.transform=_pose(cell)
			rotary.deck_length=float(cell.get("length",8))
			rotary.rotation_angle=float(cell.get("angle",-90))
			rotary.rotation_speed=float(cell.get("turn_speed",9))
			rotary.pause_duration=float(cell.get("pause",6))
			add_child(rotary)
			carriers[cell.id]=rotary
			continue
		if cell.kind!="platform": continue
		var carrier := Carrier.new()
		carrier.name=cell.id
		carrier.transform=_pose(cell)
		carrier.displacement=_vector(cell.get("travel",[0,0,-8]))
		carrier.speed=float(cell.get("speed",1.0))
		carrier.pause=float(cell.get("pause",4.0))
		add_child(carrier)
		carriers[cell.id]=carrier

func _vector(values: Array) -> Vector3:
	return Vector3(float(values[0]),float(values[1]),float(values[2]))

func _pose(cell: Dictionary) -> Transform3D:
	return Transform3D(Basis(Vector3.UP,deg_to_rad(float(cell.facing))),_vector(cell.position))

func prepare_editor_preview() -> void:
	for carrier in carriers.values(): carrier.prepare_editor_preview()
