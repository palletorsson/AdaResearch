@tool
extends Node3D

## VR Audio Control Dial
## Handles mapping from hinge rotation to normalized values and label updates

signal hinge_moved(angle)

@export var hinge_node: NodePath = NodePath("DialOrigin/InteractableHinge")
@export var label_node: NodePath = NodePath("Frame/Label3DValue")
@export_range(0, 6) var decimal_places: int = 1

@onready var _hinge: Node = get_node_or_null(hinge_node)
@onready var _label: Label3D = get_node_or_null(label_node)

func _ready() -> void:
	if _hinge:
		_hinge.hinge_moved.connect(_on_hinge_moved)
		_update_label(_hinge.get("hinge_position"))

func _process(_delta: float) -> void:
	# Keep the handle on the board (lock local Y and Z to origin)
	var handle = get_node_or_null("DialOrigin/InteractableHinge/HandleOrigin/InteractableHandle")
	if handle and handle.is_picked_up():
		handle.transform.origin.y = 0
		handle.transform.origin.z = 0

func _on_hinge_moved(angle: float) -> void:
	# Normalize angle to 0-1 based on limits
	var h_min = _hinge.get("hinge_limit_min")
	var h_max = _hinge.get("hinge_limit_max")
	var normalized = remap(angle, h_min, h_max, 0.0, 1.0)
	_update_label(normalized)
	hinge_moved.emit(angle)

func _update_label(value: float) -> void:
	if _label:
		_label.text = String.num(value, decimal_places)

func set_param_name(text: String):
	var name_label = get_node_or_null("Frame/LabelName")
	if name_label: name_label.text = text

func get_normalized_value() -> float:
	if not _hinge: return 0.5
	var angle = _hinge.get("hinge_position")
	var h_min = _hinge.get("hinge_limit_min")
	var h_max = _hinge.get("hinge_limit_max")
	return remap(angle, h_min, h_max, 0.0, 1.0)

func set_normalized_value(val: float):
	if not _hinge: return
	var h_min = _hinge.get("hinge_limit_min")
	var h_max = _hinge.get("hinge_limit_max")
	var angle = remap(val, 0.0, 1.0, h_min, h_max)
	_hinge.set("hinge_position", angle)
	_update_label(val)
