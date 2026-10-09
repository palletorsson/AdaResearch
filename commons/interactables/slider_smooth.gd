@tool
extends Node3D

# Range and readout adapter. The joint constrains geometry; the held hand stays free.

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
var _surface_value: Label
var _surface_viewport: SubViewport

var _interaction: Node3D

func _ready() -> void:
	if not Engine.is_editor_hint() and _slider is XRToolsInteractableSlider:
		_interaction = preload("res://commons/interactables/scalar_pointer.gd").attach(self, _slider)
	_connect_slider_signal()
	_update_label(_current_slider_value())
	

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
	var pos = remap(clampf(val, 0.0, 1.0), 0.0, 1.0, s_min, s_max)
	_slider.set("slider_position", pos)
	_update_label(_current_slider_value())

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
		norm = 0.0 if is_equal_approx(s_min, s_max) else remap(scalar_value, s_min, s_max, 0.0, 1.0)

	# Map to logical range
	var logical_value = lerp(range_min, range_max, norm)

	var text := _format_value(logical_value)
	if text == _last_display_text:
		return
	_last_display_text = text
	_label.text = text
	if is_instance_valid(_surface_value):
		_surface_value.text = text
		_surface_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

## Optional live 2D value screen seated on the horizontal panel fader. The
## original label remains an internal compatibility sink but is never drawn.
## Rendering happens only when the formatted value changes.
func use_panel_value_surface() -> void:
	if is_instance_valid(_surface_value): return
	if not _ensure_label(): return
	_label.hide()
	# The handle is 35 mm tall. Keep the value window above its swept area,
	# including at the left endpoint, with a backing that covers the whole screen.
	var frame_mesh := get_node("Frame/PanelMesh") as MeshInstance3D
	frame_mesh.mesh = frame_mesh.mesh.duplicate()
	frame_mesh.mesh.size.x = 0.106
	var display := preload("res://commons/ui/control_value_surface.gd").build(
		get_node("Frame"), Vector2(0.078, 0.026), Vector3(-0.035, -0.061, 0.0085), 90.0)
	_surface_viewport = display.viewport
	_surface_value = display.label
	_surface_value.text = _last_display_text

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


func pointer_event(event: XRToolsPointerEvent) -> void:
	if is_instance_valid(_interaction): _interaction.pointer_event(event)
