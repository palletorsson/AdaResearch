extends Node3D

var pivot := Node3D.new()
var cube := MeshInstance3D.new()
var mark := MeshInstance3D.new()
var axis := Vector3.UP
var offset := Vector3(2, 0, 0)
var speed := 45.0
var elapsed := 0.0

func _ready() -> void:
    assert(axis.length() > 0.0)
    add_child(pivot)
    pivot.position = Vector3(0, 1.2, 0)
    cube.mesh = BoxMesh.new()
    pivot.add_child(cube)
    cube.position = offset

    var mark_mesh := BoxMesh.new()
    mark_mesh.size = Vector3(0.3, 0.12, 0.02)
    mark.mesh = mark_mesh
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.06, 0.06, 0.06)
    mark.material_override = ink
    cube.add_child(mark)
    mark.position = Vector3(0.18, 0.2, 0.51)

func _process(delta: float) -> void:
    elapsed += delta
    var angle := deg_to_rad(speed * elapsed)
    pivot.basis = Basis(axis.normalized(), angle)
