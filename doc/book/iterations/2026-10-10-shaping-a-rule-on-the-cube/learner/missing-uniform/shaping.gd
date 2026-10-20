extends Node3D

const PointBody = preload("point_body.gd")
const Circle = preload("circle.gdshader")
var material := ShaderMaterial.new()
var control: PointBody
var readout := Label3D.new()
var radius := 0.30
var soft := false
var receivers: Array[MeshInstance3D] = []

func _ready() -> void:
    material.shader = Circle
    make_box(Vector3(0, 1.6, -0.08), Vector3(2.2, 2.2, 0.1))
    make_receiver(Vector2(2, 2), Vector3(0, 1.6, 0))
    make_box(Vector3(0, 0.8, 1.0), Vector3(2.2, 0.1, 0.8))
    make_box(Vector3(-0.65, 1.15, 1.0), Vector3.ONE * 0.6)
    make_receiver(Vector2(0.54, 0.54), Vector3(-0.65, 1.15, 1.306))
    control = PointBody.new()
    control.position = Vector3(0.65, 1.2, 1.2)
    add_child(control)
    control.action_pressed.connect(toggle_edge)
    readout.position = Vector3(0, 2.85, 0)
    readout.font_size = 36
    readout.pixel_size = 0.002
    add_child(readout)
    update_rule()

func make_receiver(size: Vector2, at: Vector3) -> void:
    var surface := MeshInstance3D.new()
    var square := QuadMesh.new()
    square.size = size
    surface.mesh = square
    surface.material_override = material
    surface.position = at
    add_child(surface)
    receivers.append(surface)

func make_box(at: Vector3, size: Vector3) -> void:
    var body := StaticBody3D.new()
    body.position = at
    var surface := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    surface.mesh = box
    var grey := StandardMaterial3D.new()
    grey.albedo_color = Color(0.12, 0.12, 0.12)
    surface.material_override = grey
    body.add_child(surface)
    var boundary := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    boundary.shape = shape
    body.add_child(boundary)
    add_child(body)

func _process(_delta: float) -> void:
    update_rule()

func toggle_edge(_point) -> void:
    soft = not soft
    update_rule()

func update_rule() -> void:
    var height := to_local(control.global_position).y
    radius = clampf(0.30 + (height - 1.2) * 0.38, 0.08, 0.46)
    pass # Deliberate missing connection
    material.set_shader_parameter("softness", 0.045 if soft else 0.0)
    readout.text = "Raise the point: radius %.2f\nTrigger: %s edge" % [
        radius, "soft" if soft else "hard"
    ]
