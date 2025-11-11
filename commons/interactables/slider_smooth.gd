@tool
extends Node3D

@export var slider_node: NodePath = NodePath("SliderOrigin/InteractableSlider")
@export var label_node: NodePath = NodePath("Frame/Label3DValue")
@export_range(0, 6) var decimal_places: int = 2
 
@onready var _slider: Node = get_node_or_null(slider_node)
@onready var _label: Label3D = get_node_or_null(label_node)
var _last_display_text: String = ""

func _ready() -> void:
	_connect_slider_signal()
	_update_label(_current_slider_value())

func _connect_slider_signal() -> void:
	if not _slider:
		push_warning("SliderSmooth: Slider node not found at %s" % slider_node)
		return
	if _slider.has_signal("slider_moved") and not _slider.is_connected("slider_moved", Callable(self, "_on_slider_moved")):
		_slider.connect("slider_moved", Callable(self, "_on_slider_moved"))

func _on_slider_moved(position) -> void:
	print("SliderSmooth: _on_slider_moved called with position: ", position)
	_update_label(position)

func _current_slider_value():
	if not _slider:
		return null
	var value = _slider.get("slider_position")
	print("SliderSmooth: _current_slider_value returning: ", value)
	return value

func _update_label(value) -> void:
	if not _ensure_label():
		return
	var text := _format_value(value)
	print("SliderSmooth: _update_label - value: ", value, " formatted text: ", text, " last_text: ", _last_display_text)
	if text == _last_display_text:
		return
	_last_display_text = text
	_label.text = text
	print("SliderSmooth: Label updated to: ", text)

func _ensure_label() -> bool:
	if _label:
		return true
	_label = get_node_or_null(label_node)
	if not _label:
		push_warning("SliderSmooth: Label node not found at %s" % label_node)
		return false
	return true

func _format_value(value) -> String:
	match typeof(value):
		TYPE_VECTOR2:
			return _format_vector_value(value)
		TYPE_FLOAT, TYPE_INT:
			return _format_scalar_value(float(value))
		TYPE_NIL:
			return "--"
		_:
			return str(value)

func _format_scalar_value(value: float) -> String:
	var decimals = clamp(decimal_places, 0, 6)
	return String.num(value, decimals)

func _format_vector_value(value: Vector2) -> String:
	var decimals = clamp(decimal_places, 0, 6)
	var y_text := String.num(value.x, decimals)
	var z_text := String.num(value.y, decimals)
	return "Y: %s Z: %s" % [y_text, z_text]
