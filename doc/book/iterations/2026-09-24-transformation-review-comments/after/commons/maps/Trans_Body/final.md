The corridor narrows, and then it stops.

<!-- @approach_wall -->

A wall of upright slats stands across the way. There is no handle, no plate, no light that turns green. Walk at it.

The slats near you turn out of the plane, and the ones further off do not. The opening centres on where you stand rather than on the wall. Step sideways along the face and the opening comes with you; step back and it closes.

The distance part of the rule can be written simply, for a visitor within reach:

```gdscript
var t: float = absf(slat_x - visitor_x) / aperture_m
var d: float = absf(visitor_z) / reach_m
var openness: float = (1.0 - t) * (1.0 - d)
```

Two distances, multiplied: how far the slat is from you along the wall, and how far you are from the wall. The program smooths the response and opens neighbouring slats far enough for a body to pass. The slat does not know whether you meant to come. Its mechanism holds which side you approached from while it swings, then settles back. Even this small response needs a little state.

A door gives you a place to approach. This wall lets the place of approach move with you. Someone has still chosen how close counts as close, how wide the opening should become, and which collision bodies it will notice. The invitation has dimensions. The slats remain attached to their hinges, the material is the same, nothing has been consumed. Your position changes what that arrangement allows.

Look back while you are still close: a slat may stay open for you. Continue into the space beyond its reach and wait for it to close. Crossing the plane and leaving the wall's attention are different distances.

<!-- @carve_grid -->

The next throat holds a low block of small cubes, about 1.3 metres high. You can look over it. The lattice reaches across the way, but it does not enclose your head.

Press into it. The cubes your body touches stop existing.

They are removed. You advance a shell at a time, leaving an open-topped cut through the block. For a standing visitor this is closer to a trench than a tunnel. Your view was above it before your legs had a way through.

This extra reach has a name:

```gdscript
@export var bite_m: float = 0.16
```

`bite_m` gives the collision shape another sixteen centimetres of reach. The physics engine stops your body at the solid cells; this margin lets the deletion reach beyond that stop. With cells spaced thirty-four centimetres apart, it clears roughly one layer at a time. You press forward, the surface gives, and there is another surface.

Your movement supplies the input, but the operation on the lattice is deletion. Translation alone would leave every cube somewhere. Here the count changes. The whole behaviour also hangs on a tolerance: the difference between a body being stopped and a position allowed to reach beyond it.

The cut stays. Not only while this room is loaded: it is kept, and the next arrival finds it already made. Look at its stepped sides. It records where the lattice met the collision shape used for your body, expanded by that small margin. The cubes can only retain the contact at their own resolution. Some of you passed above the entire record.

![The low cube lattice before a passage and the open-topped cut left by a body, photographed from the same elevated viewpoint.](/book-review/doc/book/iterations/2026-09-23-body-what-remains/the-cut-remains.png)

*The body has left the second view. These elevated views show the missing cells; the opening was made by walking through the block.*

What is kept is not what you intended. You meant to cross; the trench is the residue of the margin that let you. Every restraint in this museum has an edge of that kind, and almost all of them are swept up behind you. This one is not.

Somebody following behind you will find the cut already made. Will their body fit the passage yours left?

<!-- @approach_scale -->

Nine blocks. At rest, the gap between neighbours is thirty-five centimetres.

Walk in anyway.

```gdscript
var t: float = clampf(sqrt(_dist2[i]) / reach_m, 0.0, 1.0)
t = t * t * (3.0 - 2.0 * t)
return lerpf(min_scale, 1.0, t)
```

Each block reads its own distance to the nearest body and takes a size from it. Close, it goes to about a third; far, it is whole. Each block keeps its place in the horizontal grid. Its visible mesh and collision box shrink together; their centres lower to keep the bottom face on the floor. Nothing is deleted. The gap changes because your distance has become a size.

So the gap you walk through was not made by clearing anything. It was made by measuring.

Look behind you near the last row. Some blocks may still be small: you have passed them, but they still measure you. Walk on towards the far end of the room. Once you are outside their reach, the field fills out again. The floor caption beyond the last row asks you to step clear; it cannot declare that you already have.

In the next room, another block will grow across your route. There, a clock supplies the factor. It will grow if you approach, if you wait, if you turn away. Here you can ask for room by moving closer. There you must learn a rhythm that does not read you.

<!-- @ -->

The cube carried you; the bottle changed the room around you. Here your approach has turned slats, removed cells and reduced blocks. Two boundaries return; one keeps the cut. Walking felt like walking, while the room was doing different kinds of work.

What the room offers depends on the body its code can recognise. The next room continues changing even when you stand still.
