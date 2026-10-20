# The ring-and-face construction from Bernini, with one receiving function.
extends MeshInstance3D

const HEIGHT := 2.4
const SIDES := 8
const SPANS := 16
var rest: Array[Vector3] = []
var weights: Array[float] = []
var faces: Array[Vector3i] = []
var points: Array[Vector3] = []

func _init() -> void:
    for row in range(SPANS + 1):
        var v := float(row) / SPANS
        for corner in range(SIDES):
            var angle := TAU * corner / SIDES
            var p := Vector3(0.23 * cos(angle), 0, 0.14 * sin(angle))
            rest.append(p.rotated(Vector3.UP, PI * v) + Vector3(0, HEIGHT * v, 0))
            weights.append(sqrt(v))
    for row in range(SPANS):
        for corner in range(SIDES):
            var a := row * SIDES + corner
            var b := row * SIDES + (corner + 1) % SIDES
            faces.append(Vector3i(a, b, a + SIDES))
            faces.append(Vector3i(b, b + SIDES, a + SIDES))
    var bottom := rest.size()
    rest.append(Vector3.ZERO)
    weights.append(0.0)
    var top := rest.size()
    rest.append(Vector3.UP * HEIGHT)
    weights.append(1.0)
    for corner in range(SIDES):
        var next := (corner + 1) % SIDES
        faces.append(Vector3i(bottom, next, corner))
        faces.append(Vector3i(top, SPANS * SIDES + corner, SPANS * SIDES + next))
    var ivory := StandardMaterial3D.new()
    ivory.albedo_color = Color(0.91, 0.89, 0.84)
    ivory.roughness = 0.55
    material_override = ivory

func receive(value: float, maximum_drop: float) -> void:
    points.clear()
    for i in range(rest.size()):
        points.append(rest[i] - Vector3.UP * weights[i] * maximum_drop * value)
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    builder.set_smooth_group(-1)
    for face in faces:
        for index in [face.x, face.y, face.z]:
            builder.add_vertex(points[index])
    builder.generate_normals()
    mesh = builder.commit()
