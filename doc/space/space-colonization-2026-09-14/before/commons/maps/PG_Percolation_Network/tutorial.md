# PG Percolation Network

Random grid. At the threshold, a spanning cluster forms.

Generate a random grid.

```gdscript
const GRID_SIZE := Vector2i(64, 64)

func generate_grid(probability: float) -> Array:
    var grid: Array = []
    for y in GRID_SIZE.y:
        var row: Array = []
        for x in GRID_SIZE.x:
            row.append(randf() < probability)
        grid.append(row)
    return grid
```

Each cell occupied with the given probability. The grid is 2D boolean.

Find clusters via flood fill.

```gdscript
func find_clusters(grid: Array) -> Array:
    var cluster_id: Array = []
    for y in GRID_SIZE.y:
        cluster_id.append([])
        for x in GRID_SIZE.x:
            cluster_id[y].append(-1)
    var next_id: int = 0
    for y in GRID_SIZE.y:
        for x in GRID_SIZE.x:
            if grid[y][x] and cluster_id[y][x] < 0:
                flood_fill(grid, cluster_id, x, y, next_id)
                next_id += 1
    return cluster_id
```

Each cluster gets a unique ID. Unoccupied cells stay at -1.

Flood-fill one cluster.

```gdscript
func flood_fill(grid: Array, cluster_id: Array, x0: int, y0: int, id: int) -> void:
    var stack: Array = [[x0, y0]]
    while not stack.is_empty():
        var p = stack.pop_back()
        if p[0] < 0 or p[0] >= GRID_SIZE.x: continue
        if p[1] < 0 or p[1] >= GRID_SIZE.y: continue
        if not grid[p[1]][p[0]] or cluster_id[p[1]][p[0]] >= 0: continue
        cluster_id[p[1]][p[0]] = id
        stack.append([p[0] + 1, p[1]])
        stack.append([p[0] - 1, p[1]])
        stack.append([p[0], p[1] + 1])
        stack.append([p[0], p[1] - 1])
    # Iterative to avoid stack overflow on large clusters
```

Iterative flood fill. Each cell is visited at most once.

Test for spanning cluster.

```gdscript
func has_spanning_cluster(cluster_id: Array) -> bool:
    var top_clusters: Dictionary = {}
    for x in GRID_SIZE.x:
        if cluster_id[0][x] >= 0:
            top_clusters[cluster_id[0][x]] = true
    for x in GRID_SIZE.x:
        if cluster_id[GRID_SIZE.y - 1][x] in top_clusters:
            return true
    return false
```

Spanning means a cluster touches both the top row and the bottom row. Probabilities around 0.59 are the threshold for 2D square site percolation.

Colour cells by cluster.

```gdscript
func colour_clusters(cluster_id: Array) -> void:
    for y in GRID_SIZE.y:
        for x in GRID_SIZE.x:
            if cluster_id[y][x] >= 0:
                var hue: float = float(cluster_id[y][x] * 31 % 100) / 100.0
                paint_cell(x, y, Color.from_hsv(hue, 0.8, 0.9))
```

Each cluster a different hue. Spanning clusters are visible because they reach across the grid.

Animate the threshold sweep.

```gdscript
func animate_threshold(start_p: float, end_p: float, steps: int) -> void:
    for i in steps:
        var p: float = lerp(start_p, end_p, float(i) / steps)
        var grid: Array = generate_grid(p)
        var cluster_id: Array = find_clusters(grid)
        colour_clusters(cluster_id)
        await get_tree().create_timer(0.2).timeout
```

Sweep p from start to end. The spanning threshold appears as a visible phase transition.

You can now generate a random grid, find clusters via flood fill, detect spanning clusters, colour them, and animate the threshold sweep. PG_Branching_Growth extends into rule-based vs noise-driven branching.
