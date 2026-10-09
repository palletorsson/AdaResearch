# Fractal Recursion

A function that calls itself. Depth bounded, structure unbounded.

Recursive factorial.

```gdscript
func factorial(n: int) -> int:
    if n <= 1: return 1
    return n * factorial(n - 1)
```

Base case at 1; recursive call with smaller argument. The call stack captures the recursion depth.

Recursive tree structure.

```gdscript
func recursive_tree(start: Vector3, direction: Vector3, length: float, depth: int) -> void:
    if depth <= 0: return
    var end := start + direction * length
    draw_segment(start, end)
    var axis: Vector3 = direction.cross(Vector3.UP).normalized()
    var left: Vector3 = direction.rotated(axis, deg_to_rad(20))
    var right: Vector3 = direction.rotated(axis, deg_to_rad(-20))
    recursive_tree(end, left, length * 0.7, depth - 1)
    recursive_tree(end, right, length * 0.7, depth - 1)
```

Binary branching. Each call spawns two shorter children.

Memoisation.

```gdscript
var memo: Dictionary = {}

func fib(n: int) -> int:
    if n in memo: return memo[n]
    if n <= 1: return n
    var result: int = fib(n - 1) + fib(n - 2)
    memo[n] = result
    return result
```

Cache results. Fibonacci without memoisation is exponential; with it, linear.

Tail-recursive form.

```gdscript
func sum_tail(n: int, acc: int = 0) -> int:
    if n == 0: return acc
    return sum_tail(n - 1, acc + n)
```

Accumulator carries state forward. Compilers can optimise this into a loop.

Iterative equivalent.

```gdscript
func sum_iterative(n: int) -> int:
    var total: int = 0
    while n > 0:
        total += n
        n -= 1
    return total
```

Same computation; no call stack. Faster and safer for large n.

Detect stack depth.

```gdscript
func measure_depth(n: int, depth: int = 0) -> int:
    if n <= 0: return depth
    return measure_depth(n - 1, depth + 1)
```

Returns the number of recursive calls made. Useful for testing stack-overflow limits.

Self-similar structure.

```gdscript
func render_fractal_at(position: Vector3, size: float, depth: int) -> void:
    if depth <= 0:
        spawn_cube_at(position, size * 0.3)
        return
    var offset: float = size * 0.5
    for dx in [-1, 1]:
        for dy in [-1, 1]:
            for dz in [-1, 1]:
                render_fractal_at(position + Vector3(dx, dy, dz) * offset, size * 0.5, depth - 1)
```

Each cube spawns 8 smaller cubes. Cantor dust in 3D.

You can now write recursive functions, memoise their results, recognise tail recursion, convert to iteration, measure call depth, and build self-similar 3D structures. Fractal_RecursiveTrees extends into tree morphologies.

Convert iteration to pixel coordinates.

```gdscript
func complex_to_pixel(c: Vector2, bounds: Rect2, resolution: Vector2i) -> Vector2i:
    return Vector2i(
        int((c.x - bounds.position.x) / bounds.size.x * resolution.x),
        int((c.y - bounds.position.y) / bounds.size.y * resolution.y)
    )
```

Maps math-space to image-space. Inverse of pixel-to-complex used in rendering.
