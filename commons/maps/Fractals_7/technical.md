# Fractals_7 - Technical Tutorial

## Dimensional Extension of Cantor

### 1D: Cantor Set
Remove middle third of each segment:

```gdscript
func cantor_1d(segments: Array, depth: int) -> Array:
    if depth <= 0:
        return segments

    var result = []
    for seg in segments:
        var third = (seg.end - seg.start) / 3.0
        result.append(Segment.new(seg.start, seg.start + third))
        result.append(Segment.new(seg.end - third, seg.end))

    return cantor_1d(result, depth - 1)

# Properties:
# - 2^n segments after n iterations
# - Dimension = log(2)/log(3) ≈ 0.631
```

### 2D: Cantor Dust (Sierpinski Carpet)
Remove middle ninth of each square:

```gdscript
func cantor_2d(squares: Array, depth: int) -> Array:
    if depth <= 0:
        return squares

    var result = []
    for sq in squares:
        var third = sq.size / 3.0
        for x in [0, 1, 2]:
            for y in [0, 1, 2]:
                # Skip center square (1,1)
                if x == 1 and y == 1:
                    continue
                var new_pos = sq.position + Vector2(x, y) * third
                result.append(Square.new(new_pos, third))

    return cantor_2d(result, depth - 1)

# Properties:
# - 8^n squares after n iterations
# - Dimension = log(8)/log(3) ≈ 1.893
```

### 3D: Menger Sponge
Remove center and six face-centers:

```gdscript
func menger_3d(cubes: Array, depth: int) -> Array:
    if depth <= 0:
        return cubes

    var result = []
    for cube in cubes:
        var third = cube.size / 3.0
        for x in [0, 1, 2]:
            for y in [0, 1, 2]:
                for z in [0, 1, 2]:
                    # Count how many coordinates are at center (1)
                    var center_count = int(x == 1) + int(y == 1) + int(z == 1)

                    # Skip if 2 or more are at center
                    # (center cube + 6 face-center cubes)
                    if center_count >= 2:
                        continue

                    var new_pos = cube.position + Vector3(x, y, z) * third
                    result.append(Cube.new(new_pos, third))

    return menger_3d(result, depth - 1)

# Properties:
# - 20^n cubes after n iterations
# - Dimension = log(20)/log(3) ≈ 2.727
```

### Interactive Cube Subdivision

```gdscript
extends RigidBody3D

@export var max_depth: int = 3
var current_depth: int = 0

func _on_touched():
    if current_depth >= max_depth:
        # Reset to single cube
        reset_to_original()
        return

    subdivide_menger()
    current_depth += 1

func subdivide_menger():
    var cubes = get_all_child_cubes()
    if cubes.is_empty():
        cubes = [self]

    for cube in cubes:
        var new_cubes = menger_subdivide_single(cube)
        for new_cube in new_cubes:
            add_child(new_cube)
        if cube != self:
            cube.queue_free()

func menger_subdivide_single(cube: Node3D) -> Array:
    var result = []
    var size = cube.scale / 3.0
    var offset = cube.scale.x / 3.0

    for x in [0, 1, 2]:
        for y in [0, 1, 2]:
            for z in [0, 1, 2]:
                var center_count = int(x == 1) + int(y == 1) + int(z == 1)
                if center_count >= 2:
                    continue

                var new_cube = create_cube()
                new_cube.scale = size
                new_cube.position = cube.position + Vector3(x - 1, y - 1, z - 1) * offset
                result.append(new_cube)

    return result
```

### Dimensional Table

| Dimension | Name | N kept | Scale | D = log(N)/log(S) |
|-----------|------|--------|-------|-------------------|
| 1D | Cantor Set | 2 | 3 | 0.631 |
| 2D | Sierpinski Carpet | 8 | 3 | 1.893 |
| 3D | Menger Sponge | 20 | 3 | 2.727 |
| nD | Generalized | 3^n - ... | 3 | varies |

### Passages in the Menger Sponge

```gdscript
func calculate_passage_size(initial_size: float, iterations: int) -> float:
    # Smallest passages after n iterations
    return initial_size / pow(3, iterations)

# For walkable passages (≥1 meter):
# Initial size 27m, 3 iterations → passages = 1m
# Initial size 81m, 4 iterations → passages = 1m
# Initial size 243m, 5 iterations → passages = 1m
```

### Surface Area and Volume

```gdscript
func menger_properties(initial_size: float, depth: int) -> Dictionary:
    var side = initial_size

    # Volume: (20/27)^n of original
    var volume_ratio = pow(20.0 / 27.0, depth)
    var volume = pow(side, 3) * volume_ratio
    # Limit as n → ∞: 0

    # Surface area calculation is more complex
    # It grows without bound as depth increases
    # Limit as n → ∞: ∞

    return {
        "volume": volume,
        "volume_ratio": volume_ratio,
        "note": "Surface area → ∞ while volume → 0"
    }
```

## Implementation Notes

### Efficient Menger Rendering
Use instancing for repeated cube patterns:

```gdscript
func render_menger_instanced(depth: int):
    var positions = calculate_menger_positions(depth)

    var multimesh = MultiMesh.new()
    multimesh.mesh = cube_mesh
    multimesh.instance_count = positions.size()

    for i in range(positions.size()):
        var transform = Transform3D()
        transform = transform.translated(positions[i].position)
        transform = transform.scaled(Vector3.ONE * positions[i].scale)
        multimesh.set_instance_transform(i, transform)
```

## Key Takeaway
The Cantor principle (remove middles) scales across dimensions. From 1D dust to 2D carpet to 3D sponge, the same logic produces structures with zero measure (length, area, volume) but fractional dimension. The Menger sponge is **walkable infinity**: finite bounding box, infinite surface, zero volume.
