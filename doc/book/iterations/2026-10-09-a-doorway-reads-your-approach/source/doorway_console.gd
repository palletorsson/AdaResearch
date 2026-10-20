extends "res://commons/artifacts/camera_glitch_study/glitch_console.gd"
var reach_dial: Node3D
var pace_dial: Node3D

func _ready() -> void:
	box(self,Vector3(0,.025,0),Vector3(1.6,.05,.55),INK,true)
	box(self,Vector3(0,.49,-.1),Vector3(.1,.98,.15),INK,true)
	face=Node3D.new();face.position=Vector3(0,1.04,0);face.rotation_degrees.x=-55;add_child(face)
	box(face,Vector3.ZERO,Vector3(1.85,.88,.05),INK,true)
	box(face,Vector3(0,0,.032),Vector3(1.82,.85,.012),PAPER)
	text(face,"A DOORWAY READS YOUR APPROACH",Vector3(0,.37,.045),.00066,INK)
	reach_dial=dial("REACH / m",Vector3(-.67,.13,.047),1,7,1)
	pace_dial=dial("PACE / m/s",Vector3(-.35,.13,.047),.4,2.4,1)
	screen_title=text(face,"",Vector3(.39,.22,.047),.00049,INK)
	screen_state=text(face,"",Vector3(.39,.08,.047),.00041,INK)
	button("LIVE",Vector2(-.59,-.14),.5)
	button("DEMO SLOW",Vector2(0,-.14),.5)
	button("DEMO FAST",Vector2(.59,-.14),.5)
	button("SWAP RULES",Vector2(-.39,-.27),.68)
	button("RESET",Vector2(.39,-.27),.68)
	text(face,"LIVE READS YOUR BODY / DEMO SUPPLIES INPUTS",Vector3(0,-.38,.045),.00039,INK)
