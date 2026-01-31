extends Node3D
class_name CurveControlPoint

## Control point for EditableCurve - grabbable handle for curve manipulation

signal position_changed(new_position: Vector3)

var _last_position: Vector3
var _is_grabbed: bool = false

func _ready() -> void:
	_last_position = position

func _process(_delta: float) -> void:
	if position != _last_position:
		position_changed.emit(position)
		_last_position = position

# XRToolsPickable callbacks
func _on_picked_up(_pickable) -> void:
	_is_grabbed = true

func _on_dropped(_pickable) -> void:
	_is_grabbed = false

func is_grabbed() -> bool:
	return _is_grabbed
