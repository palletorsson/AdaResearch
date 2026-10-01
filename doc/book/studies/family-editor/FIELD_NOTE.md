# Field note: four stances of one pyramid

1 October 2026. Observer: Claude, the session that built this kit and a second session that ran all of it again, working from the repository, from logs and from stills. Nothing here was walked by a body in a headset, the editor's windows were not watched, and no person looked at the stills to say which two look alike.

This is the kit's own note, in the form of [the decision and the field note](../../course/opening/FIELD_NOTE.md). It is an example of the form. Your note will have another decision in it.

## The note

```
Question:        Which two of the four stances look most alike from 2 m,
                 and which step along the axis changes the body most?
Baseline:        Ada's pyramid as borrowed/ada_pyramid.gd builds it: base 0.6 m,
                 height 0.8 m, apex_stance "centred", alone in the studio, in BODY.
Intervention:    one field, apex_stance: centred, edge, corner, beyond,
                 read from the class and set before add_child().
Prediction:      the course outline's, written before any run (quoted below).
Observation:     corner and beyond are the closest pair from no standpoint of four.
                 Details below.
Another cause:   the standpoint; perspective; smooth normals; the light.
                 Three were tried, one is left open.
Decision:        follow twice, then settle; one branch left open.
Reason:          below.
Run it again:    the two commands at the end.
```

## The apparatus

- **Scene.** `family_editor.tscn`. The members are `borrowed/ada_pyramid.gd`; the spire is `guests/family-editor/spire.gd`, which is the same body at lean 0, 1 and 1.6 (checked corner by corner).
- **Engine.** Godot 4.6.stable.official.89cea1439, Windows, an NVIDIA GeForce RTX 3070, the Compatibility renderer.
- **What I could see.** Stills of 960 by 720 pixels of one member alone in the plain studio, 2 m from its middle, the body casting no shadow. Two stills differ at a pixel when their three channels together are more than a tenth of full scale apart. A second still of each member in one flat colour says which pixels are body. Logs of headless runs, and of an editor started with no window.
- **What I could not see.** An eye. The editor's Inspector, Debugger panel and viewport.

## The predictions, as the outline stated them

1. "corner and beyond will look most alike. In pyramid.gd's own numbers the apex sits at (0, 0), (0, -0.3), (-0.3, -0.3) and (-0.48, -0.48) in plan: corner and beyond are 0.25 m apart, the closest pair, while centred to edge and edge to corner are 0.30 m apart, and corner and beyond lean along the same diagonal. What the sheet has to show is the one thing the distances do not rank: beyond is the only member whose apex has left its own footprint."
2. "One exported enum carries a pyramid from monument to lean-to, and the step that changes the category is not the largest step."
3. "the setter calls _rebuild() before the node is ready, so errors fill the Output as soon as the scene opens (guard with is_node_ready())".

## The trajectory

Each state names its parent. Status is one of continue, consolidate, branch, unresolved, stop.

### T0. Baseline

One member at `centred`: six triangles, five corners, the apex over (0, 0) at 0.8 m.

### T1. The planted bug as it behaves (parent T0, status: consolidate)

**Intervention.** The spire's setter with its `is_node_ready()` taken out, and a value set before the node is in the room: by the scene's stored `lean = 1.6`, and by a line of code.
**Prediction.** The outline's third: errors fill the Output.
**Observed.** One script error for each such value: `Invalid assignment of property or key 'mesh' with value of type 'ArrayMesh' on a base object of type 'Nil'.` Then the node entered the room, `_ready()` built the body from the stored value, and the scene ran with no further error.
**Observed.** In an editor started with no window, with `@tool` on the script, the same error was logged once as the scene opened.
**Concluded.** The fault is real and smaller than predicted: one red line, then a picture that looks right.

### T2. The sheet, from the front (parent T0, status: continue)

**Observed.** Share of the still on which two members differ: centred and edge 0.49%; corner and beyond 3.64%; edge and corner 5.75%; centred and corner 5.98%; edge and beyond 7.58%; centred and beyond 7.87%.
**Concluded.** The outline's first prediction is false from this standpoint. The closest pair is centred and edge: a band of 3.44 pixels of outline and nothing inside it.

### T3. Other standpoints (parent T2, status: continue)

**Another cause.** One camera. From the front the apex of `edge` moves straight away from the eye.
**Intervention.** The same four stills from above, across the diagonal the apex walks, and along it.
**Observed.** From above, with perspective, the first run showed the body of `corner` larger than that of `centred` (10.09% of the still against 8.20%; from the builder's scratch log): the apex is nearer the eye than the base, so it looked off a base it stands over.
**Decision.** Follow. I changed that standpoint to a plan, straight down with no perspective.
**Observed, plan.** The three members with the apex over the base have the same outline; each pair with `beyond` in it differs on 6.54%, 2.42% of it outline and 4.11% inside. Closest: centred and edge, 2.07%.
**Concluded, from the stills.** The three equal numbers are what this measure does: it counts where two stills differ, not by how much. In each of the three the half of the square on the dark side differs from the same half of `beyond`, by one tone or by another.
**Observed, across.** Closest: centred and edge, 4.42%. Corner and beyond 11.14%.
**Observed, along.** Closest: centred and corner, 0.79%. Corner and beyond 6.80%, of which 0.35% is outline and 6.45% inside.
**Concluded.** The prediction is false from all four. Which pair is closest depends on the standpoint: the apex that moved along the line of sight is the one that did not seem to move.

### T4. Smooth normals (parent T2, status: consolidate)

**Another cause.** My first stills were shaded round: `generate_normals()` smooths across corners that share a place unless told otherwise.
**Intervention.** `set_smooth_group(-1)`: every face lit flat, as Ada's own builder does.
**Observed.** From the front, centred and edge went from 2.41% to 0.49%: the 1.92% inside the outline was the smoothing. The closest pair was the same before and after. The earlier numbers are in the builder's scratch log, not in `sheet.json`.

### T5. The light (parent T3, status: unresolved)

**Observed.** In plan the spire at lean 0, 0.2, 0.4, 0.6 and 0.8 gives the same still: 0.02% together. The step to 1.0 changes 4.01% with the outline unchanged.
**Observed.** The studio's sun shines 88 degrees from the diagonal the apex walks, 43 degrees above the horizon.
**Concluded.** The line between the lit faces and the dark ones lies along the apex's diagonal, so in plan the apex moves along a line that does not move.
**Guessed.** That the 4.01% is one dark face turning to the sun: by the sun's direction that face first turns to it at lean 0.96. I did not photograph the faces one by one.
**Decision.** Leave open. A quarter turn of each member under the same sun would separate the light from the standpoint. It was not run.

### T6. The claim (parent T3, status: consolidate)

**Observed.** The three steps of the axis, in order. In metres of the apex's travel: 0.3, 0.3, 0.255. In pixels: level 0.49, 5.75, 3.64%; plan 2.07, 4.10, 6.54%; across 4.42, 8.85, 11.14%; along 6.35, 6.00, 6.80%.
**Concluded.** The step that takes the apex off its base is the shortest in metres and the largest in pixels from three standpoints of four. The outline's claim holds in metres and from the front.

### T7. A body (parent T0, status: consolidate)

**Observed.** The walker, on its autopilot, along the diagonal. Lean 0: stopped 0.60 m from the middle from both sides. Lean 1.0: stopped 0.73 m out on the side the spire leans to; from the far side it walked up the spire and arrived, feet at 0.42 m. Lean 1.6: stopped 0.92 m out, over floor the base does not cover; from the far side arrived, feet at 0.31 m.
**Observed.** From the far side, lean by lean: stopped at 0.5, 0.6, 0.7 and 0.8; arrived at 0.9 and 1.0.
**Concluded.** For this walker the spire stops being a wall between lean 0.8 and 0.9, before the apex leaves the base at 1.0.
**Guessed.** That this is the walker's 45 degree rule for what counts as floor: the ridge from the far corner rises 0.8 m over 0.42 m times (1 + lean), which is 45 degrees at lean 0.89. I did not change the walker's limit to test it.

### T8. The editor (parent T1, status: consolidate)

**Observed.** In an editor started with no window, with the scene open: the script printed `rebuilt in the editor: lean 1.6`; a second tool script set `lean` to 0.5 and the body's box went from 0.78 to 0.6 m wide; without `@tool` the spire had no children there and the box stayed empty.
**Observed.** An earlier spire that was itself the mesh node had its built mesh written into `family_editor.tscn` when the scene was saved there (1051 to 2873 bytes, in a scratch copy). The shipped spire builds on children the scene does not own; the saved scene held `lean = 0.5` and no mesh.
**Concluded.** `@tool` does what the lesson says, as far as a log can tell.

## What was observed, what was concluded, what is guessed

- **Observed.** The error text and how many times it came. The share of pixels on which each pair differs, from four standpoints. The spire's stills at nine values of lean. Where the walker stopped and where it stood. What the windowless editor logged, and what stood in the saved scene file.
- **Concluded.** Corner and beyond are not the closest pair from any of four standpoints. The closest pair is the one whose apex moved along the line of sight. The step off the base is the shortest in metres and mostly the largest in pixels. The walker's category changes before the eye's.
- **Guessed.** That a person 2 m away would agree with the pixel count. That the jump at lean 1.0 in plan is a face turning to the sun. That the walker's change at 0.9 is its floor angle. That the Inspector's slider behaves as the script that stood in for it.

## Unresolved

- **No eye was asked.** Every "look alike" above is pixels.
- **The light.** All four standpoints shared one sun, and it stands square to the axis of this family. T5 is open.
- **The measure has a threshold.** It counts a pixel as different or not. Three pairs in plan measure exactly 6.54% for that reason, and a slow change of tone can stay under the threshold for several steps and then be counted all at once.
- **The editor.** Whether dragging the Inspector's slider rebuilds at every tick, and how that feels, was not watched.
- **Edge is not on the spire's line.** The spire is Ada's pyramid at three of the four stances; `edge` has no lean.

## The decisions, in one place

| at | decision | reason |
|---|---|---|
| T1 | settle | the fault is real as measured; the lesson reports one red line and not a flood |
| T3 | follow | the prediction had failed from one camera only, and that camera hid the move it was asked about |
| T3 | follow once more | "above" with perspective showed an apex off a base it stands over; a plan does not |
| T4 | settle | flat faces are what Ada builds, and the closest pair did not change |
| T5 | leave open | the sun is the look's, the same in every kit; turning the members is the learner's next intervention |
| T7 | settle | the walker's numbers are the chapter's place, and the 45 degree reading is marked as a guess |

**The decision of this note: follow twice, then settle.** I followed the standpoint, because a prediction about what two bodies look like cannot be tested from one camera, and then the projection, because the standpoint I had added was itself misleading. I settle with four standpoints that agree on one thing: corner and beyond are not the closest pair. I leave the light open and say so, because it is the one cause all four share.

## Replay

Run on 1 October 2026, from this folder, with Godot 4.6.

```
godot --path . --xr-mode off --script res://sheet.gd
godot --headless --path . --xr-mode off --script res://verify.gd
```

The first needs a window: it photographs the members and the spire, writes `sheet.json`, `sheet.png` and `process.png`, and prints every number in T2, T3, T5 and T6. The second runs 60 checks, among them T1, T7 and T8, and exits 0.

Both were run again the same day by a second session, on fresh copies of the kit. Observed: `sheet.json`, `sheet.png`, `process.png` and every still came out byte for byte the same, and the checks' measurements were the same.

## Evidence

- `sheet.json`: every pair and standpoint, the steps, the spire's series, the sun. `sheet.png`: the four members from the four standpoints.
- `verification.json`: the checks, the error text, the walker's numbers, the editor's lines.
- `guest_trial.json`: the room's trial of the guest.
- `stills/`: the single stills. The folder is not tracked; `sheet.gd` makes it again.
