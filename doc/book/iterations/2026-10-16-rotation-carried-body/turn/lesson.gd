extends Node3D
const BoxBody = preload("box_body.gd")

var travel: MeshInstance3D
var pivot := Node3D.new()
var axis := Vector3.UP
var offset := Vector3.ZERO
var duration := 8.0
var elapsed := 0.0

func _ready() -> void:
    assert(duration > 0.0 and axis.length() > 0.0)
    add_child(pivot)
    pivot.position = Vector3(0, 1.2, 0)
    travel = box(Vector3(1.2, 0.2, 0.8), offset)
    travel.reparent(pivot, false)
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
    var angle := deg_to_rad(360.0 * value)
    pivot.basis = Basis(axis.normalized(), angle)
