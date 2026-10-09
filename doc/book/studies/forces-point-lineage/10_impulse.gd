extends "study.gd"
var point = Point.new()
var target: RigidBody3D
var used := false
var impulse := Vector3(0, 0, 3) # N·s in the study frame

func _ready() -> void:
    add_child(point)
    point.position = Vector3(0, 1.2, -1)
    target = Point.new()
    add_child(target)
    target.position = Vector3(0, 1.2, 1)
    for body in [point, target]:
        body.mass = 1.0
        body.collision_layer = 4
        body.collision_mask = 4
    caption("One impulse. Then the contact has its turn.")
    button("ROLL ONCE", Vector3(0, 1, -1.8), roll)

func roll() -> void:
    if used:
        return
    used = true
    point.apply_central_impulse(global_basis * impulse)

