extends MeshInstance3D
## Supplied renderer of a line. One contract: show_between(a, b).
## Attach it to a MeshInstance3D, or make one in code:
##   var segment: MeshInstance3D = preload("res://supplied/segment.gd").new()
## show_between(a, b) lays a thin cylinder from a to b, two positions in the
## frame of this node's parent. Two points closer than a tenth of a millimetre
## hide it. The cylinder is this node's own: the first call makes it (a copy of
## the CylinderMesh the node was given, or one of 12 mm radius in LINE), so two
## segments never share one length. Endpoint data and this body are separate.

const Look := preload("res://supplied/look.gd")

var _own := false   # true once the cylinder is this node's own

func show_between(a: Vector3, b: Vector3) -> void:
	if not _own:
		_make_mesh()
	var displacement := b - a
	var distance := displacement.length()
	visible = distance > 0.0001
	if not visible: return
	position = (a + b) * 0.5
	(mesh as CylinderMesh).height = distance
	quaternion = Quaternion(Vector3.UP, displacement / distance)

func _make_mesh() -> void:
	_own = true
	if mesh is CylinderMesh:
		mesh = mesh.duplicate()
		return
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 24
	cylinder.material = Look.paint(Look.LINE)
	mesh = cylinder
