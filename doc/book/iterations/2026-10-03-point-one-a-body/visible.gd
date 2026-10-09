extends Node3D

var point_position := Vector3(0.0, 1.12, 0.0)
var radius := 0.14

func _ready():
    var sphere := SphereMesh.new()
    sphere.radius = radius
    sphere.height = radius * 2.0

    var marker := MeshInstance3D.new()
    marker.mesh = sphere
    marker.position = point_position
    add_child(marker)
