# Chamber CA — Technical

The chamber puts two cellular automata in contact: the learner's cellular catalyst seeds patterns into the lifeform_walker's Game-of-Life hide.

## Cellular Catalyst

```gdscript
class_name CellularCatalyst extends Node3D

@export var seed_pattern: Array = [
    [0, 1, 0],
    [0, 0, 1],
    [1, 1, 1],
]  # glider

func fire(aim_direction: Vector3) -> void:
    var projectile := CA_PROJECTILE_SCENE.instantiate()
    projectile.seed_pattern = seed_pattern
    projectile.global_position = global_position
    projectile.linear_velocity = aim_direction * 8.0
    get_tree().root.add_child(projectile)
```

## Lifeform Walker

The creature's hide is a live 2D Conway's Game of Life grid. When a catalyst projectile hits, the projectile's seed pattern is stamped onto the hide at the impact point.

```gdscript
class_name LifeformWalker extends CharacterBody3D

@export var hide_size: Vector2i = Vector2i(32, 32)

var hide_grid: Array  # 2D array of bool
var next_gen: Array

func _ready() -> void:
    hide_grid = []
    for y in range(hide_size.y):
        hide_grid.append([])
        for x in range(hide_size.x):
            hide_grid[y].append(randf() < 0.2)
    next_gen = hide_grid.duplicate(true)

@export var generation_interval: float = 0.2
var time_since_gen: float = 0.0

func _process(delta: float) -> void:
    time_since_gen += delta
    if time_since_gen >= generation_interval:
        time_since_gen = 0.0
        step_game_of_life()
        update_hide_texture()

func step_game_of_life() -> void:
    for y in range(hide_size.y):
        for x in range(hide_size.x):
            var neighbours := count_live_neighbours(x, y)
            var alive: bool = hide_grid[y][x]
            if alive:
                next_gen[y][x] = (neighbours == 2 or neighbours == 3)
            else:
                next_gen[y][x] = (neighbours == 3)
    var temp = hide_grid
    hide_grid = next_gen
    next_gen = temp

func count_live_neighbours(x: int, y: int) -> int:
    var count := 0
    for dy in range(-1, 2):
        for dx in range(-1, 2):
            if dx == 0 and dy == 0: continue
            var nx: int = (x + dx + hide_size.x) % hide_size.x
            var ny: int = (y + dy + hide_size.y) % hide_size.y
            if hide_grid[ny][nx]: count += 1
    return count

func stamp_pattern(pattern: Array, at: Vector2i) -> void:
    for dy in range(pattern.size()):
        for dx in range(pattern[dy].size()):
            var tx: int = (at.x + dx) % hide_size.x
            var ty: int = (at.y + dy) % hide_size.y
            if pattern[dy][dx] == 1:
                hide_grid[ty][tx] = true
```

## Hide Rendering

The hide is rendered as a shader-sampled texture. Live cells appear as lighter pixels; dead cells as darker.

```gdscript
func update_hide_texture() -> void:
    var image := Image.create(hide_size.x, hide_size.y, false, Image.FORMAT_RGBA8)
    for y in range(hide_size.y):
        for x in range(hide_size.x):
            var c: Color = Color.WHITE if hide_grid[y][x] else Color(0.1, 0.1, 0.1)
            image.set_pixel(x, y, c)
    hide_texture = ImageTexture.create_from_image(image)
```

## Science Screen

The screen shows both grids side by side: catalyst's current pattern and creature's current hide. Surviving gliders are highlighted.

## Complexity

Game of Life step is O(W·H) per generation. At 32×32 grid and 5 Hz update rate, that is 5120 cell updates per second — trivial.

## Within the Sequence

Chamber_CA closes Cellular Automata with rule systems meeting rule systems. The chamber hands the learner back with the cellular catalyst in their kit.

## Save State Integration

The chamber's progress is tracked via the save manager. Befriending a creature, completing a configuration, or reaching a milestone is recorded in the learner's profile and becomes available in subsequent sessions.

```gdscript
func on_befriend_event(creature_name: String) -> void:
    var save = get_tree().get_first_node_in_group("save_manager")
    save.add_befriended_creature(creature_name)
    save.mark_milestone(chamber_id + "_befriended", Time.get_datetime_string_from_system())
```

## Performance Budget

The chamber's per-frame cost is dominated by creature animations and the science screen's rendering. Both are modest: the creature uses a vertex-displacement shader or a prebuilt animation, and the science screen redraws scatter points incrementally rather than from scratch each frame.

```gdscript
func _process(_delta: float) -> void:
    if science_screen.needs_redraw():
        science_screen.redraw_incremental()
```

## VR Comfort

The chamber avoids fast camera moves and sudden lighting changes. Projectiles fire from the learner's hand rather than from fixed spawners, so the learner controls the motion. The chamber's lighting is stable across the encounter; any changes happen gradually through creature state transitions.

## Accessibility

The chamber supports seated play: all interactive elements are within arm's reach, and the projectile direction is controllable from a single hand. The creature responds to either controller, so handedness is not a barrier.

## Within the Curriculum

This chamber is one of the curriculum's catalyst chambers — small, self-contained rooms where the sequence's accumulated vocabulary becomes relationship with a creature. The pattern is consistent across sequences: creature, catalyst (or its deliberate absence), science screen, return to Lab.
