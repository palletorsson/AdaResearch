@tool
extends XRToolsInteractableHandleDriven

signal slider_moved(position)

@export var limit_y_min: float = -0.2
@export var limit_y_max: float = 0.2
@export var limit_z_min: float = -0.2
@export var limit_z_max: float = 0.2
@export var step_y: float = 0.0
@export var step_z: float = 0.0
@export var slider_position: Vector2 = Vector2.ZERO : set = _set_slider_position
@export var default_position: Vector2 = Vector2.ZERO
@export var default_on_release: bool = false

func _ready() -> void:
	super()
	_apply_transform(slider_position)
	if released.connect(_on_slider_released):
		push_error("Cannot connect slider released signal")

func _process(_delta: float) -> void:
	if grabbed_handles.is_empty():
		return

	var offset_sum := Vector3.ZERO
	for item in grabbed_handles:
		var handle := item as XRToolsInteractableHandle
		if handle:
			offset_sum += handle.global_transform.origin - handle.handle_origin.global_transform.origin

	offset_sum = offset_sum * global_transform.basis
	var offset_vec := Vector2(offset_sum.y, offset_sum.z) / grabbed_handles.size()
	move_slider(slider_position + offset_vec)

func move_slider(position: Vector2) -> void:
	var new_position := _do_move_slider(position)
	if new_position.is_equal_approx(slider_position):
		return

	slider_position = new_position
	_apply_transform(slider_position)
	emit_signal("slider_moved", slider_position)

func _set_slider_position(position: Vector2) -> void:
	slider_position = _do_move_slider(position)
	_apply_transform(slider_position)

func _apply_transform(position: Vector2) -> void:
	transform.origin.y = position.x
	transform.origin.z = position.y

func _do_move_slider(position: Vector2) -> Vector2:
	position = _apply_steps(position)
	position = _apply_limits(position)
	return position

func _apply_steps(position: Vector2) -> Vector2:
	if step_y:
		position.x = round(position.x / step_y) * step_y
	if step_z:
		position.y = round(position.y / step_z) * step_z
	return position

func _apply_limits(position: Vector2) -> Vector2:
	position.x = clamp(position.x, limit_y_min, limit_y_max)
	position.y = clamp(position.y, limit_z_min, limit_z_max)
	return position

func _on_slider_released(_interactable) -> void:
	if default_on_release:
		move_slider(default_position)
