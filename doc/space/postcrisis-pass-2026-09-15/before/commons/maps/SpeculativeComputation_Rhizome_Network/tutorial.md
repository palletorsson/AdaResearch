# Rhizome Network

No root. No trunk. No privileged path.

Build a cave system where any chamber connects to any other.

Declare a node set.

```gdscript
class_name RhizomeNode
extends Node3D

@export var id: String = ""
@export var neighbors: Array[String] = []
```

Each node is a Node3D with an id and a neighbour list.

No parent field. No depth. No rank.

Build the network.

```gdscript
func build_network(ids: Array[String]) -> void:
    for id in ids:
        var n := RhizomeNode.new()
        n.id = id
        nodes[id] = n
        add_child(n)
```

Every id becomes a node. The nodes exist as siblings under the same parent. Nothing is a root.

Connect any two nodes.

```gdscript
func connect_nodes(a: String, b: String) -> void:
    if a == b: return
    if not nodes[a].neighbors.has(b):
        nodes[a].neighbors.append(b)
    if not nodes[b].neighbors.has(a):
        nodes[b].neighbors.append(a)
```

Connections are bidirectional. The edge is not owned by either endpoint. The rhizome is a relation, not a possession.

Draw the edges.

```gdscript
func draw_edges(immediate: MeshInstance3D) -> void:
    var mesh := ImmediateMesh.new()
    mesh.surface_begin(Mesh.PRIMITIVE_LINES)
    for id in nodes:
        for n_id in nodes[id].neighbors:
            mesh.surface_add_vertex(nodes[id].global_position)
            mesh.surface_add_vertex(nodes[n_id].global_position)
    mesh.surface_end()
    immediate.mesh = mesh
```

Edges are pure line segments. No arrowheads, no weights, no hierarchy. The visual grammar refuses to name a direction.

Compute reachability without spanning tree.

```gdscript
func reachable_from(start: String) -> Array[String]:
    var seen: Array[String] = [start]
    var frontier: Array[String] = [start]
    while not frontier.is_empty():
        var here := frontier.pop_back()
        for n_id in nodes[here].neighbors:
            if not seen.has(n_id):
                seen.append(n_id)
                frontier.append(n_id)
    return seen
```

Flood fill, not BFS tree. The function returns the set of reachable ids without implying an order. Any start point is a centre, which means none is.

Walk the rhizome from the player.

```gdscript
func step_from(here: String, target: String) -> String:
    for n_id in nodes[here].neighbors:
        if n_id == target: return n_id
    return nodes[here].neighbors.pick_random()
```

If the target is adjacent, go to it. Otherwise, pick any neighbour. The walk is not a plan; it is a traversal that accepts non-hierarchy.

Colour-code chambers by their degree.

```gdscript
func color_by_degree() -> void:
    for id in nodes:
        var d: int = nodes[id].neighbors.size()
        var t: float = clamp(d / 6.0, 0.0, 1.0)
        tint_chamber(nodes[id], Color(1.0, 1.0 - t, 0.4))
```

Degree replaces rank. High-degree chambers glow warmer, not because they are important but because they are more connected. Connectedness is a property, not a privilege.

You have built a cave system that grows the way thought should. The next map, Lab Equipment Simulation, returns to formalization with the rhizome carried as a lesson.
