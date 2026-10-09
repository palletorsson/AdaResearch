# RackControlBase.gd
# Base class for all canonical rack 2D controls.
# Subclasses override _draw_control() to render their specific visual.
# Now also handles mouse/pointer input for VR 2D-in-3D interaction.

extends Control
class_name RackControlBase

signal value_changed(new_value: float)

## Display label shown below the control
@export var control_label: String = "" : set = set_control_label

## Current value normalized 0-1
@export_range(0.0, 1.0) var normalized_value: float = 0.5 : set = set_normalized_value

## Override accent color (token name). Empty = use control_type default.
@export var accent_color_name: String = ""

## Optional style variant for controls that support multiple visual modes.
@export var style_variant: String = "" : set = set_style_variant

## Control type key for token lookups (set by subclass)
var _control_type: String = "default"

## Resolved accent color
var _accent: Color = Color.WHITE
var _cell_bg: Color = Color.BLACK
var _track_groove: Color = Color.DIM_GRAY
var _label_color: Color = Color.WHITE
var _label_dim: Color = Color.GRAY

## Interaction state
var _is_dragging: bool = false


func _ready() -> void:
	_load_colors()
	custom_minimum_size = _get_canonical_size()
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _draw() -> void:
	_draw_background()
	_draw_control()
	_draw_label()


## Override in subclasses to render the specific control visual
func _draw_control() -> void:
	pass


## Override to return canonical pixel size from tokens
func _get_canonical_size() -> Vector2:
	return RackDesignTokens.get_size_px(_control_type)


func _draw_background() -> void:
	# Outer border (dark inset line — Rams recessed panel look)
	var border_color := Color(0.35, 0.33, 0.30)
	var bg_rect := Rect2(Vector2.ZERO, size)
	draw_rect(bg_rect, border_color)

	# Inner background (cream cell)
	var inset := 1.5
	var inner_rect := Rect2(Vector2(inset, inset), size - Vector2(inset * 2, inset * 2))
	draw_rect(inner_rect, _cell_bg)

	# Subtle inner shadow (top-left darker edge for depth)
	draw_line(Vector2(inset, inset), Vector2(size.x - inset, inset), Color(0.30, 0.28, 0.26, 0.4), 0.5)
	draw_line(Vector2(inset, inset), Vector2(inset, size.y - inset), Color(0.30, 0.28, 0.26, 0.4), 0.5)

	# Subtle highlight (bottom-right lighter edge)
	draw_line(Vector2(inset, size.y - inset), Vector2(size.x - inset, size.y - inset), Color(0.85, 0.82, 0.78, 0.3), 0.5)
	draw_line(Vector2(size.x - inset, inset), Vector2(size.x - inset, size.y - inset), Color(0.85, 0.82, 0.78, 0.3), 0.5)


func _draw_label() -> void:
	if control_label.is_empty():
		return
	var font := get_theme_default_font()
	var fs := RackDesignTokens.get_font_size("label_font_size")
	var text_w := font.get_string_size(control_label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	var x := (size.x - text_w) / 2.0
	var y := size.y - 4.0
	draw_string(font, Vector2(x, y), control_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _label_color)


func _load_colors() -> void:
	if accent_color_name.is_empty():
		_accent = RackDesignTokens.get_control_accent(_control_type)
	else:
		_accent = RackDesignTokens.get_color(accent_color_name)
	_cell_bg = RackDesignTokens.get_color("cell_bg")
	_track_groove = RackDesignTokens.get_color("track_groove")
	_label_color = RackDesignTokens.get_color("label_text")
	_label_dim = RackDesignTokens.get_color("label_dim")


func set_normalized_value(val: float) -> void:
	var clamped := clampf(val, 0.0, 1.0)
	if normalized_value != clamped:
		normalized_value = clamped
		value_changed.emit(normalized_value)
		queue_redraw()


func get_normalized_value() -> float:
	return normalized_value


func set_control_label(text: String) -> void:
	control_label = text
	queue_redraw()


func set_style_variant(value: String) -> void:
	style_variant = value
	queue_redraw()


# ── 2D Input Handling (for VR Viewport2Din3D interaction) ──────────

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_dragging = true
				_on_pointer_pressed(event.position)
				accept_event()
			else:
				_is_dragging = false
				_on_pointer_released(event.position)
				accept_event()
	elif event is InputEventMouseMotion and _is_dragging:
		_on_pointer_dragged(event.position)
		accept_event()


## Override in subclasses for press behavior
func _on_pointer_pressed(_pos: Vector2) -> void:
	pass

## Override in subclasses for drag behavior
func _on_pointer_dragged(_pos: Vector2) -> void:
	pass

## Override in subclasses for release behavior
func _on_pointer_released(_pos: Vector2) -> void:
	pass
