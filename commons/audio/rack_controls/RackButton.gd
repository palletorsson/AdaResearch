# RackButton.gd
# Canonical 2D push button — rounded rect with glow state.
# Draws: body, indicator ring, label. Supports momentary and toggle modes.

extends RackControlBase
class_name RackButton

## Whether the button is currently pressed/active
var is_pressed: bool = false : set = set_is_pressed

## Toggle mode: stays on/off. False = momentary.
@export var toggle_mode: bool = false

## Colors for each state
@export var pressed_color_name: String = "button_pressed"
@export var released_color_name: String = "button_released"

var _pressed_color: Color
var _released_color: Color


func _init() -> void:
	_control_type = "btn"


func _ready() -> void:
	super._ready()
	_pressed_color = RackDesignTokens.get_color(pressed_color_name)
	_released_color = RackDesignTokens.get_color(released_color_name)


func set_is_pressed(val: bool) -> void:
	is_pressed = val
	normalized_value = 1.0 if val else 0.0
	queue_redraw()


func _draw_control() -> void:
	var btn_r := RackDesignTokens.get_layout("button_corner_radius_px", 6.0)
	var label_margin := RackDesignTokens.get_layout("label_bottom_margin_px", 24.0)

	# Button body area
	var btn_margin := 6.0
	var btn_rect := Rect2(
		Vector2(btn_margin, btn_margin),
		Vector2(size.x - btn_margin * 2, size.y - label_margin - btn_margin)
	)

	# Current state color
	var body_color: Color
	var glow_alpha: float
	if is_pressed:
		body_color = _pressed_color
		glow_alpha = 0.5
	else:
		body_color = _released_color
		glow_alpha = 0.2

	# Outer glow
	var glow_rect := Rect2(
		btn_rect.position - Vector2(2, 2),
		btn_rect.size + Vector2(4, 4)
	)
	draw_rect(glow_rect, Color(body_color, glow_alpha))

	# Button body
	draw_rect(btn_rect, body_color)

	# Inner highlight (top edge)
	var highlight := Color(1.0, 1.0, 1.0, 0.15)
	draw_line(
		btn_rect.position + Vector2(2, 1),
		Vector2(btn_rect.end.x - 2, btn_rect.position.y + 1),
		highlight, 1.0
	)

	# Center dot indicator
	var center := btn_rect.get_center()
	var dot_r := 3.0
	var dot_color := Color(1.0, 1.0, 1.0, 0.6) if is_pressed else Color(0.3, 0.3, 0.3, 0.4)
	draw_circle(center, dot_r, dot_color)
