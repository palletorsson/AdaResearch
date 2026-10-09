# Fractals_4 - Technical Tutorial

## The Cantor Set Algorithm

### Basic Construction
The Cantor set is defined by recursive deletion:

```gdscript
func cantor_set(segments: Array, depth: int) -> Array:
    if depth <= 0:
        return segments

    var new_segments = []

    for seg in segments:
        var start = seg[0]
        var end = seg[1]
        var third = (end - start) / 3.0

        # Keep left third and right third, discard middle
        new_segments.append([start, start + third])
        new_segments.append([end - third, end])

    return cantor_set(new_segments, depth - 1)

# Usage
var initial = [[0.0, 1.0]]  # Unit interval
var cantor = cantor_set(initial, 5)  # 5 iterations
# Result: 32 segments, each of length 1/243
```

### Visualizing in 3D
For VR, represent each segment as a 3D box:

```gdscript
func render_cantor_set(segments: Array, height: float, y_position: float):
    for seg in segments:
        var start = seg[0]
        var end = seg[1]
        var length = end - start

        var box = CSGBox3D.new()
        box.size = Vector3(length, height, height)
        box.position = Vector3((start + end) / 2.0, y_position, 0)

        add_child(box)

# Show multiple iterations stacked vertically
func render_cantor_stack(max_depth: int):
    for depth in range(max_depth):
        var segments = cantor_set([[0.0, 1.0]], depth)
        var height = 0.1 / pow(1.5, depth)  # Thinner at higher depths
        var y = depth * 0.3  # Stack vertically

        render_cantor_set(segments, height, y)
```

### Cantor Set Properties
Mathematical properties to visualize:

```gdscript
func cantor_statistics(depth: int) -> Dictionary:
    var segments = cantor_set([[0.0, 1.0]], depth)

    # Total length remaining
    var total_length = 0.0
    for seg in segments:
        total_length += seg[1] - seg[0]
    # Formula: (2/3)^depth

    # Number of segments
    var num_segments = segments.size()
    # Formula: 2^depth

    # Length of each segment
    var segment_length = 1.0 / pow(3, depth)
    # Formula: (1/3)^depth

    return {
        "total_length": total_length,
        "num_segments": num_segments,
        "segment_length": segment_length,
        "fractal_dimension": log(2) / log(3)  # ≈ 0.631
    }
```

### The Menger Sponge
The 3D analog of the Cantor set:

```gdscript
func menger_sponge(cube: AABB, depth: int) -> Array:
    if depth <= 0:
        return [cube]

    var result = []
    var size = cube.size / 3.0

    for x in range(3):
        for y in range(3):
            for z in range(3):
                # Skip if 2 or more coordinates are 1 (center)
                var center_count = int(x == 1) + int(y == 1) + int(z == 1)
                if center_count >= 2:
                    continue  # Remove center and face centers

                var new_pos = cube.position + Vector3(x, y, z) * size
                var new_cube = AABB(new_pos, size)

                # Recursive call
                result.append_array(menger_sponge(new_cube, depth - 1))

    return result

# Menger sponge properties:
# - 20 sub-cubes per iteration (27 - 7 removed)
# - Dimension = log(20) / log(3) ≈ 2.727
# - Infinite surface area, zero volume
```

### Cantor Dust (2D)
The 2D analog—Cantor set applied in both dimensions:

```gdscript
func cantor_dust(rect: Rect2, depth: int) -> Array:
    if depth <= 0:
        return [rect]

    var result = []
    var size = rect.size / 3.0

    # Keep corners only (4 quadrants minus center cross)
    for x in [0, 2]:
        for y in [0, 2]:
            var new_pos = rect.position + Vector2(x, y) * size
            var new_rect = Rect2(new_pos, size)
            result.append_array(cantor_dust(new_rect, depth - 1))

    return result

# Cantor dust properties:
# - 4 sub-squares per iteration
# - Dimension = log(4) / log(3) ≈ 1.262
# - More than Cantor set (0.631) but less than a plane (2)
```

### Ternary Representation
Points in the Cantor set have a special property:

```gdscript
func is_in_cantor_set(x: float, precision: int = 20) -> bool:
    # A number is in the Cantor set if and only if
    # its base-3 representation contains no 1s

    var value = x
    for i in range(precision):
        value *= 3.0
        var digit = int(value) % 3
        if digit == 1:
            return false
        value -= int(value)

    return true

# This gives an infinite set of points!
# Examples in Cantor set: 0, 1/3, 2/3, 1, 1/9, 2/9, 7/9, 8/9, ...
```

## Implementation Notes

### Iteration Limits
At 10 iterations:
- 1024 segments (2^10)
- Each segment length: 1/59049 (3^-10)
- Total length: ≈ 0.017 (about 1.7% of original)

```gdscript
@export var max_iterations: int = 10
@export var min_segment_length: float = 0.001

func render_adaptive(depth: int, segment_length: float):
    if segment_length < min_segment_length:
        return  # Stop when segments become invisible
    # ... render logic
```

### LOD for Menger Sponge
The sponge grows rapidly:
- Depth 1: 20 cubes
- Depth 2: 400 cubes
- Depth 3: 8,000 cubes
- Depth 4: 160,000 cubes

```gdscript
func menger_lod(center: Vector3, camera_pos: Vector3, max_depth: int) -> int:
    var distance = center.distance_to(camera_pos)
    return clamp(max_depth - int(distance / 5.0), 1, max_depth)
```

## Key Takeaway
The Cantor set proves that **removing can create complexity**. After infinite deletions, uncountably many points remain. The fractal dimension D = log(2)/log(3) ≈ 0.631 quantifies this: more than isolated points, less than a continuous line. Structure emerges from systematic absence.
