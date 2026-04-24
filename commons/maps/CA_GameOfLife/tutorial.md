# CA Game of Life

Birth, survival, death. Three rules produce infinite variety.

Implement the life-cycle rule.

```gdscript
func game_of_life_rule(alive: bool, neighbours: int) -> bool:
    if alive:
        return neighbours in [2, 3]  # survival
    return neighbours == 3  # birth
```

Two survival counts, one birth count. Every other count produces death.

Seed a glider.

```gdscript
const GLIDER := [
    [0, 1, 0],
    [0, 0, 1],
    [1, 1, 1],
]

func place_pattern(pattern: Array, x: int, y: int) -> void:
    for dy in pattern.size():
        for dx in pattern[0].size():
            var nx: int = (x + dx) % size.x
            var ny: int = (y + dy) % size.y
            grid[ny][nx] = pattern[dy][dx]
```

The glider walks diagonally. Four generations bring it back to the same shape, displaced by one cell.

Seed a glider gun.

```gdscript
const GOSPER_GLIDER_GUN := [
    # 36-wide, 9-tall pattern
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    # ... remaining rows
]
```

A structure that emits a new glider every 30 generations. Proves Conway's Life supports sustained activity.

Count the population.

```gdscript
func population() -> int:
    var count: int = 0
    for row in grid:
        for cell in row:
            if cell == 1: count += 1
    return count
```

Total live cells. Oscillators have periodic populations; gliders have constant populations.

Detect still lifes.

```gdscript
func is_still_life() -> bool:
    var next := step_to(grid.duplicate(true))
    return grids_equal(grid, next)
```

A configuration that doesn't change. Classic examples: block, beehive, loaf, boat.

Detect oscillators.

```gdscript
func is_oscillator(period: int) -> bool:
    var snapshot: Array = []
    for row in grid: snapshot.append(row.duplicate())
    for _i in period:
        step()
    return grids_equal(grid, snapshot)
```

Test whether the grid returns to its starting state after `period` steps. Period 2 catches blinkers; period 3 catches pulsars.

Render a life-and-death visualization.

```gdscript
func render_life_colored() -> void:
    for y in size.y:
        for x in size.x:
            var cell := grid[y][x]
            var age := cell_age[y][x]
            var color := Color.WHITE.lerp(Color.YELLOW, min(age / 20.0, 1.0)) if cell else Color.BLACK
            paint_cell(x, y, color)
```

Newly-born cells are white; older survivors fade toward yellow. The pattern's history becomes visible.

You can now implement Conway's rule, place standard patterns (glider, glider gun), count the population, detect still lifes and oscillators, and render the grid with age-colouring. CA_BeyondBinary extends into multi-state and hex grids.
