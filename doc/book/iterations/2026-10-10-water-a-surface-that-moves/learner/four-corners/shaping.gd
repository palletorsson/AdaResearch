extends Node3D

const PointBody = preload("point_body.gd")
const Water = preload("water.gdshader")
const SUBDIVISIONS := 0
const OCTAVES := 3
var material := ShaderMaterial.new()
var control: PointBody
var readout := Label3D.new()
var relief := 0.15
var phase := 0.0
var mode := 0
var surface := MeshInstance3D.new()
var bridge: StaticBody3D
var cube: StaticBody3D

func _ready() -> void:
    material.shader = Water
    material.set_shader_parameter("octaves", OCTAVES)
    var plane := PlaneMesh.new()
    plane.size = Vector2(3, 3)
    plane.subdivide_width = SUBDIVISIONS
    plane.subdivide_depth = SUBDIVISIONS
    surface.mesh = plane
    surface.material_override = material
    surface.position.y = 0.70
    surface.custom_aabb = AABB(Vector3(-1.5, -0.25, -1.5), Vector3(3, 0.5, 3))
    add_child(surface)
    make_box(Vector3(0, 0.38, 0), Vector3(3.2, 0.08, 3.2))
    for side in [-1.0, 1.0]:
        make_box(Vector3(side * 1.55, 0.72, 0), Vector3(0.10, 0.60, 3.2))
        make_box(Vector3(0, 0.72, side * 1.55), Vector3(3, 0.60, 0.10))
    var glass := StandardMaterial3D.new()
    glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    glass.albedo_color = Color(0.65, 0.90, 0.90, 0.18)
    glass.roughness = 0.12
    bridge = make_box(Vector3(0, 1.04, 0), Vector3(0.50, 0.06, 3.2), glass)
    cube = make_box(Vector3(-2, 0.72, 0), Vector3.ONE * 0.60)
    make_box(Vector3(-2, 0.21, 0), Vector3(0.8, 0.42, 0.8))
    control = PointBody.new()
    control.position = Vector3(0.65, 1.2, 1.2)
    add_child(control)
    var black := StandardMaterial3D.new()
    black.albedo_color = Color(0.04, 0.04, 0.04)
    control.coat(black)
    control.action_pressed.connect(next_mode)
    var lamp := OmniLight3D.new()
    lamp.position = Vector3(-1.3, 2.4, 1.8)
    lamp.omni_range = 4.0
    lamp.light_energy = 5.0
    lamp.shadow_enabled = true
    add_child(lamp)
    readout.position = Vector3(0, 2.15, -1.5)
    readout.font_size = 36
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
    mode = (mode + 1) % 3
    update_rule()

func update_rule() -> void:
    var local_point := to_local(control.global_position)
    relief = clampf(0.15 + (local_point.y - 1.2) * 0.5, 0.0, 0.25)
    phase = fposmod((local_point.x - 0.65) * TAU, TAU)
    material.set_shader_parameter("relief", relief)
    material.set_shader_parameter("phase", phase)
    material.set_shader_parameter("mode", mode)
    readout.text = "%s | Raise: %.2f m | Sideways: phase %.2f\nTrigger: next reading" % [
        ["COLOUR", "NORMAL", "HEIGHT"][mode], relief, phase
    ]
