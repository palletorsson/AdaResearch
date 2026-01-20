# Fractals_6 - Technical Tutorial

## Recursive Tree Algorithm

### Basic Binary Branching
The simplest recursive tree divides each branch into two:

```gdscript
func recursive_tree(start: Vector3, direction: Vector3, length: float, depth: int):
    if depth <= 0:
        return

    # Draw current branch
    var end = start + direction * length
    draw_branch(start, end)

    # Calculate child branch parameters
    var child_length = length * 0.7  # 70% of parent length
    var branch_angle = deg_to_rad(30)  # 30 degree spread

    # Left branch: rotate direction left
    var left_dir = direction.rotated(Vector3.FORWARD, branch_angle)
    recursive_tree(end, left_dir, child_length, depth - 1)

    # Right branch: rotate direction right
    var right_dir = direction.rotated(Vector3.FORWARD, -branch_angle)
    recursive_tree(end, right_dir, child_length, depth - 1)
```

### Parameterized Tree
Expose key parameters for experimentation:

```gdscript
@export var branch_angle: float = 25.0  # degrees
@export var length_ratio: float = 0.7   # child/parent length
@export var thickness_ratio: float = 0.6  # child/parent thickness
@export var max_depth: int = 8

func recursive_tree_parameterized(
    start: Vector3,
    direction: Vector3,
    length: float,
    thickness: float,
    depth: int
):
    if depth <= 0 or length < 0.01:
        return

    var end = start + direction * length
    draw_branch_cylinder(start, end, thickness)

    var child_length = length * length_ratio
    var child_thickness = thickness * thickness_ratio
    var angle_rad = deg_to_rad(branch_angle)

    # 3D branching: rotate around multiple axes
    var left_dir = direction.rotated(Vector3.FORWARD, angle_rad)
    var right_dir = direction.rotated(Vector3.FORWARD, -angle_rad)

    recursive_tree_parameterized(end, left_dir, child_length, child_thickness, depth - 1)
    recursive_tree_parameterized(end, right_dir, child_length, child_thickness, depth - 1)
```

### 3D Tree with Rotation
For more natural 3D trees, rotate branch plane at each level:

```gdscript
func tree_3d(
    start: Vector3,
    direction: Vector3,
    up: Vector3,
    length: float,
    depth: int
):
    if depth <= 0:
        return

    var end = start + direction * length
    draw_branch(start, end)

    # Calculate local coordinate system
    var right = direction.cross(up).normalized()
    up = right.cross(direction).normalized()

    var child_length = length * 0.7
    var branch_angle = deg_to_rad(30)
    var twist_angle = deg_to_rad(137.5)  # Golden angle for phyllotaxis

    # Create two branches with twist
    for i in range(2):
        var rotation = twist_angle * i
        var branch_right = right.rotated(direction, rotation)
        var child_dir = direction.rotated(branch_right, branch_angle)

        tree_3d(end, child_dir, up, child_length, depth - 1)
```

### Leonardo's Rule (Pipe Model)
Natural trees follow area-preserving branching:

```gdscript
func tree_leonardo(
    start: Vector3,
    direction: Vector3,
    radius: float,  # Branch cross-section radius
    depth: int
):
    if depth <= 0 or radius < 0.01:
        return

    var length = radius * 10.0  # Length proportional to radius
    var end = start + direction * length
    draw_branch_cylinder(start, end, radius)

    # Leonardo's rule: sum of child areas = parent area
    # πr² = πr₁² + πr₂²
    # For symmetric binary: r₁ = r₂ = r / √2
    var child_radius = radius / sqrt(2.0)
    var branch_angle = deg_to_rad(25)

    var left_dir = direction.rotated(Vector3.FORWARD, branch_angle)
    var right_dir = direction.rotated(Vector3.FORWARD, -branch_angle)

    tree_leonardo(end, left_dir, child_radius, depth - 1)
    tree_leonardo(end, right_dir, child_radius, depth - 1)
```

### Asymmetric Branching
More natural trees have unequal branches:

```gdscript
func tree_asymmetric(
    start: Vector3,
    direction: Vector3,
    length: float,
    depth: int
):
    if depth <= 0:
        return

    var end = start + direction * length
    draw_branch(start, end)

    # Main branch: continues mostly in same direction
    var main_angle = deg_to_rad(15)
    var main_length = length * 0.8
    var main_dir = direction.rotated(Vector3.FORWARD, main_angle)

    # Side branch: smaller, more angled
    var side_angle = deg_to_rad(50)
    var side_length = length * 0.5
    var side_dir = direction.rotated(Vector3.FORWARD, -side_angle)

    tree_asymmetric(end, main_dir, main_length, depth - 1)
    tree_asymmetric(end, side_dir, side_length, depth - 1)
```

### Tree Statistics

```gdscript
func tree_statistics(depth: int, branch_ratio: float) -> Dictionary:
    # Number of branches (binary tree)
    var total_branches = pow(2, depth + 1) - 1

    # Number of tips (leaves)
    var num_leaves = pow(2, depth)

    # Total length (geometric series)
    var total_length = (1.0 - pow(branch_ratio, depth + 1)) / (1.0 - branch_ratio)

    # Approximate fractal dimension
    # D = log(N) / log(S) where N = branches per node, S = length scale
    var D = log(2) / log(1.0 / branch_ratio)

    return {
        "branches": total_branches,
        "leaves": num_leaves,
        "total_length": total_length,
        "dimension": D
    }
```

## Implementation Notes

### Mesh Generation
For smooth tree visualization:

```gdscript
func generate_branch_mesh(start: Vector3, end: Vector3, radius: float) -> ArrayMesh:
    var mesh = ArrayMesh.new()
    var arrays = []
    arrays.resize(Mesh.ARRAY_MAX)

    var direction = (end - start).normalized()
    var length = (end - start).length()
    var segments = 8  # Around circumference
    var length_segments = 4  # Along branch

    # Generate vertices, normals, UVs for tapered cylinder
    # ... mesh generation code

    return mesh
```

### LOD System
Trees get complex quickly:

```gdscript
func calculate_tree_lod(camera_distance: float) -> int:
    if camera_distance < 5.0:
        return 8  # Full detail
    elif camera_distance < 15.0:
        return 6
    elif camera_distance < 30.0:
        return 4
    else:
        return 2  # Minimal detail
```

## Key Takeaway
Recursive trees demonstrate **form without memory**. No database stores the tree's shape—only the rule (branch, reduce, repeat) and parameters (angle, ratio, depth). This is emergence: complex organic form arising from simple algorithmic specification.
