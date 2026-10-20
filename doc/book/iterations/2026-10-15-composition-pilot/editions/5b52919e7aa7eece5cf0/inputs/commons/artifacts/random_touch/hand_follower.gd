extends Node3D
## Offsets only the contacting virtual hand. Tracking, camera and body stay intact.
const WITHDRAW_DISTANCE := 0.20
const PRIORITY := 120
var controller: XRController3D
var point: Node3D
var tracked_start := Vector3.ZERO
var point_start := Vector3.ZERO
var collision_hand: Node3D
var visual_hand: Node3D
var installed := false
var had_tracking := false

func begin(tracked: XRController3D, sphere: Node3D) -> bool:
	if not is_instance_valid(tracked) or not is_instance_valid(sphere): return false
	if tracked.has_meta("random_touch_owner") and is_instance_valid(tracked.get_meta("random_touch_owner")): return false
	# Runtime-created hand roots may not have a PackedScene owner.
	collision_hand = XRTools.find_xr_child(tracked,"*","XRToolsCollisionHand",true,false)
	visual_hand = XRTools.find_xr_child(tracked,"*","XRToolsHand",true,false)
	if collision_hand == null and visual_hand == null: return false
	controller = tracked
	point = sphere
	tracked_start = tracked.global_position
	point_start = sphere.global_position
	had_tracking = tracked.get_is_active()
	global_transform = tracked.global_transform
	if collision_hand != null: collision_hand.add_target_override(self, PRIORITY)
	if visual_hand != null: visual_hand.add_target_override(self, PRIORITY)
	tracked.set_meta("random_touch_owner", self)
	installed = true
	return true

func withdrawn() -> bool:
	if not installed or not is_instance_valid(controller) or not is_instance_valid(point): return true
	if had_tracking and not controller.get_is_active(): return true
	# Compare actual tracking with the original contact, never the displaced mesh.
	return controller.global_position.distance_to(tracked_start) > WITHDRAW_DISTANCE

func update_target() -> void:
	if not installed or not is_instance_valid(controller) or not is_instance_valid(point): return
	global_transform = controller.global_transform
	global_position += point.global_position - point_start
	force_update_transform()

func stop() -> void:
	if is_instance_valid(collision_hand): collision_hand.remove_target_override(self)
	if is_instance_valid(visual_hand): visual_hand.remove_target_override(self)
	if is_instance_valid(controller) and controller.has_meta("random_touch_owner") and controller.get_meta("random_touch_owner") == self:
		controller.remove_meta("random_touch_owner")
	installed = false

func _exit_tree() -> void:
	stop()
