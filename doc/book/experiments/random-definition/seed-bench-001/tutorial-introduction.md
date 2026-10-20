# Keep the values; change their spatial assignment

This continues Random Definition's seed lesson. The question is no longer whether a random number can make a picture. What changes when the same retained values become colour, height, size or orientation? Predict which relationships will survive a change of assignment. An unhelpful, confusing or visually dull comparison is a result too.

The user asked to see flat colour, bars and their combination at once, then clarified that random values should control object scaling and rotation. All five views now appear together. The 48 values are sixteen ordered triples, not one scalar per cell. Colour uses the three channels directly. The spatial views use their mean `u = (a+b+c)/3`. This distinction matters: the mean discards channel order, so differently coloured triples can produce the same height, scale and turn.

Run `python doc/book/experiments/random-definition/seed-bench-001/launch.py` from the repository. It opens a separate instance of the existing museum beside the study. The original hall instrument stays nearby. The launcher uses desktop mode; physical headset usability remains a separate test. For an XR encounter, mount the same scene in the museum at hall-local `(10.5,0,18.5)`, Y rotation `-90` degrees and unit scale. The printed scripts use the supplied XRTools hand/ray controls and the shared `push_button_front.tscn` from the interactable demo.

The back row shows FLAT, BARS and COMBO. The front row shows SCALE and ROTATE. Each contains the same sixteen cells in the same row-major order, `i = 4*row + column`. Corresponding cells share their input triple. Different viewing positions are not identical retinal conditions; move around the apparatus as well as comparing it from the initial viewpoint.

| View | Assignment | What stays fixed |
| --- | --- | --- |
| FLAT | RGB = `(a,b,c)` | Block height 4 cm |
| BARS | Neutral colour; length `0.04 + 0.12*u` metres | Width/depth 9 cm; bottom 8 cm above tray |
| COMBO | Same RGB as FLAT and same geometry as BARS | All sampled values |
| SCALE | Neutral cube side `0.09*(0.35+0.65*u)` metres | Cell centre XZ and bottom |
| ROTATE | Neutral rectangular piece, yaw `360*u` degrees | Dimensions 9 x 4 x 4 cm; centre and bottom |

The turn marker identifies one end. Rotation is periodic: zero and a full turn look identical. The long rectangular footprint makes rotation visible and fits within its cell at every angle. Its widest rotated extent is less than the 10.5 cm pitch. In SCALE, all three dimensions shrink together; the cube is between 35% and 100% of its 9 cm reference size. These two panels use different fixed shapes to make their respective changes visible; comparing them does not isolate one geometric variable.

For the bar views, set both `mesh.size.y = h` and `centre.y = 0.08 + h/2`. The bottom stays fixed while the top rises. FLAT/BARS/COMBO retain 1.5 cm gutters and fill the dark inset. Each now has a 54 cm outer frame and 46 cm dark inset, making the border broader and more visible. Scale and rotation change the apparent gaps as part of the experiment.

Work through invented black, white, red and green triples before looking at the seed: their means are `0`, `1`, `1/3`, `1/3`. Bar lengths are 4, 16, 8 and 8 cm. Scale factors are `0.35`, `1`, about `0.567`, `0.567`; turns are 0, 360, 120 and 120 degrees. These are arithmetic examples, not the first draws of seed 42. What can height tell you about colour, and what has it lost?

All controls remain on one rectangular-button board. Hand press or controller ray activates a cap. CLOSE hides the board without clearing a result; CONTROLS reopens it. The actions are RESET 42 (F1), CURRENT VIEWS (F2), KEEP (F3), REPLAY (F4), EXPORT (F5), IMPORT (F6), CLEAR KEPT (F7) and NEXT SEED (F8). RESET 42 deliberately regenerates that deterministic baseline. CURRENT VIEWS reuses stored values and explicitly forks an earlier saved recipe into this five-view version. The views themselves are simultaneous, not toggles.

Use the research cycle:

1. Record seed 42, the current recipe and a prediction about one corresponding cell across the five views.
2. Compare FLAT/COMBO to examine added height; compare BARS/COMBO to examine added colour. Describe what the other two assignments make visible or obscure.
3. KEEP, then EXPORT. NEXT SEED makes new seeded draws. REPLAY must return to the stored values and recipe.
4. CLEAR KEPT, then IMPORT. Close and reopen the study and import again. The file is `seed-bench-001.json` in Godot's user data folder, available through **Project → Open User Data Folder** in the editor.
5. Reconstruct the three printed scripts in a separate folder. Explain the mean, fixed bottom and scale/turn formulas; record what code you borrowed or needed help with.
6. Let an observation choose the next change. For example, propose a first-channel assignment only if it helps investigate what the mean obscures. Preserve the recipe before revising it. Return the account independently to both tutorial and final; either can initiate the next experiment.

Schema v3 records the five-view recipe and its parameters. Older v1 floating cubes and v2 bar layouts still import and render with their original cell geometry. CURRENT VIEWS forks them with a parent ID, preserving their values and the kept original. Earlier source versions and outcomes remain recoverable.

KEEP makes a deep copy. Import validates the complete record before changing state. Seed and generator state remain decimal strings; exact float bytes are authoritative because decimal JSON parsing shifted some values in the first run. An invalid import leaves current and kept results intact. Replay never resumes an RNG. Another seeded acquisition is deterministic; neither replay nor NEXT SEED establishes genuinely unpredictable randomness. See [observations](observations.md) and Godot's [RNG](https://docs.godotengine.org/en/4.6/classes/class_randomnumbergenerator.html) and [JSON](https://docs.godotengine.org/en/4.6/classes/class_json.html) documentation.

The complete files below are extracted and executed by the scripted reconstruction check. That verifies printed code, not a person's understanding. Keep human reconstruction, physical VR and performance evidence separate.
