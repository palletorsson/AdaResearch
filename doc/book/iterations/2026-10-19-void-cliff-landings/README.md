# Floors as cliffs

The request changes the spatial premise: an unfinished tower with a visible
ledge to jump onto, rather than only a succession of museum halls.

Implemented on the shared main tower's 13 lower floors. Three convex concrete
profiles stagger left/right on the south facade, with eight metres between
the two base positions plus the individual profile offsets. This replaces
the first study's alternating north/south route. The
first roof departure has a four-metre rail opening. Collision follows the
outline; no invisible rectangle catches a missed clipped corner. The kill
bounds now include the new projection. Streaming follows the existing floor.

The feature is optional in `layout.json`, leaving separate sequence trials
unchanged. The slab belongs to fixed architecture. User-curated rooms and the
shaft-B pads remain in place. On Point Lines the existing enclosed puzzle
occupies part of the landing: aim inside its rear wall, then open its door.

## Source

- `commons/void/cliff_landings.gd`: outline, mesh, matching collider, edge paint.
- `commons/void/layout.json`: enabled flag and three profiles; dimensions in metres.
- `commons/void/architecture.gd`: shared floor and first roof opening.
- `commons/void/game.gd`: include projection in the existing outer kill bounds.
- Encyclopedia `void-model.ts` / `void-scene.ts`: optional frame metadata and
  whole-floor camera framing using the new extent.
- `tools/export_void_editor.py`: regenerated actual floor/prop/artifact models.

## Evidence

`python tools/test_void_cliffs.py --capture`

- 160 Godot checks passed: each slab's top, cut-away corner, same-side position
  and clear space above; real step/jump landings onto every lower floor in both
  desktop and XRTools, plus a direct jump from the first ledge to the second.
- 42 existing fall-contract checks passed: one floor costs 10 health, skipping
  floors kills, grunt/red fade/checkpoint restart works, normal jumping is free.
- 427 GLB model files exported; exporter reported no failures.
- Focused TypeScript check for both changed editor modules passed. A broad
  repository check reports errors elsewhere, including old capture files,
  biome API types and course-progress types; this task does not repair them.
- Screenshots captured from Godot's Mobile renderer and the actual lab editor.
- XR checks use synthetic trackers, not a physical headset.

Fun, fear, readability at headset resolution and comfort remain play-test
questions. Repeating three outlines is an initial shared-floor study; each
later floor can receive its own authored profile without moving its artifacts.
