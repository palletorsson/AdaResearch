# What a budget leaves

A released mesh settles into a shape nobody specified, and what stands afterwards is a fossil of the forces that made it.

The last hall let us draw a sag and evaluate a formula. Here a connected shape keeps a history of being changed. A frame budget allows only so many corrections: nudge the points, move to the next constraint, begin another pass. The cloth continues; the lattice and the vessel keep the pose reached after a chosen number of steps. Their stopping times were supplied with their rules.

## Nudged, not solved

<!-- @verlet_workbench -->

A magenta cloth of ten by eight points hanging from its two top corners. It receives sixty settling steps before you arrive, then continues in fixed one-sixtieth-second steps. Watch it before touching the controls. A changing sideways gust keeps disturbing it; motion here does not mean that a single settling process has failed to finish.

The panel now offers PASSES, RESET and WIND. PASSES cycles through nudged, worked, pressed and held: one, four, eight and twelve constraint passes per step. Each choice restarts the same grid and its sixty preliminary steps. Switch WIND off to compare the corrections under gravity alone. The bench begins at four passes. Press PASSES through eight and twelve until the readout says nudged: one pass. The next press returns to worked: four passes. Does the cloth hold the same outline? RESET lets you return to the beginning without changing the chosen settings.

```gdscript
var pos: Vector3 = positions[i]
var prev: Vector3 = prev_positions[i]
var vel: Vector3 = (pos - prev) * damping
var new_pos: Vector3 = pos + vel + gravity * dt * dt
prev_positions[i] = pos
positions[i] = new_pos
```

There is no separately stored velocity in that code. In the position update used by Loup Verlet in 1967, where a point is going is implied by where it just was: keep two positions, and their difference carries the motion.[^verlet] The temporary variable called `vel` holds that difference after damping. A point at rest, released, falls gravity times a step squared on its first update. At sixty steps a second, this bench's gravity gives less than a millimetre. The constraints then correct those proposed positions.

Now read MEAN and WORST. They report spring-length errors relative to the lengths we asked the cloth to keep. A pass corrects each spring in turn, moving a free endpoint by half the current error scaled by stiffness; a correction can disturb a neighbouring spring. More passes give those relations another chance to agree.

With WIND off, compare the readings as the step count reaches 420—about six seconds after each restart, which already includes sixty preliminary steps. At one pass, the mean absolute error is about 1.4% and the worst spring error about 34%. At four passes, they fall to about 0.36% and 8.9%. The average has become small while one local relation is still far from its request. Look between those two numbers. What would we overlook if the bench reported only the reassuring one?

<!-- @mass_spring_bench -->

The lattice version stands on a bench: forty-eight pink masses, a hundred and seventy-nine cyan wires, rocking eight degrees either side on an eighteen-second cycle. Compare its movement with the cloth. Are the relations between its points still changing, or is one retained form being turned?

All eighty of its solver steps ran before the room finished loading. The rocking carries a frozen result: a grid with a random hundredth-of-a-metre disturbance per particle, rest lengths, gravity and a fixed time to act. Nobody placed each vertex of the final slump by hand. Somebody did choose the conditions from which it came.

<!-- @frozen_glass_vessel -->

And here is where it stops being a demonstration. A sphere of glass, fifteen rings by twenty-two segments, three hundred and thirty particles, of which the eighty-eight above the top eighth are pinned as if gripped by a blowpipe. Every free vertex is pushed out by a fifth as an initial expansion. Spring rest lengths are made from that expanded shape, then the whole thing is dropped into gravity for two hundred steps of the same solver the cloth is running.

It runs once, when the room loads, and stops. The pose it happens to be in at that moment is the vessel. The glass lets you see an inside that its closed collision surface keeps your moving body outside. Transparency offers a view, not an entrance. The falling has finished; the boundary it left can still meet you.

![The frozen glass vessel with the cloth behind it in the museum](/book-review/doc/book/figures/formfinding/glass-keeps-a-boundary-museum.png)

*The cloth keeps changing. The vessel keeps a moment, and the surface of that moment keeps a boundary.*

In the source, changing stiffness, gravity or the number of settling steps makes other vessels possible; those controls are not on this exhibit. A different duration keeps a different moment of the process. The clock is part of the genome here. The form records the conditions that acted on it and how long they were allowed to act.

<!-- @science_screen -->

A screen, and the thing this room is about is the one thing no still image can hold. Every shape here is a duration: eighty steps, two hundred steps, a cloth still taking another step. A picture of a vessel contains none of the falling that made it, which is exactly what a fossil is and exactly what the vessel is.

<!-- @ -->

## A fossil of forces

The vessel in this room was designed through conditions rather than by placing its final vertices. What you see is the frozen output of a simulation, kept because it was interesting, in the same way a fossil is a shape that some process left behind and then stopped.

That is the chapter's argument at its most literal. Nobody drew the amphora. Somebody chose a stiffness, a pin ring, a pulse and a number of steps, and the amphora is what those choices left.

Next: a balance written into the relations between parts. How can we tell an encoded equilibrium from a form that has physically found one?

[^verlet]: Loup Verlet, [“Computer Experiments on Classical Fluids. I”](https://journals.aps.org/pr/abstract/10.1103/PhysRev.159.98) (1967). The bench adds distance-constraint corrections to its position update; those corrections and their pass budget are part of this implementation.
