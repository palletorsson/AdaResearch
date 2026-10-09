extends Node3D

const PointBody = preload("point_body.gd")
@export var cells: int = 16
@export var amplitude: float = 0.18
@export var frequency: float = 1.0 # Cycles per metre, not per second.
var points: Array[Vector3] = []
var faces: Array[Vector3i] = []
var surface := MeshInstance3D.new()
var receiver := StaticBody3D.new()
var boundary := CollisionShape3D.new()
var point: PointBody

func height_at(x: float, z: float) -> float:
    return 0.8 + amplitude * sin(frequency * x) * sin(frequency * z)

func _ready() -> void:
    add_child(surface)
    add_child(receiver)
    receiver.add_child(boundary)
    for row in range(cells + 1):
        for column in range(cells + 1):
            var x := -1.0 + 2.0 * column / cells
            var z := -1.0 + 2.0 * row / cells
            points.append(Vector3(x, height_at(x, z), z))
    var stride := cells + 1
    for row in range(cells):
        for column in range(cells):
            var a := row * stride + column
            faces.append(Vector3i(a, a + 1, a + stride))
            faces.append(Vector3i(a + 1, a + stride + 1, a + stride))
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    for face in faces:
        for index in [face.x, face.y, face.z]:
            builder.add_vertex(points[index])
    builder.generate_normals()
    surface.mesh = builder.commit()
    var blue := StandardMaterial3D.new()
    blue.albedo_color = Color("76b6c9")
    blue.roughness = 0.65
    surface.material_override = blue
    boundary.shape = surface.mesh.create_trimesh_shape()
    var contact := PhysicsMaterial.new()
    contact.friction = 0.45
    contact.bounce = 0.0
    receiver.physics_material_override = contact
    point = PointBody.new()
    point.position = Vector3(0.20, 1.8, 0.20)
    point.mass = 0.1
    point.gravity_scale = 1.0
    point.release_mode = XRToolsPickable.ReleaseMode.UNFROZEN
    point.freeze = false
    point.physics_material_override = contact
    var black := StandardMaterial3D.new()
    black.albedo_color = Color("17191c")
    black.roughness = 0.16
    for child in point.get_children():
        if child is MeshInstance3D:
            child.material_override = black
    add_child(point)
