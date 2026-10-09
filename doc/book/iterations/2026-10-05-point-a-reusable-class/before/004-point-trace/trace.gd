extends Node3D

const RADIUS := 0.14
const CENTRE := Vector3(0, 1.12, 0)
const MIN_SEGMENT_DISTANCE := 0.05

const LineSkin = preload("line_skin.gd")

var point: XRToolsPickable
var readout: Label3D
var positions: Array[Vector3] = []
var trail: Node3D

func _ready() -> void:
    point = XRToolsPickable.new()
    point.position = CENTRE
    point.freeze = true
    point.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    point.release_mode = XRToolsPickable.ReleaseMode.FROZEN
    point.ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    point.collision_layer = 4
    point.collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    point.add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    point.add_child(boundary)

    add_child(point)

    readout = Label3D.new()
    readout.position = Vector3(0, 1.6, 0)
    readout.font_size = 36
    readout.pixel_size = 0.005
    add_child(readout)

    trail = Node3D.new()
    add_child(trail)
    positions.append(point.position)

func _process(_delta: float) -> void:
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

    readout.text += "\nPOINTS " + str(positions.size())
