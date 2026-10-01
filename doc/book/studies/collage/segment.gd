extends MeshInstance3D
## Supplied renderer: a cylinder has a local Y axis and needs a visible width.
## Endpoint data and this body are separate, as in the museum’s line.gd.

func show_between(a: Vector3, b: Vector3) -> void:
	var displacement := b - a
	var distance := displacement.length()
	visible = distance > 0.0001
	if not visible: return
	position = (a + b) * 0.5
	(mesh as CylinderMesh).height = distance
	quaternion = Quaternion(Vector3.UP, displacement / distance)
