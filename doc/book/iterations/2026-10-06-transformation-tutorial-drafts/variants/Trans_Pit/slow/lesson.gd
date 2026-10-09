extends Node3D

const LEAF_SIZE := Vector3(1.1, 2.5, 0.18)
var leaves: Array[AnimatableBody3D] = []
var visuals: Array[MeshInstance3D] = []
var shapes: Array[BoxShape3D] = []
var sensor := Area3D.new()
var duration := 6.0
var progress := 0.0
var slide := 1.15

func _ready() -> void:
    assert(duration > 0.0 and slide >= 0.0)
    box(Vector3(0.25, 2.6, 0.35), Vector3(-1.25, 1.3, 0))
    box(Vector3(0.25, 2.6, 0.35), Vector3(1.25, 1.3, 0))
    box(Vector3(2.75, 0.2, 0.35), Vector3(0, 2.7, 0))
    for side in [-1.0, 1.0]:
        box(LEAF_SIZE, Vector3(side * 0.55, 1.25, 0), true)

    sensor.collision_layer = 0
    sensor.collision_mask = 1
    sensor.set_collision_mask_value(20, true)
    add_child(sensor)
    var hitbox := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(5, 3, 4)
    hitbox.shape = shape
    hitbox.position.y = 1.5
    sensor.add_child(hitbox)

func box(size: Vector3, at: Vector3, is_leaf := false) -> void:
    var body := AnimatableBody3D.new()
    body.sync_to_physics = false
    body.position = at
    add_child(body)
    var visual := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    visual.mesh = mesh
    body.add_child(visual)
    var shape := BoxShape3D.new()
    shape.size = size
    var collision := CollisionShape3D.new()
    collision.shape = shape
    body.add_child(collision)
    if is_leaf:
        leaves.append(body)
        visuals.append(visual)
        shapes.append(shape)

func _physics_process(delta: float) -> void:
    var target := 0.0
    for body in sensor.get_overlapping_bodies():
        if body.is_in_group("em_walker") or body.is_in_group("player_body"):
            target = 1.0
            break
    progress = move_toward(progress, target, delta / duration)
    apply_pose(progress)

func apply_pose(t: float) -> void:
    for i in leaves.size():
        var side := -1.0 if i == 0 else 1.0
        leaves[i].position = Vector3(side * (0.55 + slide * t), 1.25 + 0.9 * t, 0)
        leaves[i].rotation_degrees.z = side * 55.0 * t
        var factor := lerpf(1.0, 0.35, t)
        visuals[i].scale = Vector3.ONE * factor
        shapes[i].size = LEAF_SIZE * factor
