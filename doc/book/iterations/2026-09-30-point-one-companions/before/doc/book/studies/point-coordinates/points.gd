extends Node3D

func _ready() -> void:
    var a := Vector3(-0.75, 1.12, 0.0)
    var b := Vector3(0.75, 1.12, 0.0)

    $A.position = a
    $A.visible = true
    $B.position = b
    $B.visible = true

    print("local ", $A.position)
    print("world ", $A.global_position)
