# Field note: four kinds of leg on uneven ground

1 October 2026. Observer: Claude, the session that built this kit, working from the repository and from stills. Nothing here was walked by a body in a headset, and no person looked at the stills to say which two look alike.

This is the kit's own note, in the form of [the decision and the field note](../../course/opening/FIELD_NOTE.md). It is an example of the form. Your note will have another decision in it.

## The note

```
Question:        How many parts does a leg need to meet uneven ground,
                 and which two kinds of leg look most alike on it?
Baseline:        legs.tscn of this kit: a creature on four legs of 0.8 m, 3 parts each,
                 standing at x = 1.7 on the borrowed ground, heading zero.
Intervention:    one field, segments: 1, 2, 3, 6. The leg's length stays 0.8 m.
Prediction:      the course outline's, written before any run (quoted below).
Observation:     3 and 6 are the closest pair from four comparisons; after a walk
                 by 0.03 of a percent. One part meets no ground. Details below.
Another cause:   the standpoint; the ground; the history of the pose. Three were tried.
Decision:        follow once, then settle.
Reason:          below.
Run it again:    the commands at the end.
```

## The apparatus

- **Scene.** A creature made by `creature.gd`: a trunk and four instances of `leg.tscn`, each a chain of `segments` parts that follows its foot and is carried back to its hip. The feet's places come from rays and do not depend on the legs.
- **Engine.** Godot 4.6.stable.official.89cea1439, Windows, an NVIDIA GeForce RTX 3070, the Compatibility renderer.
- **What I could see.** Stills of 960 by 720 pixels, the eye 2.2 m from the creature and 0.5 m above its middle, or straight above it, the creature's shadow off. Two stills differ at a pixel when their three channels together are more than a tenth of full scale apart. And numbers read from the scene: where each leg ends, where its foot's place is, the angle between two parts.
- **What I could not see.** An eye. "Look alike" in this note is a count of pixels.

## The prediction, as the outline stated it

"3 and 6 will look most alike on uneven ground: both bend smoothly around a step. 1 cannot bend at all, so its foot hangs above or sinks below the ground."

## The trajectory

### T0. Baseline

Three parts, standing for three seconds where it was put down. Feet at 0.000, 0.154, 0.218 and 0.000 m; body at 0.493 m; hips 0.445 to 0.605 m from their feet's places; every leg's end on its place to the millimetre.

### T1. The sheet, from the side (parent T0, status: continue)

**Observed.** Share of the still on which two creatures differ: 1 and 2, 6.55%; 1 and 3, 6.66%; 1 and 6, 6.59%; 2 and 3, 5.44%; 2 and 6, 4.76%; 3 and 6, 3.03%.
**Observed.** With one part every leg ends past its place, under the ground, by 0.195, 0.313, 0.355 and 0.195 m. With 2, 3 and 6 parts: 0.000 m, four times.
**Concluded.** The closest pair is 3 and 6. One part cannot meet this ground. It sinks; it never hangs above, because 0.8 m is more than every distance from hip to foot here.

### T2. Another standpoint, another ground (parent T1, status: continue)

**Another cause.** One camera, and one place on the ground.
**Intervention.** The same four from straight above; and the same four on the flat floor, from the side.
**Observed.** From above 3 and 6 differ on 0.50%, the other pairs on 1.40% to 2.84%. On the flat floor 3 and 6 differ on 1.94%, the other pairs on 4.42% to 6.84%.
**Concluded.** The pair is closest from both, and on both grounds. The uneven ground is not what makes it so: it pushes the two apart, from 1.94% to 3.03%.

### T3. The reason the outline gave (parent T1, status: branch)

**Intervention.** Measure the sharpest bend between two parts that follow each other, over the four legs.
**Prediction.** If 3 and 6 "both bend smoothly", both bend less sharply than 2.
**Observed.** 112.4° with 2 parts, 113.2° with 3, 74.9° with 6. On the flat floor 96.7°, 76.6° and 47.8°.
**Concluded.** On the uneven ground a leg of 3 bends as sharply as a leg of 2. The outline's reason is false there. What 3 and 6 share is an outline in the still, not a way of bending.

### T4. The history of the pose (parent T1, status: consolidate)

**Another cause.** The follow loop starts each frame from the pose the last frame left. A creature put down and left to stand has one history. Would the pair be closest with another?
**Intervention.** The same place, reached by walking 1.2 m and then standing for three seconds. The body ended at x = 1.673 with all four values, 2.7 cm from the place of T1, with its feet at most 2 mm higher.
**Prediction.** 3 and 6 stay the closest pair; the gap narrows.
**Observed.** 3 and 6 differ on 4.61%, 2 and 6 on 4.64%, 2 and 3 on 4.67%. The sharpest bend is 112.4°, 111.0° and 165.0°: in a leg of 6, one part lies folded back along the one before it.
**Concluded.** The pair is still the closest, by 0.03 of a percent, which is about 200 pixels of 691,200. I would not defend that order. The same feet on the same ground give other legs after a walk.

### T5. Walking (parent T0, status: unresolved)

**Observed.** Over the uneven ground the legs' ends were, on average, 0.339 m from their feet's places with 1 part, 0.006 m with 2, 0.008 m with 3, 0.005 m with 6. The creature walked 2.05 m in 6 seconds with all four.
**Observed.** Of 10 places along every part, under the ground by more than 3 cm: 24.9% with 1 part, 0.0% with 2, 0.0% with 3, 3.5% with 6.
**Observed.** The same count from a start half a metre further on: 26.9%, 0.6%, 0.7% and 4.9%.
**Concluded.** In both walks the leg of 6 has more of itself under the ground than the legs of 2 and 3. Two walks are not many.
**Guessed.** That a leg of many parts trails its last parts along the ground behind the foot, and that the share depends on where in its stride the creature meets a bump. I did not test this.

## What was observed, what was concluded, what is guessed

- **Observed.** The share of pixels on which each pair differs, from the side at rest, from above, on the flat floor and after a walk. Where each leg ends. The sharpest bend. The share of the legs under the ground while walking.
- **Concluded.** One joint is what decides whether the foot meets its place: 2, 3 and 6 parts all do, 1 does not. 3 and 6 are the closest pair by this measure, clearly from rest and barely after a walk. They do not both bend smoothly.
- **Guessed.** That a person would agree with the pixel count. That the fold in the leg of 6 comes from the foot's lift and glide, which pulls the last part forward faster than the parts above can follow. Neither was tested.

## Unresolved

- **No eye was asked.**
- **The order after a walk** rests on 0.03 of a percent. One other walk was not tried.
- **The fold of 165°.** I saw it and did not find out which step of the walk makes it.
- **A leg straight over its place.** The loop keeps a straight chain straight, so a leg that hangs exactly over its foot's place never bends. The creature's hips are turned, and it does not arise there. It is not repaired.

## The decisions, in one place

| at | decision | reason |
|---|---|---|
| T2 | follow | the prediction had held from one camera on one ground |
| T3 | branch | the pair was right and the reason could be measured apart from it |
| T4 | follow once more | every still so far shared one history: put down and left to stand |
| T4 | settle | the pair stayed closest, and the claim now says by how little |
| T5 | leave open | two walks, and the count moved with the start; it is the difference the lesson offers the learner to follow |

**The decision of this note: follow once, then settle.** I followed the one thing all my stills shared, a creature that had never walked, because a loop that keeps its last pose makes the pose a matter of history. The order held, by a hair. I settle on a claim that does not need the order: one joint decides which grounds a leg can meet, and past that the number of parts decides a look that depends on the way there.

## Replay

Run on 1 October 2026, from this folder, with Godot 4.6.

```
godot --path . --xr-mode off --script res://sheet.gd
godot --headless --path . --xr-mode off --script res://verify.gd
```

The first needs a window: it photographs the four creatures and writes `sheet.png`, `process.png` and `sheet.json`, which holds every number of T0 to T4. The second runs 107 checks, among them the walk of T5, and exits 0.

## Evidence

- `sheet.json`: every pair from four comparisons; for each value the feet, the hips, the legs' ends and the sharpest bend. `sheet.png`: three rows of four.
- `verification.json`: the checks, with what each measured; `axis` holds T5.
- `stills/`: the single stills. The folder is not tracked; `sheet.gd` makes it again.
