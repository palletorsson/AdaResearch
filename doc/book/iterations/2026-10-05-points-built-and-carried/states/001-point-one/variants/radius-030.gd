extends Node3D

const RADIUS := 0.3
const CENTRE := Vector3(0, 1.12, 0)

var point: StaticBody3D

func _ready() -> void:
    point = StaticBody3D.new()
    point.position = CENTRE

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    point.add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    point.add_child(boundary)

    add_child(point)
