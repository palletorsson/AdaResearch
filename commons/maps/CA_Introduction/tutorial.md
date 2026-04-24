# CA Introduction

A grid of cells. Each cell reads its neighbours. All update at once.

Build a 2D grid.

```gdscript
@export var size: Vector2i = Vector2i(32, 32)
var grid: Array = []

func initialise_random() -> void:
    grid.clear()
    for y in size.y:
        var row: Array = []
        for x in size.x:
            row.append(1 if randf() < 0.3 else 0)
        grid.append(row)
```

Each cell is 0 or 1. Random initialisation with 30% live density.

Count Moore neighbourhood.

```gdscript
func count_neighbours(x: int, y: int) -> int:
    var count: int = 0
    for dy in [-1, 0, 1]:
        for dx in [-1, 0, 1]:
            if dx == 0 and dy == 0: continue
            var nx: int = (x + dx + size.x) % size.x
            var ny: int = (y + dy + size.y) % size.y
            count += grid[ny][nx]
    return count
```

Eight neighbours, periodic boundaries. The wrap-around lets patterns flow across the edges.

Apply a rule.

```gdscript
func apply_rule(alive: bool, neighbours: int) -> bool:
    if alive:
        return neighbours == 2 or neighbours == 3
    return neighbours == 3
```

Conway's Game of Life. Live cells survive with 2 or 3 neighbours; dead cells revive with exactly 3.

Step the grid.

```gdscript
func step() -> void:
    var new_grid: Array = []
    for y in size.y:
        var row: Array = []
        for x in size.x:
            var alive: bool = grid[y][x] == 1
            var count: int = count_neighbours(x, y)
            row.append(1 if apply_rule(alive, count) else 0)
        new_grid.append(row)
    grid = new_grid
```

Build a new grid from the old. The two must be separate — updating in place would corrupt the neighbour counts.

Render as a texture.

```gdscript
func to_texture() -> ImageTexture:
    var image := Image.create(size.x, size.y, false, Image.FORMAT_L8)
    for y in size.y:
        for x in size.x:
            image.set_pixel(x, y, Color.WHITE if grid[y][x] else Color.BLACK)
    return ImageTexture.create_from_image(image)
```

Greyscale. One pixel per cell, sampled nearest-neighbour for a pixelated look.

Animate the steps.

```gdscript
@export var steps_per_second: float = 10.0

var time_since_step: float = 0.0

func _process(delta: float) -> void:
    time_since_step += delta
    if time_since_step >= 1.0 / steps_per_second:
        time_since_step = 0.0
        step()
        update_texture()
```

Ten steps per second. Fast enough to show evolution; slow enough to watch structures form.

Seed a glider.

```gdscript
func seed_glider(x: int, y: int) -> void:
    var pattern := [[0, 1, 0], [0, 0, 1], [1, 1, 1]]
    for dy in pattern.size():
        for dx in pattern[0].size():
            grid[(y + dy) % size.y][(x + dx) % size.x] = pattern[dy][dx]
```

A specific starting pattern. The glider walks across the grid at one cell per four generations.

You can now build a 2D grid, count neighbours, apply Conway's rule, step and render, animate updates, and seed specific patterns. CA_ElementaryRules extends into 1D automata.
