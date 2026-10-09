# Physical consoles in their halls

21 September 2026. Three actual museum placements were built with the current museum code, map data, plan, overrides and hand configuration. Each run redirects museum output files to its own report folder, preserving the running museum's files.

## What changed

Grammar Provenance had three evidence plaques centred 20 cm below its root. In the floor-mounted Grammar Lab, their complete casings were below the walking surface. The plaques now tilt toward the visitor in front of the three forms, centred 38 cm above the artifact root on small posts. Their casings occupy approximately 23.2–51.8 cm above the hall floor. The samples stand on 30 cm bases so the low pattern remains visible above the plaques. Text remains on flat surfaces; the grammar rules, generation depth, generated line geometry and tutorial prose were not changed.

The study moved one grid cell away from the west wall: `(5,19)` to `(6,19)`. Its neighbouring `lsystem_tree` moved from `(6,20)` to `(9,19)`, alongside the comparison instead of between it and the controls. Every artifact token remains in the room, once for each previous occurrence. Other map layers and metadata are preserved.

Fitness and Edge of Chaos already sit directly on the hall floor at metre scale. Their placement did not need changing. The Edge of Chaos terrace rules out a straight approach from the west, but both side approaches along the bay are clear. The actual museum CharacterBody walks the final metre to all three stations.

## Reusable checks

`commons/testing/probe_physical_console_halls.gd` discovers physical sliders and push buttons under the artifact's controls. For each hall it checks:

- Supporting floor and a clear standing capsule (radius 22 cm, height 1.7 m).
- A continuous, level and unobstructed final metre from the front or either side, then a controlled walk with the museum's own CharacterBody.
- Unit world scale for physics controls.
- Control height and horizontal distance from the operating position.
- Unobstructed rays to every button and both ends of every slider.
- Actual XR Tools grab-driver movement and release under the authored hall rotation.
- Provenance plaque clearance above the floor and from structural collision.

The reference pose is 50 cm in front of the console centre, with an eye height of 1.65 m. The working bounds of 0.65–1.25 m high and 0.70 m horizontal distance are project test assumptions, not an ergonomic standard. Horizontal distance is measured from the floor position, not the shoulder. Passing these checks does not establish comfort for every body.

The runs produce 109 passing checks: Grammar 25, Fitness 39, Edge 45. The original grammar capture shows three buried-plate failures. An intermediate upright placement put branches across the words; the final low inclined plaques separate the reading from the branches. After moving the plaques, the additional casing-clearance checks also pass.

## Captures and limits

These images are rendered inside the real museum, using Godot 4.6 Mobile on the desktop GPU. The museum's streaming/input/catch logic is paused for controlled inspection; the standing and walking tests do not prove a complete spawn-to-exit journey. XR Tools input is driven programmatically, without tracked hands or a headset.

Operating views use a 98-degree camera; controls and plaque details use narrower views from the same eye position. Grammar's before and after share the same eye position relative to its console; the console itself moves one metre with the study. Field simulation time is not matched across separate hall runs. These are placement comparisons, not simulation comparisons.

All three tested placements are floor-mounted. Raised or scaled furniture wrappers, short/seated visitors, tracked-hand comfort, visual acuity in the headset and standalone Quest frame time still need their own checks. The three plaques are now visible, but whether their small rules read comfortably at the control station remains a headset question; the player can approach them.

## Reproduce

From the repository root, run `python doc/reports/interfaces-2026-09-21/hall-placement/run.py grammar after` (or `fitness` / `edge`). Then run `publish_review.py` in the same folder to update the review. The `source-before` folder preserves the two files changed in this pass.

The successful runs still report the existing unresolved UID, certificate-store and shader-cache-write messages. They have no GDScript errors.

Next: apply the same placement inspection to mounted/scaled versions before broadening the physical-console migration.
