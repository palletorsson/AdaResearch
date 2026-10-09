extends Node3D
const Kit = preload("res://commons/artifacts/ignorance_gallery/gallery_kit.gd")
const TYPES = ["PrismMesh","TorusMesh","PlaneMesh","QuadMesh","PointMesh","TextMesh","RibbonTrailMesh","TubeTrailMesh"]
const NOTES = ["A WEDGE","A HOLE THROUGH THE FORM","A SUBDIVIDED SURFACE","TWO TRIANGLES","ONE VERTEX / 22 SCREEN PIXELS","LETTERS WITH DEPTH","A TRAIL'S REST SHAPE","A TRAIL'S REST SHAPE"]
var prefabs: Array[Node3D]=[]

func _ready() -> void:
	for i in TYPES.size():
		var at := Vector3(-4 if i%2==0 else 4,0,-4.2+float(i/2)*2.8)
		Kit.pedestal(self,at,0.82,1.65)
		var scene: PackedScene=load("res://commons/artifacts/ignorance_gallery/prefabs/"+str(TYPES[i])+".tscn")
		var node: Node3D=scene.instantiate();add_child(node)
		node.position=at+Vector3.UP*1.48;prefabs.append(node)
		Kit.label(self,TYPES[i],at+Vector3(0,0.58,-0.831),0.0019,PI)
		Kit.label(self,NOTES[i],at+Vector3(0,0.37,-0.832),0.0011,PI)
	Kit.label(self,"FORMS THE ENGINE GIVES US",Vector3(0,2.9,5.7),0.0040,PI)
	for x in [-4,4]:Kit.lamp(self,Vector3(x,3.1,0),1.2,9)
