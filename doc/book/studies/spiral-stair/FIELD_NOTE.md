# Field note: four rises of one spiral

1 October 2026. Observer: Claude, in two sessions: one built this kit, a second ran every measurement again and added two (they are marked). Both worked from the repository, from headless runs and from stills. Nothing here was walked by a body in a headset or by a hand on the keys, and no person looked at the stills to say which two look alike.

This is the kit's own note, in the form of [the decision and the field note](../../course/opening/FIELD_NOTE.md). It is an example of the form. Your note will have another decision in it.

## The note

```
Question:        Which rises of one spiral are a stair, to the eye and to a body?
Baseline:        spiral_stair.tscn of this kit: nine treads, radius 1.2 m, a turn of
                 30 degrees and a rise of 0.18 m a tread; the supplied walker,
                 1.80 m high, step_height 0.35 m, sent from (2.7, 0, 0).
Intervention:    one field, rise: 0.10, 0.18, 0.30, 0.60 m.
Prediction:      the course outline's, written before any run (quoted below).
Observation:     from the side 0.10 and 0.18 are the closest pair; in plan the four are
                 one picture; the walker climbs 0.10, 0.18 and 0.30 and is stopped by 0.60.
Another cause:   the two nearest numbers; the standpoint; a second reason for 0.60 to
                 be a wall. Each was tried.
Decision:        follow once, then settle.
Reason:          below.
Run it again:    the commands at the end.
```

## The apparatus

- **Scene.** `spiral_stair.tscn`. Each tread is a box 0.9 m wide, 0.7 m deep and one rise high, with a collider of the same size, the middle of its top at `place(i, 1.2)`.
- **Engine.** Godot 4.6.stable.official.89cea1439, Windows, an NVIDIA GeForce RTX 3070, the Compatibility renderer.
- **What I could see.** Stills of 960 by 720 pixels, one stair alone, from 9 m at the side and from straight above with no perspective. Two stills differ at a pixel when their three channels together are more than a tenth of full scale apart.
- **What a body did.** The supplied walker on its autopilot, sent along `route()`. A walk ends `arrived`, `blocked`, `fell` or `stopped`; I record that word and the height of the feet.
- **What I could not see.** An eye, a leg, a headset. "Look alike" is a count of pixels and "climb" is a capsule's autopilot.

## The prediction, as the outline stated it

"0.10 and 0.18 will look most alike: both read as a stair. 0.60 reads as a column of blocks, and the walker cannot climb it, because its step limit is lower."

## The trajectory

Each state names its parent. Status is one of continue, consolidate, branch, unresolved, stop.

### T0. Baseline

**Observed.** At a rise of 0.18 m the walk ended `arrived` with the feet at 1.62 m; the top is at 1.62 m. With the treads' colliders off, the same walk ended `arrived` with the feet at 0.00 m.
**Concluded.** `arrived` says the walker stands over its last point. It does not say it climbed. Every walk below is recorded with the height of the feet.

### T1. The sheet, from the side (parent T0, status: continue)

**Observed.** Share of the still on which two stairs differ: 0.10 and 0.18, 5.21%; 0.18 and 0.30, 7.13%; 0.10 and 0.30, 7.65%; 0.30 and 0.60, 12.59%; 0.10 and 0.60, 13.05%; 0.18 and 0.60, 13.57%. The stairs cover 3.91%, 4.74%, 6.20% and 10.79% of the still.
**Concluded.** The first half of the prediction held from this standpoint: 0.10 and 0.18 are the closest pair.

### T2. The plan (parent T1, status: consolidate)

**Another cause.** One standpoint.
**Intervention.** The same four stairs from straight above, with an orthogonal camera.
**Prediction.** Mine, before the run: no difference at all, because `rise` is only in y.
**Observed.** Every pair differs on 0.00% of the still. Each stair covers 19.37%.
**Observed** (second session). Counted with no threshold, two plans are not the same bytes: between 297 and 1,832 of 691,200 pixels differ, each by one step of 255 in one channel. The pair furthest apart in number, 0.10 and 0.60, has the most.
**Concluded.** "Most alike" depends on where the eye stands. From above there is no closest pair by the sheet's measure. My prediction of no difference at all was false by one step of one channel on at most 0.27% of the still; I do not know what in the renderer makes it.

### T3. The nearest numbers (parent T1, status: consolidate)

**Another cause.** 0.10 and 0.18 are 0.08 m apart; the other neighbours are 0.12 and 0.30 m apart. The closest pair might only be the closest numbers.
**Intervention.** Three pairs that are each 0.08 m apart.
**Observed.** 0.10 and 0.18 differ on 5.21%, 0.22 and 0.30 on 6.20%, 0.52 and 0.60 on 7.51%.
**Concluded.** Both causes are there. The pair is the nearest in number, and the same step separates two low stairs less than two high ones.

### T4. The walk (parent T0, status: continue)

**Observed.** Rise 0.10 m: `arrived`, feet at 0.90 m. 0.18 m: `arrived`, 1.62 m. 0.30 m: `arrived`, 2.70 m. 0.60 m: `blocked`, 0.00 m.
**Observed.** 0.35 m: `arrived`, 3.15 m. 0.36 m: `blocked`, 0.00 m.
**Concluded.** The second half of the prediction held, and its reason is exact: the line is the walker's `step_height`, 0.35 m.

### T5. The ramp (parent T4, status: branch)

**Another cause.** At 0.60 m the stair might be a wall for more than one reason. Take the steps out and see.
**Intervention.** The same spiral as one surface, `ramp` ticked.
**Prediction.** Mine, before the run: the ramp opens 0.60 m, since nothing is left to step over and the curve under the feet rises at 43.7 degrees, under the walker's 45.
**Observed.** 0.10, 0.18, 0.30 m: `arrived`, feet at 0.91, 1.65 and 2.69 m. 0.60 m: `blocked`, feet at 0.23 m.
**Observed.** The two triangles of a piece are 12.3 and 25.6 degrees steep at 0.18 m, 36.0 and 58.0 at 0.60 m. The walker's `floor_max_angle` is 45. With it set to 70 the walk on the 0.60 ramp ended `arrived` at 5.41 m. The ramp's limit for the unchanged walker is between 0.38 m (`arrived`) and 0.40 m (`blocked`).
**Concluded.** My prediction was false. 0.60 m is a wall twice: by the step, and by the slope. The second is partly made by the triangulation: the curve under the feet rises at 16.0 degrees where one of the triangles is 25.6.
**Decision.** Follow once more. **Reason.** The ramp was built for a body that does not step, and none had been sent.

### T6. A body that does not step (parent T5, status: consolidate)

**Intervention.** The walker with `step_height` 0.
**Observed.** The stair: `blocked` on the floor at 0.10, 0.18, 0.30 and 0.60 m. The ramp: `arrived` at 0.10, 0.18 and 0.30 m (0.89, 1.61, 2.69 m); `blocked` at 0.60 m (0.23 m) and at 0.35 m (0.26 m), which the stepping walker climbs.
**Concluded.** Every rise of the stair excludes this body. The ramp admits it up to somewhere between 0.30 and 0.35 m.

### T7. Headroom (parent T4, status: consolidate)

**Intervention.** Sixteen treads, once round and a third.
**Observed.** Rise 0.18 m: `blocked`, feet at 0.00 m, with the twelfth tread 1.98 m over the foot. 0.20 m, 2.20 m overhead: `blocked`, feet at 0.20 m. 0.21 m, 2.31 m: `arrived`, 3.36 m. 0.30 m: `arrived`, 4.80 m.
**Concluded.** A stair of more than one turn has a lowest rise as well as a highest, for a body of this height.

### T8. The planted bug (parent T0, status: stop)

**Intervention.** `turn_deg` handed to `cos()` and `sin()` without `deg_to_rad()`.
**Prediction.** The outline's: "the stair wraps several times around its column".
**Observed.** The treads lie 81.1 degrees back from each other, 1.56 m apart, 2.03 times round. The walk ended `blocked` with the feet at 0.00 m, 0.80 m short of the foot. Godot logged no error and no warning. `walk_test.gd` failed both its checks and exited with code 2.
**Concluded.** The fault is silent in the log and loud in a test.

### T9. The guest in the room (parent T4, status: consolidate)

**Observed.** On a place 1.6 m wide: six treads, radius 0.5 m, a turn of 40 degrees, a rise of 0.30 m. The room's own trial ended `arrived`, 0.52 m from the middle of the place, feet at 1.80 m. The same guest at a rise of 0.18 m: `blocked`, feet at 0.00 m. As a ramp at 0.30 m: `blocked`, 0.09 m. As a ramp at 0.10 m: `arrived`, 0.61 m.
**Guessed** (first session). That at 0.18 m the walker, lifted 0.35 m to step, touches the third tread, which is close on so small a circle.
**Observed** (second session). The walker's own landing test, repeated where the walk at 0.18 m ended: lifted 0.35 m and moved 0.32 m ahead, it would come down on the second tread, whose top is at 0.36 m, with a landing normal of y = 0.85. The walker steps only when that y is above 0.9.
**Concluded.** The guess named the wrong tread. The walker's round foot would land on the edge of the second tread and not on the top of the first, and its own rule refuses an edge. The treads are 0.35 m deep and the walker is 0.6 m wide.

## What was observed, what was concluded, what is guessed

- **Observed.** The share of pixels on which each pair differs, from two standpoints. How each walk ended and how high the feet were. The slopes of the ramp's triangles. What Godot logged.
- **Concluded.** 0.10 and 0.18 are the closest pair from the side and not from above. The walker's line is its `step_height`. 0.60 m is a wall by its step and by its slope. A stair of more than a turn has a lowest rise. So has a narrow one, for a wide foot.
- **Guessed.** That a person would agree with the pixel count. That a person in a headset could climb what the capsule climbs. Neither was tested.

## Unresolved

- **No eye was asked.** "Reads as a stair" and "reads as a column of blocks" were not measured.
- **The slope limit.** The steepest triangle of the 0.60 ramp is 58.0 degrees. A walker with `floor_max_angle` 60 is stopped by it and one with 61 climbs. I did not find out what lies between 58.0 and 61.
- **The ramp's arrival heights.** On the ramp the feet end between 1 cm under and 6 cm over the height of the last point. The walker stops within 0.1 m of the point, on a slope; I did not separate that from anything else.
- **The narrow stair's lowest rise.** T9 says why 0.18 m stops the walker. Where the line lies was only probed in scratch: stopped at 0.20 m, climbing at 0.22 m. It is not in `verification.json`.
- **The plan's last step of blue.** See T2.

## The decisions, in one place

| at | decision | reason |
|---|---|---|
| T1 | follow | the prediction had held from one standpoint and for the two nearest numbers |
| T3 | settle on the pixels | two other causes were tried and both are stated |
| T5 | follow | 0.60 m was explained by one cause, and the ramp could show a second |
| T6 | settle | the ramp's limit and the stair's are both measured, for two bodies |
| T9 | follow, then settle | the narrow stair was a question about the walker's own code; its landing test, repeated, answered it |

**The decision of this note: follow once, then settle.** I followed the "because" of the prediction, since a wall with one named cause may have two, and it had. I settle on a rise of 0.18 m for the kit's stair: the walker climbs it, it is the lower of the two middle values, and the tables say whom it shuts out.

## Replay

Run on 1 October 2026, from this folder, with Godot 4.6.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --script res://sheet.gd
godot --headless --path . --xr-mode off --script res://walk_test.gd
```

The first runs 69 checks, among them every walk of T0 and T4 to T9, and exits 0. The second needs a window: it photographs the stairs, writes `sheet.json`, `sheet.png`, `process.png` and `well.png`, and prints every number of T1 to T3. The third is the lesson's own test.

## Evidence

- `sheet.json`: every pair from both standpoints, the three pairs 0.08 m apart, the walks of the sheet, the strip.
- `verification.json`: the checks, with what each measured.
- `sheet.png`, `process.png`, `well.png`: looked at.
- `stills/`: the single stills. The folder is not tracked; `sheet.gd` makes it again.
