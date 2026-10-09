# PG Space Colonization

Trees reach for attractors. Branches extend where sunlight is.

Scatter attractors.

```gdscript
func scatter_attractors(count: int, bounds: AABB) -> Array:
    var attractors: Array = []
    for _i in count:
        var p := Vector3(
            randf_range(bounds.position.x, bounds.end.x),
            randf_range(bounds.position.y, bounds.end.y),
            randf_range(bounds.position.z, bounds.end.z)
        )
        attractors.append(p)
    return attractors
```

Points in a volume. Each attractor is a consumable target.

Seed a tree.

```gdscript
class_name SpaceColonizationTree extends Node3D

var nodes: Array = [Vector3.ZERO]  # node positions
var parents: Array = [-1]  # index of parent node, -1 for root
var attractors: Array = []
```

Starts with one node (the root). Grows by adding nodes influenced by attractors.

Find the closest node to each attractor.

```gdscript
func closest_node(attractor: Vector3) -> int:
    var best: int = -1
    var best_dist: float = INF
    for i in nodes.size():
        var d: float = nodes[i].distance_to(attractor)
        if d < best_dist:
            best_dist = d; best = i
    return best
```

Each attractor influences one node — the nearest. Per-attractor cost is O(N).

Grow one step.

```gdscript
@export var influence_radius: float = 2.0
@export var kill_radius: float = 0.3
@export var step_length: float = 0.3

func grow_step() -> bool:
    var influences: Dictionary = {}  # node_index -> average direction
    var kept_attractors: Array = []
    for a in attractors:
        var closest := closest_node(a)
        if closest < 0 or nodes[closest].distance_to(a) > influence_radius:
            kept_attractors.append(a)
            continue
        if nodes[closest].distance_to(a) < kill_radius:
            continue  # consumed
        influences.get_or_add(closest, Vector3.ZERO)
        influences[closest] += (a - nodes[closest]).normalized()
        kept_attractors.append(a)
    attractors = kept_attractors
    if influences.is_empty(): return false
    for node_index in influences:
        var direction: Vector3 = influences[node_index].normalized()
        nodes.append(nodes[node_index] + direction * step_length)
        parents.append(node_index)
    return true
```

Sum influences per node; add a child in the averaged direction. Attractors within kill_radius are consumed.

Render the tree.

```gdscript
func render_tree() -> void:
    for i in nodes.size():
        if parents[i] < 0: continue
        spawn_cylinder_between(nodes[parents[i]], nodes[i])
```

One cylinder per edge. Cheap to render; tree-like structure emerges.

Render with tapered radius.

```gdscript
func node_subtree_size(i: int) -> int:
    var count: int = 1
    for j in parents.size():
        if parents[j] == i:
            count += node_subtree_size(j)
    return count
```

Larger subtree means thicker trunk. Used as an input to the cylinder's radius.

You can now scatter attractors, grow a tree toward them, consume reached attractors, and render the result with tapered branches. PG_Percolation_Network extends into random connectivity.

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
