# Koch & Sierpinski

Additive Koch. Subtractive Sierpinski.

Koch curve recursion.

```gdscript
func koch_segment(a: Vector2, b: Vector2, depth: int) -> Array:
    if depth == 0:
        return [[a, b]]
    var third: Vector2 = (b - a) / 3.0
    var p1: Vector2 = a + third
    var p2: Vector2 = a + third * 2
    var peak: Vector2 = p1 + third.rotated(-PI / 3)
    return (
        koch_segment(a, p1, depth - 1) +
        koch_segment(p1, peak, depth - 1) +
        koch_segment(peak, p2, depth - 1) +
        koch_segment(p2, b, depth - 1)
    )
```

Each segment splits into four. The middle third is replaced by a peak forming an equilateral triangle.

Build the Koch snowflake.

```gdscript
func koch_snowflake(centre: Vector2, radius: float, depth: int) -> Array:
    var angles := [PI / 2, PI / 2 + TAU / 3, PI / 2 + 2 * TAU / 3]
    var points: Array = []
    for a in angles:
        points.append(centre + Vector2(cos(a), sin(a)) * radius)
    return (
        koch_segment(points[0], points[1], depth) +
        koch_segment(points[1], points[2], depth) +
        koch_segment(points[2], points[0], depth)
    )
```

Three Koch segments forming a triangle. The result is the Koch snowflake.

Sierpinski triangle.

```gdscript
func sierpinski_triangle(a: Vector2, b: Vector2, c: Vector2, depth: int) -> Array:
    if depth == 0:
        return [[a, b, c]]
    var ab: Vector2 = (a + b) / 2
    var bc: Vector2 = (b + c) / 2
    var ca: Vector2 = (c + a) / 2
    return (
        sierpinski_triangle(a, ab, ca, depth - 1) +
        sierpinski_triangle(ab, b, bc, depth - 1) +
        sierpinski_triangle(ca, bc, c, depth - 1)
    )
```

Three sub-triangles at corners; central triangle removed. Classic substructure.

Render Sierpinski.

```gdscript
func render_sierpinski(triangles: Array) -> void:
    for tri in triangles:
        var polygon := MeshInstance3D.new()
        polygon.mesh = build_triangle_mesh(tri[0], tri[1], tri[2])
        add_child(polygon)
```

Each returned triangle becomes a filled polygon. Visible holes form the pattern.

Sierpinski carpet.

```gdscript
func sierpinski_carpet(corner: Vector2, size: float, depth: int) -> Array:
    if depth == 0:
        return [Rect2(corner, Vector2(size, size))]
    var third: float = size / 3.0
    var squares: Array = []
    for dx in 3:
        for dy in 3:
            if dx == 1 and dy == 1: continue  # remove centre
            squares += sierpinski_carpet(corner + Vector2(dx * third, dy * third), third, depth - 1)
    return squares
```

Nine sub-squares minus the centre. Eight survive.

Compute scaling ratios.

```gdscript
func dimension(pieces: int, ratio: float) -> float:
    return log(pieces) / log(1.0 / ratio)
```

Number of self-similar pieces divided by log of scale factor. Koch: D = log(4)/log(3) ≈ 1.26. Sierpinski: D = log(3)/log(2) ≈ 1.58.

You can now render Koch curves, Koch snowflakes, Sierpinski triangles, Sierpinski carpets, and compute their fractal dimensions. Fractal_MengerSponge extends into the 3D version.
