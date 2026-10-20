extends Node3D

const PointBody = preload("point_body.gd")
const Relief = preload("relief.gdshader")
const Maps = preload("relief_maps.gd")
var material := ShaderMaterial.new()
var control: PointBody
var readout := Label3D.new()
var strength := 0.6
var roughness := 0.35
var mode := 0
var maps: Dictionary
var receivers: Array[MeshInstance3D] = []

func _ready() -> void:
    material.shader = Relief
    maps = Maps.build()
    material.set_shader_parameter("height_map", maps.height)
    material.set_shader_parameter("normal_map", maps.normal)
    material.set_shader_parameter("texel", Vector2.ONE / Maps.SIDE)
    material.set_shader_parameter("height_gain", Maps.GAIN)
    make_box(Vector3(0, 1.6, -0.08), Vector3(2.2, 2.2, 0.1))
    make_receiver(Vector2(2, 2), Vector3(0, 1.6, 0))
    make_box(Vector3(0, 0.8, 1.0), Vector3(2.2, 0.1, 0.8))
    make_box(Vector3(-0.65, 1.15, 1.0), Vector3.ONE * 0.6)
    make_receiver(Vector2(0.54, 0.54), Vector3(-0.65, 1.15, 1.306))
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

func next_mode(_point) -> void:
    mode = (mode + 1) % 3
    update_rule()

func update_rule() -> void:
    var local_point := to_local(control.global_position)
    strength = clampf(0.6 + (local_point.y - 1.2) * 2.0, 0.0, 1.0)
    roughness = clampf(0.35 + (local_point.x - 0.65) * 0.5, 0.05, 0.95)
    material.set_shader_parameter("strength", strength)
    material.set_shader_parameter("roughness", roughness)
    material.set_shader_parameter("mode", mode)
    readout.text = "%s | Raise: relief %.2f | Sideways: roughness %.2f\nTrigger: next reading" % [
        ["FLAT", "HEIGHT MAP", "NORMAL MAP"][mode], strength, roughness
    ]
