# Bring the trace, not another demonstration

3 October 2026. Palle corrected the Grid pilot: the gesture made in Trace, with a mouse or VR hand, must become Grid's material. The previous live-point recorder taught rounding but discarded this relationship.

## The construction now

Trace keeps its existing sampling, ordered list, loop and capacity. The supplied TraceMemory node watches the PointHandle's normal dropped signal, shared by desktop and XR Tools. On release it serializes the current retained positions into a local versioned record, with full numeric precision. The record uses Study-local coordinates in metres. A too-short or invalid save leaves the previous valid record alone. Successful writes replace it using a temporary file and rename; the helper reports success or failure in the room.

Grid loads that value snapshot into `source_points`. The learner's loop calculates an integer address for each position, converts it back into metres and appends it to a new `grid_points` array. It neither modifies the source nor overwrites its file. Every sample keeps its index: equal rounded neighbours remain entries, and rendering hides their zero-length segment. A changed grid size always starts from the saved source, avoiding cumulative rounding.

Storage is local to the same device. It survives stopping Trace and running Grid in a new engine process. It does not promise transfer between a desktop and a standalone headset. The museum's own TraceData already carries released drawings to grid_lines; this is the small starter's equivalent transport, extended to survive separate F6 runs. The museum's multi-trace replay and centre/scale-before-display-rounding remain distinct from this lesson, which rounds source-frame values before displaying them.

## What the student owns

The record, its sampling decision and its ordered traversal in Trace; then the mapping from each saved Vector3 to a Vector3i address and a new Vector3 position in Grid. `for p in source_points` revisits known iteration, now visiting values directly. Keeping two named lists makes the distinction between source and interpretation inspectable.

Release signals, JSON/file handling, error reporting and comparison layout remain supplied components. They are named, included, and instantiated in code. No scene-authored lesson object is fetched by dollar reference or another node path. The source and rounded view use one common centre and scale derived from the source alone, then separate horizontally. Those display transforms never alter either list. The original side should therefore stay fixed when grid spacing changes.

No saved trace produces an honest empty state. There is no canned shape masquerading as a student's drawing. The review images use a synthetic controller gesture and say so; the file they replay is the one the actual Trace release callback saved.

## Review scope

Canonical tutorials for Trace and Grid, their executable studies, package instructions and the starter download are updated together. Earlier review pages are retained as historical snapshots and point here. The live museum and critical manuscript are unchanged. Coordinates still needs its earlier shared-starter tutorial pass.

Checks exercise desktop mouse-motion handling, synthetic controller grip/release, exact saved values, the unchanged source, repeatable alternate spacings, duplicate output positions, invalid/missing records and separate engine processes. Physical headset use and a beginner reading trial remain pending.
