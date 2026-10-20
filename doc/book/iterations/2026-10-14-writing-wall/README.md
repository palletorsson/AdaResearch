# Random Definition writing wall — 14 October 2026

Palle asked for a refrigerator-magnet planning wall tying the artifact sequence to tutorial.md and final.md, with draggable meanings, hover briefs, directed connections and separate writing notes. Palle clarified that the requested range/assignment upgrade concerns the colour-grid window, not the source console.

## Open and use

[Open the writing wall](http://localhost:3003/long-museum/writing-wall?map=Random_Definition). Links are also installed in the Long Museum sidebar and each hall editor. The `map` parameter opens other existing halls using their actual artifacts and registry briefs; Random Definition has the authored question seeds.

The wall reads the current map, registry and two texts. The saved Random Definition wall contains ten regular artifact placements plus the three independently placed frame/source/movement instruments. Each magnet has its current brief, a question group, tutorial and final writing seeds, and a separately labelled proposed apparatus change.

- Drag a heading to arrange meanings. Arrow keys move a focused magnet. Use zoom or Fit width.
- Hover/focus a magnet for its brief and both text seeds; select it to edit.
- Reorder the numbered list by dragging rows or using its arrows. One order supplies the magnet numbers, room plan and both text outlines.
- Select a writing overlay, add notes, and optionally attach them to an artifact.
- Connect two cards/notes. Select a line (or focus it and press Enter) to name the relation, reverse its arrow, make it undirected or delete it.
- Toggle tutorial/final overlays independently. Shared connections remain visible.
- Text order shows the proposed outline and current source passages. Repeated source markers remain separately readable; no artifact order is inferred from unmarked tutorial prose.
- Save, undo/redo, refresh and export the wall or either Markdown outline.

`commons/maps/Random_Definition/writing_wall.json` is the shared planning document. It does not move runtime placements or rewrite tutorial.md/final.md. The room plan draws a numbered itinerary over current positions; it is not a collision-tested walking path. Physical rearrangement remains in the existing hall editor. This distinction lets Palle agree on an order before editing geometry or prose.

## Persistence

Backend: `ada_encyclopedia/src/lib/writing-wall-store.ts`; API: `/api/writing-wall`; UI: `src/app/long-museum/writing-wall/`. Saves validate identifiers, links, layer membership, text sizes, coordinates and the complete order. A per-hall lock and source-version comparison prevent stale saves overwriting changed sources. A temporary file is atomically renamed; prior bytes survive in `doc/book/writing-wall-history/<map>/`.

New room artifacts appear as new magnets. Removed artifacts retain their writing and are marked missing until explicitly removed. Moving a uniquely named artifact preserves its magnet identity. Repeated instances use coordinate-qualified identities; moving those may require reconciling a missing and a new magnet instead of guessing ownership.

## Colour-window implementation

`seed_replay_demo.gd` now supports the opt-in `mapping_study` comparison, enabled only in this hall. The left pane remains RGB [0,1]. RIGHT: MAP cycles RGB / RED ONLY / SWAP R/B; RIGHT: RANGE switches full / [0.2,0.8]; RESET MAP restores the assignment and bounds. Every mode consumes three draws per cell. Red-only fixes green and blue at 0.5. Mapping controls leave source provenance, the seed and the carrying sphere's RNG/trip untouched. Replay and visit-state restoration preserve the mapping.

The existing controls are grouped into a shorter rectangular board for this opt-in layout. Pane captions show the mapping and bounds above the glass. The supporting [tutorial](../../experiments/random-definition/window-mapping-001/tutorial.md) and [provisional final passage](../../experiments/random-definition/window-mapping-001/final.md) describe the experiment and its limits.

## Verification

- Seven automated backend tests pass: source/part enumeration, save/reload/history, stale-source conflicts, room reconciliation, invalid/forged records, outline/layer order, and path/lock rejection.
- The focused TypeScript project (`tests/writing-wall/tsconfig.json`) passes. The broader repository typecheck has unrelated existing errors, including the FractalEdge type mismatch in `src/lib/fractal/tree.ts`; it is not reported as clean.
- Real browser checks: loaded all 13 magnets; pointer and keyboard movement; attached and edited a note; changed sequence and observed matching room and tutorial-outline numbers; created a final-layer connection; edited its label, reversed it and made it undirected; isolated the final overlay; discarded transient test edits; saved the window's finished brief and reloaded it. No browser/UI automation bypass was used. `writing-wall.jpg` and `room-sequence.jpg` show the delivered page.
- Twenty native museum checks pass in `writing-wall-02`: equal starting panes, real mapping/range/reset button events, arithmetic for red-only and channel swapping, fixed raw sample/baseline/receipt/ride RNG, state roundtrip, replay and independent draw-offset controls. See `museum.json`, `museum.log` and `window-range.png`.
- Headset reach, comfort, independent human reconstruction and learning observations remain open. No new entropy claim or comparative learning finding is made.

`tutorial-outline.md` and `final-outline.md` are snapshots exported from the saved wall, not installed chapter replacements. `before/` preserves the modified pre-existing files. No commit or push was requested.
