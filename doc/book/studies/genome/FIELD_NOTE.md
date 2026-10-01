# Field note: five creatures and one file

1 October 2026. Observer: Claude, the session that built this kit, working from the repository and from stills. Nothing here was walked by a body in a headset, and no person looked at the stills to say which two look alike.

This is the kit's own note, in the form of [the decision and the field note](../../course/opening/FIELD_NOTE.md). It is an example of the form. Your note will have another decision in it.

## The note

```
Question:        Which two of five creatures look most alike from above, and is there
                 a place on the axis where a creature becomes a flower?
Baseline:        cabinet.tscn of this kit. A new genome: 3 segments, 4 limbs raised
                 25 degrees, BODY, body_seed 1. Each creature alone in the studio, 2 m.
Intervention:    one gene, limb_count: 0, 2, 4, 6, 12.
Prediction:      the course outline's, written before any run (quoted below).
Observation:     from above the closest pair is 0 and 2; 6 and 12 are not. Details below.
Another cause:   which limbs lie on top of each other; the standpoint; the turn of
                 the body. All three were tried.
Decision:        follow twice, then settle.
Reason:          below.
Run it again:    the two commands at the end.
```

## The apparatus

- **Scene.** `guests/genome/genome.tscn`, built by `creature.gd` from a `genes.gd` resource: balls stacked from the ground, capsules around the lowest ball.
- **Engine.** Godot 4.6.stable.official.89cea1439, Windows, an NVIDIA GeForce RTX 3070, the Compatibility renderer.
- **What I could see.** Stills of 960 by 720 pixels, one creature alone, the camera 2 m from the point 0.5 m above the ground, a 40 degree field of view, the body casting no shadow. Two stills differ at a pixel when their three channels together are more than a tenth of full scale apart. A second still of each creature in one flat colour says which pixels are body.
- **What I could not see.** An eye. "Look alike" in this note is a count of pixels. "Reads as a flower" is not something a count can say.

## The predictions, as the outline stated them

All three were written in the course outline before this kit existed.

1. "6 and 12 will look most alike from above: past about six limbs the body reads as radial, a star or a flower, not an animal."
2. "A genome draws a border between kinds: somewhere between 4 and 6 limbs, a creature becomes a flower."
3. "five bodies built from one Genome instance: mutate one and all five change (duplicate() is the repair)."

## The trajectory

Each state names its parent. Status is one of continue, consolidate, branch, unresolved, stop.

### T0. Baseline

One creature from a new genome: 3 balls and 4 limbs, 7 parts, 0.88 m high. With `body_seed` 1 the balls have radii 0.2088, 0.1642 and 0.1412 m in every run.

### T1. Five bodies, one genome (parent T0, status: continue)

**Intervention.** The row's loop hands each of five creatures the parent genome itself and sets `limb_count` on it: 0, 2, 4, 6, 12.
**Prediction.** The outline's third: all five change.
**Observed.** The plates read 0, 2, 4, 6, 12. Every creature was built of 15 parts and its genome read 12. The specimen, which had the same genome, had 12 limbs too; the file still said 6. Godot printed no error, no warning and no line.
**Observed.** `load()` of one path twice returned one object. After another genome was saved to that path, `load()` still returned the first, with 6 limbs; read past the loader's memory, the file said 12.
**Observed.** With `parent.duplicate(true)` for each: 3, 5, 7, 9 and 15 parts. `duplicate()` without `true` did the same for these five plain genes. On a resource holding a material and a list, `duplicate()` left both shared and `duplicate(true)` copied both.
**Concluded.** The prediction held as stated. The fault is silent, and each plate was true at the moment it was written.

### T2. The sheet, from above (parent T0, status: branch)

**Observed.** Share of the still on which two creatures differ: 0 and 2, 2.74%; 2 and 4, 2.75%; 2 and 6, 5.47%; 0 and 4, 5.49%; 0 and 6, 8.21%; 4 and 6, 8.22%; 6 and 12, 8.23%; 4 and 12, 10.95%; 2 and 12, 13.70%; 0 and 12, 16.44%.
**Observed.** The bodies cover 3.71%, 6.35%, 9.00%, 11.63% and 19.55% of the still: 1.32% for each limb.
**Concluded.** The outline's first prediction was false from above. 6 and 12 are seventh of ten pairs. The closest pair is 0 and 2.

### T3. What the number counts (parent T2, status: consolidate)

**Another cause.** Every creature's first limb points the same way. 12 limbs contain the directions of 6, 4 and 2. The pairs might be close because limbs lie on top of each other, not because the bodies are alike.
**Intervention.** Every count from 0 to 12, each against 12, from above.
**Observed.** 0: 16.44%. 1: 15.06%. 2: 13.70%. 3: 12.32%. 4: 10.95%. 5: 17.62%. 6: 8.23%. 7: 18.55%. 8: 14.88%. 9: 17.28%. 10: 18.80%. 11: 19.94%.
**Concluded.** The counts that divide 12 fall on a line, about 1.37% of the still for each limb that has no partner. The others do not: 11 limbs are further from 12 than no limbs are. From above this measure counts the limbs that do not coincide. It does not see a kind.

### T4. From the side (parent T2, status: continue)

**Another cause.** One standpoint.
**Observed.** From the side the closest pair is 2 and 4, 0.98%, with 0.00% outline: the two new limbs point at the camera and away from it. 6 and 12 are second, 2.61%, with 0.48% outline. Then 0 and 2, 3.12%.
**Observed.** The outline of each count against the outline of 12, from the side: 0, 5.53%; 1, 3.98%; 2, 2.43%; 3, 2.45%; 4, 2.43%; 5, 1.30%; 6, 0.48%; 7, 0.96%; 8, 1.20%; 9, 0.64%; 10, 0.56%; 11, 0.64%.
**Concluded.** From the side the outline settles between 4 and 6 limbs: 2.43% at 4, 1.30% at 5, 0.48% at 6, and it stays under 1.3% after. That is the place the outline's claim names. It shows in one measure, from one standpoint.

### T5. Turned (parent T4, status: consolidate)

**Intervention.** Each count from the side, against itself turned by half the angle between two limbs.
**Observed.** The whole difference: 2 limbs, 4.10%; 3, 5.84%; 4, 5.47%; 5, 5.16%; 6, 6.21%; 12, 6.17%. Its outline part: 2, 3.10%; 3, 3.95%; 4, 2.06%; 5, 1.83%; 6, 1.67%; 7, 1.39%; 8, 1.29%; 9, 1.09%; 10, 0.87%; 11, 0.81%; 12, 0.57%.
**Concluded.** Where you stand matters less to the outline as limbs are added, and its one large fall is between 3 and 4. Inside the outline a turned creature of 12 changes as much as a turned creature of 6.

### T6. What the file holds (parent T0, status: consolidate)

**Observed.** A genome with 6 limbs is saved as seven lines: the script's path and `limb_count = 6`. A genome at its defaults is saved as six lines with no gene. A file with no gene in it loaded with 4 limbs under our script and 8 under a copy whose default is 8.
**Observed.** `wings = 2` in a file: loaded without it, nothing printed. `limb_count = "six"`: 0. `limb_count = 3.5`: 3. A script path that is not there: null, six error lines, among them `Parse Error: [ext_resource] referenced non-existent resource at: res://genes.gd.`
**Observed.** A save under a name ending in `.txt` returned 15, wrote nothing and printed nothing.
**Concluded.** The file is the difference from a script, and the script is not in it.

### T7. A body (parent T0, status: unresolved)

**Observed.** The walker, sent at the specimen, ended "blocked" 0.50 m from its middle. Sent past the trunk and through a limb it arrived. A marble dropped over the trunk rested at 0.90 m; over a limb, at 0.10 m, on the floor.
**Observed.** With one segment the body is 0.53 m high and with five 1.20 m; the walker stopped at 0.50 m and the marble rested at 0.90 m in both.
**Concluded.** What stops a body is one cylinder in the scene file, shared by every creature. No gene touches it.
**Guessed.** That a hand would want to take the creature by a limb. Nothing here can be taken.

## What was observed, what was concluded, what is guessed

- **Observed.** The parts built and the genes read back. What `save()` wrote and returned, what `load()` returned for each file, and what was printed. The share of pixels on which each pair differs, from two standpoints, for thirteen counts. Where the walker stopped and the marble rested.
- **Concluded.** Sharing is silent. From above, 6 and 12 are not the closest pair, and the measure counts coinciding limbs. From the side the outline settles between 4 and 6 limbs. The file holds the difference from its script.
- **Guessed.** That a person would call 6 and 12 the same kind from above, and 11 and 12 too, whatever the pixels say. That is the outline's "reads as", and it was not tested.

## Unresolved

- **No eye was asked.** The border between a creature and a flower may be exactly where the outline put it, for a person. A count of pixels cannot say.
- **Coinciding limbs.** Every still has the first limb pointing the same way. With each creature turned by an angle of its own the pairs from above would change. Not run; it is the difference the lesson offers the learner.
- **The inside.** A turned creature of 12 differs from itself on 6.17% of the still with only 0.57% of outline. I take the rest to be limbs crossing in front of the trunk and each other. I did not separate it.
- **The loader's memory.** A file written over while an earlier load was in use came back stale. After the nodes that used it were freed, a load of the same path gave the new values. I saw that once and did not test when the memory is dropped.
- **An exported build** was not made, so nothing here shows what `save()` does when it cannot write.

## The decisions, in one place

| at | decision | reason |
|---|---|---|
| T1 | settle | the fault did what the outline said, and the silence was checked |
| T2 | follow | the prediction was false, and the ten numbers were multiples of one number |
| T3 | follow | the measure was counting something other than likeness: change the standpoint |
| T5 | settle | two standpoints agree on what the measure can and cannot see |
| T7 | leave open | a creature that can be taken by a limb needs a hand, and a chapter of its own |

**The decision of this note: follow twice, then settle.** The first follow asked what the number from above was made of, because ten differences that are all multiples of 1.37 are a count and not a likeness. The second changed the standpoint, and found the one place where the outline's claim shows. I settle there: the kit claims that the genome draws no border and that a standpoint does, and says that no eye was asked.

## Replay

Run on 1 October 2026, from this folder, with Godot 4.6.

```
godot --path . --xr-mode off --script res://sheet.gd
godot --headless --path . --xr-mode off --script res://verify.gd
```

The first needs a window: it photographs the creatures, writes `sheet.json`, `sheet.png` and `process.png`, and prints every number in T2 to T5. The second runs the checks, among them every observation of T1, T6 and T7, and exits 0.

## Evidence

- `sheet.json`: every pair from both standpoints, and the series from 0 to 12. `sheet.png`: the five creatures from above and from the side. `process.png`: the five steps.
- `verification.json`: the checks, with what each measured.
- `stills/`: the single stills. The folder is not tracked; `sheet.gd` makes it again.
