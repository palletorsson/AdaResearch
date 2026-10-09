extends Node3D
## Supplied visual reference: an XY section at local Z = 0.
## No collision or snapping rule. Its labels are lattice indices, not metres.

const Segment = preload("res://prepared/segment.gd")
var ink := StandardMaterial3D.new()
var line_count := 0

func _init():
    ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    ink.albedo_color = Color("48434c")

func build(step: float):
    for child in get_children():
        child.queue_free()
    line_count = 0
    if step < 0.025:
        return # Keep a very fine display from generating thousands of rulers.
    for x in range(ceili(-1.0 / step), floori(1.0 / step) + 1):
        line(Vector3(x * step, 0.5, 0), Vector3(x * step, 1.75, 0))
        label(str(x), Vector3(x * step, 0.4, 0))
    for y in range(ceili(0.5 / step), floori(1.75 / step) + 1):
        line(Vector3(-1, y * step, 0), Vector3(1, y * step, 0))
        label(str(y), Vector3(-1.12, y * step, 0))

func line(a: Vector3, b: Vector3):
    var segment := Segment.new()
    segment.mesh.top_radius = 0.003
    segment.mesh.bottom_radius = 0.003
    segment.material_override = ink
    segment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(segment)
    segment.show_between(a, b)
    line_count += 1

func label(value: String, at: Vector3):
    var text := Label3D.new()
    text.text = value
    text.position = at
    text.font_size = 24
    text.pixel_size = 0.0017
    text.outline_size = 0
    text.modulate = Color("a49ca9")
    add_child(text)
