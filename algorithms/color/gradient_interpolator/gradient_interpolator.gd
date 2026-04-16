# gradient_interpolator.gd
# Gradient Interpolator — shows gradient interpolation between two colors
# using different color spaces (RGB vs HSV lerp).
# A row of 16 colored cubes shows the gradient. Toggle between modes.
#
# @identity
# essence: the path between two colors depends on which space you walk through
# desire: pick two colors, watch 16 cubes paint a gradient, toggle RGB/HSV and see the path change
# critical_parameter: interpolation mode — RGB walks a straight line in a cube, HSV walks an arc on a cylinder
# triggers: Color A/B sliders pick from 8 presets; Mode button toggles RGB/HSV; all trigger full recalculation
# emerges: RGB gradients can look muddy; HSV gradients pass through the rainbow — same endpoints, different journeys
# needs: RackTemplates panel [has]; BoxMesh gradient cubes [has]; Label3D mode display [has]
# relationships: sibling to subpixel_display (both explore color representation); feeds into colorspaces
# truth: Interpolation is not neutral — the space you choose shapes every color you pass through.

extends Node3D

class_name GradientInterpolator

# ── Grid ──────────────────────────────────────────────────────────────────────
@export var step_count: int = 16
@export var cube_size: float = 0.02
@export var cube_gap: float = 0.004

# ── Presets ───────────────────────────────────────────────────────────────────
const COLOR_PRESETS: Array[Color] = [
	Color(1.0, 0.0, 0.0),    # Red
	Color(1.0, 0.5, 0.0),    # Orange
	Color(1.0, 1.0, 0.0),    # Yellow
	Color(0.0, 1.0, 0.0),    # Green
	Color(0.0, 1.0, 1.0),    # Cyan
	Color(0.0, 0.0, 1.0),    # Blue
	Color(0.5, 0.0, 1.0),    # Purple
	Color(1.0, 0.0, 0.5),    # Magenta
]

# ── State ─────────────────────────────────────────────────────────────────────
var _color_a_idx: int = 0
var _color_b_idx: int = 5
var _mode_hsv: bool = false  # false = RGB, true = HSV
var _cubes: Array[MeshInstance3D] = []
var _mode_label: Label3D
var _color_a_swatch: MeshInstance3D
var _color_b_swatch: MeshInstance3D
var _color_a_mat: StandardMaterial3D
var _color_b_mat: StandardMaterial3D


func _ready() -> void:
	_build_gradient_row()
	_build_swatches()
	_build_mode_label()
	_build_panel()
	_recalculate()


# ═════════════════════════════════════════════════════════════════════════════
# GRADIENT ROW
# ═════════════════════════════════════════════════════════════════════════════

func _build_gradient_row() -> void:
	var total_w: float = step_count * (cube_size + cube_gap) - cube_gap
	var start_x: float = -total_w / 2.0 + cube_size / 2.0
	var row_y: float = 0.32

	for i in step_count:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(cube_size, cube_size, cube_size)
		mi.mesh = box

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.WHITE
		mi.material_override = mat

		mi.position = Vector3(
			start_x + i * (cube_size + cube_gap),
			row_y,
			0
		)
		add_child(mi)
		_cubes.append(mi)


# ═════════════════════════════════════════════════════════════════════════════
# SWATCHES (show selected colors)
# ═════════════════════════════════════════════════════════════════════════════

func _build_swatches() -> void:
	var total_w: float = step_count * (cube_size + cube_gap) - cube_gap

	# Color A swatch (left)
	_color_a_swatch = MeshInstance3D.new()
	var qa := QuadMesh.new()
	qa.size = Vector2(0.04, 0.04)
	_color_a_swatch.mesh = qa
	_color_a_mat = StandardMaterial3D.new()
	_color_a_mat.albedo_color = COLOR_PRESETS[_color_a_idx]
	_color_a_swatch.material_override = _color_a_mat
	_color_a_swatch.position = Vector3(-total_w / 2.0 - 0.04, 0.32, 0.01)
	add_child(_color_a_swatch)

	# Color B swatch (right)
	_color_b_swatch = MeshInstance3D.new()
	var qb := QuadMesh.new()
	qb.size = Vector2(0.04, 0.04)
	_color_b_swatch.mesh = qb
	_color_b_mat = StandardMaterial3D.new()
	_color_b_mat.albedo_color = COLOR_PRESETS[_color_b_idx]
	_color_b_swatch.material_override = _color_b_mat
	_color_b_swatch.position = Vector3(total_w / 2.0 + 0.04, 0.32, 0.01)
	add_child(_color_b_swatch)


# ═════════════════════════════════════════════════════════════════════════════
# MODE LABEL
# ═════════════════════════════════════════════════════════════════════════════

func _build_mode_label() -> void:
	_mode_label = Label3D.new()
	_mode_label.name = "ModeLabel"
	_mode_label.text = "MODE: RGB"
	_mode_label.pixel_size = 0.0015
	_mode_label.font_size = 16
	_mode_label.modulate = Color(0.9, 0.85, 0.5)
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode_label.position = Vector3(0, 0.40, 0)
	add_child(_mode_label)


# ═════════════════════════════════════════════════════════════════════════════
# PANEL
# ═════════════════════════════════════════════════════════════════════════════

func _build_panel() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("GRADIENT", [
		[
			{"type": "slider_h", "label": "COLOR A", "default": 0.0},
			{"type": "slider_h", "label": "COLOR B", "default": 0.625},
		],
		[{"type": "button", "label": "MODE"}],
	])
	panel.position = Vector3(0, 0.05, 0.06)
	panel.rotation_degrees = Vector3(-20, 0, 0)
	add_child(panel)

	# Color A slider (Param_0)
	var a_slider: Node = panel.find_child("Param_0", true, false)
	if a_slider and a_slider.has_signal("slider_moved"):
		a_slider.slider_moved.connect(_on_color_a_slider)

	# Color B slider (Param_1)
	var b_slider: Node = panel.find_child("Param_1", true, false)
	if b_slider and b_slider.has_signal("slider_moved"):
		b_slider.slider_moved.connect(_on_color_b_slider)

	# Mode button (Btn_0)
	var mode_btn: Node = panel.find_child("Btn_0", true, false)
	if mode_btn:
		var area = mode_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _toggle_mode())


func _on_color_a_slider(_value: float) -> void:
	var slider: Node = get_node_or_null("GRADIENT/Param_0")
	if slider and slider.has_method("get_normalized_value"):
		var norm: float = slider.get_normalized_value()
		_color_a_idx = clampi(int(norm * 7.99), 0, 7)
		_color_a_mat.albedo_color = COLOR_PRESETS[_color_a_idx]
		_recalculate()


func _on_color_b_slider(_value: float) -> void:
	var slider: Node = get_node_or_null("GRADIENT/Param_1")
	if slider and slider.has_method("get_normalized_value"):
		var norm: float = slider.get_normalized_value()
		_color_b_idx = clampi(int(norm * 7.99), 0, 7)
		_color_b_mat.albedo_color = COLOR_PRESETS[_color_b_idx]
		_recalculate()


func _toggle_mode() -> void:
	_mode_hsv = not _mode_hsv
	_mode_label.text = "MODE: HSV" if _mode_hsv else "MODE: RGB"
	_recalculate()


# ═════════════════════════════════════════════════════════════════════════════
# INTERPOLATION
# ═════════════════════════════════════════════════════════════════════════════

func _recalculate() -> void:
	var ca: Color = COLOR_PRESETS[_color_a_idx]
	var cb: Color = COLOR_PRESETS[_color_b_idx]

	for i in _cubes.size():
		var t: float = float(i) / float(_cubes.size() - 1)
		var col: Color

		if _mode_hsv:
			col = _lerp_hsv(ca, cb, t)
		else:
			col = ca.lerp(cb, t)

		var mat: StandardMaterial3D = _cubes[i].material_override
		mat.albedo_color = col


func _lerp_hsv(a: Color, b: Color, t: float) -> Color:
	var ah: float = a.h
	var as_: float = a.s
	var av: float = a.v

	var bh: float = b.h
	var bs: float = b.s
	var bv: float = b.v

	# Shortest path around the hue wheel
	var dh: float = bh - ah
	if dh > 0.5:
		dh -= 1.0
	elif dh < -0.5:
		dh += 1.0

	var h: float = fmod(ah + dh * t + 1.0, 1.0)
	var s: float = lerpf(as_, bs, t)
	var v: float = lerpf(av, bv, t)

	return Color.from_hsv(h, s, v)


func apply_grid_config(config: Dictionary) -> void:
	pass
