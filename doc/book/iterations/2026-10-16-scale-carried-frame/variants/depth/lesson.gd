extends Node3D
const BoxBody = preload("box_body.gd")

var pivot := Node3D.new()
var point := MeshInstance3D.new()
var factors := Vector3(1, 1, 3)

func _ready() -> void:
    add_child(pivot)
    for at in [Vector3(-0.285, 0.3, 0), Vector3(0.285, 0.3, 0)]:
        var post := box(Vector3(0.12, 0.6, 0.2), at)
        post.reparent(pivot, false)
    var lintel := box(Vector3(0.69, 0.12, 0.2), Vector3(0, 0.66, 0))
    lintel.reparent(pivot, false)
    var sphere := SphereMesh.new()
    sphere.radius = 0.325
    sphere.height = 0.65
    point.mesh = sphere
    add_child(point)
    point.position = Vector3(1.8, 0.325, 0)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.06, 0.06, 0.06)
    point.material_override = ink
    apply_pose(factors)

func box(size: Vector3, at: Vector3) -> MeshInstance3D:
    var body := BoxBody.new(size)
    body.position = at
    add_child(body)
    return body


func apply_pose(value: Vector3) -> void:
    assert(value.x > 0.0 and value.y > 0.0 and value.z > 0.0)
    pivot.scale = value
