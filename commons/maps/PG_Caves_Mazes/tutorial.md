# PG Caves Mazes

Carve spaces. Two methods. Cave via CA; maze via spanning tree.

Generate a CA-based cave.

```gdscript
func generate_cave(size: Vector2i, fill_prob: float = 0.45, iterations: int = 5) -> Array:
    var grid: Array = []
    for y in size.y:
        var row: Array = []
        for x in size.x:
            row.append(randf() < fill_prob)
        grid.append(row)
    for _i in iterations:
        grid = smooth_step(grid, size)
    return grid
```

Start with random fill; smooth via cellular automaton rules.

Smooth one step.

```gdscript
func smooth_step(grid: Array, size: Vector2i) -> Array:
    var new_grid: Array = []
    for y in size.y:
        var row: Array = []
        for x in size.x:
            var neighbour_count: int = count_wall_neighbours(grid, x, y, size)
            if neighbour_count >= 5:
                row.append(true)
            elif neighbour_count <= 3:
                row.append(false)
            else:
                row.append(grid[y][x])
        new_grid.append(row)
    return new_grid
```

Classic 5-4 rule. Cells with 5+ wall neighbours become walls; cells with 3 or fewer become open.

Count neighbours.

```gdscript
func count_wall_neighbours(grid: Array, x: int, y: int, size: Vector2i) -> int:
    var count: int = 0
    for dy in [-1, 0, 1]:
        for dx in [-1, 0, 1]:
            if dx == 0 and dy == 0: continue
            var nx: int = x + dx
            var ny: int = y + dy
            if nx < 0 or nx >= size.x or ny < 0 or ny >= size.y:
                count += 1  # treat out-of-bounds as wall
            elif grid[ny][nx]:
                count += 1
    return count
```

Eight neighbours. Boundary conditions treat off-grid as wall (so caves don't open at the edges).

Recursive backtracker maze.

```gdscript
func generate_maze(size: Vector2i) -> Array:
    var visited: Array = []
    for y in size.y:
        var row: Array = []
        for x in size.x: row.append(false)
        visited.append(row)
    var walls_carved: Array = []
    var stack: Array = [Vector2i(0, 0)]
    visited[0][0] = true
    while not stack.is_empty():
        var current: Vector2i = stack[-1]
        var neighbours := unvisited_neighbours(current, visited, size)
        if neighbours.is_empty():
            stack.pop_back()
        else:
            var next: Vector2i = neighbours[randi() % neighbours.size()]
            walls_carved.append([current, next])
            visited[next.y][next.x] = true
            stack.append(next)
    return walls_carved
```

Stack-based DFS. Carves a spanning tree; result is always a perfectly connected maze.

Render walls.

```gdscript
func render_walls(walls_carved: Array, size: Vector2i, scale: float = 1.0) -> void:
    for y in size.y:
        for x in size.x:
            for direction in [Vector2i(1, 0), Vector2i(0, 1)]:
                var neighbour := Vector2i(x, y) + direction
                if neighbour.x >= size.x or neighbour.y >= size.y: continue
                if not [Vector2i(x, y), neighbour] in walls_carved and not [neighbour, Vector2i(x, y)] in walls_carved:
                    spawn_wall_between(Vector2i(x, y), neighbour, scale)
```

Walls are edges not carved. Each uncarved edge becomes a visual wall.

Braid a maze.

```gdscript
func braid(walls_carved: Array, cells_with_few_connections: Array, probability: float = 0.3) -> void:
    for cell in cells_with_few_connections:
        if randf() < probability:
            var new_carve := pick_random_uncarved_neighbour(cell)
            if new_carve: walls_carved.append([cell, new_carve])
```

Removes some dead ends. Creates loops. Less punishing navigation.

You can now generate a CA-based cave, a spanning-tree maze, render walls, and braid the maze for loops. PG_Sculpted_Forms extends into additive architectural generation.
