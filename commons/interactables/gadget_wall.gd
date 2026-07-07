@tool
extends Node3D
class_name GadgetWall

# @identity
# essence: a teaching wall of every hand interaction the lab can offer — press, hover, poke, grab-carry,
#          snap, climb, and the grab-driven family (lever, sliders, dial, wheel, joystick, XY pad) — one
#          of each, labelled, with a status light that lights when you work it. The dictionary of the hand
#          made touchable in a single panel.
# desire: to make the hand vocabulary legible all at once. Stand before it and try each verb; the lit
#         status dot confirms "yes, that worked, that is what this gesture does". A Rosetta stone for hands.
# critical_parameter: GADGETS — the ordered list of scene + label + signal. Each entry says what to place,
#         what to call it, and which signal proves it was used (lighting its dot).
# triggers: _ready instantiates each gadget at a grid slot, adds a label and a status dot, and connects the
#          gadget's success signal to light its dot.
# emerges: a complete, self-documenting sampler — the one place a newcomer learns the whole hand grammar,
#          and the one place a developer checks that every interaction modality still works.
# needs: each gadget scene [present]; per-gadget label + status dot [present]; signal wiring [present]
# relationships: successor to InteractableDemo (which sampled controls); this samples MODALITIES, including
#                the new hover/grab/snap/poke/climb gadgets and the hand_scanner keystone.
# truth: an interface is a vocabulary, and a vocabulary is best taught by laying one of every word in a row.
#        The gadget wall is that row — the hand's whole sentence, spread out to be spoken once each.

# Each: scene path, label, success signal (or "" if none), row, col.
const GADGETS := [
	# Row 0 — contact + presence
	{ "scene": "res://commons/interactables/push_button.tscn",      "label": "PRESS",      "signal": "pressed",        "row": 0, "col": 0 },
	{ "scene": "res://commons/interactables/hand_scanner.tscn",     "label": "HOVER/DWELL","signal": "scan_complete",  "row": 0, "col": 1 },
	{ "scene": "res://commons/interactables/poke_keypad.tscn",      "label": "POKE",       "signal": "key_pressed",    "row": 0, "col": 2 },
	{ "scene": "res://commons/interactables/grab_cube.tscn",        "label": "GRAB-CARRY", "signal": "grabbed",        "row": 0, "col": 3 },
	{ "scene": "res://commons/interactables/snap_socket.tscn",      "label": "SNAP/PLACE", "signal": "socket_filled",  "row": 0, "col": 4 },
	{ "scene": "res://commons/interactables/climb_grip.tscn",       "label": "CLIMB",      "signal": "",               "row": 0, "col": 5 },
	# Row 1 — grab-to-drive family
	{ "scene": "res://commons/interactables/lever_smooth.tscn",     "label": "LEVER",      "signal": "",               "row": 1, "col": 0 },
	{ "scene": "res://commons/interactables/slider_smooth.tscn",    "label": "SLIDER V",   "signal": "",               "row": 1, "col": 1 },
	{ "scene": "res://commons/interactables/slider_horizontal.tscn","label": "SLIDER H",   "signal": "slider_moved",   "row": 1, "col": 2 },
	{ "scene": "res://commons/interactables/dial_smooth.tscn",      "label": "DIAL",       "signal": "",               "row": 1, "col": 3 },
	{ "scene": "res://commons/interactables/wheel_smooth.tscn",     "label": "WHEEL 2H",   "signal": "",               "row": 1, "col": 4 },
	{ "scene": "res://commons/interactables/joystick_smooth.tscn",  "label": "JOYSTICK",   "signal": "",               "row": 1, "col": 5 },
	{ "scene": "res://commons/interactables/slider_plane.tscn",     "label": "XY PAD",     "signal": "",               "row": 1, "col": 6 },
]

@export var col_spacing: float = 0.34
@export var row_spacing: float = 0.42
@export var row_y_top: float = 1.45
@export var auto_build: bool = true

var _built: bool = false
var _dots: Dictionary = {}   # gadget index -> {mat}


func _ready() -> void:
	if _built or not auto_build:
		return
	_build()


func _build() -> void:
	_built = true

	# Back panel.
	var n_cols := 7
	var width: float = n_cols * col_spacing
	var panel := MeshInstance3D.new()
	panel.name = "BackPanel"
	var pm := BoxMesh.new()
	pm.size = Vector3(width, 1.2, 0.03)
	panel.mesh = pm
	var panel_mat := StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.10, 0.11, 0.13)
	panel_mat.metallic = 0.2
	panel_mat.roughness = 0.85
	panel.material_override = panel_mat
	panel.position = Vector3(0, row_y_top - row_spacing * 0.5, -0.05)
	add_child(panel)

	# Title.
	var title := Label3D.new()
	title.text = "HAND GADGETS — one of every interaction"
	title.font_size = 40
	title.pixel_size = 0.0016
	title.modulate = Color(0.85, 0.9, 1.0)
	title.position = Vector3(0, row_y_top + 0.28, 0)
	add_child(title)

	var x_center: float = (n_cols - 1) * col_spacing * 0.5
	for i in range(GADGETS.size()):
		var g: Dictionary = GADGETS[i]
		_place_gadget(i, g, x_center)


func _place_gadget(index: int, g: Dictionary, x_center: float) -> void:
	var scene_path: String = g["scene"]
	var slot := Node3D.new()
	slot.name = "Slot_%s" % g["label"].replace("/", "_").replace(" ", "_")
	var x: float = g["col"] * col_spacing - x_center
	var y: float = row_y_top - g["row"] * row_spacing
	slot.position = Vector3(x, y, 0)
	add_child(slot)

	# Instantiate the gadget.
	if ResourceLoader.exists(scene_path):
		var inst = load(scene_path).instantiate()
		inst.name = "Gadget"
		slot.add_child(inst)
		# Wire success signal -> light the dot. The lambda declares four
		# default params so it absorbs any signal arity (0..2 used here;
		# Godot fills the rest from defaults).
		var sig: String = g["signal"]
		if sig != "" and inst.has_signal(sig):
			inst.connect(sig, _make_dot_lighter(index))
	else:
		push_warning("GadgetWall: missing scene %s" % scene_path)

	# Label below.
	var lbl := Label3D.new()
	lbl.text = g["label"]
	lbl.font_size = 26
	lbl.pixel_size = 0.0011
	lbl.modulate = Color(0.8, 0.84, 0.92)
	lbl.position = Vector3(0, -0.13, 0.02)
	slot.add_child(lbl)

	# Status dot above the label.
	var dot := MeshInstance3D.new()
	dot.name = "StatusDot"
	var sm := SphereMesh.new()
	sm.radius = 0.012
	sm.height = 0.024
	dot.mesh = sm
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.4, 0.4, 0.45)
	dmat.emission_enabled = true
	dmat.emission = Color(0.4, 0.4, 0.45)
	dmat.emission_energy_multiplier = 0.3
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dot.material_override = dmat
	dot.position = Vector3(0.0, -0.085, 0.02)
	slot.add_child(dot)
	_dots[index] = dmat


# Returns a callable that lights gadget `index`'s dot, ignoring whatever
# args the signal carries (four defaults cover every signal used here).
func _make_dot_lighter(index: int) -> Callable:
	return func(_a = null, _b = null, _c = null, _d = null): _light_dot(index)


func _light_dot(index: int) -> void:
	if not _dots.has(index):
		return
	var mat: StandardMaterial3D = _dots[index]
	mat.albedo_color = Color(0.3, 0.95, 0.45)
	mat.emission = Color(0.3, 0.95, 0.45)
	mat.emission_energy_multiplier = 2.0
