# RackControlBase.gd
# Base class for all canonical rack 2D controls.
# Subclasses override _draw_control() to render their specific visual.
# These Controls define the LOOK — 3D interactables provide the PHYSICS.
#
# Drawing primitives used (_draw_rect, _draw_circle, _draw_arc, _draw_line)
# map 1:1 to SVG elements for pixel-perfect web parity.

extends Control
class_name RackControlBase

signal value_changed(new_value: float)

## Display label shown below the control
@export var control_label: String = "" : set = set_control_label

## Current value normalized 0-1
@export_range(0.0, 1.0) var normalized_value: float = 0.5 : set = set_normalized_value

## Override accent color (token name). Empty = use control_type default.
@export var accent_color_name: String = ""

## Control type key for token lookups (set by subclass)
var _control_type: String = "default"

## Resolved accent color
var _accent: Color = Color.WHITE
var _cell_bg: Color = Color.BLACK
var _track_groove: Color = Color.DIM_GRAY
var _label_color: Color = Color.WHITE
var _label_dim: Color = Color.GRAY


func _ready() -> void:
	_load_colors()
	custom_minimum_size = _get_canonical_size()
	size = custom_minimum_size
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
	var r := RackDesignTokens.get_layout("corner_radius_px", 4.0)
	# Rounded rect background
	var bg_rect := Rect2(Vector2.ZERO, size)
	draw_rect(bg_rect, _cell_bg)


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


func set_control_label(text: String) -> void:
	control_label = text
	queue_redraw()
