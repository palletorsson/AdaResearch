# Supplied renderer: a reduced version of rainbow.gd's concentric half-strips.
extends MeshInstance3D

const STEPS := 32
var inner_radius: float
var outer_radius: float

func build(inner: float, outer: float, colour: Color) -> void:
    inner_radius = inner
    outer_radius = outer
    var vertices := PackedVector3Array()
    var normals := PackedVector3Array()
    var indices := PackedInt32Array()
    for i in range(STEPS + 1):
        var angle := PI * float(i) / STEPS
        var direction := Vector3(cos(angle), sin(angle), 0)
        vertices.append(direction * inner)
        vertices.append(direction * outer)
        normals.append(Vector3.BACK)
        normals.append(Vector3.BACK)
    for i in range(STEPS):
        var n := i * 2
        indices.append_array([n, n + 1, n + 2, n + 1, n + 3, n + 2])
    var data := []
    data.resize(Mesh.ARRAY_MAX)
    data[Mesh.ARRAY_VERTEX] = vertices
    data[Mesh.ARRAY_NORMAL] = normals
    data[Mesh.ARRAY_INDEX] = indices
    var result := ArrayMesh.new()
    result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
    mesh = result
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material_override = material
