# Field note: four arrangements of one row

1 October 2026. Observer: Claude, the session that built this kit, working from the repository and from stills. Nothing here was walked by a body in a headset, and no person looked at the stills to say which two look alike. An earlier session began the kit and was cut off; it left one probe, on the logarithm of zero and on the order of a sum, and this note uses what that probe found after running it again.

This is the kit's own note, in the form of [the decision and the field note](../../course/opening/FIELD_NOTE.md). It is an example of the form. Your note will have another decision in it.

## The note

```
Question:        Which two of four arrangements of the same 200 symbols look
                 most alike, and does the counted entropy differ between them?
Baseline:        lab.tscn of this kit: 200 symbols from 0 to 9, seed 40, as
                 drawn; each a bar 0.02 m wide, its height its value, its
                 colour value % 4.
Intervention:    one field, arrangement: as drawn, sorted by value, sorted by
                 colour, sorted in reverse. Nothing else changes.
Prediction:      the course outline's, written before any run (quoted below);
                 and my own, written before the first render.
Observation:     value and reverse are the farthest pair, not the closest;
                 flipped, they are one picture to 0.12%. H is the same in all
                 four to the last bit.
Another cause:   the seed; the standpoint; perspective; the order of the sum.
                 Three were tried.
Decision:        follow twice, then settle; two things left open.
Reason:          below.
Run it again:    the two commands at the end.
```

## The apparatus

- **Scene.** `lab.tscn`: a `Node3D` that runs `row.gd`, another that runs `f_curve.gd`, and the supplied walker, on the kit base's floor.
- **Engine.** Godot 4.6.stable.official.89cea1439, Windows, an NVIDIA GeForce RTX 3070, the Compatibility renderer.
- **What I could see.** Stills of 960 by 720 pixels of one row alone, its shadow off and its label hidden, from the side and from straight above, 4.95 m away: one bar is 4 pixels wide. Two stills differ at a pixel when their three channels together are more than a tenth of full scale apart. And the lists themselves: the symbols, their order, their counts.
- **What was counted as entropy.** The distribution: the shares of the ten symbols in one row of 200. The estimator: the plain one, H = −Σ p log₂ p with p = count / 200, a symbol with count 0 left out. Nothing else in this note is called entropy.
- **What I could not see.** An eye. "Look alike" is a count of pixels. And a hand on the keys: every walk is the walker's autopilot, and Space was pressed by a script.

## The predictions, as stated

The outline's, written before this kit existed:

1. "'sorted by value' and 'reversed' will look most alike: they are mirror images. All four carry exactly the same counted entropy: the picture changes and the number does not."
2. "planted bug: log() of a zero count is -inf and the entropy reads nan: skip the symbols that never occur".
3. "Walk your own F curve: the chapters where your prediction was most wrong are the highest points; stand on them."

Mine, written before the first run of `sheet.gd`, from arithmetic on the bars: value and reverse differ on the whole of both staircases, about 18% of the still, and will be the farthest pair; as drawn against any sorted row, about 14%; the closest pair I cannot rank, my guess is value and colour; one still flipped, under 1%; H the same in all four.

## The trajectory

Each state names its parent. Status is one of continue, consolidate, branch, unresolved, stop.

### T0. Baseline

The row of seed 40 as drawn. It begins 2, 6, 6, 3, 8, 4. The counts of 0 to 9 are 21, 18, 22, 14, 25, 18, 17, 16, 26, 23. H = 3.296 bits of at most 3.322.

### T1. The planted bug (parent T0, status: consolidate)

**Intervention.** The two lines that skip a count of 0 taken out; `count` at 12.
**Prediction.** The outline's second.
**Observed.** The label and the printed line read `H = -nan bits`. Godot logged no error and no warning. Symbols 5, 7 and 9 do not occur in the first 12 draws. `log(0.0)` is `-inf`; `0.0 * log(0.0)` is `nan`; `print()` writes it `nan` and `"%.3f"` writes it `-nan`. With `count` at 200 the same script gave 3.296.
**Concluded.** The prediction held. The fault is silent, and it is hidden as long as every symbol occurs.
**Observed, about how the fault got in.** A sum over the dictionary's own keys never meets a count of 0 and has no such fault. The fault comes with the decision to ask about all ten symbols in a fixed order, and T4 is why that decision was made.

### T2. The sheet (parent T0, status: continue)

**Observed.** Share of the still on which two rows differ, from the side: colour and reverse 15.55%; value and colour 16.05%; drawn and value 17.20%; drawn and colour 18.97%; drawn and reverse 19.47%; value and reverse 19.92%. From above: 5.72%, 6.19%, 6.31%, 6.90%, 6.84%, 7.59%, in the same order of pairs.
**Concluded.** The first half of the outline's prediction is false by this measure: value and reverse are the farthest pair from both standpoints. My 18% was near; my 14% for the drawn row was low by a quarter.
**Observed.** The row as drawn covers 20.39% of the still from the side, and a sorted row 14.07%.
**Inferred.** The same 200 bars take more of the picture when they stand in no order: a tall bar beside a short one shows its side to an eye that is not straight in front of it. That is where my 14% went wrong. I did not render without perspective to confirm it.

### T3. A mirror (parent T2, status: consolidate)

**Another cause.** The outline's reason was that the two are mirror images. The measure compares place by place and cannot know that.
**Intervention.** The still of the reversed row flipped left to right, then compared with the row sorted by value.
**Observed.** They differ on 0.12% of the still from the side and 0.17% from above.
**Concluded.** They are mirror images, nearly to the pixel. The outline was right about the rows and wrong about what a count of pixels would say.
**Guessed.** That the 0.12% is the light: the sun stands to the left, and the flipped still shows faces lit from the right. Not tested.

### T4. The number (parent T0, status: consolidate)

**Observed.** H is 3.29584088399618570 for each of the four rows: equal as numbers, with `==`.
**Another cause.** The earlier session's probe had found two rows whose H differed in the last digits. I ran it again: summed in the order the dictionary met the symbols, the reversed row reads 3.29584088399618610 and the other three 3.29584088399618570, 4.4e-16 apart.
**Concluded.** The second half of the outline's prediction holds exactly only because `entropy()` adds in the alphabet's order. "Exactly the same" is a fact about the counts and, with care, about the sum.
**Not done.** Another processor. `log()` may round otherwise elsewhere.

### T5. The seed (parent T2, status: consolidate)

**Another cause.** One seed. The closest pair might be the accident of 40.
**Intervention.** Seed 41, from the side.
**Observed.** Closest: value and colour, 13.30%. Farthest: value and reverse, 18.30%. Colour and reverse, the closest pair of seed 40, is second, 14.52%. H is 3.276 in all four.
**Concluded.** Which pair is closest is the seed's. Which pair is farthest held for two seeds. Two seeds are not many.

### T6. Three more numbers about the number (parent T4, status: consolidate)

**Observed.** Counted by colour, four symbols, the row has 1.921 bits of at most 2. The rows of seeds 1 to 100 have between 3.245 and 3.319 bits, 3.292 on average; none reaches 3.322. Runs, the places where a symbol differs from its left neighbour plus one: 175 as drawn, 10 in each sorted row.
**Concluded.** The number depends on what is called a symbol. The plain estimator read low for every one of a hundred samples of an even source. And a count that does see order still cannot tell a staircase from its mirror.

### T7. The log as a body (parent T0, status: branch)

**Observed.** Sixteen entries, read from sixteen kits' sheets. Nine have F = 0. The largest: extrude 8.97, genome 5.49, family-editor 3.15, chessboard 3.14.
**Observed.** The walker, sent from plate to plate, arrived 16 times of 16. On extrude its feet were at 0.320 m and the plate's top at 0.319 m. On six plates (family, collage, family-editor, bullet, disturbed-order, soft-body) its feet were more than 2 cm above the plate; on collage, 0.05 m high, at 0.30 m.
**Concluded.** The outline's third prediction held for the peaks. For the valleys it did not: a body 0.6 m wide on plates of 0.4 m stands on the higher neighbour.
**Observed.** With `rise` at 0.1 the plate of extrude is 0.947 m high and the walk ended "blocked" on collage, 0.10 m short of its middle.
**Observed.** In the room, the guest with sixteen plates of 0.094 m stopped the walker 0.50 m from its middle. With three plates of 0.5 m the walker stepped onto the highest, its feet at 0.30 m.
**Concluded.** Whether this curve can be walked is decided by three choices that are not in the log: the plate's width, the rise, and the walker.

## What was observed, what was concluded, what is guessed

- **Observed.** The draws, their counts, the four orders. H for each row, to seventeen digits, summed two ways. The share of pixels on which each pair of stills differs, from two standpoints and for two seeds, and with one still flipped. How each walk ended, and how high the feet were.
- **Concluded.** Value and reverse are the farthest pair by this measure and mirror images to 0.12%. H is the same in all four rows. The closest pair changes with the seed. A missing symbol turns the sum into `nan` in silence.
- **Guessed.** That a person would call value and reverse the most alike, as the outline did. That the 0.12% is the light. That perspective explains why the drawn row covers more of the still.

## Unresolved

- **No eye was asked.** The disagreement between the outline and the measure is the interesting result here, and only a person looking can settle which of them is right about "alike".
- **Perspective.** The side view is not a bar chart: tall bars show their sides. An orthographic camera would separate that from the arrangement. Not rendered.
- **F is one rule.** `predicted` and `observed` are two differences from one table; another rule would give another curve. Legs, collage and soft-body have F = 0 with a reason that did not hold, or held in part.
- **The log is second-hand.** Its numbers were read from other kits' sheets, which were still being finished that day.

## The decisions, in one place

| at | decision | reason |
|---|---|---|
| T1 | settle | the fault is real, silent, and two lines mend it |
| T2 | follow | the outline's reason, the mirror, had not been measured |
| T3 | follow | one seed could be an accident |
| T4 | settle | the sum's order explains the one case where H differed |
| T5 | settle | the farthest pair held; the closest is the seed's, and I say so |
| T7 | branch, then leave open | the curve can be walked on its peaks; the valleys depend on widths I chose |

**The decision of this note: follow twice, then settle.** I followed the mirror, because the outline's reason was about a symmetry and the measure had no way to see one. I followed the seed, because a closest pair 0.5 of a percent ahead of the next is not a finding. After those two the kit can say what it claims with numbers of its own: four rows that differ on 15.55% to 19.92% of a still have one H, to the last bit. I leave open whether an eye agrees with the outline, and what the side view would say without perspective.

## Replay

Run on 1 October 2026, from this folder, with Godot 4.6.

```
godot --path . --xr-mode off --script res://sheet.gd
godot --headless --path . --xr-mode off --script res://verify.gd
```

The first needs a window: it photographs the rows, writes `sheet.json`, `sheet.png` and `process.png`, and prints every number in T2, T3 and T5. The second runs 77 checks, among them T1, T4, T6 and T7, and exits 0. Add `--fixed-fps 60` and it takes under a second instead of sixteen.

## Evidence

- `sheet.json`: every pair, both standpoints, the flipped stills, seed 41, the four entropies, how much of the still each row covers, the bars read back, the strip.
- `verification.json`: the checks, and under `measured` the counts, the entropies summed both ways, the runs, the hundred seeds, every walk.
- `guest_trial.json`: the room's trial of the guest.
- `stills/`: the single stills. The folder is not tracked; `sheet.gd` makes it again.
