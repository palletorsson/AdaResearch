extends MeshInstance3D

func _init(size: Vector3 = Vector3.ONE) -> void:
    var shape := BoxMesh.new()
    shape.size = size
    mesh = shape
