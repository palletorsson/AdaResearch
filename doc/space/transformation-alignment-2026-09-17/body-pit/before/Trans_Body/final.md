The corridor narrows, and then it stops.

<!-- @approach_wall -->

A wall of upright slats stands across the way. There is no handle, no plate, no light that turns green. Walk at it.

The slats near you turn out of the plane, and the ones further off do not. What opens is about as wide as you are, and it is centred on you rather than on the wall. Step sideways along the face and the opening comes with you; step back and it closes.

The distance part of the rule can be written simply, for a visitor within reach:

```gdscript
var t: float = absf(slat_x - visitor_x) / aperture_m
var d: float = absf(visitor_z) / reach_m
var openness: float = (1.0 - t) * (1.0 - d)
```

Two distances, multiplied. The implementation smooths this value and opens a neighbouring run of slats far enough for a body to pass. The first is how far this slat is from you along the wall; the second is how far you are from the wall. Neither is a decision. A slat has no way of knowing whether you meant to come, and no way of remembering that you did.

A door decides where you go. It was placed by someone who had already worked out where people would want to be, and it opens the same way for everyone who arrives. This wall has not worked anything out. It is still a wall: every slat is where it was, the material is the same, nothing has been consumed. Only your standing here is different, and that turns out to be enough.

Look back at it from the far side. It is shut again.

<!-- @carve_grid -->

The next throat is filled to the walls with small cubes. You can see through the gaps between them and there is nothing to see except more of them.

Press into it. The cubes your body touches stop existing.

Not pushed aside, not folded away: removed, and they do not come back. You advance a shell at a time, and behind you is a tunnel with your shoulders in it.

The test is one line, and the interesting part is a number:

```gdscript
@export var bite_m: float = 0.16
```

The lattice is solid and so are you, so the physics engine stops you at the surface and your collider never actually overlaps a cube. A lattice that deleted only what it strictly intersected would delete nothing, for ever, and would look exactly like this one. `bite_m` is the margin by which you are allowed to reach past the place you were stopped. At zero the room is a wall. At 0.16 against a 0.34 cell it clears about one shell per press.

Your movement supplies the input, but the operation on the lattice is deletion. Translation alone would leave every cube somewhere. Here the count changes. The whole behaviour also hangs on a tolerance: the difference between a body being stopped and a position allowed to reach beyond it.

The tunnel stays. Nothing here regrows, because the corridor is the only record that you came this way, and it is not a record of your route — a route is a line. It is a record of your volume.

Somebody following behind you will find the tunnel already cut. They will not be able to tell whether it was made by a person or built that way.

<!-- @approach_scale -->

Nine blocks, set closer together than a pair of shoulders. At rest the gap between neighbours is thirty-five centimetres, which is not "tight". It is shut.

Walk in anyway.

```gdscript
var t: float = clampf(sqrt(_dist2[i]) / reach_m, 0.0, 1.0)
t = t * t * (3.0 - 2.0 * t)
return lerpf(min_scale, 1.0, t)
```

Each block reads its own distance to the nearest body and takes a size from it. Close, it goes to about a third; far, it is whole. Each block keeps its place in the horizontal grid. Its visible mesh and collision box shrink together; their centres lower to keep the bottom face on the floor. Nothing is deleted. The gap changes because your distance has become a size.

So the gap you walk through was not made by clearing anything. It was made by measuring.

Look behind you. They have grown back, and the field is shut again, and the way you came is not there any more.

In the pit one room on, another block will grow across your route. There, a clock supplies the factor. It will grow if you approach, if you wait, if you turn away. Here you can ask for room by moving closer. There you must learn a rhythm that does not read you.

<!-- @ -->

Three thresholds and not one of them has a mechanism you could point at — no trigger plate, no switch, no moment where the room decided. The wall is still a wall, the blocks still have their places, and only the lattice is permanently different, because only the lattice was allowed to keep what happened.

In every other room in this chapter you have watched a cube be moved, turned or grown. Here your approach has turned slats, removed cells and reduced blocks. Two boundaries return; one keeps the cut. Walking felt like walking, while the room was doing different kinds of work.

The next room continues changing even when you stand still.
