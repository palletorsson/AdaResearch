# Point Trace — recording rules in the installed hall

Current arrangement, 17 October 2026: pens on transparent glass, three held spatial beads, the sampling monitor and ball ramp. The 24 × 24-cell map and its museum plan use the same placements. Older studies below are retained development history, not the current installation.

## Glass contact

`glass_paint_wall` extends the existing whiteboard with a 3.0 × 1.1 m clear pane. Its bottom is 0.75 m above the hall floor. The two supports and feet stand on the floor; a thin collision box occupies the pane. The four plain pens and eraser use the existing shelf and return behaviour.

`glass_surface` / `config_glass` is an opt-in flag. The body uses an alpha material; the dry-ink canvas starts with transparent pixels, draws opaque ink, and erases to alpha zero. Ink renders from both sides. Other whiteboards retain their white canvas and white eraser. At this aspect ratio the image is 1024 × 375 pixels; it is a bounded image, not a growing mesh archive.

The pen's nib must be within the writing rectangle and 0.035 m of its drawing plane. Leaving that range ends the stroke. Four pens use no positional grid, 10 mm, 40 mm and 80 mm respectively before mapping accepted contacts into image coordinates. The ungridded pen still produces a pixel image. Brush radius is three pixels; eraser radius is twenty-two.

Shelf tools are pickable through desktop and XRTools. On release they fall; leaving their dock by more than the return threshold invokes the existing delayed return. The glass image stays in this hall for this visit and is not published to TraceData.

## Beads in space

The three `draw_dot` placements opt into `#tool:bead`. A small pickable sphere replaces the former pen; its centre is the observed point. The held tool supports desktop pickup hooks and XRTools' snapped grip state. Recording waits for the pickup to settle and stops on release. Beads ignore nearby board planes, so proximity to the glass cannot flatten the spatial trace.

The recorder keeps its existing five-millimetre movement gate, 4096-position capacity, and 10/40/80 mm world-coordinate rounding. The movement gate compares against the last gate-passing reading; immediately repeated shaped positions are omitted. Returning to an earlier address after another retained position is allowed. A stationary pause does not encode its duration.

Adjacent retained positions become straight segments. Neither the samples nor these joins recover the whole motion. The plinth panels show the current count and last ten retained world positions. They stay fixed at the stations. The sampling monitor discovers the same recorder scripts after the tool replacement. It observes the held tool before the bead's rounding, retains its own record and compares several spacings applied to it; it is not reading the bead's already-rounded list.

## Transfer and its limits

On release, at least two retained positions are copied into the `TraceData` autoload. This is session storage, not a disk save. Neither colour nor timestamps travel with the list. Grid reads existing lists and listens for later releases. It recentres and scales the positions for pink, and rounds their displayed coordinates for green; source positions remain unchanged.

The tutorial independently implements a small scene-file archive at `user://ada_student_trace.scn`. Its persistence belongs to that student program, not to the museum's session store. The ball ramp records its centre after release and retains its path locally; it also does not publish to TraceData.

## Arrangement

Entry is (12,0). Glass (7,5) precedes beads (4/6/8,11); the sampling monitor stands at (2,10). The ramp at (18,14) has a clear run toward the rear. Telemetry, science screen and film occupy row 21. Exit is (12,23). Coordinates refer to source cells.

## Retained development material

The [previous technical draft](../../../doc/space/point-trace-focus-2026-09-16/previous/technical.md) preserves experiments in timestamps, simplification, fading and storage. Those sketches need separate implementation and verification. Its numerical memory comparison and its named simplification algorithm were not reliable descriptions of the installed recorder; they should not be used as current evidence.


## Head path and floor projection — 24 September 2026

`head_trace_projection` occupies cell (2,3), centred at (2.5, 0, 3.5). Its 2.2 m square is a flush visual mark over the existing museum floor, with no added obstacle collider. Pink records full positions; cyan is derived from that same list by `Vector3(p.x, FLOOR_Y, p.z)` in the artifact's local frame. It measures neither feet nor eye gaze. Locomotion is included in the world camera position before conversion to the hall-relative frame.

Input comes from the current XRCamera3D under the current XROrigin3D, with an initialized primary XR interface reporting normal tracking. There is no synthetic fallback. Without active XR, a camera belonging to the active `em_walker` can supply the separately labelled DESKTOP VIEW. Spectator/capture cameras are excluded. Godot notes that the game-logic [XRCamera3D position](https://docs.godotengine.org/en/4.6/classes/class_xrcamera3d.html) may lag the render-thread pose; this is a sampled headset account, not an unmediated body. The interface's [tracking status](https://docs.godotengine.org/en/4.6/classes/class_xrinterface.html#class-xrinterface-method-get-tracking-status) determines admission; unknown or degraded status waits rather than inventing movement.

Accepted positions are at least 15 mm apart, with a shared capacity of 256. The recorder operates on process callbacks without interpolation of missing measurements. Tracking loss, source changes, XRTools teleport, reference/play-area changes, frame gaps above 0.25 s and single-step displacements above 0.45 m prevent a joining segment. The displacement limit is a guard, not proof that every unsignalled discontinuity can be detected. A new observer begins a separate record. Zero-length projected joins are omitted, while their coincident positions remain represented.

Leaving the square preserves the display. After 0.6 s outside, re-entering starts a fresh drawing. Merely waiting or temporarily losing tracking does not erase the previous record. Head/floor history is local to this artifact and is not published to TraceData or carried into Grid.

Validation and labelled scripted camera captures: [head-path review](../../../doc/book/iterations/2026-09-24-head-trace/index.html). The probe exercises production input selection with controlled desktop and XR fixtures; it is not a headset or learner trial.


## The pause leaves a line — measured writing mode

The existing desk at cell (4,1) now uses `#recording:head_height#rows:5#write_speed:0.06#run_demo:0`. This is an opt-in companion, `measured_height_writer.gd`, called by the original script. Other placements keep the default `asemic` generator. The measured branch never seeds handwriting, invokes `_row_v`, or substitutes demo motion. Its identity/registry text now distinguishes the two modes and avoids claiming to measure attention or confession.

The desk and spatial head trace share `commons/artifacts/trace_shared/measured_view_source.gd`. This extraction preserves current-rig and normal-XR-tracking checks, desktop walking-camera labels, and teleport/reference-change notification. Capturing a spectator camera is refused. The spatial trace's existing behaviour is covered by the regression probe.

The writing begins when the observer is in the reading position in front of the table (local X within 0.8 m, Z from 0.40 to 1.65 m, height from 0.2 to 3.2 m). The initial local camera height supplies a baseline. Time advances U at 0.06 page fractions per second across 0.84 of a row. Height relative to that baseline moves V, clamped to +/-0.70 m and a bounded row amplitude. The sign reports `row limit` beyond that range. Raw accepted heights and elapsed times remain in parallel arrays. Sideways movement and gaze are not height measurements.

A sample is accepted on a callback at least 0.05 s after the prior accepted sample, without filling intervening positions. Actual cadence therefore depends on frame timing. During tracking/view loss in an active visit, time continues but ink is omitted. Long frame gaps (>0.25 s), large displacements (>0.45 m), and notified teleports/recentering also omit an observation rather than invent a connecting gesture. The stroke consists of fine measured dots, not an interpolated waveform.

The page has five rows, nominally 70 seconds of clock space, and a separate maximum of 1800 samples. Reaching either limit holds the page. Leaving preserves it; after 0.6 s outside, returning starts a new page and height baseline. Changing the observer also starts a new record. Nothing is exported to TraceData.

Visual inspection found the original tilted paper intersected its tabletop, hiding early marks. In measured mode its centre is lifted by the vertical component of half its depth, so the entire sheet clears the table; the compact label rises with it. This correction is local to measured mode.

[Actual museum images and focused evidence](../../../doc/book/iterations/2026-09-24-trace-pause/index.html) use explicitly supplied camera coordinates, including constant input and linear height changes. The checks compare the measured desk with the real held `draw_dot` recorder and cover the shared head selector. They do not establish headset comfort, learner discovery, or Quest performance.

## 26 September 2026 — Point released to gravity

`trace_ball_ramp` occupies a new side bay at source cell (12,2), with an open approach at x=8, z=4..6. The 0.28 m diameter black sphere uses XRToolsPickable, dynamic release, layer 6/mask 1 and native rigid-body gravity. A 1 m plinth leads to a 0.82 m-wide sloped plank and shallow landing tray. The trace samples its released centre at a minimum 18 mm movement, stops adding at rest, and retains at most 1024 segments. A new release clears the previous path. Picking up pauses recording; abandoned balls recover after falling below the room or leaving the installation. No scripted downhill motion. This path stays in the hall; existing hand-drawn TraceData publishing remains unchanged. Native tests exercise the production pickup/release; headset feel is pending.
