# Tutorial 2D Build — Technical

The grid is a flat 4×4 plane; each cell is labelled with its (row, column) indices. Two helpers expose row and column operations, and a grid agent performs programmatic traversal.

```gdscript
class_name Grid2D extends Node3D

@export var size: Vector2i = Vector2i(4, 4)
@export var cell_size: float = 1.0

var cell_nodes: Array = []  # 2D array of cell Node3Ds

func _ready() -> void:
    for y in range(size.y):
        var row: Array = []
        for x in range(size.x):
            var cell := create_cell(x, y)
            row.append(cell)
        cell_nodes.append(row)

func create_cell(x: int, y: int) -> Node3D:
    var cell := GRID_CELL_SCENE.instantiate()
    cell.position = Vector3(x, 0, y) * cell_size
    cell.get_node("Label").text = "(%d, %d)" % [y, x]
    add_child(cell)
    return cell
```

## Row Helper

Pressing the row helper highlights every cell in a selected row.

```gdscript
class_name RowHelper extends Node3D

@export var grid: Grid2D
var selected_row: int = 0

func highlight_row(row_index: int) -> void:
    for y in range(grid.size.y):
        for x in range(grid.size.x):
            var highlight: bool = (y == row_index)
            grid.cell_nodes[y][x].set_highlight(highlight)
    selected_row = row_index

func _on_cycle_button_pressed() -> void:
    selected_row = (selected_row + 1) % grid.size.y
    highlight_row(selected_row)
```

## Column Helper

Analogous to the row helper but operates on the x axis.

## Grid Agent

The grid agent follows a traversal order and visits every cell. Three modes are available: row-major, column-major, and diagonal.

```gdscript
class_name GridAgent extends CharacterBody3D

@export var grid: Grid2D
@export var step_interval: float = 0.5
@export var order: String = "row_major"

var visit_sequence: Array = []
var current_index: int = 0
var time_since_step: float = 0.0

func _ready() -> void:
    build_sequence()

func build_sequence() -> void:
    visit_sequence.clear()
    match order:
        "row_major":
            for y in range(grid.size.y):
                for x in range(grid.size.x):
                    visit_sequence.append(Vector2i(x, y))
        "column_major":
            for x in range(grid.size.x):
                for y in range(grid.size.y):
                    visit_sequence.append(Vector2i(x, y))
        "diagonal":
            for d in range(grid.size.x + grid.size.y - 1):
                for x in range(max(0, d - grid.size.y + 1), min(d + 1, grid.size.x)):
                    visit_sequence.append(Vector2i(x, d - x))

func _process(delta: float) -> void:
    time_since_step += delta
    if time_since_step >= step_interval:
        time_since_step = 0.0
        current_index = (current_index + 1) % visit_sequence.size()
        move_to_cell(visit_sequence[current_index])
```

## Complexity

Grid setup is O(W·H). Helpers are O(W·H) per highlight update. Agent traversal is O(1) per step with a precomputed sequence of length W·H.

Within the sequence, Tutorial_2D_Build introduces the coordinate pair. Tutorial_3D will next add the third dimension.

## Cell Identity

Each cell is a small Area3D with its coordinates stored as metadata. The Area3D's `body_entered` signal connects to a handler that updates the currently-highlighted cell.

```gdscript
class_name GridCell extends Area3D

@export var coordinates: Vector2i

signal learner_entered(coords: Vector2i)

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("learner"):
        learner_entered.emit(coordinates)
```

## Helper Cycling

Each helper has a button that advances through row or column indices. Holding the button triggers auto-advance at a fixed rate.

```gdscript
class_name IndexHelper extends Node3D

@export var max_index: int = 4
@export var auto_advance_rate: float = 2.0  # indices per second

var current_index: int = 0
var button_held: bool = false
var time_since_advance: float = 0.0

func _process(delta: float) -> void:
    if not button_held: return
    time_since_advance += delta
    if time_since_advance >= 1.0 / auto_advance_rate:
        time_since_advance = 0.0
        advance()

func advance() -> void:
    current_index = (current_index + 1) % max_index
    emit_signal("index_changed", current_index)
```

## Highlight Rendering

Highlighted cells render with an emission-on shader material. The highlight fades in and out smoothly rather than snapping on.

```glsl
shader_type spatial;
uniform float highlight_strength : hint_range(0.0, 1.0);
uniform vec3 base_color;
uniform vec3 highlight_color;

void fragment() {
    vec3 final_color = mix(base_color, highlight_color, highlight_strength);
    ALBEDO = final_color;
    EMISSION = highlight_color * highlight_strength * 0.3;
}
```

## Agent Movement Smoothing

The grid agent's movement uses ease-in-out interpolation between cells rather than linear movement. The smoothing makes the traversal feel deliberate rather than robotic.

```gdscript
func _process(delta: float) -> void:
    time_since_step += delta
    var t: float = clamp(time_since_step / step_interval, 0.0, 1.0)
    var eased_t: float = ease(t, 0.5)  # ease-in-out
    global_position = last_cell_position.lerp(next_cell_position, eased_t)
```

## Accessibility

The map supports keyboard-only navigation for learners who cannot use VR. Arrow keys move the highlighted selection, Enter invokes the helper, and Tab switches between helpers and agent.
## Save State

The agent's traversal and helper selections do not persist across sessions. The map is a calibration for 2D indexing intuition; persistence is unnecessary.