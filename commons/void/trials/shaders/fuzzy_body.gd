extends "res://commons/artifacts/fuzzy_body/fuzzy_body.gd"
## Fit only the backdrop and heading below the existing six-metre slab.
func make_room() -> void:
	super.make_room()
	for child in get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh and is_equal_approx(child.mesh.size.y,6.6):
			child.mesh = child.mesh.duplicate()
			child.mesh.size.y = 5.5
			child.position.y = 2.75
		if child is Label3D and child.position.y > 5.7:
			child.position.y -= .65
