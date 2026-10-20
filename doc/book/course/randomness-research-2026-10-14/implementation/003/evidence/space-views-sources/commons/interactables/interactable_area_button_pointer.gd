@tool
extends "res://addons/godot-xr-tools/interactables/interactable_area_button.gd"

var _pointers: Dictionary = {}

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
			if _pointers.has(pointer): return
			_pointers[pointer] = true
			pointer.tree_exiting.connect(_release_pointer.bind(pointer), CONNECT_ONE_SHOT)
			_on_button_entered(pointer)
		XRToolsPointerEvent.Type.RELEASED, XRToolsPointerEvent.Type.EXITED:
			_release_pointer(pointer)

func _release_pointer(pointer: Node3D) -> void:
	if not _pointers.has(pointer): return
	_pointers.erase(pointer)
	var callback := _release_pointer.bind(pointer)
	if pointer.tree_exiting.is_connected(callback):
		pointer.tree_exiting.disconnect(callback)
	_on_button_exited(pointer)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		# Release ray presses; a hand still touching the cap keeps ownership.
		for pointer in _pointers.keys(): _release_pointer(pointer)
