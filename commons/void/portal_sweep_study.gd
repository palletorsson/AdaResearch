extends Node3D
## Carry Profiles' actual I section and sweep engine into the portal encounter.
const Sweep = preload("res://commons/artifacts/glyph_profile_gallery/profile_sweep.gd")
const Geometry = preload("res://commons/artifacts/primitive_encounters/geometry.gd")
const PushButton = preload("res://commons/interactables/push_button.tscn")
const FONT_PATH := "res://commons/artifacts/glyph_profile_gallery/JetBrainsMono-Medium.ttf"
const PATH_SEGMENTS := 96
const ROUND_SEGMENTS := 32
var turn_degrees: int = 270
var round_profile: bool = false
var letter: Dictionary
var section: Dictionary
var body: MeshInstance3D
var section_view: MeshInstance3D
var readout: Label3D

func _ready() -> void:
	set_meta("editor_label", "Close the path / I section to round section")
	var font := FontFile.new()
	assert(font.load_dynamic_font(FONT_PATH) == OK)
	letter = Sweep.profile(font, "I")
	Geometry.box(self,"Table",Vector3(0,.84,0),Vector3(2.8,.1,2.15),Color("a8a2a8"))
	for x in [-1.2,1.2]:
		for z in [-.85,.85]:
			Geometry.box(self,"Leg",Vector3(x,.395,z),Vector3(.06,.79,.06),Color("30313b"))
	Geometry.box(self,"ReadoutBack",Vector3(0,1.65,-1),Vector3(2.7,.85,.055),Color("252634"))
	readout = Geometry.label(self,"",Vector3(0,1.67,-.967),24)
	readout.pixel_size = .0018
	readout.modulate = Color("f5e6f0")
	body = MeshInstance3D.new(); body.name = "SweptBody"; body.position = Vector3(0,1.08,-.12)
	var material := Geometry.material(Color("c77fb5"))
	material.roughness = .4; material.emission_enabled = true
	material.emission = Color("9c4d86"); material.emission_energy_multiplier = .24
	body.material_override = material; add_child(body)
	section_view = MeshInstance3D.new(); section_view.name = "Section"; section_view.position = Vector3(-1.08,1.24,-.1)
	section_view.material_override = Geometry.material(Color("edce92")); add_child(section_view)
	var label := Geometry.label(self,"SECTION",Vector3(-1.08,1.01,.14),17)
	label.modulate = Color("302733")
	button("PathButton",-.9,"PATH +90",advance_path)
	button("SectionButton",0,"I / ROUND",toggle_section)
	button("ResetButton",.9,"RESET",reset_study)
	var light := OmniLight3D.new(); light.name = "StudyLight"; light.position = Vector3(0,1.7,.1)
	light.light_color = Color("e2bad6"); light.light_energy = .7; light.omni_range = 3.2
	light.shadow_enabled = false; add_child(light)
	rebuild()

func button(title: String, x: float, caption: String, action: Callable) -> void:
	var control: Node3D = PushButton.instantiate()
	# The shared scene is wall-mounted by default. Its local +Y cap faces up here.
	control.name = title; control.position = Vector3(x,.9,.8); control.rotation = Vector3.ZERO
	add_child(control); control.pressed.connect(action)
	var label := Geometry.label(self,caption,Vector3(x,.899,.53),21)
	label.rotation.x = -PI/2

func advance_path() -> void:
	turn_degrees = 90 if turn_degrees == 360 else turn_degrees + 90
	rebuild()

func toggle_section() -> void:
	round_profile = not round_profile
	rebuild()

func reset_study() -> void:
	turn_degrees = 270; round_profile = false
	rebuild()

func circle_section() -> Dictionary:
	var points: Array[Vector2] = [Vector2.ZERO]
	var faces: Array[Vector3i] = []
	var boundary: Array[Vector2i] = []
	for i in ROUND_SEGMENTS:
		points.append(Vector2(cos(TAU*i/ROUND_SEGMENTS),sin(TAU*i/ROUND_SEGMENTS))*.5)
	for i in ROUND_SEGMENTS:
		var a := i+1
		var b := (i+1)%ROUND_SEGMENTS+1
		faces.append(Vector3i(0,b,a)); boundary.append(Vector2i(b,a))
	return {"glyph":"round", "points":points, "faces":faces, "boundary":boundary}

func path_frames() -> Array[Transform3D]:
	var frames: Array[Transform3D] = []
	var closed := turn_degrees == 360
	var count := PATH_SEGMENTS if closed else turn_degrees*PATH_SEGMENTS/360+1
	for i in count:
		var angle := PI*.75+TAU*i/PATH_SEGMENTS
		var radial := Vector3(cos(angle),0,sin(angle))
		var basis := Basis(radial,Vector3.UP,Vector3(-sin(angle),0,cos(angle)))
		frames.append(Transform3D(basis.scaled_local(Vector3(.3,.3,1)),radial*.69))
	return frames

func rebuild() -> void:
	section = circle_section() if round_profile else letter
	body.mesh = Sweep.make(section,path_frames(),turn_degrees == 360)
	var section_frames: Array[Transform3D] = [Transform3D(Basis.IDENTITY.scaled(Vector3(.4,.4,1)),Vector3(0,0,-.025)),Transform3D(Basis.IDENTITY.scaled(Vector3(.4,.4,1)),Vector3(0,0,.025))]
	section_view.mesh = Sweep.make(section,section_frames)
	var profile_name := "ROUND SECTION (32 SIDES)" if round_profile else "LETTER I SECTION / FROM PROFILES"
	var relation := "CLOSED PATH / JOINED SEAM" if turn_degrees == 360 else "OPEN PATH / TWO CAPPED ENDS"
	readout.text = "CARRY A SECTION AROUND A PATH\n%s\n%d DEGREES / %s\n%s" % [profile_name,turn_degrees,relation,"ROUND SECTION + CLOSED CIRCLE = TORUS" if round_profile and turn_degrees == 360 else "Close the path. Then change the section."]
