extends Node
## Increases joystick deadzone to prevent drift from controller stick.
## Add this as a child of your XROrigin3D or scene root.

@export var y_deadzone: float = 0.15
@export var x_deadzone: float = 0.25

func _ready() -> void:
	# Wait for XRToolsUserSettings to be loaded
	await get_tree().process_frame

	if XRToolsUserSettings:
		var old_y = XRToolsUserSettings.y_axis_dead_zone
		var old_x = XRToolsUserSettings.x_axis_dead_zone

		XRToolsUserSettings.y_axis_dead_zone = y_deadzone
		XRToolsUserSettings.x_axis_dead_zone = x_deadzone

		print("JoystickDeadzoneFix: Updated deadzone from (x: %s, y: %s) to (x: %s, y: %s)" % [old_x, old_y, x_deadzone, y_deadzone])
	else:
		push_warning("JoystickDeadzoneFix: XRToolsUserSettings not found")
