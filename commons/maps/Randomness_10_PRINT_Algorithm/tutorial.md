# 10 PRINT Algorithm

One coin flip per cell, infinite visual structure. Build the maze from the simplest random choice.

Declare the maze grid.

```gdscript
class_name TenPrintMaze
extends Node3D

@export var rows: int = 20
@export var cols: int = 20
@export var cell_size: float = 0.4
```

Three numbers. Two for extent, one for cell size. The algorithm needs nothing else.

Flip a cell.

```gdscript
func flip_cell() -> String:
    if randi() % 2 == 0:
        return "/"
    return "\\"
```

A single coin flip returns one of two slashes. The entire maze grammar is this function.

Spawn the slash.

```gdscript
func spawn_slash(x: int, y: int, kind: String) -> void:
    var scene := preload("res://commons/artifacts/randomness/maze_slash.tscn")
    var slash := scene.instantiate()
    slash.position = Vector3(x * cell_size, 0.0, y * cell_size)
    slash.rotation.y = deg_to_rad(45.0 if kind == "/" else -45.0)
    add_child(slash)
```

Each cell gets a diagonal bar. The two rotations produce the two slashes. The mesh is one plank used twice.

Build the full maze.

```gdscript
func build_maze() -> void:
    for x in cols:
        for y in rows:
            spawn_slash(x, y, flip_cell())
```

400 cells, 400 flips, 400 bars. The maze completes in one frame.

Animate the build.

```gdscript
func animate_build() -> void:
    var i := 0
    while i < cols * rows:
        var x := i % cols
        var y := i / cols
        spawn_slash(x, y, flip_cell())
        i += 1
        await get_tree().create_timer(0.01).timeout
```

A coroutine paces the build. The learner watches the maze emerge one cell at a time. Emergence is performed.

Reseed to replay.

```gdscript
func reseed(new_seed: int) -> void:
    seed(new_seed)
    _clear()
    build_maze()
```

A new seed gives a new maze. The learner can compare two mazes drawn from two seeds.

Measure path length.

```gdscript
func count_paths_hint() -> int:
    return cols * rows
```

The maze always has as many segments as cells. Path lengths and connections vary by seed. Counting is left as a small exercise.

Overlay a grid for reference.

```gdscript
func draw_grid() -> void:
    for x in cols + 1:
        grid_lines.add_line(Vector3(x * cell_size, 0, 0), Vector3(x * cell_size, 0, rows * cell_size))
    for y in rows + 1:
        grid_lines.add_line(Vector3(0, 0, y * cell_size), Vector3(cols * cell_size, 0, y * cell_size))
```

A faint grid underlies the slashes. The coin flip becomes visible as choice over structure.

You have generated infinite pattern from one flip. The next map, Random Cubes, turns randomness onto objects.
<<</MAP>>>

Expose the flip bias.

```gdscript
func set_bias(p: float) -> void:
    bias = clamp(p, 0.0, 1.0)

func flip_cell_biased() -> String:
    return "/" if randf() < bias else "\\"
```

A bias slider tilts the coin. At 0.5 the maze is symmetric. At the extremes the maze degenerates into a single diagonal.
