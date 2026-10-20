# Shadow Game — Make a crossing

17 October 2026. First playable episode inside the Endless Museum project.

Open **Shadow Game** from the existing main menu, or run `commons/shadow_game/shadow_game.tscn` with F6. The scene uses the supplied museum XR rig, desktop player and existing biome.

## The encounter

Three familiar objects acquire related jobs. Release the cube in the pink frame to power a hinge. Hold the stick and press trigger to turn a beam across the gap. Carry the shiny black sphere across, leaving a trace, and release it on the far plinth. The objects and drawing remain after completion. The player can keep rearranging them.

Removing the cube pauses the bridge; returning it resumes the same bridge. Falling returns the player to arrival while retaining the arrangement. Lost objects return to their last placed pose. Recall and a deliberate two-press reset are available separately.

This is the first small shared world, with one authored crossing. It is not yet the full cumulative curriculum. The next candidate is retained cube copies that let the player build a crossing of their own.

## Actual reuse

| Inherited material | New application |
| --- | --- |
| PointBody from the Lines lesson | The same sphere construction and XR pickup, with a black material and desktop input hooks. |
| BoxBody from the Scale lesson | The block, platforms and plinths. Pickup and collision are added explicitly. |
| LineSkin from the Lines lesson | The held stick and recorded trace segments. |
| Existing museum player and staging | Desktop and XR entry, movement and return to the menu. |
| Existing BiomeObject | Supplied terrain and vegetation around museum fragments. Recording and residents are disabled here. |

The original form helpers, canonical tutorials, reflective texts and spine order were not edited. The point records a new trace in this scene; importing the student's earlier archive is still future work. Biome growth is not a reward or claimed student output.

## What persists

`user://shadow-game/world-v1.json` records stable object names, placed local positions and rotations, actual and target bridge angle, completion, and ordered trace positions with stroke boundaries. Held objects retain their last placed pose in the save. Reopening constructs new runtime instances from that data; this is saved-state continuity rather than uninterrupted object identity.

The record is schema-checked, bounded and written at full float precision. The trace keeps up to 256 positions, at least 0.12 metres apart within a stroke, and reports when full. Reset clears only this game's arrangement.

## Verification

**Native game: 41/41 assertions passed, process exit 0.** `python tools/test_shadow_game.py --render` tests the real scene with synthetic XRTools pickup/release and desktop hooks. It includes incorrect action order, socket placement, bridge pause/resume, actual gap/bridge collider queries, a real CharacterBody3D walking across, completion, exact trace reconstruction in a fresh scene, invalid save rejection, fall recovery and deliberate reset.

**Menu route: 6/6 assertions passed; process shutdown failed.** `python tools/test_shadow_game.py --menu --render` entered through the real menu button's dwell and staging route, verified the player/environment, returned to the menu and confirmed another visit could be launched. After these assertions the process exited with Windows access violation `3221225477` (`0xC0000005`), with renderer null-material and object-lifetime warnings. A similar staging shutdown failure is documented in `doc/book/iterations/2026-10-12-biome-is-the-arena/HANDOVER.md`. This pass did not establish its root cause or fix it; the route assertions are not a clean end-to-end process result.

The final native result is in `checks.json` and `native-process.json`. Menu assertions and the shutdown output are in `menu-checks.json` and `menu-stdout.log`. `receipt.json` records hashes of the implementation and relevant reused sources at publication.

Initial testing exposed insufficient JSON float precision; full-precision serialization fixed exact trace reconstruction. The menu harness also needed to disable its untracked controller pointers, which otherwise selected a different button at their default origin. These are test findings, not hidden successful runs.

Screenshots are actual Godot compatibility-renderer captures at 1440 × 960. Before and after use the same viewpoint. The visible trace in these captures was produced by the automated input traversal. No image-generation tool was used.

**Not verified:** physical headset ergonomics, Quest performance/export, human learning, or the entire museum's regression suite. No Quest installation was updated. A headset play pass should check grip alignment, trigger use, readable labels and crossing comfort.

## Files

- `commons/shadow_game/`: game scene, object adapters, encounter, supplied-world setup, native verification and play instructions.
- `commons/scenes/main_menu/MainMenu3D.gd` and `.tscn`: Shadow Game button and scene routing only for this task; these files contain other pre-existing work.
- `tools/test_shadow_game.py`: bounded native test runner with isolated scratch saves.
- This folder: native screenshots, checks, logs, source receipt and the review page.

The next episode should deepen this place: reuse these objects, add one operation, preserve earlier interactions, then compare the resulting scene and test its saved state.


## Export dependency repair — 17 October 2026

The `world.gd:44` call to `Encounter.new()` failed because the encounter's point,
box and line dependencies were still loaded from `doc/`. That directory is
ignored by Godot and deliberately excluded from the Android export. The
encounter therefore could not compile into an instantiable script.

`point.gd`, `piece.gd` and `encounter.gd` now share the byte-identical lesson
builders already packaged under `commons/museum_runner/forms/`. Their provenance
and hashes preserve the connection to the unchanged lessons. No interaction,
world-layout or save-format logic changed. The native inheritance assertion now
checks this packaged class identity.

Validation: 41/41 native Shadow Game checks passed, clean process exit, including
full-world construction, XR pickup, real bridge traversal and save restoration.
The combined Windows PCK regression adds eight Shadow Game encounter checks to
the runner's fifteen, all passing with documentation absent and no loose source
folder available. It instantiates the exact class used at the failing line,
builds the three pickable bodies and real buttons, powers and opens the bridge,
records visible trace segments, and completes the crossing. The package run
exits cleanly without script errors.

The PCK uses the Android export preset's include/exclude filters and script mode;
it is not a full museum APK or physical headset test. The earlier menu test and
its shutdown limitation have not been rerun. See the combined
[package receipt](../2026-10-17-museum-runner/package-receipt.json).
