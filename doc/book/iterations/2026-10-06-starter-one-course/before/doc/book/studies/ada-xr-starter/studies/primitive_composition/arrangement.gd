extends Node3D

const Pyramid = preload("res://studies/primitive_composition/pyramid.gd")

var positions: Array[Vector3] = [
    Vector3(-1.15, 0, 0),
    Vector3(0, 0, -0.8),
    Vector3(1.15, 0, 0),
]
var bodies: Array[MeshInstance3D] = []

func _ready():
    for at in positions:
        var body := Pyramid.new()
        body.position = at
        add_child(body)
        bodies.append(body)
