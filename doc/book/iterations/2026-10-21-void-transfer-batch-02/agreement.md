# Museum to Void: transfer before curation

Palle's direction, 21 October 2026: first make the existing collection visible
inside the Void, then curate and integrate it. This batch transfers four maps.

| Owner | Sequence | Maps |
|---|---|---|
| Claude | L-Systems | LSystems_Grammar_Lab; LSystems_Growth |
| Codex / coordinator | Procedural Generation | PG_Genetic_Evolution; PG_Space_Colonization |

Use the active checkout `C:/Users/palle/Documents/GitHub/AdaResearch_46`.
The encyclopedia is the sibling `ada_encyclopedia`; localhost port 3003 is live.
This checkout contains extensive user changes and unresolved older merge files.
Do not switch branches, reset, clean, commit, resolve unrelated merges or overwrite
another worker's files. Work directly in the owned folder specified below.

## Ownership

Each worker owns only `commons/void/trials/<sequence>/` for its assigned sequence.
It may add adapters, scenes, JSON, native test scripts and evidence inside that
folder. It owns that folder's `transfer-status.json` and `HANDOFF.md`.
Codex owns shared `catalog.json`, `playable.json`, `reviews.json`, `briefs.json`,
`line_parts.json`, runtime code, editor code, exports and this batch directory.
Propose any needed catalog overrides in the worker's `catalog-additions.json`;
the coordinator will merge them. Existing registry keys already work in trials.

## What to build

Read your generated `source-inventory.json`, the two source maps' `map_data.json`
and `final.md`, their actual registry scenes/scripts, and any relevant Endless
Museum assembly. Preserve every original placement, including repeated artifacts
with different configurations. Preserve each raw token and source cell as provenance.

Fill your trial's two content floors: roof/canopy 0, source maps 1 and 2, catch 3.
Use the existing Void floor/pillars/shafts and shared player. Do not add perimeter
walls or ceilings. Allow enough floor area to lay out the artifacts at meaningful
scale; do not shrink a working interface merely to squeeze it in. Keep both shaft
centres clear, a walking aisle, and the A corner landing clear. Keep artifacts
individually editable. Preserve the controls and their relation to their artifact.

This is a collection transfer, not a new game design or final spatial composition.
Make only the functional adapters necessary to load, relocate and operate the
original instrument. Keep original scripts and scenes unchanged; use local wrappers
when needed. Do not replace an artifact with a decorative approximation, silently
drop difficult items, change shader meanings, or silently clamp experiments.
Leave chapter texts, original map data, curriculum and curated main tower unchanged.

Each placed entry needs id, artifact, position [x,z], station (NW/NE/SW/SE),
height, facing (0/90/180/270), scale and original parsed config. See
`commons/void/trials/noise/rooms.json` and `floor_content.gd` for the actual contract.
Do not assume the old grid height is an absolute floor height. Check how the scene
positions its own geometry. Layout coordinates are local to each content floor.

## Evidence and coordination

Update transfer-status.json early to acknowledge the assignment, then on completion:
`stage`: inventoried / placed / blocked; exact source and placed counts; omitted
items with reasons; adaptations; unresolved dependencies; checks actually run.
Native-tested and headset-tested remain false until those checks are performed.
Curated remains false. Every omission must remain visible in the handoff.

Use static checks and write focused Godot probes if useful. **Do not launch Godot,
run renderer tests, export editor GLBs or touch live game saves in parallel.**
Codex will serialize native tests and exports on this one GPU and register the
finished packages. Do not edit shared files to make your tests work.

Write HANDOFF.md with changed files, placement intent, source mapping, exact
controls to test, bounds concerns and commands/probes ready for the coordinator.
The coordinator reviews source coverage, native load/errors, reset and residency,
key operations, editor save/copy/move and screenshots. A loaded scene alone does
not establish working interaction. A synthetic XR check is not a headset playtest.

## Later curation

Once the collection is visible: select the encounter order; connect useful objects
to the path and shafts; test what the player learns by acting; tune light, danger,
scale and pacing; then compare the lived map with the existing final/tutorial text.
Only then decide where the transfer joins the curated tower.

## Repeating this process

Keep the first batch small: two source maps per worker, with one coordinator.
Start from the exact scene paths in the inventory. Use bounded searches in source
directories; never recursively scan generated `ada_run` runtimes or junctions.
Deliver placements and unresolved dependencies before attempting final staging.
After handing off a folder, wait for coordinator feedback before editing it again.
The coordinator runs `tools/audit_void_transfer.py <sequence>`, reviews adapters,
runs the native probe, exports once, and runs the editor save check. Preserve any
user edits made after the handoff rather than regenerating the room file.

## Batch 02 focus

Claude owns only commons/void/trials/lsystems/. Deliver placements and a concise handoff first; the coordinator writes and runs focused native tests. Do not spend this assignment writing a comprehensive test suite. Preserve source operations and explicitly identify coupled instruments needing wiring. Do not run Godot. Argon is not participating.
