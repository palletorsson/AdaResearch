# Point Trace - Technical Tutorial

## The Trace as Sampled Recording

A trace accumulates an ordered selection of positions. The placed draw_dot and draw_stick scenes admit movement of at least 5 mm, optionally round it to a grid, reject consecutive duplicate results and retain at most 4096 positions. The examples below develop possible recorders; they are simplified sketches, not the complete installed scripts. In particular, the timestamp and disk-storage examples are extensions, not fields or controls promised by the current recorders.

```gdscript
# Line: Two points, instant result
var line_start = Vector3(0, 0, 0)
var line_end = Vector3(5, 0, 0)
var distance = line_start.distance_to(line_end)  # Instant: 5.0

# Trace: Continuous recording
var trace_points = []  # Accumulates over time

func _process(delta):
    var current_position = controller.global_position
    trace_points.append(current_position)
    # Result grows with every frame - not predetermined
```

The trace has **no final form** until movement stops. It cannot be known in advance.

## Reading the installed instrument

The four drawing dots on plinths use no added grid, 10 mm, 40 mm and 80 mm spacing. Their shared recorder presents a cased panel tilted 35 degrees from vertical. The large count comes from `_trail_points.size()` after capacity enforcement; the coordinate table shows at most ten entries, numbered by their current one-based position in that array. Eighteen retained points therefore show rows 9–18. These are current array addresses, not persistent sample IDs.

For draw_dot and draw_stick, the coordinates are world metres even when `_shape_sample()` quantizes them in a whiteboard's frame. The board capture zone extends 0.05 m from the face and includes a 0.02 m tolerance around its bounds. Accepted coordinates are clamped to the face bounds and placed 0.004 m in front to make the stroke visible. Away from the board, quantization uses world axes.

The display captures its anchor beside the trace when it first appears. Appending points or evicting the oldest point does not move the panel; clearing the trace hides it and lets the next record establish a new anchor. Text, backing and casing share one transform. `commons/ui/instrument_panel_case.gd` supplies the reusable housing; it adds no input controls or collision barrier.

## The whiteboard has its own pens

The `whiteboard` token opts in with `#pens:1`. Its four pens and eraser are children of the board, independent of `draw_dot`. `whiteboard_drawing.gd` reuses the project's `drawingboard/pen.tscn` model and `paper_draw_surface.gd` canvas. `whiteboard_pen.gd` reads the visible nib while the XRTools pickable is held. A nib outside the board bounds or more than 0.035 m from the writing plane ends the stroke; returning starts a new one.

Board-local horizontal and vertical positions are rounded to the chosen 0/10/40/80 mm pitch before conversion to UV coordinates. At the Trace board's 1.6 by 1.2 m size, the canvas is 1024 by 768 pixels. The brush connects accepted contacts, using a three-pixel radius; the eraser paints white with a 22-pixel radius. No added positional grid does not mean an infinitely resolved texture or continuous tracking.

The adapter disables the old wet-paint simulation so ink does not diffuse or fade. The canvas renders once when a stroke changes and retains its image between updates. It stays attached to the board, and has no disk persistence in this encounter. The dot's numeric panel still describes its own retained position array; it does not count pixels or samples from these separate board pens.

## Implementing draw_dot: Recording Controller Movement

The installed `draw_dot` records its held point; `draw_stick` records the tip of its rod. This simplified implementation introduces a movement gate. The current scenes use a 0.005 m threshold and add spatial shaping and duplicate rejection after that gate:

```gdscript
extends Node3D

var is_drawing: bool = false
var current_line_points: PackedVector3Array = []
var line_mesh: ImmediateMesh
var mesh_instance: MeshInstance3D
var min_distance: float = 0.01  # Minimum distance between points

func _ready():
    # Setup immediate mesh for dynamic line drawing
    line_mesh = ImmediateMesh.new()
    mesh_instance = MeshInstance3D.new()
    mesh_instance.mesh = line_mesh

    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.3, 0.7, 1.0)
    material.emission_enabled = true
    material.emission = Color(0.5, 0.8, 1.0)
    material.emission_energy = 2.0
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mesh_instance.material_override = material

    add_child(mesh_instance)

func _on_trigger_pressed():
    is_drawing = true
    current_line_points.clear()
    var start_pos = global_position
    current_line_points.append(start_pos)

func _on_trigger_released():
    is_drawing = false

func _process(delta):
    if is_drawing:
        var current_pos = global_position

        # Only add point if moved sufficient distance
        if current_line_points.size() == 0 or \
           current_pos.distance_to(current_line_points[-1]) > min_distance:
            current_line_points.append(current_pos)
            update_line_mesh()

func update_line_mesh():
    line_mesh.clear_surfaces()

    if current_line_points.size() < 2:
        return

    line_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

    for point in current_line_points:
        line_mesh.surface_add_vertex(point)

    line_mesh.surface_end()
```

## The Sampling Problem

The visible trace connects discrete samples. The installed recorder can inspect a position on each `_process` call, but the movement and duplicate gates determine whether it retains that position. Neither a fixed frame rate nor one accepted sample per frame is guaranteed.

```gdscript
# What we record (sampled)
var trace_points = [
    Vector3(0, 0, 0),      # Frame 1
    Vector3(0.1, 0, 0),    # Frame 2
    Vector3(0.2, 0.05, 0), # Frame 3
    # ... gaps between frames
]

# What actually happened (continuous)
# Infinite positions between samples - lost forever
```

The trace can preserve intermediate positions a two-endpoint segment omits. It does not preserve the entire path between accepted samples.

## Duration as Data

To retain explicit timing, we could extend the recorder with timestamps. The placed pens have fading off, so their live position lists do not currently encode pause duration:

```gdscript
# Trace with timestamps
var trace_with_time = []

func record_position():
    var timestamp = Time.get_ticks_msec()
    var position = global_position
    trace_with_time.append({
        "position": position,
        "time": timestamp
    })

# Calculate drawing duration
func get_trace_duration() -> float:
    if trace_with_time.size() < 2:
        return 0.0

    var start_time = trace_with_time[0].time
    var end_time = trace_with_time[-1].time
    return (end_time - start_time) / 1000.0  # Convert to seconds

# Calculate drawing speed
func get_average_speed() -> float:
    var total_distance = 0.0

    for i in range(1, trace_with_time.size()):
        var prev_pos = trace_with_time[i-1].position
        var curr_pos = trace_with_time[i].position
        total_distance += prev_pos.distance_to(curr_pos)

    var duration = get_trace_duration()
    return total_distance / duration if duration > 0 else 0.0
```

The trace knows **how long** and **how fast** - data that points and lines cannot hold.

## Trace vs. Line: Data Comparison

```gdscript
# Line data structure (minimal)
var line = {
    "start": Vector3(0, 0, 0),
    "end": Vector3(5, 3, 0),
    "distance": 5.83  # Calculated once
}
# Memory: 3 Vector3 values + 1 float = ~28 bytes

# Trace data structure (accumulating)
var trace = {
    "points": [
        Vector3(0, 0, 0),
        Vector3(0.1, 0.02, 0),
        Vector3(0.2, 0.05, 0),
        # ... potentially hundreds of points
    ],
    "start_time": 12345,
    "end_time": 12890
}
# Memory: N * 12 bytes (where N = number of samples)
# Hypothetical 180 float32 Vector3 values: 2,160 bytes before container metadata
```

The trace is **77x more data** for the same spatial extent. This is the cost of preserving duration.

## Persistence and Erasure

The trace can be saved or cleared:

```gdscript
# Save trace permanently
var saved_traces = []

func save_current_trace():
    saved_traces.append(current_line_points.duplicate())

# Clear trace (erasing history)
func clear_trace():
    current_line_points.clear()
    update_line_mesh()

# Fade trace over time (decay)
func apply_trace_decay(fade_rate: float):
    for saved_trace in saved_traces:
        # Reduce opacity or delete old points
        pass  # Implementation would modify material alpha
```

Unlike mathematical objects, traces can **fade** - they exist in time and can disappear.

## Performance Considerations

Continuous trace recording has computational cost:

```gdscript
# Optimization: Simplify trace by removing redundant points
func simplify_trace(tolerance: float = 0.05):
    if current_line_points.size() < 3:
        return

    var simplified = [current_line_points[0]]

    for i in range(1, current_line_points.size() - 1):
        var prev = simplified[-1]
        var curr = current_line_points[i]
        var next = current_line_points[i + 1]

        # Check if current point is necessary (Ramer-Douglas-Peucker)
        var line_dist = point_to_line_distance(curr, prev, next)

        if line_dist > tolerance:
            simplified.append(curr)

    simplified.append(current_line_points[-1])
    current_line_points = simplified

func point_to_line_distance(point: Vector3, line_start: Vector3, line_end: Vector3) -> float:
    var line_vec = line_end - line_start
    var point_vec = point - line_start
    var line_len = line_vec.length()

    if line_len == 0:
        return point_vec.length()

    var t = point_vec.dot(line_vec) / (line_len * line_len)
    t = clamp(t, 0.0, 1.0)

    var projection = line_start + line_vec * t
    return point.distance_to(projection)
```

Simplification reduces the trace to "significant" points - a partial return to line-like compression.

## Key Takeaway

The trace keeps selected positions in order. Duration, intention and the movement between those positions need another account. Sampling and finite storage make some comparisons possible while leaving others unavailable.

The current table reports retained world positions in metres with millimetre-scale precision and stays visible after release. Compare two rows, pause, and compare again. The record supports a claim about retained positions; it cannot by itself prove the gesture's speed, duration or intention.


## Encounter reference, 15 September 2026

[Companion notes for the current book passage](encounter-reference.md) retain instrument settings, recording distinctions and code excerpts moved out of the main reading.
