# Triangle: one illustration in the museum and the book

Implemented 23 September 2026.

- Native Godot artifact `triangle_construction_plate`: ivory plate, charcoal frame, pink positions/fill; same three vertices rendered as positions, boundary, and face. All geometry and text are native Godot nodes.
- Registered in `commons/artifacts/registry/primitives.json` and placed in Point_Triangle_Context at (9,5), offset (0.15,0,-0.30). Primary reference in the existing boundary-and-face group, between puzzle and drawing in group order. The two hands-on encounters remain.
- Book figure is the same scene rendered orthographically, with the mounting feet/legs hidden. It is not a separately drawn diagram. Rebuild: `python tools/capture_triangle_plate.py`.
- Added only image and caption to `commons/maps/Point_Triangle_Context/final.md`. Core manuscript/map hashes and artifact inventory/intent updated.
- The first placement at (1,13) was partly hidden by a partition. Native inspection led to the wider wall at (9,5). A local sculpture-clear rectangle [7,5,11,8] keeps generated sculpture out of the reading area; authored artifacts and all floor cells remain unchanged.

## Verification

Seventeen controlled native Godot geometry/capture checks pass. Three stages preserve coordinates; their edge and fill nodes match the stated construction. Actual museum build exits 0 and screenshots were inspected. The plate retains scale (1,1,1), bounds approximately 4.245 x 2.7225 x 0.4 metres. Existing cabinet material-remap and ObjectDB exit warnings remain; no illustration script errors. No headset legibility or learner test is claimed.

## Scope and concurrent work

Original prose, code, footnotes, encounter markers and all existing placements remain. Frozen full-book and audio files remain unchanged. Local figure renders and dated museum photos are in this review.

Triangle-only updated purpose notes are saved in `triangle-purpose-update.json`. The shared ten-hall purpose view has not been rebuilt: independent Polyhedra additions changed that hall's manuscript and placement anchors while this work was underway. Preserve those additions and reconcile its notes in its own pass; do not overwrite or weaken the shared audit to force a build. No shared purpose source, snapshot or report was changed by this illustration pass.

The renderer writes figures under this review directory so the existing book-review route can serve them. Browser automation was unavailable due to its Windows sandbox launcher; native images were visually inspected and HTTP delivery/HTML anchors checked directly.
