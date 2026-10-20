extends Node3D
const BoxBody = preload("box_body.gd")

var travel: MeshInstance3D
var start := Vector3(-2, 1, 0)
var finish := Vector3(2, 3, 0)
var duration := 4.0
var via_corner := false
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
    if animate:
        pose = pingpong(2.0 * elapsed / period, 1.0)
    apply_pose(pose)

func apply_pose(value: float) -> void:
    var t := clampf(value, 0.0, 1.0)
    travel.position.z = lerpf(-1.4, 1.4, t)
    grow.scale = Vector3.ONE * lerpf(0.25, 1.0, t)
    turn.rotation_degrees.y = 90.0 * t
