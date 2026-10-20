extends "res://commons/artifacts/camera_glitch_study/glitch_console.gd"
var change_dial: Node3D
var count_dial: Node3D

func _ready() -> void:
	box(self,Vector3(0,.02,0),Vector3(1.45,.04,.6),INK,true)
	box(self,Vector3(0,.5,-.1),Vector3(.09,1,.1),INK,true)
	face=Node3D.new();face.position=Vector3(0,1.04,0);face.rotation_degrees.x=-55;add_child(face)
	box(face,Vector3.ZERO,Vector3(1.85,.76,.045),INK,true)
	box(face,Vector3(0,0,.03),Vector3(1.82,.73,.01),PAPER)
	text(face,"ONE ARCADE / FOUR OPERATIONS",Vector3(0,.31,.043),.00085,INK)
	change_dial=dial("CHANGE",Vector3(-.66,.07,.044),0,100,0)
	count_dial=dial("BAYS",Vector3(-.33,.07,.044),4,24,0)
	screen_title=text(face,"",Vector3(.29,.13,.045),.00060,INK)
	screen_state=text(face,"",Vector3(.29,.045,.045),.00040,INK)
	for i in 5:button(["SOURCE","CURVE","HINGE","FIELD","STRETCH"][i],Vector2(-.70+i*.35,-.17),.31)
	text(face,"1-5: STUDIES    ARROWS: CHANGE / COUNT    R: RESET",Vector3(0,-.30,.045),.00040,INK)
