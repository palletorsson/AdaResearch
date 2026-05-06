# Point Lines

Build a grid of points. Connect each to its grid neighbours.

Declare the grid dimensions.

```gdscript
const GRID_SIZE := Vector2i(8, 8)
const SPACING := 1.0
```

An 8-by-8 grid with unit spacing gives 64 points and 112 edges.

Spawn the points.

```gdscript
var points: Array = []  # 2D array of Node3D

func spawn_grid() -> void:
    for y in GRID_SIZE.y:
        var row: Array = []
        for x in GRID_SIZE.x:
            var p := spawn_point_at(Vector3(x, 0, y) * SPACING)
            row.append(p)
        points.append(row)
```

Each point is a small mesh at a grid coordinate. The 2D array `points[y][x]` holds them by row.

Connect horizontal neighbours.

```gdscript
func connect_horizontal() -> void:
    for y in GRID_SIZE.y:
        for x in range(GRID_SIZE.x - 1):
            draw_line(points[y][x].position, points[y][x + 1].position)
```

`x - 1` so the inner loop stops before the last column. Each iteration draws the edge between column x and column x+1.

Connect vertical neighbours.

```gdscript
func connect_vertical() -> void:
    for y in range(GRID_SIZE.y - 1):
        for x in GRID_SIZE.x:
            draw_line(points[y][x].position, points[y + 1][x].position)
```

Same pattern for the other axis. After both passes, every interior point has four edges; corner points have two; edge points have three.

Move a point and update its lines.

```gdscript
func move_point(coords: Vector2i, new_pos: Vector3) -> void:
    points[coords.y][coords.x].position = new_pos
    redraw_edges_touching(coords)
```

The grid is no longer rectangular once a point moves. The adjacency structure persists.

Add diagonal connections.

```gdscript
func connect_diagonal() -> void:
    for y in range(GRID_SIZE.y - 1):
        for x in range(GRID_SIZE.x - 1):
            draw_line(points[y][x].position, points[y + 1][x + 1].position)
```

Diagonals add 49 edges to the 112 horizontal and vertical ones. The grid becomes a triangulation.

Count the graph's vertices and edges.

```gdscript
func graph_stats() -> Dictionary:
    var V: int = GRID_SIZE.x * GRID_SIZE.y
    var E: int = (GRID_SIZE.x - 1) * GRID_SIZE.y + (GRID_SIZE.y - 1) * GRID_SIZE.x
    return {"vertices": V, "edges": E}
```

V = 64, E = 112 for horizontal plus vertical. Euler's formula V - E + F = 2 (for planar graphs) lets you check the face count without enumerating.

You can now build a grid of points and connect them by adjacency. Point_Trace will next turn the learner's motion into a line that persists.

Find a point's closest grid neighbour.

```gdscript
func closest_grid_neighbour(p: Vector3) -> Vector2i:
    var best := Vector2i(0, 0)
    var best_dist: float = INF
    for y in GRID_SIZE.y:
        for x in GRID_SIZE.x:
            var d: float = p.distance_to(points[y][x].position)
            if d < best_dist:
                best_dist = d; best = Vector2i(x, y)
    return best
```

Brute-force O(W·H) search. For larger grids, spatial indexing accelerates this to O(log).

Query the degree of a grid vertex.

```gdscript
func vertex_degree(coords: Vector2i) -> int:
    var degree := 0
    if coords.x > 0: degree += 1
    if coords.x < GRID_SIZE.x - 1: degree += 1
    if coords.y > 0: degree += 1
    if coords.y < GRID_SIZE.y - 1: degree += 1
    return degree
```

Interior vertices have degree 4. Edge vertices have 3. Corner vertices have 2.
