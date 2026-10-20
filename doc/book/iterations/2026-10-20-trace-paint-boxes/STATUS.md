# Point Trace paint boxes — 2026-10-20

User: replace “plan vitrine / original museum” in Point Trace with several 3D
painting configurations; hand enters → draw; hand leaves → retain. Plinth 60 cm
high, box 60 × 60 × 140 cm.

Implemented in the current Void / Endless Museum `commons/void/rooms.json`,
floor 4. Removed only placement `museum-point_line_grid-7-15`. Added four
`trace_paint_box` instances: tube, ribbon, beads, grid. Preserved other placements.
New script and scene: `commons/artifacts/trace_paint_box/`. Registry entry and
Void catalog entry expose the reusable scene.

Each tracked controller supplies an independent stroke. Box-local records and
MultiMesh geometry survive exit, tracking loss, visibility changes and floor
sleep. Re-entry starts separately. Explicit per-box Clear. Bounded 2,048-sample
capacity stops recording, preserves existing work, and displays FULL. Session
retention only; no disk archive and no automatic bead-to-Grid publication.

Verification: `python tools/test_trace_paint_boxes.py` stages real dependencies
and runs native Godot against the actual floor. `--capture` adds museum images;
`--staged --capture --photos-only` reframes them without rerunning interaction
checks. 99 native checks / 102 rendered checks pass. Synthetic XRServer poses,
not a physical headset. Screenshots contain test-drawn spirals; production
stations begin empty.

`python tools/export_trace_paint_boxes.py` exports only the four models into
the existing encyclopedia layout editor manifest, preserving other entries.
No tutorial/final text changes. No Quest build or installation in this pass.
