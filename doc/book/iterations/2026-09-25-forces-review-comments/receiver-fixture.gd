extends XRToolsPlayerBody
## A contract fixture: no tracked pose, body registration or collision simulation.
## Production providers and ground-control gate run against the real body type.
var contact_stop := false
func _ready() -> void:
	set_physics_process(false)
func move_player(p_velocity: Vector3) -> Vector3:
	velocity = Vector3.ZERO if contact_stop else p_velocity
	return velocity
