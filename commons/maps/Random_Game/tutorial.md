# Random Game

The floor itself is probabilistic. Build the 8x8 arena where falling cubes and origami enemies make randomness gameplay.

Declare the game grid.

```gdscript
class_name RandomGameGrid
extends Node3D

@export var size: Vector2i = Vector2i(8, 8)
@export var sink_period_range: Vector2 = Vector2(2.0, 8.0)
```

Eight by eight floor. Each tile has its own sink period in the given range. No tile shares a cycle.

Populate the tiles.

```gdscript
func populate_tiles() -> void:
    for x in size.x:
        for y in size.y:
            var tile := preload("res://commons/artifacts/randomness/game_tile.tscn").instantiate()
            tile.position = Vector3(x, 0, y)
            tile.sink_period = randf_range(sink_period_range.x, sink_period_range.y)
            tile.phase_offset = randf() * TAU
            add_child(tile)
```

Each tile gets a period and a phase. The grid becomes an incoherent field of independent oscillators.

Sink the tiles on schedule.

```gdscript
func update_tile(tile: Node3D, t: float) -> void:
    var value := sin(TAU * t / tile.sink_period + tile.phase_offset)
    tile.position.y = -0.5 if value < 0.0 else 0.0
```

Sine drives the sink state. When the sine is negative, the tile drops. The player must read each tile's rhythm separately.

Detect falls.

```gdscript
func check_player_footing(player: Node3D) -> bool:
    var cell := _world_to_cell(player.position)
    var tile: Node3D = tiles.get(cell)
    if tile and tile.position.y < -0.1:
        return false
    return true
```

If the tile under the player is sunk, footing fails. The game triggers a reset or a life loss.

Spawn origami enemies.

```gdscript
func spawn_origami(count: int) -> void:
    for i in count:
        var fold := preload("res://commons/artifacts/randomness/origami_fold.tscn").instantiate()
        fold.position = Vector3(randf_range(0, size.x - 1), 0, randf_range(0, size.y - 1))
        fold.next_move_delay = randf_range(0.5, 2.0)
        add_child(fold)
```

Origami enemies unfold across cells with random delays. Movement is discrete; timing is stochastic.

Move an origami.

```gdscript
func step_origami(fold: Node3D, dt: float) -> void:
    fold.timer += dt
    if fold.timer < fold.next_move_delay: return
    fold.timer = 0.0
    fold.next_move_delay = randf_range(0.5, 2.0)
    fold.position += Vector3(randi_range(-1, 1), 0, randi_range(-1, 1))
```

Random direction, random delay. The enemy is never where the player predicts.

Score survival in ticks.

```gdscript
func on_tick(dt: float) -> void:
    if check_player_footing(player):
        score += dt
    score_label.text = "%.1f s" % score
```

The longer the player survives, the higher the score. The game rewards randomness-reading over route-memorising.

Reset on defeat.

```gdscript
func reset_game() -> void:
    score = 0.0
    for tile in tiles.values():
        tile.phase_offset = randf() * TAU
    for fold in folds:
        fold.position = Vector3(randf_range(0, 8), 0, randf_range(0, 8))
```

A reset reseeds phases and positions. No run is ever the same.

You have played inside randomness. The next map, Chamber Random, closes the sequence as a catalyst encounter.
<<</MAP>>>
