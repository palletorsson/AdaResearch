extends "res://commons/artifacts/camera_glitch_study/glitch_console.gd"
## Authored-size XRTools controls; only the instrument face is new.
var bend_dial: Node3D
var gap_dial: Node3D
var scale_dial: Node3D

func _ready() -> void:
	box(self, Vector3(0,.02,0), Vector3(1.1,.04,.5), INK, true)
	box(self, Vector3(0,.48,-.1), Vector3(.09,.92,.1), INK, true)
	face=Node3D.new();face.position=Vector3(0,1,0);face.rotation_degrees.x=-55;add_child(face)
	box(face, Vector3.ZERO, Vector3(1.45,.67,.045), INK, true)
	box(face, Vector3(0,0,.03), Vector3(1.42,.64,.01), PAPER)
	text(face,"THE CORRIDOR HAS A SPINE",Vector3(0,.27,.042),.00076,INK)
	bend_dial=dial("BEND / JOINT",Vector3(-.49,.045,.044),-18,28,0)
	gap_dial=dial("SEPARATE",Vector3(-.17,.045,.044),0,1.2,2)
	scale_dial=dial("EACH BAY",Vector3(.15,.045,.044),.88,1.08,2)
	text(face,"LIFT THE PINK POINT\nFLOOR TO ROOF",Vector3(.48,.07,.045),.00039,INK)
	button("PASSAGE",Vector2(-.49,-.205),.27)
	button("FOLD",Vector2(-.17,-.205),.27)
	button("SLIP",Vector2(.15,-.205),.27)
	button("RESET",Vector2(.48,-.205),.27)
