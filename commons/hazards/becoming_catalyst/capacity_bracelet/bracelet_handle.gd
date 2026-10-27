extends "res://addons/godot-xr-tools/interactables/interactable_handle.gd"
## Reject the wearing hand before target selection. Releasing after pickup is
## too late: the wrist handle would always win over the thing being reached for.
var bracelet: Node3D
func can_pick_up(by: Node3D) -> bool:
	var controller: Node = by
	while controller!=null and not controller is XRController3D:controller = controller.get_parent()
	if is_instance_valid(bracelet) and controller!=null and controller==bracelet._controller:return false
	return super.can_pick_up(by)
