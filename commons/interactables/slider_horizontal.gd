@tool
extends Node3D

# Dedicated script for Horizontal Sliders
# Enforces 0-degree rotation on the interactable slider

@export var slider_node: NodePath = NodePath("SliderOrigin/InteractableSlider")
@export var label_node: NodePath = NodePath("Frame/Label3DValue")
@export_range(0, 6) var decimal_places: int = 2

signal slider_moved(value)

@onready var _slider: Node = get_node_or_null(slider_node)
@onready var _label: Label3D = get_node_or_null(label_node)
var _last_display_text: String = ""

func _ready() -> void:
	# Enforce usage of interactable slider
	if _slider:
		# Ensure 0 rotation for horizontal sliding (X-axis)
		_slider.rotation_degrees.z = 0
		
	_connect_slider_signal()
	_update_label(_current_slider_value())

func _process(_delta: float) -> void:
	# Keep the handle on the board (lock Y and Z local to its origin)
	var handle = get_node_or_null("SliderOrigin/InteractableSlider/HandleOrigin/InteractableHandle")
	if handle and handle.is_picked_up():
		handle.transform.origin.y = 0
		handle.transform.origin.z = 0

func _connect_slider_signal() -> void:
	if not _slider:
		push_warning("SliderHorizontal: Slider node not found at %s" % slider_node)
		return
	if _slider.has_signal("slider_moved") and not _slider.is_connected("slider_moved", Callable(self, "_on_slider_moved")):
		_slider.connect("slider_moved", Callable(self, "_on_slider_moved"))

func _on_slider_moved(position) -> void:
	_update_label(position)
	slider_moved.emit(position)

func get_normalized_value() -> float:
	if not _slider: return 0.5
	var val = _slider.get("slider_position")
	var s_min = _slider.get("slider_limit_min")
	var s_max = _slider.get("slider_limit_max")
	if s_min == null: s_min = 0.0
	if s_max == null: s_max = 1.0
	if s_max == s_min: return 0.0
	return remap(val, s_min, s_max, 0.0, 1.0)

func set_normalized_value(val: float):
	if not _slider: return
	var s_min = _slider.get("slider_limit_min")
	var s_max = _slider.get("slider_limit_max")
	if s_min == null: s_min = 0.0
	if s_max == null: s_max = 1.0
	var pos = remap(val, 0.0, 1.0, s_min, s_max)
	_slider.set("slider_position", pos)
	_update_label(pos)

func _current_slider_value():
	if not _slider:
		return null
	var value = _slider.get("slider_position")
	return value

func _update_label(value) -> void:
	if not _ensure_label():
		return
	var text := _format_value(value)
	if text == _last_display_text:
		return
	_last_display_text = text
	_label.text = text

func set_param_name(text: String):
	var name_label = get_node_or_null("Frame/LabelName")
	if name_label: name_label.text = text

func _ensure_label() -> bool:
	if _label:
		return true
	_label = get_node_or_null(label_node)
	if not _label:
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
