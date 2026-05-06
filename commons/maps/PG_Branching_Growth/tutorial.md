# PG Branching Growth

Two branching strategies. Rules versus noise.

Rule-based recursive branching.

```gdscript
func recursive_branch(start: Vector3, direction: Vector3, length: float, depth: int) -> void:
    if depth <= 0: return
    var end := start + direction * length
    spawn_cylinder_between(start, end)
    var axis: Vector3 = direction.cross(Vector3.UP).normalized()
    var left: Vector3 = direction.rotated(axis, deg_to_rad(25))
    var right: Vector3 = direction.rotated(axis, deg_to_rad(-25))
    recursive_branch(end, left, length * 0.7, depth - 1)
    recursive_branch(end, right, length * 0.7, depth - 1)
```

Classic binary branching. Each call spawns two children at fixed angles.

Noise-driven growth.

```gdscript
var noise := FastNoiseLite.new()

func noise_grow_step(position: Vector3, step: float = 0.1) -> Vector3:
    var h: float = 0.01
    var dx: float = noise.get_noise_3dv(position + Vector3(h, 0, 0)) - noise.get_noise_3dv(position - Vector3(h, 0, 0))
    var dy: float = noise.get_noise_3dv(position + Vector3(0, h, 0)) - noise.get_noise_3dv(position - Vector3(0, h, 0))
    var dz: float = noise.get_noise_3dv(position + Vector3(0, 0, h)) - noise.get_noise_3dv(position - Vector3(0, 0, h))
    return position + Vector3(dx, dy, dz).normalized() * step
```

Gradient of a noise field. The path follows the local gradient direction.

Grow a noise path.

```gdscript
func grow_noise_path(start: Vector3, steps: int) -> Array:
    var path: Array = [start]
    var current := start
    for _i in steps:
        current = noise_grow_step(current)
        path.append(current)
    return path
```

Each step advances along the gradient. The path is organic-looking.

Render a path as cylinders.

```gdscript
func render_path(path: Array) -> void:
    for i in range(path.size() - 1):
        spawn_cylinder_between(path[i], path[i + 1])
```

One cylinder per segment. The path becomes a single connected curve.

Branch from a path.

```gdscript
func branch_from_path(path: Array, branches_per_node: int = 2, branch_length: int = 20) -> void:
    for i in range(0, path.size(), 4):  # every 4 nodes
        for _b in branches_per_node:
            var branch_direction := Vector3(randfn(0, 1), randfn(0, 1), randfn(0, 1)).normalized()
            var branch := grow_noise_path(path[i], branch_length)
            render_path(branch)
```

Every four nodes spawn additional branches. Creates a tree-like structure from noise-driven growth.

Compare side by side.

```gdscript
func compare_methods() -> void:
    recursive_branch(Vector3(-3, 0, 0), Vector3.UP, 1.0, 6)
    var noise_path := grow_noise_path(Vector3(3, 0, 0), 100)
    render_path(noise_path)
    branch_from_path(noise_path)
```

Rule-based on the left, noise-driven on the right. The visual difference is striking.

You can now recursive-branch, noise-gradient-step, grow organic paths, branch from a path, and compare the two strategies side by side. PG_Caves_Mazes extends into subtractive generation.

Reset the tree.

```gdscript
func reset() -> void:
    nodes.clear()
    parents.clear()
    attractors.clear()
    nodes.append(Vector3.ZERO)
    parents.append(-1)
```

Start fresh. Useful when scatter conditions change.
