# Field note: four spheres on the sweep sheet

1 October 2026. Observer: Claude, the session that built this kit, working from the repository and from stills. Nothing here was walked by a body in a headset, and no person looked at the stills to say which two look alike.

This is the kit's own note, in the form of [the decision and the field note](../../course/opening/FIELD_NOTE.md). It is an example of the form. Your note will have another decision in it.

## The note

```
Question:        Which two of the four members look most alike from 2 m,
                 and what is their difference made of?
Baseline:        family.tscn of this kit: four members of the class Globe, 1 m across,
                 each alone on the sheet; segments 16, rings 8 is the class's default.
Intervention:    one field, segments: 4, 8, 16, 64, with rings at half of it.
Prediction:      the course outline's, written before any run (quoted below).
Observation:     16 and 64 are the closest pair from four standpoints. Details below.
Another cause:   the smooth normals; the standpoint; the turn of the member;
                 the distance; the threshold of the measure. Four were tried.
Decision:        follow once, then settle.
Reason:          below.
Run it again:    the three commands at the end.
```

## The apparatus

- **Scene.** `family.tscn`. Each member is a `SphereMesh` of radius 0.5 m, built by `globe.gd` from two whole numbers.
- **Engine.** Godot 4.6.stable.official.89cea1439, Windows, an NVIDIA GeForce RTX 3070, the Compatibility renderer.
- **What I could see.** Stills of 960 by 720 pixels, one member alone, the camera 2 m from its middle with a 40 degree field of view, the light's shadow off. Two stills differ at a pixel when their three channels together are more than a tenth of full scale apart. A second still of each member in one flat colour says exactly which pixels are body.
- **What I could not see.** An eye. "Look alike" in this note is a count of pixels.

## The predictions, as the outline stated them

Both were written in the course outline before this kit existed.

1. "16 and 64 will look most alike at 2 m: the silhouette of 16 segments misses the true circle by 1 - cos(11.25 deg), about 2% of the radius. 4 is not a coarse sphere but another body, close to an octahedron."
2. "the sweep sets rings from a text field as the string '16'; set() on a typed int refuses it in silence and four identical spheres come back."

## The trajectory

Each state names its parent. Status is one of continue, consolidate, branch, unresolved, stop.

### T0. Baseline

One member, 16 segments and 8 rings: 288 triangles listed, 256 with area.

### T1. The silent refusal that was not there (parent T0, status: branch)

**Intervention.** `set("segments", "4")` on a member, the field typed `int`.
**Prediction.** The outline's second: refused in silence, the field stays 16.
**Observed.** The field read 4. Godot printed nothing.
**Observed, widening.** `"sixteen"` and an empty text became 0. `"4 8 16 64"` became 481664. 3.5 became 3, `true` became 1. A `Vector3`, a list and `null` left the field unchanged. A field typed `String` handed the number 16 was left unchanged. A name the class does not have, `set("radial_segments", 4)`, changed nothing. No line was printed for any of these.
**Concluded.** The prediction was false for a text on an `int`. `set()` converts what it can and refuses the rest, in silence both ways. The refusal the outline had in mind exists in the other direction, a number on a `String`.
**Decision.** Follow. **Reason.** The lesson needed a fault that is real. The wrong name is one: it gives four identical members under four different plates.

### T2. The sheet, from the side (parent T0, status: continue)

**Observed.** Share of the still on which two members differ: 4 and 8, 10.54%; 4 and 16, 14.08%; 4 and 64, 15.27%; 8 and 16, 3.73%; 8 and 64, 5.17%; 16 and 64, 0.85%. The body covers 29.58% of the still.
**Observed.** Of the 0.85%, 0.73% is rim, where one body is and the other is not: a band 3.17 pixels wide on average. Inside the outline they differ on 0.11%.
**Concluded.** The outline's first prediction held from this standpoint: 16 and 64 are the closest pair.

### T3. Other standpoints (parent T2, status: continue)

**Another cause.** One camera. A pair can be close from one place and far from another.
**Intervention.** The same stills from straight above, and from the side with each member turned half a segment.
**Observed.** From above 16 and 64 differ on 0.99%, turned on 0.76%. They are the closest pair in both. From above the outline of 16 fell short of its widest point by 2.06% of the radius; the member of 64 read 0.49%.
**Concluded.** The prediction held from three standpoints. The arithmetic, 1.92%, is within a pixel of what was measured. The measure cannot read below about half a percent.

### T4. Lit flat (parent T3, status: consolidate)

**Another cause.** All three standpoints shared one thing: `SphereMesh` hands the light a smooth normal at every corner. The likeness might be the shading and not the count.
**Intervention.** The same corners and triangles with every triangle lit flat. Nothing else changed.
**Prediction.** 16 and 64 stay the closest pair; the difference between them grows.
**Observed.** 16 and 64 differ on 4.65% of the still: 0.73% on the rim, as before, and 3.92% inside. They are still the closest pair. 8 and 16 went from 3.73% to 13.10%.
**Concluded.** The pair is closest either way. With smooth normals most of the likeness is shading: the rim is under a fifth of what separates the two when lit flat.

### T5. Distance, and the longer series (parent T2, status: consolidate)

**Observed.** The rim between 16 and 64 is a band of 3.41 pixels from 1.5 m, 3.17 from 2 m, 1.72 from 4 m and 0.65 from 8 m.
**Observed.** Against 64, from the side: 4 segments 15.27%, 6 7.70%, 8 5.17%, 12 2.21%, 16 0.85%, 24 0.29%, 32 0.19%, 48 0.04%.
**Concluded.** The difference falls at every step. Nothing in these numbers marks 16 as a step. The outline's claim, "above about 16 segments a sphere stops paying visibly", names a distance and a still size as much as a count.

### T6. The octahedron (parent T2, status: consolidate)

**Intervention.** A member with 4 segments and one ring, beside the member of 4, which has two.
**Observed.** They differ on 9.06% of the still from the side and 4.83% from above. The member of 4 and the member of 8 differ on 10.54% and 11.84%. The octahedron has 8 triangles with area, the member of 4 has 16.
**Concluded.** "Close to an octahedron" is half right. The member of 4 is nearer to the octahedron than to its sibling, and it is not one: with the rings at half the segments it has a square band between two pyramids.

### T7. A body (parent T0, status: unresolved)

**Observed.** The marble dropped over a member fell through it and came to rest on the ground at 0.10 m, inside the mesh. With a body made by `create_trimesh_collision()` and the marble dropped over the middle, it came to rest at 1.10 m on all four members, on the point of the member of 4 as well. Dropped 22 cm to the side it rolled off all four and left the ground.
**Guessed.** That the marble stays on a point because nothing in the drop pushes it sideways: the numbers are exact where a hand is not. I did not test this.

## What was observed, what was concluded, what is guessed

- **Observed.** The triangle counts. What `set()` left in a field for each value handed to it, and that nothing was printed. The share of pixels on which each pair differs, from four standpoints and four distances. Where the marble came to rest.
- **Concluded.** 16 and 64 are the closest pair by this measure. Their likeness is mostly smooth shading. The member of 4 is another body, and not the octahedron. A text handed to a typed `int` by `set()` is converted, not refused.
- **Guessed.** That a person standing 2 m away would agree with the pixel count. That a three-pixel rim is seen by some eyes and not by others. Neither was tested.

## Unresolved

- **No eye was asked.** Every "look alike" above is pixels.
- **The band from 1.5 m.** From 2 m to 1.5 m the body grows by a third in the still, and the rim band grew from 3.17 to 3.41 pixels, less than a tenth. I did not find out why.
- **Two fields moved together.** Segments and rings changed at once in every member. Which of the two the outline needs more was not separated. That is the difference the lesson offers the learner to follow.
- **The sphere of 481664 segments** was never built. The class's two `clampi` lines are there because of it; what Godot does without them was not run.

## The decisions, in one place

| at | decision | reason |
|---|---|---|
| T1 | follow | the lesson's planned fault was not real, and a sheet that cannot fail teaches nothing |
| T3 | follow | the prediction had held from one camera only |
| T4 | follow once more | three standpoints shared smooth normals; change that one thing |
| T4 | settle | the pair stayed closest and the difference is now explained: rim 0.73%, shading the rest |
| T7 | leave open | a marble on a point is worth a lesson of its own, not a line in this one |

**The decision of this note: follow once, then settle.** I followed the one cause that all my standpoints shared, the smooth normals, because a prediction that holds three times from stills made the same way has been tested once. It held a fourth time, lit flat, and showed what the likeness is made of. I settle there: the kit claims that 16 and 64 are the closest pair and says why, and nothing I could measure next would change either sentence.

## Replay

Run on 1 October 2026, from this folder, with Godot 4.6.

```
godot --headless --path . --xr-mode off --import
godot --path . --xr-mode off --script res://sheet.gd
godot --headless --path . --xr-mode off --script res://verify.gd
```

The first lists the named class. The second needs a window: it photographs the members, writes `sheet.json`, `sheet.png` and `process.png`, and prints every number in T2 to T6. The third runs 56 checks, among them every row of T1 and both drops of T7, and exits 0.

## Evidence

- `sheet.json`: every pair, standpoint and distance. `sheet.png`: the four members from the side, from above and lit flat.
- `verification.json`: the checks, with what each measured.
- `stills/`: the single stills. The folder is not tracked; `sheet.gd` makes it again.
