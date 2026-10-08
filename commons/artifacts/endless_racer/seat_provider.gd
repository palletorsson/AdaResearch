extends XRToolsMovementProvider
## Own locomotion while driving, while XRTools still updates the tracked head/body.
@export var order := -100
var race: Node3D
func physics_movement(_delta: float, body: XRToolsPlayerBody, _disabled: bool):
	if not is_instance_valid(race) or race.rider!=body:return false
	body.velocity=body.move_player(Vector3.ZERO)
	return true
