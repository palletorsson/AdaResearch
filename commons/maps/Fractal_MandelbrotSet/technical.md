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

## Key Takeaway
Fibonacci (additive) and Sierpinski (subtractive) both produce self-referential structures. The golden ratio connects them: Fibonacci ratios converge to φ, while Sierpinski's self-similar scaling embodies related mathematical properties. **Addition and deletion are complementary paths to fractal complexity.**

## Implementation Notes and Complexity

The Mandelbrot set is defined as the set of complex numbers c for which the iteration z_new equals z_squared plus c, starting from z equals zero, does not diverge to infinity. Membership is tested by iterating and checking whether the magnitude of z exceeds a bailout threshold (typically 2) within a maximum iteration count. The output is a per-pixel classification: either in the set (never escaped within the iteration budget) or escaped at iteration N (which gives a colour for visualisation).

The time complexity is O(W times H times I) where W and H are the image dimensions and I is the maximum iteration count. Each pixel iterates independently, which makes the Mandelbrot an embarrassingly parallel problem — perfect for GPU evaluation. A shader implementation computes one pixel per thread, and modern GPUs process millions of pixels per frame. CPU implementations can reach interactive rates using SIMD and cache-friendly memory layouts, but GPU is the conventional choice.

Rendering precision matters at deep zoom levels. At zoom depths beyond about 10 to the 14, double-precision floating-point begins to produce visible artifacts — adjacent pixels sample positions that differ by less than a ULP, and the iteration's convergence test becomes unreliable. Deep zoom renderers use arbitrary-precision arithmetic or perturbation theory, both of which cost substantially more per pixel.

Colouring is where aesthetic decisions enter. The escape iteration count is an integer, and mapping it to a colour gradient is a designer's choice. Smooth colouring applies a continuous correction based on the magnitude of z at escape, producing gradient transitions that avoid the banding that pure integer counts produce. The map exposes a gradient selector so the learner can compare colouring strategies.

Within the sequence, Mandelbrot is the complex-dynamics chapter. Previous maps used iterated substitution on real numbers (Cantor) or on geometric figures (Koch, Sierpinski). Mandelbrot uses iterated substitution on complex numbers, and the resulting set lives in a plane where the iteration's behaviour produces the characteristic self-similar boundary.
