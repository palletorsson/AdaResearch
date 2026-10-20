extends "res://commons/artifacts/camera_glitch_study/glitch_console.gd"
var step_dial: Node3D
var limit_dial: Node3D

func _ready() -> void:
	box(self,Vector3(0,.02,0),Vector3(1.6,.04,.6),INK,true)
	box(self,Vector3(0,.5,-.1),Vector3(.10,1,.1),INK,true)
	face=Node3D.new();face.position=Vector3(0,1.04,0);face.rotation_degrees.x=-55;add_child(face)
	box(face,Vector3.ZERO,Vector3(1.95,.88,.045),INK,true)
	box(face,Vector3(0,0,.03),Vector3(1.92,.85,.01),PAPER)
	text(face,"THE MODEL CALLS ITSELF",Vector3(0,.37,.043),.00085,INK)
	step_dial=dial("STEPS",Vector3(-.72,.14,.044),0,32,0)
	limit_dial=dial("CAPACITY",Vector3(-.40,.14,.044),4,24,0)
	text(face,"CALLS / LEAK ONLY",Vector3(-.40,-.012,.047),.00028,INK)
	screen_title=text(face,"",Vector3(.28,.18,.046),.00060,INK)
	screen_state=text(face,"",Vector3(.28,.075,.046),.00039,INK)
	for i in 4:button(["SOURCE","CALLS","LEAK","WRAP"][i],Vector2(-.69+i*.46,-.12),.41)
	for i in 3:button(["STEP","PLAY / HOLD","RESET"][i],Vector2(-.58+i*.58,-.25),.49)
	text(face,"1-4: STUDIES    SPACE: PLAY    ENTER: STEP    R: RESET",Vector3(0,-.37,.045),.00039,INK)
