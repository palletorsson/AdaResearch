extends Node3D
## A wall-mounted explanation, with no stand, controls or billboard behaviour.
const Objects=preload("objects.gd")
const Typeface=preload("res://commons/utils/baked_text_albedo.gd")
const SIZE=Vector2(1.60,0.98)
var heading:=""
var explanation:=""
var comparisons:=""
var reading: Label3D
var backing_enabled:=true

func _ready() -> void:
	name="WallExplanation"
	if backing_enabled:
		# Own the support instead of assuming an existing room wall is present.
		var body=Objects.box(self,Vector3(0,1.125-position.y,-0.10),Vector3(1.9,2.25,0.16),Color("d4d0c2"),true)
		body.name="FloorToTopBacking"
		Objects.box(self,Vector3(0,0.04-position.y,-0.10),Vector3(1.94,0.08,0.20),Objects.DARK,true)
	var plate=Objects.box(self,Vector3.ZERO,Vector3(SIZE.x,SIZE.y,0.018),Color("e9e5d9"))
	plate.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	for side in [-1,1]:
		Objects.box(self,Vector3(side*(SIZE.x/2+0.02),0,0.002),Vector3(0.04,SIZE.y+0.08,0.055),Color("796647"))
		Objects.box(self,Vector3(0,side*(SIZE.y/2+0.02),0.002),Vector3(SIZE.x,0.04,0.055),Color("796647"))
	ink(heading,Vector3(-0.72,0.405,0.012),27)
	ink(explanation,Vector3(-0.72,0.30,0.012),24)
	reading=ink(comparisons,Vector3(-0.72,-0.07,0.012),24)
	reading.modulate=Color("8d3155")

func ink(words: String,p: Vector3,size: int) -> Label3D:
	var label:=Label3D.new();add_child(label);label.text=words;label.position=p
	label.font=Typeface.project_font();label.font_size=size;label.pixel_size=0.0013
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	label.outline_size=0;label.modulate=Color("233538")
	return label

func approach() -> Vector3:
	return to_global(Vector3(0,-position.y,0.95))
