extends "res://commons/artifacts/primitive_encounters/piece.gd"
## The held point is also the point being recorded. Release suspends it.
func is_drawing_ready() -> bool:
	if has_meta("capability_desktop_held"):return true
	return is_picked_up() and _grab_driver != null and _grab_driver.state == XRToolsGrabDriver.GrabState.SNAP
