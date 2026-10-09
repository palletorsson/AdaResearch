extends Node3D

func _ready() -> void:
    var point_position := Vector3(0.0, 1.12, 0.0)

    var radius := 0.14
    var sphere := SphereMesh.new()
    sphere.radius = radius
    sphere.height = radius * 2.0

    var visible_point := MeshInstance3D.new()
    visible_point.mesh = sphere
    visible_point.position = point_position
    add_child(visible_point)
