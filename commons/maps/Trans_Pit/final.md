The neutrality of a transformation is only available from outside the space it acts on. Inside it, move, turn and grow are three ways of being removed, and the pit is the constant.

Three rooms in a row, one per transformation, and fire below each. Everything the chapter did to objects, this hall does to you. A block translates, and you are pushed. A wall rotates, and you are swept. A block scales, and you are squeezed off the floor. The pit is the same in all three. Only the geometry of your removal changes.

```gdscript
func _physics_process(delta: float) -> void:
    phase = fmod(phase + delta * speed / distance, 2.0)
    var t: float = phase if phase < 1.0 else 2.0 - phase  # triangle wave
    global_position = start_position + axis * distance * t
```

A number that climbs from zero to two and wraps, folded into a wave that goes out and comes back. That is all a pusher is: a translation on a timer, going three metres out and three back, forever. The tutorial's grower climbs once and stops; the blocks in the room breathe.

## Translation, from inside

<!-- @pusher_block -->

Three stone blocks in the first corridor, each shuttling along the depth of the room, three metres out and three metres back, at three different speeds with three different pauses. From outside, a pusher is the mildest thing in the chapter: position changes and nothing else does. From inside, standing where it wants to be, it is a wall that arrives. There are fire pits either side of the lane. A translation does not push you into them. It moves, you are in the way, and the difference between those two sentences is where you are standing.

<!-- @ -->

## Rotation, from inside

The middle room has revolving walls: two of them, a quarter turn at a time about a vertical axis, one four cells long and one three, and fire around the edges. A rotation has a pivot, and from outside you would say the wall goes nowhere, it only turns. From inside you learn the other half of the fact: a point at the end of a turning wall moves fastest of all, and the edge of the room is where the sweep arrives. Direction matters again, and now it matters to your feet.

## Scale, from inside

<!-- @grower_block -->

The last room has three blocks that breathe. Each swells from a third of a metre to three and a half across and shrinks back, a full breath every three seconds or so, and it never stops. Small is safe and big is danger, and the colour tells you which. Scale kept its promise in the last hall: the block's proportions never change. What changes is your footprint, which is the floor minus the block, and the floor minus a swelling block is a place to stand that keeps disappearing. Fire pits on both sides. A block that only grew has removed you.

<!-- @ -->

## The constant

The pit does not care which move sent you into it. Fire is the same fire under all three rooms, and the reload is the same reload. What the hall proves is that a transformation's neutrality is a fact about the outside view. The matrices in the first hall were true: translation preserved everything but position, rotation everything but direction, scale everything but size. They were true of the blocks and the walls. You were not in the matrix. You were in the room, and from inside the room every one of those preservations arrives as a body coming toward you.

That is the end of the chapter, and it is the chapter turned round. Three ways of closing a gap, seen from the gap.
