extends Node3D

var travel: MeshInstance3D
var grow: MeshInstance3D
var turn: MeshInstance3D
var far_banks: Array[MeshInstance3D] = []
var far_gap := 0.0
var animate := true
var pose := 0.0
var duration := 4.0
var elapsed := 0.0

func _ready() -> void:
    assert(duration > 0.0 and far_gap >= 0.0)
    for x in [-4.0, 0.0, 4.0]:
        box(Vector3(1.2, 0.4, 1), Vector3(x, 0.8, -1.5))
        far_banks.append(box(Vector3(1.2, 0.4, 1), Vector3(x, 0.8, 1.5 + far_gap)))
    travel = box(Vector3(1.2, 0.2, 0.8), Vector3(-4, 0.9, -1.4))
    grow = box(Vector3(1.2, 2, 2), Vector3.ZERO)
    turn = box(Vector3(2, 0.2, 0.6), Vector3(4, 0.9, 0))
    apply_pose(pose)

func box(size: Vector3, at: Vector3) -> MeshInstance3D:
    var body := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    body.mesh = mesh
    body.position = at
    add_child(body)
    return body

func _process(delta: float) -> void:
    elapsed += delta
    if animate:
        pose = pingpong(elapsed / duration, 1.0)
    apply_pose(pose)

func apply_pose(value: float) -> void:
    var t := clampf(value, 0.0, 1.0)
    travel.position.z = lerpf(-1.4, 1.4, t)
    grow.scale = Vector3.ONE * lerpf(0.25, 1.0, t)
    turn.rotation_degrees.y = 90.0 * t
