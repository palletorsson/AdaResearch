# Field note: four amplitudes of one floor

1 October 2026. Observer: Claude, the session that built this kit, working from the repository and from stills. Nothing here was walked by a body in a headset, and no person looked at the stills to say which two look alike. A second session finished the kit the same day and ran both commands at the end of this note again, on a fresh copy: the stills and `sheet.json` came out the same byte for byte, and every check passed.

This is the kit's own note, in the form of [the decision and the field note](../../course/opening/FIELD_NOTE.md). It is an example of the form. Your note will have another decision in it.

## The note

```
Question:        Which two of the four floors look most alike, and at what
                 amplitude does the floor stop reading as a grid?
Baseline:        schotter.tscn of this kit: 60 cubes of 0.5 m, 12 columns of 5,
                 0.6 m apart, seed 1968; amplitude 20 is the script's default.
Intervention:    one field, amplitude: 0, 5, 20, 90 degrees. It scales the turn
                 about three axes and the slide together.
Prediction:      the course outline's, written before any run (quoted below).
Observation:     0 and 5 are the closest pair from two standpoints. The grid's
                 lines begin to close between 5 and 10 degrees. The walker
                 crossed every floor.
Another cause:   the seed; the standpoint; the gaps; the turn and the slide
                 moving together. Three were tried.
Decision:        follow twice, then settle; one difference left open.
Reason:          below.
Run it again:    the two commands at the end.
```

## The apparatus

- **Scene.** `schotter.tscn`: a `Node3D` that runs `schotter.gd`, on the kit base's floor, with the supplied walker on the first column. `maze.tscn` for the second body.
- **Engine.** Godot 4.6.stable.official.89cea1439, Windows, an NVIDIA GeForce RTX 3070, the Compatibility renderer.
- **What I could see.** Stills of 960 by 720 pixels of one floor alone, its shadow off: in plan (from straight above, without perspective, 120 pixels to a metre) and from a raised standpoint 9.1 m from the floor's middle. Two stills differ at a pixel when their three channels together are more than a tenth of full scale apart. A second still of each floor in one flat colour says which pixels are cube. And the transforms of the sixty cubes, read from the scene.
- **What I could not see.** An eye. "Look alike" and "reads as a grid" are counts in this note. And a hand on the keys: every walk is the walker's autopilot.

## The predictions, as the outline stated them

All three were written in the course outline before this kit existed.

1. "0 and 5 will look most alike: 5 degrees moves a 1 m cube's corner about 6 cm, less than the gap between cubes, so the grid still reads. Somewhere between 5 and 20 it stops reading as a grid."
2. "planted bug: randomize() left in after setting the seed, so the 'repeatable' floor changes on every run".
3. "Walk down the Schotter floor until the disorder makes it unwalkable (the colliders follow the cubes); get lost in the 10 PRINT maze."

## The trajectory

Each state names its parent. Status is one of continue, consolidate, branch, unresolved, stop.

### T0. Baseline

The floor of seed 1968 at amplitude 20: sixty cubes, the first column in order, the last cube turned (−5.9, 19.9, 17.2) degrees. Two builds stand alike, 60 cubes of 60.

### T1. A generator with no seed (parent T0, status: continue)

**Intervention.** The lesson's second step: `RandomNumberGenerator.new()` and nothing else.
**Observed.** Two builds in one run gave two floors. Two runs gave two more. Nothing in the script asks for that.
**Concluded.** In Godot 4.6 a new generator does not begin at a fixed place.

### T2. The planted bug (parent T1, status: continue)

**Intervention.** `rng.randomize()` under `rng.seed = seed_value`.
**Prediction.** The outline's second.
**Observed.** The generator held another number than 1968 after every build, a different one each time; `seed_value` still read 1968; two builds were two floors. Godot logged no error and no warning.
**Concluded.** The prediction held as stated. The one sign of the fault is `rng.seed` read back; a line that printed `seed_value` would have hidden it.
**Observed, widening.** Three more changes were silent. The seed line inside the inner loop: the five cubes of a column lie exactly alike. One unused draw under the seed line: the last cube turned (19.9, 17.2, 4.8), the right floor's numbers moved one place along. `float()` taken away: eleven columns in order, and the printed line the same as the right one.

### T3. The sheet (parent T0, status: continue)

**Observed.** Share of the still on which two floors differ, in plan: 0 and 5, 1.81%; 5 and 20, 6.20%; 0 and 20, 8.89%; 20 and 90, 20.07%; 5 and 90, 21.53%; 0 and 90, 21.86%. From the raised standpoint: 0.73%, 2.95%, 3.70%, 11.83%, 12.98%, 13.66%, in the same order.
**Observed.** At 5 degrees no corner of any cube moved more than 6.7 cm from its place in order. The gap is 10 cm.
**Concluded.** The first half of the outline's first prediction held from both standpoints: 0 and 5 are the closest pair.

### T4. A measure for "reads as a grid" (parent T3, status: continue)

**Another cause.** The pixel count has no notion of a grid. The second half of the prediction needs one.
**Intervention.** Two counts. In the plan: how much of the grid's lines, the middles of the eleven gaps between columns and the four between rows, is not covered by a cube. On the cubes: how many have a corner over the middle of a gap, seen from above: outside their own cell of 0.6 m on a side where a neighbour stands.
**Observed.** Lines clear at 0, 5, 7, 10, 15, 20, 45, 90 degrees: 100%, 100%, 99.9%, 98.1%, 89.7%, 80.7%, 51.2%, 41.0%. Cubes with a corner over a gap's middle at 0, 5, 20, 90: 0, 0, 35 and 52 of 60. At 20 degrees, column by column: 0, 0, 0, 0, 2, 3, 5, 5, 5, 5, 5, 5. With ten seeds, 1968 to 1977, the first cube does so at an amplitude of 5, 6 or 7 whole degrees; under seed 1968 at 7.
**Concluded.** The second half held, at the lower end of "between 5 and 20". There is no one point where the grid stops. The count on the cubes puts the break between a column's own amplitude of about 7 degrees and about 11.
**Observed.** At 90 degrees 41.0% of the lines are clear and 15.2% of the floor's whole rectangle is.
**Concluded.** Something of the grid can still be counted in the rubble. No cube's middle slides more than 0.25 m along x or along z.

### T5. The seed (parent T3, status: consolidate)

**Another cause.** One seed. What I call the effect of the amplitude might be the accident of 1968.
**Intervention.** Seed 1969 at the same amplitudes, in plan.
**Observed.** Seed 1968 and seed 1969 differ on 2.44% of the still at 5 degrees, 11.47% at 20 and 28.85% at 90. Their grid lines are clear on 100% and 100%, 80.7% and 77.4%, 41.0% and 43.2%.
**Concluded.** By pixels, two floors of one amplitude are further apart than two amplitudes of one seed. The pixel count tells which cube went where, and not how much disorder there is. The line count was close for these two seeds. Two seeds are not many.

### T6. No gaps (parent T4, status: consolidate)

**Intervention.** The outline's claim says the grid is what lets us see disorder. So take the visible grid away: `spacing` 0.5, the cubes touching, the floor in order one slab.
**Prediction.** Mine: the same 5 degrees changes less of the floor.
**Observed.** In plan, 0 against 5 degrees: 1.89% of the floor's pixels without gaps, 5.79% with them. 0 against 20: 13.25% and 28.45%.
**Concluded.** The same disorder shows on a third as much at 5 degrees and on half as much at 20. The claim's direction is supported. Its word "only" is not: without gaps the disorder still shows, on 1.89%.
**Not done.** A floor with no grid under it at all was not built. Touching cubes are still a grid.

### T7. The amplitude only scales (parent T0, status: consolidate)

**Observed.** At seed 1968 every cube's turn at amplitude 20 is four times its turn at amplitude 5, about each axis; the largest miss printed as 0.000000 radians.
**Concluded.** The four floors of the sheet are one set of 300 draws at four sizes. They are not four samples of chance.

### T8. A body on the floor (parent T0, status: branch)

**Prediction.** The outline's third: the walk ends where the disorder is too great.
**Observed.** The walker arrived at the last column in 8 walks of 8: amplitudes 0, 5, 20 and 90 at seed 1968, and 90 at seeds 1969 to 1972. Its feet moved between 0.50 and 0.50 m, 0.49 and 0.51, 0.46 and 0.55, 0.38 and 0.68. Every `Body` stood and was turned exactly as its mesh.
**Concluded.** The prediction was false for this floor and this walker.
**Intervention.** Two changes, one at a time: `spacing` 0.8 (gaps of 0.3 m); `step_height` 0 on the walker.
**Observed.** With the gaps: arrived at 0 and at 20 degrees; at 90 blocked under seeds 1968, 1970 and 1972 and arrived under 1969 and 1971. Without the step: arrived at 20 degrees; at 90 blocked under seeds 1968, 1970 and 1971 and arrived under 1969 and 1972.
**Concluded.** Disorder alone did not stop this body. Disorder with gaps, or disorder and a body that cannot step, stopped it under three seeds of five.
**Guessed.** That it always arrives at spacing 0.6 because a cube turns about its own middle and the middles stay 0.6 m apart. In a scratch copy, not kept in the kit's checks, I let every cube rest on the ground on its lowest corner instead: the walker was then blocked at 90 degrees under one seed of five. That is one trial and I did not follow it.
**Observed, about the instrument.** The walker crossed the floor in order in 96 steps of the physics; 6.6 m at 2 m/s is 198. It takes each gap of 0.1 m as a step, and its step carries it 0.32 m forward. Its speed over cubes measures nothing.

### T9. The maze (parent T0, status: consolidate)

**Observed.** Seed 1982: 9 walls lean one way and 15 the other. Twenty openings, ten corridors, followed by rule: none leads from the west side to the east. Four of the 48 triangles of floor are reached by no corridor. Sent straight across, the walker was blocked after 0.98 m. Led along the longest corridor, 11 cells, it arrived at the way out. Of the seeds 1982 to 2081, four have a corridor from west to east: 2010, 2029, 2031, 2037. In 2010 the walker crossed in 16 cells.
**Concluded.** A corridor between these diagonals cannot fork: each triangle opens on two sides. "Get lost" is the wrong word for what this maze does to a body that follows it. It brings the body back out.
**Not done.** Nobody stood between the walls.

## What was observed, what was concluded, what is guessed

- **Observed.** What each build printed. The transforms of the cubes. The share of pixels on which each pair of stills differs, from two standpoints. The share of the grid's lines not covered. How each walk ended, where, and how high the feet went. Which side each corridor leaves by.
- **Concluded.** 0 and 5 are the closest pair by this measure. The grid's lines begin to close between 5 and 10 degrees and no cube reaches over the middle of a gap below 5. Another seed moves more pixels than another amplitude does. Gaps make the same disorder show on two to three times as much of the floor. No amplitude made this floor unwalkable for this walker. `randomize()` after a seed discards the seed, in silence.
- **Guessed.** That a person would agree with the pixel count about 0 and 5. That the line count would stay close across many seeds; it was compared for two. Why the walker always arrives at spacing 0.6.

## Unresolved

- **No eye was asked.** Every "look alike" and every "reads" above is a count.
- **The turn and the slide moved together.** `amplitude` scales both. Which of the two closes the grid's lines was not separated. That is the difference the lesson offers the learner to follow.
- **Few seeds.** Two for the stills, five for the walks, ten for the cell count.
- **Why three seeds of five.** With gaps, or without the step, the same amplitude stopped the walker under some seeds and not others. I did not look at where it stuck.
- **A floor with no grid.** The claim says "only against a structure already built". Every floor here has `x * spacing` in it.

## The decisions, in one place

| at | decision | reason |
|---|---|---|
| T2 | settle | the fault is real, silent, and the read-back shows it |
| T3 | follow | the prediction's second half had no measure yet |
| T4 | follow | one seed could be an accident |
| T5 | follow once more | the claim is about the grid, and the grid had not been varied |
| T6 | settle | the direction of the claim is supported and its "only" is not; a floor with no grid is another program |
| T8 | branch, then leave open | the outline's walk did not happen; gaps and the step explain when it does, the seed's part is not explained |

**The decision of this note: follow twice, then settle.** I followed the seed, because a sheet made from one seed shows one set of draws at four sizes and I wanted to know what was the amplitude's and what was 1968's. I followed the gaps, because the claim is about the grid and nothing in the sheet varied the grid. After those two the kit can say what it claims with numbers of its own: 0 and 5 are closest; the lines begin to close between 5 and 10 degrees; gaps make the disorder show. I leave the turn against the slide to the learner, and the walker's three seeds of five open.

## Replay

Run on 1 October 2026, from this folder, with Godot 4.6.

```
godot --path . --xr-mode off --script res://sheet.gd
godot --headless --path . --xr-mode off --script res://verify.gd
```

The first needs a window: it photographs the floors, writes `sheet.json`, `sheet.png`, `process.png` and `maze.png`, and prints every number in T3 to T6. The second runs 66 checks, among them T1, T2, T4's count on the cubes, T7, T8 and T9, and exits 0. Add `--fixed-fps 60` and it takes two seconds instead of a minute.

## Evidence

- `sheet.json`: every pair, both standpoints, the line counts, the two seeds, the floor without gaps, the strip.
- `verification.json`: the checks, and under `measured` every walk, every corridor and every count on the cubes. Two of its entries, the builds without a seed and with `randomize()`, are different in every run.
- `guest_trial.json`: the room's trial of the guest.
- `stills/`: the single stills. The folder is not tracked; `sheet.gd` makes it again.
