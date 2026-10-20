extends Node3D
const BoxBody = preload("box_body.gd")

var pivot := Node3D.new()
var point := MeshInstance3D.new()
var near_distance := 1.0
var far_distance := 4.0
var largest := 4.0
var factors := Vector3.ONE

func _ready() -> void:
    assert(far_distance > near_distance and near_distance >= 0.0)
    assert(largest >= 1.0)
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

func _process(_delta: float) -> void:
    var visitor := get_viewport().get_camera_3d()
    if visitor == null:
        return
    var separation := visitor.global_position - pivot.global_position
    separation.y = 0.0
    respond(separation.length())

func respond(distance: float) -> void:
    var fraction := clampf((distance - near_distance) / (far_distance - near_distance), 0.0, 1.0)
    var factor := lerpf(1.0, largest, fraction)
    apply_pose(Vector3.ONE * factor)

func box(size: Vector3, at: Vector3) -> MeshInstance3D:
    var body := BoxBody.new(size)
    body.position = at
    add_child(body)
    return body


func apply_pose(value: Vector3) -> void:
    assert(value.x > 0.0 and value.y > 0.0 and value.z > 0.0)
    pivot.scale = value
