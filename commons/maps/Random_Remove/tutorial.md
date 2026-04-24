# Random Remove

Randomness deletes. Build the 8x8 arena where stochastic selection removes cubes and exposes the distribution.

Declare the remover.

```gdscript
class_name RemoveRandom
extends Node3D

enum Mode { RANGE, COLUMN, ROW, ALL }

@export var mode: Mode = Mode.RANGE
@export var size: Vector2i = Vector2i(8, 8)
```

Four modes, one rectangular grid. The mode selects how the random pick happens.

Populate the grid.

```gdscript
func populate() -> void:
    for x in size.x:
        for y in size.y:
            var cube := preload("res://commons/artifacts/randomness/grid_cube.tscn").instantiate()
            cube.position = Vector3(x, 0, y)
            add_child(cube)
            cubes[Vector2i(x, y)] = cube
```

64 cubes arranged in the 8x8. Each cube is indexed by its grid position. Removal targets the index.

Remove by range.

```gdscript
func remove_range(count: int) -> void:
    var keys := cubes.keys()
    keys.shuffle()
    for i in min(count, keys.size()):
        _drop_cube(keys[i])
```

Shuffled keys produce uniform selection without replacement. Drop lowers the cube through the floor and frees it.

Remove by column.

```gdscript
func remove_column() -> void:
    var x := randi() % size.x
    for y in size.y:
        _drop_cube(Vector2i(x, y))
```

A random column disappears wholesale. The strip is always size.y cubes. The learner sees a single axis as a unit.

Remove by row.

```gdscript
func remove_row() -> void:
    var y := randi() % size.y
    for x in size.x:
        _drop_cube(Vector2i(x, y))
```

Same mechanic, different axis. Rows and columns together demonstrate that random choice can select either coordinate.

Remove all at once.

```gdscript
func remove_all() -> void:
    for key in cubes.keys():
        _drop_cube(key)
```

Every cube drops simultaneously. The arena empties. The moment is a demonstration of what total removal looks like.

Animate the drop.

```gdscript
func _drop_cube(key: Vector2i) -> void:
    if not cubes.has(key): return
    var cube: Node3D = cubes[key]
    var tween := create_tween()
    tween.tween_property(cube, "position:y", -3.0, 0.6)
    tween.tween_callback(cube.queue_free)
    cubes.erase(key)
```

Each cube falls for 0.6 seconds and frees. The sequence becomes a readable cascade rather than a silent delete.

Log the distribution.

```gdscript
func log_removed(key: Vector2i) -> void:
    removal_log.append({"x": key.x, "y": key.y, "mode": mode})
```

The log captures where and how. Later the learner can plot the removals and see the spread their mode produced.

You have seen randomness as subtraction. The next map, 10 PRINT, turns it generative.
<<</MAP>>>

Undo the last removal.

```gdscript
func undo_last() -> void:
    if removal_log.is_empty(): return
    var last: Dictionary = removal_log.pop_back()
    _respawn_cube(Vector2i(last.x, last.y))
```

The last removed cube respawns at its old position. The learner can rewind a step at a time.
