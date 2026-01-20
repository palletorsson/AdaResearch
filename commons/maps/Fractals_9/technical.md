# Fractals_9 - Technical Tutorial

## The Fibonacci Sequence

### Basic Generation

```gdscript
func fibonacci_sequence(n: int) -> Array:
    var seq = [1, 1]
    for i in range(2, n):
        seq.append(seq[i-1] + seq[i-2])
    return seq

# Result: [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, ...]
```

### Golden Ratio Connection

```gdscript
func fibonacci_ratio(n: int) -> float:
    var seq = fibonacci_sequence(n)
    return float(seq[-1]) / float(seq[-2])

# As n → ∞, ratio → φ = (1 + √5) / 2 ≈ 1.618033988749895

const PHI = (1.0 + sqrt(5.0)) / 2.0

func fibonacci_closed_form(n: int) -> int:
    # Binet's formula
    return int(round((pow(PHI, n) - pow(-PHI, -n)) / sqrt(5.0)))
```

### Fibonacci Spiral Visualization

```gdscript
func fibonacci_spiral(num_squares: int, scale: float):
    var fib = fibonacci_sequence(num_squares + 2)
    var position = Vector2.ZERO
    var directions = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
    var dir_index = 0

    for i in range(num_squares):
        var size = fib[i] * scale

        # Draw square
        draw_rect(Rect2(position, Vector2(size, size)))

        # Draw quarter arc
        draw_arc(position + directions[(dir_index + 2) % 4] * size, size)

        # Move to next position
        position += directions[dir_index] * size
        dir_index = (dir_index + 1) % 4
```

## The Sierpinski Triangle

### Construction by Deletion

```gdscript
func sierpinski_delete(triangles: Array, depth: int) -> Array:
    if depth <= 0:
        return triangles

    var result = []
    for tri in triangles:
        var mid01 = (tri[0] + tri[1]) / 2.0
        var mid12 = (tri[1] + tri[2]) / 2.0
        var mid20 = (tri[2] + tri[0]) / 2.0

        # Keep three corner triangles, delete center
        result.append([tri[0], mid01, mid20])
        result.append([mid01, tri[1], mid12])
        result.append([mid20, mid12, tri[2]])
        # Central triangle [mid01, mid12, mid20] is NOT added

    return sierpinski_delete(result, depth - 1)
```

### Construction by Chaos Game

```gdscript
func sierpinski_chaos_game(vertices: Array, num_points: int) -> Array:
    var points = []
    var current = Vector2(randf(), randf())  # Random start

    for i in range(num_points):
        # Pick random vertex
        var vertex = vertices[randi() % 3]
        # Move halfway toward it
        current = (current + vertex) / 2.0
        points.append(current)

    return points

# This produces the Sierpinski triangle!
# The "chaos game" converges to the fractal attractor
```

### Pascal's Triangle Connection

```gdscript
func sierpinski_from_pascal(rows: int):
    # Sierpinski pattern appears in Pascal's triangle
    # by coloring odd numbers
    for row in range(rows):
        for col in range(row + 1):
            var value = binomial(row, col)
            if value % 2 == 1:
                draw_point(col, row)  # Odd numbers form Sierpinski

func binomial(n: int, k: int) -> int:
    if k == 0 or k == n:
        return 1
    return binomial(n-1, k-1) + binomial(n-1, k)
```

## Connection: Self-Reference

### Fibonacci Self-Reference

```gdscript
# F(n) is defined in terms of F(n-1) and F(n-2)
# This is additive self-reference

func fibonacci_recursive(n: int) -> int:
    if n <= 1:
        return 1
    return fibonacci_recursive(n-1) + fibonacci_recursive(n-2)
```

### Sierpinski Self-Reference

```gdscript
# Each Sierpinski triangle contains 3 smaller Sierpinski triangles
# This is geometric self-reference

func is_in_sierpinski(p: Vector2, depth: int) -> bool:
    # Transform p to [0,1] × [0,1] with equilateral triangle
    for i in range(depth):
        # Which sub-triangle?
        if in_center_triangle(p):
            return false  # In deleted region
        p = transform_to_subtriangle(p)
    return true
```

### Golden Ratio in Both

```gdscript
# Fibonacci: ratio of consecutive terms → φ
var fib_ratio = fibonacci_sequence(20)[-1] / fibonacci_sequence(20)[-2]
# ≈ 1.618

# Sierpinski: the golden ratio appears in the self-similar scaling
# When scaled by φ, certain properties align with Fibonacci tiling

# Both relate to the same underlying mathematics of self-reference
```

## Sierpinski Properties

```gdscript
func sierpinski_statistics(depth: int) -> Dictionary:
    # Number of triangles
    var num_triangles = pow(3, depth)

    # Total area (fraction of original)
    var area_fraction = pow(0.75, depth)  # (3/4)^n → 0

    # Fractal dimension
    var D = log(3) / log(2)  # ≈ 1.585

    return {
        "triangles": num_triangles,
        "area_fraction": area_fraction,
        "dimension": D
    }
```

## 3D Visualizations

```gdscript
func fibonacci_spiral_3d(num_levels: int, scale: float):
    var fib = fibonacci_sequence(num_levels + 2)

    for level in range(num_levels):
        var radius = fib[level] * scale
        var height = level * scale
        var angle = level * TAU * PHI  # Golden angle

        var pos = Vector3(
            cos(angle) * radius,
            height,
            sin(angle) * radius
        )

        create_sphere_at(pos, radius * 0.1)

func sierpinski_3d(tetrahedra: Array, depth: int) -> Array:
    # Sierpinski tetrahedron: 4 sub-tetrahedra, dimension ≈ 2.0
    if depth <= 0:
        return tetrahedra

    var result = []
    for tet in tetrahedra:
        var mids = []
        for i in range(4):
            for j in range(i + 1, 4):
                mids.append((tet[i] + tet[j]) / 2.0)

        # Create 4 corner tetrahedra
        for corner in range(4):
            var new_tet = [tet[corner]]
            # Add midpoints of edges from this corner
            for m in get_midpoints_from_corner(corner, mids):
                new_tet.append(m)
            result.append(new_tet)

    return sierpinski_3d(result, depth - 1)
```

## Implementation Notes

### Performance
Sierpinski triangle at depth 10 has 59,049 triangles. Use LOD:

```gdscript
func sierpinski_lod(camera_distance: float) -> int:
    if camera_distance < 5.0:
        return 10
    elif camera_distance < 20.0:
        return 7
    else:
        return 4
```

## Key Takeaway
Fibonacci (additive) and Sierpinski (subtractive) both produce self-referential structures. The golden ratio connects them: Fibonacci ratios converge to φ, while Sierpinski's self-similar scaling embodies related mathematical properties. **Addition and deletion are complementary paths to fractal complexity.**
