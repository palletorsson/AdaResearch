extends Node3D

const CENTRE := Vector3(0, 1.12, 0)
const MIN_SEGMENT_DISTANCE := 0.05

const PointBody = preload("point_body.gd")

const LineSkin = preload("line_skin.gd")
const TraceArchive = preload("trace_archive.gd")

var point: XRToolsPickable
var readout: Label3D
var positions: Array[Vector3] = []
var trail: Node3D

func _ready() -> void:
    point = PointBody.new()
    point.position = CENTRE
    add_child(point)

    readout = Label3D.new()
    readout.position = Vector3(0, 1.6, 0)
    readout.font_size = 36
    readout.pixel_size = 0.005
    add_child(readout)

    trail = Node3D.new()
    add_child(trail)
    positions.append(point.position)
    point.dropped.connect(_save_trace)

func _process(_delta: float) -> void:
    var world_position := point.global_position
    var local_position := to_local(world_position)
    readout.text = "LOCAL " + str(local_position) + "\nWORLD " + str(world_position)

    var last := positions[positions.size() - 1]
    if (local_position - last).length() >= MIN_SEGMENT_DISTANCE:
        positions.append(local_position)

        for segment in trail.get_children():
            segment.queue_free()

        for i in range(1, positions.size() - 1):
            var a := positions[i - 1]
            var displacement := positions[i] - a
            var segment := LineSkin.new()
            trail.add_child(segment)
            segment.show_segment(a, displacement, displacement.length())

    readout.text += "\nPOINTS " + str(positions.size())

func _save_trace(_point: Node3D) -> void:
    await get_tree().process_frame
    if positions.size() < 2:
        return
    var error := TraceArchive.save_drawing(trail, positions)
    if error != OK:
        push_error("Could not save this trace: " + error_string(error))
