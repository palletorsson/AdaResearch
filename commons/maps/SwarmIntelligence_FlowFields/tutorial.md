# Flow Fields

Precompute directions across a grid. Agents follow the field.

Build a 2D vector field.

```gdscript
@export var grid_size: Vector2i = Vector2i(32, 32)
var field: Array = []  # 2D array of Vector2

func initialise_field() -> void:
    for y in grid_size.y:
        field.append([])
        for x in grid_size.x:
            field[y].append(Vector2.ZERO)
```

Each cell stores a direction. Agents sample the field at their position.

Compute a radial field.

```gdscript
func compute_radial_field(centre: Vector2i) -> void:
    for y in grid_size.y:
        for x in grid_size.x:
            var direction: Vector2 = Vector2(centre.x - x, centre.y - y)
            if direction.length() > 0:
                field[y][x] = direction.normalized()
```

Every cell points toward the centre. Agents released into this field converge.

Compute a Dijkstra field.

```gdscript
func compute_dijkstra_field(goal: Vector2i, is_passable: Callable) -> void:
    var distance: Array = []
    for y in grid_size.y:
        distance.append([])
        for x in grid_size.x:
            distance[y].append(INF)
    distance[goal.y][goal.x] = 0
    var queue: Array = [goal]
    while not queue.is_empty():
        var current: Vector2i = queue.pop_front()
        for neighbour in get_neighbours(current):
            if not is_passable.call(neighbour): continue
            var new_dist: float = distance[current.y][current.x] + 1
            if new_dist < distance[neighbour.y][neighbour.x]:
                distance[neighbour.y][neighbour.x] = new_dist
                queue.push_back(neighbour)
    for y in grid_size.y:
        for x in grid_size.x:
            field[y][x] = steepest_descent(x, y, distance)
```

BFS-based. The field points agents toward the nearest goal along the shortest walkable path.

Find steepest descent.

```gdscript
func steepest_descent(x: int, y: int, distance: Array) -> Vector2:
    var best := Vector2.ZERO
    var best_dist: float = distance[y][x]
    for dy in [-1, 0, 1]:
        for dx in [-1, 0, 1]:
            if dx == 0 and dy == 0: continue
            var nx: int = x + dx; var ny: int = y + dy
            if nx < 0 or nx >= grid_size.x or ny < 0 or ny >= grid_size.y: continue
            if distance[ny][nx] < best_dist:
                best_dist = distance[ny][nx]; best = Vector2(dx, dy)
    return best.normalized()
```

Search neighbours for the cell with lowest distance. Field direction points there.

Sample the field for an agent.

```gdscript
func sample_field(position: Vector2) -> Vector2:
    var x: int = clamp(int(position.x), 0, grid_size.x - 1)
    var y: int = clamp(int(position.y), 0, grid_size.y - 1)
    return field[y][x]
```

Direct cell lookup. For smoother motion, bilinear interpolation between four corners.

Agents follow the field.

```gdscript
func _physics_process(delta: float) -> void:
    for agent in agents:
        var force: Vector2 = sample_field(agent.position) * 2.0
        agent.velocity += force * delta
        agent.velocity = agent.velocity.limit_length(3.0)
        agent.position += agent.velocity * delta
```

Apply field force; cap velocity; move. The agent traces a path along the field.

You can now build a 2D flow field, compute radial and Dijkstra variants, and steer agents through it. SwarmIntelligence_Boids_Algorithm extends into reynolds flocking.
