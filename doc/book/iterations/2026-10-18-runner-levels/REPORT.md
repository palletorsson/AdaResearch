# Museum Runner — four maps and saved progress

18 October 2026. Revision `2026-10-18-level-checkpoints-1`.

The runner now loads four separate map scenes inside the shared XR viewing rig:
Point / Line (108 m), Face / Body (144 m), Transformation (144 m), and Array / Colour (180 m).
Each has its own seed, visual family, starting speed and finish gate. The black sphere and
centred view remain consistent. Head tracking and the existing shooting controls are retained.

Before: the visual families rotated through one endless course. Only the best score was saved.
Now: reaching a finish wins the map and saves the next map plus cumulative earned score.
Press A/X or Space to continue. A collision stops the attempt; retry restores the saved
start of the current map, its layout and banked score. Pickups from a failed attempt do
not accumulate in the checkpoint. Closing on a win screen preserves the next map.

After the fourth map, completion is saved and A/X returns to the museum. There is no
automatic wrap to map one. Checkpoints are at map starts, not at individual obstacles.

## Save behaviour

`campaign.gd` reads/writes the runner's existing `user://museum-runner/best.cfg`.
Legacy best-only files retain the record and start at map one. Stable map IDs identify
the next map. Unknown or invalid checkpoint data falls back to the first map without
discarding a valid best score. Museum progression is separate.

A temporary file is written before replacing the checkpoint. Advancement happens only
after a successful write. A write failure leaves the finish reached and offers Retry save.
An unfinished attempt can set a best-score record, but cannot advance its saved map or score.

## Verification

**116/116 native assertions and 76/76 compiled-package runtime assertions passed.**
The package harness also passes 13 packaging/provenance checks.
Tests cover the existing steering, shooting and collision behaviour, plus finish/save,
duplicate finish protection, checkpoint retry, fresh-instance reload, save migration,
invalid records, a real failed file replacement and retry, collision on the finish tick,
scene cleanup, unchanged XR origin, each map and final completion.

Images are real Godot test captures. The finish checks position the runner near each
boundary; they do not claim a human playthrough or a verified difficulty curve.
The native harness still emits renderer teardown warnings (null materials, texture
release and ObjectDB); counts are in receipt.json and full output is retained. No GDScript
parse/runtime error appears in the final native run.

## Quest

Installed on Quest 3. The previous runner save is preserved; the four-map flow is ready for a headset playthrough.

Physical steering was confirmed on the preceding build. The new level transitions,
checkpoint persistence and map pacing have not yet had a human Quest playthrough.
See `quest-build.json` when available; installation alone does not establish that test.

## Files

- `commons/museum_runner/game.gd`: level flow, finish detection, checkpoint UI.
- `commons/museum_runner/campaign.gd`: migration and persistent checkpoints.
- `commons/museum_runner/runner_map.gd`, `maps/*.tscn`: the four maps and finish gate.
- `tools/probes/museum_runner_levels.gd`: shared native and packaged level tests.

Run `python tools/test_museum_runner.py --render` and `python tools/test_museum_runner_package.py`.
