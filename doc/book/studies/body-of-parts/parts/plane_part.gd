extends MeshInstance3D
## Supplied with the plane part. The mesh is a saved walk; this gives it its body,
## with the three lines Plane's room used: a shape made from the mesh, solid from
## both sides.

func _ready() -> void:
	var shape: ConcavePolygonShape3D = mesh.create_trimesh_shape()
	shape.backface_collision = true
	$Body/CollisionShape3D.shape = shape
