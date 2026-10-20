# Five familiar parts; colour changes their grouping without changing their geometry.
extends Node3D

var palette: Array[Color] = [
    Color(0.78, 0.60, 0.30), # 0: ochre
    Color(0.80, 0.16, 0.16), # 1: red
    Color(0.16, 0.36, 0.80), # 2: blue
]
var colour_slots: Array[int] = [2, 0, 1, 0, 2]
var parts: Array[MeshInstance3D] = []

func _ready() -> void:
    add_box(Vector3(1.10, 0.60, 1.10), Vector3(0, 0.30, 0))
    add_box(Vector3(0.95, 0.95, 0.95), Vector3(0, 1.075, 0))
    add_round(0.475, 0.95, Vector3(0, 2.025, 0))
    add_box(Vector3(0.85, 0.95, 0.85), Vector3(0, 2.975, 0))
    add_round(0.425, 0.95, Vector3(0, 3.45, 0), true)
    apply_colours()

func add_box(size: Vector3, at: Vector3) -> void:
    var shape := BoxMesh.new()
    shape.size = size
    add_part(shape, at)

func add_round(radius: float, height: float, at: Vector3, hemisphere := false) -> void:
    var shape := SphereMesh.new()
    shape.radius = radius
    shape.height = height
    shape.is_hemisphere = hemisphere
    add_part(shape, at)

func add_part(shape: Mesh, at: Vector3) -> void:
    var part := MeshInstance3D.new()
    part.mesh = shape
    part.position = at
    var material := StandardMaterial3D.new()
    material.roughness = 0.55
    part.material_override = material
    add_child(part)
    parts.append(part)

func apply_colours() -> void:
    assert(colour_slots.size() == parts.size(), "Give every part a palette index.")
    for i in parts.size():
        var slot: int = colour_slots[i]
        assert(slot >= 0 and slot < palette.size(), "Palette index outside the list.")
        var material: StandardMaterial3D = parts[i].material_override
        material.albedo_color = palette[slot]
