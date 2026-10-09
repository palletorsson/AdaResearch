extends XRToolsMovementProvider
## Read the same opted-in media after direct movement has supplied its request.
## This adapts stick locomotion; it cannot resist tracked physical walking.
@export var order: int = 90
var receiver: XRToolsPlayerBody

func physics_movement(_delta: float, player_body: XRToolsPlayerBody, disabled: bool):
	if disabled or player_body != receiver:
		return
	for medium in get_tree().get_nodes_in_group("ada_kinetic_media"):
		player_body.ground_control_velocity *= medium.walk_multiplier(player_body.global_position)
	return false
