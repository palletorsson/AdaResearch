extends Node3D

const TraceArchive = preload("trace_archive.gd")
const LineSkin = preload("line_skin.gd")

var sculpture: Node3D
var grid_copy: Node3D
var positions := PackedVector3Array()
var addresses: Array[Vector3i] = []
var grid_step := 0.25
var readout: Label3D

func _ready() -> void:
    readout = Label3D.new()
    readout.position = Vector3(0, 2.0, 0)
    readout.font_size = 36
    readout.pixel_size = 0.003
    add_child(readout)

    sculpture = TraceArchive.load_drawing()
    if sculpture == null:
        readout.text = "Draw in Trace, then release the point to save."
        return
    add_child(sculpture)
    positions = sculpture.get_meta("positions").duplicate()

    grid_copy = sculpture.duplicate() as Node3D
    add_child(grid_copy)
    for i in grid_copy.get_child_count():
        var segment := grid_copy.get_child(i)
        var original := sculpture.get_child(i)
        segment.set_script(LineSkin)
        segment.mesh = original.mesh.duplicate()
        segment.material_override = original.material_override.duplicate()
        segment.material_override.albedo_color = Color(0.25, 0.85, 0.60)
    _place_on_grid()

func _process(_delta: float) -> void:
    if grid_copy != null and Input.is_action_just_pressed("ui_accept"):
        grid_step = 0.50 if grid_step == 0.25 else 0.25
        _place_on_grid()

func _place_on_grid() -> void:
    addresses.clear()
    for p in positions:
        addresses.append(Vector3i(
            roundi(p.x / grid_step),
            roundi(p.y / grid_step),
            roundi(p.z / grid_step)
        ))
    for i in range(1, addresses.size()):
        var a := Vector3(addresses[i - 1]) * grid_step
        var b := Vector3(addresses[i]) * grid_step
        var displacement := b - a
        grid_copy.get_child(i - 1).show_segment(a, displacement, displacement.length())
    readout.text = "YOUR SAVED TRACE\nPOINTS " + str(positions.size())
    readout.text += "\nGRID " + str(grid_step) + " m"
