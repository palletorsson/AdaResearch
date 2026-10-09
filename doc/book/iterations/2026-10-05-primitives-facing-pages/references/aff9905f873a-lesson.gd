extends Node3D
const CubeBody = preload("cube_body.gd")
var first := CubeBody.new()
var second := CubeBody.new()

func _ready() -> void:
    first.position = Vector3(-0.7, 0.7, 0)
    second.position = Vector3(0.7, 0.7, 0)
    add_child(first)
    add_child(second)
    second.other_diagonal()
