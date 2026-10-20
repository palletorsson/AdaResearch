extends Node3D
const BoxBody = preload("box_body.gd")

var pivot := Node3D.new()
var point := MeshInstance3D.new()
var factors := Vector3.ONE

func _ready() -> void:
    assert(duration > 0.0 and axis.length() > 0.0)
    add_child(pivot)
    pivot.position = Vector3(0, 1.2, 0)
    travel = box(Vector3(1.2, 0.2, 0.8), offset)
    travel.reparent(pivot, false)
    var mark := box(Vector3(0.3, 0.02, 0.18), Vector3(0.35, 0.11, 0.2))
    mark.reparent(travel, false)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.06, 0.06, 0.06)
    mark.material_override = ink
    apply_pose(0.0)

func box(size: Vector3, at: Vector3) -> MeshInstance3D:
    var body := BoxBody.new(size)
    body.position = at
    add_child(body)
    return body


func apply_pose(value: float) -> void:
    var angle := deg_to_rad(360.0 * value)
    pivot.basis = Basis(axis.normalized(), angle)
