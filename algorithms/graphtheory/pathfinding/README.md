# Dijkstra Pathfinding Visualization

Step-by-step animation of Dijkstra's shortest path algorithm — watch the search frontier expand until it finds the goal.

## QFEP Connection

Pathfinding is **F-minimization through exploration**. The algorithm systematically explores possibilities (E, uncertainty) to find the optimal path (F, structure). The frontier represents the boundary between known and unknown — order gradually consuming chaos.

## How It Works

```
Step 1:        Step 10:       Step 20:       Final:
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│ S        │   │ S░░░     │   │ S░░░░░░░ │   │ S████░░░ │
│          │   │ ░░░      │   │ ░░░░░░░░ │   │ ░░██░░░░ │
│   ███    │   │ ░░███    │   │ ░░███░░░ │   │ ░░███░░░ │
│   █      │   │ ░░█░░    │   │ ░░█░░░░░ │   │ ░░█████░ │
│     G    │   │     G    │   │ ░░░░░G░░ │   │ ░░░░░G░░ │
└──────────┘   └──────────┘   └──────────┘   └──────────┘
  Start         Exploring       Near goal      Path found
```

Dijkstra's algorithm:
1. Start at source with distance 0
2. Add neighbors to frontier with their distances
3. Process lowest-distance frontier cell
4. Update neighbor distances if shorter path found
5. Repeat until goal reached

## Parameters

### Grid
| Export | Default | Description |
|--------|---------|-------------|
| `grid_width` | 20 | Cells wide |
| `grid_height` | 20 | Cells tall |
| `cell_size` | 1.0 | World units per cell |
| `obstacle_probability` | 0.3 | Random obstacle density |

### Pathfinding
| Export | Default | Description |
|--------|---------|-------------|
| `start_pos` | (2, 2) | Source cell |
| `goal_pos` | (17, 17) | Target cell |
| `algorithm_speed` | 0.1 | Seconds between steps |
| `animate_search` | true | Show step-by-step |

### Visualization
| Export | Default | Description |
|--------|---------|-------------|
| `show_costs` | true | Display distance values |
| `show_visited_cells` | true | Highlight explored cells |
| `show_frontier` | true | Highlight frontier cells |

## Color Coding

| Color | Meaning |
|-------|---------|
| White | Empty cell |
| Black | Obstacle |
| Green | Start |
| Red | Goal |
| Blue | Visited |
| Yellow | Frontier |
| Cyan | Final path |

## Files

| File | Purpose |
|------|---------|
| `pathfinding_visualization.tscn` | Scene |
| `pathfinding_visualization.gd` | Algorithm and visualization |

## Usage

```gdscript
var pf = preload("res://algorithms/graphtheory/pathfinding/pathfinding_visualization.tscn").instantiate()
pf.algorithm_speed = 0.05  # Faster animation
pf.obstacle_probability = 0.4  # More obstacles
add_child(pf)
```

## Algorithm Complexity

| Metric | Value |
|--------|-------|
| Time | O((V + E) log V) with heap |
| Space | O(V) for distances/previous |

Where V = cells, E = edges (4 per cell for grid).

## VR Experience

Watch the search frontier expand in 3D. The color progression shows the algorithm's "knowledge" spreading from the start. When the frontier reaches the goal, the final path lights up — the shortest route through the obstacles.

## Educational Value

Dijkstra's algorithm teaches:
- **Greedy choices**: Always expand lowest-cost frontier
- **Optimal substructure**: Shortest paths contain shortest paths
- **Priority queues**: Efficient frontier management
- **Graph traversal**: Systematic exploration

## See Also

- `pathfinding/flow_field/` — Field-based pathfinding
- `searchpathfinding/` — Other search algorithms
- `graphtheory/graphspace/` — Graph visualization
