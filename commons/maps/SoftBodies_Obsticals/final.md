When soft meets hard, collision is not an instant but a negotiation that unfolds over time.

A rigid body's collision is a moment: it arrives, a number is computed, it leaves changed. A soft body has no such moment. It arrives, and then for the next second the news of the arrival travels through it, spring by spring, and what happens at the far side depends on everything in between. This room is twenty metres square and mostly empty so that you can watch that take its time.

```gdscript
if p.y < floor_h:
    positions[i].y = floor_h            # the contact is a constraint, not an impulse
```

The whole of collision, for a soft body, is that: a point that has gone somewhere it should not be is put back, and the springs attached to it spend the following frames arguing about what that means for everyone else.

## The rack

<!-- @softbody_gallery_part2 -->

The south half of the room is a drop rack, twelve cells of magenta wireframe with soft spheres falling onto them every couple of seconds, six columns of different stiffness. Stand at the end of the row and look along it, because the row is the experiment: the same fall, the same frame, and a different material each time.

The soft ones spread across the wire and take a full second to decide what shape they are. The stiff ones bounce and keep their corners. Somewhere in the middle a sphere lands, holds an obviously wrong shape for a moment, and then remembers. That interval is what the room is about, and it exists only because the material has to pass the news along.

One warning: pressing the jump key reloads this map. The rack listens for it.

<!-- @breathing_room -->

Two grey slabs standing across the north corner, four metres high and seven long, with a five-metre gap between them. They are named for the thing they do not do. The scene loads a version of the script with no update loop in it at all, so there is no breathing, no expansion and no contraction: two walls, still, forever. Its twin slab stands outside the room, behind the north wall.

Take it as the room's honest failure. A corridor whose walls close on you would have been the hard case of this argument, where the negotiation has no way out. What is here instead is the geometry of that idea with the time taken out.

<!-- @flagdancer -->

A rainbow flag rippling along the north wall, its bottom two metres below the floor and two metres of its width inside the wall. It looks like the softest thing in the room and it is the only one with no physics whatsoever: seventeen bones driven by sine waves, no cloth solver, no forces, nothing to collide with. It cannot be touched and it does not respond.

It is worth standing in front of for exactly that reason. It is what soft looks like when it is animated rather than simulated, and next to the rack, which is genuinely negotiating, the difference is visible without being told. One is obeying a curve. The other is working something out.

<!-- @pick_up_cube -->

A black cube in orange wireframe turning and bobbing beside the slabs. Walk into it and it is gone.

<!-- @grab_long_stick -->

A rod on the floor by the south wall, and the only object here a hand can take. Carry it into the rack and you become the hard thing in the encounter. That is the room's best use of a minute: hold something rigid, push it into something soft, and watch how long the answer takes to arrive.

<!-- @ -->

## Resistance is morphology

An obstacle does not stop a soft body. It reshapes it, and the shape it leaves is a record of the meeting: where the contact was, how stiff both parties were, how long they were in touch.

That is why the negotiation matters more than the moment. A rigid collision destroys its own evidence, resolving into two new velocities and nothing else. A soft collision leaves the encounter written into the object, for as long as the springs take to argue it away, and sometimes longer.

The chapter has now had three answers to who decides the form. The material alone. The field it hangs in. And here, the thing it runs into. The next answer is the one that outlasts all of them: what happens when the record does not argue itself away, and the encounter stays.

Next: a skeleton that kept the shape of the water it grew in.
