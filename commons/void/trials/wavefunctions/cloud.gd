extends "res://algorithms/transformation/rotatescalecubes/rotatescalecubes.gd"
## Keep the original 500 cubes, but don't install a second world environment.
func setup_lighting() -> void:
	pass

func _process(delta: float) -> void:
	# The original repeatedly multiplies scale; keep its subtle pulse bounded.
	var mm := multi_mesh_instance.multimesh
	for i in mm.instance_count:
		var transform := mm.get_instance_transform(i)
		transform.basis = transform.basis.orthonormalized()
		mm.set_instance_transform(i, transform)
	super._process(delta)
