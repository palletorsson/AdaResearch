# Field note: three bodies on one sheet

1 October 2026. Observer: Claude, the session that built this kit, working from the repository and from stills. Nothing here was scanned, nothing was drawn in a headset, and no person looked at the stills to say which two look alike.

This is the kit's own note, in the form of [the decision and the field note](../../course/opening/FIELD_NOTE.md). It is an example of the form. Your note will have another decision in it.

## The note

```
Question:        Which two of the three bodies look most alike from 2 m,
                 and what sets the third apart: its outline or its count?
Baseline:        collage.tscn of this kit: the solid by hand, stretch 1.53 and cut 0.38,
                 each body alone on the sheet, all three in the sheet's one paint.
Intervention:    one thing, how the body was made: by hand, drafted, found.
Prediction:      the course outline's, written before any run (quoted below).
Observation:     by hand and drafted are one picture. The found body is the odd one:
                 by 5 pixels of outline and by 293 times the triangles. Details below.
Another cause:   the material; the standpoint; the shading; the way the found body
                 itself was made. Three were tried. The fourth cannot be tried here.
Decision:        settle for the two made bodies; leave the found one open.
Reason:          below.
Run it again:    the three commands at the end.
```

## The apparatus

- **Scene.** `collage.tscn`. Three bodies on the sweep sheet.
- **Engine.** Godot 4.6.stable.official.89cea1439, Windows, an NVIDIA GeForce RTX 3070, the Compatibility renderer.
- **By hand.** `solid.gd`: Point Cube's eight corners, pulled 1.53 along one diagonal, stood on it, the two end corners cut at 0.38 of each edge. The two numbers and the order are the hall's (`DurerPolyhedron.gd`).
- **Drafted.** `drafted_solid.gd`: the answer of a second AI assistant of my own kind to three lines of instruction and nothing else. It was asked once, told to use no tools, and its answer was kept byte for byte.
- **Found.** `found.gltf`: not a scan. A script of mine made it from the solid above: every triangle cut into 324 small ones, the skin welded and smoothed three times, its corners pushed in and out by up to 4 mm and slid along the skin by up to about a centimetre, the foot left out with a ragged rim, a ragged patch taken out of the top, written in centimetres around an origin 37 cm, 4.3 cm and 22 cm off the foot.
- **What I could see.** Stills of 960 by 720 pixels, one body alone, the camera 2 m from the middle of its place with a 40 degree field of view, the light's shadow off. Two stills differ at a pixel when their three channels together are more than a tenth of full scale apart. A second still of each body in one flat colour says exactly which pixels are body.
- **What I could not see.** An eye. A scan. A hand in a headset. "Look alike" in this note is a count of pixels.

## The predictions, as the outline stated them

Both were written in the course outline before this kit existed.

1. "The hand-coded and the AI-coded will look most alike: same instruction, same primitives. The scan is the outlier by triangle count, not by silhouette."
2. "planted bug: the import arrives 100 times too large (centimetres against metres): read its AABB in the Inspector before moving the camera"

## The trajectory

Each state names its parent. Status is one of continue, consolidate, branch, unresolved, stop.

### T0. Baseline

**Observed.** The solid by hand lists 20 triangles and has 12 corners, 18 edges and 8 flat faces. It stands 0.989 m high in a box 0.789 m wide and deep. Its corners lie within 0.08 mm of the hall's construction for the same cube.

### T1. The drafted answer (parent T0, status: continue)

**Intervention.** Three lines to an assistant: what to write, what to keep, what would prove it wrong.
**Prediction.** The outline's first sentence: the two will look most alike.
**Observed.** The answer ran with no message. 20 triangles, all facing outward. Its twelve corners lie within 0.0001 mm of ours. From the side, from above and lit flat, the two stills differ on 0.00% of the frame.
**Observed.** It is written another way: 36 corners and a list of 60 corner numbers through `ArrayMesh`, where ours hands `SurfaceTool` 60 corners and no numbers.
**Concluded.** The first sentence held. Its reason, "same primitives", did not: the primitives differ and the picture does not.

### T2. Where the two part (parent T1, status: consolidate)

**Another cause.** A likeness of 0.00% may only mean that both were looked at where the three lines had spoken.
**Intervention.** Values the lines did not name: a cut of 0.9, a stretch of 3, a cut of 0.
**Observed.** Cut 0.9: ours wrote 0.5 into its field and stood 0.883 m; the drafted one kept 0.9 and stood 0.530 m; the stills differ on 14.88% of the frame. Stretch 3: ours built 2, the drafted one 3. Cut 0: ours lists 20 triangles, 12 with area; the drafted one lists 18.
**Concluded.** One body at the values the lines named, two bodies outside them. Each class drew its own limits and neither was asked to.

### T3. The found body arrives (parent T0, status: continue)

**Intervention.** `load("res://found.gltf").instantiate()`, added and hung on the sheet, with nothing else done to it.
**Prediction.** The outline's second: 100 times too large.
**Observed.** Its box read `[P: (-0.804559, 4.3, -59.32127), S: (75.61543, 99.03934, 75.02676)]`. In the room it stood 99.04 m high, its lowest point 4.30 m above the ground, its middle 42.95 m from its plate. None of its 2,993 corners was in the camera's view. The picture changed on 0.57% of the tile: a plate, and no body. Godot printed nothing.
**Observed.** With the origin repaired and the unit left at 1.0, a shadow with a ragged edge lay over most of the room and no body was in the picture.
**Concluded.** The prediction held. The outline did not say what it looks like: it looks like nothing, and the output still says `found: 5851 triangles`.
**Not watched.** The Inspector. I read the box with `print()`.

### T4. The found body on the sheet (parent T3, status: continue)

**Observed.** With a unit of 0.01 and its foot at its origin it stands 0.990 m high. Against the solid by hand it differs on 2.91% of the still from the side: 0.96% is outline, a band 5.00 pixels wide, and 1.95% inside. It lists 5,851 triangles, and the renderer drew every one of them from 2, 4, 8 and 16 m. 137 of its edges belong to one triangle only, in two rings.
**Concluded.** By this measure the found body is the odd one on every count, a little by its outline and 293 times by its triangles.

### T5. Other causes (parent T4, status: consolidate)

**The material.** In the material its file brought, it differs from the solid on 20.30% of the still, every pixel of the body. In the sheet's paint, 2.91%. The table uses the paint.
**The standpoint.** From above: 3.61%, of which 2.04% is outline, a band of 12.20 pixels. The hole in its top shows from there.
**The shading.** Lit flat: 2.68%, the outline the same 0.96%.
**Concluded.** The order of the three pairs is the same from all three standpoints. The size of the difference depends on what the body wears and where I stand.

### T6. The cause I cannot remove (parent T4, status: unresolved)

**Observed.** I made the found body from the solid. How round its edges are, how deep its lumps, and where its holes lie are my numbers.
**Concluded.** Its outline was near because I built it near. The second sentence of the prediction, about a scan, was not tested by this kit.

### T7. A body (parent T0, status: unresolved)

**Observed.** With no collider the marble falls through the solid and through the found body and lies on the ground at 0.10 m. With bodies from `create_trimesh_collision()`, dropped over the middle, it rests on the solid's top at 1.08 m; on the found body it does not stay: it rolls off and leaves the ground.
**Guessed.** That the rounded top and the edge of the hole tip it. I did not separate the two.

### T8. The build (parent T3, status: stop)

**Observed.** A room with the solid and the found body was exported for Windows in 4 seconds. The build started with a window and without one, ran 300 frames and printed the arrival line. The pack holds `found.gltf.import` and the scene made at import, and not `found.gltf`.
**Not done.** No other machine, no headset.

## What was observed, what was concluded, what is guessed

- **Observed.** The triangle and corner counts. The boxes. The share of pixels on which each pair differs, from three standpoints, in two materials. What each class did with a cut of 0.9. Where the marble came to rest. What the build printed.
- **Concluded.** By hand and drafted are the closest pair, and at the named values the same body. The import arrives 100 times too large and off its origin, and shows as nothing. A stand-in made from the solid is near the solid by its outline and far by its count.
- **Guessed.** That a person standing 2 m away would agree with the pixel count. That a real scan of a paper model of this solid would have an outline about this near. That another assistant, or the same one asked again, would answer as this one did. None was tested.

## Unresolved

- **No scan.** The claim about scans is open.
- **One answer.** The drafter was asked once. It is of the same kind as the session that wrote the lesson and the three lines, so the two routes are not as independent as two people would be. It reported using no tools. The run's record counts one tool call, which handing the answer back needs. I did not read its transcript.
- **The marble on the found body.** Why it rolls off was not separated.
- **Coarser copies.** Godot's import has *Generate LODs* on by default. From 2 to 16 m the renderer drew all 5,851 triangles. I did not find out whether coarser copies were made or when they would be drawn.
- **Sculpted in VR.** The outline's fourth value was not made. A script cannot stand in for a hand.

## The decisions, in one place

| at | decision | reason |
|---|---|---|
| T1 | follow | a difference of 0.00% says the comparison may have been made where nothing could differ |
| T2 | settle | the two are one body where the lines spoke, and I know where they part |
| T3 | follow | the planted fault had to be real before a lesson could stand on it |
| T5 | follow, three times | each cause was one change away |
| T6 | leave open | a body made from the solid cannot test a sentence about scans |
| T7 | leave open | one drop is an observation, not an account |

**The decision of this note: settle for the made pair, leave the found body open.** The made pair is settled because I followed the one thing a perfect likeness hides, the values nobody named, and found where the two bodies part. The found body is left open because the kit's measurement of it is a measurement of my own script, and I would rather say that than report the prediction as confirmed.

## Replay

Run on 1 October 2026, from this folder, with Godot 4.6.

```
godot --headless --path . --xr-mode off --import
godot --path . --xr-mode off --script res://sheet.gd
godot --headless --path . --xr-mode off --script res://verify.gd
```

The first lists the named classes and imports `found.gltf`. The second needs a window: it photographs the bodies, writes `sheet.json`, `sheet.png` and `process.png`, and prints every number in T1, T2, T4 and T5. The third runs 59 checks, among them T0, T3 and T7, and exits 0.

## Evidence

- `sheet.json`: every pair and standpoint. `sheet.png`: the three bodies from the side, from above and lit flat.
- `verification.json`: the checks, with what each measured.
- `drafted_solid.gd`: the answer. The three lines are in TUTORIAL.md, as they were sent.
- `stills/`: the single stills. The folder is not tracked; `sheet.gd` makes it again.
