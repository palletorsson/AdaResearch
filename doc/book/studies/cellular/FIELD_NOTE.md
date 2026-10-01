# Field note: four rules on one floor

1 October 2026. Observer: Claude, the session that built this kit, working from the repository, from stills and from a walker on its autopilot. Nothing here was walked by a body in a headset, no hand was on the keys, and no person looked at the stills to say which two look alike.

This is the kit's own note, in the form of [the decision and the field note](../../course/opening/FIELD_NOTE.md). It is an example of the form. Your note will have another decision in it.

## The note

```
Question:        Which two of the rules 30, 90, 110 and 250 make the most alike floors
                 from one live cell, and can that be read from the rule numbers?
Baseline:        cellular.tscn of this kit: 17 cells on a ring, 11 rows, cells of 0.4 m,
                 each row 0.15 m higher; rule 90 is what the script starts with.
Intervention:    one field, rule: 30, 90, 110, 250. Nothing else.
Prediction:      the course outline's, written before any run (quoted below).
Observation:     90 and 250 are the closest pair by every measure taken. Details below.
Another cause:   the ring at the ends; the size of the floor; the standpoint. All three tried.
Decision:        follow twice, then settle. One thing left open.
Reason:          below.
Run it again:    the commands at the end.
```

## The apparatus

- **Scene.** `cellular.tscn`; for the stills each floor stands alone in the studio of `supplied/sheet_tools.gd`.
- **Engine.** Godot 4.6.stable.official.89cea1439, Windows, an NVIDIA GeForce RTX 3070, the Compatibility renderer.
- **What I could see.** Stills of 960 by 720 pixels from 9 m above the floor's middle and from 6.5 m in front of it, a 40 degree field of view, the bodies casting no shadow. Two stills differ at a pixel when its three channels together are more than 25 of 255 apart. The rows as the script prints them, and the cells its colliders cover. A walker, a capsule 0.6 m wide, on its autopilot. A marble 0.2 m across.
- **What I could not see.** An eye. "Alike" in this note is a count of pixels or of cells.

## The predictions, as the outline stated them

Both were written in the course outline before this kit existed.

1. "90 and 250 will look most alike: both grow a symmetric triangle at the same speed, 90 as Sierpinski's nested holes and 250 as a regular checker. 30 and 110 are both lopsided: 30 is disorderly on one side, 110 grows toward one side only."
2. The planted bug: "reading and writing the same buffer, so the rule sees its own new values and the pattern leans to one side".

## The trajectory

Each state names its parent. Status is one of continue, consolidate, branch, unresolved, stop.

### T0. Baseline

Rule 90, two buffers, a ring: 37 tiles in 11 rows, 0 cells unlike their mirror image.

### T1. One buffer (parent T0, status: consolidate)

**Intervention.** `step()` writes into the row it reads.
**Prediction.** The outline's second: the pattern leans to one side.
**Observed.** Row 1 is ten cells, from cell 7 to cell 16, where two buffers give two cells. 68 tiles in all; 72 of 187 cells unlike their mirror. Godot logged no error and no warning. Giving both names one buffer (`next = now`) produced the same rows.
**Observed, other rules, in an arithmetic copy and not in Godot.** With one buffer Rule 30 from one cell is a single cell that moves one place to the right in each row, and two cells in the one row where it comes round the ring; Rule 250 fills the whole row from row 2 on.
**Concluded.** The prediction held for Rule 90, and the side is the side the loop runs towards. What the fault looks like depends on the rule; "leans" describes 90.

### T2. The sheet (parent T0, status: continue)

**Observed.** Share of the still on which two floors differ, from above and from the front, and the cells that differ of 187:

| pair | above | front | cells |
| --- | --- | --- | --- |
| 30, 90 | 12.45% | 7.97% | 46 |
| 30, 110 | 15.50% | 9.50% | 56 |
| 30, 250 | 13.24% | 8.06% | 49 |
| 90, 110 | 15.52% | 11.03% | 58 |
| 90, 250 | 8.19% | 4.83% | 29 |
| 110, 250 | 15.92% | 10.96% | 59 |

**Observed.** Tiles: 69, 37, 47, 66 for 30, 90, 110, 250. Every tile of 90 is a tile of 250 (66 minus 37 is the 29 that differ).
**Concluded.** The first half of the outline's prediction held from two standpoints and by cells.

### T3. The ring (parent T2, status: consolidate)

**Another cause.** The floor is a ring, and from row 9 on the cells come round the ends. The likeness might be made there.
**Intervention.** `ring` unticked: beyond an end is dead.
**Observed.** Ring against dead ends, the same rule: 2, 6, 3 and 4 cells differ for 30, 90, 110 and 250, all from row 9 on; the stills differ on 0.67%, 1.96%, 1.00% and 1.30%. With dead ends the pairs differ on 48, 55, 51, 57, 27 and 60 cells, in the order of the table.
**Concluded.** 90 and 250 are the closest pair with either ending.

### T4. A longer floor (parent T2, status: consolidate)

**Another cause.** Eleven rows are few.
**Intervention.** 33 cells and 17 rows, a ring, counted from the colliders and not photographed.
**Observed.** The pairs differ on 125, 138, 131, 139, 70 and 151 of 561 cells.
**Concluded.** The pair is still the closest. I did not go further than 17 rows in Godot.

### T5. Lopsided (parent T2, status: consolidate)

**Observed.** Tiles left and right of the middle column: Rule 110, 33 and 3; Rule 30, 32 and 30. Cells unlike their mirror: 64 for 110, 48 for 30, none for 90 and 250.
**Concluded.** The second half of the prediction held for 110 as stated: it grows to one side, and its 3 tiles on the right came round the ring. For 30 it held only as arrangement: the two sides weigh the same and are arranged differently. "Disorderly on one side" I did not measure; I have no measure of disorder here and did not make one.

### T6. Read from the rule? (parent T2, status: consolidate)

**Observed.** Answers that differ, of eight: 30 and 90, 2; 90 and 250, 2; 30 and 250, 4; the other three pairs, 3.
**Concluded.** Two pairs that are each two answers apart differ on 46 and on 29 cells. The pair four answers apart is closer than all three pairs that are three apart. On this floor the number of answers that differ does not order the pairs.

### T7. A body (parent T2, status: branch)

**Observed.** The autopilot, from in front of the seed straight up the middle: on 90 and on 250 it stepped onto the seed and was stopped there, its feet at 0.15 m; on 30 it climbed to 0.90 m, fell through and was stopped on the ground under row 7; on 110 it arrived on the last row at 1.65 m. Up the left edge of 90 it arrived on row 8, at 1.46 m. A marble dropped over the middle of row 4 came to rest at 0.10 m under Rule 90 and at 0.85 m on Rule 250.
**Concluded.** The pair that is closest for the count of pixels is treated alike by the walker on this route and differently by the marble at this place.
**Guessed.** That the walker is stopped on the seed because the one-cell gap in row 1, 0.4 m, is narrower than the walker, 0.6 m, and the two tiles beside it stand in its way. I did not try a wider cell.

### T8. The pool (parent T0, status: unresolved)

**Observed.** After one step the most B in a cell is 1.883; after 1000 steps it is 0.420, and 360 of 576 cells hold a tenth or more. A second pool held the same numbers. A walker standing on the seed block, 0.60 m up, was lifted to 0.86 m and stood on the ground, 0.00 m, 600 steps later, 0.05 m from where it began. Sent out, it arrived, its feet 0.22 m up on the way.
**Guessed.** That the square shape of the wall comes from the square seed and the four-neighbour mean. I ran one seed and one pair of numbers.

## What was observed, what was concluded, what is guessed

- **Observed.** The rows, the tiles, the cells and pixels on which each pair differs, with a ring and with dead ends, on two floor sizes. Where the walker and the marble came to rest. The pool's numbers.
- **Concluded.** 90 and 250 are the closest pair by these measures. 110 is lopsided by weight, 30 by arrangement only. The count of answers that differ does not order the pairs. One buffer makes Rule 90 lean the way the loop runs.
- **Guessed.** That a person would agree with the pixel count. Why the walker stops on the seed. Where the pool's square comes from.

## Unresolved

- **No eye was asked.**
- **A corner.** A walker sent at a tile from an angle ended "blocked" on the ground at its corner; from straight ahead it stepped up. I went round it and did not chart which angles do which.
- **Disorder.** The outline calls Rule 30 disorderly. I counted mirror differences and nothing else.
- **`sheet.gd` ends with two lines** about a leaked texture, after its results are written. The kit base's sheet does the same. Cause not found.

## The decisions, in one place

| at | decision | reason |
|---|---|---|
| T1 | settle | the fault is real, silent and reproducible two ways |
| T3 | follow | the likeness could have been made by the ring |
| T4 | follow | eleven rows could have been too few |
| T4 | settle | the pair stayed closest three times, from causes that do not share the ring or the size |
| T7 | branch | what a body does is another measure; it belongs to the learner's decision |
| T7 | leave open | the corner, and the wider cell |

**The decision of this note: follow twice, then settle.** The two causes I could name for a false likeness were the ring and the short floor. I changed each alone and the pair stayed the closest. I settle there. The claim the kit makes is the measured one: these eight bits choose between a checker, a fractal, a one-sided growth and an arrangement with no mirror, and counting the bits that differ did not tell me which pairs would be near.

## Replay

Run on 1 October 2026, from this folder, with Godot 4.6.

```
godot --path . --xr-mode off --script res://sheet.gd
godot --headless --path . --xr-mode off --script res://verify.gd
```

The first needs a window: it photographs the four floors, writes `sheet.json`, `sheet.png`, `process.png` and `pool.png`, and prints every number in T2 to T6. The second runs 70 checks, among them the rows of T1, the walks and drops of T7 and the numbers of T8, and exits 0.

## Evidence

- `sheet.json`: every pair from both standpoints, the cells and answers that differ, the rows of each rule with a ring and with dead ends, the longer floor, the strip.
- `verification.json`: the checks, and what each walk and drop measured.
- `stills/`: the single stills. The folder is not tracked; `sheet.gd` makes it again.
