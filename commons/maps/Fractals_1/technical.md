# Fractals_1 - Technical Tutorial

## Recursion in Code

### The Basic Pattern
A fractal is defined by a rule that applies to its own output:

```gdscript
func fractal_subdivide(cube: Node3D, depth: int):
    if depth <= 0:
        return  # Base case: stop recursion

    var scale = cube.scale / 2.0
    var offset = scale.x / 2.0

    # Create 8 smaller cubes (2x2x2 grid)
    for x in [-1, 1]:
        for y in [-1, 1]:
            for z in [-1, 1]:
                var new_cube = cube.duplicate()
                new_cube.scale = scale
                new_cube.position = cube.position + Vector3(x, y, z) * offset
                cube.get_parent().add_child(new_cube)

                # Recursive call: apply same rule to new cube
                fractal_subdivide(new_cube, depth - 1)

    cube.queue_free()  # Remove original
```

This is the essence of fractal generation: **self-application**.

### Fractal Dimension Formula
The fractal dimension D measures how complexity scales:

```gdscript
func calculate_fractal_dimension(num_copies: int, scale_factor: float) -> float:
    # D = log(N) / log(S)
    # N = number of self-similar pieces
    # S = how much larger the whole is than each piece
    return log(num_copies) / log(scale_factor)

# Examples:
var line_D = calculate_fractal_dimension(2, 2)      # = 1.0 (standard line)
var square_D = calculate_fractal_dimension(4, 2)    # = 2.0 (standard square)
var sierpinski_D = calculate_fractal_dimension(3, 2) # ≈ 1.585 (between line and plane)
```

### The Hilbert Curve
A space-filling curve maps a 1D line to fill 2D/3D space:

```gdscript
# Hilbert curve generation using L-System
var hilbert_rules = {
    "A": "-BF+AFA+FB-",
    "B": "+AF-BFB-FA+"
}

func hilbert_3d_point(t: float, order: int) -> Vector3:
    # Maps parameter t ∈ [0,1] to position in unit cube
    # Higher order = finer resolution
    var n = pow(2, order)
    var index = int(t * n * n * n)
    return hilbert_index_to_xyz(index, order)

func hilbert_index_to_xyz(index: int, order: int) -> Vector3:
    var pos = Vector3.ZERO
    var s = 1
    var rx: int
    var ry: int
    var rz: int

    var temp = index
    for i in range(order):
        rx = 1 & (temp / 4)
        ry = 1 & ((temp ^ rx) / 2)
        rz = 1 & (temp ^ rx ^ ry)
        # Rotate quadrant
        pos = rotate_hilbert(s, pos, rx, ry, rz)
        pos += Vector3(s * rx, s * ry, s * rz)
        temp /= 8
        s *= 2

    return pos / float(s)  # Normalize to unit cube
```

### Subdivision Cube Implementation
The interactive subdivision cube responds to touch:

```gdscript
extends RigidBody3D

@export var max_depth: int = 4
var current_depth: int = 0

func _on_touched():
    if current_depth >= max_depth:
        return

    subdivide()
    current_depth += 1

func subdivide():
    var new_scale = scale / 3.0
    var offset = scale.x / 3.0

    # Create 27 positions, keep 20 (Menger pattern)
    for x in [-1, 0, 1]:
        for y in [-1, 0, 1]:
            for z in [-1, 0, 1]:
                # Skip center and face centers
                var axis_count = int(x == 0) + int(y == 0) + int(z == 0)
                if axis_count >= 2:
                    continue

                var child = duplicate()
                child.scale = new_scale
                child.position = position + Vector3(x, y, z) * offset
                get_parent().add_child(child)

    queue_free()
```

## Implementation Notes

### Performance Considerations
Fractal recursion grows exponentially:
- Depth 1: 8 cubes
- Depth 2: 64 cubes
- Depth 3: 512 cubes
- Depth 4: 4,096 cubes

Use LOD (Level of Detail) for distant fractals:

```gdscript
func _process(_delta):
    var distance = global_position.distance_to(camera.global_position)
    var target_depth = clamp(4 - int(distance / 5.0), 0, max_depth)

    if target_depth != current_depth:
        regenerate(target_depth)
```

### Why Infinite from Finite?
The recursion formula contains unbounded potential:
- Fixed rule (finite)
- Applied repeatedly (potentially infinite)
- Each application increases detail
- No theoretical limit to iteration

The computer imposes practical limits (memory, time, floating-point precision), but the mathematical object has no such bounds.

## Selective Recursion: Fractals as Search

Pure fractals like the Menger sponge subdivide uniformly. But **functional forms** emerge from selective subdivision:

```gdscript
# Recursive chair: subdivide then prune
func make_chair_from_cube():
    # Step 1: Subdivide 3x3x3 (exploration)
    var parts = subdivide_3x3x3(cube)

    # Step 2: Keep only useful regions (exploitation)
    for part in parts:
        var keep = false
        if part.layer == "bottom" and part.is_corner():
            keep = true  # Legs
        elif part.layer == "middle":
            keep = true  # Seat
        elif part.layer == "top" and part.is_back_row():
            keep = true  # Backrest

        if not keep:
            part.queue_free()  # Prune non-functional space

    # Step 3: Reshape remaining parts (refinement)
    flatten_seat()
    elongate_legs()
    extend_back()
```

This is **search with constraints**—using fractal subdivision to explore the space of possible forms while pruning regions that don't fit functional criteria.

## QFEP Connection

In the Queer Free Energy Principle (**QFE = F − λE(S) + φΔE(S,t)**):

| QFEP Term | Fractal Interpretation |
|-----------|----------------------|
| **F** | The subdivision rule itself (deterministic, ordered) |
| **E(S)** | Entropy of resulting structures (complexity, variety) |
| **λ** | Exploration/exploitation balance (uniform vs selective) |
| **φΔE(S,t)** | Rate of complexity change per iteration |

**Menger sponge**: λ = 1, uniform entropy generation, pure exploration
**Recursive chair**: λ tuned, selective pruning, balanced search
**Single cube**: λ = 0, no subdivision, pure exploitation of known form

## Key Takeaway
Fractals demonstrate that **complexity need not be designed**—a simple rule, self-applied, generates infinite structure. But more than that: **selective recursion is a search strategy** for finding useful forms in vast possibility spaces. The λ parameter determines how much we explore (subdivide everything) versus exploit (prune to known-good regions).
