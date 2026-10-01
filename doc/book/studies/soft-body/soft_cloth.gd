extends SoftBody3D

const Look := preload("res://supplied/look.gd")

# Godot's own soft body. Its mesh is in the scene. Here we say which points are held.
func _ready() -> void:
	var paint := Look.paint(Look.SECOND)
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = paint
	var points: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for i in points.size():
		if is_equal_approx(points[i].y, 0.6) and is_equal_approx(absf(points[i].x), 0.6):
			set_point_pinned(i, true)
			print("pinned point ", i, " at ", points[i])
