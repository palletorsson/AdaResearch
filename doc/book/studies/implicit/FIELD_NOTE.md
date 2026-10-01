# Field note: one field cut at 0.2, 0.4, 0.6 and 0.8

1 October 2026. Observer: Claude, the session that built this kit, working from the repository, from numbers the scripts wrote and from stills. Nothing here was walked by a body in a headset, no hand carved the field, and no person looked at the stills to say which two look alike.

This is the kit's own note, in the form of [the decision and the field note](../../course/opening/FIELD_NOTE.md). It is an example of the form. Your note will have another decision in it.

## The note

```
Question:        How much of an implicit body is its threshold? Does one number
                 decide how many bodies there are, and does a picture show where?
Baseline:        field_body.gd of this kit: three sources of reach 0.95 m, 2.42
                 radii apart, noise of 0.08, asked on a grid of 40 cells in a box
                 of 5 m, threshold 0.4.
Intervention:    one field, threshold: 0.2, 0.4, 0.6, 0.8.
Prediction:      the course outline's, written before any run (quoted below), and
                 one of my own, written before the sheet was rendered.
Observation:     0.6 and 0.8 are the closest pair, 12.14% of the still. The bodies
                 are 1, 1, 3 and 3. One becomes three between 0.48 and 0.50.
Another cause:   how far apart the sources are; the noise; the grid. All three tried.
Decision:        follow twice, then settle.
Reason:          below.
Run it again:    the two commands at the end.
```

## The apparatus

- **Body.** `field_body.gd`: a sum of three bells and a noise, asked at 68,921 places, turned into triangles cell by cell with the Ada project's marching-cubes table.
- **Engine.** Godot 4.6.stable.official.89cea1439, Windows, an NVIDIA GeForce RTX 3070, the Compatibility renderer.
- **What I could measure.** The count of bodies: triangles that share a corner, grouped. Lengths, from the points of the skin. Stills of 960 by 720 pixels, the body alone, seen level from the front, 6.5 m away; two stills differ at a pixel when their three channels together are more than a tenth of full scale apart. The time from one frame to the next.
- **What I could not.** An eye: "look alike" below is a count of pixels. A hand. A time on any machine but this one; the times moved from run to run because other programs were running.
- **The body is the same on every run.** Two runs of the sheet gave the same fourteen stills to the last byte.

## The predictions

The outline's: "0.4 and 0.6 will look most alike: both show separate blobs, one set fatter. At 0.2 the blobs fuse into one body; at 0.8 they shrink into beads."

Mine, from arithmetic, before the sheet was rendered: 0.6 and 0.8. A source alone has its skin where its bell is at the threshold, a ball of 1.27, 0.96, 0.71 and 0.47 radii at the four thresholds. Seen from the front its outline covers an area that goes with the square of that: 1.61, 0.92, 0.51 and 0.22. The smallest step is the last.

The outline's planted bug: "add_child() called from the worker thread errors or crashes until the node is handed back with call_deferred()".

## The trajectory

Each state names its parent. Status is one of continue, consolidate, branch, unresolved, stop.

### T0. Baseline

At 0.4: one body of 6,282 triangles, 4.16 m wide and 3.83 m high, standing on the floor, closed above it.

### T1. The comparison, as the hall writes it (parent T0, status: consolidate)

**Observed.** With a bit for each corner under the threshold, `at[i] < level`, the same 6,282 triangles were made and none of them faced outward. Godot printed nothing. With `>`, all of them did.
**Observed.** In a still of the running scene the body then shows its far wall from inside, with a dark rim, and two holes at the bottom through which the floor is seen.
**Concluded.** The borrowed table does not say which side of the threshold a bit stands for. The code that uses it has to agree with the engine's winding.

### T2. The sheet (parent T0, status: continue)

**Observed.** Bodies at 0.2, 0.4, 0.6 and 0.8: 1, 1, 3 and 3. Triangles: 8,296, 6,282, 3,588 and 1,508. Share of the still covered: 50.57, 33.99, 16.40 and 6.77%. Lowest point: 0, 0, 0.217 and 0.456 m.
**Observed.** Share of the still on which two bodies differ: 0.2 and 0.4, 27.02%; 0.2 and 0.6, 40.05%; 0.2 and 0.8, 47.16%; 0.4 and 0.6, 22.12%; 0.4 and 0.8, 30.47%; 0.6 and 0.8, 12.14%.
**Concluded.** The closest pair is 0.6 and 0.8. The outline's pair, 0.4 and 0.6, is the second closest of six, and its two members are not alike in kind: one body, and three. "At 0.2 the blobs fuse" held, and so did "at 0.8 they shrink into beads". My own pair held.
**Concluded.** The count and the picture disagree about where the body changes. Between neighbours the picture changes most from 0.2 to 0.4, which are both one body, and less from 0.4 to 0.6, where one becomes three.

### T3. Where one becomes three (parent T2, status: consolidate)

**Intervention.** The threshold in hundredths, from 0.40 to 0.60.
**Observed.** One body up to 0.48. Two at 0.49: pieces of 3,504 and 1,756 triangles. Three from 0.50.
**Concluded.** The body's count is decided inside two hundredths of the axis. The sheet's four values step over it.

### T4. The sources further apart (parent T2, status: branch)

**Another cause.** Whether 0.4 is one body is the spacing's doing, not the threshold's alone.
**Intervention.** The same three sources 1.17 times further from their middle: 2.83 radii apart.
**Observed.** Bodies at the four thresholds: 1, 3, 3 and 3.
**Concluded.** The outline's sentence about 0.4 and 0.6 is true of that field. It describes a spacing, and the kit's body has another. The stills of that field were not made, so its closest pair is not known.

### T5. The noise (parent T3, status: consolidate)

**Intervention.** `wobble` 0.
**Observed.** One body up to 0.47, three from 0.48, and no threshold with two.
**Concluded.** The three necks are equal without the noise and part together. The noise makes them unequal, moves the step up by a hundredth or two, and puts a body of two parts in between.

### T6. The grid (parent T3, status: consolidate)

**Intervention.** The same field on grids of 10, 20, 40 and 80 cells.
**Observed.** One body up to 0.46, 0.47, 0.48 and 0.48. Three from 0.51, 0.50 and 0.51 on the three finer grids; on the grid of 10 there are still two at 0.52. Triangles at 0.4: 364, 1,548, 6,282 and 25,264. At the sheet's four thresholds all four grids count 1, 1, 3 and 3.
**Observed.** At 0.43 and at 0.47 the grid of 80 finds a separate piece of 8 triangles. No coarser grid does.
**Concluded.** What the grid cannot resolve it joins or drops. The count at the sheet's values does not depend on it; the place of the step does, by two hundredths.
**Guessed.** That the pieces of 8 triangles are bumps of the noise close to the skin. I did not look at where they are.

### T7. The thread (parent T0, status: consolidate)

**Observed, in a window.** A usual frame took 16.68 ms. While the body was built on the main thread the longest frame was 107 to 108 ms; with a worker, 26 to 28 ms. At 80 cells: 700 to 711 and 62 to 63 ms.
**Observed.** With the hand-back called straight from the worker thread Godot logged four errors for every build and did not crash: one for `add_child()` ("Adding children to a node inside the SceneTree is only allowed from the main thread"), three that begin "The caller thread can't call the function". The skin was on, the wall was not in the scene, the signal was not sent, and a walker walked through the body.
**Observed.** With `wait_for_task_completion()` taken out of the hand-back, every check passed and Godot exited with code 0. With `_exit_tree()` taken out, a body freed in the middle of a build left its thread calling a body that was gone: "Invalid call. Nonexistent function 'value_at' in base 'previously freed'."
**Concluded.** The outline's bug is real in Godot 4.6 and is an error, four times, not a crash. The thread removes the build from the frame and leaves the hand-back in it: about 10 ms at 40 cells, about 46 at 80.
**Unresolved.** What an unwaited task costs. Nothing I ran shows it.

### T8. A body in it (parent T0, status: stop)

**Observed.** The walker, on its autopilot, was stopped 0.71 m in front of the body's middle. One hole carved 0.6 m ahead of it; stopped again at −0.19 m; a second hole; then it arrived on the far side. The body was still one body, of 6,330 triangles.
**Observed.** No point of the skin lay within 0.5 m of a hole's middle line; 2,649 lay between 0.5 and 0.6 m; the body was 4.16 m wide and 3.83 m high as before.
**Observed.** A marble dropped from 4.6 m over the top source was 3.68 m up a second later. The same drop beside the body was on the floor.
**Concluded.** A cut in the field is a hole in the body and in its wall, and the body can be walked into. The place asked for a hand; a walker's position and a key stood in for it.

## What was observed, what was concluded, what is guessed

- **Observed.** Every count, length and share of pixels above. The silence of the turned comparison. The four errors of the planted bug. How each walk ended.
- **Concluded.** 0.6 and 0.8 are the closest pair. One number does decide the count, between 0.48 and 0.50 for this field on this grid. The stills do not show where.
- **Guessed.** That a person at 6.5 m would call 0.6 and 0.8 the most alike. That the crumbs are noise. Neither was tested.

## Unresolved

- **No eye was asked.** A difference of 12% of a still is easy to see. Whether three balls and three beads read as "alike" to a person, and one fat body and one lean one as "different", was not tried.
- **The crumbs** of T6.
- **The unwaited task** of T7.
- **The table's two ways.** With the comparison turned, the grid of 10 cells kept one body up to 0.52 in place of 0.46. A case and its opposite are not always cut the same way. Seen once, in a negative test, and not followed.
- **The headset.** Nothing here was drawn for two eyes, and no hand was in the field.

## The decisions, in one place

| at | decision | reason |
|---|---|---|
| T2 | follow | the prediction named the wrong pair, and the count and the picture disagreed about where the body changes |
| T3 | follow once more | the step is two hundredths wide; whether that place belongs to the field or to how we ask it was open |
| T4 | branch, not taken | another spacing makes the outline's sentence true; it is another body |
| T5, T6 | settle | the noise and the grid each move the step by a hundredth or two and do not change the count at the sheet's values |
| T7 | leave open | the unwaited task needs a way to see the pool |
| T8 | stop | the hand is another session's work, with a headset |

**The decision of this note: follow twice, then settle.** I followed the count because the picture could not say where one body becomes three, and then the grid and the noise because the step was so narrow that it could have been made by the asking. I settle on this: the threshold decides the count, within two hundredths, and the room gets a body whose threshold moves: the guest rests at 0.6, three bodies, and falls to 0.3, one body, while a walker is within 2.5 m of it.

## Replay

Run on 1 October 2026, from this folder, with Godot 4.6.

```
godot --path . --xr-mode off --script res://sheet.gd
godot --headless --path . --xr-mode off --script res://verify.gd
```

The first needs a window: it writes `sheet.json`, `sheet.png` and `process.png`, and prints every number in T2 and the windowed half of T7. The second prints T1 and T3 to T8, and writes them to `verification.json`.

## Evidence

- `sheet.json`: both rows, every pair, the strip, the frames. `sheet.png`, `process.png`.
- `verification.json`: the checks, and under `measured` every number of T1 and T3 to T8.
- `stills/`: the single stills. The folder is not tracked; `sheet.gd` makes it again.
