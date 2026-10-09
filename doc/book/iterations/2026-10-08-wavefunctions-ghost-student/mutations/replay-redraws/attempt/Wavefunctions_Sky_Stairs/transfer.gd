extends Node3D

const LineSkin = preload("line_skin.gd")
var count := 11
var angle_step := TAU / 40.0
var radius := 2.5
var amplitude := 0.0
var rise := 0.15
var tread_size := Vector3(1.2, 0.12, 0.6)
var points: Array[Vector3] = []
var treads: Array[StaticBody3D] = []
var label: Label3D

func sample_position(index: int) -> Vector3:
    var angle := index * angle_step
    var r := radius + amplitude * sin(2.0 * angle)
    return Vector3(r * cos(angle), index * rise, r * sin(angle))

func text_at(words: String, at: Vector3, size: int = 24) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = size
    text.pixel_size = 0.0025
    text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(text)
    return text

func _ready() -> void:
    var finish := StandardMaterial3D.new()
    finish.albedo_color = Color(0.87, 0.86, 0.83)
    finish.roughness = 0.7
    for i in range(count):
        var top := sample_position(i)
        points.append(top)
        var tread := StaticBody3D.new()
        tread.position = top - Vector3.UP * tread_size.y * 0.5
        tread.rotation.y = -i * angle_step
        var surface := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = tread_size
        surface.mesh = box
        surface.material_override = finish
        tread.add_child(surface)
        var boundary := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = tread_size
        boundary.shape = shape
        tread.add_child(boundary)
        add_child(tread)
        treads.append(tread)
        if i > 0:
            var line := LineSkin.new()
            add_child(line)
            var previous := points[i - 1] + Vector3.UP * 0.025
            var delta := top + Vector3.UP * 0.025 - previous
            line.show_segment(previous, delta, delta.length())
        if i in [0, 5, 10]:
            text_at("%d | top %.2f m" % [i, top.y], top + Vector3.UP * 0.28, 18)
    var inner := edge_distance(4, 5, -1.0)
    var outer := edge_distance(4, 5, 1.0)
    label = text_at("Same rise: %.2f m\n4 to 5: inner %.2f m | outer %.2f m\nDistances between side midpoints, not clear gaps" % [rise, inner, outer], Vector3(0, 1.6, 1.0))

func edge_position(index: int, side: float) -> Vector3:
    var tread := treads[index]
    var local := Vector3(side * tread_size.x * 0.5, tread_size.y * 0.5, 0)
    return tread.transform * local

func edge_distance(a: int, b: int, side: float) -> float:
    return edge_position(a, side).distance_to(edge_position(b, side))
