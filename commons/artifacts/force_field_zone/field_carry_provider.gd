extends XRToolsMovementProvider
## An exclusive receiver for the opted-in lesson; tracked movement still exists.
@export var order: int = 95
var receiver: XRToolsPlayerBody

func physics_movement(delta: float, body: XRToolsPlayerBody, disabled: bool):
	if body != receiver: return false
	var active = null
	for zone in get_tree().get_nodes_in_group("ada_museum_carry"):
		if not disabled and active == null and zone._point_inside(body.global_position): active = zone
		else: zone.release_carry(body)
	if active == null: return false
	body.velocity = active.carry_velocity(body, delta, body.velocity)
	body.velocity = body.move_player(body.velocity)
	active.record_carry(body)
	return true
