extends Node3D
## A receiving platform below the downward Boolean passage, with a west exit.
const Parts = preload("res://commons/artifacts/rotation_studies/parts.gd")
func _ready() -> void:
	var pad:=Parts.box(self,"Landing",Vector3(3.0,.25,3.0),Vector3(0,-.125,0),Color("d2c2a5"))
	pad.get_node("Body").set_meta("void_floor_surface",true)
	var exit:=Parts.box(self,"Exit",Vector3(1.5,.25,1.4),Vector3(-2.25,-.125,0),Color("d2c2a5"))
	exit.get_node("Body").set_meta("void_floor_surface",true)
	var text:=Parts.label(self,"LAND / CONTINUE WEST",Vector3(0,.01,0),24)
	text.rotation_degrees=Vector3(-90,180,0)
