extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Fixed node pool. The road passes a stationary cockpit; no accumulated world drift.
const MODEL=preload("res://commons/artifacts/endless_racer/race_model.gd")
var sections: Array[Node3D]=[]
var cars: Array[Node3D]=[]
var features: Array[Node3D]=[]
var cube_material: Material
var barrier_material: Material

func _ready() -> void:
	var asphalt=material("19202d");var white=material("eff1de");var rose=material("ef79af",true);var cyan=material("6de4d5",true)
	cube_material=material("e3b55e",true);barrier_material=material("ce4971")
	box(Vector3(0,-0.55,-150),Vector3(650,0.3,650),material("121926"))
	for i in range(MODEL.POOL):
		var section=Node3D.new();add_child(section);sections.append(section)
		box(Vector3(0,-0.10,0),Vector3(10,0.18,MODEL.SECTION+0.06),asphalt,false,section)
		for x in [-5.15,5.15]:
			box(Vector3(x,0.36,0),Vector3(0.18,0.72,MODEL.SECTION+0.1),white,false,section)
			box(Vector3(x,0.73,0),Vector3(0.21,0.06,MODEL.SECTION+0.1),rose if x<0 else cyan,false,section)
		for z in [-6,-2,2,6]:
			box(Vector3(0,0.012,z),Vector3(0.1,0.015,1.8),white,false,section)
		for x in [-12,12]:
			box(Vector3(x,3.0,0),Vector3(1.5,6,1.5),white,false,section)
			box(Vector3(x,5.9,0),Vector3(1.6,0.16,1.6),cyan if x<0 else rose,false,section)
		var arch=Node3D.new();section.add_child(arch);cars.append(arch)
		for x in [-5.3,5.3]:box(Vector3(x,3.1,0),Vector3(0.22,6.2,0.22),cyan,false,arch)
		box(Vector3(0,6.2,0),Vector3(10.8,0.22,0.22),cyan,false,arch)
		var item=box(Vector3(0,0.65,0),Vector3.ONE*0.8,cube_material,false,section);features.append(item)

func sync(model: RefCounted) -> void:
	var first:=int(floor(model.distance/MODEL.SECTION))-2
	var eye_centre: float=model.centre(model.distance)+model.offset
	for i in sections.size():
		var index:=first+i;var s:=float(index)*MODEL.SECTION
		var a:=Vector3(model.centre(s)-eye_centre,0,model.distance-s)
		var b:=Vector3(model.centre(s+MODEL.SECTION)-eye_centre,0,model.distance-s-MODEL.SECTION)
		var node=sections[i];node.position=(a+b)*0.5
		node.rotation.y=atan2(-(b-a).x,-(b-a).z)
		node.scale.z=a.distance_to(b)/MODEL.SECTION
		cars[i].visible=posmod(index,8)==0
		var item: Dictionary=model.feature(index)
		features[i].visible=not item.is_empty() and not model.consumed.has(index)
		if not item.is_empty():
			# The section local x agrees with the road's right side.
			features[i].position.x=item.lane
			features[i].material_override=cube_material if item.kind=="cube" else barrier_material
			features[i].scale=Vector3.ONE if item.kind=="cube" else Vector3(2,1.5,1)
			features[i].rotation.y=0.3 if item.kind=="cube" else 0
