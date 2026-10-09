# Golden Spiral

Fibonacci rectangles. A spiral through their quarter-arcs.

Compute Fibonacci numbers.

```gdscript
func fib(n: int) -> int:
    if n <= 1: return n
    var a: int = 0
    var b: int = 1
    for _i in range(n - 1):
        var c: int = a + b
        a = b
        b = c
    return b
```

Iterative. Linear time.

Golden ratio.

```gdscript
const PHI: float = 1.61803398875  # (1 + sqrt(5)) / 2
```

Limit of consecutive Fibonacci ratios. Ubiquitous in art and nature.

Build Fibonacci rectangles.

```gdscript
func fibonacci_rectangles(count: int) -> Array:
    var rectangles: Array = []
    var position := Vector2.ZERO
    var direction := Vector2.RIGHT
    for i in count:
        var side: float = float(fib(i + 1))
        var rect := Rect2(position, Vector2(side, side))
        rectangles.append(rect)
        position = rect.end if direction.x > 0 else Vector2(rect.position.x, rect.end.y)
        direction = direction.rotated(PI / 2)
    return rectangles
```

Each rectangle is a square with side equal to the next Fibonacci number. They tile around a shared corner.

Draw a quarter-arc in each rectangle.

```gdscript
func quarter_arc(centre: Vector2, radius: float, start_angle: float) -> Array:
    var points: Array = []
    for i in 32:
        var t: float = float(i) / 31
        var angle: float = start_angle + t * PI / 2
        points.append(centre + Vector2(cos(angle), sin(angle)) * radius)
    return points
```

32 points along a quarter circle. Smooth enough for a visible curve.

Render the spiral.

```gdscript
func render_golden_spiral(rectangles: Array) -> void:
    var rotation: float = PI
    for rect in rectangles:
        var centre: Vector2 = rect.position
        var radius: float = rect.size.x
        var arc_points: Array = quarter_arc(centre, radius, rotation)
        for i in range(1, arc_points.size()):
            spawn_line_segment(arc_points[i - 1], arc_points[i])
        rotation += PI / 2
```

Sequential quarter-arcs form the spiral. Each arc starts where the previous ended.

Spawn in 3D.

```gdscript
func spawn_line_segment(a: Vector2, b: Vector2) -> void:
    var line := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.03
    cylinder.bottom_radius = 0.03
    var a3 := Vector3(a.x, 0, a.y)
    var b3 := Vector3(b.x, 0, b.y)
    cylinder.height = a3.distance_to(b3)
    line.mesh = cylinder
    line.position = (a3 + b3) / 2
    line.look_at(b3, Vector3.UP)
    line.rotate_object_local(Vector3.RIGHT, PI / 2)
    add_child(line)
```

2D to 3D: XY becomes XZ, Y stays Y. Places the spiral on the ground plane.

You can now compute Fibonacci numbers, tile rectangles, render quarter-arcs, and form the golden spiral. Fractal_MandelbrotSet extends into complex-dynamics fractals.

Convert iteration to pixel coordinates.

```gdscript
func complex_to_pixel(c: Vector2, bounds: Rect2, resolution: Vector2i) -> Vector2i:
    return Vector2i(
        int((c.x - bounds.position.x) / bounds.size.x * resolution.x),
        int((c.y - bounds.position.y) / bounds.size.y * resolution.y)
    )
```

Maps math-space to image-space. Inverse of pixel-to-complex used in rendering.
