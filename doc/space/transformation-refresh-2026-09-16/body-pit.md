# Body and Pit — implementation, prose and checks

## Body

Kept the existing encounter prose, correcting the distinction between rotation, removal and scaling. Carving deletes cells; movement through the lattice is not the same operation. The proximity scaling field keeps horizontal positions but lowers the centres as cubes shrink so their bases remain on the floor. The handoff to Pit now distinguishes proximity input from clock input.

Added tutorial and summary files, which were missing. Updated intent without replacing the existing throat-width rationale.

Actual endless-museum check: **8/8 passed**. The three thresholds instantiate, and physics rays confirm continuous floor at source coordinates (5,22), (5,23), (5,24). This verifies the repaired exit. This pass did not physically traverse all three responsive gates.

## Pit

The final, tutorial, summary and intent now describe the live pusher, rotation-cube and grower implementations. Removed claims that growth is broken, that it responds to approach, that the pusher uses a triangle-wave implementation, that it crosses three metres in half a second, and that the middle room uses a continuous revolving-wall artifact. No blanket claim that arbitrary scaling preserves shape.

Two implementation problems were found and corrected:

1. `pusher_block.gd` cached its default +X endpoint in `_ready`. Late map configuration changed its advertised axis but not that endpoint. Configuration now refreshes the path and direction arrow when axis or travel changes. Speed-only updates keep progress. The arrow orientation is computed in local coordinates rather than calling `look_at` before entering the scene tree.
2. Floor anchoring initially resized a grower's shape while moving its `AnimatableBody3D` origin. Physics synchronization restored an old body position, producing up to 1.5748m of lower-face drift. The body origin now remains fixed; both the mesh and collision shape centres move to half their new size. This keeps the lower face at the floor while preserving the legacy centre-anchored default.

Actual endless-museum check: **27/27 passed**. Three growers receive their authored configuration; a complete cycle reaches 0.30000001m and 3.5m with measured lower faces at Y=0 throughout (maximum drift 0.0m, mesh/collider mismatch 0.0m). The three pushers reach their +Z, +Z and −Z endpoints and pause. Legacy grower and pusher defaults are checked.

## Scope of evidence

`commons/testing/probe_transformation_pit.gd` reuses the real museum boot from `probe_transformation_opening.gd`. Run with no extra argument for Pit, or `-- --map=Trans_Body` for Body. Reports are copied beside this file as `Trans_Body-checks.json` and `Trans_Pit-checks.json`.

These are headless Godot physics checks. Headset comfort, the degree to which expanding collision shapes push every player rig, and current fire/death policy remain unverified. The embedded museum disarms source utility hazards; the prose therefore does not promise an instant-kill/reload behavior implemented by the transformation artifacts themselves.
