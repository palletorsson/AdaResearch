# Point_Animatedcube — focused book pass, 2026-09-16

The room's small experiment is to move one corner out of a square face's plane and discover the shared diagonal between its two triangles. The final chapter follows outline → editable builder → rigid folding net, matching the room's primary order and the net's later placement. It keeps the distinction between replaying a presentation and restoring the initial coordinates, and Palle's admission "A world without composition yet."

## Scope

The main chapter is 778 whitespace-delimited words including code, annotation tags and two footnotes, down from 1,244. The old generic tween tutorial has been replaced by instructions for the installed controls and optional return visits. The cartons, glove box, shadow and phosphor discussions remain available there. In particular, the shadow comparison now names the line's explicitly disabled shadow setting instead of treating the result as a proof of dimension.

Corrected the stale summary and inventory: the map is 13 × 14, with two instrumented builders and one net placement. The main surface is triangulated; it is not a flexible-quad implementation. Three artifact types remain primary in both the book tags and the role file. Only their order changed. Existing room entries in the spine manifest follow that order without introducing duplicates from other rooms.

All fourteen artifact placements, runtime code, the critical essay, other rooms' rulings, user notes and positions are preserved. Earlier field notes and walked text remain intact beneath a historical notice. The before/ directory contains fourteen exact pre-edit copies; archive.json records their hashes and the inspected runtime sources.

## Verification

- Existing Godot probe_cube_primary.gd: 40 checks, zero failures. Exercises actual pointer-button events, supplied handle positions in a translated/rotated instance, replay, restoration, pause, geometry updates, diagonals, readout bounds and the map's two configured builder instruments.
- Content/live API validation: 16 checks, zero failures. Confirms archived bytes, unchanged runtime and map, scoped role/manifest changes, tag order, footnotes, live text and all fourteen live placements.
- ReactMarkdown + remark-gfm: 9 render checks, zero failures, including both footnote targets/backlinks and the tutorial return link.
- Scoped git diff --check passes. Existing LF/CRLF conversion warnings remain.

The Godot process exited successfully. Its startup log still includes the known unresolved UID rwex60pqapc and Windows certificate-store errors; this is not a clean-startup claim. No engine code was changed in this pass. Full-room headset reach, viewing comfort and sightlines remain unverified.

The first probe wrapper failed only while printing a Unicode success symbol after Godot had exited 0; component-checks.json is the successfully written probe result. No duplicate runtime run was needed.

## Reading

- http://localhost:3003/book?map=Point_Animatedcube&section=final
- http://localhost:3003/necklace/thread?map=Point_Animatedcube&role=primary
- Next room: Primitives_Ignorance.

## Subsequent amendment

Palle brought the museum floor, walls and cube-based prefabs into the main encounter. See `museum-as-cube/README.md` for the four-text amendment and validation. The word count above describes the earlier pass, before this addition.

The subsequent supplied review is applied in `review-footnotes/README.md`: three sourced technical notes and a shorter main walk, retaining the museum connection.
