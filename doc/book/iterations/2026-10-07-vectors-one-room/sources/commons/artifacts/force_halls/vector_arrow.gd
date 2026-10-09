extends Node3D
## Solid geometry allocated once. Dragging changes only these transforms.
var shaft: MeshInstance3D
var head: MeshInstance3D
var from_point := Vector3.ZERO
var to_point := Vector3.ZERO
var arrowhead := true

func build(ink: Material, radius := 0.014, with_head := true) -> void:
	arrowhead=with_head
	shaft=MeshInstance3D.new()
	var tube=CylinderMesh.new()
	tube.top_radius=radius; tube.bottom_radius=radius; tube.height=1.0
	tube.radial_segments=12; tube.rings=1
	shaft.mesh=tube; shaft.material_override=ink; add_child(shaft)
	head=MeshInstance3D.new()
	var cone=CylinderMesh.new()
	cone.top_radius=0.0; cone.bottom_radius=radius*3.3; cone.height=1.0
	cone.radial_segments=12; cone.rings=1
	head.mesh=cone; head.material_override=ink; add_child(head)
	visible=false

func set_ends(start: Vector3, end: Vector3) -> void:
	from_point=start; to_point=end
	var displacement=end-start
	var length=displacement.length()
	visible=length>0.0001 and displacement.is_finite()
	if not visible:return
	position=start
	quaternion=Quaternion(Vector3.UP,displacement/length)
	var tip=minf(0.12,length*0.22) if arrowhead else 0.0
	shaft.scale.y=length-tip
	shaft.position.y=(length-tip)*0.5
	head.visible=arrowhead
	if arrowhead:
		head.scale.y=tip
		head.position.y=length-tip*0.5
