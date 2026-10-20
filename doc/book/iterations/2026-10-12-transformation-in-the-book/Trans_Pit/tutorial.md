# Make room with three operations

**Learning elements**

- Combining translation, rotation and scale
- One progress value driving several properties
- Overlap as a continuing condition
- Opening and returning over time
- Keeping a solid boundary with the visible shape

First watch the blocks that arrive, turn and grow regardless of your approach. Then meet the door at the end of the hall. Its leaves move aside, turn and shrink while the frame stays still. The same operations can take space or offer it.

Combine the sequence's parts: Scale's fixed frame, two familiar boxes, Pre's player-detecting area and a timed change. Body used continuous distance; this study asks whether anyone is within reach. This time the frame and leaves are solid. A closed leaf stops you; the transformed leaves leave a passage. The installed door's staggered movements and closing delay remain further variations.

## The complete study

Attach `lesson.gd` to an empty `TransformStudy` on clear museum floor, with zero rotation and unit scale. Stand at least three metres away before starting, then approach from either side. All dimensions below are local metres. The area extends two metres in front of and behind the doorway.

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

const LEAF_SIZE := Vector3(1.1, 2.5, 0.18)
var leaves: Array[AnimatableBody3D] = []
var visuals: Array[MeshInstance3D] = []
var shapes: Array[BoxShape3D] = []
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
```

The box function now builds each box around an `AnimatableBody3D`: a solid body whose movement our code controls. Inside it, a `MeshInstance3D` supplies the visible box and a `CollisionShape3D` holds a matching `BoxShape3D`. The frame uses the same construction but stays still. We set `sync_to_physics` false because our own `_physics_process` assigns the poses on physics ticks.

When `is_leaf` is true, the function keeps three references: the body in `leaves`, its mesh instance in `visuals`, and its collision shape in `shapes`. The same index identifies parts of the same leaf. Their centres begin equally far from the middle. The frame boxes are outside these lists, so the pose function leaves them alone.

Pre reacted once when a body entered. Here `get_overlapping_bodies()` reads who is still in the area on each physics tick. The loop recognises the same museum player groups. If one qualifies, the target becomes one and `break` ends the search. If no player qualifies, the target remains zero. An ordinary prop does not hold the opening. If two qualifying bodies enter, either one remaining is enough.

`move_toward` changes `progress` by at most `delta / duration` per physics tick and stops at its target. Three seconds takes it from fully closed to fully open. Leaving halfway reverses from the current pose; it does not jump to an endpoint. Physics ticks keep the overlap reading with the physics simulation, while `delta` still measures seconds.

## Follow each operation

The `side` value is −1 for the left leaf and +1 for the right. Multiplying by it gives opposite horizontal directions and opposite turns.

At `t = 0`, the two leaves meet. At `t = 1`, their centres have moved sideways and upward, each has turned 55 degrees in the doorway's face, and each is 35 percent of its starting size. Z is the rotation axis here; Y remains up. Both leaves keep their own centres as their turning and scaling origins.

The body's position and rotation carry both its mesh and collision. For size, we scale the visual and resize the box shape by the same factor, while the physics body keeps unit scale. That makes the visible gap agree with the solid boundary. Shrinking only the mesh would leave an invisible barrier.

Approach and wait as the leaves withdraw, then walk through the frame. The area keeps the door open while you remain nearby, including on the far side. After everyone leaves, this version begins closing immediately. Its frame has finite width: walking around it is also possible.

These operations share one fraction and happen together in our study. The installed mechanism staggers them and waits three seconds before closing. In either case, inspect intermediate poses: endpoints alone do not describe the available space throughout the movement.

## Author another opening

Change `duration` to `6.0`. The journey takes twice as long; its end pose stays the same. Then restore three seconds and change `slide` to `1.5`. The leaves travel farther sideways while keeping the same turn and final size. Predict the larger gap before approaching.

You have made a response from three known operations. Keep this working opening as one composition. Its two leaves also returned to arrays and indices from Trace: one index connects a body, its visible mesh and its collision shape. The fixed frame stays outside that collection.

In Arrays, return to Trans_Pre's one-metre `BoxMesh` and collection area. Begin with still cubes, give each copy an address, then collect one without shifting the others' addresses. Carry the cube construction, local placement, loops and overlap detection; leave the door's animation and solid leaves here. We reuse code and understanding across halls, rather than transport a live node. The next question is what the collection must remember after one of its bodies disappears.
