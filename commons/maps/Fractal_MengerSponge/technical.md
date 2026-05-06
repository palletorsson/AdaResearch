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

## Key Takeaway
Recursive trees demonstrate **form without memory**. No database stores the tree's shape—only the rule (branch, reduce, repeat) and parameters (angle, ratio, depth). This is emergence: complex organic form arising from simple algorithmic specification.

## Implementation Notes and Complexity

The Menger sponge is constructed by recursive subdivision and selective removal. Start with a unit cube. Divide it into 27 sub-cubes. Remove the centre sub-cube and the six face-centre sub-cubes, leaving 20 sub-cubes. Apply the same procedure to each remaining sub-cube. After N iterations, the structure has 20 to the N sub-cubes, and the fractal dimension is log(20) over log(3), approximately 2.727.

The recursion's time complexity is O(20 to the N), and memory scales identically unless the structure is computed on demand rather than stored. A naive implementation that materialises every sub-cube as a scene tree node runs out of memory at around N equals 5 on consumer hardware. The map caps rendering depth at N equals 4 and uses instanced rendering: a single small cube mesh is drawn many times with different transforms, avoiding per-sub-cube allocation.

Face culling becomes important at high iteration depths. Many of the sub-cubes are partially or fully occluded by their neighbours, and rendering them wastes GPU time. Godot's occlusion culling helps, but the sponge's characteristic self-similarity means that many sub-cubes are geometrically distinct at sub-pixel scale and cannot be collapsed. The rendering cost becomes the dominant constraint at high depths, not the recursion.

The Menger sponge has the universal curve property: every compact one-dimensional curve is homeomorphic to a subset of the Menger sponge. This is a surprising theoretical result with direct pedagogical consequences: the sponge is, in a formal sense, a library of all possible one-dimensional curves. The side panel in the map notes this without attempting to demonstrate it, since a demonstration would require searching a high-dimensional embedding space.

Within the sequence, Menger is the three-dimensional climax of the deletion arc. Cantor, Sierpinski, and Menger climb the dimensional ladder by the same recursive mechanism, and Menger is the top rung.
