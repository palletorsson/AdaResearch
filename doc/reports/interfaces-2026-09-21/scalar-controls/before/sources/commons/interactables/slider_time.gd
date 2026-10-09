@tool
extends Node3D

@export var slider_node: NodePath = NodePath("SliderOrigin/InteractableSlider")
@export var label_node: NodePath = NodePath("Frame/Label3DValue")
@export var min_value: float = 0.0
@export var max_value: float = 100.0
@export_range(0, 6, 1) var decimal_places: int = 0
@export var label_prefix: String = " "
@export var label_suffix: String = ""

var _slider: Node
var _label: Label3D
var _last_text := ""

func _ready() -> void:
	set_process(true)
	_cache_nodes()
	_connect_slider_signal()
	_update_label_from_slider()

 
func _cache_nodes() -> void:
	if not _slider:
		_slider = get_node_or_null(slider_node)
	if not _label:
		_label = get_node_or_null(label_node)
	if not _label:
		push_warning("TimeSlider: Label node not found at %s" % label_node)

func _connect_slider_signal() -> void:
	if not _slider:
		push_warning("TimeSlider: Slider node not found at %s" % slider_node)
		return
	if _slider.has_signal("slider_moved") and not _slider.is_connected("slider_moved", Callable(self, "_on_slider_moved")):
		_slider.connect("slider_moved", Callable(self, "_on_slider_moved"))

func _on_slider_moved(position: float) -> void:
	_apply_value_to_label(position)

func _update_label_from_slider() -> void:
	_cache_nodes()
	if not _slider:
		return
	var position_value = _slider.get("slider_position")
	if position_value == null:
		return
	_apply_value_to_label(float(position_value))

func _apply_value_to_label(slider_position_value: float) -> void:
	if not _label:
		return
	var time_value = _slider_position_to_time(slider_position_value)
	var display_text = _format_time_value(time_value)
	if display_text == _last_text:
		return
	_last_text = display_text
	_label.text = display_text

func _slider_position_to_time(position_value: float) -> float:
	var slider_limits := _get_slider_limits()
	var range = max(0.0001, slider_limits.y - slider_limits.x)
	var normalized = clamp((position_value - slider_limits.x) / range, 0.0, 1.0)
	return lerp(min_value, max_value, normalized)

func _get_slider_limits() -> Vector2:
	if _slider and _slider.has_method("get"):
		var min_limit = float(_slider.get("slider_limit_min"))
		var max_limit = float(_slider.get("slider_limit_max"))
		return Vector2(min_limit, max_limit)
	return Vector2.ZERO

func _format_time_value(value: float) -> String:
	var decimals = clamp(decimal_places, 0, 6)
	return "%s%s%s" % [label_prefix, String.num(value, decimals), label_suffix]
