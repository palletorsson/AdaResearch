# Fractals_8 - Technical Tutorial

## Comparing Cantor Constructions

### The Unifying Pattern
Both 1D Cantor and 3D Menger follow the same logic:

```gdscript
# General Cantor-type construction
func cantor_generic(elements: Array, dimension: int, depth: int) -> Array:
    if depth <= 0:
        return elements

    var result = []
    for element in elements:
        var subdivisions = subdivide_element(element, 3, dimension)

        for sub in subdivisions:
            if not is_center(sub, dimension):
                result.append(sub)

    return cantor_generic(result, dimension, depth - 1)

func is_center(subdivision, dimension: int) -> bool:
    # Element is "center" if 2 or more coordinates are at center position
    var center_coords = 0
    for coord in subdivision.position_indices:
        if coord == 1:  # Middle position in 0, 1, 2
            center_coords += 1
    return center_coords >= 2 if dimension > 1 else center_coords >= 1
```

### Dimension Formula
All Cantor-type constructions follow the same formula:

```gdscript
func cantor_dimension(d: int) -> float:
    # d = underlying space dimension
    # N = number of pieces kept = 3^d - (pieces removed)

    # Pieces removed in d dimensions:
    # Those with 2+ center coordinates
    var removed = 0
    for i in range(int(pow(3, d))):
        var coords = index_to_coords(i, d, 3)
        var centers = coords.count(1)
        if centers >= 2 or (d == 1 and centers >= 1):
            removed += 1

    var kept = int(pow(3, d)) - removed
    return log(kept) / log(3)

# Results:
# d=1: kept=2, D=0.631
# d=2: kept=8, D=1.893
# d=3: kept=20, D=2.727
```

### Visualization Side by Side

```gdscript
extends Node3D

@export var cantor_depth: int = 6
@export var menger_depth: int = 3
@export var spacing: float = 5.0

func _ready():
    # Create 1D Cantor set
    var cantor_1d = create_cantor_1d(cantor_depth)
    cantor_1d.position = Vector3(-spacing, 0, 0)
    add_child(cantor_1d)

    # Create 3D Menger sponge
    var menger_3d = create_menger_3d(menger_depth)
    menger_3d.position = Vector3(spacing, 0, 0)
    add_child(menger_3d)

    # Add labels
    create_label("D ≈ 0.631", Vector3(-spacing, 2, 0))
    create_label("D ≈ 2.727", Vector3(spacing, 2, 0))
```

### Interactive Comparison

```gdscript
# Allow player to adjust iteration depth and see both update
@export var shared_depth: int = 3:
    set(value):
        shared_depth = value
        update_visualizations()

func update_visualizations():
    # 1D Cantor: can show more iterations
    cantor_node.depth = shared_depth * 2  # More visible at higher depth

    # 3D Menger: fewer iterations needed (exponential growth)
    menger_node.depth = shared_depth

    # Show statistics
    update_statistics_display()

func update_statistics_display():
    var cantor_stats = {
        "segments": pow(2, shared_depth * 2),
        "dimension": log(2) / log(3)
    }

    var menger_stats = {
        "cubes": pow(20, shared_depth),
        "dimension": log(20) / log(3)
    }

    # Display for comparison
    stats_label.text = """
    Cantor Set:
      Segments: %d
      Dimension: %.3f

    Menger Sponge:
      Cubes: %d
      Dimension: %.3f
    """ % [
        cantor_stats.segments,
        cantor_stats.dimension,
        menger_stats.cubes,
        menger_stats.dimension
    ]
```

### The Measure-Dimension Relationship

```gdscript
# Both constructions have:
# - Zero n-dimensional measure (length/area/volume)
# - Fractional Hausdorff dimension

func compare_measures(depth: int) -> Dictionary:
    return {
        "cantor_1d": {
            "length": pow(2.0/3.0, depth),  # → 0
            "dimension": 0.631
        },
        "carpet_2d": {
            "area": pow(8.0/9.0, depth),  # → 0
            "dimension": 1.893
        },
        "menger_3d": {
            "volume": pow(20.0/27.0, depth),  # → 0
            "dimension": 2.727
        }
    }

# All measures → 0 as depth → ∞
# But all dimensions > 0
# This is the fractal paradox
```

## Implementation Notes

### Synchronized Animation
For pedagogical effect, animate both constructions together:

```gdscript
var animation_depth: float = 0.0

func _process(delta):
    animation_depth += delta * 0.5  # Slow reveal

    var int_depth = int(animation_depth) % (max_depth + 1)

    cantor_node.set_visible_depth(int_depth * 2)
    menger_node.set_visible_depth(int_depth)
```

### Visual Cues for Correspondence
Highlight the "removed" portions in both:

```gdscript
func highlight_removed():
    # In 1D Cantor: show middle thirds in red before removal
    # In 3D Menger: show center + face-centers in red

    for element in get_to_be_removed():
        element.material.albedo_color = Color.RED
        await get_tree().create_timer(0.5).timeout
        element.queue_free()
```

## Key Takeaway
The Cantor set and Menger sponge are **the same construction in different dimensions**. The principle (remove centers) is dimension-independent; only the specifics (what counts as "center") change with dimension. Understanding one helps understand all.
