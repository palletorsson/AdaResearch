class_name ParameterController3D
extends Node3D

## Compatibility wrapper for legacy parameter controllers.
## Uses the working commons/interactables horizontal slider so older
## artifacts keep their existing API but get real XR interaction.

signal value_changed(new_value: float)

const SLIDER_SCENE := preload("res://commons/interactables/slider_horizontal.tscn")

@export var parameter_name: String = "Parameter"
@export var min_value: float = 0.0
@export var max_value: float = 1.0
@export var default_value: float = 0.5
@export var step_size: float = 0.01
@export var slider_scale: Vector3 = Vector3(0.65, 0.65, 0.65)

var current_value: float = 0.5

var _slider: Node3D
var _suppress_emit: bool = false

func _ready() -> void:
	current_value = clamp(default_value, min_value, max_value)
	_ensure_slider()
	_sync_slider_from_value()

func _ensure_slider() -> void:
	if is_instance_valid(_slider):
		return

	_slider = SLIDER_SCENE.instantiate()
	_slider.name = "InteractableSliderCompat"
	_slider.scale = slider_scale
	add_child(_slider)

	if _slider.has_method("set_param_name"):
		_slider.call("set_param_name", parameter_name)
	if _slider.has_method("set_range"):
		_slider.call("set_range", min_value, max_value)
	if _slider.has_signal("slider_moved") and not _slider.is_connected("slider_moved", Callable(self, "_on_slider_moved")):
		_slider.connect("slider_moved", Callable(self, "_on_slider_moved"))

func _on_slider_moved(_value: Variant) -> void:
	if not is_instance_valid(_slider):
		return
	current_value = _slider.call("get_normalized_value")
	current_value = lerp(min_value, max_value, current_value)
	if step_size > 0.0:
		current_value = round(current_value / step_size) * step_size
		_sync_slider_from_value(true)
	if not _suppress_emit:
		value_changed.emit(current_value)

func _sync_slider_from_value(skip_emit: bool = false) -> void:
	if not is_instance_valid(_slider):
		return

	if _slider.has_method("set_param_name"):
		_slider.call("set_param_name", parameter_name)
	if _slider.has_method("set_range"):
		_slider.call("set_range", min_value, max_value)

	var normalized := inverse_lerp(min_value, max_value, clamp(current_value, min_value, max_value))
	_suppress_emit = skip_emit
	_slider.call("set_normalized_value", normalized)
	_suppress_emit = false

func set_value(new_value: float) -> void:
	current_value = clamp(new_value, min_value, max_value)
	if step_size > 0.0:
		current_value = round(current_value / step_size) * step_size
	_sync_slider_from_value(true)
	value_changed.emit(current_value)

func get_value() -> float:
	return current_value

func on_grab_start(_controller_position: Vector3) -> void:
	pass

func on_grab_update(_controller_position: Vector3) -> void:
	pass

func on_grab_end() -> void:
	pass
