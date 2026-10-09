# CA Expanding Space

The neighbourhood grows. More reach, different structure.

Variable-radius neighbourhood.

```gdscript
@export var radius: int = 1

func count_in_radius(x: int, y: int, r: int) -> int:
    var count: int = 0
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dx == 0 and dy == 0: continue
            var nx: int = (x + dx + size.x) % size.x
            var ny: int = (y + dy + size.y) % size.y
            count += grid[ny][nx]
    return count
```

Moore neighbourhood at arbitrary radius. Radius 1 gives 8 neighbours; radius 2 gives 24.

Weighted neighbourhood.

```gdscript
func weighted_neighbourhood(x: int, y: int, weights: Array) -> float:
    var total: float = 0.0
    var r: int = (weights.size() - 1) / 2
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dx == 0 and dy == 0: continue
            var w: float = weights[dy + r][dx + r]
            var nx: int = (x + dx + size.x) % size.x
            var ny: int = (y + dy + size.y) % size.y
            total += w * grid[ny][nx]
    return total
```

Each neighbour contributes its weight times its state. Equivalent to a convolution.

Smoothing kernel.

```gdscript
const SMOOTH_KERNEL := [
    [1, 2, 1],
    [2, 4, 2],
    [1, 2, 1],
]
```

Gaussian-like. Heavier weight on closer neighbours.

Grow a 3D tree from a cellular rule.

```gdscript
class_name CAGrowthTree extends Node3D

var occupied: Dictionary = {}  # Vector3i -> int

func grow_step(radius: int, threshold: int) -> void:
    var new_cells: Dictionary = {}
    for cell in occupied:
        for dx in range(-radius, radius + 1):
            for dy in range(-radius, radius + 1):
                for dz in range(-radius, radius + 1):
                    if dx == 0 and dy == 0 and dz == 0: continue
                    var candidate: Vector3i = cell + Vector3i(dx, dy, dz)
                    if candidate in occupied: continue
                    var count: int = count_occupied_neighbours(candidate, radius)
                    if count >= threshold:
                        new_cells[candidate] = 1
    for c in new_cells:
        occupied[c] = 1
```

Cells activate when enough nearby cells are already active. Produces fractal branching structures.

Spawn the tree.

```gdscript
func spawn_visual_cells() -> void:
    for cell in occupied:
        var mesh := MeshInstance3D.new()
        mesh.mesh = BoxMesh.new()
        mesh.scale = Vector3(0.2, 0.2, 0.2)
        mesh.position = Vector3(cell) * 0.3
        add_child(mesh)
```

Each occupied cell is a small cube. The tree emerges as an accumulation of cubes.

Crossway interference.

```gdscript
func crossway_step(zone_a: Array, zone_b: Array) -> void:
    for y in size.y:
        for x in size.x:
            var in_a: bool = Vector2i(x, y) in zone_a
            var in_b: bool = Vector2i(x, y) in zone_b
            var rule: Callable = rule_a if in_a else (rule_b if in_b else rule_default)
            grid[y][x] = rule.call(x, y)
```

Different regions use different rules. Overlap produces interference that neither region produces alone.

You can now implement variable-radius neighbourhoods, weighted convolutions, 3D CA tree growth, and cross-zone rule interference. CA_SoftRules extends into stochastic rules.
