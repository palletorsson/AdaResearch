# Point Trace

Record the learner's motion as a persistent line.

Buffer recent positions.

```gdscript
var trace: Array = []  # list of Vector3
const MAX_POINTS := 200

func _process(_delta: float) -> void:
    var p: Vector3 = learner.global_position
    trace.append(p)
    if trace.size() > MAX_POINTS:
        trace.pop_front()
```

A ring buffer bounded at 200 samples. Older samples fall off as new ones arrive.

Render the trace as connected segments.

```gdscript
func render_trace() -> void:
    if trace.size() < 2: return
    clear_previous_segments()
    for i in range(trace.size() - 1):
        spawn_line_segment(trace[i], trace[i + 1])
```

Each consecutive pair becomes a short segment. The segments together form the trail.

Fade older segments.

```gdscript
func render_with_fade() -> void:
    for i in range(trace.size() - 1):
        var age_fraction: float = float(i) / trace.size()
        var color: Color = Color.WHITE.lerp(Color.TRANSPARENT, 1.0 - age_fraction)
        spawn_line_segment(trace[i], trace[i + 1], color)
```

Older segments have lower alpha. The trail reads as receding rather than infinite.

Simplify the trace for performance.

```gdscript
func simplify_trace(tolerance: float = 0.05) -> Array:
    var simplified: Array = [trace[0]]
    for i in range(1, trace.size() - 1):
        var prev = simplified[-1]
        if prev.distance_to(trace[i]) > tolerance:
            simplified.append(trace[i])
    simplified.append(trace[-1])
    return simplified
```

Points within the tolerance distance of their predecessor are dropped. The resulting trace uses fewer segments while preserving the shape.

Save the trace to disk.

```gdscript
func save_trace(path: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    for p in trace:
        file.store_line("%.3f %.3f %.3f" % [p.x, p.y, p.z])
```

Three floats per line, space-separated. The file is a human-readable record of the walk.

Load a previously saved trace.

```gdscript
func load_trace(path: String) -> Array:
    var loaded: Array = []
    var file := FileAccess.open(path, FileAccess.READ)
    while not file.eof_reached():
        var line: String = file.get_line()
        var parts := line.split_whitespace()
        if parts.size() == 3:
            loaded.append(Vector3(float(parts[0]), float(parts[1]), float(parts[2])))
    return loaded
```

The loaded trace can be replayed, compared with a current walk, or used as reference geometry.

You can now record a walk, render it as a decaying trail, simplify it for efficiency, and persist it to disk. Point_Line_Grid will next snap traces to a discrete grid so recorded motion becomes quantised history.

Compute the total path length.

```gdscript
func total_path_length() -> float:
    var total: float = 0.0
    for i in range(1, trace.size()):
        total += trace[i - 1].distance_to(trace[i])
    return total
```

Sum of consecutive distances. A direct walk produces a short path; wandering produces a long one.

Detect loops in the path.

```gdscript
func has_loop(tolerance: float = 0.3) -> bool:
    for i in range(trace.size()):
        for j in range(i + 10, trace.size()):
            if trace[i].distance_to(trace[j]) < tolerance:
                return true
    return false
```

A loop means the learner returned to a previous position. The 10-sample skip avoids matching neighbouring samples that are close by default.
