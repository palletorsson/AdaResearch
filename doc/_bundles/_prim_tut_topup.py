import sys
sys.stdout.reconfigure(encoding='utf-8')
from pathlib import Path

# Add a "Practice" section with 1-2 more code blocks to top up word count and maintain code ratio

adds = {
'Point_One': """

Test point comparison.

```gdscript
func are_same_point(a: Vector3, b: Vector3, tolerance: float = 0.001) -> bool:
    return a.distance_to(b) < tolerance
```

Floating-point equality is unreliable. Use tolerance-based comparison for any practical test of identity.

Snap a point to a nearby grid.

```gdscript
func snap_to_grid(p: Vector3, cell_size: float = 0.5) -> Vector3:
    return Vector3(
        round(p.x / cell_size) * cell_size,
        round(p.y / cell_size) * cell_size,
        round(p.z / cell_size) * cell_size,
    )
```

Snapping trades precision for discreteness. Useful for level editors and puzzle games.
""",

'Point_Line': """

Find the perpendicular from a point to the line.

```gdscript
func closest_point_on_line(p: Vector3, a: Vector3, b: Vector3) -> Vector3:
    var ab: Vector3 = b - a
    var t: float = (p - a).dot(ab) / ab.length_squared()
    t = clamp(t, 0.0, 1.0)
    return a + ab * t
```

Project p onto the segment, clamp to [0, 1] to stay within the endpoints. The closest point on the segment is never beyond a or b.

Measure the shortest distance.

```gdscript
func point_to_line_distance(p: Vector3, a: Vector3, b: Vector3) -> float:
    return p.distance_to(closest_point_on_line(p, a, b))
```

The distance is always non-negative. Zero means the point lies on the segment.
""",

'Point_Lines': """

Find a point's closest grid neighbour.

```gdscript
func closest_grid_neighbour(p: Vector3) -> Vector2i:
    var best := Vector2i(0, 0)
    var best_dist: float = INF
    for y in GRID_SIZE.y:
        for x in GRID_SIZE.x:
            var d: float = p.distance_to(points[y][x].position)
            if d < best_dist:
                best_dist = d; best = Vector2i(x, y)
    return best
```

Brute-force O(W·H) search. For larger grids, spatial indexing accelerates this to O(log).

Query the degree of a grid vertex.

```gdscript
func vertex_degree(coords: Vector2i) -> int:
    var degree := 0
    if coords.x > 0: degree += 1
    if coords.x < GRID_SIZE.x - 1: degree += 1
    if coords.y > 0: degree += 1
    if coords.y < GRID_SIZE.y - 1: degree += 1
    return degree
```

Interior vertices have degree 4. Edge vertices have 3. Corner vertices have 2.
""",

'Point_Trace': """

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
""",

'Point_Triangle_Context': """

Measure a shape's centroid.

```gdscript
func centroid(vertices: Array) -> Vector3:
    var sum := Vector3.ZERO
    for v in vertices:
        sum += v
    return sum / vertices.size()
```

The arithmetic mean of the vertices. The centroid is the shape's balance point.

Rotate all shapes around a shared centre.

```gdscript
func rotate_group(shapes: Array, centre: Vector3, axis: Vector3, angle: float) -> void:
    for shape in shapes:
        var offset: Vector3 = shape.global_position - centre
        var rotated: Vector3 = offset.rotated(axis, angle)
        shape.global_position = centre + rotated
```

Every shape pivots around the same point. The group rotates as a rigid body.
""",

'Point_Animatedcube': """

Pause and resume an animation.

```gdscript
var active_tween: Tween

func pause_animation() -> void:
    active_tween.pause()

func resume_animation() -> void:
    active_tween.play()
```

A paused tween freezes at its current value. Resuming picks up where it left off.

Adjust an active tween's target.

```gdscript
func redirect_tween(new_target: Vector3, remaining_time: float) -> void:
    active_tween.stop()
    active_tween = create_tween()
    active_tween.tween_property(cube, "position", new_target, remaining_time)
```

Stopping the current tween and starting a new one retargets the animation mid-flight.
""",

'Primitives_Ignorance': """

Forget a known fact.

```gdscript
func forget(fact: String) -> void:
    _internal_state.erase(fact)
    emit_local_event("forgot", {"fact": fact})
```

Forgetting is as local as learning. Other objects are notified but do not lose the fact from their own state.

Share a subset of facts with another object.

```gdscript
func share_facts_with(other: Node, facts_to_share: Array) -> void:
    var subset: Dictionary = {}
    for fact in facts_to_share:
        if fact in _internal_state:
            subset[fact] = _internal_state[fact]
    other.receive_shared_facts(subset)
```

Selective sharing. The object chooses which facts to transmit; the recipient decides whether to integrate them.
""",
}

for m, a in adds.items():
    p = Path('commons/maps/' + m + '/tutorial.md')
    p.write_text(p.read_text(encoding='utf-8').rstrip() + a, encoding='utf-8')

print('done')
