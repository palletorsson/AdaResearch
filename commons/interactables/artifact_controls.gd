extends Node3D
class_name ArtifactControls

## Helper for adding VR controls to artifacts using the rack control system.
## Uses the canonical rack 2D controls (RackSliderH, RackKnob, etc.) wrapped
## in VRRackControl for pixel-perfect web↔VR parity.
## For physical interaction, add_physical_stepped_slider supplies a grabbable
## handle with printed labels. Keep its enclosing physics assembly at unit scale.
##
## Usage:
##   var controls := ArtifactControls.new()
##   controls.position = Vector3(2.0, 1.5, 0.0)
##   add_child(controls)
##
##   controls.add_slider("STIFFNESS", 0.5, func(v): stiffness = lerp(10.0, 500.0, v))
##   controls.add_knob("DAMPING", 0.3, func(v): damping = v * 20.0)
##   controls.add_button("RESET", func(): reset_simulation())
##   controls.add_meter("ENERGY", 0.0)
##   controls.add_label("status", "STABLE")

# Rack control scenes
const RACK_SLIDER_H = "res://commons/audio/rack_controls/RackSliderH.tscn"
const RACK_SLIDER_V = "res://commons/audio/rack_controls/RackSliderV.tscn"
const RACK_KNOB = "res://commons/audio/rack_controls/RackKnob.tscn"
const RACK_BUTTON = "res://commons/audio/rack_controls/RackButton.tscn"
const RACK_METER = "res://commons/audio/rack_controls/RackMeter.tscn"
const RACK_LABEL = "res://commons/audio/rack_controls/RackLabel.tscn"
const RACK_XY_PAD = "res://commons/audio/rack_controls/RackXYPad.tscn"
const RACK_SLIDER_STEPPED = "res://commons/audio/rack_controls/RackSliderStepped.tscn"
const RACK_SLIDER_BIPOLAR = "res://commons/audio/rack_controls/RackSliderBipolar.tscn"

# Fallback if rack controls not available
const SLIDER_HORIZONTAL_LEGACY = "res://commons/interactables/slider_horizontal.tscn"
const PUSH_BUTTON_LEGACY = "res://commons/interactables/push_button.tscn"

var _slot_index: int = 0
var _slot_spacing: float = 0.09  # meters between controls
var _controls: Dictionary = {}  # name -> VRRackControl or Node
var _use_rack: bool = true


func _ready() -> void:
	# Check if rack system is available
	_use_rack = ResourceLoader.exists(RACK_SLIDER_H)
	if not _use_rack:
		push_warning("ArtifactControls: Rack controls not found, falling back to legacy sliders")


## Add a horizontal slider (rack-style).
func add_slider(
	param_name: String,
	initial_value: float,
	on_change: Callable,
) -> Node:
	if _use_rack:
		return _add_rack_slider(param_name, initial_value, on_change)
	else:
		return _add_legacy_slider(param_name, initial_value, on_change)


## Add a knob/dial control (rack-style).
func add_knob(
	param_name: String,
	initial_value: float,
	on_change: Callable,
) -> Node:
	if _use_rack:
		return _add_rack_control(RACK_KNOB, param_name, initial_value, on_change)
	else:
		return _add_legacy_slider(param_name, initial_value, on_change)


## Add a stepped slider (discrete values).
func add_stepped_slider(
	param_name: String,
	initial_value: float,
	on_change: Callable,
	step_count: int = 5,
) -> Node:
	if _use_rack:
		var ctrl := _add_rack_control(RACK_SLIDER_STEPPED, param_name, initial_value, on_change)
		ctrl.set_step_count(step_count)
		return ctrl
	else:
		return _add_legacy_slider(param_name, initial_value, on_change)


## Physical selector with flat printed labels; use a unit-scale parent.
func add_physical_stepped_slider(param_name: String, initial_value: float, on_change: Callable, step_count: int = 6) -> Node3D:
	var ctrl: Node3D = load("res://commons/interactables/physical_stepped_slider.gd").new()
	ctrl.name = "Physical_%s" % param_name.replace(" ", "_")
	ctrl.param_name = param_name
	ctrl.step_count = step_count
	ctrl.set_normalized_value(initial_value)
	ctrl.position = _next_slot_position()
	add_child(ctrl)
	ctrl.value_changed.connect(on_change)
	_controls[param_name] = ctrl
	_slot_index += 1
	return ctrl


## Add a push button.
func add_button(label_text: String, on_press: Callable) -> Node:
	if _use_rack:
		return _add_rack_button(label_text, on_press)
	else:
		return _add_legacy_button(label_text, on_press)


## Add a meter display (read-only, updated via update_meter()).
func add_meter(param_name: String, initial_level: float = 0.0) -> Node:
	if _use_rack:
		var ctrl := _make_vr_rack_control(RACK_METER, param_name)
		ctrl.position = _next_slot_position()
		add_child(ctrl)
		ctrl.set_level(initial_level)
		_controls[param_name] = ctrl
		_slot_index += 1
		return ctrl
	else:
		return add_label(param_name, "0.0")


## Add a backed 2D status screen. Update through update_label(), as before.
func add_label(label_id: String, initial_text: String = "", font_size: int = 14) -> Node3D:
	var label := Node3D.new()
	label.name = "Label_%s" % label_id
	label.position = _next_slot_position()
	add_child(label)
	var casing := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(.20, .052, .02)
	casing.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(.12, .14, .16)
	casing.material_override = mat
	label.add_child(casing)
	var surface: Dictionary = preload("res://commons/ui/control_value_surface.gd").build(label, Vector2(.184, .042), Vector3(0, 0, .011))
	var value: Label = surface.label
	value.add_theme_font_size_override("font_size", clampi(font_size * 3, 24, 64))
	value.text = initial_text
	label.set_meta("status_surface", surface)
	_controls[label_id] = label
	_slot_index += 1
	return label


## Update a meter's level (0.0 to 1.0).
func update_meter(param_name: String, level: float) -> void:
	var ctrl = _controls.get(param_name)
	if ctrl and ctrl.has_method("set_level"):
		ctrl.set_level(level)


## Update a label's text.
func update_label(label_id: String, text: String) -> void:
	var ctrl = _controls.get(label_id)
	if ctrl and ctrl.has_meta("status_surface"):
		var surface: Dictionary = ctrl.get_meta("status_surface")
		if surface.label.text != text:
			surface.label.text = text
			surface.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	elif ctrl and ctrl.has_method("set_text"):
		ctrl.set_text(text)


## Set spacing between controls (default 0.09m for rack density).
func set_spacing(spacing: float) -> void:
	_slot_spacing = spacing


# ── Internal: Rack system ──────────────────────────────────────

func _next_slot_position() -> Vector3:
	return Vector3(0, -_slot_index * _slot_spacing, 0)


func _make_vr_rack_control(scene_path: String, param_name: String) -> Node:
	var ctrl := VRRackControl.new()
	ctrl.control_scene_path = scene_path
	ctrl.name = "Rack_%s" % param_name.replace(" ", "_")
	ctrl.set_param_name(param_name)
	return ctrl


func _add_rack_slider(param_name: String, initial_value: float, on_change: Callable) -> Node:
	var ctrl := _make_vr_rack_control(RACK_SLIDER_H, param_name)
	ctrl.position = _next_slot_position()
	add_child(ctrl)

	# Set initial value and label after tree enter
	call_deferred("_configure_rack_control", ctrl, param_name, initial_value, on_change)
	_controls[param_name] = ctrl
	_slot_index += 1
	return ctrl


func _add_rack_control(scene_path: String, param_name: String, initial_value: float, on_change: Callable) -> Node:
	var ctrl := _make_vr_rack_control(scene_path, param_name)
	ctrl.position = _next_slot_position()
	add_child(ctrl)
	call_deferred("_configure_rack_control", ctrl, param_name, initial_value, on_change)
	_controls[param_name] = ctrl
	_slot_index += 1
	return ctrl


func _add_rack_button(label_text: String, on_press: Callable) -> Node:
	var ctrl := _make_vr_rack_control(RACK_BUTTON, label_text)
	ctrl.position = _next_slot_position()
	add_child(ctrl)
	# Button handling via the 2D control's signal
	call_deferred("_configure_rack_button", ctrl, label_text, on_press)
	_controls[label_text] = ctrl
	_slot_index += 1
	return ctrl


func _configure_rack_control(ctrl: Node, param_name: String, initial_value: float, on_change: Callable) -> void:
	if not is_instance_valid(ctrl):
		return
	ctrl.set_param_name(param_name)
	ctrl.set_normalized_value(initial_value)

	# Connect value_changed from inner 2D control
	var inner: Control = ctrl.get_control()
	if inner and inner.has_signal("value_changed"):
		inner.value_changed.connect(func(val: float):
			on_change.call(val)
		)


func _configure_rack_button(ctrl: Node, label_text: String, on_press: Callable) -> void:
	if not is_instance_valid(ctrl):
		return
	ctrl.set_param_name(label_text)
	var inner: Control = ctrl.get_control()
	if inner and inner.has_signal("value_changed"):
		# RackButton emits normalized state, not a `pressed` signal.
		# Only its rising edge invokes an action; release and exit don't repeat it.
		inner.value_changed.connect(func(value: float):
			if value >= .5: on_press.call()
		)


# ── Internal: Legacy fallback ──────────────────────────────────

func _add_legacy_slider(param_name: String, initial_value: float, on_change: Callable) -> Node:
	var scene := load(SLIDER_HORIZONTAL_LEGACY) as PackedScene
	if not scene:
		return add_label(param_name, str(initial_value))
	var slider := scene.instantiate()
	slider.name = "Slider_%s" % param_name.replace(" ", "_")
	slider.position = _next_slot_position()
	slider.rotation_degrees.x = -30
	slider.scale = Vector3(0.8, 0.8, 0.8)
	var name_label = slider.get_node_or_null("Frame/LabelName")
	if name_label:
		name_label.text = param_name
	add_child(slider)
	slider.slider_moved.connect(func(_pos):
		if slider.has_method("get_normalized_value"):
			on_change.call(slider.get_normalized_value())
	)
	if slider.has_method("set_normalized_value"):
		slider.set_normalized_value(initial_value)
	_controls[param_name] = slider
	_slot_index += 1
	return slider


func _add_legacy_button(label_text: String, on_press: Callable) -> Node:
	var scene := load(PUSH_BUTTON_LEGACY) as PackedScene
	if not scene:
		return add_label(label_text, "[BTN]")
	var btn := scene.instantiate()
	btn.name = "Button_%s" % label_text.replace(" ", "_")
	btn.position = _next_slot_position()
	btn.scale = Vector3(0.8, 0.8, 0.8)
	add_child(btn)
	var area = btn.get_node_or_null("InteractableAreaButton")
	if area and area.has_signal("button_pressed"):
		area.button_pressed.connect(func(): on_press.call())
	_controls[label_text] = btn
	_slot_index += 1
	return btn
