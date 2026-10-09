extends Node3D

const CENTRE := Vector3(0, 1.12, 0)
const MIN_SEGMENT_DISTANCE := 0.05

const PointBody = preload("point_body.gd")

const LineSkin = preload("line_skin.gd")

var point: XRToolsPickable
var readout: Label3D
var positions: Array[Vector3] = []
var trail: Node3D
var grid_step := 0.25
var addresses: Array[Vector3i] = []
var snapped_positions: Array[Vector3] = []
var grid_trail: Node3D

func _ready() -> void:
    point = PointBody.new()
    point.position = CENTRE
    add_child(point)

    readout = Label3D.new()
    readout.position = Vector3(0, 2.0, 0)
    readout.font_size = 36
    readout.pixel_size = 0.003
    add_child(readout)

    trail = Node3D.new()
    add_child(trail)
    positions.append(point.position)

    grid_trail = Node3D.new()
    add_child(grid_trail)
    point.action_pressed.connect(_change_pitch)
    _redraw_grid()

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("ui_accept"):
        _change_pitch()

    var world_position := point.global_position
    var local_position := to_local(world_position)
    readout.text = "LOCAL " + str(local_position) + "\nWORLD " + str(world_position)

    var last := positions[positions.size() - 1]
    if (local_position - last).length() >= MIN_SEGMENT_DISTANCE:
        positions.append(local_position)

        for segment in trail.get_children():
            segment.queue_free()

        for i in range(1, positions.size()):
            var a := positions[i - 1]
            var displacement := positions[i] - a
            var segment := LineSkin.new()
            trail.add_child(segment)
            segment.show_segment(a, displacement, displacement.length())

        _redraw_grid()

    readout.text += "\nPOINTS " + str(positions.size())
    readout.text += "\nPITCH " + str(grid_step) + " m"
    if not addresses.is_empty():
        readout.text += "\nLAST ADDRESS " + str(addresses[addresses.size() - 1])

func _change_pitch(_held_point: Node3D = null) -> void:
    if grid_step == 0.25:
        grid_step = 0.50
    else:
        grid_step = 0.25
    _redraw_grid()

func _redraw_grid() -> void:
    addresses.clear()
    snapped_positions.clear()
    for segment in grid_trail.get_children():
        segment.queue_free()
    if grid_step <= 0.0:
        return

    for p in positions:
        var address := Vector3i(
            roundi(p.x / grid_step),
            roundi(p.y / grid_step),
            roundi(p.z / grid_step)
        )
        addresses.append(address)
        snapped_positions.append(Vector3(address) * grid_step)

    for i in range(1, snapped_positions.size()):
        var a := snapped_positions[i - 1]
        var displacement := snapped_positions[i] - a
        var segment := LineSkin.new()
        var finish := segment.material_override as StandardMaterial3D
        finish.albedo_color = Color(0.25, 0.85, 0.60)
        grid_trail.add_child(segment)
        segment.show_segment(a, displacement, displacement.length())
