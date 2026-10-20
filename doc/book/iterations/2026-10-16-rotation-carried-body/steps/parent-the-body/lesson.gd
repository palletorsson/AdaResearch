extends Node3D
const BoxBody = preload("box_body.gd")

var travel: MeshInstance3D
var pivot := Node3D.new()
var axis := Vector3.UP
var offset := Vector3.ZERO
var duration := 8.0
var elapsed := 0.0

func _ready() -> void:
    assert(duration > 0.0)
    travel = box(Vector3(1.2, 0.2, 0.8), start)
    apply_pose(0.0)

func box(size: Vector3, at: Vector3) -> MeshInstance3D:
    var body := BoxBody.new(size)
    body.position = at
    add_child(body)
    return body

func _process(delta: float) -> void:
    elapsed += delta
    apply_pose(elapsed / duration)

func apply_pose(value: float) -> void:
    var t := clampf(value, 0.0, 1.0)
    if via_corner:
        var corner := Vector3(start.x, finish.y, start.z)
        if t < 0.5:
            travel.position = start.lerp(corner, t * 2.0)
        else:
            travel.position = corner.lerp(finish, (t - 0.5) * 2.0)
    else:
        travel.position = start.lerp(finish, t)
