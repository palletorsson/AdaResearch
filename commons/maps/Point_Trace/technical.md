# Point Trace - Technical Tutorial

## The Trace as Continuous Recording

A trace is not calculated - it is **accumulated**. Unlike a line (two points, one calculation), a trace records every position over time.

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

## Implementing draw_dot: Recording Controller Movement

The `draw_dot` tool tracks VR controller position and draws a continuous line through space:

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

The trace appears continuous, but it's actually **sampled** at frame rate (60-90 Hz in VR).

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

The trace preserves **more** than the line (entire path, not just endpoints) but still **less** than the actual movement (gaps between samples).

## Duration as Data

Unlike geometric primitives, the trace encodes **time**:

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
# For 2 seconds at 90fps: 180 points * 12 bytes = 2,160 bytes
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

The trace is geometry that **remembers**. It preserves duration, gesture, and the path itself - not just the result. But preservation requires **continuous sampling** and **accumulating storage**. The trace resists the clean compression of points and lines, insisting that **how you moved matters**, not just where you ended up.

The draw_dot tool makes this visible: Your hand's movement through VR space becomes persistent geometry. The trace is **proof of passage** - evidence that a body moved through this space at this speed for this duration.
