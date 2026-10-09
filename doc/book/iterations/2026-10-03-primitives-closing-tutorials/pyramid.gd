extends MeshInstance3D
## Supplied construction: five positions, four side faces and a triangulated base.
## All dimensions are local metres. This visible enclosure has no collider.

const SurfaceBuilder = preload("res://studies/primitive_column/column_surface.gd")
var vertices: Array[Vector3] = [
    Vector3(-0.4, 0, -0.4), Vector3(0.4, 0, -0.4),
    Vector3(0.4, 0, 0.4), Vector3(-0.4, 0, 0.4),
    Vector3(0, 1.5, 0),
]
var faces := [[0, 4, 1], [1, 4, 2], [2, 4, 3], [3, 4, 0], [0, 1, 2], [0, 2, 3]]

func _init():
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    for face in faces:
        SurfaceBuilder.triangle(builder, vertices[face[0]], vertices[face[1]], vertices[face[2]])
    mesh = builder.commit()
    material_override = preload("res://studies/primitive_column/stone.tres")
