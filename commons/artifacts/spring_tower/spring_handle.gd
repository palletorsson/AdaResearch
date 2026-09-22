extends XRToolsPickable
## The hand sets a one-dimensional release position; throwing is deliberately excluded.
var machine: Node3D

func _physics_process(_delta: float) -> void:
	if is_picked_up() and is_instance_valid(machine):
		machine.follow_handle(global_position)
		global_position = machine.to_global(Vector3(machine.displacement, machine.HEIGHT, 0))
		global_basis = machine.global_basis
