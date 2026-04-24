# GT Pathfinding

The maze is a graph. Walk it with DFS, BFS, or A*.

Build a grid graph.

```gdscript
func grid_graph(size: Vector2i) -> Graph:
    var g := Graph.new()
    for y in size.y:
        for x in size.x:
            g.add_vertex(Vector2i(x, y))
    for y in size.y:
        for x in size.x - 1:
            g.add_edge(Vector2i(x, y), Vector2i(x + 1, y))
    for y in size.y - 1:
        for x in size.x:
            g.add_edge(Vector2i(x, y), Vector2i(x, y + 1))
    return g
```

Every cell is a vertex; adjacent cells are connected by edges. The base for maze algorithms.

Remove random edges to form walls.

```gdscript
func remove_walls(g: Graph, remove_ratio: float = 0.3) -> void:
    var to_remove: Array = []
    for edge in g.edges:
        if randf() < remove_ratio:
            to_remove.append(edge)
    for edge in to_remove:
        g.edges.erase(edge)
```

Removing edges creates walls. The maze is the resulting sparse graph.

Depth-first search.

```gdscript
func dfs(g: Graph, start, goal) -> Array:
    var stack: Array = [start]
    var came_from: Dictionary = {start: null}
    while not stack.is_empty():
        var current = stack.pop_back()
        if current == goal: break
        for neighbour in g.neighbours(current):
            if not neighbour in came_from:
                came_from[neighbour] = current
                stack.push_back(neighbour)
    return reconstruct_path(came_from, goal)
```

Stack-based. Goes deep; backtracks on dead ends.

Breadth-first search.

```gdscript
func bfs(g: Graph, start, goal) -> Array:
    var queue: Array = [start]
    var came_from: Dictionary = {start: null}
    while not queue.is_empty():
        var current = queue.pop_front()
        if current == goal: break
        for neighbour in g.neighbours(current):
            if not neighbour in came_from:
                came_from[neighbour] = current
                queue.push_back(neighbour)
    return reconstruct_path(came_from, goal)
```

Queue-based. Explores in concentric waves. Finds the shortest path on unweighted graphs.

Reconstruct a path.

```gdscript
func reconstruct_path(came_from: Dictionary, goal) -> Array:
    var path: Array = []
    var current = goal
    while current != null:
        path.push_front(current)
        current = came_from[current]
    return path
```

Walk backward from goal to start via the came_from dictionary. Reverse order.

A* search.

```gdscript
func astar(g: Graph, start, goal, heuristic: Callable) -> Array:
    var open := PriorityQueue.new()
    open.push(start, 0.0)
    var came_from: Dictionary = {start: null}
    var g_score: Dictionary = {start: 0.0}
    while not open.is_empty():
        var current = open.pop()
        if current == goal: break
        for neighbour in g.neighbours(current):
            var tentative: float = g_score[current] + 1.0
            if tentative < g_score.get(neighbour, INF):
                came_from[neighbour] = current
                g_score[neighbour] = tentative
                var f: float = tentative + heuristic.call(neighbour, goal)
                open.push(neighbour, f)
    return reconstruct_path(came_from, goal)
```

Priority queue orders by estimated total cost. The heuristic focuses the search.

Manhattan distance heuristic.

```gdscript
func manhattan(a: Vector2i, b: Vector2i) -> float:
    return abs(a.x - b.x) + abs(a.y - b.y)
```

Sum of axis-aligned distances. Admissible for 4-connected grids.

You can now build a grid graph, carve walls, implement DFS, BFS, A*, reconstruct paths, and use Manhattan distance as a heuristic. GT_Network_Analysis extends into centrality measures.
