# Field note: four orders of three verbs

1 October 2026. Observer: Claude, in two sessions: one built this kit, and a second ran all of it again and finished it. Both worked from the repository, from headless runs and from stills. Nothing here was walked by a body in a headset, nobody had their hands on the keys, and no person looked at the stills to say which two look alike.

This is the kit's own note, in the form of [the decision and the field note](../../course/opening/FIELD_NOTE.md). It is an example of the form. Your note will have another decision in it.

## The note

```
Question:        Is the order of the verbs part of the form? Which two of the
                 four orders are most alike, and alike for whom: an eye, a
                 count, a body that walks in?
Baseline:        combine.tscn of this kit: A (member of 16), B (member of 4),
                 C (the tunnel), S (the found body, closed), order 0:
                 ((A union B) minus C) intersect S, baked.
Intervention:    one field, order: 0, 1, 2, 3. Nothing else changes.
Prediction:      the course outline's, written before any run (quoted below).
Observation:     the first two are the closest pair from two standpoints of
                 three by share of the still, and from all three by share of
                 what the bodies cover. By volume and under the walker they
                 are not alike. Details below.
Another cause:   the standpoint; the size of the bodies in the still; where B
                 stands. All three were tried.
Decision:        follow twice, then settle.
Reason:          below.
Run it again:    the commands at the end.
```

## The apparatus

- **Scene.** `combine.tscn`. Four operands under one `CSGCombiner3D`, each with its own paint; the result baked to a mesh with a collider made from it.
- **Engine.** Godot 4.6.stable.official.89cea1439, Windows, an NVIDIA GeForce RTX 3070, the Compatibility renderer.
- **What I could see.** Stills of 960 by 720 pixels in the sheet's plain studio, one body alone, the light's shadow off, from the front (the eye 4.8 m from the body's middle, on the tunnel's line), from the front right, and from straight above. Two stills differ at a pixel when their three channels together are more than a tenth of full scale apart. A second still in one flat colour says which pixels are body. Headless: triangle counts, the volume a closed mesh encloses, where the walker's autopilot ended and how high its feet were, where a marble came to rest.
- **What I could not see.** An eye. The editor's windows. A hand on the keys.

## The prediction, as the outline stated it

"The first two will be the closest pair: they differ only where C overlaps B, so with C's tunnel through A alone they are the same body. The third will lose most of its volume (an intersection keeps only the overlap)."

## The trajectory

Each state names its parent. Status is one of continue, consolidate, branch, unresolved, stop.

### T0. Baseline

Observed. Order 0 has 574 triangles of 768 listed and encloses 1.859 m³. The walker, sent to the middle, arrived with its feet at 0.30 m.

### T1. A body that vanished (parent T0, status: branch)

**Intervention.** The found body as a scanner leaves it, a shell with an open foot, as the fourth operand, intersected.
**Prediction.** None written. I expected an error.
**Observed.** The result had 0 triangles. Godot logged no error and no warning. The shell alone has 340 triangles and 20 edges that belong to one triangle only. United with A or taken from A it changed nothing: 256 triangles, A alone.
**Concluded.** The combiner takes an operand that is not a closed skin as no body, in silence.
**Decision.** Follow. **Reason.** The outline names no planted bug for this chapter, and this is a real silence that a found body brings with it. The lesson is built on it, and the scan gets a foot of 20 triangles that no scanner saw.

### T2. The sheet, by share of the still (parent T0, status: continue)

**Observed.** Share of the still on which two orders differ, from the front, the front right and above: orders 0 and 1, 14.50%, 12.12%, 0.42%; 0 and 2, 16.15%, 26.33%, 13.58%; 0 and 3, 10.26%, 17.24%, 9.23%; 1 and 2, 24.30%, 27.33%, 13.84%; 1 and 3, 17.75%, 23.66%, 9.52%; 2 and 3, 9.06%, 14.96%, 8.67%.
**Concluded.** The first two are the closest pair from the front right and from above. From the front the closest pair is the last two.
**Decision.** Follow. **Reason.** Two standpoints and the third disagree, and the third is the one that looks along the tunnel, where the two orders differ.

### T3. The size of the bodies (parent T2, status: consolidate)

**Another cause.** The last two are small: from the front they cover 2.72% and 8.34% of the still. Two small bodies cannot differ on much of a still.
**Intervention.** The same stills, each pair counted against the pixels that either body covers.
**Observed.** Orders 2 and 3 differ on 100.0% from every standpoint: they share no pixel. Orders 0 and 1 differ on 59.5% from the front, 44.2% from the front right and 2.9% from above, and are the closest pair from all three. From the front orders 0 and 3 follow at 60.7%.
**Concluded.** The front's verdict in T2 was the size of the bodies, not their likeness. By the second count the outline's first sentence held from three standpoints, from the front by 1.2 points.

### T4. Where B stands (parent T2, status: consolidate)

**Intervention.** `b_x` from 0.2 to 0.95: B clear of the tunnel.
**Prediction.** The outline's condition: the first two orders are then the same body.
**Observed.** 576 triangles each, 1.5763 m³ each, the same 292 corners to a tenth of a millimetre, the same triangles, and 0.00% of the still from the front and from the front right. The two meshes' lists of corners are not equal as lists: the surfaces come in the order of the children, 207, 58, 65 and 246 triangles in the first order and 207, 65, 58 and 246 in the second.
**Concluded.** The condition held exactly.

### T5. Other ways to be alike (parent T2, status: consolidate)

**Observed.** Volumes: order 0, 1.859 m³; order 1, 3.239; order 2, 0.196; order 3, 0.793. Triangles: 574, 544, 150, 422.
**Observed.** The walker sent to the middle: order 0, arrived, feet at 0.30 m; order 1, blocked 0.80 m in front of the middle, feet at 0.00 m; order 2, arrived, feet at 0.30 m; order 3, arrived, feet at 0.00 m.
**Concluded.** The third order lost most of its volume, as predicted: it keeps 10.5% of the first. By volume the closest pair is orders 2 and 3, 0.597 m³ apart; orders 0 and 1 are 1.380 m³ apart. For a body, orders 0 and 1 are a door and a wall.

### T6. Baked and not baked (parent T0, status: consolidate)

**Observed.** The combiner's picture and the baked mesh differ on 0.00% of the still. Not baked, the walker arrived in the middle with its feet at 0.00 m and walked out through the side wall; put on the tunnel's floor at 0.30 m it was at 0.00 m a second later; a marble dropped in the hollow rested at 0.10 m. Baked, the walker arrived at 0.30 m, was blocked 0.06 m either side of the middle, and the marble rested at 0.40 m.
**Observed.** With `use_collision` on the combiner the walker put in the hollow stayed at 0.30 m; sent in from outside it was blocked at the door.
**Concluded.** The picture carries no information about whether the physics was told. With `use_collision` the physics was told, and the supplied walker's step, which asks for a `StaticBody3D`, was not.

### T7. What baking cost (parent T6, status: unresolved)

**Observed.** After each verb the result had 256, 296, 392 and 574 triangles, of which 0, 4, 16 and 26 are under one square centimetre; the smallest is 0.016 cm². The tunnel's wall lists 48 triangles and is 81 in the result. The operands list 768.
**Concluded.** The total went down, and the seams made slivers.
**Guessed.** That these slivers are where the body would fold first if it were bent, and that they cost the collider more than their area says. Neither was tested: nothing was deformed and no frame time was measured.

## What was observed, what was concluded, what is guessed

- **Observed.** The counts of triangles, the volumes, the edges of the shell, the share of pixels on which each pair differs by two counts, what Godot logged, where the walker and the marble ended.
- **Concluded.** Child order is operand order, and the same operands give four bodies. The first two orders are the closest pair to this measure of an eye, and not close as volumes or under a walker. An open operand is nothing, in silence. A CSG body is a picture until it is baked.
- **Guessed.** That a person would call the first two orders alike from the front right. That the slivers matter for bending and for the physics. Neither was tested.

## Unresolved

- **No eye was asked.** Every "alike" above is pixels.
- **Whether the editor warns.** In a running scene the open shell gave silence. Whether the editor marks the node was not watched.
- **Why a key leaves the walker a centimetre short.** Walked at a wall of the hollow from the middle, by the autopilot or with `move_right` held, the walker stopped 0.056 m from the middle. With `move_left` held after that, coming from the other wall, it stopped 0.045 m from the middle. I did not look at why.
- **One machine, one build.** Another build of Godot may cut the seams into other triangles; the counts here are this build's.

## The decisions, in one place

| at | decision | reason |
|---|---|---|
| T1 | follow | a body that vanishes without a message is the fault a found body really brings |
| T2 | follow | three standpoints disagreed about the closest pair |
| T3 | settle | the disagreement was the size of the bodies in the still, and both counts are now on the page |
| T5 | settle | pixels, volume and the walker give three different answers, and the lesson says which is which |
| T7 | leave open | bending and frame time belong to other chapters |

**The decision of this note: follow twice, then settle.** I followed the vanished body because the lesson needed a fault that is real. I followed the front standpoint because a prediction that holds from two cameras and fails from the third has not been understood yet. It was the measure: a share of the whole still is small for small bodies. I settle there. The kit claims that the order of the verbs is part of the form, shows the four bodies, and says in which sense the first two are alike and in which they are not.

## Replay

Run on 1 October 2026, from this folder, with Godot 4.6.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --script res://sheet.gd
```

The first runs 71 checks, among them every number of T0, T1 and T4 to T7, and exits 0. The second needs a window: it photographs the four orders, writes `sheet.json`, `sheet.png` and `process.png`, and prints every number of T2 and T3.

## Evidence

- `sheet.json`: every pair from every standpoint by both counts, the orders' triangles and volumes, the picture before and after baking, B clear of the tunnel, the strip. `sheet.png`: the four orders from the front, the front right and above.
- `verification.json`: the checks, with what each measured.
- `stills/`: the single stills. The folder is not tracked; `sheet.gd` makes it again.
