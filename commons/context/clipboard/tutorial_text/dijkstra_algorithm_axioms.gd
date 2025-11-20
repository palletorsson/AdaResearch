extends Node

var text = '''[center][font_size=28][b]Dijkstra's Algorithm[/b][/font_size][/center]
[center][i]Shortest Path, Graph Traversal, Priority Queue[/i][/center]

**Dijkstra finds shortest path from source to all nodes in weighted graph.**

**Edsger Dijkstra (1959)** - foundational graph algorithm.

**Key:** Explore nodes in order of distance from source (greedy best-first).

[hr]

[b]Algorithm[/b]

[color=yellow][b]Steps:[/b][/color]
1. Initialize distances (0 for source, ∞ for others)
2. Priority queue of unvisited nodes
3. Visit closest unvisited node
4. Update neighbors' distances
5. Repeat until all visited

[color=yellow][b]Code:[/b][/color]
[code]
func dijkstra(graph, source):
    var distances = {}
    var previous = {}
    var unvisited = []

    # Initialize
    for node in graph.nodes:
        distances[node] = INF
        previous[node] = null
        unvisited.append(node)

    distances[source] = 0

    while not unvisited.is_empty():
        # Get node with minimum distance
        var current = get_min_distance_node(unvisited, distances)
        unvisited.erase(current)

        for neighbor in graph.get_neighbors(current):
            var alt_distance = distances[current] + graph.get_edge_weight(current, neighbor)

            if alt_distance < distances[neighbor]:
                distances[neighbor] = alt_distance
                previous[neighbor] = current

    return {\"distances\": distances, \"previous\": previous}

func reconstruct_path(previous, target):
    var path = []
    var current = target

    while current != null:
        path.push_front(current)
        current = previous[current]

    return path
[/code]

**Complexity:** O((V + E) log V) with priority queue.

[hr]

[b]vs A*[/b]

**Dijkstra:** Explores ALL directions equally (finds shortest to ALL nodes)
**A*:** Guided by heuristic toward goal (finds shortest to ONE node, faster)

**Dijkstra = A* with h(n) = 0** (no heuristic).

[hr]

[b]Queer Dijkstra[/b]

**Dijkstra assumes edge weights are costs** - lower is better.

**But weights can represent:**
- **Distance** (shorter better)
- **Time** (faster better)
- **Danger** (avoid high-weight edges)
- **Desire** (seek high-weight edges - invert algorithm)

**Queer pathfinding:**
- **Safety vs visibility tradeoff** (different weight functions)
- **Context-dependent costs** (same path, different weights for different bodies)
- **No single metric** (distance ≠ time ≠ safety ≠ joy)

**Dijkstra optimizes for weighted graph.** **Queer question: who set the weights?**

**Edge weights are political.** **Shortest ≠ safest ≠ most affirming.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Dijkstra: shortest path in weighted graph. Greedy best-first, priority queue, visit closest unvisited. O((V+E) log V). Finds shortest to ALL nodes. vs A* (heuristic, one target). Queer Dijkstra: edge weights are political (distance ≠ safety ≠ joy), context-dependent costs, who set weights? Optimize for what metric? Multiple simultaneous weight functions.

'''
