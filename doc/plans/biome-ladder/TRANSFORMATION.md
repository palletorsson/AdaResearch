# B11 — cover carried forward

Implemented 2026-10-13 in `commons/hazards/biome_ladder/ladder_encounter.gd`.

The six tall shelters now return in Transformation, Arrays and Colour. The entrance pair of boxes stays still. Four spheres move one metre forward and back from their starting places; the two far boxes turn; the two cylinders grow uniformly from 2 to 2.4 m high. Cones remain still. Each moving form carries one operation.

Scaling raises a cylinder's centre as its size changes, keeping its base on the floor. Visible meshes and collision shapes change together. At maximum growth the cylinders leave 1.88 m between them; the central passage and access to pickups were checked throughout the motion cycle. Two pickup positions moved inward, away from the larger shelters.

Primitives and Transformation share the white floor with thin black outlines. Arrays introduces the checkerboard; Colour retains its disco floor. Skull health, player health, projectile speed and saved ability progression retain their previous rules.

## What the tests establish

- `tools/probes/biome_transformation_cover.gd`: **82/82**, rendered Godot, exit 0. Samples 32 phases per stage. Checks fixed refuge, floor progression, ground contact, actual collision tops, passage and pickup access. Sixteen real hostile flights exercise protected/exposed positions, moving boxes/cylinders and fully grown balls. A fixed observation point receives a shot with the far box at 0 degrees and is protected at 45 degrees. Report: `transformation-checks.json`.
- Claude's unchanged `tools/probes/biome_ladder_cover.gd`, rerun by Codex: standing cover succeeds in all four stages. The previous report is retained in `claude-cover-before.json`; the new report is `claude-cover-checks.json`. The report records its exact source hashes and sampled flight count.
- Existing rendered suites rerun: **54/54** four-stage checks, **47/47** desktop input checks, **27/27** Primitives cover checks. Each exits 0. The desktop aim fixture now stands clear of the inherited box; it still uses viewport input and actual projectile collisions. The Primitives suite now expects inherited shelter in later stages.

Existing ObjectDB cleanup warnings remain. The older menu/death test's shutdown crash is still separately documented; this iteration did not rerun or fix it. Headset comfort, real ducking and Quest performance remain playtests. The lower-aim cases in Claude's test do not resize the player capsule.

## Native captures

- `transformation-before.png` / `transformation-after.png`: before and after from the entry view. The after image shows the white outlined floor, taller shelter and carried catalyst.
- `transformation-motion-a.png` / `transformation-motion-b.png`: the same standing viewpoint at two phases. Compare sphere position, cylinder height and box orientation. These are paused native captures, not generated illustrations.
- `transformation-opening-clear.png` / `transformation-opening-screened.png`: the same view near the far box. The projectile test verifies the corresponding opening and shelter.

Source evidence: `ada_run/biome_transformation_cover/`. Its baseline runtime source and Claude's original report are preserved. Run the Codex probe normally for assertions; `-- --capture-only` refreshes the three overview/motion images without presenting that capture pass as a test run.

## Next handoff

Claude can independently review the new phase probe and report, then check whether the timed openings are readable in play. Claude's own probe source was not edited. The next implementation candidate remains B12: a coloured shot leaves a retained floor mark that RESET clears. Tiling follows a legible Colour interaction. Tutorials and final.md were not changed.
