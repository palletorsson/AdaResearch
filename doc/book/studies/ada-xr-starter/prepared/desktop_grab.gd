extends Node3D
## Supplied desktop adapter for XRToolsPickable's pickup/release interface.
## A mouse ray selects a nearby object; this does not simulate a tracked hand.

# Preserve the current hand-to-object offset, as a near grip does. A distant
# desktop selection must not teleport a recorder's point into the camera.
var picked_up_ranged := false
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
    if is_instance_valid(picked_up_object):
        picked_up_object.set_meta("ada_release_cleanup", true)
        var held := picked_up_object
        drop_object()
        if is_instance_valid(held):
            held.remove_meta("ada_release_cleanup")
        return
    drop_object()
