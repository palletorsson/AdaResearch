# Trace the carried point

5 October 2026. The author selected arrays, loops and the segment-distance condition, using the same student dot built in the preceding lessons.

The complete `trace.gd` continues the tested Lines script. It explicitly removes the second endpoint and their single live span, while preserving the original point, its geometry, pickup settings and coordinate readout. A typed position array replaces the fixed pair. The unchanged `line_skin.gd` draws its neighbouring segments.

The tutorial explains seed, lifetime, append, zero-based index, size, the last retained position, `if`, indentation and `for`/`range`. It prints the full main program and supplied helper once. No production artifact supplies missing teaching code.

## Evidence

- **124 native Godot checks pass.**
- Exact current Lines → printed Trace composition is verified.
- Real XR Tools pickup, movement, release and re-pickup are exercised with synthetic controllers.
- Sampling checks include cumulative small steps, pauses, turns, returns, preserved order and scene-local coordinates.
- Segment count and endpoints are checked against the retained positions.
- Threshold and traversal experiments are saved as complete tested programs.
- Removing the distance gate and connecting wrong neighbours trigger the expected failures.

The tests are headless: hardware input, appearance, headset comfort and learner understanding remain outside their scope. `reading-review.json` records the independent review of the explanation and continuity.

Run from the project root:

```powershell
python doc/book/iterations/2026-10-05-trace-the-carried-point/student/run_checks.py
python doc/book/iterations/2026-10-05-trace-the-carried-point/build_review.py
```

## What carries onward

The positions are values in `PointStudy`'s local frame. The array lasts while that station exists; a new instance begins a new record. There are no timestamps, files or automatic transfer into the production Grid artifact. Grid must next continue this learner program and reuse its data explicitly. Its older production-session tutorial is marked for revision.

The museum, reflective text, upstream lessons and earlier native evidence remain unchanged. Their hashes are recorded in `before/unchanged.json`.

[Book spread](../2026-10-05-primitives-facing-pages/Point_Trace.html) · [Review](index.html) · [Native report](student/report-runtime.json)
