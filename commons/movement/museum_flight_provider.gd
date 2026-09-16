extends XRToolsMovementProvider
## Uses the same bounded volume as the museum walker. Leaves other locomotion
## untouched outside it; respects earlier exclusive providers such as teleport.
@export var order: int = 29
var receiver: XRToolsPlayerBody
var _was_inside := false

func physics_movement(_delta: float, body: XRToolsPlayerBody, disabled: bool):
	if body != receiver: return false
	var zone: Node3D = null
	for candidate in get_tree().get_nodes_in_group("ada_museum_flight"):
		if candidate.contains_point(body.global_position):
			zone = candidate
			break
	if disabled or not enabled or not body.enabled or zone == null:
		if _was_inside and not disabled: body.velocity = Vector3.ZERO
		_was_inside = false
		is_active = false
		return false
	_was_inside = true
	is_active = true
	var left: XRController3D = XRHelpers.get_left_controller(body)
	var velocity_ := Vector3.ZERO
	if left != null and left.get_is_active():
		velocity_ = zone.flight_velocity(left.global_basis, left.get_vector2("primary"))
	body.velocity = body.move_player(velocity_)
	return true
