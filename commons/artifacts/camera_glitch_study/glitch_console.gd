extends Node3D
## A compact instrument using the same live angular controls as InteractableDemo.
## Rectangular caps retain the shared pointer, hand-poke, release and sound paths.
const Dial = preload("res://commons/interactables/dial_smooth.tscn")
const ButtonScene = preload("res://commons/interactables/push_button.tscn")
const Fonts = preload("res://commons/utils/baked_text_albedo.gd")
const INK := Color("18282c")
const PAPER := Color("e6e1d5")
const PINK := Color("cf7395")
var face: Node3D
var effect_dial: Node3D
var amount_dial: Node3D
var buttons: Dictionary = {}
var screen_title: Label3D
var screen_state: Label3D

func _ready() -> void:
	name = "GlitchConsole"
	# A smaller footprint gives all controls one reachable reading position.
	box(self, Vector3(0,.025,0), Vector3(.88,.05,.48), INK, true)
	for x in [-.40,.40]:
		box(self, Vector3(x,.46,-.05), Vector3(.035,.87,.20), INK, true)
	face = Node3D.new()
	face.position = Vector3(0,.96,0)
	face.rotation_degrees.x = -55
	add_child(face)
	box(face, Vector3.ZERO, Vector3(1.16,.68,.058), INK, true)
	box(face, Vector3(0,0,.032), Vector3(1.13,.65,.012), PAPER)
	box(face, Vector3(-.085,0,.04), Vector3(.002,.56,.001), Color("b9b5ad"))
	text(face, "ENDLESS MUSEUM   /   IMAGE INSTRUMENT", Vector3(-.025,.284,.041), .00050, INK)
	box(face, Vector3(-.28,.15,.042), Vector3(.48,.15,.006), INK)
	screen_title = text(face, "", Vector3(-.28,.17,.047), .00060, Color("f3eee5"))
	screen_state = text(face, "", Vector3(-.28,.105,.047), .00038, Color("a2c6b9"))
	effect_dial = dial("EFFECT", Vector3(-.405,-.075,.045), 1, 10, 0)
	# 0..270 with 30-degree detents makes exactly ten distinct choices.
	var selector = effect_dial.get_node("DialOrigin/InteractableHinge")
	selector.hinge_limit_min = 0.0
	selector.hinge_limit_max = 270.0
	selector.hinge_steps = 30.0
	amount_dial = dial("STRENGTH", Vector3(-.165,-.075,.045), 0, 100, 0)
	text(face, "TURN TO CHOOSE", Vector3(-.405,-.218,.043), .00025, INK)
	text(face, "0 = SOURCE", Vector3(-.165,-.218,.043), .00025, INK)
	# Seven buttons grouped into one bank switch and three close pairs.
	button("PIXELS / FORM", Vector2(.24,.163), .45)
	button("PREVIOUS", Vector2(.115,.035), .20)
	button("NEXT", Vector2(.365,.035), .20)
	button("SNAP", Vector2(.115,-.085), .20)
	button("LIVE / HOLD", Vector2(.365,-.085), .20)
	button("HOME", Vector2(.115,-.205), .20)
	button("RESET", Vector2(.365,-.205), .20)
	box(face, Vector3(-.515,.282,.043), Vector3(.025,.012,.002), PINK)
	for x in [-.55,.55]:
		for y in [-.31,.31]:
			box(face, Vector3(x,y,.04), Vector3(.012,.003,.002), INK)

func dial(caption: String, at: Vector3, low: float, high: float, decimals: int) -> Node3D:
	var control: Node3D = Dial.instantiate()
	control.position = at
	control.decimal_places = decimals
	face.add_child(control)
	control.set_range(low,high)
	control.get_node("Frame/PanelMesh").hide()
	control.get_node("Frame/LabelName").hide()
	var value: Label3D = control.get_node("Frame/Label3DValue")
	value.font = Fonts.project_font("medium")
	value.font_size = 32
	value.pixel_size = .0006
	value.position.y = .084
	value.modulate = INK
	var handle_mesh: MeshInstance3D = control.get_node("DialOrigin/InteractableHinge/KnobMesh")
	handle_mesh.material_override = material(INK)
	var indicator: MeshInstance3D = handle_mesh.get_node("Indicator")
	indicator.material_override = material(PINK)
	# The shared controls keep their authored physics dimensions and unit scale.
	for i in (10 if caption=="EFFECT" else 11):
		var angle := deg_to_rad(i*30.0 if caption=="EFFECT" else -135.0+i*27.0)
		var tick := box(control, Vector3(cos(angle)*.055,sin(angle)*.055,.008), Vector3(.002,.008,.002), INK)
		tick.rotation.z = angle-PI*.5
	text(face, caption, at+Vector3(0,-.105,0), .0004, INK)
	return control

func button(id: String, at: Vector2, width: float) -> void:
	var control: Node3D = ButtonScene.instantiate()
	control.name = id.validate_node_name()
	control.position = Vector3(at.x,at.y,.047)
	control.rotation_degrees.x = 90
	# The scene is rotated so its local +Y cap faces the panel's +Z.
	var cap := BoxMesh.new()
	cap.size = Vector3(width,.018,.067)
	control.get_node("Button/ButtonMesh").mesh = cap
	control.get_node("Button/ButtonMesh").set_surface_override_material(0,material(PAPER))
	var backing := BoxMesh.new()
	backing.size = Vector3(width+.009,.012,.076)
	control.get_node("ButtonBase/BaseMesh").mesh = backing
	for path in ["Button/CollisionShape3D","ButtonBase/CollisionShape3D","InteractableAreaButton/CollisionShape3D"]:
		var shape := BoxShape3D.new()
		shape.size = Vector3(width,.025 if path.begins_with("Button") else .045,.067)
		control.get_node(path).shape = shape
	control.get_node("AccentRing").hide()
	control.get_node("InteractableAreaButton").displacement = Vector3(0,-.005,0)
	control.released_color = Color("f4efe5")
	control.selected_color = PINK
	control.pressed_color = Color("eeb3cb")
	control.released_emission_energy = 0.0
	control.pressed_emission_energy = .12
	face.add_child(control)
	# Put the legend ON the cap, moving with the actual button press.
	var legend := text(control.get_node("Button"),id,Vector3(0,.011,0),.00052,INK)
	legend.name = "Legend"
	legend.rotation_degrees.x = -90
	buttons[id] = control

func show_state(pixel_bank: bool, mode: int, title: String, strength: float, held: bool, saved: bool) -> void:
	effect_dial.set_normalized_value(float(mode)/9.0)
	amount_dial.set_normalized_value(strength)
	screen_title.text = "%s  %02d / 10\n%s" % ["PIXELS" if pixel_bank else "FORM",mode+1,title.trim_prefix("%02d / "%(mode+1))]
	screen_title.font_size = 40
	screen_state.text = "%s   /   %s" % ["HOLD" if held else "LIVE", "SNAP READY" if saved else "NO SNAP"]
	buttons["PIXELS / FORM"].set_selected(pixel_bank)
	buttons["LIVE / HOLD"].set_selected(held)
	for id in buttons:
		buttons[id].get_node("Button/Legend").modulate = PAPER if buttons[id].is_selected() else INK

func material(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = .72
	return mat

func box(parent: Node3D, at: Vector3, size: Vector3, colour: Color, solid := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.position = at
	mesh.material_override = material(colour)
	parent.add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		parent.add_child(body)
		body.position = at
		var collider := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		collider.shape = bounds
		body.add_child(collider)
	return mesh

func text(parent: Node3D, caption: String, at: Vector3, pixel: float, ink: Color) -> Label3D:
	var label := Label3D.new()
	label.text = caption
	label.position = at
	label.font = Fonts.project_font("medium")
	label.font_size = 36
	label.pixel_size = pixel
	label.modulate = ink
	label.outline_size = 0
	parent.add_child(label)
	return label
