# Point Trace — let positions remain

Open this project's `project.godot` in the prepared Godot 4.6 environment from Day Zero. `trace.tscn` is the main scene. Follow TUTORIAL.md; the chapter assumes the finished Point Lines study. It takes two sessions: the first ends at *Stop here*, with the whole script as it should stand at that point.

`trace.tscn` inherits `line.tscn`, which inherits `base.tscn`. A, B, the segment and the distance readout come from Lines unchanged; `line.tscn`, `line.gd` and `segment.gd` are copies of the Lines kit, and `line.tscn` still runs on its own. `trace.tscn` puts `trace.gd` on the root, attaches `mover.gd` to B, adds `Strip` and `Record`, and raises the borrowed camera so the floor plane reads as a drawing.

`trace.gd` is the complete learner script: a typed list, a condition, a distance gate, a summed route length, a capacity of 32 and a pause. The tutorial rebuilds it from an empty list.

Supplied parts. `mover.gd` moves B parallel to the floor with `Input.get_vector()` over four named actions, `move_left`, `move_right`, `move_forward` and `move_backward` (WASD and the arrow keys). Its `autopilot` export runs a slow figure-eight with rests, for hands-off use. `trace_strip.gd` draws a list as one line strip through a single contract, `draw(points)`; it is used here and opened in Point_Triangle_Context. The Input Map also defines `pause` (Space), which the tutorial has you remove and add again.

Checks. `godot --headless --path . --xr-mode off --script res://verify.gd` runs 47 checks and writes `verification.json`; `verify.log` holds the last run's output. They cover the five actions and their keys, B moving under actions and real key events, a rebinding that needs no script edit, holding still adding nothing, a gate of zero adding one position per frame, the capacity dropping the oldest first, the route never shorter than the straight distance, the strip receiving the list in order, the pause, and the autopilot. Every code block in TUTORIAL.md was also run as its own step in Godot 4.6 (last on 2026-09-30, tab-indented as the page shows them), with the behaviour and messages the text reports. Parts marked *(editor)* describe the editor's windows and were not watched. A beginner learner trial remains distinct from these execution checks.

Fixed-camera desktop study. It contains no XR player and has not been tried in a headset. The museum's pens, ball and whiteboard are encounters in the hall, not parts of this download.

Lineage: Point Zero's continuing update → Point One's visible marker → Coordinates' positions → Lines' two endpoints and distance → kept positions, a gate, a capacity and a route length → Grid's snapped copy.
