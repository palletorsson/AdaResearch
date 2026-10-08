extends Node3D
## A single native 3D illustration shared by the museum and book capture.
## The coordinates match TriangleLinePuzzle.TRI_UV, enlarged uniformly for reading.
## No texture of the book image is used in the museum: points, edges, face and type
## are real scene geometry. No interaction or drawing state is implied by the plate.

const PAPER := Color("f4f0e7")
const INK := Color("202933")
const MUTED := Color("647079")
const RULE := Color("d7d2c8")
const ROSE := Color("c83f77")
const REGULAR = preload("res://commons/font/static/Roboto-Regular.ttf")
const LIGHT = preload("res://commons/font/static/Roboto-Light.ttf")
const MONO = preload("res://commons/font/JetBrainsMono-Medium.ttf")
const TRI_UV: Array[Vector2] = [Vector2(-0.2, -0.173), Vector2(0.2, -0.173), Vector2(0, 0.173)]
const WIDTH := 4.2
const HEIGHT := 2.0
const CENTER_Y := 1.7
const DIAGRAM_SCALE := 2.3

@export var show_mount: bool = true

var diagrams: Array[Node3D] = []

func _ready() -> void:
    _build_case()
    _build_type()
    for stage in range(3):
        _build_diagram(stage, -1.35 + float(stage) * 1.35)

func _material(color: Color, unshaded: bool = true) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.88
    if unshaded: m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return m

func _box(label: String, at: Vector3, size: Vector3, color: Color, parent: Node = null) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.name = label
    var mesh := BoxMesh.new()
    mesh.size = size
    instance.mesh = mesh
    instance.material_override = _material(color)
    if parent == null: parent = self
    parent.add_child(instance)
    instance.position = at
    return instance

func _build_case() -> void:
    _box("Frame", Vector3(0, CENTER_Y, -0.05), Vector3(WIDTH + 0.045, HEIGHT + 0.045, 0.08), INK)
    _box("Paper", Vector3(0, CENTER_Y, 0), Vector3(WIDTH, HEIGHT, 0.035), PAPER)
    for x: float in ([-1.55, 1.55] if show_mount else []):
        _box("Leg", Vector3(x, 0.42, -0.06), Vector3(0.035, 0.84, 0.035), INK)
        _box("Foot", Vector3(x, 0.025, -0.02), Vector3(0.18, 0.05, 0.4), INK)
    var body := StaticBody3D.new()
    body.name = "PlateCollision"
    body.collision_layer = 1
    body.collision_mask = 0
    add_child(body)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(WIDTH + 0.045, HEIGHT + 0.045, 0.10)
    collision.shape = shape
    body.add_child(collision)
    collision.position = Vector3(0, CENTER_Y, -0.02)

func _label(words: String, at: Vector3, size: int, color: Color = INK, font: Font = REGULAR, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label3D:
    var label := Label3D.new()
    label.text = words
    label.font = font
    label.font_size = size
    label.pixel_size = 0.001
    label.modulate = color
    label.outline_size = 0
    label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    label.no_depth_test = false
    label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
    label.horizontal_alignment = align
    add_child(label)
    label.position = at
    return label

func _rule(a: Vector3, b: Vector3, color: Color = RULE, radius: float = 0.0012, parent: Node = null) -> MeshInstance3D:
    var delta := b - a
    var instance := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = delta.length()
    mesh.radial_segments = 10
    mesh.rings = 1
    instance.mesh = mesh
    instance.material_override = _material(color)
    if parent == null: parent = self
    parent.add_child(instance)
    instance.position = (a + b) / 2.0
    instance.quaternion = Quaternion(Vector3.UP, delta.normalized())
    return instance

func _build_type() -> void:
    _label("ADA RESEARCH   /   PRIMITIVES", Vector3(-1.89, 2.52, 0.04), 24, MUTED, MONO, HORIZONTAL_ALIGNMENT_LEFT)
    _label("FIG. 01", Vector3(1.87, 2.52, 0.04), 24, MUTED, MONO, HORIZONTAL_ALIGNMENT_RIGHT)
    _label("Three points. A boundary. A face.", Vector3(-1.89, 2.35, 0.04), 66, INK, LIGHT, HORIZONTAL_ALIGNMENT_LEFT)
    _rule(Vector3(-1.89, 2.19, 0.04), Vector3(1.89, 2.19, 0.04))
    for stage in range(3):
        var x := -1.35 + float(stage) * 1.35
        _label("0%d" % (stage + 1), Vector3(x - 0.48, 2.05, 0.04), 24, ROSE, MONO, HORIZONTAL_ALIGNMENT_LEFT)
        _label(["Positions", "Boundary", "Face"][stage], Vector3(x - 0.48, 1.94, 0.04), 42, INK, REGULAR, HORIZONTAL_ALIGNMENT_LEFT)
        _label(["A    B    C", "AB  +  BC  +  CA", "ABC"][stage], Vector3(x, 1.03, 0.04), 25, MUTED, MONO)
        _label(["Three places in space.", "Connect, then close.", "Give the inside a surface."][stage], Vector3(x, 0.9, 0.04), 29, INK)
    for x: float in [-0.675, 0.675]:
        _rule(Vector3(x, 1.12, 0.035), Vector3(x, 2.08, 0.035))
    _rule(Vector3(-1.89, 0.8, 0.04), Vector3(1.89, 0.8, 0.04))
    _label("Closing a boundary and filling it are two operations.", Vector3(0, 0.735, 0.04), 27, MUTED)

func _build_diagram(stage: int, x: float) -> void:
    var diagram := Node3D.new()
    diagram.name = ["Positions", "Boundary", "Face"][stage]
    add_child(diagram)
    diagram.position = Vector3(x, 1.47, 0.065)
    diagrams.append(diagram)
    var points: Array[Vector3] = []
    for p: Vector2 in TRI_UV:
        points.append(Vector3(p.x * DIAGRAM_SCALE, p.y * DIAGRAM_SCALE, 0))
    # A faint shared baseline gives the three studies the same datum.
    _rule(Vector3(-0.55, points[0].y, -0.02), Vector3(0.55, points[0].y, -0.02), RULE, 0.001, diagram)
    if stage == 2:
        var face := MeshInstance3D.new()
        face.name = "TriangleFill"
        var mesh := ImmediateMesh.new()
        mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
        for v: Vector3 in points: mesh.surface_add_vertex(v + Vector3(0,0,-0.006))
        mesh.surface_end()
        face.mesh = mesh
        var mat := _material(Color(ROSE.r, ROSE.g, ROSE.b, 0.32))
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.cull_mode = BaseMaterial3D.CULL_DISABLED
        face.material_override = mat
        diagram.add_child(face)
    if stage >= 1:
        for i in range(3):
            var edge := _rule(points[i], points[(i+1)%3], INK, 0.005, diagram)
            edge.name = "Edge%d" % i
    for i in range(3):
        var vertex := MeshInstance3D.new()
        vertex.name = "Vertex" + ["A", "B", "C"][i]
        var sphere := SphereMesh.new()
        sphere.radius = 0.017
        sphere.height = 0.034
        sphere.radial_segments = 20
        sphere.rings = 10
        vertex.mesh = sphere
        vertex.material_override = _material(ROSE)
        diagram.add_child(vertex)
        vertex.position = points[i] + Vector3(0,0,0.007)
        var offset := Vector3(-0.055,-0.055,0.06) if i == 0 else Vector3(0.055,-0.055,0.06)
        if i == 2: offset = Vector3(0,0.065,0.06)
        _label(["A", "B", "C"][i], diagram.position + points[i] + offset, 28, INK, MONO)

func illustration_state() -> Dictionary:
    return {"vertices": TRI_UV, "scale": DIAGRAM_SCALE, "stages": [
        {"points": 3, "edges": 0, "faces": 0},
        {"points": 3, "edges": 3, "faces": 0},
        {"points": 3, "edges": 3, "faces": 1}
    ]}
