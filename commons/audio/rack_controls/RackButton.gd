# RackButton.gd
# Dieter Rams style switch — clean circle, copper indicator when active.

extends RackControlBase
class_name RackButton

var is_pressed: bool = false : set = set_is_pressed
@export var toggle_mode: bool = false
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
	var label_margin := RackDesignTokens.get_layout("label_bottom_margin_px", 24.0)
	var center := Vector2(size.x / 2.0, (size.y - label_margin) / 2.0 + 2.0)
	var btn_r: float = min(size.x, size.y - label_margin) * 0.32

	# Outer ring — thin black circle
	draw_arc(center, btn_r, 0, TAU, 32, Color(0.1, 0.1, 0.1), 1.0)

	# Button body — dark circle (pressed = accent color, released = dark)
	var body_color: Color = _pressed_color if is_pressed else _released_color
	draw_circle(center, btn_r - 1.5, body_color)

	# Inner ring detail
	draw_arc(center, btn_r - 1.5, 0, TAU, 32, Color(body_color.lightened(0.15)), 0.5)

	# Center indicator — copper dot when pressed, dark when off
	var dot_color := _accent if is_pressed else Color(0.2, 0.2, 0.2, 0.4)
	draw_circle(center, 2.5, dot_color)


func _on_pointer_pressed(_pos: Vector2) -> void:
	if toggle_mode:
		set_is_pressed(not is_pressed)
	else:
		set_is_pressed(true)

func _on_pointer_released(_pos: Vector2) -> void:
	if not toggle_mode:
		set_is_pressed(false)
