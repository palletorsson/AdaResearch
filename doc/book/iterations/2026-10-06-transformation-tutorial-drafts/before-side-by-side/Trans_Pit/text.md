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

{{CODE}}

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
