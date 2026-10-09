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

{{CODE}}

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

You have made a response from three known operations. Arrays can now repeat a body and give each instance its own place or variation. Keep this working opening as one composition; not every object in the next hall needs to inherit its sensor.
