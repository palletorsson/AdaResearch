# A line you did not hold

24 September 2026. Implemented after the author agreed to a head-path/floor-projection comparison, following the correction of an early-chapter sine-generated test gesture.

## Choice and placement

Added `head_trace_projection` to Point_Trace at cell (2,3), centred at (2.5,0,3.5). A 2.2 m outlined square occupies the open left side of the first room. The existing floor supports it; the artifact adds no collision barrier. A small sign at its back edge identifies pink HEAD PATH and cyan SAME POINTS / ON THE FLOOR. There is no menu. Enter to record; step out to inspect; return after 0.6 s outside to start a fresh record.

The runtime samples the active headset camera. Desktop museum walking-camera input has its own label. Capture/spectator views and inactive XR rigs are refused. Tracking loss or unknown status yields no fabricated positions. Gaps, teleport and recenter notifications break the stroke. A new observer starts a new record. Positions are kept in the square's local coordinates, with a 15 mm movement gate and a bounded list of 256. This is headset position including locomotion, not foot or eye tracking.

One list supplies both views. Pink retains all three coordinates; cyan replaces height with a fixed floor height. When several head positions stand vertically above one another, they coincide on the floor. Degenerate floor segments are skipped rather than normalized into invalid geometry. Four bounded MultiMesh renderers display the two bead/cord views. There is no sine or random path generator.

## What changed in the book

Added “A line you did not hold” after the stick section. It asks for movement and comparison before showing the one-line projection. The critical opening comes from finding a recognisable act in a line with no shoulders or intention. Existing prose, code, anchors and footnotes are preserved. The closing handoff now says that the head trace stays in this hall; only the established drawing-tool release sends points onward to Grid. The new artifact is primary in the same position in the reading order. Tutorial, technical, critical and detour companions record the addition.

## Evidence

29 focused checks, three selected walking paths and a floor-support ray passed in the actual isolated Endless Museum. No GDScript errors in the run. The ordinary museum CharacterBody reached the square, stepped aside and traversed the exit route. Source switching, stationary/sub-threshold input, height collapse, long-frame/large-step breaks, XRTools teleport, recenter, tracking loss/recovery and the bounded record were checked.

For the images, 61 explicit piecewise camera positions were supplied through the production recorder. They produce 60 spatial joins and 40 nonzero floor joins: the down-and-up movement collapses at one floor position. No sine, randomness or smoothing generated the test path. The XR branch used a controlled interface fixture. These are actual engine renders of a scripted test, not a recording of someone wearing a headset. Headset comfort, visual legibility while moving and spontaneous learner discovery remain untested.

An initial review identified a source-switching ambiguity: replacing the observer could relabel a retained desktop drawing as headset input. The implementation now begins another record when the source changes. The second run verifies that behaviour and short-teleport/inactive-rig cases.

## Remaining distinctions

The older automatic-writing desk still generates sine-shaped handwriting, and existing coloured-dot guide strokes / hand-monitor fallbacks are also generated. Those are recorded in the earlier INPUT-SOURCES inventory. This encounter adds a literal measured comparison; it does not claim to have cleaned up every existing example. These older features were not removed or rewritten in this pass.

The 0.45 m displacement guard is not a proof of detecting every unannounced small teleport. The chosen 15 mm gate omits smaller motion, and the headset game-logic pose can lag rendering. These are limits of this record, not reasons to call it the whole body. See the technical companion for the Godot API references.

## Reproduce

Run `python doc/book/iterations/2026-09-24-head-trace/check_hall.py` from the project root. The script creates a private museum copy with output paths redirected into `ada_run/encounter_pilot/Point_Trace`. Runtime results, source hashes, exact changes and the chapter before/after are retained here. No live game restart, live museum bake/save replacement, commit or frozen full-book rebuild was performed.
