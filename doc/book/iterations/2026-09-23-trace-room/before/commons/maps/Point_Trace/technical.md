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

At this board's 1.6 by 1.2 m size, the canvas is 1024 by 768 pixels. A three-pixel brush connects valid contacts; the eraser paints white with a 22-pixel radius. The adapter disables the prior wet-paint simulation and renders the canvas when a stroke changes. Its image stays with the board during this visit.

## Optional comparisons

The telemetry diptych uses [hand_telemetry_display.gd](../../primitives/hand_telemetry_display/hand_telemetry_display.gd). Its default sampling interval is 0.12 seconds. A process callback crossing that timer threshold appends the current time and position, even if a tracked controller has stayed still. Actual cadence remains limited by callbacks; this is not a guarantee of perfectly periodic sampling.

The footer labels a found controller node as TRACKING and the synthetic fallback as DEMO FEED. The lookup checks tracker/name but not active-pose validity or the currently driven rig; TRACKING therefore does not establish live hardware input by itself. Without a controller, synthetic motion fills the rows. Confirming the active source is a pending implementation improvement.

The automatic-writing desk uses changes of an available headset camera's position to vary the amplitude of wordless marks, with fallback demonstration motion. This mapping supports an experiment in interpreting marks; it does not measure confession, attention or intention.

## Transfer into Grid

On release, the dot or stick calls [TraceData.add_trace()](../../globals/trace_data.gd). That function requires at least two positions and duplicates the list. Its autoload storage survives room changes in the running game. It has no trace disk-save operation here and does not copy pen colour, identity or per-point timestamps. The whiteboard and player_trace do not publish their records to this store.

[grid_lines.gd](../../primitives/line/grid_lines.gd) reads existing traces and listens for later releases. It subtracts the source bounding-box centre and applies a fivefold enlargement, reducing the factor if necessary to fit the longest dimension within five display metres. A second rendering rounds transformed coordinates to another lattice. Source positions remain unchanged. This supports the book's conditional ending: the bend may have grown.

## Retained development material

The [previous technical draft](../../../doc/space/point-trace-focus-2026-09-16/previous/technical.md) preserves experiments in timestamps, simplification, fading and storage. Those sketches need separate implementation and verification. Its numerical memory comparison and its named simplification algorithm were not reliable descriptions of the installed recorder; they should not be used as current evidence.
