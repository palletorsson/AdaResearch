# Where could the line come from?

24 September 2026 — source inspection, not a headset trial.

The author asks for bodily sources before sine or random generators have been introduced. The new amber recorder meets that requirement in play: it samples the held point and retains 32 positions. Its revised screenshot fixture uses explicit piecewise-linear positions. Neither set of automated captures is a visitor recording.

## Existing sources

| Artifact / file | Actual input and transformation | Consequence for this hall |
| --- | --- | --- |
| `trace_short_memory`, inheriting `commons/primitives/point/draw_dot.gd` | Held point world position; 5 mm movement gate; consecutive joins; 32-position capacity. | Real tool motion is the source. Begins empty. The local renderer invents no extra positions. |
| `commons/primitives/point/player_trace.gd`, placed in Point_Lines | In VR, headset X/Z combined with rig floor height; in desktop, active walker position. | Already a route projected onto the floor, not a measurement of feet. It drops the headset's vertical movement. |
| `commons/primitives/hand_telemetry_display/hand_telemetry_display.gd`, paired in Point_Trace | Timed controller position rows; synthetic sine drift if no controller node is found. | Found node does not establish an active tracked pose. Validate the driven rig and pose; wait without invented samples when unavailable. |
| Three coloured `draw_dot` placements in Point_Trace | Live recording plus `retention:trace`, an appearance-only guide stroke calculated by `_ret_curve`. | The guides use sine. They are not the visitor's drawing. A map-local `retention:none` would remove those examples while keeping real drawing and resolution choices. Not applied in this correction. |
| `commons/primitives/automatic_writing_desk/automatic_writing_desk.gd` | Head-position speed controls the amplitude of generated sine handwriting; seeded rows and optional demo motion also use sine. | It is an interpretation of motion, not a literal head trace. Disabling its demo alone would not solve this distinction. |
| `commons/artifacts/science_screen/science_screen.gd` | Point mode traces a found point, alongside random target gameplay; trace mode can read a drawing artifact's retained list. | Prefer an explicit source and a measured-trace view for this chapter; do not infer headset tracking from a screen's moving mark. |

## Proposed next encounter, not yet built

Reuse the bodily route idea: record full headset positions and show the same list as a line suspended in space and as its floor projection. Leaning and crouching change one view while their height is absent from the other. The existing player trace supplies a starting point for input selection, but full-height recording is a new mode.

A further option is to trace where the headset's forward direction meets a board. This can make a line while the visitor turns in place. Label it head direction, not eye gaze; eye tracking requires a separate supported and validated input. Break the stroke when the ray misses the board or tracking is lost rather than joining across absent samples.

For each bodily recorder: explicitly choose room-relative or world-relative coordinates; handle teleport/recentering as a break, not a line through intervening space; validate the active input; show no fabricated movement during tracking loss. Desktop camera input must be labelled separately from headset input.

The immediate artistic question can stay simple: the hand makes a mark on purpose; the head leaves another while attending to it. What does flattening those movements keep, and what does it lose?
