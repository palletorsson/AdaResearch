A released mesh settles into a shape nobody specified, and what stands afterwards is a fossil of the forces that made it.

The chain in the last hall was already right. A machine cannot do that. It has a frame to get through and a mesh of hundreds of points, so it does the only thing available: nudge everything a little toward where it should be, and do it again next frame. Nothing here is ever solved. It is relaxed, pass after pass, and it stops when it is close enough.

```gdscript
var pos: Vector3 = positions[i]
var prev: Vector3 = prev_positions[i]
var vel: Vector3 = (pos - prev) * damping
var new_pos: Vector3 = pos + vel + gravity * dt * dt
prev_positions[i] = pos
positions[i] = new_pos
```

There is no velocity in that code. Loup Verlet's idea, from 1967, is that you do not need one: where a point is going is implied by where it just was, so keep two positions and the difference between them is the motion. A point at rest, released, falls exactly gravity times a frame squared on its first step, which at sixty frames a second is under three millimetres.

## Nudged, not solved

<!-- @verlet_workbench -->

A magenta cloth of ten by eight points hanging from its two top corners, and this is the only thing in the chapter that is still solving while you watch it: sixty steps before you arrive, and then one more integration every frame you are in the room.

On the panel below it there is a dial reading nudged, worked, pressed or held. Those are one, four, eight and twelve constraint passes per frame, and the bench runs on four. You cannot turn it. It is a cylinder with a lit notch that rotates itself on a slow sine, and there is no collider, no grab and no input handler anywhere in the file. The setting is real and the control is furniture.

Two things about the number are worth more than the dial. The first is that a pass never finishes the job; it takes half the error off each spring and moves on to the next. The second is stranger, and it is measurable: going from one pass to four makes the whole cloth tauter and makes the single worst spring in it *worse*, because a sweep fixes each spring in turn and every fixed spring pulls its neighbour out of true. Relaxation improves the total and is under no obligation to improve any particular part of it.

<!-- @mass_spring_bench -->

The lattice version, and it is over your head: it shares a cell with the spawn point, so the grid bumped it up a level and its slab hangs a metre above where you land. Forty-eight pink masses, a hundred and seventy-nine cyan wires, rocking eight degrees either side on an eighteen-second cycle.

It is not settling. All eighty of its solver steps ran before the room finished loading, and what sways above you is the frozen result, tilted by a random hundredth of a metre per particle and then baked. No shape was authored: there is a grid, a rest length per spring and gravity, and the slumped block is what those three agreed on, once, in a moment nobody saw.

<!-- @frozen_glass_vessel -->

And here is where it stops being a demonstration. A sphere of glass, fifteen rings by twenty-two segments, three hundred and thirty particles, of which the eighty-eight above the top eighth are pinned as if gripped by a blowpipe. Every free vertex is pushed out by a fifth, a pressure pulse, and then the whole thing is dropped into gravity for two hundred steps of the same solver the cloth is running.

It runs once, when the room loads, and stops. The pose it happens to be in at that moment is the vessel. You cannot go inside it, whatever the label says: it has no collider at all, and you will walk through the glass.

Change the stiffness and you get a different vessel. Tilt the gravity and you get a lopsided one. Stop the clock earlier and you get a bottle instead of a bowl. The clock is part of the genome here, which is a real claim about glass and about D'Arcy Thompson's whole argument: the form is not a design, it is a record of the forces that acted and how long they were allowed to act.

<!-- @science_screen -->

A screen, and the thing this room is about is the one thing no screen can hold. Every shape here is a duration: eighty steps, two hundred steps, one integration per frame. A picture of a vessel contains none of the falling that made it, which is exactly what a fossil is and exactly what the vessel is.

<!-- @ -->

## A fossil of forces

The vessel in this room was never designed and it is not a simulation you are watching. It is the frozen output of one, kept because it was interesting, in the same way a fossil is a shape that some process left behind and then stopped.

That is the chapter's argument at its most literal. Nobody drew the amphora. Somebody chose a stiffness, a pin ring, a pulse and a number of steps, and the amphora is what those choose.

Next: forms that are not settling at all, but held, by forces that exactly cancel.
