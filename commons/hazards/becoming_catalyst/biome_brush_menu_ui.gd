extends Control
## Biome Brush menu — the Tilt-Brush-style 2D panel rendered on the left hand via
## viewport_2d_in_3d. A grid of biome elements (the "layer" you paint) + a brush
## size control. The right-hand pointer selects; signals drive BiomeBrushController.
## See doc/VR_EDITING_SYSTEM.md and doc/PAINT_LAYERS.md.

signal element_selected(element_name: String)
signal size_changed(radius: int)

const ELEMENTS: Array = ["tree", "critter", "flower", "mushroom", "large_critter"]
const LABELS: Array = ["Tree", "Critter", "Flower", "Mushroom", "Big Critter"]
const COLORS: Array = [
	Color(0.45, 0.85, 0.50), Color(1.0, 0.70, 0.36), Color(1.0, 0.55, 0.76),
	Color(0.80, 0.55, 0.40), Color(0.95, 0.45, 0.30),
]

var _buttons: Array = []
var _selected: int = 0
var _size_label: Label = null


func _ready() -> void:
	# Size comes from the viewport_2d_in_3d (full-rect anchors fill it); setting
	# `size` here would just warn. custom_minimum_size keeps the desktop preview sane.
	custom_minimum_size = Vector2(500, 420)

	# Background.
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.10, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 18; root.offset_top = 14
	root.offset_right = -18; root.offset_bottom = -14
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	# Header.
	var title := Label.new()
	title.text = "◆  BIOME  BRUSH"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.45, 0.85, 0.55))
	root.add_child(title)

	var sub := Label.new()
	sub.text = "LAYER"
	sub.add_theme_font_size_override("font_size", 15)
	sub.add_theme_color_override("font_color", Color(0.6, 0.64, 0.72))
	root.add_child(sub)

	# Element grid (the "brushes" — what you paint).
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	root.add_child(grid)
	for i in ELEMENTS.size():
		var b := Button.new()
		b.text = str(LABELS[i])
		b.custom_minimum_size = Vector2(146, 86)
		b.add_theme_font_size_override("font_size", 18)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_on_pick.bind(i))
		grid.add_child(b)
		_buttons.append(b)

	# Brush size.
	var size_row := HBoxContainer.new()
	size_row.add_theme_constant_override("separation", 12)
	root.add_child(size_row)
	var size_cap := Label.new()
	size_cap.text = "SIZE"
	size_cap.add_theme_font_size_override("font_size", 15)
	size_cap.add_theme_color_override("font_color", Color(0.6, 0.64, 0.72))
	size_cap.custom_minimum_size = Vector2(58, 0)
	size_row.add_child(size_cap)
	var slider := HSlider.new()
	slider.min_value = 1; slider.max_value = 6; slider.step = 1; slider.value = 2
	slider.custom_minimum_size = Vector2(300, 40)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_size)
	size_row.add_child(slider)
	_size_label = Label.new()
	_size_label.text = "r2"
	_size_label.add_theme_font_size_override("font_size", 20)
	_size_label.add_theme_color_override("font_color", Color(0.93, 0.96, 1.0))
	_size_label.custom_minimum_size = Vector2(48, 0)
	size_row.add_child(_size_label)

	_refresh()
	# Emit the initial selection so the brush starts in sync.
	call_deferred("emit_signal", "element_selected", str(ELEMENTS[_selected]))


func _on_pick(i: int) -> void:
	_selected = clampi(i, 0, ELEMENTS.size() - 1)
	_refresh()
	element_selected.emit(str(ELEMENTS[_selected]))


func _on_size(v: float) -> void:
	var r := int(v)
	if _size_label:
		_size_label.text = "r%d" % r
	size_changed.emit(r)


## Called by the 3D wrapper when the brush cycles element via Ax, to keep the
## panel highlight in sync with the actual active element.
func set_selected_element(element_name: String) -> void:
	var idx := ELEMENTS.find(element_name)
	if idx >= 0:
		_selected = idx
		_refresh()


func _refresh() -> void:
	for i in _buttons.size():
		var b: Button = _buttons[i]
		var c: Color = COLORS[i]
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(c.r, c.g, c.b, 0.30 if i != _selected else 0.85)
		sb.corner_radius_top_left = 8; sb.corner_radius_top_right = 8
		sb.corner_radius_bottom_left = 8; sb.corner_radius_bottom_right = 8
		if i == _selected:
			sb.border_width_left = 3; sb.border_width_right = 3
			sb.border_width_top = 3; sb.border_width_bottom = 3
			sb.border_color = Color(1.0, 1.0, 1.0, 0.9)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		b.add_theme_color_override("font_color", Color(0.05, 0.06, 0.09) if i == _selected else Color(0.93, 0.96, 1.0))
