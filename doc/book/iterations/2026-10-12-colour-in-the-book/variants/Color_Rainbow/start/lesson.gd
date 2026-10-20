extends Node3D

const ArcStrip = preload("arc_strip.gd")
const INNER_RADIUS := 0.7
const TOTAL_THICKNESS := 0.6

var palette: Array[Color] = [Color(0.8, 0.2, 0.6), Color(0.15, 0.55, 0.9), Color(1, 0.8, 0.15)]
var bands: Array[MeshInstance3D] = []

func _ready() -> void:
    assert(not palette.is_empty())
    var width := TOTAL_THICKNESS / float(palette.size())
    for i in range(palette.size()):
        var inner := INNER_RADIUS + i * width
        var band := ArcStrip.new()
        band.build(inner, inner + width, palette[i])
        add_child(band)
        bands.append(band)
