# Cantor Set

Remove the middle third. Recurse. Fractal dimension 0.631.

Generate Cantor intervals.

```gdscript
func cantor_intervals(start: float, end: float, depth: int) -> Array:
    if depth == 0:
        return [[start, end]]
    var third_length: float = (end - start) / 3.0
    var left_intervals: Array = cantor_intervals(start, start + third_length, depth - 1)
    var right_intervals: Array = cantor_intervals(end - third_length, end, depth - 1)
    return left_intervals + right_intervals
```

Recursive: split into thirds, keep outer thirds. 2^n intervals at depth n.

Render intervals as cylinders.

```gdscript
func render_cantor(intervals: Array, y: float, length: float) -> void:
    for interval in intervals:
        var segment := MeshInstance3D.new()
        var cylinder := CylinderMesh.new()
        cylinder.top_radius = 0.02
        cylinder.bottom_radius = 0.02
        cylinder.height = interval[1] - interval[0]
        segment.mesh = cylinder
        segment.position = Vector3((interval[0] + interval[1]) / 2, y, 0)
        segment.rotate_object_local(Vector3.RIGHT, PI / 2)
        add_child(segment)
```

Each interval is a short cylinder. The pattern is a horizontal line of shrinking bars.

Stack generations vertically.

```gdscript
func render_generations(max_depth: int) -> void:
    for depth in max_depth + 1:
        var intervals: Array = cantor_intervals(0.0, 10.0, depth)
        render_cantor(intervals, -depth * 0.3, 0.0)
```

Each row shows one generation. The pattern tree develops downward.

Compute the set's measure.

```gdscript
func measure(depth: int, total_length: float) -> float:
    var remaining: float = pow(2.0 / 3.0, depth) * total_length
    return remaining
```

Each generation multiplies the total length by 2/3. Converges to zero as depth grows.

Compute fractal dimension.

```gdscript
func cantor_dimension() -> float:
    return log(2) / log(3)
```

Two pieces at 1/3 scale. D = log(2)/log(3) ≈ 0.631. Between 0 and 1 — fractal rather than linear.

Cantor dust (2D variant).

```gdscript
func cantor_dust(depth: int, size: float) -> Array:
    if depth == 0:
        return [Vector2.ZERO]
    var points: Array = []
    var sub_points: Array = cantor_dust(depth - 1, size / 3)
    for dx in [0, 2]:
        for dy in [0, 2]:
            for sub in sub_points:
                points.append(sub + Vector2(dx * size / 3, dy * size / 3))
    return points
```

Four corners at each scale. 4^n points at depth n.

Visualise dimension.

```gdscript
func animate_dimension_comparison() -> void:
    var cantor_d: float = cantor_dimension()
    var sierpinski_d: float = log(3) / log(2)
    var menger_d: float = log(20) / log(3)
    display_dimension_graph([cantor_d, sierpinski_d, menger_d], ["Cantor", "Sierpinski", "Menger"])
```

Three fractals, three dimensions. The comparison shows fractal dimension lives between integers.

You can now generate Cantor intervals, render them as cylinders, compute the fractal dimension, and extend to Cantor dust in 2D. Fractal_KochSierpinski extends into additive and multiplicative 2D fractals.

Convert iteration to pixel coordinates.

```gdscript
func complex_to_pixel(c: Vector2, bounds: Rect2, resolution: Vector2i) -> Vector2i:
    return Vector2i(
        int((c.x - bounds.position.x) / bounds.size.x * resolution.x),
        int((c.y - bounds.position.y) / bounds.size.y * resolution.y)
    )
```

Maps math-space to image-space. Inverse of pixel-to-complex used in rendering.
