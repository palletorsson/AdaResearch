extends "res://commons/void/lines_area.gd"
## Familiar blue barriers pass from tabletop toys to architectural bodies.
## The source scene, sign, feet and solid collider scale together. Static
## arrangement: no automatic animation, falling-body or domino claim.
const SourceBarrier = preload("res://commons/artifacts/do_not_cross_barrier/do_not_cross_barrier.gd")
const Kit = preload("res://commons/artifacts/movable_pivot/mechanism.gd")
const Timber = preload("res://commons/artifacts/primitive_encounters/timber_finish.gd")
const Finish = preload("res://commons/artifacts/machine_finish.gd")
const SCALES := [.14,.20,.29,.43,.64,.95,1.35,1.9,2.5]
const BASES := [.80,.80,.80,.53,.25,0,0,0,0]
const ALONG := [-4.0,-3.65,-3.30,-2.55,-1.7,-.6,.7,2.1,3.6]
var specimens: Array[Node3D] = []

func _ready() -> void:
	var table:=Node3D.new();table.name="ScaleTable";table.position.z=-3.7;add_child(table)
	Kit.box(table,"StandardSheet",Vector3(2.44,.06,1.22),Vector3(0,.77,0),Timber.material(),true)
	for x in [-.84,.84]:
		Kit.box(table,"TemporaryBlock",Vector3(.46,.74,.7),Vector3(x,.37,0),Finish.ivory(),true)
	# Two progressively lower packing blocks continue the tabletop towards the
	# floor. This stages growth downwards before the last three rise above B.
	for row in [["LowerSupport01",3,.53,.43],["LowerSupport02",4,.25,.64]]:
		var index:=int(row[1]);var height:=float(row[2]);var factor:=float(row[3])
		var support:=Node3D.new();support.name=row[0];support.position.z=ALONG[index];add_child(support)
		Kit.box(support,"PackingBlock",Vector3(2.2*factor+.10,height,.46),Vector3(0,height*.5,0),Finish.ivory(),true)
		Kit.box(support,"TimberCap",Vector3(2.2*factor+.14,.025,.48),Vector3(0,height-.0125,0),Timber.material())
	for i in SCALES.size():
		var part:=Node3D.new();part.name="GrowingBarrier%02d"%(i+1);part.position=Vector3(0,BASES[i],ALONG[i]);add_child(part);specimens.append(part)
		var barrier:=SourceBarrier.new();barrier.name="BlueDoNotCross";barrier.form="sawhorse";barrier.span_m=2.2;barrier.height_m=1.15
		barrier.solid=true;barrier.scale=Vector3.ONE*SCALES[i];part.add_child(barrier)
	for child in get_children():
		if child is Node3D:
			var b:=_mesh_bounds(child,child)
			part_defaults[str(child.name)]={"position":[child.position.x,child.position.y,child.position.z],"rotation":[child.rotation_degrees.x,child.rotation_degrees.y,child.rotation_degrees.z],"bounds":[b.position.x,b.position.y,b.position.z,b.size.x,b.size.y,b.size.z]}

func prepare_editor_preview() -> void:
	pass
