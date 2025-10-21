# VRInfoBoardInput.gd
# VR input handler for info board scrolling and interaction
# Handles VR controller input for scrolling through text content
extends Node3D
class_name VRInfoBoardInput

# VR controller references
var left_controller: XRController3D
var right_controller: XRController3D
var current_controller: XRController3D

# Scroll settings
@export var scroll_sensitivity: float = 0.1
@export var scroll_deadzone: float = 0.1
@export var haptic_feedback: bool = true
@export var haptic_intensity: float = 0.3

# Target scroll container
var target_scroll_container: ScrollContainer
var info_board_base: AlgorithmInfoBoardBase

# Input state
var is_scrolling: bool = false
var last_trigger_value: float = 0.0
var scroll_accumulator: float = 0.0

# Signals
signal scroll_changed(scroll_value: float)
signal vr_input_detected(controller: XRController3D)

func _ready():
	# Find VR controllers
	_find_vr_controllers()
	
	# Connect to VR controller signals
	_connect_controller_signals()

func _find_vr_controllers():
	# Find XR controllers in the scene
	var xr_origin = get_tree().get_first_node_in_group("xr_origin")
	if xr_origin:
		left_controller = xr_origin.find_child("LeftController", true, false)
		right_controller = xr_origin.find_child("RightController", true, false)
	
	# Fallback: search for any XRController3D nodes
	if not left_controller or not right_controller:
		var controllers = get_tree().get_nodes_in_group("xr_controllers")
		for controller in controllers:
			if controller is XRController3D:
				if not left_controller:
					left_controller = controller
				elif not right_controller:
					right_controller = controller
					break

func _connect_controller_signals():
	# Connect to controller button events
	if left_controller:
		left_controller.button_pressed.connect(_on_controller_button_pressed.bind(left_controller))
		left_controller.button_released.connect(_on_controller_button_released.bind(left_controller))
	
	if right_controller:
		right_controller.button_pressed.connect(_on_controller_button_pressed.bind(right_controller))
		right_controller.button_released.connect(_on_controller_button_released.bind(right_controller))

func _process(delta):
	# Handle VR controller input for scrolling
	_handle_vr_scroll_input(delta)

func _handle_vr_scroll_input(delta: float):
	if not target_scroll_container:
		return
	
	# Check both controllers for trigger input
	var left_trigger = _get_trigger_value(left_controller)
	var right_trigger = _get_trigger_value(right_controller)
	
	# Use the controller with the highest trigger value
	var active_trigger = max(left_trigger, right_trigger)
	var active_controller = left_controller if left_trigger > right_trigger else right_controller
	
	if active_trigger > scroll_deadzone:
		if not is_scrolling:
			is_scrolling = true
			current_controller = active_controller
			vr_input_detected.emit(active_controller)
		
		# Calculate scroll delta based on trigger change
		var trigger_delta = active_trigger - last_trigger_value
		scroll_accumulator += trigger_delta * scroll_sensitivity
		
		# Apply scroll if we have accumulated enough change
		if abs(scroll_accumulator) >= 1.0:
			var scroll_direction = 1 if scroll_accumulator > 0 else -1
			_scroll_content(scroll_direction)
			scroll_accumulator = 0.0
			
			# Provide haptic feedback
			if haptic_feedback and active_controller:
				_provide_haptic_feedback(active_controller)
	else:
		if is_scrolling:
			is_scrolling = false
			current_controller = null
			scroll_accumulator = 0.0
	
	last_trigger_value = active_trigger

func _get_trigger_value(controller: XRController3D) -> float:
	if not controller:
		return 0.0
	
	# Get trigger value from controller
	return controller.get_float("trigger_click")

func _scroll_content(direction: int):
	if not target_scroll_container:
		return
	
	# Calculate scroll amount
	var scroll_amount = 50 * direction  # Adjust scroll speed as needed
	
	# Apply scroll
	var new_scroll = target_scroll_container.scroll_vertical + scroll_amount
	target_scroll_container.scroll_vertical = new_scroll
	
	# Emit signal
	scroll_changed.emit(new_scroll)

func _provide_haptic_feedback(controller: XRController3D):
	if not controller or not haptic_feedback:
		return
	
	# Trigger haptic feedback
	controller.pulse(haptic_intensity, 0.1)

func _on_controller_button_pressed(button: String, controller: XRController3D):
	# Handle button presses for navigation
	match button:
		"ax_button":  # A/X button - next page
			if info_board_base:
				info_board_base.next_page()
		"by_button":  # B/Y button - previous page
			if info_board_base:
				info_board_base.prev_page()
		"menu_button":  # Menu button - toggle animation
			if info_board_base:
				info_board_base.toggle_animation()

func _on_controller_button_released(button: String, controller: XRController3D):
	# Handle button releases if needed
	pass

# Public API
func set_target_scroll_container(scroll_container: ScrollContainer):
	target_scroll_container = scroll_container

func set_info_board_base(board_base: AlgorithmInfoBoardBase):
	info_board_base = board_base

func set_scroll_sensitivity(sensitivity: float):
	scroll_sensitivity = sensitivity

func set_haptic_feedback(enabled: bool, intensity: float = 0.3):
	haptic_feedback = enabled
	haptic_intensity = intensity

# Utility functions
func is_vr_active() -> bool:
	return left_controller != null or right_controller != null

func get_active_controller() -> XRController3D:
	return current_controller

func get_scroll_position() -> float:
	if target_scroll_container:
		return target_scroll_container.scroll_vertical
	return 0.0
