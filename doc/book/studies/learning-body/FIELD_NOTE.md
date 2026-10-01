# Field note: four labellers on one floor

1 October 2026. Observer: Claude, a session that finished this kit, working from the repository and from stills. An earlier session began it and labelled the builder's 36 places. Nothing here was walked by a body in a headset, no person labelled a place, and no person looked at the stills to say which two look alike.

This is the kit's own note, in the form of [the decision and the field note](../../course/opening/FIELD_NOTE.md). It is an example of the form. Your note will have another decision in it.

## The note

```
Question:        Which two of four labellers leave the most alike floor,
                 and what is a floor's sureness made of?
Baseline:        learning_body.tscn of this kit: 36 samples labelled by "the builder",
                 3 neighbours vote, 640 cells of 0.25 m.
Intervention:    one field, labelled_by: one person, the class, a default dataset,
                 random labels. The rule and k stay.
Prediction:      the course outline's, written before any run (quoted below).
Observation:     one person and the class are the closest pair, by pixels and by cells,
                 at four values of k. Details below.
Another cause:   the measure; k; and that both sets were made by one builder.
                 Two were tried. The third cannot be tried at a desk.
Decision:        follow twice, then settle with the claim cut down; one thing left open.
Reason:          below.
Run it again:    the three commands at the end.
```

## The apparatus

- **Scene.** `learning_body.tscn`; for the stills, the field alone in the plain studio of `supplied/sheet_tools.gd`.
- **Data.** `samples.json`, 144 samples, all stand-ins: see the README. "One person" is 36 labels by a session of Claude. "The class" is three rules that each flip one answer in six.
- **Engine.** Godot 4.6.stable.official.89cea1439, Windows, an NVIDIA GeForce RTX 3070, the Compatibility renderer.
- **What I could see.** Stills of 960 by 720 pixels from 8.6 m above the middle of the floor; the field covers 76.67% of a still. Two stills differ at a pixel when their three channels together are more than 25 of 255 apart. And the field itself, asked cell by cell: a label and a share for each of 640 cells.
- **What I could not see.** An eye, and a person's reason for a label.

## The predictions, as the outline stated them

Both were written in the course outline before this kit existed.

1. "The class and the default dataset will look most alike: smooth, confident regions. Random labels give a speckled field, and your own labels draw the most particular map."
2. "the Image is rewritten but the ImageTexture is not updated, so the floor never changes (texture.update(image) is the repair)".

## The trajectory

Each state names its parent. Status is one of continue, consolidate, branch, unresolved, stop.

### T0. Baseline

One person's field, 3 neighbours: 222 of 640 cells say stay, 354 are sure, the boundary is 72 cell sides long in 3 regions, and the field is wrong about 2 of its own 36 samples.

### T1. The floor that never changes (parent T0, status: consolidate)

**Intervention.** `paint_field()` without `texture.update(image)`: the shipped script with that one line taken out.
**Prediction.** The outline's second.
**Observed.** With a window: the image held 640 painted pixels, the texture read back held 0, and the floor in the still was `#0c0c0c`. The still differed from the mended field's on 75.55%. `painted 640 cells` was printed. Godot logged no error and no warning.
**Observed, without a window.** A texture made from a red image and updated with a green one read back red. Headless, `update()` changes nothing that can be read.
**Concluded.** The prediction held. And a headless check cannot see this fault: `verify.gd` reads the script's text for the line, and reads the texture back only when it is run with a window.

### T2. The sheet (parent T0, status: continue)

**Observed.** Share of the still on which two fields differ: one person and the class 48.13%; the class and the default dataset 54.47%; one person and random labels 56.93%; the class and random labels 59.14%; one person and the default dataset 61.55%; the default dataset and random labels 72.30%.
**Observed.** Cells sure, of 640: the default dataset 568, one person 354, the class 275, random labels 140. Boundary in cell sides: 27, 72, 114, 135.
**Concluded.** The outline's first prediction was false in its first part: the closest pair is one person and the class, and the class is neither smooth nor confident. It held in its second part: random labels give the longest boundary and the fewest sure cells. Its third part, "most particular", I could not measure.

### T3. Another measure (parent T2, status: continue)

**Another cause.** The pixel count also counts a cell whose label stayed and whose sureness changed, and it counts the balls.
**Intervention.** Count cells whose label differs, and nothing else.
**Observed.** One person and the class 233 of 640; the class and the default dataset 269; the class and random labels 351; one person and random labels 370; one person and the default dataset 406; the default dataset and random labels 420.
**Concluded.** The closest pair and the farthest pair are the same by both measures. The middle of the order is not.

### T4. Another k (parent T3, status: consolidate)

**Another cause.** One value of `k`.
**Intervention.** The same count with 1, 3, 5 and 9 neighbours.
**Observed.** One person and the class differ on 260, 233, 185 and 203 cells: the closest pair at all four. The class and the default dataset: 302, 269, 312, 277.
**Concluded.** The pair does not depend on `k` in this range.

### T5. The same places, other labels (parent T2, status: consolidate)

**Observed.** The builder and the coin labelled the same 36 places. The coin gave 17 of them the other label. 370 of 640 cells answer differently, and the field's sure cells go from 354 to 140.
**Concluded.** With the places, the rule and `k` held fixed, the labels alone moved more than half of the floor. This is the cleanest pair on the sheet, because only one thing differs between its two members.

### T6. A line (parent T2, status: consolidate)

**Observed.** After 100 rounds the perceptron's line is wrong about 0 of 36 for the default dataset, 15 for the class, 21 for one person and 21 for random labels. The stills of one person and of random labels by a line differ on 17.61%, the closest of all twelve pairs on the sheet.
**Observed.** One person's line after 99, 100, 101 and 102 rounds: wrong about 22, 21, 12, 22. On XOR, after 1000 rounds: 2 of 4.
**Concluded.** The line fits the dataset that was made as two heaps and no other. The count for one person is a fact about the round it was stopped at.
**Guessed.** That the swing is the perceptron on data no line can split: it never stops correcting. I did not test this beyond the four rounds.

### T7. The error (parent T6, status: consolidate)

**Observed.** For one person, the squared error of the line through the middle is 4.01 where the walker starts, 1.00 in the middle of the floor, and 0.927 at its lowest cell. `walk_down()` takes 17 steps to (−0.2, 0.75); the line of that place is wrong about 15 of 36. One cell of the floor is wrong about 12.
**Concluded.** The lowest error is not the fewest mistakes, and for these labels it is hardly lower than the error of a line that says nothing.

### T8. Two tests (parent T0, status: consolidate)

**Observed.** With one neighbour, `wrong()` is 0 for all four labellers. Each sample asked of a field that never saw it: wrong about 5 of 36 for one person, 10 for the class, 0 for the default dataset, 23 for random labels.
**Observed.** One person's lone "stay" at the right edge has a region of 10 cells with `k` at 1 and none with `k` at 3, where it is one of the two samples the field is wrong about.
**Concluded.** The first test cannot tell a coin from a person when `k` is 1. The second can.

### T9. A body (parent T0, status: unresolved)

**Observed.** The walker's autopilot, sent 4.2 m across the field, arrived with its feet at 0.00 m; the readout changed four times on the way, from stay to pass. Sent through a ball, it arrived. With the rule at the error it was sent downhill by the field and stopped at (−0.29, 0.78), reading `error 0.92 here; the line of these weights gets 15 of 36 wrong`. In the room it stepped onto the guest's slab, its feet at 0.10 m, and was told `you stand on stay, sure to 100%`.
**Not observed.** Anyone standing on a portrait of their own labels.

## What was observed, what was concluded, what is guessed

- **Observed.** Every count above: pixels on which two stills differ, cells whose label differs, sure cells, boundary lengths, mistakes of both rules, where a walker stopped and what the readout said.
- **Concluded.** By these measures the closest pair is one person and the class. A field's sureness follows how far its labels agree with their neighbours. The same places with other labels give another floor. A line fits only the data made for a line.
- **Guessed.** That one person and the class are close because one builder made both with the same idea, staying near the front of the floor: the class's three rules say so in `make_samples.gd`, and the builder's 13 stays lie mostly at the front left. That a real class would be less like one of its members than this one is. Neither can be tested without people.

## Unresolved

- **No person, no class.** Everything called "one person" or "the class" is a stand-in. What the sheet says about a real class is nothing.
- **Who made the default?** The default dataset is "nobody's" in the file. It was written by the same session that wrote the others, to be split by a line. Its consent line is missing on purpose.
- **"Most particular."** No count for it. One person's field has 3 regions, the class's 7, the coin's 7, the default's 2; I do not think regions are what the outline meant.
- **The perceptron's swing** was sampled at four rounds only.
- **Two lines at exit.** `sheet.gd` logs `ERROR: Texture with GL ID of 24: leaked 349524 bytes` twice after its work is written. The base's own sheet does the same. I did not find out why.

## The decisions, in one place

| at | decision | reason |
|---|---|---|
| T2 | follow | the prediction's first part was false, and the measure counted more than labels |
| T3 | follow once more | one value of `k` |
| T4 | settle | the pair is the same by two measures and four values of `k` |
| T5 | consolidate | one pair on the sheet differs in one thing only; the claim rests on it |
| T9 | leave open | a portrait needs a person |

**The decision of this note: follow twice, then settle with the claim cut down.** I followed the two causes I could change at a desk, the measure and `k`, and the closest pair stayed. The third cause, that one builder made both sets, I can name and cannot remove. So the kit does not claim that a class looks like one of its members. It claims what T5 shows: on the same 36 places, with the same rule, 17 other labels changed 370 of 640 cells; and that a field is sure only where its labellers agree with their neighbours.

## Replay

Run on 1 October 2026, from this folder, with Godot 4.6.

```
godot --headless --path . --xr-mode off --script res://make_samples.gd
godot --path . --xr-mode off --script res://sheet.gd
godot --headless --path . --xr-mode off --script res://verify.gd
```

The first writes `samples.json` again, the same bytes. The second needs a window: it photographs the fields, writes `sheet.json`, `sheet.png`, `k.png` and `process.png`, and prints every number in T1 to T8. The third runs 128 checks, among them the walks of T9 and the fault of T1, and exits 0.

## Evidence

- `sheet.json`: every pair, by pixels and by cells; every labeller's counts; the line's mistakes by round; the two tests; the error; the fault; the strip. `sheet.png`, `k.png`, `process.png`.
- `verification.json`: the checks, with what each measured. `room_trial.json`: the room test.
- `stills/`: the single stills. The folder is not tracked; `sheet.gd` makes it again.
