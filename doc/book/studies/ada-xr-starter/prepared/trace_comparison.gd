extends Node3D
## Supplied twin display. Data is never modified. Both views use the SAME fit,
## based on the source bounds, and different horizontal offsets. Rounding occurs
## in the original Study frame before this shared display transform.

const TraceDrawing = preload("res://prepared/trace_drawing.gd")
const Segment = preload("res://prepared/segment.gd")
var original := TraceDrawing.new()
var rounded := TraceDrawing.new()
var ruling := Node3D.new()
var message := Label3D.new()
var centre := Vector3.ZERO
var display_scale := 1.0

func _ready():
    add_child(original)
    add_child(rounded)
    add_child(ruling)
    message.position = Vector3(0, 2.65, -0.6)
    message.font_size = 27
    add_child(message)
    label("YOUR TRACE", Vector3(-1.22, 2.21, 0))
    label("ON THE GRID", Vector3(1.22, 2.21, 0))

func show_message(text: String):
    message.text = text

func label(text: String, at: Vector3):
    var node := Label3D.new()
    node.text = text
    node.position = at
    node.font_size = 25
    node.outline_size = 0
    node.pixel_size = 0.002
    add_child(node)

func show_traces(source: Array[Vector3], mapped: Array[Vector3], step: float):
    var low := source[0]
    var high := source[0]
    for p in source:
        low = low.min(p)
        high = high.max(p)
    centre = (low + high) * 0.5
    var span := high - low
    # Reserve half a metre around the source for ordinary rounding experiments.
    display_scale = minf(1.6 / maxf(span.x + 1.0, 1.0), minf(1.15 / maxf(span.y + 1.0, 1.0), 1.0 / maxf(span.z + 1.0, 1.0)))
    original.scale = Vector3.ONE * display_scale
    rounded.scale = Vector3.ONE * display_scale
    original.position = Vector3(-1.22, 1.3, 0) - centre * display_scale
    rounded.position = Vector3(1.22, 1.3, 0) - centre * display_scale
    ruling.transform = rounded.transform
    original.clear()
    rounded.clear()
    for i in range(1, source.size()):
        original.join(source[i - 1], source[i])
        rounded.join(mapped[i - 1], mapped[i])
    original.dot_material.albedo_color = Color("ec9dbb")
    rounded.dot_material.albedo_color = Color("f2eee4")
    for stroke in original.strokes:
        stroke.get_child(0).material_override.albedo_color = Color("ec9dbb")
    message.text = str(source.size()) + " positions from Trace / grid " + str(step) + " m"
    draw_ruling(low, high, step)

func draw_ruling(low: Vector3, high: Vector3, step: float):
    for child in ruling.get_children():
        child.queue_free()
    if step <= 0:
        return
    var x0 := floori(low.x / step) - 1
    var x1 := ceili(high.x / step) + 1
    var y0 := floori(low.y / step) - 1
    var y1 := ceili(high.y / step) + 1
    if x1 - x0 + y1 - y0 > 160:
        return
    var z := roundf(centre.z / step) * step
    for x in range(x0, x1 + 1):
        ruled_line(Vector3(x * step, y0 * step, z), Vector3(x * step, y1 * step, z))
    for y in range(y0, y1 + 1):
        ruled_line(Vector3(x0 * step, y * step, z), Vector3(x1 * step, y * step, z))
    label("XY section at z = %.2f m" % z, Vector3(1.22, 0.45, 0))

func ruled_line(a: Vector3, b: Vector3):
    var segment := Segment.new()
    segment.mesh.top_radius = 0.003 / display_scale
    segment.mesh.bottom_radius = 0.003 / display_scale
    segment.material_override.albedo_color = Color("49434d")
    segment.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    segment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    ruling.add_child(segment)
    segment.show_between(a, b)
