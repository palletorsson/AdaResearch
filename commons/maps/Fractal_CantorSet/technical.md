# Fractals_3 - Technical Tutorial

## Recursive Circles

### Basic Circle Recursion
Place smaller circles around a parent circle's circumference:

```gdscript
func recursive_circles(center: Vector2, radius: float, depth: int):
    if depth <= 0:
        return

    # Draw current circle
    draw_circle(center, radius)

    # Parameters for child circles
    var child_radius = radius * 0.4  # Each child is 40% of parent
    var num_children = 6              # 6 children around circumference
    var placement_radius = radius - child_radius  # Place inside parent

    for i in range(num_children):
        var angle = TAU * i / num_children
        var child_center = center + Vector2(cos(angle), sin(angle)) * placement_radius

        # Recursive call
        recursive_circles(child_center, child_radius, depth - 1)
```

### Apollonian Gasket
A classical circular fractal where circles pack to fill space:

### 3D Recursive Circles
For the VR visualization, circles become 3D toruses or rings:

```gdscript
func recursive_circles_3d(center: Vector3, radius: float, normal: Vector3, depth: int):
    if depth <= 0:
        return

    # Create torus mesh at this level
    var torus = create_torus(center, radius, normal, tube_radius)
    add_child(torus)

    # Calculate child positions on the circle
    var child_radius = radius * 0.35
    var num_children = 5
    var placement_radius = radius * 0.7

    # Get perpendicular vectors to normal
    var tangent = normal.cross(Vector3.UP).normalized()
    if tangent.length() < 0.1:
        tangent = normal.cross(Vector3.RIGHT).normalized()
    var bitangent = normal.cross(tangent)

    for i in range(num_children):
        var angle = TAU * i / num_children
        var offset = tangent * cos(angle) + bitangent * sin(angle)
        var child_center = center + offset * placement_radius

        # Child circles can have tilted normals for visual interest
        var child_normal = (normal + offset * 0.3).normalized()

        recursive_circles_3d(child_center, child_radius, child_normal, depth - 1)
```

### Inward Spiraling
Circles that spiral toward center:

### Fractal Dimension of Circle Packings
The Apollonian gasket has dimension ≈ 1.3057:

```gdscript
func estimate_apollonian_dimension(max_depth: int) -> float:
    # Count circles at each scale
    var counts = []
    var scales = []

    for depth in range(1, max_depth + 1):
        var count = count_circles_at_depth(depth)
        var avg_radius = average_radius_at_depth(depth)

        counts.append(count)
        scales.append(1.0 / avg_radius)

    # Linear regression of log(count) vs log(scale)
    # Slope approximates fractal dimension
    return linear_regression_slope(
        scales.map(func(s): return log(s)),
        counts.map(func(c): return log(c))
    )
```

## Implementation Notes

### Depth vs. Iterations
The map uses 40 iterations, which produces fine detail:

### Performance: Instance Rendering
Many small circles can use GPU instancing:

```gdscript
var circle_transforms: Array[Transform3D] = []

func collect_circles(center: Vector3, radius: float, depth: int):
    if depth <= 0:
        return

    # Store transform instead of creating mesh
    var transform = Transform3D().scaled(Vector3.ONE * radius).translated(center)
    circle_transforms.append(transform)

    # ... recurse

func render_all_circles():
    var multimesh = MultiMesh.new()
    multimesh.instance_count = circle_transforms.size()

    for i in range(circle_transforms.size()):
        multimesh.set_instance_transform(i, circle_transforms[i])

    # Single draw call for all circles
```

## Key Takeaway
Circular recursion demonstrates that self-similarity operates in any geometry. The key insight: **different recursion topologies produce different aesthetics** (branching trees vs. spiraling mandalas) while sharing the same mathematical foundation (self-application of rules).

## Implementation Notes and Complexity

The Cantor set is constructed by repeated middle-third removal. Starting from the unit interval, each step removes the open middle third of every remaining interval. After N steps, the remaining structure consists of 2 to the N intervals, each of length 3 to the minus N. The total length tends to zero; the total number of endpoints tends to infinity; the fractal dimension is log(2) over log(3), approximately 0.631.

The recursive construction has straightforward time and space complexity. Each step multiplies the interval count by 2, so generating N steps requires O(2 to the N) storage for the interval list. Naive implementations allocate a new list at each step; a more efficient implementation stores only the endpoints and reconstructs intervals on demand, giving O(N) memory for the recursion depth plus O(2 to the N) time to enumerate the intervals.

Rendering the Cantor set is limited by what can actually be displayed. At eight iterations the structure has 256 intervals, each too narrow to be distinct on a normal display. Beyond ten iterations the visualisation collapses visually, even though the mathematical construction continues. The map caps visible depth at a threshold that produces legible geometry, and a side panel tracks the mathematical depth separately.

The Cantor dust — the 2D analogue — is constructed similarly but with 8 of 9 squares retained instead of 2 of 3 intervals. The fractal dimension is log(8) over log(3), approximately 1.893. The Cantor carpet uses 8 of 9 squares as well but colours them differently; Sierpinski's carpet removes the centre of each square instead, producing dimension log(8) over log(3), the same value.

Within the sequence, Cantor is the one-dimensional entry point to the fractals sequence. Sierpinski, Koch, and Menger all generalise Cantor's subtractive logic to higher dimensions, and the dimensional ladder from Cantor to Menger runs through this map's construction.
