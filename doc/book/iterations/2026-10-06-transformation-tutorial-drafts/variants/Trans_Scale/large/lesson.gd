extends Node3D

var doorway := Node3D.new()
var point := MeshInstance3D.new()
var factors := Vector3(4, 4, 4)

func _ready() -> void:
    assert(factors.x > 0.0 and factors.y > 0.0 and factors.z > 0.0)
    add_child(doorway)
    box(Vector3(0.12, 0.6, 0.2), Vector3(-0.285, 0.3, 0))
    box(Vector3(0.12, 0.6, 0.2), Vector3(0.285, 0.3, 0))
    box(Vector3(0.69, 0.12, 0.2), Vector3(0, 0.66, 0))
    doorway.scale = factors

    var sphere := SphereMesh.new()
    sphere.radius = 0.325
    sphere.height = 0.65
    point.mesh = sphere
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.06, 0.06, 0.06)
    ink.roughness = 0.18
    point.material_override = ink
    add_child(point)
    point.position = Vector3(1.8, 0.325, 0)

func box(size: Vector3, at: Vector3) -> void:
    var body := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    body.mesh = mesh
    body.position = at
    doorway.add_child(body)
