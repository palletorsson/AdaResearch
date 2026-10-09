extends Node3D

const RADIUS := 0.14
const CENTRE := Vector3(0, 1.12, 0)

var point: XRToolsPickable
var readout: Label3D

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

func _process(_delta: float) -> void:
    var world_position := point.global_position
    var local_position := to_local(world_position)
    readout.text = "LOCAL " + str(local_position) + "\nWORLD " + str(world_position)
