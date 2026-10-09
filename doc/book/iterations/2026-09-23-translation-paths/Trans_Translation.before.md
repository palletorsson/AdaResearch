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

Coordinates describe the ride; their agreement with the surrounding floor makes it usable.

<!-- @pick_up_cube -->

The small pickups have been waiting along these journeys. They rise and fall without turning. Their small vertical loop continues as the carrier brings you into contact with them, and each collected cube disappears with a sound.

You can return along the same displacement. The pickups already taken do not return with you.

The transport does not collect them at a distance. It adds its own movement to the detected rider:

```gdscript
var movement_delta = global_position - previous_position
_translate_rider(carried_player, movement_delta)
```

The helper moves the desktop body or the VR tracking origin with its collision body by that small displacement. It does not place the visitor at the destination. A pickup's detection area then recognises the passing body and calls `collect()`. Two small systems meet: one carries, the other notices contact. The empty place left behind belongs to their encounter.

<!-- @ -->

At the last crossing, the waiting cubes run diagonally over the pit. Watch an edge of the carrier as you travel. It does not turn.

This direction changes x and z together. The destination lies eight metres across and eight metres further into the hall. Both coordinates change during the same journey. We have combined directions without adding rotation.

Thirteen pickups mark one possible passage through seven rides. Their positions make some encounters easy and leave other parts of the arena untouched. Another arrangement could ask for another journey using exactly the same operations.

<!-- @translation_cube_demo -->

Step onto the final terrace. Two small door mechanisms wait at hand height. Their handles have the same distance to travel upwards and sideways. Try taking the diagonal.

One refuses. Its handle travels up a rail before sideways movement becomes possible. The other lets you combine those directions; a translucent door shows where you can arrive. Release a handle and take it again. The rule remains in the mechanism.

For the guided door, the code projects your displacement onto the currently permitted direction:

```gdscript
var t = (knob_pos - start).dot(phase1_dir)
knob_pos = start + phase1_dir * t
```

The full implementation also clamps the distance. Your hand can propose another path, but the handle retains only the part its current axis admits.

Up followed by sideways reaches the same position as sideways followed by up. Translation itself does not impose this order. The first mechanism does. The second gives both freedoms together. A destination can be shared by journeys with very different permissions.

<!-- @ -->

The torus beside the course already turns while its cylinder rises and falls. It offers a glimpse of the next question. Our carriers have kept their facing throughout; this neighbouring object combines the operations. Keep the difference between travelling and facing in mind. In Trans_Rotation, the turn itself will become the question.
