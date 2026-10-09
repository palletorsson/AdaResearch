# Spine interfaces: Trace and Grid

21 September 2026. User asked to continue through the spine after the shared scalar-control repair.

Review: `/book-review/doc/book/iterations/2026-09-21-interface-spine-primitives-review/index.html`.

## Implemented

- `data_instrument_surface.gd`: fixed cased SubViewport with 2D Labels, aligned numeric type, fitted text, and redraw only for changed content. Positive local Z is front.
- `draw_dot.gd`: adopts the shared display. Recording, sampling, retention, drop/save, capacity eviction and first-sample anchoring remain unchanged. Inherited time-domain recorder tested with its additional contract row.
- `grid_lines.gd`: adopts the display; the museum's `#panel:1` placement has Previous / Auto / Next physical buttons. Starts held; either arrow stops auto; wrapping and new-release page reset tested. Unconfigured instances retain auto paging. Case moves from local (3.35,2.2,1.5) to (3.10,2.2,3.15), on a support for the existing one-metre basin. Full case stays outside the five-metre lattice. Stand remains upright.
- `Point_Line_Grid/final.md`: one sentence explaining held pages and Auto. No manuscript argument, artifact role or map order removed.

## Evidence

- 23 Trace checks, including last-ten indices, capacity, dropping, stationary anchor, clear/restart, long signed coordinates, and the clock-derived recorder.
- 30 Grid checks: real dot release through TraceData, geometry/source distinction, scale and quantization, actual physical-button pointer dispatch, held/automatic paging and wrapping.
- 24 real-hall checks (6 Trace, 18 Grid). Grid buttons are approximately 0.826 m above deck, 0.406–0.444 m horizontally from the tested pose. All interaction rays reach the intended controls; standing capsule and final-metre collision clearance pass.
- Captures use supplied positions, not a recorded human VR session. Grid reading camera follows the moved instrument. No headset, seated-reach, real-hand poke, or Quest performance validation. Existing unrelated UID/material warnings remain.

Commands:

```
python doc/reports/interfaces-2026-09-21/spine-primitives/run_tests.py
python doc/reports/interfaces-2026-09-21/spine-primitives/run.py trace after
python doc/reports/interfaces-2026-09-21/spine-primitives/run.py grid after
python doc/reports/interfaces-2026-09-21/spine-primitives/publish.py
```

The museum runner uses private control/plan/output copies so it does not overwrite the active museum session. Before-source copies have `.gdignore`. Published captures/checks are copied alongside the page; source hashes identify the final state. Working tree had unrelated changes; nothing committed.

## Continue

Next spine hall: Point_Triangle_Context, its triangle puzzle and face-drawing controls. Other candidates are Grid's separate snap-sphere display and remaining Lines readouts. Inspection noticed `line_demo.gd` hides CategoryLogicDisplay initially but shows it again on disconnect; verify whether that old display should return before editing. This pass did not touch it.

Point_One's radio remains the secondary test placement; the invisible point must stay invisible. Do not treat this pair of instruments as a complete first-sequence certification. Gallery_Furniture is outside the active museum spine and remains a separate access task.
