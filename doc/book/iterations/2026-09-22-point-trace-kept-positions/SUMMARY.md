# Point Trace: the time between positions

Three paragraph edits in the first drawing encounter. The opening loop, pause, release and change of viewpoint already give the reader something to do and notice; they are preserved.

## Decisions

- Name the existing list and explain size(). Carry the previous room's two-point construction into repeated connections that can form a curve. Preserve the joints image and the distinction between a drawn connection and the intervening hand movement.
- Make the movement comparison precise without a control inventory. The reference position advances when the movement gate passes, before any later shaping or duplicate rejection. It is not necessarily the last saved point. Keep the return to Point One's running counter and give the pause a concrete consequence: the position list does not report how long the reader waited.
- Make the last-ten display window easy to picture. At eleven retained positions, rows 2–11 are displayed while all eleven still belong to the line. Disappearing from this window is not the same as eviction from the stored list.

## Preserved

“Bring the detour”; the opening encounter; the current code; the shared unread machinery; the resolution comparison and its invitation to find a use for coarseness; the drawing stick; the whiteboard's meaningful lifting; the release-and-copy route into Grid; all footnotes and artifact anchors. Point One and Point Lines are unchanged.

Compared the current chapter with the earlier version in doc/space/point-trace-focus-2026-09-16/previous/final.md. Its strongest passages already survive. No wholesale restoration, shortening or further historical claims are needed here.

## Source correspondence

The current dot scene observes GrabPoint, uses a 0.005 m movement threshold and retains up to 4096 positions. draw_dot.gd compares current_global with _last_global_position; below threshold it returns before appending. Passing advances the comparison position before shaping and duplicate checks.

size() supplies the retained count. The table starts at max(0, size - 10), and displayed row numbers add one to the current list index. The mesh joins the retained positions as a line strip.

Per-point timestamps are appended only when fading is enabled. These placements keep fading off. The script has elapsed time for other work; that does not mean the position list records the duration of a still pause. No claim is made that the whole engine stops measuring time.

The source permits these investigations. No new Godot, headset or learner test was performed. No map, scene, script behavior or artifact roles changed.

## Reading records and next step

The canonical chapter, encounter text hash and paragraph-purpose notes are synchronized in a new derived snapshot. The frozen full-book and audio captures remain unchanged. Exact edits are in Point_Trace.diff; before and after chapters are retained beside this page.

Next close reading: another resolution, another gesture. Start from the existing comparison of enlargement, repeated corners and what a particular drawing needs from its recorder. The later stick and whiteboard passages are already concrete; do not force equivalent changes into each encounter.
