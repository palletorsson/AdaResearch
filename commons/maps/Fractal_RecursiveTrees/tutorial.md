# Fractal Recursive Trees

Branching trees. Parametric binary subdivision.

Define tree parameters.

```gdscript
@export var branch_angle: float = 25.0
@export var length_ratio: float = 0.75
@export var max_depth: int = 6
```

Angle, shrink ratio, depth. Three numbers define the tree's shape.

Build the tree.

```gdscript
func build_tree(start: Vector3, direction: Vector3, length: float, depth: int) -> void:
    if depth <= 0:
        spawn_leaf(start)
        return
    var end := start + direction * length
    spawn_branch(start, end, depth)
    var axis: Vector3 = direction.cross(Vector3.UP).normalized()
    var left: Vector3 = direction.rotated(axis, deg_to_rad(branch_angle))
    var right: Vector3 = direction.rotated(axis, deg_to_rad(-branch_angle))
    build_tree(end, left, length * length_ratio, depth - 1)
    build_tree(end, right, length * length_ratio, depth - 1)
```

Binary branching with fixed angle and shrink. Exponentially many leaves.

Trunk with taper.

```gdscript
func spawn_branch(start: Vector3, end: Vector3, depth: int) -> void:
    var branch := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.02 * depth
    cylinder.bottom_radius = 0.02 * (depth + 1)
    cylinder.height = start.distance_to(end)
    branch.mesh = cylinder
    branch.position = (start + end) / 2
    branch.look_at(end, Vector3.UP)
    branch.rotate_object_local(Vector3.RIGHT, PI / 2)
    add_child(branch)
```

Thicker at the trunk, thinner at the tips. The taper scales with depth.

Add randomness.

```gdscript
func build_random_tree(start: Vector3, direction: Vector3, length: float, depth: int) -> void:
    if depth <= 0:
        spawn_leaf(start)
        return
    var end := start + direction * length
    spawn_branch(start, end, depth)
    var axis := Vector3(randfn(0, 0.2), 0, randfn(0, 0.2)).cross(direction).normalized()
    var left := direction.rotated(axis, deg_to_rad(randf_range(15, 35)))
    var right := direction.rotated(axis, deg_to_rad(-randf_range(15, 35)))
    build_random_tree(end, left, length * randf_range(0.6, 0.85), depth - 1)
    build_random_tree(end, right, length * randf_range(0.6, 0.85), depth - 1)
```

Each call uses slightly different parameters. Trees no longer look identical.

Three-way branching.

```gdscript
func build_ternary(start: Vector3, direction: Vector3, length: float, depth: int) -> void:
    if depth <= 0:
        spawn_leaf(start)
        return
    var end := start + direction * length
    spawn_branch(start, end, depth)
    for angle_deg in [30, 0, -30]:
        var axis: Vector3 = direction.cross(Vector3.UP).normalized()
        var rotated := direction.rotated(axis, deg_to_rad(angle_deg))
        build_ternary(end, rotated, length * 0.75, depth - 1)
```

Three children per branch. Denser tree than binary; matches how plants often actually grow.

Approximate biology.

```gdscript
func phyllotactic_angle(i: int) -> float:
    return i * 137.5  # golden angle
```

The golden angle produces Fibonacci-like spiral patterns that appear in plant phyllotaxis. 137.5° between successive branches.

Build a tree and animate its growth.

```gdscript
var growth_progress: float = 0.0

func _process(delta: float) -> void:
    growth_progress = min(1.0, growth_progress + delta * 0.2)
    update_branch_lengths_to(growth_progress)
```

Branches grow from 0 to full length. The learner watches the tree form.

You can now build parametric trees with binary/ternary branching, random variation, phyllotactic spirals, and animated growth. Fractal_CantorSet extends into 1D deletion fractals.
