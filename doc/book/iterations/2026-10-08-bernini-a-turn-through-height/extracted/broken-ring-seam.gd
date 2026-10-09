extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
@export var height := 2.4
@export var sides := 8
@export var spans := 16
@export var radii := Vector2(0.40, 0.20)
@export var angular_speed := 0.4
var turns := 0.5
var running := false
var points: Array[Vector3] = []
var faces: Array[Vector3i] = []
var shaft := Node3D.new()
var surface := MeshInstance3D.new()
var point: PointBody
var label: Label3D
var witness: Array[MeshInstance3D] = []

func ring_position(row: int, corner: int) -> Vector3:
    var u := float(row) / spans
    var angle := TAU * corner / sides
    var profile := Vector3(radii.x * cos(angle), 0, radii.y * sin(angle))
    return profile.rotated(Vector3.UP, TAU * turns * u) + Vector3(0, 0.25 + height * u, 0)

func turns_from_height() -> float:
    return clampf((point.position.y - 0.8) / 0.8, 0.0, 1.0)

func _ready() -> void:
    add_child(shaft)
    shaft.add_child(surface)
    var ivory := StandardMaterial3D.new()
    ivory.albedo_color = Color(0.91, 0.89, 0.84)
    ivory.roughness = 0.55
    surface.material_override = ivory
    var base := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.55
    cylinder.bottom_radius = 0.55
    cylinder.height = 0.25
    base.mesh = cylinder
    base.position.y = 0.125
    base.material_override = ivory
    add_child(base)
    for row in range(spans):
        var line := LineSkin.new()
        shaft.add_child(line)
        witness.append(line)
    point = PointBody.new()
    point.position = Vector3(1.1, 1.2, 0.4)
    var black := StandardMaterial3D.new()
    black.albedo_color = Color(0.025, 0.025, 0.03)
    black.roughness = 0.18
    point.get_child(0).material_override = black
    add_child(point)
    point.action_pressed.connect(toggle_rotation)
    label = Label3D.new()
    label.position = Vector3(0.5, 3.0, 0)
    label.font_size = 28
    label.pixel_size = 0.004
    add_child(label)
    turns = turns_from_height()
    rebuild()
    draw_label()

func rebuild() -> void:
    points.clear()
    faces.clear()
    for row in range(spans + 1):
        for corner in range(sides):
            points.append(ring_position(row, corner))
    for row in range(spans):
        for corner in range(sides):
            var next := (corner + 1) % (sides - 1)
            var a := row * sides + corner
            var b := row * sides + next
            var c := a + sides
            var d := b + sides
            faces.append(Vector3i(a, b, c))
            faces.append(Vector3i(b, d, c))
    var bottom := points.size()
    points.append(Vector3(0, 0.25, 0))
    var top := points.size()
    points.append(Vector3(0, 0.25 + height, 0))
    for corner in range(sides):
        var next := (corner + 1) % (sides - 1)
        faces.append(Vector3i(bottom, next, corner))
        faces.append(Vector3i(top, spans * sides + corner, spans * sides + next))
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    builder.set_smooth_group(-1)
    for face in faces:
        for index in [face.x, face.y, face.z]:
            builder.add_vertex(points[index])
    builder.generate_normals()
    surface.mesh = builder.commit()
    for row in range(spans):
        var a := points[row * sides]
        var b := points[(row + 1) * sides]
        witness[row].show_segment(a, b - a, a.distance_to(b))

func toggle_rotation(_held: Variant) -> void:
    running = not running
    draw_label()

func _process(delta: float) -> void:
    var selected := turns_from_height()
    if absf(selected - turns) > 0.002:
        turns = selected
        rebuild()
    if running:
        shaft.rotate_y(angular_speed * delta)
    draw_label()

func draw_label() -> void:
    label.text = "LIFT: %.2f turns through height\nTRIGGER: whole-object rotation %s" % [turns, "ON" if running else "OFF"]
