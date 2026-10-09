The far bank is familiar now. In the last hall, a moving surface carried you across. Here that small surface becomes the thread through a longer space.

Before boarding, follow the line of waiting cubes with your eyes. Some hang over the pit. Others are high above the floor. Which ones could you reach from where you stand?

<!-- @tc -->

The first carrier travels into depth. Step aboard and let the room pass. Look at the cube under your feet: it keeps its facing and size. Along this journey, only its z coordinate changes.

At the next island, the route turns sideways. The carrier moves along x. You can keep looking towards the far end of the hall while travelling across it. Direction of travel and direction of attention have separated.

Then the way goes up.

Stand on the lift and watch the lower landing descend from view. It is still where it was. The carrier changes y; the room gives that change a consequence. You arrive beside an upper platform, three metres above the ground route.

The three small axis markers near the entrance have made these directions visible one at a time. Now the same distinctions have carried your body.

The transport script calculates a destination from a starting position, a direction and a distance:

```gdscript
target_position = initial_position + (move_direction * move_distance)
```

The direction is normalised before this calculation. It says which way; the distance says how far. A displacement of three metres upwards is written with a different direction from three metres forwards. The addition is the same kind of operation.

On the upper route, another carrier travels along z. You have done this before, but there is more space below your feet. What changed in the operation? What changed in the encounter?

A sideways return carries you back across x in the opposite direction. Then the next carrier moves down and forward together, like an escalator. Its surface stays level while its path slopes: three metres down, two metres further along z. Watch the pickup approach as the lower landing comes towards you.

<!-- @pick_up_cube -->

The small pickups have been waiting along these journeys. They rise and fall without turning. Their small vertical loop continues as the carrier brings you into contact with them, and each collected cube disappears with a sound.

Take one, then look back while the carrier moves on.

The transport does not collect them at a distance. It adds its own movement to the detected rider:

```gdscript
var movement_delta = global_position - previous_position
_translate_rider(carried_player, movement_delta)
```

For each small move of the carrier, your position moves with it. A pickup detects the arriving body and disappears. Ride back to its place. The carrier can repeat the journey; the cube is gone.

<!-- @ -->

At the last crossing, the waiting cubes run diagonally over the pit. Watch an edge of the carrier as you travel. It does not turn.

This direction changes x and z together. The destination lies eight metres across and eight metres further into the hall. Both coordinates change during the same journey. We have combined directions without adding rotation.

Thirteen pickups mark one possible passage through seven rides. Their positions make some encounters easy and leave other parts of the arena untouched. Another arrangement could ask for another journey using exactly the same operations.

<!-- @translation_cube_demo -->

Step onto the final terrace. Two small door mechanisms wait at hand height. Take a square handle and try moving it upwards and sideways in the same gesture. A pale line stays behind it.

At the rail-guided door, the line rises. The sideways part of your gesture has gone missing. Beside it, the other mechanism lets the handle move in both directions together. Its line can cross the opening diagonally.

Lift the guided handle to the corner of its rail, then move it sideways. A bend leads to the place the other handle could reach directly. The translucent panel beside the second door marks its destination. Compare the two handles in their frames: they have the same distance to travel up and across.

What do the lines record? Here is the guided door retaining the part of a displacement that runs along its current axis:

```gdscript
var t = (knob_pos - start).dot(phase1_dir)
knob_pos = start + phase1_dir * t
```

The full implementation also clamps the distance. The trail records the handle after this correction. Your hand can propose a diagonal and leave a vertical line.

In the trace hall, movement left positions behind. Here the recorded positions belong to a handle whose movement has already been constrained. The line can be an accurate record without showing everything you tried.

Bring the free handle back towards its starting corner, then try a curved route to the ghost. The lines can remain together as you try another way. There is room to take the long way, within the movement this frame allows.

![Two door mechanisms leave different traces for different permitted paths.](/book-review/doc/book/iterations/2026-09-23-translation-paths/translation-paths.png)

*A guided bend, a direct diagonal, and a curved route to the same relative endpoint. Each panel records a separate gesture at the handle.*

Up followed by sideways reaches the same position as sideways followed by up. Translation itself does not impose this order. The first mechanism does. The second gives both freedoms together. A destination can be shared by journeys with very different permissions.

<!-- @ -->

The torus beside the course already turns while its cylinder rises and falls. It offers a glimpse of the next question. Our carriers have kept their facing throughout; this neighbouring object combines the operations. Keep the difference between travelling and facing in mind. In the next hall, the turn itself will become the question.
