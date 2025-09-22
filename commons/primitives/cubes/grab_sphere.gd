@tool
extends XRToolsPickable


## Alternate material when button pressed
@export var alternate_material : Material

## Freeze behavior options
@export var alter_freeze : bool = true  # Enable alternating freeze behavior

# Original material
var _original_material : Material

# Current controller holding this object
var _current_controller : XRController3D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Call the super
	super()

	# Get the original material
	_original_material = $MeshInstance3D.get_active_material(0)

	# Listen for when this object is picked up or dropped
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)


# Called when this object is picked up
func _on_picked_up(_pickable) -> void:
	# Listen for button events on the associated controller
	_current_controller = get_picked_up_by_controller()
	if _current_controller:
		_current_controller.button_pressed.connect(_on_controller_button_pressed)
		_current_controller.button_released.connect(_on_controller_button_released)


# Called when this object is dropped
func _on_dropped(_pickable) -> void:
	# Toggle freeze state on drop if alter_freeze is enabled
	if alter_freeze and has_method("set_freeze_enabled"):
		var current_frozen = freeze
		set_freeze_enabled(!current_frozen)
		print("DEBUG: Toggled freeze state from ", current_frozen, " to ", !current_frozen)
	
	# Unsubscribe to controller button events when dropped
	if _current_controller:
		_current_controller.button_pressed.disconnect(_on_controller_button_pressed)
		_current_controller.button_released.disconnect(_on_controller_button_released)
		_current_controller = null

	# Restore original material when dropped
	$MeshInstance3D.set_surface_override_material(0, _original_material)
	GameManager.add_console_message("Point Position: " + str(global_position), "info", "system")

# Called when a controller button is pressed
func _on_controller_button_pressed(button : String):
	# Handle controller button presses
	if button == "ax_button":
		# Set alternate material when button pressed
		if alternate_material:
			$MeshInstance3D.set_surface_override_material(0, alternate_material)


# Called when a controller button is released
func _on_controller_button_released(button : String):
	# Handle controller button releases
	if button == "ax_button":
		# Restore original material when button released
		$MeshInstance3D.set_surface_override_material(0, _original_material)
