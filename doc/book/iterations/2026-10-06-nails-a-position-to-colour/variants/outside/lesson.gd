extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")

var box_size := Vector3(0.6, 0.6, 0.6)
var start := Vector3(-0.2, 0.9, 0.3)
var point: XRToolsPickable
var preview: MeshInstance3D
var swatch: StandardMaterial3D
var readout: Label3D

func _ready() -> void:
    point = PointBody.new()
    point.position = start
    add_child(point)

    preview = MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(0.32, 0.32, 0.04)
    preview.mesh = box
    preview.position = Vector3(-0.35, 0.3, 0)
    swatch = StandardMaterial3D.new()
    swatch.roughness = 0.35
    preview.material_override = swatch
    add_child(preview)

    readout = Label3D.new()
    readout.position = Vector3(0.3, 0.85, 0)
    readout.font_size = 32
    readout.pixel_size = 0.003
    add_child(readout)

    for end in [Vector3(box_size.x, 0, 0), Vector3(0, box_size.y, 0), Vector3(0, 0, box_size.z)]:
        var guide := LineSkin.new()
        add_child(guide)
        guide.show_segment(Vector3.ZERO, end, end.length())

func _process(_delta: float) -> void:
    var local_position := to_local(point.global_position)
    var chosen := colour_at(local_position, box_size)
    swatch.albedo_color = chosen
    readout.text = "RGB %.2f  %.2f  %.2f" % [chosen.r, chosen.g, chosen.b]

func colour_at(p: Vector3, size: Vector3) -> Color:
    assert(size.x > 0 and size.y > 0 and size.z > 0)
    var channels := (p / size).clamp(Vector3.ZERO, Vector3.ONE)
    return Color(channels.x, channels.y, channels.z)
