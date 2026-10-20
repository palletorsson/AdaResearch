extends "res://commons/artifacts/camera_glitch_study/glitch_console.gd"
var turn_dial: Node3D
var scale_dial: Node3D
var limb_dial: Node3D
func _ready() -> void:
	name="PivotConsole"
	box(self,Vector3(0,.02,0),Vector3(1.10,.04,.48),INK,true)
	box(self,Vector3(0,.47,-.10),Vector3(.08,.9,.10),INK,true)
	face=Node3D.new();face.position=Vector3(0,1.0,0);face.rotation_degrees.x=-55;add_child(face)
	box(face,Vector3.ZERO,Vector3(1.45,.67,.045),INK,true)
	box(face,Vector3(0,0,.03),Vector3(1.42,.64,.01),PAPER)
	text(face,"MOVE THE CENTRE",Vector3(0,.267,.041),.00080,INK)
	turn_dial=dial("ROTATION",Vector3(-.49,.045,.044),-180,180,0)
	scale_dial=dial("SCALE",Vector3(-.17,.045,.044),.55,1.3,2)
	limb_dial=dial("LIMBS",Vector3(.15,.045,.044),0,100,0)
	text(face,"GRAB THE PINK POINT",Vector3(.48,.10,.044),.00037,INK)
	text(face,"ONE BODY\n25 BONES",Vector3(.48,.02,.044),.00048,INK)
	button("RUN",Vector2(-.49,-.205),.27)
	button("BONES",Vector2(-.17,-.205),.27)
	button("CENTRE",Vector2(.15,-.205),.27)
	button("RESET",Vector2(.48,-.205),.27)
