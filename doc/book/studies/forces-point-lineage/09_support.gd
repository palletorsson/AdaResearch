extends "study.gd"
var leg: StaticBody3D
var load: RigidBody3D

func _ready() -> void:
    leg = StaticBody3D.new()
    leg.position = Vector3(0, 0.5, 0)
    add_child(leg)
    box_on(leg, Vector3(0.4, 1.0, 0.4))
    load = RigidBody3D.new()
    load.position = Vector3(0, 1.31, 0)
    load.mass = 2.0
    add_child(load)
    box_on(load, Vector3.ONE * 0.6)
    caption("A cube stays up because something meets it.")
    button("REMOVE SUPPORT", Vector3(0, 1, -0.8), remove_support)

func box_on(body: PhysicsBody3D, size: Vector3) -> void:
    var surface := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    surface.mesh = mesh
    body.add_child(surface)
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collider.shape = shape
    body.add_child(collider)

func remove_support() -> void:
    leg.position.x = 1.5
    load.sleeping = false

