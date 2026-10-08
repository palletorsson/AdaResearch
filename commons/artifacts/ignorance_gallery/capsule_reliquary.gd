extends Node3D
const Kit = preload("res://commons/artifacts/ignorance_gallery/gallery_kit.gd")
var tiers: Array[MeshInstance3D]=[]
var capsule: Node3D
var body: MeshInstance3D

func _ready() -> void:
	var architecture = preload("res://commons/artifacts/ignorance_gallery/gallery_architecture.gd")
	architecture.bay(self,13.0,-1.0)
	architecture.pentagon(self,Vector3(-3.3,2.2,4.1))
	Kit.label(self,"ENDLESS MUSEUM",Vector3(3.2,2.65,4.1),0.0032,PI)
	Kit.label(self,"always another room",Vector3(3.2,2.32,4.09),0.002,PI)
	for i in 8:
		var height := 0.13
		var radius := lerpf(1.55,0.62,float(i)/7.0)
		tiers.append(Kit.cylinder(self,Vector3(0,height*(i+0.5),0),radius,height,i+4))
		Kit.label(self,str(i+4),Vector3(0,height*(i+0.5),-radius-0.006),0.0014,PI)
	capsule=load("res://commons/primitives/capsule/capsule.tscn").instantiate()
	capsule.facture="facet" # Existing flat-face view of the same five-by-five construction.
	add_child(capsule)
	body=capsule.get_node("capsule")
	body.scale=Vector3.ONE*1.6
	body.material_override=Kit.material(Kit.BLACK)
	capsule.position=Vector3(0,1.04+0.8,0)
	# Preserve the authored five-by-five mesh and its 45-degree/second turn.
	for child in capsule.get_children():
		if child is Light3D:child.visible=false
	Kit.lamp(self,Vector3(-1.4,3.2,-1.5),1.6,6)
	Kit.lamp(self,Vector3(1.8,2.8,1.5),1.2,6)
	Kit.label(self,"FIVE",Vector3(0,0.11,-1.64),0.0028,PI)
