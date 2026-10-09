extends Node3D

const PointBody = preload("point_body.gd")
const VALUE_BOTTOM := 0.46
const VALUE_TOP := 4.6

var start := Vector3(6.4, 0.65, 9.6)
var point: XRToolsPickable
var swatch: StandardMaterial3D
var readout: Label3D

func _ready() -> void:
    point = PointBody.new()
    point.position = start
    add_child(point)
    var preview := MeshInstance3D.new()
    var tile := BoxMesh.new()
    tile.size = Vector3(0.28, 0.28, 0.025)
    preview.mesh = tile
    preview.position = Vector3(0.35, 0, 0)
    swatch = StandardMaterial3D.new()
    swatch.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    preview.material_override = swatch
    point.add_child(preview)
    readout = Label3D.new()
    readout.position = Vector3(0.35, 0.35, 0)
    readout.font_size = 28
    readout.pixel_size = 0.002
    point.add_child(readout)

func _process(_delta: float) -> void:
    var hand := to_local(point.global_position)
    var field := hand_to_field(hand)
    var hsv := hsv_at(field)
    var colour := colour_at(field)
    swatch.albedo_color = colour
    readout.text = "HSV %.3f %.3f %.3f\nRGB %.3f %.3f %.3f" % [hsv.x, hsv.y, hsv.z, colour.r, colour.g, colour.b]

func hand_to_field(hand: Vector3) -> Vector3:
    var fraction := clampf((hand.y - 0.65) / 1.2, 0, 1)
    return Vector3(hand.x, lerpf(VALUE_BOTTOM, VALUE_TOP, fraction), hand.z)

func hsv_at(p: Vector3) -> Vector3:
    var hue := clampf(p.x / 12.8, 0, 1) * 0.85
    var saturation := lerpf(0.25, 1.0, clampf(p.z / 19.2, 0, 1))
    var value := clampf((p.y - VALUE_BOTTOM) / (VALUE_TOP - VALUE_BOTTOM), 0, 1)
    return Vector3(hue, saturation, value)

func colour_at(p: Vector3) -> Color:
    var hsv := hsv_at(p)
    return Color.from_hsv(hsv.x, hsv.y, hsv.z)
