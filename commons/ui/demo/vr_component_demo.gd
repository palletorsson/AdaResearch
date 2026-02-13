@tool
extends Node3D

## VR Component Demo — spawns all interactable and display components
## on a white backdrop panel for visual review.
##
## Usage:
##   1. Open vr_component_demo.tscn
##   2. In editor: components appear via @tool
##   3. In VR: grab and interact with everything
##
## Press R in-game to rebuild the layout.

const _P = preload("res://commons/ui/ada_palette.gd")

# ── Component scenes ──
const SLIDER_V     = preload("res://commons/interactables/slider_smooth.tscn")
const SLIDER_H     = preload("res://commons/interactables/slider_horizontal.tscn")
const SLIDER_SNAP  = preload("res://commons/interactables/slider_snap.tscn")
const SLIDER_ZERO  = preload("res://commons/interactables/slider_zero.tscn")
const SLIDER_AXIS  = preload("res://commons/interactables/slider_axis.tscn")
const DIAL         = preload("res://commons/interactables/dial_smooth.tscn")
const BUTTON       = preload("res://commons/interactables/push_button.tscn")
const JOYSTICK     = preload("res://commons/interactables/joystick_smooth.tscn")
const LEVER        = preload("res://commons/interactables/lever_smooth.tscn")
const WHEEL        = preload("res://commons/interactables/wheel_smooth.tscn")
const XY_PAD       = preload("res://commons/interactables/slider_plane.tscn")

const WAVEFORM     = preload("res://commons/audio/interfaces/VRWaveformDisplay.tscn")
const SPECTRUM     = preload("res://commons/audio/interfaces/VRSpectrumDisplay.tscn")
const SIMPLE_WAVE  = preload("res://commons/audio/interfaces/VRSimpleWaveform.tscn")
const LISSAJOUS    = preload("res://commons/audio/interfaces/VRLissajousDisplay.tscn")
const MONITOR      = preload("res://commons/audio/interfaces/VRAudioMonitor.tscn")

const VR_DIAL      = preload("res://commons/audio/interfaces/VRAudioControlDial.tscn")
const VR_SLIDER    = preload("res://commons/audio/interfaces/VRAudioControlSlider.tscn")
const VR_SLIDER_V  = preload("res://commons/audio/interfaces/VRAudioControlSliderVertical.tscn")

# Layout
const RACK_UNIT := 0.08  # 8cm grid
const GAP := 0.01        # 1cm between modules
const ROW_HEIGHT := 0.28 # Vertical spacing between rows

@onready var components_root: Node3D = $Components

func _ready():
	if not components_root:
		components_root = Node3D.new()
		components_root.name = "Components"
		add_child(components_root)
	_build_layout()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_rebuild()

func _rebuild():
	for child in components_root.get_children():
		child.queue_free()
	await get_tree().process_frame
	_build_layout()

func _build_layout():
	var x := 0.0
	var y := 0.0

	# ── Row 0: Section label ──
	_add_label("CONTROLS", Vector3(0.4, y + 0.16, 0.015), 36)
	y -= ROW_HEIGHT * 0.5

	# ── Row 1: Sliders ──
	_add_label("SLIDERS", Vector3(-0.05, y + 0.14, 0.015), 20, _P.TEXT_SECONDARY)
	x = 0.0
	x = _place(SLIDER_V, Vector3(x, y, 0), "Vertical"); x += 0.10
	x = _place(SLIDER_AXIS, Vector3(x, y, 0), "Axis"); x += 0.10
	x = _place(SLIDER_SNAP, Vector3(x, y, 0), "Snap"); x += 0.26
	x = _place(SLIDER_ZERO, Vector3(x, y, 0), "Bipolar"); x += 0.26
	x = _place(SLIDER_H, Vector3(x, y, 0), "Horizontal"); x += 0.26

	y -= ROW_HEIGHT

	# ── Row 2: Rotary + Interactive ──
	_add_label("ROTARY & INTERACTIVE", Vector3(-0.05, y + 0.14, 0.015), 20, _P.TEXT_SECONDARY)
	x = 0.0
	x = _place(DIAL, Vector3(x, y, 0), "Dial 1"); x += 0.10
	x = _place(DIAL, Vector3(x, y, 0), "Dial 2"); x += 0.10
	x = _place(WHEEL, Vector3(x, y, 0), "Wheel"); x += 0.16
	x = _place(BUTTON, Vector3(x, y + 0.05, 0), "Btn 1"); x += 0.10
	x = _place(BUTTON, Vector3(x, y + 0.05, 0), "Btn 2"); x += 0.10
	x = _place(JOYSTICK, Vector3(x, y, 0), "Joystick"); x += 0.20
	x = _place(XY_PAD, Vector3(x, y, 0), "XY Pad"); x += 0.20
	x = _place(LEVER, Vector3(x, y, 0), "Lever"); x += 0.10

	y -= ROW_HEIGHT

	# ── Row 3: VR Audio Controls (TE-style) ──
	_add_label("VR AUDIO CONTROLS", Vector3(-0.05, y + 0.14, 0.015), 20, _P.TEXT_SECONDARY)
	x = 0.0
	x = _place(VR_DIAL, Vector3(x, y, 0), "VR Knob 1"); x += 0.10
	x = _place(VR_DIAL, Vector3(x, y, 0), "VR Knob 2"); x += 0.10
	x = _place(VR_SLIDER, Vector3(x, y, 0), "VR Fader"); x += 0.36
	x = _place(VR_SLIDER_V, Vector3(x, y, 0), "VR Vert"); x += 0.10

	y -= ROW_HEIGHT + 0.06

	# ── Row 4: Displays ──
	_add_label("DISPLAYS & MONITORS", Vector3(-0.05, y + 0.16, 0.015), 20, _P.TEXT_SECONDARY)
	x = 0.0
	x = _place(WAVEFORM, Vector3(x, y, 0), "Waveform"); x += 0.34
	x = _place(SPECTRUM, Vector3(x, y, 0), "Spectrum"); x += 0.34
	x = _place(SIMPLE_WAVE, Vector3(x, y, 0), "Simple Wave"); x += 0.34

	y -= ROW_HEIGHT + 0.06
	x = 0.0
	x = _place(LISSAJOUS, Vector3(x, y, 0), "Lissajous"); x += 0.36
	x = _place(MONITOR, Vector3(x, y, 0), "Monitor"); x += 0.36

# ═══════════════════════════════════════════
#  HELPERS
# ═══════════════════════════════════════════

func _place(scene: PackedScene, pos: Vector3, label_text: String = "") -> float:
	var inst = scene.instantiate()
	inst.position = pos
	components_root.add_child(inst)

	if label_text != "" and inst.has_method("set_param_name"):
		inst.set_param_name(label_text)

	# Return X position after this component for chaining
	return pos.x

func _add_label(text: String, pos: Vector3, font_size: int = 24, color: Color = _P.TEXT_PRIMARY):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.font_size = font_size
	lbl.pixel_size = 0.0006
	lbl.modulate = color
	lbl.outline_size = 0
	lbl.position = pos
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	components_root.add_child(lbl)
