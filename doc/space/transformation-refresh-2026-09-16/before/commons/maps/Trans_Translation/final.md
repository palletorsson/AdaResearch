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

Each carrier's top is placed at its departure deck, with its centre half a metre below. The upper lift socket needs its own starting height: the empty cell alone cannot tell us whether a journey begins above or below. The destination must meet a landing as well. Coordinates describe the ride; their agreement with the surrounding floor makes it usable.

<!-- @pick_up_cube -->

The small pickups have been waiting along these journeys. They rise and fall without turning. Their small vertical loop continues as the carrier brings you into contact with them, and each collected cube disappears with a sound.

You can return along the same displacement. The pickups already taken do not return with you.

The transport does not collect them at a distance. It adds its own movement to the detected rider:

```gdscript
var movement_delta = global_position - previous_position
carried_player.global_position += movement_delta
```

A pickup's detection area then recognises that body and calls `collect()`. Two small systems meet: one carries, the other notices contact. The empty place left behind belongs to their encounter.

<!-- @ -->

At the last crossing, the waiting cubes run diagonally over the pit. Watch an edge of the carrier as you travel. It does not turn.

This direction changes x and z together. The destination lies eight metres across and eight metres further into the hall. Both coordinates change during the same journey. We have combined directions without adding rotation.

Thirteen pickups mark one possible passage through seven rides. Their positions make some encounters easy and leave other parts of the arena untouched. Another arrangement could ask for another journey using exactly the same operations.

Step onto the final terrace. Keep the difference between travelling and facing in mind. In Trans_Rotation, the turn itself will become the question.
