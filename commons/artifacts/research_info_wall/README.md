# Research information wall

A reusable 6.2 m × 2.35 m × 0.24 m physical partition, with floor plinth and collision. Framed interpretation, replaceable image, working whiteboard and three handwritten movable sticky notes share one architectural object. It is installed independently at Random_Entropies (9,13), facing the chair-description chamber; side passages remain clear. The seven entropy encounters keep their order.

## Working with it

Pick up a dark/red marker and touch the whiteboard or a sticky note. Lift the nib to break the stroke. Use the eraser locally. Lift a sticky note and release near the wall to pin it; release away from the wall to return it to its last pinned location. The markers and eraser return to their shelf when dropped below it or lost at a distance. Native XR pickup and desktop grab/drop hooks are supported.

Ink and pinned positions autosave after a pause and on exit, locally under `user://research_info_walls/<storage_key>.json`. Each note keeps its own image as it moves. Set an explicit, unique `storage_key` for authored placements so moving that wall in the editor does not change the notebook it opens. A fallback key includes map/name/position for unconfigured instances. Storage is per device; no cloud or multiplayer notebook exists. There is no visitor save menu.

## Optional modules and appearance

Scene exports `drawing_enabled`, `notes_enabled`, `illustration_enabled` choose modules before the wall enters the tree. Grid metadata accepts the same booleans. Exports `heading`, `explanation` and `comparisons` supply the framed reading. Styles `gallery`, `workshop`, `night` change the partition material and trim without rebuilding writing surfaces or resetting notes. Use the Inspector, `#style:workshop` map metadata or `apply_style("workshop")`. These are author choices, not another player control board.

The prototype has three notes, two pens and an eraser. It does not yet spawn unlimited notes, provide typed text entry or share work between devices. The working wall is a separately registered artifact; the seven framed entropy captions use a smaller support module.

## Reuse and verification

- Registry: `commons/artifacts/registry/research_walls.json`, token `research_info_wall`.
- Image handoff: [ILLUSTRATION_SLOT.md](ILLUSTRATION_SLOT.md).
- Reuses `whiteboard_canvas.gd`, `whiteboard_pen.gd` and the plain drawing-pen model without modifying those shared implementations.
- `writing_surface.gd` supplies bounded paper-local coordinates and PNG persistence. `wall_pen.gd` breaks a stroke when moving between surfaces. `sticky_note.gd` uses the actual XRTools pickup/drop lifecycle and desktop hooks.
- Native tests exercise real pickup callbacks and rendered ink storage; this is supplied motion, not evidence of headset comfort or independent research value.
- Current review and test scripts: `doc/book/iterations/2026-10-16-research-info-wall/`.

The current illustration is a provisional native overhead capture, not the separately developed final illustration. Quest packaging and real headset reach/performance have not been tested in this pass.
