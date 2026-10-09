# GT Layout

Force-directed layout. Nodes repel; edges pull.

Track vertex positions and velocities.

```gdscript
var positions: Dictionary = {}  # vertex_id -> Vector3
var velocities: Dictionary = {}
```

Two dictionaries keyed on vertex id. Initialised with random positions and zero velocities.

Compute repulsion.

```gdscript
@export var repulsion_k: float = 1.0

func repulsion_force_on(v) -> Vector3:
    var total := Vector3.ZERO
    for other in vertices:
        if other == v: continue
        var direction: Vector3 = positions[v] - positions[other]
        var distance: float = direction.length() + 0.01
        total += direction.normalized() * repulsion_k / (distance * distance)
    return total
```

Inverse-square repulsion. Every pair of vertices pushes apart.

Compute attraction.

```gdscript
@export var spring_k: float = 0.5

func spring_force_on(v) -> Vector3:
    var total := Vector3.ZERO
    for edge in edges:
        if edge[0] == v or edge[1] == v:
            var other = edge[0] if edge[1] == v else edge[1]
            var direction: Vector3 = positions[other] - positions[v]
            total += direction * spring_k
    return total
```

Linear attraction along edges. Connected vertices pull together.

Step the simulation.

```gdscript
@export var damping: float = 0.9

func _physics_process(delta: float) -> void:
    for v in vertices:
        var force: Vector3 = repulsion_force_on(v) + spring_force_on(v)
        velocities[v] += force * delta
        velocities[v] *= damping
        positions[v] += velocities[v] * delta
    update_visual_positions()
```

Each step: compute forces, integrate, damp. The graph settles to equilibrium.

Update visuals.

```gdscript
func update_visual_positions() -> void:
    for child in get_children():
        if child.has_meta("vertex_id"):
            var v = child.get_meta("vertex_id")
            child.global_position = positions[v]
```

Visual meshes follow the computed positions. Update every frame.

Compute layout stress.

```gdscript
func layout_stress() -> float:
    var adj: Dictionary = adjacency_list()
    var total: float = 0.0
    for u in vertices:
        var distances: Dictionary = bfs_distances(u, adj)
        for v in vertices:
            if u == v: continue
            var gd: int = distances[v]
            var sd: float = positions[u].distance_to(positions[v])
            total += (gd - sd) * (gd - sd)
    return total
```

Stress measures mismatch between graph distances and spatial distances. Lower is better.

Seed random positions.

```gdscript
func seed_positions(bounds: Vector3) -> void:
    for v in vertices:
        positions[v] = Vector3(randf(), randf(), randf()) * bounds
        velocities[v] = Vector3.ZERO
```

Random initial positions in a bounded volume. The simulation will settle to a layout.

You can now build a force-directed layout with repulsion and spring attraction, integrate the dynamics, update visuals, and measure layout stress. GT_Pathfinding extends into maze navigation.

Snap positions to a grid.

```gdscript
func snap_positions(cell_size: float = 0.5) -> void:
    for v in vertices:
        positions[v] = (positions[v] / cell_size).round() * cell_size
```

Discretise for cleaner visuals. Useful when the layout looks right but jitters slightly.
