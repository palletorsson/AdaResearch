# Recursive Trees — 14 September 2026

The next hall after Recursion now has two primary encounters and a matching final.md. The full collection remains: twelve placements, ten token types, including both inverted trees and both small subdivision cubes.

The first encounter uses the existing tapered-cylinder tree. A compact physical desk grows one generation at a time and independently varies turn, inherited length and descendant count. Four binary generations contain 31 segments including the trunk; four ternary generations contain 121. Reset replays the same geometry. The second desk exposes the existing block tree's form, recursion strata, accumulated bounds and terminal marks without rebuilding its geometry.

## Repairs and preservation

- Archived current map, scripts and texts under `before/`. `map-982ba8280.json` (23 April) and `map-90d48b730.json` (19 August) confirm the nested enclosure predates the museum conversion. This pass adds a ten-row approach ahead of it and keeps that enclosure.
- Fixed branch endpoint coordinates, removed the extra half-length mesh offset and applied the first length inheritance once. The render nodes share a tree-local container; metadata retains the logical parent graph.
- The growing tree resets generated geometry only, preserving its desk. A local RNG supports reproducible resets without reseeding adjacent works. The lesson is deterministic, capped at four generations/121 segments; the underlying generator has a separate 512-segment ceiling.
- The block tree also uses a local RNG. Detail blocks now use their sibling branch's coordinate frame. Its standalone overlay is hidden only with `lesson:true`. Its readout desk is excluded from the sculpture's colour and bounds measurement.
- Both downward trees are separated, raised and reduced in scale. The Möbius scene's original ~70 m span is reduced to an approximately 4.3 m specimen. The full source scene remains available.
- The last walking test exposed an automatically generated `ArtPlinth1/Collider` across the exit at world z≈23.075. Extending this hall's sculpture clearance through the passage removes that obstruction. No global museum engine or saved hand changes were needed.
- Two primary anchors agree with artifact roles, ruled encounter order, book lines and compiled museum wall captions. The Necklace primary view was checked live: growing tree first, block tree second.

## Evidence

`receipt.json`, `report.json` and `engine.log` are copied from the final successful isolated rendered run by `tools/build_recursive_trees_review.py`. The runner rejects any script error, failed assertion, missing report or stale source hash. `baseline/` holds the earlier inspection; its two inventory checks were not a pedagogical acceptance test.

Tests exercise real pointer/mouse input through the project's standalone DesktopPlayer rig inside the actual museum scene. They check all twelve button targets, actual state transitions, branch connection geometry, exact replay, 31/121 counts, repeated rebuilds, a transformed second instance, transparent glass in every sculpture reading, current wall labels and a five-leg walk around the enclosure into the exit passage. Direct calls are used only for the repeated-rebuild and second-instance checks and are identified in the report. The dormant native player is parked outside the isolated test room so that only one test visitor occupies the route.

The user’s editor and live museum remain open. The saved hand is copied for each run and its hash checked afterward. Headset reach, comfort, Quest performance and the native museum walker's own button interaction lane remain unverified.

The source-backed order generator was run and its broader changes inspected. Only the RecursiveTrees entries were taken into the current manifest; unrelated stale entries were left as found. The learning-arc receipt check now verifies unchanged per-hall slices of shared book/role files against hash-matched pre-edit archives, while requiring exact executable-source hashes. Updating one room's prose therefore need not erase another room's accepted evidence.

Review: `http://localhost:3003/research/possible-bodies/recursive-trees.html`.

Next hall: **Fractal_CantorSet** — more retained intervals, less retained length; distinguish the construction history, finite state and mathematical limit.
