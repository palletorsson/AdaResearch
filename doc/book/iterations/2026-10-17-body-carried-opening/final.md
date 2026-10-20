# The Body

The corridor narrows, and then it stops.

<!-- @approach_wall -->

A wall of upright slats stands across the way. There is no handle. Walk towards it.

The slats nearest you turn. What opens is about as wide as you are, and it is centred on you rather than on the wall. Step sideways along the wall and the opening follows; step back and it closes. A doorway has come to meet you.

Within reach, the distance part of the rule can be written:

```gdscript
var t: float = absf(slat_x - visitor_x) / aperture_m
var d: float = absf(visitor_z) / reach_m
var openness: float = (1.0 - t) * (1.0 - d)
```

One distance runs along the wall, from the slat to you. The other runs out from the wall to where you stand. Each is divided by its chosen reach, making a fraction. Subtracting the fractions from one gives more weight to closeness; multiplying the results lets both distances shape the opening. The program also smooths the response and opens neighbouring slats far enough for a body to pass.

Neither is a decision. A slat has no way of knowing whether you meant to come, and no way of remembering that you did.

Someone has chosen that width, that reach, and which bodies the wall will notice. The invitation has dimensions. Yet you can move its centre along the wall. Your position changes what this arrangement allows.

A door decides where you go. It was placed by someone who had already worked out where people would want to be, and it opens the same way for everyone who arrives. This wall has not worked anything out. It is still a wall: every slat is where it was, the material is the same, nothing has been consumed. Only your standing here is different, and that turns out to be enough.

Pass through and look back. While you are still close, a slat may remain open for you. Go farther and wait. It settles into the wall again. You have crossed the boundary before you have left its attention.

<!-- @carve_grid -->

The next narrow passage holds a block of small cubes, about 1.3 metres high. You can see over it. Your legs still need a way through.

Press forward. A layer gives way, and another waits behind it. The missing cubes leave an open-topped trench. Your eyes had crossed this space before your body could.

Physics stops your body at the solid cells. A lattice that deleted only what it strictly intersected would delete nothing, for ever, and would look exactly like this one. To let the cut begin, the program gives its removal test a little extra reach:

```gdscript
@export var bite_m: float = 0.16
```

Sixteen centimetres beyond the collision shape used for your body. With cells spaced thirty-four centimetres apart, that margin clears roughly one layer at a time. At zero the room is a wall. The next step becomes possible because something has been removed.

That is a strange thing to find at the centre of an artifact about translation: the whole behaviour hangs on a tolerance, and the tolerance is not in the mathematics of translation at all. It is in the difference between a body and a position.

Moving a cube would leave it somewhere. Here, the count changes. The lattice loses cells as you advance. Not pushed aside, not folded away: removed, and they do not come back.

Turn back. The cut stays when you walk away. A return during the same session can reopen the cells kept in memory. Look along the stepped sides: they record where the lattice met your body's collision shape, widened by that small margin. Whole cubes are either present or absent. The record can have no finer edge than the cells that make it.

Some of you passed above the entire record.

![The low cube lattice before a passage and the open-topped cut left by a body, photographed from the same elevated viewpoint.](/book-images/iterations/2026-09-23-body-what-remains/the-cut-remains.png)

*The body has left the second view. These elevated views show the missing cells; the opening was made by walking through the block.*

The cut keeps the route without keeping your reason for taking it. Its width includes an allowance you may never have noticed. Somebody following would meet an opening already shaped by another passage. Would their body fit, or would they need to widen it?

<!-- @approach_scale -->

Nine blocks stand ahead. At rest the gap between neighbours is thirty-five centimetres, which is not "tight". It is shut.

Move closer. The nearest blocks shrink. Continue between them: the opening travels with you.

```gdscript
var t: float = clampf(sqrt(_dist2[i]) / reach_m, 0.0, 1.0)
t = t * t * (3.0 - 2.0 * t)
return lerpf(min_scale, 1.0, t)
```

Each block compares its distance from the nearest body with its sensing reach. The first line turns that comparison into a fraction between zero and one; the second smooths it. `lerpf` uses it to choose a size between about a third and full scale. The visible block and its collision box shrink together, lowering as they do so to keep their feet on the floor. Their places in the horizontal grid stay fixed.

All nine blocks are still there. Your distance has become their size. So the gap you walk through was not made by clearing anything. It was made by measuring.

Look behind you near the last row. Some blocks may still be small. Take a few more steps towards the far end and watch them fill out. You can be through the gap and still be holding it open.

<!-- @ -->

Three thresholds and not one of them has a mechanism you could point at — no trigger plate, no switch, no moment where the room decided. Two boundaries return; one keeps the cut. Looking back finds a wall, a trench, a field of blocks. Each has answered the same approach differently.

In every other room in this chapter you have watched a cube be moved, turned or grown. Here you have done all three, to a room, and none of them felt like an operation. Walking felt like walking.

In the next room, growing blocks follow a clock. Coming closer will no longer ask them to make room. You will have to find your moment.
