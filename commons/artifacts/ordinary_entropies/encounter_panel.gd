extends Node3D
## One small surface: question, current state, reading and canonical XR buttons.
signal requested(action: String)
const Objects=preload("objects.gd")
const Rack=preload("res://commons/audio/rack_templates/RackTemplates.gd")
const Typeface=preload("res://commons/utils/baked_text_albedo.gd")
const SIZE=Vector2(0.94,0.50)
var heading:=""
var question:=""
var extra_action:=""
var face: Node3D
var state_label: Label3D
var readout: Label3D
var buttons: Dictionary={}
var button_labels: Dictionary={}

func _ready() -> void:
	name="EncounterPanel"
	Objects.box(self,Vector3(0,0.015,0),Vector3(0.38,0.03,0.32),Objects.DARK,true)
	Objects.box(self,Vector3(0,0.55,0),Vector3(0.045,1.10,0.045),Objects.DARK)
	face=Node3D.new();face.name="Face";add_child(face)
	face.position.y=1.12;face.rotation_degrees.x=-20
	var plate=Objects.box(face,Vector3.ZERO,Vector3(SIZE.x,SIZE.y,0.035),Color("e9e5d9"),true)
	plate.name="SinglePanel";plate.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	ink(heading,Vector3(0,0.202,0.019),27)
	ink(question,Vector3(0,0.150,0.019),25)
	state_label=ink("",Vector3(0,0.095,0.019),25)
	state_label.modulate=Color("9e365e")
	readout=ink("",Vector3(0,0.018,0.019),24)
	var actions: Array[String]=["PREVIOUS","NEXT"]
	if not extra_action.is_empty():actions.append(extra_action)
	for i in actions.size():
		var key: String=actions[i]
		var x: float=(i-(actions.size()-1)*0.5)*0.28
		var button: Node3D=load("res://commons/interactables/push_button.tscn").instantiate()
		face.add_child(button);button.position=Vector3(x,-0.135,0.025)
		Rack.make_button_rectangular(button)
		button.released_emission_energy=0.0
		buttons[key]=button
		button.pressed.connect(func():requested.emit(key))
		button_labels[key]=ink(key,Vector3(x,-0.207,0.019),23)

func ink(text: String,position_on_face: Vector3,font_size: int) -> Label3D:
	var label:=Label3D.new();face.add_child(label);label.position=position_on_face
	label.text=text;label.font=Typeface.project_font();label.font_size=font_size
	label.pixel_size=0.00085;label.outline_size=0;label.modulate=Color("233538")
	return label

func show_state(state: String,reading: String,playing: bool=false) -> void:
	state_label.text=state;readout.text=reading
	if button_labels.has("PLAY"):
		button_labels["PLAY"].text="PAUSE" if playing else "PLAY"
		buttons["PLAY"].set_selected(playing)

func approach() -> Vector3:
	return to_global(Vector3(0,0,0.85))
