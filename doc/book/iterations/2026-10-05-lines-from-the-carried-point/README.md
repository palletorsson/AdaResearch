# Lines from the carried point

5 October 2026. Continue the current tested Coordinates script, rather than the older assumed point reconstruction.

The canonical `commons/maps/Point_Lines/tutorial.md` now keeps Coordinates’ construction and readout. It duplicates the pickable point for B, creates the supplied segment renderer, and adds displacement, distance and a live segment. The coordinate text remains and gains a distance reading.

The lesson prints one complete `line.gd`, with one `_ready()` definition, and the complete unchanged `line_skin.gd`. The optional second segment uses C/D position values without creating additional pickup objects. Parallel, plus, X and depth-separated X are arrangements of two relations. Trace remains the next unassembled continuation.

## Verification

`student/run_checks.py` extracts the exact printed main script, helper and two-line addition. It reconstructs the main program from the current Coordinates output through declared edits and binds the written experiments to full executable variants. Native Godot checks the reduced program with actual XR Tools and synthetic controllers. Deliberately broken variants test whether the checks detect incorrect behaviour.

The resulting `student/report-runtime.json` is the source of outcomes and hashes. Its tests do not establish hardware input, headset comfort, rendered appearance or student understanding. `reading-review.json` records a separate read-only review of the teaching continuity.

From the repository root:

```powershell
python doc/book/iterations/2026-10-05-lines-from-the-carried-point/student/run_checks.py
python doc/book/iterations/2026-10-05-lines-from-the-carried-point/build_review.py
```

The museum, reflective text, upstream tutorials and older Lines test evidence are preserved. `before/unchanged.json` records their hashes. Current Ghost Student metadata points to the newly tested continuation; historical reports keep their original inputs.

[Review](index.html) · [Native report](student/report-runtime.json) · [Student code](student/line.gd) · [Drawing helper](student/line_skin.gd)
