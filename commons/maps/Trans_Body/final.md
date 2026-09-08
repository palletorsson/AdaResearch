The corridor narrows, and then it stops.

<!-- @approach_wall -->

A wall of upright slats stands across the way. There is no handle, no plate, no light that turns green. Walk at it.

The slats near you turn out of the plane, and the ones further off do not. What opens is about as wide as you are, and it is centred on you rather than on the wall. Step sideways along the face and the opening comes with you; step back and it closes.

The rule each slat follows is short:

```gdscript
var t: float = absf(slat_x - visitor_x) / aperture_m
var d: float = absf(visitor_z) / reach_m
var openness: float = (1.0 - t) * (1.0 - d)
```

Two distances, multiplied. The first is how far this slat is from you along the wall; the second is how far you are from the wall. Neither is a decision. A slat has no way of knowing whether you meant to come, and no way of remembering that you did.

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

That is a strange thing to find at the centre of an artifact about translation: the whole behaviour hangs on a tolerance, and the tolerance is not in the mathematics of translation at all. It is in the difference between a body and a position.

The tunnel stays. Nothing here regrows, because the corridor is the only record that you came this way, and it is not a record of your route — a route is a line. It is a record of your volume.

Somebody will walk this hall after you and find the tunnel already cut. They will not be able to tell whether it was made by a person or built that way.

<!-- @approach_scale -->

Nine blocks, set closer together than a pair of shoulders. At rest the gap between neighbours is thirty-five centimetres, which is not "tight". It is shut.

Walk in anyway.

```gdscript
factor = lerp(min_scale, 1.0, clamp(dist / reach_m, 0.0, 1.0))
```

Each block reads its own distance to the nearest body and takes a size from it. Close, it goes to about a third; far, it is whole. Nothing is moved and nothing is removed — each block keeps its centre and its place in the grid, and only its extent is a function of you.

So the gap you walk through was not made by clearing anything. It was made by measuring.

Look behind you. They have grown back, and the field is shut again, and the way you came is not there any more.

This is the same arithmetic as the block in the pit two rooms on, which grows as you approach and pushes you off the edge. One factor, running the other way. Neither of them is doing anything to you; both are reading you, and the difference between hospitality and threat is a sign.

<!-- @ -->

Three thresholds and not one of them has a mechanism you could point at — no trigger plate, no switch, no moment where the room decided. The wall is still a wall, the blocks still have their places, and only the lattice is permanently different, because only the lattice was allowed to keep what happened.

In every other room in this chapter you have watched a cube be moved, turned or grown. Here you have done all three, to a room, and none of them felt like an operation. Walking felt like walking.

The next room does the same reading and comes to a different conclusion about you.
