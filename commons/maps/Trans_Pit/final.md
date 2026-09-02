The neutrality of a transformation is only available from outside the space it acts on. Inside it, move and turn are ways of being removed, and the pit is the constant.

Three rooms in a row, one per transformation, and fire in all of them. Everything the chapter did to objects, this hall does to you. A block translates, and it crosses the ground you are standing on. A slab turns, and the way through is somewhere else.

```gdscript
func _physics_process(delta: float) -> void:
    phase = fmod(phase + delta * speed / distance, 2.0)
    var t: float = phase if phase < 1.0 else 2.0 - phase  # triangle wave
    global_position = start_position + axis * distance * t
```

A number that climbs from zero to two and wraps, folded into a wave that goes out and comes back. That is all a pusher is: a translation on a timer, going three metres out and three back, forever.

## Translation, from inside

<!-- @pusher_block -->

Three red blocks in the first corridor, each with an arrow on its face saying where it will go. Each crosses three metres of the corridor in about half a second, straight over a fire pit, waits a second, and comes back. They differ only in how fast. From outside, a pusher is the mildest thing in the chapter: position changes and nothing else does. From inside, standing where it wants to be, it is a wall that arrives. The pit is two cells along the block's line, and the block crosses it. Not every hole in this corridor burns, and the ones that do not are the same distance down.

<!-- @ -->

## Rotation, from inside

The middle room has two turning slabs, orange and wireframed, each a little over two metres across and knee high. They stand in the two clear channels between three blocks of fire. Each takes two seconds to make a quarter turn about a vertical axis and then stops: one waits four seconds before the next quarter, the other three. A rotation has a pivot, and from outside you would say the slab goes nowhere, it only turns. From inside you learn the other half of the fact: a turn changes what the same slab occupies. Side on it nearly closes the channel. End on it leaves a metre either side. Nothing about the slab changed, and the gap did.

## Scale, from inside

<!-- @grower_block -->

The last room has three cubes in a row, a metre each, and they do not move. Their tokens ask for a swelling that runs from a third of a metre to three and a half, and the grid does not pass those two words through, so nothing arrives and nothing grows. Scale is the one transformation this hall never performs on you, and you will walk past it without noticing, which is very nearly what scale does anyway.

<!-- @ -->

## The constant

The pit does not care which move sent you into it. Fire is the same fire under all three rooms, and the reload is the same reload. The matrices in the first hall were true: translation preserved everything but position, rotation everything but direction, scale everything but size. They were true of the blocks and the slabs. You were not in the matrix. You were in the room, and from inside the room every one of those preservations arrives as a body coming toward you.

That is the end of the chapter, and it is the chapter turned round. Three ways of closing a gap, seen from the gap. The teleporter is at the far end, past the last block. The next chapter is colour, which moves nothing at all.
