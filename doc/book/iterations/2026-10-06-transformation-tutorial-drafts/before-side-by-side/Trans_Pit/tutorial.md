# Make room with three operations

**Learning elements**

- Combining translation, rotation and scale
- One progress value driving several properties
- Overlap as a continuing condition
- Opening and returning over time

First watch the blocks that arrive, turn and grow regardless of your approach. Then meet the door at the end of the hall. Its leaves move aside, turn and shrink while the frame stays still. The same operations can take space or offer it.

Combine the sequence's parts: Scale's fixed frame, two familiar boxes, Pre's player-detecting area and a timed change. Body used continuous distance; this study asks whether anyone is within reach. We make a visual opening with a working approach sensor. The installed door's solid leaves, collision resizing, staggered movements and closing delay remain supplied; this reduced study does not block the player.

## The complete study

Attach `lesson.gd` to an empty `TransformStudy` on clear museum floor, with zero rotation and unit scale. Stand at least three metres away before starting, then approach from either side. All dimensions below are local metres. The area extends two metres in front of and behind the doorway.

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

var leaves: Array[MeshInstance3D] = []
var sensor := Area3D.new()
var duration := 3.0
var progress := 0.0
var slide := 1.15

func _ready() -> void:
    assert(duration > 0.0 and slide >= 0.0)
    box(Vector3(0.25, 2.6, 0.35), Vector3(-1.25, 1.3, 0))
    box(Vector3(0.25, 2.6, 0.35), Vector3(1.25, 1.3, 0))
    box(Vector3(2.75, 0.2, 0.35), Vector3(0, 2.7, 0))
    for side in [-1.0, 1.0]:
        leaves.append(box(Vector3(1.1, 2.5, 0.18), Vector3(side * 0.55, 1.25, 0)))

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

func box(size: Vector3, at: Vector3) -> MeshInstance3D:
    var body := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    body.mesh = mesh
    body.position = at
    add_child(body)
    return body

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
        leaves[i].scale = Vector3.ONE * lerpf(1.0, 0.35, t)
```

`leaves` keeps the two instances made by the familiar box function. Their initial centres lie equally far from the middle. The frame boxes are not in this list, so the pose function leaves them alone.

Pre reacted once when a body entered. Here `get_overlapping_bodies()` reads who is still in the area on each physics tick. The loop recognises the same museum player groups. If one qualifies, the target becomes one and `break` ends the search. If no player qualifies, the target remains zero. An ordinary prop does not hold the opening. If two qualifying bodies enter, either one remaining is enough.

`move_toward` changes `progress` by at most `delta / duration` per physics tick and stops at its target. Three seconds takes it from fully closed to fully open. Leaving halfway reverses from the current pose; it does not jump to an endpoint. Physics ticks keep the overlap reading with the physics simulation, while `delta` still measures seconds.

## Follow each operation

The `side` value is −1 for the left leaf and +1 for the right. Multiplying by it gives opposite horizontal directions and opposite turns.

At `t = 0`, the two leaves meet. At `t = 1`, their centres have moved sideways and upward, each has turned 55 degrees in the doorway's face, and each is 35 percent of its starting size. Z is the rotation axis here; Y remains up. Both leaves keep their own centres as their turning and scaling origins.

These operations share one fraction and happen together in our study. The installed mechanism staggers them. In either case, inspect intermediate poses: endpoints alone do not describe the available space throughout the movement.

## Author another opening

Change `duration` to `6.0`. The journey takes twice as long; its end pose stays the same. Then restore three seconds and change `slide` to `1.5`. The leaves travel farther sideways while keeping the same turn and final size. Predict the larger gap before approaching.

You have made a response from three known operations. Arrays can now repeat a body and give each instance its own place or variation. Keep this working opening as one composition; not every object in the next hall needs to inherit its sensor.
