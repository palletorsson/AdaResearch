# GT Pathfinding — Technical

The map is a maze whose corridors are graph edges and whose junctions are graph vertices. The learner walks the maze to find the exit, and their walk implicitly executes a pathfinding algorithm. Three explicit algorithm modes — DFS, BFS, and A* — can be toggled at stations along the way, and each mode highlights the maze in a different characteristic pattern.

The `pathfinding3d` artifact exposes A* directly. A* searches the graph with a priority queue ordered by f(n) = g(n) + h(n), where g is the known cost from start to n and h is a heuristic estimate of the cost from n to goal.

```gdscript
func astar(start: Vector3i, goal: Vector3i) -> Array[Vector3i]:
    var open := PriorityQueue.new()
    open.push(start, 0.0)
    var came_from := {}
    var g_score := {start: 0.0}

    while not open.is_empty():
        var current: Vector3i = open.pop()
        if current == goal:
            return reconstruct(came_from, current)
        for nbr in neighbors(current):
            var tentative := g_score[current] + cost(current, nbr)
            if tentative < g_score.get(nbr, INF):
                g_score[nbr] = tentative
                came_from[nbr] = current
                var f := tentative + heuristic_weight * heuristic(nbr, goal)
                open.push(nbr, f)
    return []
```

The heuristic_weight parameter is the map's central control. At 0.0, A* degenerates to Dijkstra — it explores everything uniformly, guaranteed to find the optimal path. At 1.0, A* is standard: it uses the heuristic to focus the search without sacrificing optimality (provided the heuristic is admissible). Above 1.0, A* becomes greedy — it trusts the heuristic completely, potentially missing shorter paths but running faster.

DFS and BFS are simpler. DFS uses a stack and goes deep before wide; its backtrack is visible when the algorithm hits a dead end. BFS uses a queue and explores in concentric waves; its wavefront is visible as the distance-from-start increments. The three modes produce visibly different search patterns on the same maze, and the map lets the learner compare them side by side.

Movement models extend the problem. Ground-walking treats walls as impassable. Flying ignores walls entirely. Climbing treats vertical surfaces as passable. Each mode changes the neighbour function, and the change rewrites what counts as reachable.

Within the sequence, Pathfinding makes the learner's body the search algorithm and uses the body's experience as the ground truth against which the formal algorithms are compared. GT_Network_Analysis will next shift from traversal to measurement.

## Heuristic Design

A* requires an admissible heuristic — one that never overestimates the true cost to the goal. For grid-based pathfinding, the Euclidean distance is always admissible (it is the optimum unconstrained path). The Manhattan distance is admissible when movement is restricted to orthogonal directions. Chebyshev distance is admissible when diagonal movement costs the same as orthogonal.

Choosing the tightest admissible heuristic matters for performance. A* with a perfectly tight heuristic explores only the optimal path — it wastes no work. A* with a loose heuristic degenerates toward Dijkstra. The map's configurable heuristic_weight lets the learner experiment with inadmissible heuristics (weight above 1.0) that are faster but lose the optimality guarantee.

## Data Structures

The open set is a priority queue. A binary heap supports push and pop in O(log n), which is adequate for typical maze sizes. A Fibonacci heap achieves amortised O(1) push and O(log n) pop, theoretically faster, but the constant factors make binary heaps competitive in practice.

The closed set records already-explored vertices. A hash set gives O(1) membership checks. Without the closed set, A* can loop indefinitely on graphs with cycles; with it, A* terminates after at most V vertex expansions.

```gdscript
class PriorityQueue:
    var heap: Array = []

    func push(item, priority: float) -> void:
        heap.append({"item": item, "pri": priority})
        _sift_up(heap.size() - 1)

    func pop():
        var top = heap[0]
        heap[0] = heap.pop_back()
        if heap.size() > 0:
            _sift_down(0)
        return top["item"]
```

Path reconstruction walks the came_from dictionary backward from goal to start, then reverses. The operation is O(path length).

Within the sequence, Pathfinding's algorithms operate on the same graph data structure GT_Foundations introduced. The maze itself is a grid graph where each cell is a vertex and each unblocked wall is an edge.

## One More Note on the Heuristic

Manhattan distance is the default heuristic in grid mazes. It sums the absolute differences along each axis, which is exactly the minimum step count on a grid without diagonals. The map's maze uses four-neighbour connectivity, so Manhattan is admissible and tight.
