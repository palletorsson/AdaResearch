# Point Trace — implementation reference

The current book develops the selected-position recorder, its spatial grain, its sampling point, and the whiteboard's contact rule. [tutorial.md](tutorial.md) gives the short programming route. This reference distinguishes those installed behaviours from optional comparisons and possible extensions.

## Drawing dots and stick

Both scenes use [draw_dot.gd](../../primitives/point/draw_dot.gd). Their scene properties set `min_segment_distance = 0.005` metres and `trail_max_points = 4096`. Recording requires the pickable to be held. The dot observes its GrabPoint; the stick observes `GrabStick/Blade/Top/TrackBall`.

In the recording branch of `_process()`, the script reads the observed world position and compares it with `_last_global_position`. A reading below the movement threshold is declined. Passing the gate updates that comparison position before calling `_shape_sample()`. If the shaped result approximately equals the immediately preceding saved position, it is declined; otherwise it is appended.

The gate's reference is therefore the last gate-passing reading, not necessarily the last retained point or the previous frame's position. A released tool updates the reference without extending the trace. Returning to an earlier position after other saved positions is allowed.

The four dot placements use no added lattice, 10 mm, 40 mm and 80 mm spacing. In free space the helper rounds world X, Y and Z to multiples of the spacing. Near a whiteboard it can shape the sample in the board's frame, then convert it back to world coordinates. That capture zone extends 0.05 m from the board plane, with 0.02 m around its bounds; positions are clamped to the face and offset 0.004 m for visibility. This behaviour is separate from the board's own pens.

## Reading the line

The retained coordinates enter an ImmediateMesh line strip. Adjacent positions are connected directly, including diagonals across the recording lattice. These segments are constructed geometry, not additional measurements.

The cased display tilts 35 degrees from vertical. Its count is read after capacity enforcement; the table shows the last ten retained positions in world metres, with at least three decimal places. Eighteen retained points produce rows 9–18. These numbers are current list positions, not permanent sample identifiers.

The panel anchors beside the trace and remains readable after release. Appending or evicting points does not make it chase the newest endpoint. The casing and display do not change the data being reported.

When the list exceeds 4096 positions, its oldest position is removed. Live fading is off here. The optional `_trail_times` array is populated only when fading is enabled, so it is empty under these placements' default settings. The live position list does not encode the duration of stationary pauses.

## The whiteboard's pens

The map enables separate pens with `#pens:1`. [whiteboard_pen.gd](../../artifacts/whiteboard/whiteboard_pen.gd) reads the nib of the held tool; [whiteboard_drawing.gd](../../artifacts/whiteboard/whiteboard_drawing.gd) converts its world position into the drawing surface's local frame.

A nib outside the bounds or more than 0.035 m from the plane ends the stroke. The next valid contact starts another stroke. The four pens use 0/10/40/80 mm positional spacing before conversion to canvas coordinates. NO GRID omits that rounding; the image still consists of pixels.

At this board's 2.0 by 1.2 m size, the canvas is 1024 by 614 pixels. A three-pixel brush connects valid contacts; the eraser paints white with a 22-pixel radius. The adapter disables the prior wet-paint simulation and renders the canvas when a stroke changes. Its image stays with the board during this visit.

## Room arrangement and tool return

The four drawing dots and the stick occupy five equally spaced plinths centred on the room at X = 4.5 m. Their recording configuration is unchanged. The whiteboard faces into the room from the east wall; its lower edge is 0.95 m above the floor, with a 0.925 m shelf. The hand-telemetry diptych sits 0.45 m higher than before, against the rear wall. The science screen occupies the clear rear-wall panel across the doorway, using its recessed pylon housing. Its face is 1.3 by 1.1 m, centred about 2.03 m above the floor; the housing stays clear of the vertical wall trim. The map excludes automatically placed benches because one blocked the drawing aisle.

`#pen_shelf:1` enables the board's shelf and return behaviour in this map. Four grips distinguish the existing inks and resolutions: beads, a loop, fins and a stepped sleeve. Labels stay on the shelf. The eraser has its own place. Each tool remains the same rigid body throughout pickup, release and return.

Released shelf tools fall under physics. A tool more than 0.25 m below its dock or more than 3 m away returns after 1.25 seconds in that condition. Its home transform is relative to the board, so wall rotation and placement are respected. Held tools never return. Both XRTools pickup and the desktop pointer's grab/drop hooks are supported. Other boards retain the floating-tool arrangement unless they opt into the shelf.

## Optional comparisons

The telemetry diptych uses [hand_telemetry_display.gd](../../primitives/hand_telemetry_display/hand_telemetry_display.gd). Its default sampling interval is 0.12 seconds. A process callback crossing that timer threshold appends the current time and position, even if a tracked controller has stayed still. Actual cadence remains limited by callbacks; this is not a guarantee of perfectly periodic sampling.

The footer labels a found controller node as TRACKING and the synthetic fallback as DEMO FEED. The lookup checks tracker/name but not active-pose validity or the currently driven rig; TRACKING therefore does not establish live hardware input by itself. Without a controller, synthetic motion fills the rows. Confirming the active source is a pending implementation improvement.

The automatic-writing desk uses changes of an available headset camera's position to vary the amplitude of wordless marks, with fallback demonstration motion. This mapping supports an experiment in interpreting marks; it does not measure confession, attention or intention.

## Short-memory companion

`trace_short_memory` inherits the existing draw-dot scene and recorder. Its capacity is 32 instead of 4096, its ink is amber, and its static plaque states the capacity. The extra data panel is disabled so it cannot obscure the drawing. A local display override draws each retained position as a 12 mm bead and each adjacent connection as a 7 mm cord. Two small MultiMeshes render the same list; there is no additional trajectory record. The 5 mm movement gate, unsnapped positions, pickup requirement, lack of time fading and release-to-TraceData behaviour are inherited unchanged. The original four dots and stick retain their configurations.

The companion stands in the exit bay at cell (2,9), facing the approach from the central passage. A visitor can draw beyond the bay while carrying the point. Continuing a gesture eventually removes earlier positions, whereas a stationary pause leaves the retained list unchanged. Capacity counts accepted positions; its duration and spatial length depend on the movement and process callbacks. It is not a fixed-time trail.

The controlled Godot comparison supplies the same 72 positions through two held tools and their real recorder callbacks. The original keeps 72; the companion keeps exactly the last 32. A four-second synthetic pause does not remove any; a later accepted position removes one. Releasing copies the remaining 32 positions to TraceData. This establishes the mechanism, not headset comfort or whether a visitor enjoys drawing with it.

## Transfer into Grid

On release, the dot or stick calls [TraceData.add_trace()](../../globals/trace_data.gd). That function requires at least two positions and duplicates the list. Its autoload storage survives room changes in the running game. It has no trace disk-save operation here and does not copy pen colour, identity or per-point timestamps. The whiteboard and player_trace do not publish their records to this store.

[grid_lines.gd](../../primitives/line/grid_lines.gd) reads existing traces and listens for later releases. It subtracts the source bounding-box centre and applies a fivefold enlargement, reducing the factor if necessary to fit the longest dimension within five display metres. A second rendering rounds transformed coordinates to another lattice. Source positions remain unchanged. This supports the book's conditional ending: the bend may have grown.

## Retained development material

The [previous technical draft](../../../doc/space/point-trace-focus-2026-09-16/previous/technical.md) preserves experiments in timestamps, simplification, fading and storage. Those sketches need separate implementation and verification. Its numerical memory comparison and its named simplification algorithm were not reliable descriptions of the installed recorder; they should not be used as current evidence.


## Head path and floor projection — 24 September 2026

`head_trace_projection` occupies cell (2,3), centred at (2.5, 0, 3.5). Its 2.2 m square is a flush visual mark over the existing museum floor, with no added obstacle collider. Pink records full positions; cyan is derived from that same list by `Vector3(p.x, FLOOR_Y, p.z)` in the artifact's local frame. It measures neither feet nor eye gaze. Locomotion is included in the world camera position before conversion to the hall-relative frame.

Input comes from the current XRCamera3D under the current XROrigin3D, with an initialized primary XR interface reporting normal tracking. There is no synthetic fallback. Without active XR, a camera belonging to the active `em_walker` can supply the separately labelled DESKTOP VIEW. Spectator/capture cameras are excluded. Godot notes that the game-logic [XRCamera3D position](https://docs.godotengine.org/en/4.6/classes/class_xrcamera3d.html) may lag the render-thread pose; this is a sampled headset account, not an unmediated body. The interface's [tracking status](https://docs.godotengine.org/en/4.6/classes/class_xrinterface.html#class-xrinterface-method-get-tracking-status) determines admission; unknown or degraded status waits rather than inventing movement.

Accepted positions are at least 15 mm apart, with a shared capacity of 256. The recorder operates on process callbacks without interpolation of missing measurements. Tracking loss, source changes, XRTools teleport, reference/play-area changes, frame gaps above 0.25 s and single-step displacements above 0.45 m prevent a joining segment. The displacement limit is a guard, not proof that every unsignalled discontinuity can be detected. A new observer begins a separate record. Zero-length projected joins are omitted, while their coincident positions remain represented.

Leaving the square preserves the display. After 0.6 s outside, re-entering starts a fresh drawing. Merely waiting or temporarily losing tracking does not erase the previous record. Head/floor history is local to this artifact and is not published to TraceData or carried into Grid.

Validation and labelled scripted camera captures: [head-path review](../../../doc/book/iterations/2026-09-24-head-trace/index.html). The probe exercises production input selection with controlled desktop and XR fixtures; it is not a headset or learner trial.
