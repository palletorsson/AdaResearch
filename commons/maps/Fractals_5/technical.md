# Fractals_5 - Technical Tutorial

## The Koch Curve Algorithm

### Edge Replacement Rule
Each segment is replaced by four segments forming an outward spike:

```gdscript
func koch_replace(start: Vector2, end: Vector2) -> Array:
    # Divide segment into thirds
    var third = (end - start) / 3.0

    var p1 = start
    var p2 = start + third
    var p4 = start + third * 2.0
    var p5 = end

    # Calculate peak of equilateral triangle
    var mid = (p2 + p4) / 2.0
    var perpendicular = Vector2(-(p4 - p2).y, (p4 - p2).x).normalized()
    var height = third.length() * sqrt(3.0) / 2.0
    var p3 = mid + perpendicular * height

    return [p1, p2, p3, p4, p5]
```

### Recursive Generation
Apply the rule to each segment:

```gdscript
func koch_curve(points: Array, depth: int) -> Array:
    if depth <= 0:
        return points

    var new_points = []

    for i in range(points.size() - 1):
        var replaced = koch_replace(points[i], points[i + 1])
        # Add all except last (to avoid duplicates)
        for j in range(replaced.size() - 1):
            new_points.append(replaced[j])

    # Add final point
    new_points.append(points[-1])

    return koch_curve(new_points, depth - 1)

# Usage
var initial = [Vector2(0, 0), Vector2(1, 0)]
var koch = koch_curve(initial, 5)  # 1025 points
```

### Koch Snowflake
Three Koch curves forming a closed shape:

```gdscript
func koch_snowflake(center: Vector2, radius: float, depth: int) -> Array:
    # Start with equilateral triangle
    var angles = [PI/2, PI/2 + TAU/3, PI/2 + 2*TAU/3]
    var triangle = []
    for angle in angles:
        triangle.append(center + Vector2(cos(angle), sin(angle)) * radius)
    triangle.append(triangle[0])  # Close the loop

    # Apply Koch to each edge
    var snowflake = []
    for i in range(3):
        var edge = koch_curve([triangle[i], triangle[i+1]], depth)
        # Add all except last to avoid duplicates
        for j in range(edge.size() - 1):
            snowflake.append(edge[j])

    snowflake.append(snowflake[0])  # Close
    return snowflake
```

### L-System Representation
The Koch curve as an L-System:

```gdscript
var koch_lsystem = {
    "axiom": "F",
    "rules": {"F": "F+F--F+F"},
    "angle": 60  # degrees
}

func generate_koch_lsystem(iterations: int) -> String:
    var current = koch_lsystem.axiom

    for i in range(iterations):
        var next = ""
        for char in current:
            if char in koch_lsystem.rules:
                next += koch_lsystem.rules[char]
            else:
                next += char
        current = next

    return current

# "F" → "F+F--F+F" → "F+F--F+F+F+F--F+F--F+F--F+F+F+F--F+F" → ...
```

### 3D Koch Curve
For VR visualization:

```gdscript
func koch_curve_3d(points_2d: Array, height: float) -> PackedVector3Array:
    var points_3d = PackedVector3Array()

    for p in points_2d:
        points_3d.append(Vector3(p.x, height, p.y))

    return points_3d

func render_koch_tube(points: PackedVector3Array, radius: float):
    var mesh = ImmediateMesh.new()
    mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

    for i in range(points.size() - 1):
        var p1 = points[i]
        var p2 = points[i + 1]
        var dir = (p2 - p1).normalized()

        # Calculate perpendicular vectors for tube
        var up = Vector3.UP
        var right = dir.cross(up).normalized()
        up = right.cross(dir).normalized()

        # Add tube segment vertices
        for angle_step in range(8):
            var angle = TAU * angle_step / 8.0
            var offset = (right * cos(angle) + up * sin(angle)) * radius
            mesh.surface_add_vertex(p1 + offset)
            mesh.surface_add_vertex(p2 + offset)

    mesh.surface_end()
    return mesh
```

### Properties and Dimension

```gdscript
func koch_statistics(depth: int) -> Dictionary:
    # After n iterations:
    var num_segments = pow(4, depth)
    var segment_length = pow(1.0/3.0, depth)
    var total_length = pow(4.0/3.0, depth)  # Grows without bound

    # Fractal dimension
    var D = log(4) / log(3)  # ≈ 1.2619

    # Snowflake area (converges!)
    var initial_area = sqrt(3) / 4.0  # Equilateral triangle
    var final_area = initial_area * 8.0 / 5.0  # Limit

    return {
        "segments": num_segments,
        "segment_length": segment_length,
        "total_length": total_length,
        "dimension": D,
        "snowflake_area": final_area
    }
```

### The Coastline Paradox
Measuring coastlines with different ruler lengths:

```gdscript
func measure_coastline(points: Array, ruler_length: float) -> float:
    var total = 0.0
    var current_pos = points[0]
    var point_index = 0

    while point_index < points.size() - 1:
        # Find next point approximately ruler_length away
        var distance_needed = ruler_length
        while distance_needed > 0 and point_index < points.size() - 1:
            var segment_length = current_pos.distance_to(points[point_index + 1])
            if segment_length <= distance_needed:
                distance_needed -= segment_length
                current_pos = points[point_index + 1]
                point_index += 1
            else:
                # Move partway along segment
                var dir = (points[point_index + 1] - current_pos).normalized()
                current_pos += dir * distance_needed
                distance_needed = 0

        total += ruler_length

    return total

# Shorter rulers → longer measured coastlines
# At the limit: infinite length
```

## Implementation Notes

### Depth Limits
Koch curve grows quickly:
- Depth 5: 1,024 segments
- Depth 8: 65,536 segments
- Depth 10: 1,048,576 segments

```gdscript
@export var max_depth: int = 7
@export var min_segment_length: float = 0.005

func adaptive_koch(depth: int, scale: float) -> int:
    var segment_length = scale * pow(1.0/3.0, depth)
    if segment_length < min_segment_length:
        return depth - 1
    return depth
```

## Key Takeaway
The Koch curve demonstrates **infinite complexity through addition**. Unlike the Cantor set (deletion), Koch adds structure at every iteration. The result: a curve of dimension 1.262 that has infinite length but encloses (as a snowflake) finite area. This is the coastline paradox: boundaries that grow longer the closer you look.
