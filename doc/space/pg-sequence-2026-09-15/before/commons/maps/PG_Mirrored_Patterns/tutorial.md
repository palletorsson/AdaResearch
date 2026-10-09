# PG Mirrored Patterns

Mirror a cellular automaton. Symmetry amplifies pattern.

Run a 2D CA.

```gdscript
@export var size: Vector2i = Vector2i(64, 64)
var grid: Array = []

func initialise() -> void:
    grid.clear()
    for y in size.y:
        var row: Array = []
        for x in size.x:
            row.append(randi_range(0, 1))
        grid.append(row)
```

Start with random binary values. Subsequent updates depend on the CA rule.

Apply a simple rule.

```gdscript
func ca_step() -> void:
    var new_grid: Array = []
    for y in size.y:
        var row: Array = []
        for x in size.x:
            var count: int = neighbour_count(x, y)
            var alive: bool = grid[y][x] == 1
            var new_state: int = 0
            if alive and (count == 2 or count == 3): new_state = 1
            elif not alive and count == 3: new_state = 1
            row.append(new_state)
        new_grid.append(row)
    grid = new_grid
```

Conway's Game of Life rules. Could be replaced by any CA.

Mirror horizontally.

```gdscript
func mirror_horizontal() -> void:
    var half: int = size.x / 2
    for y in size.y:
        for x in range(half):
            grid[y][size.x - 1 - x] = grid[y][x]
```

Copy the left half onto the right in reverse. The right half becomes the mirror of the left.

Mirror in both axes.

```gdscript
func mirror_both() -> void:
    mirror_horizontal()
    var half: int = size.y / 2
    for y in range(half):
        for x in size.x:
            grid[size.y - 1 - y][x] = grid[y][x]
```

Horizontal and vertical. The full grid becomes a 4-fold symmetric kaleidoscope.

Apply rotational symmetry.

```gdscript
func apply_rotational(steps: int = 4) -> void:
    var base: Array = []
    for y in size.y: base.append(grid[y].duplicate())
    for step in range(1, steps):
        var angle: float = step * TAU / steps
        for y in size.y:
            for x in size.x:
                var cx: float = size.x / 2.0; var cy: float = size.y / 2.0
                var rx: int = int(cx + cos(-angle) * (x - cx) - sin(-angle) * (y - cy))
                var ry: int = int(cy + sin(-angle) * (x - cx) + cos(-angle) * (y - cy))
                if rx >= 0 and rx < size.x and ry >= 0 and ry < size.y:
                    grid[y][x] = grid[y][x] or base[ry][rx]
```

Rotate the base grid; OR it onto itself. Four-fold rotation produces kaleidoscopic symmetry.

Grow a rhizomatic maze.

```gdscript
class_name RhizomaticMaze

var passages: Dictionary = {}  # cell -> set of adjacent open cells

func grow_from_seed(seed: Vector2i, max_cells: int) -> void:
    var active: Array = [seed]
    passages[seed] = {}
    var count: int = 0
    while not active.is_empty() and count < max_cells:
        var cell: Vector2i = active[randi() % active.size()]
        var next: Vector2i = random_unclaimed_neighbour(cell)
        if next == Vector2i(-1, -1):
            active.erase(cell)
            continue
        passages[cell][next] = true
        passages[next] = {cell: true}
        active.append(next)
        count += 1
```

Multiple seeds produce a non-hierarchical maze. Passages merge where seed territories meet.

You can now run a 2D CA, mirror horizontally, rotate for 4-fold symmetry, and grow a rhizomatic maze from multiple seeds. Chamber_ProcGen extends into the bricoleur encounter.
