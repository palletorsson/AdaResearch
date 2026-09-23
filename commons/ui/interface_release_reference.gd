# Shared rack controls in a focused, pointer-operated 2D-in-3D comparison.
# Five choices persist; a signed command returns; a signed setting persists.
extends Node3D

const Face = preload("res://commons/audio/rack_controls/vr_wrappers/ModuleFaceTexture.gd")
var face: Node3D
var receivers: Array[MeshInstance3D] = []
var readout: Label
const IDS := ["choice", "return", "hold"]

func _ready() -> void:
	_box("Foot", Vector3(.72, .035, .48), Vector3(0, .018, 0), Color(.12, .15, .17))
	_box("Stem", Vector3(.14, .96, .12), Vector3(0, .50, -.05), Color(.20, .23, .25))
	var deck := Node3D.new()
	deck.name = "Deck"
	deck.position.y = 1.1
	deck.rotation_degrees.x = -18
	add_child(deck)
	var casing := _box("Housing", Vector3(.62, .49, .055), Vector3.ZERO, Color(.15, .18, .20))
	casing.reparent(deck, false)
	face = Face.new()
	face.name = "ReleaseControls"
	face.position.z = .029
	deck.add_child(face)
	face.build({"name": "CHOICE / RELEASE", "hp_width": 32, "controls": [
		{"id": "choice", "type": "sls", "x_hp": 7, "y_frac": .64, "width_hp": 6,
		 "height_px": 240, "label": "CHOICE", "step_count": 5, "default": .5},
		{"id": "return", "type": "slz", "x_hp": 16, "y_frac": .64, "width_hp": 6,
		 "height_px": 240, "label": "COMMAND", "min": -1, "max": 1, "default": 0},
		{"id": "hold", "type": "slz", "x_hp": 25, "y_frac": .64, "width_hp": 6,
		 "height_px": 240, "label": "SETTING", "min": -1, "max": 1, "default": 0,
		 "return_to_center": false}]})
	readout = Label.new()
	readout.name = "ReceiverReadout"
	readout.position = Vector2(20, 66)
	readout.size = Vector2(1112, 150)
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	readout.add_theme_font_size_override("font_size", 26)
	readout.add_theme_color_override("font_color", Color(.12, .14, .15))
	readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face._panel_control.add_child(readout)
	_box("ReceiverShelf", Vector3(.62, .025, .18), Vector3(0, 1.34, -.33), Color(.18, .22, .24))
	_box("ReceiverSupport", Vector3(.08, 1.34, .08), Vector3(0, .67, -.35), Color(.18, .22, .24))
	for i in 3:
		var x: float = (i - 1) * .162
		_box("Rail%d" % i, Vector3(.007, .32, .012), Vector3(x, 1.54, -.35), Color(.15, .19, .21))
		for mark in 5:
			_box("Tick%d_%d" % [i, mark], Vector3(.075, .004, .012), Vector3(x, 1.41 + mark * .065, -.345), Color(.5, .54, .52))
		receivers.append(_box("Receiver%d" % i, Vector3(.08, .04, .08), Vector3(x, 1.54, -.33),
			[Color(.96, .4, .13), Color(.24, .72, .80), Color(.76, .43, .73)][i]))
		face.get_2d_control(IDS[i]).value_changed.connect(_apply.unbind(1))
		face.get_2d_control(IDS[i])._accent = receivers[i].material_override.albedo_color.darkened(.18)
	_apply()

func _apply() -> void:
	for i in receivers.size():
		receivers[i].position.y = 1.41 + face.get_2d_control(IDS[i]).normalized_value * .26
	var choice: float = face.get_2d_control("choice").normalized_value
	var command: float = face.get_2d_control("return").normalized_value * 2 - 1
	var setting: float = face.get_2d_control("hold").normalized_value * 2 - 1
	readout.text = "CHOOSE A LEVEL     /     MOVE A MARKER\n%d of 5                 %+.2f                 %+.2f\nRelease: stays         returns to 0          stays" % [roundi(choice * 4) + 1, command, setting]

func _box(label: String, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = .65
	node.material_override = mat
	add_child(node)
	return node
