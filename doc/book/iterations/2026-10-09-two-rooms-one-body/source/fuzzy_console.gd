extends "res://commons/artifacts/camera_glitch_study/glitch_console.gd"

var width_dial: Node3D
var force_dial: Node3D
var cut_dial: Node3D

func _ready() -> void:
	box(self,Vector3(0,.025,0),Vector3(1.8,.05,.55),INK,true)
	box(self,Vector3(0,.49,-.1),Vector3(.10,.98,.15),INK,true)
	face=Node3D.new();face.position=Vector3(0,1.04,0);face.rotation_degrees.x=-55;add_child(face)
	box(face,Vector3.ZERO,Vector3(2.05,.93,.05),INK,true)
	box(face,Vector3(0,0,.032),Vector3(2.02,.90,.012),PAPER)
	text(face,"TWO ROOMS CLAIM ONE BODY",Vector3(0,.40,.046),.00080,INK)
	width_dial=dial("WIDTH",Vector3(-.76,.15,.047),.15,1.8,2)
	force_dial=dial("STRENGTH",Vector3(-.45,.15,.047),0,1,2)
	cut_dial=dial("THRESHOLD",Vector3(-.14,.15,.047),0,1,2)
	screen_title=text(face,"",Vector3(.56,.22,.047),.00050,INK)
	screen_state=text(face,"",Vector3(.56,.09,.047),.00040,INK)
	for i in 3:button(["FIELDS","RULES","CUT"][i],Vector2(-.62+i*.62,-.14),.55)
	for i in 3:button(["LEFT","CENTRE","RIGHT"][i],Vector2(-.62+i*.62,-.26),.55)
	text(face,"GRAB THE BLACK POINT / MOVE LEFT AND RIGHT",Vector3(0,-.40,.047),.00046,INK)
