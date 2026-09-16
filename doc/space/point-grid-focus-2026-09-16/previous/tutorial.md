# Point Line Grid

Snap continuous motion to a grid. Memory becomes quantised.

Set the grid resolution.

```gdscript
const CELL_SIZE := 0.5

func world_to_cell(pos: Vector3) -> Vector3i:
    return Vector3i(
        int(round(pos.x / CELL_SIZE)),
        int(round(pos.y / CELL_SIZE)),
        int(round(pos.z / CELL_SIZE))
    )

func cell_to_world(cell: Vector3i) -> Vector3:
    return Vector3(cell) * CELL_SIZE
```

`round` snaps to the nearest cell. A cell size of 0.5 means the learner's position maps to a 50cm grid.

Record cells visited.

```gdscript
var visited_cells: Dictionary = {}  # Vector3i -> timestamp

func _process(_delta: float) -> void:
    var cell := world_to_cell(learner.global_position)
    if not cell in visited_cells:
        visited_cells[cell] = Time.get_ticks_msec()
        highlight_cell(cell)
```

The dictionary records the first time each cell was entered. Re-entry doesn't overwrite.

Draw the grid as visible cells.

```gdscript
func highlight_cell(cell: Vector3i) -> void:
    var marker := MARKER_SCENE.instantiate()
    marker.position = cell_to_world(cell)
    marker.modulate = Color(1, 1, 0.3, 0.4)
    add_child(marker)
```

Each visited cell gets a semi-transparent marker. The markers together form a record of where the learner has been.

Show the grid lines only where the learner has walked.

```gdscript
func draw_visited_lines() -> void:
    var visited_list: Array = visited_cells.keys()
    visited_list.sort_custom(func(a, b): return visited_cells[a] < visited_cells[b])
    for i in range(visited_list.size() - 1):
        var a: Vector3 = cell_to_world(visited_list[i])
        var b: Vector3 = cell_to_world(visited_list[i + 1])
        draw_line_segment(a, b)
```

Sort by visit time, then connect in order. The result is a polyline of the learner's quantised path.

Quantise continuous motion into discrete steps.

```gdscript
func quantised_step(from: Vector3, to: Vector3) -> Array:
    var from_cell := world_to_cell(from)
    var to_cell := world_to_cell(to)
    var steps: Array = [from_cell]
    var current := from_cell
    while current != to_cell:
        var diff := to_cell - current
        if abs(diff.x) >= abs(diff.y) and abs(diff.x) >= abs(diff.z):
            current.x += sign(diff.x)
        elif abs(diff.y) >= abs(diff.z):
            current.y += sign(diff.y)
        else:
            current.z += sign(diff.z)
        steps.append(current)
    return steps
```

Bresenham-like stepping from one cell to the next. Each step advances along the axis of greatest remaining distance.

Measure path length in cells.

```gdscript
func path_length_cells(path: Array) -> int:
    return path.size() - 1  # edges between consecutive cells
```

The grid converts continuous distance into a step count. Path length becomes a discrete integer.

You can now snap world positions to a grid, record visited cells, and render the learner's quantised path. Point_Triangle will next close a path into a cycle, introducing the first polygon.
