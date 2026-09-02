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

A cloth of ten by eight points on a bench, with a dial on the panel reading nudged, worked, pressed or held. Those are one, four, eight and twelve constraint passes per frame, and the bench ships on four. Each pass walks the springs in order and moves the two ends of each a little closer to its rest length. Turn the dial up and the cloth hangs tauter, because more of the error got worked out before the frame ended.

Two things about that are worth more than the dial. The first is that a pass never finishes the job; it takes half the error off each spring and moves on. The second is stranger, and you can see it if you watch one bad fold rather than the whole sheet: going from one pass to four can make the single worst spring in the cloth *worse* while the cloth as a whole gets better, because fixing a spring pulls its neighbour out of true. Relaxation improves the total and is under no obligation to improve any particular part of it.

<!-- @mass_spring_bench -->

The lattice version, about sixty centimetres of jelly on a pillar: a four by three by four grid of masses with a spring on every edge, stiffness a little over half, given eighty steps before you ever see it. No shape was authored. There is a grid, a rest length per spring and gravity, and the slumped block on the bench is what those three agree on.

<!-- @frozen_glass_vessel -->

And here is where it stops being a demonstration. A sphere of glass, fourteen rings by twenty-two segments, pinned around the top eighth as if on a blowpipe, given a pressure pulse of a fifth and then released into gravity for a fixed number of steps. The simulation runs once, when the room loads, and then it stops: the pose it happens to be in at that moment is the vessel, and you can walk inside it.

Change the stiffness and you get a different vessel. Tilt the gravity and you get a lopsided one. Stop the clock earlier and you get a bottle instead of a bowl. The clock is part of the genome here, which is a real claim about glass and about D'Arcy Thompson's whole argument: the form is not a design, it is a record of the forces that acted and how long they were allowed to act.

<!-- @science_screen -->

The screen sweeps the room once a second and flattens what it finds. What it cannot show is the only thing this room is about, which is duration: the vessel it draws is a still, and the vessel is a still, and neither of them contains the eighty steps that made it.

<!-- @ -->

## A fossil of forces

The vessel in this room was never designed and it is not a simulation you are watching. It is the frozen output of one, kept because it was interesting, in the same way a fossil is a shape that some process left behind and then stopped.

That is the chapter's argument at its most literal. Nobody drew the amphora. Somebody chose a stiffness, a pin ring, a pulse and a number of steps, and the amphora is what those choose.

Next: forms that are not settling at all, but held, by forces that exactly cancel.
