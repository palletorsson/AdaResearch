extends Node3D

var cube := MeshInstance3D.new()
var start := Vector3(-2, 1, 0)
var finish := Vector3(2, 3, 2)
var duration := 4.0
var via_corner := true
var elapsed := 0.0

func _ready() -> void:
    assert(duration > 0.0)
    var mesh := BoxMesh.new()
    mesh.size = Vector3(1.2, 0.2, 1.2)
    cube.mesh = mesh
    add_child(cube)
    cube.position = start

func _process(delta: float) -> void:
    elapsed += delta
    var t := clampf(elapsed / duration, 0.0, 1.0)
    if via_corner:
        var corner := Vector3(start.x, finish.y, start.z)
        if t < 0.5:
            cube.position = start.lerp(corner, t * 2.0)
        else:
            cube.position = corner.lerp(finish, (t - 0.5) * 2.0)
    else:
        cube.position = start.lerp(finish, t)
