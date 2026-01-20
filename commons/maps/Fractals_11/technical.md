# Fractals_11 - Technical Tutorial

## Inverted Tree Algorithm

### Basic Inversion
The simplest inversion negates the vertical component:

```gdscript
func recursive_tree_inverted(
    start: Vector3,
    direction: Vector3,
    length: float,
    depth: int
):
    if depth <= 0:
        return

    var end = start + direction * length
    draw_branch(start, end)

    var child_length = length * 0.7
    var branch_angle = deg_to_rad(30)

    # Note: direction.y is negative for downward growth
    var left_dir = direction.rotated(Vector3.FORWARD, branch_angle)
    var right_dir = direction.rotated(Vector3.FORWARD, -branch_angle)

    recursive_tree_inverted(end, left_dir, child_length, depth - 1)
    recursive_tree_inverted(end, right_dir, child_length, depth - 1)

# Call with downward initial direction
func create_inverted_tree():
    recursive_tree_inverted(
        Vector3(0, 5, 0),      # Start above ground
        Vector3.DOWN,          # Grow downward
        2.0,                   # Initial branch length
        8                      # Depth
    )
```

### Mirrored Tree Pair
Create both upward and downward trees from the same point:

```gdscript
func create_tree_pair(origin: Vector3, length: float, depth: int):
    # Upward tree (canopy)
    recursive_tree(origin, Vector3.UP, length, depth)

    # Downward tree (roots)
    recursive_tree_inverted(origin, Vector3.DOWN, length, depth)
```

### Tree Cloud Effect
Multiple inverted trees creating a cloud-like formation:

```gdscript
func inverted_tree_cloud(center: Vector3, count: int, radius: float):
    for i in range(count):
        # Random position in disk
        var angle = randf() * TAU
        var r = sqrt(randf()) * radius
        var pos = center + Vector3(cos(angle) * r, 0, sin(angle) * r)

        # Random parameters
        var length = randf_range(1.0, 2.5)
        var depth = randi_range(5, 8)
        var branch_angle = randf_range(20, 40)

        create_inverted_tree_at(pos, length, depth, branch_angle)
```

### Root System Modeling
Biological roots have different branching patterns than canopy:

```gdscript
func root_system(
    start: Vector3,
    direction: Vector3,
    length: float,
    depth: int,
    root_params: Dictionary
):
    if depth <= 0:
        return

    var end = start + direction * length
    draw_root(start, end, length * root_params.thickness_ratio)

    var child_length = length * root_params.length_decay

    # Roots tend toward water/nutrients (tropism)
    var tropism = root_params.tropism_direction * root_params.tropism_strength
    var adjusted_direction = (direction + tropism).normalized()

    # Asymmetric branching common in roots
    var main_angle = root_params.main_angle
    var side_angle = root_params.side_angle

    # Main continuation
    var main_dir = adjusted_direction.rotated(
        Vector3.RIGHT.cross(adjusted_direction),
        randf_range(-main_angle, main_angle)
    )
    root_system(end, main_dir, child_length, depth - 1, root_params)

    # Side branches (fewer than canopy)
    if randf() < root_params.branching_probability:
        var side_dir = adjusted_direction.rotated(
            Vector3.RIGHT.cross(adjusted_direction),
            side_angle
        )
        root_system(
            end,
            side_dir,
            child_length * 0.6,
            depth - 2,  # Faster depth reduction
            root_params
        )
```

### Symmetry Visualization
Show the mathematical equivalence of orientations:

```gdscript
func demonstrate_symmetry():
    # Same tree at different orientations
    var orientations = [
        Vector3.UP,
        Vector3.DOWN,
        Vector3.RIGHT,
        Vector3.LEFT,
        Vector3.FORWARD,
        Vector3.BACK
    ]

    for i in range(orientations.size()):
        var dir = orientations[i]
        var offset = dir * 10.0  # Spread out
        recursive_tree(offset, dir, 2.0, 6)

    # All trees are identical up to rotation
```

### Combined Canopy-Root System

```gdscript
class BiologicalTree:
    var trunk_base: Vector3
    var canopy_params: Dictionary
    var root_params: Dictionary

    func generate():
        # Shared trunk
        var trunk_top = trunk_base + Vector3.UP * trunk_height
        draw_trunk(trunk_base, trunk_top)

        # Canopy (upward)
        generate_canopy(trunk_top)

        # Roots (downward)
        generate_roots(trunk_base)

    func generate_canopy(start: Vector3):
        for i in range(canopy_params.main_branches):
            var angle = TAU * i / canopy_params.main_branches
            var dir = Vector3(cos(angle), 0.7, sin(angle)).normalized()
            recursive_tree(start, dir, canopy_params.length, canopy_params.depth)

    func generate_roots(start: Vector3):
        for i in range(root_params.main_roots):
            var angle = TAU * i / root_params.main_roots
            var dir = Vector3(cos(angle), -0.8, sin(angle)).normalized()
            root_system(start, dir, root_params.length, root_params.depth, root_params)
```

## Implementation Notes

### Performance with Two Trees
A mirrored tree pair doubles the geometry:

```gdscript
func calculate_tree_pair_geometry(depth: int) -> int:
    # Single tree: 2^(depth+1) - 1 branches
    var single_tree = int(pow(2, depth + 1)) - 1
    return single_tree * 2  # Both trees

# At depth 8: about 1000 branches total
```

### Visual Distinction
Differentiate roots from canopy:

```gdscript
func draw_root(start: Vector3, end: Vector3, thickness: float):
    var mesh = create_cylinder(start, end, thickness)

    # Roots are darker, more textured
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.3, 0.2, 0.1)  # Dark brown
    material.roughness = 0.9
    mesh.material_override = material

func draw_branch(start: Vector3, end: Vector3, thickness: float):
    var mesh = create_cylinder(start, end, thickness)

    # Canopy branches are lighter
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.4, 0.3, 0.2)  # Medium brown
    material.roughness = 0.7
    mesh.material_override = material
```

## Key Takeaway
Inverting a recursive tree reveals that **direction is arbitrary**. The fractal structure is orientation-independent—the same pattern emerges whether "growing" up or down. This reflects biological reality: root systems often mirror canopy complexity, following similar branching rules into different media.
