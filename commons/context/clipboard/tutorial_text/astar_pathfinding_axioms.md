**A* Pathfinding**
Optimal Paths, Heuristics, Graph Search

**A* finds shortest path from start to goal using heuristic guidance.**

**Formula:** f(n) = g(n) + h(n)
- **g(n)** = cost from start to node n (actual distance traveled)
- **h(n)** = estimated cost from n to goal (heuristic)
- **f(n)** = total estimated cost (priority for exploration)

---

## Algorithm

**Code:**

```
func astar(start, goal, graph):
    var open_set =   # Nodes to explore
    var came_from = {}  # Path reconstruction
    var g_score = {start: 0}  # Cost from start
    var f_score = {start: heuristic(start, goal)}  # Estimated total

    while not open_set.is_empty():
        var current = get_lowest_f_score(open_set, f_score)

        if current == goal:
            return reconstruct_path(came_from, current)

        open_set.erase(current)

        for neighbor in graph.get_neighbors(current):
            var tentative_g = g_score + distance(current, neighbor)

            if tentative_g < g_score.get(neighbor, INF):
                came_from = current
                g_score = tentative_g
                f_score = tentative_g + heuristic(neighbor, goal)

                if neighbor not in open_set:
                    open_set.append(neighbor)

    return []  # No path found

func heuristic(node, goal):
    # Manhattan distance for grid, Euclidean for free space
    return abs(node.x - goal.x) + abs(node.y - goal.y)
```

**Optimal:** Finds shortest path if heuristic is **admissible** (never overestimates).

---

## Heuristics

**Manhattan:** |x₁-x₂| + |y₁-y₂| (grid, 4-directional)
**Euclidean:** √[(x₁-x₂)² + (y₁-y₂)²] (straight line)
**Diagonal:** max(|x₁-x₂|, |y₁-y₂|) (grid, 8-directional)

**Better heuristic → faster search** (explores fewer nodes).

---

## Queer A*

**A* assumes single optimal path** - one