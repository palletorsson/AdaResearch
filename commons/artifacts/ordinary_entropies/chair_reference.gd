extends Node3D
## A full-size specimen establishes the object before either counting question.
const Objects=preload("objects.gd")
func _ready() -> void:
	Objects.box(self,Vector3(0,1.15,-0.10),Vector3(2.4,2.3,0.18),Color("d4d0c2"),true)
	# A full-size chair belongs on the visitor's floor, without an inaccessible shelf.
	var chair:=preload("physical_chair.gd").new()
	chair.name="ReferenceChair";chair.position=Vector3(0,0.01,0.40);add_child(chair)
	Objects.ink(self,"ONE CHAIR / TWO QUESTIONS",Vector3(0,1.96,0.015),32,0.0019)
	Objects.ink(self,"Colour: what could the next draw be?\nArrangement: how many fit the same brief?",Vector3(0,1.75,0.015),25,0.0018)
	Objects.ink(self,"Full-size chair, on the same floor.\nPink and black count as two colours.",Vector3(0,1.48,0.015),25,0.0018)
