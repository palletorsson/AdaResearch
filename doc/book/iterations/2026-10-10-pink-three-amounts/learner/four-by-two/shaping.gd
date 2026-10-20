extends Node3D

const PointBody = preload("point_body.gd")
const Recipe = preload("recipe.gdshader")
const REPEATS := Vector2(4, 2)
var material := ShaderMaterial.new()
var control: PointBody
var readout := Label3D.new()
var amounts := Vector3(1.0, 0.6, 0.3)
var mode := 1
var cube: StaticBody3D

func _ready() -> void:
    material.shader = Recipe
    material.set_shader_parameter("repeats", REPEATS)
    cube = make_box(Vector3(-0.6, 0.9, 0), Vector3.ONE * 0.60, material)
    make_box(Vector3(-0.6, 0.30, 0), Vector3(0.8, 0.60, 0.8))
    control = PointBody.new()
    control.position = Vector3(0.65, 1.2, 1.2)
    add_child(control)
    control.coat(material)
    control.action_pressed.connect(next_mode)
    var lamp := OmniLight3D.new()
    lamp.position = Vector3(-1.3, 2.4, 1.8)
    lamp.omni_range = 4.0
    lamp.light_energy = 5.0
    lamp.shadow_enabled = true
    add_child(lamp)
    readout.position = Vector3(0, 1.9, -0.5)
    readout.font_size = 28
    readout.pixel_size = 0.002
    add_child(readout)
    update_rule()



func make_box(at: Vector3, size: Vector3, paint: Material = null) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.position = at
    var surface := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    surface.mesh = box
    var grey := StandardMaterial3D.new()
    grey.albedo_color = Color(0.12, 0.12, 0.12)
    surface.material_override = grey if paint == null else paint
    body.add_child(surface)
    var boundary := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    boundary.shape = shape
    body.add_child(boundary)
    add_child(body)
    return body

func _process(_delta: float) -> void:
    update_rule()

func next_mode(_point) -> void:
    mode = (mode + 1) % 2
    update_rule()

func update_rule() -> void:
    var local_point := to_local(control.global_position)
    amounts = Vector3(
        clampf(1.0 + local_point.x - 0.65, 0.0, 1.0),
        clampf(0.6 + local_point.y - 1.2, 0.0, 1.0),
        clampf(0.3 + local_point.z - 1.2, 0.0, 1.0)
    )
    material.set_shader_parameter("amounts", amounts if mode == 1 else Vector3.ZERO)
    readout.text = "%s | X dots %.2f / Y rim %.2f / Z glow %.2f\nTrigger: compare base and composition" % [
        ["BASE", "COMPOSED"][mode], amounts.x, amounts.y, amounts.z
    ]
