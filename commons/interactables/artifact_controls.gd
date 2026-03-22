extends Node3D
class_name ArtifactControls

## Helper for adding VR sliders and buttons to artifacts.
## Reduces 10+ lines of boilerplate per control to one call.
##
## Usage:
##   var controls := ArtifactControls.new()
##   controls.position = Vector3(2.0, 1.5, 0.0)
##   add_child(controls)
##
##   controls.add_slider("STIFFNESS", 0.5, func(v): stiffness = lerp(10.0, 500.0, v))
##   controls.add_slider("WIND", 0.3, func(v): wind_strength = v * 10.0)
##   controls.add_button("RESET", func(): reset_simulation())
##   controls.add_label("status_label", "STABLE")

const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

var _slot_index: int = 0
var _slot_spacing: float = 0.12
var _scale: Vector3 = Vector3(0.8, 0.8, 0.8)
var _tilt: float = -30.0  # degrees, angled toward player
var _labels: Dictionary = {}  # name -> Label3D


func _ready() -> void:
	# Face the player by default (can be overridden by parent)
	pass


## Add a VR slider.
## Returns the slider node for additional configuration.
func add_slider(
	param_name: String,
	initial_value: float,
	on_change: Callable,
	min_val: float = 0.0,
	max_val: float = 1.0
) -> Node:
	var slider = SLIDER_HORIZONTAL.instantiate()
	slider.name = "Slider_%s" % param_name.replace(" ", "_")
	slider.position = Vector3(0, -_slot_index * _slot_spacing, 0)
	slider.rotation_degrees.x = _tilt
	slider.scale = _scale

	# Set parameter name label
	var name_label = slider.get_node_or_null("Frame/LabelName")
	if name_label:
		name_label.text = param_name

	# Set range if the slider supports it
	if slider.has_method("set_range"):
		slider.set_range(min_val, max_val)

	add_child(slider)

	# Connect signal
	slider.slider_moved.connect(func(_pos):
		if slider.has_method("get_normalized_value"):
			var normalized: float = slider.get_normalized_value()
			on_change.call(normalized)
	)

	# Set initial value
	if slider.has_method("set_normalized_value"):
		var norm := (initial_value - min_val) / maxf(max_val - min_val, 0.001)
		slider.set_normalized_value(clampf(norm, 0.0, 1.0))

	_slot_index += 1
	return slider


## Add a VR push button.
## Returns the button node.
func add_button(label_text: String, on_press: Callable) -> Node:
	var btn = PUSH_BUTTON.instantiate()
	btn.name = "Button_%s" % label_text.replace(" ", "_")
	btn.position = Vector3(0, -_slot_index * _slot_spacing, 0)
	btn.scale = _scale

	# Set label
	var label = btn.get_node_or_null("Label3D")
	if label:
		label.text = label_text

	add_child(btn)

	# Connect press signal
	var area = btn.get_node_or_null("InteractableAreaButton")
	if area and area.has_signal("button_pressed"):
		area.button_pressed.connect(func(): on_press.call())

	_slot_index += 1
	return btn


## Add an info label (for live readouts like "energy: 42.3").
## Returns the Label3D for updating via update_label().
func add_label(label_id: String, initial_text: String = "", font_size: int = 14) -> Label3D:
	var label := Label3D.new()
	label.name = "Label_%s" % label_id
	label.text = initial_text
	label.font_size = font_size
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, -_slot_index * _slot_spacing, 0.02)
	label.modulate = Color(1, 1, 1, 0.8)
	add_child(label)

	_labels[label_id] = label
	_slot_index += 1
	return label


## Update a label's text by ID.
func update_label(label_id: String, text: String) -> void:
	var label: Label3D = _labels.get(label_id)
	if label:
		label.text = text


## Set the spacing between controls (default 0.12m).
func set_spacing(spacing: float) -> void:
	_slot_spacing = spacing


## Set the scale of all subsequently added controls (default 0.8).
func set_control_scale(s: Vector3) -> void:
	_scale = s


## Set the tilt angle in degrees (default -30, angled toward player).
func set_tilt(degrees: float) -> void:
	_tilt = degrees
