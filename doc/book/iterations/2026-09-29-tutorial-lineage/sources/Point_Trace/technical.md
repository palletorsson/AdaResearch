> Current arrangement, 29 September 2026: three plain drawing pens (10/40/80 mm), their plinth readouts, a whiteboard mounted on the uninterrupted east wall, and the ball ramp. The neutral dot, stick, head projection and writing desk are no longer placed. The dated implementation notes below retain the removed studies' history.

# Point Trace — implementation reference

The current book develops the selected-position recorder, its spatial grain, its sampling point, and the whiteboard's contact rule. [tutorial.md](tutorial.md) gives the short programming route. This reference distinguishes those installed behaviours from optional comparisons and possible extensions.

## Drawing dots and stick

Both scenes use [draw_dot.gd](../../primitives/point/draw_dot.gd). Their scene properties set `min_segment_distance = 0.005` metres and `trail_max_points = 4096`. Recording requires the pickable to be held. The dot observes its GrabPoint; the stick observes `GrabStick/Blade/Top/TrackBall`.

In the recording branch of `_process()`, the script reads the observed world position and compares it with `_last_global_position`. A reading below the movement threshold is declined. Passing the gate updates that comparison position before calling `_shape_sample()`. If the shaped result approximately equals the immediately preceding saved position, it is declined; otherwise it is appended.

The gate's reference is therefore the last gate-passing reading, not necessarily the last retained point or the previous frame's position. A released tool updates the reference without extending the trace. Returning to an earlier position after other saved positions is allowed.

The three drawing pens use 10 mm, 40 mm and 80 mm spacing. In free space the helper rounds world X, Y and Z to multiples of the spacing. Near a whiteboard it can shape the sample in the board's frame, then convert it back to world coordinates. That capture zone extends 0.05 m from the board plane, with 0.02 m around its bounds; positions are clamped to the face and offset 0.004 m for visibility. This behaviour is separate from the board's own pens.

## Reading the line

The retained coordinates enter an ImmediateMesh line strip. Adjacent positions are connected directly, including diagonals across the recording lattice. These segments are constructed geometry, not additional measurements.

The cased display tilts 35 degrees from vertical. Its count is read after capacity enforcement; the table shows the last ten retained positions in world metres, with at least three decimal places. Eighteen retained points produce rows 9–18. These numbers are current list positions, not permanent sample identifiers.

The three panels are fixed to their plinths and stay visible at zero points and after release. Appending or evicting points does not make it chase the newest endpoint. The casing and display do not change the data being reported.

When the list exceeds 4096 positions, its oldest position is removed. Live fading is off here. The optional `_trail_times` array is populated only when fading is enabled, so it is empty under these placements' default settings. The live position list does not encode the duration of stationary pauses.

## The whiteboard's pens

The map enables separate pens with `#pens:1`. [whiteboard_pen.gd](../../artifacts/whiteboard/whiteboard_pen.gd) reads the nib of the held tool; [whiteboard_drawing.gd](../../artifacts/whiteboard/whiteboard_drawing.gd) converts its world position into the drawing surface's local frame.

A nib outside the bounds or more than 0.035 m from the plane ends the stroke. The next valid contact starts another stroke. The four pens use 0/10/40/80 mm positional spacing before conversion to canvas coordinates. NO GRID omits that rounding; the image still consists of pixels.

At this board's 2.0 by 1.2 m size, the canvas is 1024 by 614 pixels. A brush with a three-pixel radius connects valid contacts; the eraser paints white with a 22-pixel radius. The dedicated `whiteboard_canvas.gd` retains a bounded pixel image and uploads changes once per frame when dirty. It has no wet-paint feedback, diffusion or idle fading. Its image stays with the board during this visit.

## Room arrangement and tool return

Three drawing pens occupy plinths at source cells (3,5), (4,5) and (5,5). Each readout stays seated on its 0.90 m support. `#pen_style:simple` replaces the held sphere with a 22.5 cm pen; the recorder follows its nib. A fixed, hand-independent XRTools grab point aligns local -Z with the pickup's forward direction. Recording waits for the grip to arrive, so the pickup approach is not drawn. Other draw_dot placements keep their original sphere.

The whiteboard is at source cell (7,2), with its lower edge 0.95 m above the floor, facing west into the hall. Its two-metre width lies entirely on the solid wall before the side-bay opening. `#pen_style:simple` opts this board into plain barrels with forward-aligned grips; its four resolutions, eraser, shelf and return behavior are retained. The same pen body helper serves both drawing in space and drawing on the board.

Released shelf tools fall under physics. A tool more than 0.25 m below its dock or more than 3 m away returns after 1.25 seconds in that condition. Its home transform is relative to the board, so wall rotation and placement are respected. Held tools never return. Both XRTools pickup and the desktop pointer's grab/drop hooks are supported. Other boards retain the floating-tool arrangement unless they opt into the shelf.

## Optional comparisons

The telemetry diptych uses [hand_telemetry_display.gd](../../primitives/hand_telemetry_display/hand_telemetry_display.gd). Its default sampling interval is 0.12 seconds. A process callback crossing that timer threshold appends the current time and position, even if a tracked controller has stayed still. Actual cadence remains limited by callbacks; this is not a guarantee of perfectly periodic sampling.

The footer labels a found controller node as TRACKING and the synthetic fallback as DEMO FEED. The lookup checks tracker/name but not active-pose validity or the currently driven rig; TRACKING therefore does not establish live hardware input by itself. Without a controller, synthetic motion fills the rows. Confirming the active source is a pending implementation improvement.

The removed automatic-writing desk used the `head_height` recording mode. It measures head height against elapsed time. The default `asemic` mode elsewhere retains the original speed-modulated generated script; see the measured-mode notes below.

## Short-memory companion

`trace_short_memory` inherits the existing draw-dot scene and recorder. Its capacity is 32 instead of 4096, its ink is amber, and its static plaque states the capacity. The extra data panel is disabled so it cannot obscure the drawing. A local display override draws each retained position as a 12 mm bead and each adjacent connection as a 7 mm cord. Two small MultiMeshes render the same list; there is no additional trajectory record. The 5 mm movement gate, unsnapped positions, pickup requirement, lack of time fading and release-to-TraceData behaviour are inherited unchanged. The three remaining drawing pens retain their recording resolutions.

The companion stands in the exit bay at cell (2,9), facing the approach from the central passage. A visitor can draw beyond the bay while carrying the point. Continuing a gesture eventually removes earlier positions, whereas a stationary pause leaves the retained list unchanged. Capacity counts accepted positions; its duration and spatial length depend on the movement and process callbacks. It is not a fixed-time trail.

The controlled Godot comparison supplies the same 72 positions through two held tools and their real recorder callbacks. The original keeps 72; the companion keeps exactly the last 32. A four-second synthetic pause does not remove any; a later accepted position removes one. Releasing copies the remaining 32 positions to TraceData. This establishes the mechanism, not headset comfort or whether a visitor enjoys drawing with it.

## Transfer into Grid

On release, the drawing pen calls [TraceData.add_trace()](../../globals/trace_data.gd). That function requires at least two positions and duplicates the list. Its autoload storage survives room changes in the running game. It has no trace disk-save operation here and does not copy pen colour, identity or per-point timestamps. The whiteboard and player_trace do not publish their records to this store.

[grid_lines.gd](../../primitives/line/grid_lines.gd) reads existing traces and listens for later releases. It subtracts the source bounding-box centre and applies a fivefold enlargement, reducing the factor if necessary to fit the longest dimension within five display metres. A second rendering rounds transformed coordinates to another lattice. Source positions remain unchanged. This supports the book's conditional ending: the bend may have grown.

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
