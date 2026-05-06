# 2D Build

Two indices, one grid. Row-major traversal made physical.

Build the 4×4 grid.

```gdscript
const GRID_SIZE := Vector2i(4, 4)

func build_grid() -> void:
    for y in GRID_SIZE.y:
        for x in GRID_SIZE.x:
            var cell := CELL_SCENE.instantiate()
            cell.position = Vector3(x, 0, y)
            cell.set_meta("coords", Vector2i(x, y))
            cell.get_node("Label").text = "(%d, %d)" % [y, x]
            add_child(cell)
```

Each cell shows its (row, column) coordinates. Note the label order: row first, column second.

Highlight a row.

```gdscript
func highlight_row(row: int) -> void:
    for child in get_children():
        if child.has_meta("coords"):
            var c: Vector2i = child.get_meta("coords")
            child.modulate = Color.YELLOW if c.y == row else Color.WHITE
```

Metadata lookup finds each cell's row; colour changes accordingly.

Highlight a column.

```gdscript
func highlight_column(col: int) -> void:
    for child in get_children():
        if child.has_meta("coords"):
            var c: Vector2i = child.get_meta("coords")
            child.modulate = Color.CYAN if c.x == col else Color.WHITE
```

Same pattern, different index. Row and column helpers are symmetric operations.

Spawn a grid agent.

```gdscript
class_name GridAgent extends CharacterBody3D

var visit_sequence: Array = []
var current_index: int = 0
var step_interval: float = 0.4

func _ready() -> void:
    for y in GRID_SIZE.y:
        for x in GRID_SIZE.x:
            visit_sequence.append(Vector2i(x, y))
```

Row-major order. The agent visits (0,0), (1,0), (2,0), (3,0), (0,1), ... in sequence.

Step the agent.

```gdscript
var time_since_step: float = 0.0

func _process(delta: float) -> void:
    time_since_step += delta
    if time_since_step >= step_interval:
        time_since_step = 0.0
        current_index = (current_index + 1) % visit_sequence.size()
        var coords = visit_sequence[current_index]
        global_position = Vector3(coords.x, 0.5, coords.y)
```

Discrete movement between cells every 0.4 seconds. The learner watches the agent thread through the grid.

Switch traversal order.

```gdscript
enum Order { ROW_MAJOR, COLUMN_MAJOR, DIAGONAL }

func rebuild_sequence(order: Order) -> void:
    visit_sequence.clear()
    match order:
        Order.ROW_MAJOR:
            for y in GRID_SIZE.y:
                for x in GRID_SIZE.x:
                    visit_sequence.append(Vector2i(x, y))
        Order.COLUMN_MAJOR:
            for x in GRID_SIZE.x:
                for y in GRID_SIZE.y:
                    visit_sequence.append(Vector2i(x, y))
        Order.DIAGONAL:
            for d in range(GRID_SIZE.x + GRID_SIZE.y - 1):
                for x in range(max(0, d - GRID_SIZE.y + 1), min(d + 1, GRID_SIZE.x)):
                    visit_sequence.append(Vector2i(x, d - x))
```

Each order produces a different traversal pattern. The learner sees which pattern each order traces.

Convert coordinates to a flat array index.

```gdscript
func flat_index(coords: Vector2i) -> int:
    return coords.y * GRID_SIZE.x + coords.x
```

Row-major flattening. Coord (2, 1) in a 4×4 grid maps to flat index 6.

You can now build a 2D grid, highlight rows and columns, run a grid agent through programmatic traversal, and convert between 2D coordinates and a 1D flat index. Tutorial_3D extends into three dimensions.
