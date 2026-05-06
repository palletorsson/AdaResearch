@tool
extends "res://commons/primitives/cubes/grab_cube.gd"

## Scalable Grab Cube
##
## Extends grab_cube with scaling support.
## Scale snaps to discrete values for educational clarity (Judd-inspired).
## Supports both uniform scaling and per-axis (X, Y, Z) scaling modes.

## Scaling mode
enum ScaleMode {
	UNIFORM,    ## All axes scale together
	PER_AXIS    ## X, Y, Z scale independently (cycle with button)
}

## Scale snap values available (discrete steps only)
@export var scale_snap_values: PackedFloat32Array = [0.05, 0.1, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0, 4.0]

## Enable scaling
@export var enable_scaling: bool = true

## Scaling mode (uniform or per-axis)
@export var scale_mode: ScaleMode = ScaleMode.PER_AXIS

## Sensitivity: how much hand distance change affects scale index
## At 10.0, every 10cm of hand movement = 1 scale step
@export var scale_sensitivity: float = 10.0

## Initial scale indices for X, Y, Z (default to 1.0 = index 3)
@export var initial_scale_x_index: int = 3
@export var initial_scale_y_index: int = 3
@export var initial_scale_z_index: int = 3

## Show scale indicator label
@export var show_scale_indicator: bool = true

## Scale indicator offset from object center
@export var indicator_offset: Vector3 = Vector3(0, 0.15, 0)

## Signal emitted when scale changes (for uniform mode or any axis change)
signal scale_changed(new_scale: float, scale_index: int)

## Signal emitted when per-axis scale changes
signal axis_scale_changed(axis: String, new_scale: float, scale_index: int)

## Signal emitted when scaling starts/stops
signal scaling_state_changed(is_scaling: bool)

## Signal emitted when active axis changes
signal active_axis_changed(axis: String)

# Current scale indices for each axis
var _scale_index_x: int = 3
var _scale_index_y: int = 3
var _scale_index_z: int = 3

# Base scale of the mesh (the 0.1 cube size)
var _mesh_base_scale: float = 0.1

# Initial distance between hands when scaling started
var _initial_hand_distance: float = 0.0

# Scale index when scaling started (for the active axis)
var _scale_index_at_start: int = 0

# Is scaling currently active (two hands grabbing)
var _is_scaling: bool = false

# Current active axis for per-axis scaling (0=X, 1=Y, 2=Z)
var _active_axis: int = 1  # Start with Y (height) as most common

# Scale indicator label
var _scale_label: Label3D = null

# Track secondary controller for button disconnection
var _secondary_controller_connected: XRController3D = null

# Axis names for display
const AXIS_NAMES = ["X", "Y", "Z"]
const AXIS_COLORS = [Color.RED, Color.GREEN, Color.BLUE]


func _ready() -> void:
	super()

	# Initialize scale indices
	_scale_index_x = initial_scale_x_index
	_scale_index_y = initial_scale_y_index
	_scale_index_z = initial_scale_z_index

	# Apply initial scale
	_apply_current_scale()

	# Create scale indicator if enabled
	if show_scale_indicator and not Engine.is_editor_hint():
		_create_scale_indicator()

	# Connect to grabbed/released signals for two-hand detection
	if not Engine.is_editor_hint():
		grabbed.connect(_on_grabbed)
		released.connect(_on_released)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# Update scale indicator position
	if _scale_label and is_picked_up():
		_update_scale_indicator()

	# Handle two-handed scaling
	if _is_scaling and enable_scaling:
		_process_scaling()


func _on_grabbed(_pickable, _by: Node3D) -> void:
	# Check if this is a second hand grab
	if _grab_driver and _grab_driver.secondary:
		_start_scaling()


func _on_released(_pickable, _by: Node3D) -> void:
	# Check if we lost the secondary grab
	if _is_scaling and (not _grab_driver or not _grab_driver.secondary):
		_stop_scaling()


func _start_scaling() -> void:
	if not _grab_driver or not _grab_driver.primary or not _grab_driver.secondary:
		return

	# Get initial hand distance
	var primary_pos = _grab_driver.primary.by.global_position
	var secondary_pos = _grab_driver.secondary.by.global_position
	_initial_hand_distance = primary_pos.distance_to(secondary_pos)

	# Store starting index for active axis
	_scale_index_at_start = _get_active_axis_index()

	_is_scaling = true
	scaling_state_changed.emit(true)

	# Connect to secondary controller buttons for axis cycling
	var secondary_controller = _grab_driver.secondary.controller
	if secondary_controller and secondary_controller != _secondary_controller_connected:
		if _secondary_controller_connected:
			_disconnect_secondary_controller()
		secondary_controller.button_pressed.connect(_on_secondary_button_pressed)
		_secondary_controller_connected = secondary_controller

	# Show scale indicator
	if _scale_label:
		_scale_label.visible = true
		_update_scale_indicator_text()


func _stop_scaling() -> void:
	_is_scaling = false
	scaling_state_changed.emit(false)

	# Disconnect secondary controller buttons
	_disconnect_secondary_controller()

	# Optionally hide scale indicator after delay
	if _scale_label:
		# Keep visible briefly then fade
		var tween = create_tween()
		tween.tween_interval(1.5)
		tween.tween_property(_scale_label, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func(): _scale_label.visible = false; _scale_label.modulate.a = 1.0)


func _disconnect_secondary_controller() -> void:
	if _secondary_controller_connected and is_instance_valid(_secondary_controller_connected):
		if _secondary_controller_connected.button_pressed.is_connected(_on_secondary_button_pressed):
			_secondary_controller_connected.button_pressed.disconnect(_on_secondary_button_pressed)
	_secondary_controller_connected = null


func _on_secondary_button_pressed(button: String) -> void:
	# Use by_button on secondary controller to cycle axes
	if button == "by_button" and scale_mode == ScaleMode.PER_AXIS:
		cycle_active_axis()
		# Reset the scaling reference point when axis changes
		_scale_index_at_start = _get_active_axis_index()
		if _grab_driver and _grab_driver.primary and _grab_driver.secondary:
			var primary_pos = _grab_driver.primary.by.global_position
			var secondary_pos = _grab_driver.secondary.by.global_position
			_initial_hand_distance = primary_pos.distance_to(secondary_pos)


func _process_scaling() -> void:
	if not _grab_driver or not _grab_driver.primary or not _grab_driver.secondary:
		return

	# Get current hand distance
	var primary_pos = _grab_driver.primary.by.global_position
	var secondary_pos = _grab_driver.secondary.by.global_position
	var current_distance = primary_pos.distance_to(secondary_pos)

	# Calculate distance delta (positive = hands apart = scale up, negative = hands closer = scale down)
	var distance_delta = current_distance - _initial_hand_distance

	# Convert to scale index change
	# Each 0.1m (10cm) of movement = 1 step at sensitivity 10
	# Negative delta = negative index_delta = scale down
	var index_delta = int(round(distance_delta * scale_sensitivity))
	var new_index = clampi(_scale_index_at_start + index_delta, 0, scale_snap_values.size() - 1)

	# Apply if changed
	var current_index = _get_active_axis_index()
	if new_index != current_index:
		_set_active_axis_index(new_index)
		_apply_current_scale()
		_play_scale_tick()
		_update_scale_indicator_text()


## Get the scale index for the currently active axis
func _get_active_axis_index() -> int:
	match _active_axis:
		0: return _scale_index_x
		1: return _scale_index_y
		2: return _scale_index_z
	return _scale_index_y


## Set the scale index for the currently active axis
func _set_active_axis_index(index: int) -> void:
	index = clampi(index, 0, scale_snap_values.size() - 1)
	match _active_axis:
		0: _scale_index_x = index
		1: _scale_index_y = index
		2: _scale_index_z = index

	# Emit axis-specific signal
	var scale_value = scale_snap_values[index]
	axis_scale_changed.emit(AXIS_NAMES[_active_axis], scale_value, index)
	scale_changed.emit(scale_value, index)


## Apply the current scale indices to the mesh and collision shape
func _apply_current_scale() -> void:
	var scale_x = scale_snap_values[_scale_index_x] if _scale_index_x < scale_snap_values.size() else 1.0
	var scale_y = scale_snap_values[_scale_index_y] if _scale_index_y < scale_snap_values.size() else 1.0
	var scale_z = scale_snap_values[_scale_index_z] if _scale_index_z < scale_snap_values.size() else 1.0

	var new_size = Vector3(scale_x, scale_y, scale_z) * _mesh_base_scale

	# Update mesh size directly
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance and mesh_instance.mesh is BoxMesh:
		var box_mesh = mesh_instance.mesh as BoxMesh
		# Create a new mesh if needed to avoid sharing
		if not box_mesh.resource_local_to_scene:
			box_mesh = box_mesh.duplicate()
			mesh_instance.mesh = box_mesh
		box_mesh.size = new_size

	# Update collision shape size directly
	var collision_shape = get_node_or_null("CollisionShape3D")
	if collision_shape and collision_shape.shape is BoxShape3D:
		var box_shape = collision_shape.shape as BoxShape3D
		# Create a new shape if needed to avoid sharing
		if not box_shape.resource_local_to_scene:
			box_shape = box_shape.duplicate()
			collision_shape.shape = box_shape
		box_shape.size = new_size

	# Keep node scale at 1 (the mesh/collision carry the size)
	scale = Vector3.ONE


## Cycle to next axis (for per-axis mode)
func cycle_active_axis() -> void:
	_active_axis = (_active_axis + 1) % 3
	active_axis_changed.emit(AXIS_NAMES[_active_axis])
	_update_scale_indicator_text()
	_play_scale_tick()


## Update the scale indicator text
func _update_scale_indicator_text() -> void:
	if not _scale_label:
		return

	if scale_mode == ScaleMode.UNIFORM:
		var scale_value = scale_snap_values[_scale_index_y]
		_scale_label.text = "%.2fx" % scale_value
		_scale_label.modulate = Color(0.9, 0.95, 1.0, 0.9)
	else:
		# Per-axis mode: show active axis and all values
		var sx = scale_snap_values[_scale_index_x]
		var sy = scale_snap_values[_scale_index_y]
		var sz = scale_snap_values[_scale_index_z]
		var active_val = scale_snap_values[_get_active_axis_index()]

		_scale_label.text = "%s: %.1f\n(%.1f, %.1f, %.1f)" % [
			AXIS_NAMES[_active_axis], active_val, sx, sy, sz
		]
		_scale_label.modulate = Color(AXIS_COLORS[_active_axis], 0.9)


func _play_scale_tick() -> void:
	# Simple audio feedback - haptic feedback
	if _current_controller:
		_current_controller.trigger_haptic_pulse("haptic", 0.1, 0.3, 0.05, 0.0)
	if _grab_driver and _grab_driver.secondary:
		var secondary_controller = _grab_driver.secondary.controller
		if secondary_controller:
			secondary_controller.trigger_haptic_pulse("haptic", 0.1, 0.3, 0.05, 0.0)


func _create_scale_indicator() -> void:
	_scale_label = Label3D.new()
	_scale_label.name = "ScaleIndicator"
	_scale_label.font_size = 36
	_scale_label.pixel_size = 0.001
	_scale_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_scale_label.no_depth_test = true
	_scale_label.modulate = Color(0.9, 0.95, 1.0, 0.9)
	_scale_label.outline_modulate = Color(0.1, 0.1, 0.2, 0.8)
	_scale_label.outline_size = 8
	_scale_label.visible = false
	_scale_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	add_child(_scale_label)
	_update_scale_indicator_text()


func _update_scale_indicator() -> void:
	if not _scale_label:
		return

	# Position above the object (adjust for current Y scale)
	var scale_y = scale_snap_values[_scale_index_y] if _scale_index_y < scale_snap_values.size() else 1.0
	var y_offset = (scale_y * _mesh_base_scale * 0.5) + 0.08  # Half height + padding
	_scale_label.position = Vector3(0, y_offset, 0)


# Override button handling to add axis cycling
func _on_controller_button_pressed(button: String) -> void:
	# Call parent for material switching (ax_button)
	super(button)

	# Use by_button to cycle axes in per-axis mode
	if button == "by_button" and scale_mode == ScaleMode.PER_AXIS:
		cycle_active_axis()
		if _scale_label:
			_scale_label.visible = true


## Public API: Set scale for a specific axis by index
func set_axis_scale_index(axis: int, index: int) -> void:
	index = clampi(index, 0, scale_snap_values.size() - 1)
	match axis:
		0: _scale_index_x = index
		1: _scale_index_y = index
		2: _scale_index_z = index
	_apply_current_scale()


## Public API: Get scale index for an axis
func get_axis_scale_index(axis: int) -> int:
	match axis:
		0: return _scale_index_x
		1: return _scale_index_y
		2: return _scale_index_z
	return 3


## Public API: Get the actual Vector3 scale values
func get_scale_vector() -> Vector3:
	var sx = scale_snap_values[_scale_index_x] if _scale_index_x < scale_snap_values.size() else 1.0
	var sy = scale_snap_values[_scale_index_y] if _scale_index_y < scale_snap_values.size() else 1.0
	var sz = scale_snap_values[_scale_index_z] if _scale_index_z < scale_snap_values.size() else 1.0
	return Vector3(sx, sy, sz)


## Public API: Step scale up on active axis
func scale_up() -> void:
	var current = _get_active_axis_index()
	_set_active_axis_index(current + 1)
	_apply_current_scale()
	_update_scale_indicator_text()
	_play_scale_tick()


## Public API: Step scale down on active axis
func scale_down() -> void:
	var current = _get_active_axis_index()
	_set_active_axis_index(current - 1)
	_apply_current_scale()
	_update_scale_indicator_text()
	_play_scale_tick()


## Public API: Set active axis (0=X, 1=Y, 2=Z)
func set_active_axis(axis: int) -> void:
	_active_axis = clampi(axis, 0, 2)
	active_axis_changed.emit(AXIS_NAMES[_active_axis])
	_update_scale_indicator_text()


## Public API: Get active axis
func get_active_axis() -> int:
	return _active_axis


# Desktop input support (scroll wheel + keys)
func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	# Only process if we're picked up
	if not is_picked_up():
		return

	# Handle mouse wheel for desktop scaling
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed:
			if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
				scale_up()
				if _scale_label:
					_scale_label.visible = true
				get_viewport().set_input_as_handled()
			elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				scale_down()
				if _scale_label:
					_scale_label.visible = true
				get_viewport().set_input_as_handled()

	# Handle keyboard for axis switching (Tab or X/Y/Z keys)
	if event is InputEventKey:
		var key_event = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if key_event.keycode == KEY_TAB:
				cycle_active_axis()
				get_viewport().set_input_as_handled()
			elif key_event.keycode == KEY_X:
				set_active_axis(0)
				get_viewport().set_input_as_handled()
			elif key_event.keycode == KEY_Y:
				set_active_axis(1)
				get_viewport().set_input_as_handled()
			elif key_event.keycode == KEY_Z:
				set_active_axis(2)
				get_viewport().set_input_as_handled()
