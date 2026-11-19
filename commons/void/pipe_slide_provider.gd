extends XRToolsMovementProvider
## The existing movement-provider contract keeps teleport and disabled bodies first.
@export var order: int = 94
var receiver: XRToolsPlayerBody

func physics_movement(delta: float, body: XRToolsPlayerBody, disabled: bool):
	if body != receiver: return false
	is_active = false
	var active: Node3D = null
	for slide in get_tree().get_nodes_in_group("ada_pipe_slide"):
		if not disabled and enabled and body.enabled and active == null and slide._point_inside(body.global_position):
			active = slide
		else: slide.release_carry(body)
	if active == null: return false
	is_active = true
	body.velocity = body.move_player(active.carry_velocity(body,delta,body.velocity))
	active.record_carry(body)
	return true
