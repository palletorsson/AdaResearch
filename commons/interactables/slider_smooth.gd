@tool
extends Node3D

# Dedicated script for Audio Control Sliders (Horizontal and Vertical)
# Handles constraint enforcement to keep handles locked to track

@export var slider_node: NodePath = NodePath("SliderOrigin/InteractableSlider")
@export var label_node: NodePath = NodePath("Frame/Label3DValue")
@export_range(0, 6) var decimal_places: int = 2

## Maximum distance handle can deviate from track before snap-back
@export var max_track_deviation: float = 0.02
## Speed of snap-back animation when handle is released off-track  
@export var snap_back_speed: float = 15.0
## How strongly to enforce constraints while grabbed (higher = stiffer)
@export var constraint_strength: float = 0.8

var range_min: float = 0.0
var range_max: float = 1.0

signal slider_moved(value)

@onready var _slider: Node = get_node_or_null(slider_node)
@onready var _label: Label3D = get_node_or_null(label_node)
var _last_display_text: String = ""

# Desktop pointer drag state
var _pointer_dragging: bool = false
var _pointer_drag_start_world: Vector3 = Vector3.ZERO
var _pointer_drag_start_pos: float = 0.0

# Track the handle for constraint enforcement
var _handle: RigidBody3D = null
var _handle_origin: Node3D = null
var _is_snapping_back: bool = false

func _ready() -> void:
	_connect_slider_signal()
	_update_label(_current_slider_value())
	
	# Cache handle references
	_handle = get_node_or_null("SliderOrigin/InteractableSlider/HandleOrigin/InteractableHandle")
	_handle_origin = get_node_or_null("SliderOrigin/InteractableSlider/HandleOrigin")

func _process(delta: float) -> void:
	if not _slider:
		return
	
	var s_min = _slider.get("slider_limit_min")
	var s_max = _slider.get("slider_limit_max")
	if s_min == null: s_min = 0.0
	if s_max == null: s_max = 0.14
	
	# Get slider axis (horizontal uses X, vertical uses Y)
	var slider_axis_raw = _slider.get("slider_axis")
	var slider_axis: Vector3 = slider_axis_raw if slider_axis_raw != null else Vector3(1, 0, 0)
	
	var is_vertical = slider_axis.y != 0.0
	
	# Clamp the slider's transform position directly
	if is_vertical:
		var slider_y = _slider.transform.origin.y
		var clamped_y = clamp(slider_y, s_min, s_max)
		if slider_y != clamped_y:
			_slider.transform.origin.y = clamped_y
			_slider.slider_position = clamped_y
	else:
		var slider_x = _slider.transform.origin.x
		var clamped_x = clamp(slider_x, s_min, s_max)
		if slider_x != clamped_x:
			_slider.transform.origin.x = clamped_x
			_slider.slider_position = clamped_x
	
	# Enforce handle constraints to keep it locked to track
	_enforce_handle_constraints(delta, is_vertical)

func _enforce_handle_constraints(_delta: float, _is_vertical: bool) -> void:
	if not _handle or not _handle_origin:
		return

	var s_min = _slider.get("slider_limit_min") if _slider else 0.0
	var s_max = _slider.get("slider_limit_max") if _slider else 0.14
	if s_min == null: s_min = 0.0
	if s_max == null: s_max = 0.14

	# Handle always moves along X in slider-local space (SliderOrigin rotation
	# converts this to Y in world space for vertical sliders).
	# The handle's local x is an OFFSET from the slider's current position, so
	# its legal range is [s_min - pos, s_max - pos] — clamping to [s_min, s_max]
	# (always ≥ 0) made dragging toward smaller values impossible (one-way bug).
	var cur_pos: float = 0.0
	var cur_raw = _slider.get("slider_position")
	if cur_raw is float or cur_raw is int:        # scalar sliders only; 2D slider_plane (Vector2) drives its own constraints
		cur_pos = float(cur_raw)
	var handle_local_pos = _handle.transform.origin
	var clamped_x = clamp(handle_local_pos.x, s_min - cur_pos, s_max - cur_pos)
	_handle.transform.origin = Vector3(clamped_x, 0.0, 0.0)

	# Lock rotation
	_handle.transform.basis = Basis.IDENTITY

func _connect_slider_signal() -> void:
	if not _slider:
		push_warning("SliderSmooth: Slider node not found at %s" % slider_node)
		return
	if _slider.has_signal("slider_moved") and not _slider.is_connected("slider_moved", Callable(self, "_on_slider_moved")):
		_slider.connect("slider_moved", Callable(self, "_on_slider_moved"))

func set_range(p_min: float, p_max: float) -> void:
	range_min = p_min
	range_max = p_max
	_update_label(_current_slider_value())

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
	return _slider.get("slider_position")

func _update_label(value) -> void:
	if not _ensure_label():
		return

	# Handle Vector2 input (use x component for 1D slider)
	var scalar_value: float = 0.0
	if value is Vector2:
		scalar_value = value.x
	elif value != null:
		scalar_value = float(value)

	# Calculate normalized value from physical position
	var norm = 0.0
	if _slider:
		var s_min = _slider.get("slider_limit_min")
		var s_max = _slider.get("slider_limit_max")
		if s_min == null: s_min = 0.0
		if s_max == null: s_max = 1.0
		norm = remap(scalar_value, s_min, s_max, 0.0, 1.0)

	# Map to logical range
	var logical_value = lerp(range_min, range_max, norm)

	var text := _format_value(logical_value)
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


# ── Desktop pointer interaction ──────────────────────────────────────────────

func pointer_event(event: XRToolsPointerEvent) -> void:
	if not _slider:
		return
	match event.event_type:
		XRToolsPointerEvent.Type.PRESSED:
			_pointer_dragging = true
			_pointer_drag_start_world = event.position
			_pointer_drag_start_pos = _slider.slider_position
		XRToolsPointerEvent.Type.MOVED:
			if _pointer_dragging:
				_handle_pointer_drag(event)
		XRToolsPointerEvent.Type.RELEASED, XRToolsPointerEvent.Type.EXITED:
			_pointer_dragging = false


func _handle_pointer_drag(event: XRToolsPointerEvent) -> void:
	var slider_origin := get_node_or_null("SliderOrigin") as Node3D
	if not slider_origin or not _slider:
		return
	# SliderOrigin's local X axis is the slider's movement direction in world space
	var slider_axis_world := slider_origin.global_transform.basis.x.normalized()
	var delta_world := event.position - _pointer_drag_start_world
	var projected_offset := delta_world.dot(slider_axis_world)
	_slider.move_slider(_pointer_drag_start_pos + projected_offset)
