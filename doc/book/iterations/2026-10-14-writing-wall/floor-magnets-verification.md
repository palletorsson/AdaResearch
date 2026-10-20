# Floor magnets — 2026-10-14

User correction: number and title must stay at the artifact itself, like a draggable refrigerator magnet. A placement is allowed only on floor.

Implemented in the encyclopedia writing wall: compact numbered title cards on room cells, pointer dragging, arrow-key movement, zoom, floor/occupancy validation on client and server, actual room saves through the existing guarded cell editor, and one-step room undo. Writing drafts and the encounter order survive placement changes. Separately editable instruments remain in place when their parent/anchor moves.

Verification:
- 12 writing-wall/room tests passed (floor restrictions, occupied cells, bounds, stale versions, raw configuration preservation, independent parts, writing and order preservation).
- Focused TypeScript compilation passed, including the move API and cell-editor dependency chain.
- Browser: dragged Time / frame study from (3.5, 3.5) to (4.5, 3.5), observed saved server position, then used Undo room move.
- Browser: a drag to the west wall was rejected; the magnet stayed at its previous floor position.
- Browser: arrow-key movement saved, then undo restored the original position.
- All 13 full title texts fit inside their cards at the checked fit-width zoom.
- The Random_Definition map file was byte-identical after the movement/undo checks: SHA256 1B5115F6E28629CAD7E981F7BA37AE6D438B0467DEC8A65FFFE3F2A34B0C3046.
- Screenshot: floor-magnets.jpg.

Scope: floor-cell placement validation, not a runtime collider/clearance test. Repeated artifacts with coordinate-derived writing IDs are rejected here until a stable identity is available; this does not affect the 13 unique artifacts/instruments in Random_Definition. No desktop or headset interaction was tested in this edit.
