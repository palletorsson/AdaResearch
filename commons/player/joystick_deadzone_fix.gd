extends Node
## Increases joystick deadzone to prevent drift from controller stick.
## Add this as a child of your XROrigin3D or scene root.

@export var y_deadzone: float = 0.5  # Your joystick drifts up to 0.42
@export var x_deadzone: float = 0.3
@export var debug_joystick: bool = true  # Log joystick values
@export var debug_interval: float = 1.0  # How often to log (seconds)

var _applied: bool = false
var _left_controller: XRController3D
var _debug_timer: float = 0.0

func _ready() -> void:
	print("JoystickDeadzoneFix: Script loaded, waiting to apply...")
	await get_tree().create_timer(0.5).timeout
	_apply_deadzone()
	_find_left_controller()

func _physics_process(delta: float) -> void:
	if not debug_joystick or not _left_controller:
		return

	_debug_timer += delta
	if _debug_timer < debug_interval:
		return
	_debug_timer = 0.0

	# Get raw joystick values
	var raw = _left_controller.get_vector2("primary")
	var current_dz_y = XRToolsUserSettings.y_axis_dead_zone if XRToolsUserSettings else -1

	if abs(raw.y) > 0.01 or abs(raw.x) > 0.01:  # Only log if there's input
		print("JoystickDebug: raw=(%.3f, %.3f) deadzone_y=%.2f exceeds=%s" % [
			raw.x, raw.y, current_dz_y, abs(raw.y) > current_dz_y
		])

func _apply_deadzone() -> void:
	if _applied:
		return

	if XRToolsUserSettings:
		var old_y = XRToolsUserSettings.y_axis_dead_zone
		var old_x = XRToolsUserSettings.x_axis_dead_zone

		XRToolsUserSettings.y_axis_dead_zone = y_deadzone
		XRToolsUserSettings.x_axis_dead_zone = x_deadzone
		_applied = true

		print("JoystickDeadzoneFix: SUCCESS - Updated deadzone from (y: %s, x: %s) to (y: %s, x: %s)" % [old_y, old_x, y_deadzone, x_deadzone])
	else:
		push_warning("JoystickDeadzoneFix: XRToolsUserSettings not found - deadzone NOT applied!")

func _find_left_controller() -> void:
	_left_controller = XRHelpers.get_left_controller(self)
	if _left_controller:
		print("JoystickDeadzoneFix: Found left controller for debugging")
	else:
		print("JoystickDeadzoneFix: Left controller not found (debug disabled)")
