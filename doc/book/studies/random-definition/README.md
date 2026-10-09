# Random Definition — a pattern that returns

A standalone Godot 4.6 desktop study. Day Zero's editor/run workflow is assumed. No Ada assets, plugins, XR rig, API keys or network access are needed.

Open this `project.godot`. It starts with one cube and `study.gd`, the first lesson. Follow `TUTORIAL.md`. Edit that script; the six complete versions in `steps/` are recovery points. Copy a step's contents into `study.gd` to start from that point. `study.tscn` remains the main scene throughout.

REPLAY or Space calls the script's `replay()` function. Before you add a fixed seed, it continues the generator. Later the function resets the seed before drawing. A run can repeat a colour by chance; difference is not guaranteed on every request.

`display.gd` supplies one cube, a 4 × 4 grid or a pair of grids, plus separate materials, camera framing and replay input. Arrays are ordered left to right, bottom row first, like the museum instrument. The helper draws no random numbers. The lesson owns the generator, seed, draw order and RGB assignment. The museum uses 8 × 8 grids; the study uses 4 × 4 to keep individual cells easy to follow.

Step 6 returns to step 4's matched beginning and exchanges red and blue only on the right. It does **not** retain step 5's unused draw. Those are two separate comparisons.

For verification: `godot --path . --headless --script res://verify.gd`. A rendered run additionally captures each stage. Results describe desktop software checks, not a learner or headset trial.
