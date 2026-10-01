# Field note: one exponent on one sphere

1 October 2026. Observer: Claude, the session that built this kit, working from the repository and from stills. Nothing here was walked by a body in a headset, and no person looked at the stills to say which two look alike.

This is the kit's own note, in the form of [the decision and the field note](../../course/opening/FIELD_NOTE.md). It is an example of the form. Your note will have another decision in it.

## The note

```
Question:        Which two of four rim exponents look most alike from 2 m,
                 and does the lowest make the body read as unlit?
Baseline:        shader_skin.tscn of this kit: the family's member of 64 segments,
                 1 m across, in skin.gdshader; body BODY, stripes SHADE, rim SECOND,
                 rim_power 3, drift 0 in every still.
Intervention:    one uniform, rim_power: 0.5, 1, 3, 8.
Prediction:      the course outline's, written before any run (quoted below).
Observation:     3 and 8 are the closest pair, on two bodies and from two distances.
                 0.5 floods the body; the sun still shows through it. Details below.
Another cause:   the colour under the rim; the distance; the threshold of the
                 measure. The first two were tried.
Decision:        follow once, then settle.
Reason:          below.
Run it again:    the two commands at the end.
```

## The apparatus

- **Scene.** `shader_skin.tscn`. The body is a `SphereMesh` of radius 0.5 m with 64 segments and 32 rings, in a `ShaderMaterial` whose shader is `skin.gdshader`.
- **Engine.** Godot 4.6.stable.official.89cea1439, Windows, an NVIDIA GeForce RTX 3070, the Compatibility renderer.
- **What I could see.** Stills of 960 by 720 pixels made in the sheet's plain studio (a flat SKY, a white ambient light, the sun), the body alone, the camera 2 m from its middle with a 40 degree field of view, the body casting no shadow. Two stills differ at a pixel when their three channels together are more than 25 of 765 apart. A second still of the body in one flat colour says which pixels are body. A third, with `rim_colour` set to black, says which pixels the rim changed.
- **What I could not see.** An eye. "Look alike" and "reads as unlit" in this note are counts of pixels.

## The predictions, as the outline stated them

Both were written in the course outline before this kit existed.

1. "3 and 8 will look most alike from 2 m: both give a thin bright edge on a dark body. 0.5 floods the whole body with the rim colour, so it reads as unlit."
2. "a sampler2D uniform left unbound reads as white, so EMISSION from it makes the whole body glow".

## The trajectory

Each state names its parent. Status is one of continue, consolidate, branch, unresolved, stop.

### T0. Baseline

The member in the finished skin, `rim_power` 3. From the side at 2 m the body covers 29.58% of the still, 204,480 pixels.

### T1. The sampler nobody bound (parent T0, status: consolidate)

**Intervention.** `uniform sampler2D glow_map;` and `EMISSION = texture(glow_map, UV).rgb;`, and no picture handed over.
**Prediction.** The outline's second: white, and a glow on the whole body.
**Observed.** 100.00% of the body's pixels were exactly `#ffffff`. Godot logged no error and no warning. Read back, the parameter was null.
**Observed.** Bound to a picture of `FastNoiseLite`, 256 by 128, the body's mean colour was `#a2ab8e` and 0.71% of it was white.
**Concluded.** The prediction held. The fault is silent in the log and can be seen from a script: an unbound sampler reads back null.

### T2. The sheet, from the side (parent T0, status: continue)

**Observed.** Share of the still on which two exponents differ: 0.5 and 1, 28.48%; 0.5 and 3, 29.07%; 0.5 and 8, 29.12%; 1 and 3, 24.19%; 1 and 8, 24.25%; 3 and 8, 9.06%.
**Observed.** The rim changes 98.47% of the body at 0.5, 82.03% at 1, 30.73% at 3 and 6.77% at 8. It begins 0.25, 0.46, 0.82 and 0.96 of the radius from the middle (the radius outside which 95% of the changed pixels lie).
**Concluded.** The first sentence of the prediction held from this standpoint: 3 and 8 are the closest pair. They are not close: 9.06% of the still is 31% of the body.

### T3. The body under the rim, and the distance (parent T2, status: consolidate)

**Another cause.** The outline says "on a dark body", and ours is half lime. And a thin edge is a matter of pixels, so of distance.
**Intervention.** The same four with `body_colour` set to SHADE, so that the body is dark all over. Then both bodies from 5 m.
**Observed.** Dark body at 2 m: 3 and 8 differ on 10.52%, the closest pair; the other five pairs on 25.76% to 29.40%. From 5 m: 1.31% on our skin, 1.54% on the dark body, the closest pair in both.
**Concluded.** The pair is closest on both bodies and from both distances.

### T4. "Reads as unlit" (parent T2, status: unresolved)

**Intervention.** None; a second measure on the stills of T2 and T3. The sun stands to the left, so the body's left half is brighter than its right. If the body read as unlit the two halves would be alike.
**Observed.** Left half to right half, mean brightness: 1.26 at exponent 8, 1.23 at 3, 1.15 at 1, 1.11 at 0.5. On the dark body: 1.52, 1.20, 1.07, 1.04.
**Concluded.** The flood is real: at 0.5 the rim reaches 98.47% of the body. On our skin the glow covers a little more than half of the sun's left-to-right difference, not all of it. On the dark body nearly all.
**Guessed.** That an eye would call the dark body at 0.5 unlit and ours not. No eye was asked. And one ratio of two halves is a thin measure of "lit": it would also move if the stripes were not the same left and right. They are, by the shader, but I did not test the measure on a body I knew to be unlit.

### T5. Between the closest pair (parent T2, status: consolidate)

**Intervention.** Exponents 3, 4, 5, 6 and 7, each against 8, our skin at 2 m.
**Prediction.** None was written before the run.
**Observed.** 9.06%, 6.02%, 4.07%, 2.48%, 0.06%.
**Concluded.** It falls at every step, with no step that stands out until the last. Between 7 and 8 this measure sees almost nothing.
**Guessed.** That the drop from 2.48% to 0.06% is the threshold of the measure and not the skin: at 7 and at 8 the rim differs by less than 25 of 765 almost everywhere. I did not lower the threshold to see.

### T6. Four sides (parent T0, status: consolidate)

**Intervention.** The walker stood 2 m from the body on four sides and looked at it through its eyes, at 1.60 m. Each still was taken with the rim and with `rim_colour` black.
**Observed.** The rim changes 29.92%, 30.28%, 30.42% and 30.53% of the body from the front, the right, the back and the left, and begins 0.82 or 0.83 of the radius from the middle. Between the front and each other side, 97.06% to 97.53% of the rim's pixels are the same pixels of the still.
**Observed.** With the rim off, the front and another side differ on 51.99% to 71.26% of the body. The left half is 1.18 and 1.25 times as bright as the right from the front and the right, 0.87 and 0.81 from the back and the left.
**Observed.** Across the body's middle line the colour steps by 15.4 of 765 from behind and by 1.2 from in front: the seam of the UV.
**Concluded.** The clouds and the seam belong to the body, the bright half to the sun, the rim to the eye.

### T7. A body (parent T0, status: unresolved)

**Observed.** The walker's autopilot walked round the body, 1.5 m out, and arrived. Sent at the body from four sides it was blocked each time, 0.80 m from the middle.
**Observed.** A marble dropped on the top came to rest at 1.09 m, in the middle, with `grain` at 0 and at 1.
**Guessed.** That 1.09 and not 1.10, the sum of the two radii, is an overlap the physics allows between two touching bodies. The base's README has the same marble at 0.60 m on a box of 0.5 m, with no centimetre missing. I did not look further.

## What was observed, what was concluded, what is guessed

- **Observed.** The share of pixels on which each pair of exponents differs, on two bodies and from two distances. How much of the body the rim changes. The brightness of the two halves. The white body and the silent log. The rim's pixels from four sides. Where the walker stopped and the marble came to rest.
- **Concluded.** 3 and 8 are the closest pair by this measure and still differ on a third of the body. 0.5 floods the body. An unbound sampler is white and silent. The rim is the same pixels of the still from every side, and the skin under it is not.
- **Guessed.** That a person would agree with the pixel counts. That "unlit" is what the dark body at 0.5 looks like. That one exponent reads as rubber and another as glass, which is the outline's claim and was not tested at all.

## Unresolved

- **No eye was asked.** Every "alike" above is pixels.
- **"Reads as unlit"** was measured with one ratio and held in part. A better measure would compare with a body that is unlit by construction.
- **Rubber or glass.** The claim names two materials. I measured the width of an edge.
- **One graphics card.** `hash()` takes the sine of a large number, and cards differ there. The clouds may be other clouds elsewhere; the rim should not be.
- **The centimetre** under the marble.
- **Two eyes.** In a headset each eye is a camera and would have a rim of its own. Not run.

## The decisions, in one place

| at | decision | reason |
|---|---|---|
| T1 | settle | the planted fault is real and silent, as the outline said |
| T2 | follow | the prediction said "on a dark body" and ours is half lime |
| T3 | settle | the pair stayed closest on both bodies and from both distances |
| T4 | leave open | "unlit" needs a measure I trust, and an eye |
| T5 | follow once | the closest pair still differed on a third of the body |
| T5 | settle | the series falls at every step; the last drop is the measure's own |
| T7 | leave open | a centimetre is a lesson about colliders, not about skins |

**The decision of this note: follow once, then settle.** I followed the cause the prediction itself named, the dark body, because a pair that is closest on one skin has been tested once. It stayed closest. I followed the pair inward once more, because 9.06% is not alike, and found a slope with no step in it. I settle there: the kit claims that 3 and 8 are the closest pair and says how far apart they still are, and that 0.5 floods the body without making it unlit.

## Replay

Run on 1 October 2026, from this folder, with Godot 4.6.

```
godot --path . --xr-mode off --script res://sheet.gd
godot --headless --path . --xr-mode off --script res://verify.gd
```

The first needs a window: it photographs the bodies, writes `sheet.json`, `sheet.png`, `process.png` and `place.png`, and prints every number in T1 to T6. The second runs 48 checks, among them the silent sampler of T1 and the walker and marble of T7, and exits 0.

## Evidence

- `sheet.json`: every pair, body and distance; the rim's reach; the series against 8; the four sides; the seam; the planted bug.
- `sheet.png`: the four exponents on our skin and on the dark body. `place.png`: the four sides. `process.png`: the strip.
- `verification.json`: the checks, with what each measured.
- `stills/`: the single stills. The folder is not tracked; `sheet.gd` makes it again.
