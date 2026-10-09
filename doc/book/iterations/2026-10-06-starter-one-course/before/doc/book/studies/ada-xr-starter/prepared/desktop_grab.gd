extends Node3D
## Supplied desktop adapter for XRToolsPickable's pickup/release interface.
## A mouse ray selects a nearby object; this does not simulate a tracked hand.

var picked_up_ranged := true
var picked_up_object: XRToolsPickable

func take(body: XRToolsPickable) -> void:
	if is_instance_valid(picked_up_object) or not body.can_pick_up(self):
		return
	picked_up_object = body
	body.pick_up(self)

func drop_object() -> void:
	if is_instance_valid(picked_up_object):
		picked_up_object.let_go(self, Vector3.ZERO, Vector3.ZERO)
	picked_up_object = null

func _exit_tree() -> void:
	drop_object()
