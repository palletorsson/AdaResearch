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

```gdscript
func apollonian_gasket(c1: Circle, c2: Circle, c3: Circle, depth: int):
    if depth <= 0:
        return

    # Find the fourth circle tangent to all three
    var c4 = descartes_circle(c1, c2, c3)

    if c4.radius < MIN_RADIUS:
        return

    draw_circle(c4.center, c4.radius)

    # Recurse on the three new triangular gaps
    apollonian_gasket(c1, c2, c4, depth - 1)
    apollonian_gasket(c2, c3, c4, depth - 1)
    apollonian_gasket(c1, c3, c4, depth - 1)

func descartes_circle(c1: Circle, c2: Circle, c3: Circle) -> Circle:
    # Descartes' Circle Theorem
    # If k = 1/r (curvature), then:
    # k4 = k1 + k2 + k3 + 2*sqrt(k1*k2 + k2*k3 + k1*k3)

    var k1 = 1.0 / c1.radius
    var k2 = 1.0 / c2.radius
    var k3 = 1.0 / c3.radius

    var k4 = k1 + k2 + k3 + 2.0 * sqrt(k1*k2 + k2*k3 + k1*k3)

    # Center calculation requires complex arithmetic
    # Simplified: average weighted by curvature
    var center = (c1.center * k1 + c2.center * k2 + c3.center * k3) / (k1 + k2 + k3)

    return Circle.new(center, 1.0 / k4)
```

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

```gdscript
func spiral_circles(center: Vector2, radius: float, angle: float, depth: int):
    if depth <= 0 or radius < MIN_RADIUS:
        return

    # Draw current circle
    draw_circle(center, radius)

    # Next circle: smaller, rotated, moved toward center
    var shrink_factor = 0.85
    var rotation = 0.3  # radians per iteration
    var inward_factor = 0.1

    var new_radius = radius * shrink_factor
    var new_angle = angle + rotation
    var inward_offset = Vector2(cos(angle), sin(angle)) * radius * inward_factor
    var new_center = center - inward_offset  # Move toward center

    spiral_circles(new_center, new_radius, new_angle, depth - 1)
```

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

```gdscript
@export var iterations: int = 40
@export var min_radius: float = 0.01  # Stop when circles get too small

func recursive_circles_bounded(center: Vector2, radius: float, remaining: int):
    if remaining <= 0 or radius < min_radius:
        return

    draw_circle(center, radius)

    # ... generate children with remaining - 1
```

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
