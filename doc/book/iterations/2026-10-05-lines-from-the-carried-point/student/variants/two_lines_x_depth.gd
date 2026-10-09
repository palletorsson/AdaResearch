extends Node3D

const RADIUS := 0.14
const CENTRE := Vector3(0, 1.12, 0)

const LineSkin = preload("line_skin.gd")

var point: XRToolsPickable
var readout: Label3D
var point_b: XRToolsPickable
var line: MeshInstance3D
var distance := 0.0

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

    point_b = point.duplicate() as XRToolsPickable
    point_b.position = CENTRE + Vector3(1.0, 0, 0)
    add_child(point_b)

    line = LineSkin.new()
    add_child(line)
    point.position = Vector3(-0.6, 0.82, 0)
    point_b.position = Vector3(0.6, 2.02, 0)
    var c := Vector3(-0.6, 2.02,0.2)
    var d := Vector3(0.6, 0.82,0.2)
    var other_line := LineSkin.new()
    add_child(other_line)
    other_line.show_segment(c, d - c, (d - c).length())

func _process(_delta: float) -> void:
    var world_position := point.global_position
    var local_position := to_local(world_position)
    readout.text = "LOCAL " + str(local_position) + "\nWORLD " + str(world_position)

    var a := local_position
    var b := to_local(point_b.global_position)
    var displacement := b - a
    distance = displacement.length()
    line.show_segment(a, displacement, distance)
    readout.text += "\nDISTANCE " + str(distance)
