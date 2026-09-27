extends XRToolsMovementProvider
## XRTools scales direct movement and jump with world_scale; gravity needs the
## same local factor so the smaller visitor keeps comparable jump proportions.
@export var order: int = 28
var receiver: XRToolsPlayerBody
var factor: float = 1.0

func physics_pre_movement(_delta: float, body: XRToolsPlayerBody) -> void:
	if enabled and body == receiver: body.gravity *= factor

func physics_movement(_delta: float, _body: XRToolsPlayerBody, _disabled: bool):
	return false
