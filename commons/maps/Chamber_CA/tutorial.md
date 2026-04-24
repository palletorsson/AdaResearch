# Chamber CA

Catalyst fires bursts. Creature's hide is a Game of Life grid.

Build the cellular catalyst.

```gdscript
class_name CellularCatalyst extends Node3D

@export var burst_pattern: Array = [
    [0, 1, 0],
    [1, 1, 1],
    [0, 1, 0],
]

func fire(aim: Vector3) -> void:
    var projectile := CELL_PROJECTILE_SCENE.instantiate()
    projectile.pattern = burst_pattern
    projectile.global_position = global_position
    projectile.linear_velocity = aim * 10.0
    get_tree().root.add_child(projectile)
```

Each projectile carries a small seed pattern. On impact, the pattern stamps onto the creature's hide.

Build the lifeform walker.

```gdscript
class_name LifeformWalker extends CharacterBody3D

@export var hide_size: Vector2i = Vector2i(32, 32)

var hide_grid: Array

func _ready() -> void:
    hide_grid.clear()
    for y in hide_size.y:
        var row: Array = []
        for x in hide_size.x:
            row.append(1 if randf() < 0.2 else 0)
        hide_grid.append(row)
```

The creature's hide is a small Conway grid. Random initialisation at 20% density.

Step the hide.

```gdscript
@export var hide_step_rate: float = 4.0

var time_since_step: float = 0.0

func _process(delta: float) -> void:
    time_since_step += delta
    if time_since_step >= 1.0 / hide_step_rate:
        time_since_step = 0.0
        step_hide()
        update_hide_texture()
```

Four updates per second. The hide's texture visibly evolves on the creature's body.

Stamp a pattern onto the hide.

```gdscript
func stamp_pattern(pattern: Array, at: Vector2i) -> void:
    for dy in pattern.size():
        for dx in pattern[0].size():
            if pattern[dy][dx] == 1:
                var hx: int = (at.x + dx) % hide_size.x
                var hy: int = (at.y + dy) % hide_size.y
                hide_grid[hy][hx] = 1
```

Sets live cells at the impact location. The pattern seeds a new local perturbation in the hide.

Detect a projectile hit.

```gdscript
func _on_body_entered(body: Node) -> void:
    if body.has_meta("pattern"):
        var impact_uv: Vector2 = uv_of_contact(body.global_position)
        var cell: Vector2i = Vector2i(impact_uv * Vector2(hide_size))
        stamp_pattern(body.pattern, cell)
        body.queue_free()
```

Contact triggers a stamp. The projectile is consumed.

Track surviving gliders.

```gdscript
func count_gliders() -> int:
    var count: int = 0
    for y in hide_size.y:
        for x in hide_size.x:
            if is_glider_at(x, y): count += 1
    return count
```

A glider is a specific small pattern. Counting them measures how many perturbations survived.

You can now build a cellular catalyst, stamp patterns onto the lifeform_walker's hide, step the hide at a chosen rate, and count surviving gliders. The Cellular Automata sequence closes with rule-systems in mutual contact.

Reset the grid to random.

```gdscript
func reset_random(density: float = 0.3) -> void:
    for y in size.y:
        for x in size.x:
            grid[y][x] = 1 if randf() < density else 0
```

Useful for exploring the rule's behaviour from different starting conditions.
