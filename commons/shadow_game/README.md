# Shadow Game — Make a crossing

First playable episode, 17 October 2026. Main menu → **Shadow Game**. Direct editor entry: `res://commons/shadow_game/shadow_game.tscn` (F6). Uses the museum's existing base, XRTools hands, desktop player and biome. Installed Quest copies need a new export; no headset deployment was performed in this pass.

## Play

1. Take the blue-grey cube. Release it inside the pink frame beside the bridge. It snaps into place and powers the hinge.
2. Hold the pink stick. Press the holding hand's trigger to turn the bridge a quarter-turn. Removing the cube pauses it; replacing the cube resumes the same bridge.
3. Carry the black sphere across. Release it on the far plinth. Its movement leaves a pink trace. The crossing completes; all three objects remain available.

Desktop: arrow keys to walk, mouse to look, right click to take/release, wheel to adjust reach, left click for the held stick's action. Escape releases/captures the cursor. VR uses the existing grip pickup and trigger action. No new universal tool or weapon system was added.

A fall returns the player to arrival. An object released outside the playable bounds returns to its previous placed pose. Other placements and traces remain. **RECALL LOOSE OBJECTS** explicitly brings loose objects home, keeping the docked cube and completed point. **RESET** requires two presses within four seconds, and refuses while an object is held. **MAIN MENU** returns to the existing staging session. **MUSEUM** opens Point One.

## What carries forward

- `point.gd` extends the tested PointBody from the Lines lesson. It retains its geometry and XR pickup/collision construction; this scene supplies a dark finish and the shared desktop pickup hooks.
- `piece.gd` wraps the existing tutorial BoxBody and LineSkin with explicit physical shapes and XR pickup. The original helpers are unchanged.
- `encounter.gd` gives these three instances their roles. The bridge is an AnimatableBody3D with a matching physical box; the gap has no invisible supporting floor. One press requests one quarter-turn. This is a new interaction application, not a claim that earlier visual-motion tutorials already taught collision or game rules.
- The trace uses ordered local positions, a distance threshold and the inherited LineSkin. Each new grab starts a new stroke. Recording is bounded to 256 positions and reports when full. This prototype records its own trace; it does not import or overwrite the student's museum archive.
- The biome is supplied scenery built from the existing BiomeObject with recording off. The episode does not claim that its vegetation was made by the learner or that completing the crossing causes ecological growth.

The shared PointBody, BoxBody and LineSkin runtime copies live in
`commons/museum_runner/forms/`, with original lesson paths and hashes in
`provenance.json`. Both side games use those same builders. The historical lesson
files remain unchanged, and neither game loads them from `doc/`, which is ignored
by Godot and excluded from exported builds. The earlier `Encounter.new()` failure
in `world.gd:44` was caused by these missing inherited/preloaded scripts.

## Persistence

`user://shadow-game/world-v1.json` stores schema, stable object names, placed local positions/rotations, actual/target bridge angle, completion and ordered trace/stroke starts. Held objects save their last placed pose. Save occurs on release, completed turn and menu exit. Full-precision JSON preserves the recorded float positions. Loading validates required objects, numeric bounds, schema and record size before changing the scene.

This is source reuse and saved-state continuity. Runtime instances are recreated when reopening the scene. Storage and player setup are supplied infrastructure; canonical tutorial/final texts and the spine order are unchanged.

## Verification

`python tools/test_shadow_game.py --render` runs the actual scene, synthetic XR pickup, desktop hooks, wrong-order actions, bridge pause/resume, collider rays, CharacterBody3D traversal, independent save/reload, invalid-record controls, fall recovery and deliberate reset. Native screenshots and results are under `doc/book/iterations/2026-10-17-shadow-game/`.

`python tools/test_shadow_game.py --menu --render` exercises the actual menu button's dwell, staging entry and return. Test saves are isolated under `ada_run/shadow-game-test/`. These are native automated tests, not headset ergonomics or human-learning evidence. Consult the report for exact counts and process-exit limitations.

`python tools/test_museum_runner_package.py` additionally exports and runs both
the runner and this game's real encounter in a small PCK with the Android
preset's documentation exclusions. It checks `Encounter.new()`, all three
pickable bodies, buttons, cube placement, the held-stick action, trace creation
and completion without loose lesson files. The full Shadow Game world and player
are covered by the native test above; this package check is not a full APK or
headset test.

## Next development

Keep this place and these identities. The next candidate is to make the cube a source of retained copies, and let those copies become a construction the player chooses. Add one new operation at a time, test that earlier operations survive, and show what changed in the same scene.
