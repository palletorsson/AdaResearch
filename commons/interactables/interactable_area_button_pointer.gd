@tool
extends "res://addons/godot-xr-tools/interactables/interactable_area_button.gd"

## Extend XRTools area buttons with ray-pointer click support.
## Keeps existing hand poke behavior from XRToolsInteractableAreaButton.
func pointer_event(event: XRToolsPointerEvent) -> void:
	if not event:
		return

	var pointer: Node3D = event.pointer
	if not pointer or not is_instance_valid(pointer):
		return

	match event.event_type:
		XRToolsPointerEvent.Type.PRESSED:
			_on_button_entered(pointer)
		XRToolsPointerEvent.Type.RELEASED, XRToolsPointerEvent.Type.EXITED:
			_on_button_exited(pointer)
