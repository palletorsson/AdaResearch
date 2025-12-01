@tool
extends XRToolsInteractableHandleDriven

signal slider_moved(value)

@export var limit_min: float = -0.2
@export var limit_max: float = 0.2
@export var step: float = 0.0
@export var slider_value: float = 0.0 : set = _set_slider_value
@export var default_value: float = 0.0
@export var default_on_release: bool = false

# Auto-drive configuration
@export var auto_drive: bool = false
@export var auto_drive_speed: float = 1.0
var _time_accumulator: float = 0.0

func _ready() -> void:
	super()
	_apply_transform(slider_value)
	if released.connect(_on_slider_released):
		push_error("Cannot connect slider released signal")

func _process(delta: float) -> void:
	# If grabbed, handle manual interaction
	if not grabbed_handles.is_empty():
		var offset_sum := 0.0
		for item in grabbed_handles:
			var handle := item as XRToolsInteractableHandle
			if handle:
				# Calculate offset in local Y axis
				var diff = handle.global_transform.origin - handle.handle_origin.global_transform.origin
				# Project onto local Y axis
				offset_sum += diff.dot(global_transform.basis.y)

		var offset_val := offset_sum / grabbed_handles.size()
		move_slider(slider_value + offset_val)
		return

	# If not grabbed and auto-drive is on, oscillate
	if auto_drive:
		_time_accumulator += delta * auto_drive_speed
		# Oscillate between 0 and 1 using sine wave
		var t = (sin(_time_accumulator) + 1.0) * 0.5
		# Lerp between min and max limits
		var new_val = lerp(limit_min, limit_max, t)
		move_slider(new_val)

func move_slider(value: float) -> void:
	var new_value := _do_move_slider(value)
	if is_equal_approx(new_value, slider_value):
		return

	slider_value = new_value
	_apply_transform(slider_value)
	emit_signal("slider_moved", slider_value)

func _set_slider_value(value: float) -> void:
	slider_value = _do_move_slider(value)
	_apply_transform(slider_value)

func _apply_transform(value: float) -> void:
	transform.origin.y = value
	# Keep X and Z at 0
	transform.origin.x = 0
	transform.origin.z = 0

func _do_move_slider(value: float) -> float:
	value = _apply_steps(value)
	value = _apply_limits(value)
	return value

func _apply_steps(value: float) -> float:
	if step > 0.0:
		value = round(value / step) * step
	return value

func _apply_limits(value: float) -> float:
	return clamp(value, limit_min, limit_max)

func _on_slider_released(_interactable) -> void:
	if default_on_release:
		move_slider(default_value)
