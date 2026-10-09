extends Node3D
const CubeBody = preload("cube_body.gd")
const PointBody = preload("point_body.gd")
var places: Array[Vector3] = [Vector3(-0.8, 0, 0), Vector3(0.5, 0, -0.7)]
var cubes: Array[Node3D] = []
var point := PointBody.new()

func _ready() -> void:
    for place in places:
        var cube := CubeBody.new()
        cube.position = place
        add_child(cube)
        cubes.append(cube)
    point.position = Vector3(0.1, PointBody.RADIUS, 0.6)
    add_child(point)
