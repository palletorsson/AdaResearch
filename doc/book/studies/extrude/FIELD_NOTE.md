# Field note: one walk, four tapers

1 October 2026. Observer: Claude, the session that built this kit, working from the repository and from stills. Nothing here was walked by a body in a headset, and no person looked at the stills to say which two look alike.

This is the kit's own note, in the form of [the decision and the field note](../../course/opening/FIELD_NOTE.md). It is an example of the form. Your note will have another decision in it.

## The note

```
Question:        Which two of the four solids look most alike, and where does
                 a marble rest on each?
Baseline:        extrude.tscn of this kit: the shipped walk of eight corners,
                 height 0.8 m, taper 1.0, a prism.
Intervention:    one field, taper: 1.0, 0.6, 0.2, 0.0. Walk and height held.
Prediction:      the course outline's, written before any run (quoted below).
Observation:     0.2 and 0.0 are the closest pair from three standpoints.
                 The marble rests at 0.90 m on all four when dropped over the
                 centre, on the pyramid's point too. Details below.
Another cause:   the spacing of the four values; the standpoint; the shading
                 of a leaning wall; the threshold of the measure; the exact
                 place of the drop. Three were tried.
Decision:        follow once, then settle; one thing left open.
Reason:          below.
Run it again:    the two commands at the end.
```

## The apparatus

- **Scene.** `extrude.tscn`. The solid is made by `extrude()` in `extrude.gd` from a list of eight corners.
- **Engine.** Godot 4.6.stable.official.89cea1439, Windows, an NVIDIA GeForce RTX 3070, the Compatibility renderer.
- **What I could see.** Stills of 960 by 720 pixels in the plain studio, one solid alone, its shadow off; the eye 2.5 m from the middle, from the side and from straight above, and at (1.9, 1.5, 2.1) over a corner. Two stills differ at a pixel when their three channels together are more than 25 of 255 apart. A second still of each solid in one flat colour says which pixels are body.
- **What a body did.** The supplied marble, 0.1 m in radius, dropped from one metre above the top; the supplied walker on its autopilot. Headless, at 60 steps of the physics a second.
- **What I could not see.** An eye. "Look alike" in this note is a count of pixels.

## The prediction, as the outline stated it

"Seen from the side, 1.0 and 0.6 will look most alike: both are flat-topped blocks, and only the slope of the walls differs. 0.0 is the odd one: the top cap has no area and the solid ends in a point. Write the pair you expect, and where the marble will rest on each, before you render."

And for the place: "the marble dropped over the solid rests on the cap at the height you chose, and rolls off the pyramid."

## The trajectory

Each state names its parent. Status is one of continue, consolidate, branch, unresolved, stop.

### T0. Baseline

The prism: 28 triangles, 84 vertices in 16 places, closed, 0.8117 m³, which is the walk's area, 1.015 m², times 0.8 m.

### T1. The solid that came out round (parent T0, status: branch)

**Intervention.** None meant. The function was written as Plane wrote its fan: `add_vertex()` and `generate_normals()`.
**Observed.** The solid was shaded like a bar of soap. The top's first normal read (-0.187, 0.903, -0.387). Godot logged nothing.
**Observed.** With `set_smooth_group(-1)` the same normal read (0, 1, 0) in `SurfaceTool` and (0.0, 1.0, -0.000015) read back from the mesh. Smoothed against flat, the stills differ on 18.98% from the side and 10.96% from the corner, all of it inside the outline.
**Concluded.** `generate_normals()` averages the normals of vertices that share a place unless the smooth group is -1. The outline planned no fault for this chapter; this one is real and silent, and the lesson is built on it.

### T2. The sheet (parent T0, status: continue)

**Observed.** Share of the still on which two solids differ, side / above / corner: 1.0 and 0.6, 12.33 / 17.91 / 9.67%; 1.0 and 0.2, 30.34 / 23.50 / 18.35%; 1.0 and 0.0, 28.95 / 23.86 / 17.39%; 0.6 and 0.2, 8.30 / 6.59 / 7.48%; 0.6 and 0.0, 12.07 / 7.72 / 8.73%; 0.2 and 0.0, 3.36 / 2.84 / 2.05%.
**Observed.** From above, 0.6, 0.2 and 0.0 have the same outline to the pixel; they differ only inside it.
**Concluded.** The prediction was false. The closest pair is 0.2 and 0.0 from all three standpoints. The one that stands apart is the prism, not the pyramid.

### T3. Is it only the spacing? (parent T2, status: consolidate)

**Another cause.** The four values are 0.4, 0.4 and 0.2 apart. The closest pair is also the nearest in number.
**Intervention.** Six equal steps of 0.2, from the side, each against the next.
**Prediction.** If spacing were all, the five differences would be about equal.
**Observed.** 8.19, 6.32, 4.26, 3.79, 3.36%. The outline part falls from 3.75 to 2.66%; the part inside the outline falls from 4.44 to 0.69%.
**Concluded.** Spacing is part of it and not all. Equal steps of taper are not equal steps of the picture: the step away from the prism is 2.4 times the step into the pyramid, and most of that is inside the outline.
**Guessed.** That the inside part is the light on a wall that has begun to lean. I did not render the solids unlit to separate it.

### T4. The marble (parent T0, status: branch)

**Observed.** Dropped over the centre: at 1.0 it rests at 0.898 m where it landed; at 0.6 at 0.898 m, 0.20 m from where it landed; at 0.2 at 0.898 m, 0.03 m away; at 0.0 at 0.898 m, on the point.
**Observed.** On the pyramid, dropped 1 cm to the side, it rolled off, crossed the floor and fell over its edge.
**Concluded.** "Rolls off the pyramid" is true of every drop but the exact one.
**Guessed.** That a hand could not repeat the exact one.

### T5. The roll on the lid of 0.6 (parent T4, status: unresolved)

**Observed.** Two level lids; on one the marble stays, on the other it rolls 20 cm.
**Another cause, not tried.** The collider is the mesh's triangles, and the lid is a fan. By arithmetic on the walk the landing point is about a centimetre from one of the fan's inner edges. A ball that meets an edge between two triangles may be pushed sideways.
**Decision.** Leave open.

### T6. The project's extrude (parent T0, status: consolidate)

**Observed.** Handed the prism, `extrude_up()` returned six spires, one for each triangle of the lid's fan, 1.30 m high. At taper 0.2 it found 16 triangles facing up, six of the lid and ten of the walls, and pushed out nine; five were under 0.01 m² and two too thin.
**Observed.** In the scene the marble came to rest between the six spires of the prism, at 1.29 m. In the strip, on the six spires of the solid of taper 0.6, it ended on the floor, at 0.098 m.
**Concluded.** The two extrudes share their two numbers and not their unit: mine knows an outline, the project's knows triangles.

## What was observed, what was concluded, what is guessed

- **Observed.** The normals, with and without the smooth group. The share of pixels on which each pair differs, from three standpoints, and in six equal steps. Where the marble came to rest. What the walker did: stopped by 0.8 m, on top of 0.3 m, up a pyramid of 0.3 m.
- **Concluded.** 0.2 and 0.0 are the closest pair by this measure, and the prism stands apart. The likeness is not only spacing. A marble stays on a point when it is let go exactly over it.
- **Guessed.** That a person would agree with the pixel count. That the leaning walls' shade is what separates the prism from its siblings. That the fan's inner edge moves the marble on the lid of 0.6.

## Unresolved

- **No eye was asked.** Every "look alike" above is pixels.
- **The roll on the lid of 0.6.** T5.
- **Two bodies, two answers.** With the walk in the other order every front faces in. The marble fell through the lid; the walker was stopped by the wall. I did not find out why a wall seen from behind stops one body and a lid seen from behind lets the other through.
- **A zero with a sign.** With `index()` the bottom keeps 19 vertices where 8 would do, because its normals differ in the sign of a zero. I did not find out why `SurfaceTool` gives the bottom's triangles different zeros.

## The decisions, in one place

| at | decision | reason |
|---|---|---|
| T1 | follow | a silent fault in the first thing the learner types is the lesson |
| T2 | follow | the prediction failed, and the values were unevenly spaced: one more cause to rule out |
| T3 | settle | equal steps were unequal too; the claim can now be said with its reason |
| T5 | leave open | it is about the collider's fan, and one drop is not a measurement of it |
| T6 | settle | six spires is what the project's rule does; it is reported, not repaired |

**The decision of this note: follow once, then settle.** I followed the spacing, because a closest pair that is also the nearest in number has been explained twice over and tested not at all. Equal steps came out unequal, so the kit can claim more than "the nearest values look alike": the family is crowded toward the pyramid. I settle there. The roll on the lid stays open, and it is the difference the lesson offers the learner to follow.

## Replay

Run on 1 October 2026, from this folder, with Godot 4.6.

```
godot --path . --xr-mode off --script res://sheet.gd
godot --headless --path . --xr-mode off --script res://verify.gd
```

The first needs a window: it photographs the solids, writes `sheet.json`, `sheet.png` and `process.png`, and prints every number in T2, T3 and the stills of T1 and T6. The second runs 56 checks, among them the normals of T1, every drop of T4, the counts of T6 and the two bodies of *Unresolved*, and exits 0.

## Evidence

- `sheet.json`: every pair and standpoint, the equal steps, smoothed against flat, the strip. `sheet.png`, `process.png`.
- `verification.json`: the checks, with what each measured.
- `stills/`: the single stills. The folder is not tracked; `sheet.gd` makes it again.
