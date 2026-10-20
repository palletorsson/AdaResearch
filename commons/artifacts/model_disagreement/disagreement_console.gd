extends "res://commons/artifacts/camera_glitch_study/glitch_console.gd"
var strength_dial:Node3D
var step_dial:Node3D
var help_text:Label3D
func _ready() -> void:
	box(self,Vector3(0,.02,0),Vector3(1.8,.04,.6),INK,true)
	box(self,Vector3(0,.5,-.1),Vector3(.1,1,.1),INK,true)
	face=Node3D.new();face.position=Vector3(0,1.04,0);face.rotation_degrees.x=-55;add_child(face)
	box(face,Vector3.ZERO,Vector3(2.05,.88,.045),INK,true)
	box(face,Vector3(0,0,.03),Vector3(2.02,.85,.01),PAPER)
	text(face,"WHEN PARTS STOP AGREEING",Vector3(0,.37,.043),.00082,INK)
	strength_dial=dial("CONDITION",Vector3(-.76,.14,.044),0,100,0)
	step_dial=dial("STEPS",Vector3(-.44,.14,.044),0,32,0)
	screen_title=text(face,"",Vector3(.28,.18,.046),.00063,INK)
	screen_state=text(face,"",Vector3(.28,.06,.046),.00038,INK)
	for i in 4:button(["SOURCE","PRECISION","CLOCKS","FEEDBACK"][i],Vector2(-.735+i*.49,-.12),.44)
	for i in 4:button(["STEP","PLAY / HOLD","CONTROL","RESET"][i],Vector2(-.735+i*.49,-.25),.44)
	help_text=text(face,"1-4: STUDIES    C: CONTROL    SPACE: PLAY    R: RESET",Vector3(0,-.37,.045),.0004,INK)
