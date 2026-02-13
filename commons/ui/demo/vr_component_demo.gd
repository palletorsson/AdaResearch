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
const SLIDER_TIME  = preload("res://commons/interactables/slider_time.tscn")
const DIAL         = preload("res://commons/interactables/dial_smooth.tscn")
const BUTTON       = preload("res://commons/interactables/push_button.tscn")
const JOYSTICK     = preload("res://commons/interactables/joystick_smooth.tscn")
const JOYSTICK_SNAP = preload("res://commons/interactables/joystick_snap.tscn")
const JOYSTICK_ZERO = preload("res://commons/interactables/joystick_zero.tscn")
const LEVER        = preload("res://commons/interactables/lever_smooth.tscn")
const LEVER_SNAP   = preload("res://commons/interactables/lever_snap.tscn")
const LEVER_ZERO   = preload("res://commons/interactables/lever_zero.tscn")
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

# Layout constants
const COL_GAP := 0.04       # Horizontal gap between components
const ROW_GAP := 0.06       # Extra vertical gap between rows
const LABEL_Z := 0.015      # Z offset for labels (in front of backdrop)
const COMP_Z := 0.02        # Z offset for flat components
const STICK_Z := 0.03       # Z offset for stick-type (joystick, lever)

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
	# Usable width ≈ 1.1m (Components root at x=-0.5, backdrop extends to ~x=1.1)
	# Keep all content within x = 0.0 .. 1.05
	var x := 0.0
	var y := 0.0

	# ── Title ──
	_add_label("ADA COMPONENT LIBRARY", Vector3(0.25, y + 0.16, LABEL_Z), 36)
	y -= 0.18

	# ═══════════════════════════════════════
	#  SECTION 1: SLIDERS
	# ═══════════════════════════════════════
	_add_section_label("SLIDERS", Vector3(-0.02, y, LABEL_Z))
	y -= 0.06

	# Row 1a: Vertical sliders (compact, ~8cm wide each)
	x = 0.0
	x = _place_labeled(SLIDER_V,    Vector3(x, y, COMP_Z), "Smooth");   x += 0.14
	x = _place_labeled(SLIDER_AXIS, Vector3(x, y, COMP_Z), "Axis");     x += 0.14
	x = _place_labeled(SLIDER_SNAP, Vector3(x, y, COMP_Z), "Snap");     x += 0.14
	x = _place_labeled(SLIDER_ZERO, Vector3(x, y, COMP_Z), "Bipolar");  x += 0.14

	y -= 0.30 + ROW_GAP

	# Row 1b: Horizontal + Time sliders (wider, own row)
	x = 0.0
	x = _place_labeled(SLIDER_H,    Vector3(x, y, COMP_Z), "Horizontal"); x += 0.28
	x = _place_labeled(SLIDER_TIME, Vector3(x, y, COMP_Z), "Time");       x += 0.28

	y -= 0.30 + ROW_GAP

	# ═══════════════════════════════════════
	#  SECTION 2: ROTARY & BUTTONS
	# ═══════════════════════════════════════
	_add_section_label("ROTARY & BUTTONS", Vector3(-0.02, y, LABEL_Z))
	y -= 0.06

	x = 0.0
	x = _place_labeled(DIAL,   Vector3(x, y, COMP_Z), "Dial");        x += 0.14
	x = _place_labeled(DIAL,   Vector3(x, y, COMP_Z), "Dial 2");      x += 0.14
	x = _place_labeled(WHEEL,  Vector3(x, y, COMP_Z), "Wheel");       x += 0.20
	x = _place_labeled(BUTTON, Vector3(x, y + 0.04, STICK_Z), "Btn"); x += 0.12
	x = _place_labeled(BUTTON, Vector3(x, y + 0.04, STICK_Z), "Btn 2"); x += 0.12
	x = _place_labeled(XY_PAD, Vector3(x, y, COMP_Z), "XY Pad");     x += 0.20

	y -= 0.24 + ROW_GAP

	# ═══════════════════════════════════════
	#  SECTION 3: JOYSTICKS
	# ═══════════════════════════════════════
	_add_section_label("JOYSTICKS", Vector3(-0.02, y, LABEL_Z))
	y -= 0.06

	x = 0.0
	x = _place_labeled(JOYSTICK,      Vector3(x, y, STICK_Z), "Smooth"); x += 0.24
	x = _place_labeled(JOYSTICK_SNAP, Vector3(x, y, STICK_Z), "Snap");   x += 0.28
	x = _place_labeled(JOYSTICK_ZERO, Vector3(x, y, STICK_Z), "Zero");   x += 0.28

	y -= 0.28 + ROW_GAP

	# ═══════════════════════════════════════
	#  SECTION 4: LEVERS
	# ═══════════════════════════════════════
	_add_section_label("LEVERS", Vector3(-0.02, y, LABEL_Z))
	y -= 0.06

	x = 0.0
	x = _place_labeled(LEVER,      Vector3(x, y, STICK_Z), "Smooth"); x += 0.16
	x = _place_labeled(LEVER_SNAP, Vector3(x, y, STICK_Z), "Snap");   x += 0.28
	x = _place_labeled(LEVER_ZERO, Vector3(x, y, STICK_Z), "Zero");   x += 0.28

	y -= 0.36 + ROW_GAP

	# ═══════════════════════════════════════
	#  SECTION 5: VR AUDIO CONTROLS
	# ═══════════════════════════════════════
	_add_section_label("VR AUDIO CONTROLS", Vector3(-0.02, y, LABEL_Z))
	y -= 0.06

	x = 0.0
	x = _place_labeled(VR_DIAL,     Vector3(x, y, COMP_Z), "Knob");     x += 0.14
	x = _place_labeled(VR_DIAL,     Vector3(x, y, COMP_Z), "Knob 2");   x += 0.14
	x = _place_labeled(VR_SLIDER,   Vector3(x, y, COMP_Z), "Fader");    x += 0.28
	x = _place_labeled(VR_SLIDER_V, Vector3(x, y, COMP_Z), "Vertical"); x += 0.14

	y -= 0.28 + ROW_GAP

	# ═══════════════════════════════════════
	#  SECTION 6: DISPLAYS & MONITORS
	# ═══════════════════════════════════════
	_add_section_label("DISPLAYS & MONITORS", Vector3(-0.02, y, LABEL_Z))
	y -= 0.06

	# Row 6a: Three displays
	x = 0.0
	x = _place_labeled(WAVEFORM,    Vector3(x, y, COMP_Z), "Waveform");    x += 0.32
	x = _place_labeled(SPECTRUM,    Vector3(x, y, COMP_Z), "Spectrum");    x += 0.32
	x = _place_labeled(SIMPLE_WAVE, Vector3(x, y, COMP_Z), "Simple Wave"); x += 0.32

	y -= 0.28 + ROW_GAP

	# Row 6b: Two more displays
	x = 0.0
	x = _place_labeled(LISSAJOUS, Vector3(x, y, COMP_Z), "Lissajous"); x += 0.34
	x = _place_labeled(MONITOR,   Vector3(x, y, COMP_Z), "Monitor");   x += 0.34


# ═══════════════════════════════════════════
#  HELPERS
# ═══════════════════════════════════════════

## Place a component and add a billboard label underneath it
func _place_labeled(scene: PackedScene, pos: Vector3, label_text: String) -> float:
	var inst = scene.instantiate()
	inst.position = pos
	components_root.add_child(inst)

	# Try to set the built-in param name (only at runtime, not in editor)
	if not Engine.is_editor_hint() and inst.has_method("set_param_name"):
		inst.set_param_name(label_text)

	# Add a billboard label below the component
	var lbl := Label3D.new()
	lbl.text = label_text
	lbl.font_size = 32
	lbl.pixel_size = 0.0005
	lbl.modulate = _P.TEXT_SECONDARY
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.position = pos + Vector3(0, -0.12, 0.02)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.outline_size = 4
	lbl.outline_modulate = Color(1, 1, 1, 0.6)
	components_root.add_child(lbl)

	return pos.x

## Section header — larger, accented, flush left
func _add_section_label(text: String, pos: Vector3) -> void:
	# Accent bar
	var bar := MeshInstance3D.new()
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(0.005, 0.025, 0.002)
	bar.mesh = bar_mesh
	bar.material_override = _P.accent_material(_P.ACCENT_ORANGE)
	bar.position = pos + Vector3(-0.015, -0.012, 0)
	components_root.add_child(bar)

	# Label
	var lbl := Label3D.new()
	lbl.text = text
	lbl.font_size = 28
	lbl.pixel_size = 0.0006
	lbl.modulate = _P.TEXT_PRIMARY
	lbl.position = pos
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.outline_size = 0
	components_root.add_child(lbl)

## Simple label (for title etc.)
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
