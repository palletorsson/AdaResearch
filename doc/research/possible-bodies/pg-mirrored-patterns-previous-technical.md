# PG Mirrored Patterns — Technical

The map combines cellular automata with mirror symmetry to produce kaleidoscopic textures. A base CA runs on the left half of the grid; the right half mirrors the left after each generation.

```gdscript
class_name MirroredCA extends Node3D

@export var size: Vector2i = Vector2i(64, 64)
var cells: Array = []

func _ready() -> void:
    for y in range(size.y):
        var row: Array = []
        for x in range(size.x):
            row.append(randi() % 2)
        cells.append(row)

func step() -> void:
    var half_width := size.x / 2
    var new_cells: Array = []
    for y in range(size.y):
        var row: Array = []
        for x in range(size.x):
            if x < half_width:
                row.append(ca_rule(x, y))
            else:
                # Mirror from the left half
                row.append(0)  # placeholder, filled in second pass
        new_cells.append(row)
    for y in range(size.y):
        for x in range(half_width, size.x):
            new_cells[y][x] = new_cells[y][size.x - 1 - x]
    cells = new_cells
```

## Symmetry Groups

The wallpaper groups — 17 distinct 2D symmetry groups — classify every possible periodic 2D pattern. The map stages a subset: p1 (translation only), p2 (translation plus 180° rotation), p4m (4-fold rotation plus mirror), p6m (6-fold rotation plus mirror). The CA output is transformed by the chosen group to produce the final pattern.

```gdscript
func apply_p4m(cells: Array) -> Array:
    var size = cells.size()
    var out: Array = []
    for y in range(size):
        out.append([])
        for x in range(size):
            out[y].append(0)
    for y in range(size / 2):
        for x in range(size / 2):
            var v = cells[y][x]
            out[y][x] = v
            out[y][size - 1 - x] = v  # horizontal mirror
            out[size - 1 - y][x] = v  # vertical mirror
            out[size - 1 - y][size - 1 - x] = v  # 180° rotation
    return out
```

## Rhizomatic Mazes

The second station generates a rhizomatic maze — a maze without a canonical root, with multiple paths between cells, and with no privileged direction. The algorithm drops random seed cells and grows passages from each seed independently; where passages meet, they merge.

```gdscript
class_name RhizomaticMaze extends Node

@export var seed_count: int = 8
@export var max_growth: int = 500

var passages: Dictionary = {}  # cell -> set of adjacent open cells

func generate() -> void:
    var seeds: Array = []
    for _i in range(seed_count):
        seeds.append(random_cell())
        passages[seeds[-1]] = {}
    var active := seeds.duplicate()
    var growth_count := 0
    while not active.is_empty() and growth_count < max_growth:
        var cell = active[randi() % active.size()]
        var neighbours := random_unclaimed_neighbours(cell)
        if neighbours.is_empty():
            active.erase(cell)
            continue
        var next = neighbours[randi() % neighbours.size()]
        connect_cells(cell, next)
        active.append(next)
        growth_count += 1
```

## Complexity

The symmetric CA is O(N²) per generation for an N×N grid. The rhizomatic maze is O(growth_count) per generation — essentially linear in the number of cells carved. Both are interactive at the grid sizes the map uses (typically 64×64).

Within the sequence, Mirrored_Patterns closes Procedural Generation with the argument that symmetry and rhizomatic growth are two tools that produce structure without authored design. The sequence hands the learner forward with a generative vocabulary that spans evolution, connectivity, growth, subtraction, accumulation, and symmetry.

## Anti-Aliasing

Symmetric patterns often show aliasing artifacts at the symmetry axes — the pixels right at the mirror line look different from their neighbours because they are directly reflected rather than being interpolated. A half-pixel offset on the mirror operation corrects this: the mirror point is placed between two pixels rather than on a single pixel.

```gdscript
func mirror_h_offset(cells: Array) -> Array:
    var size = cells.size()
    var half = size / 2
    var out: Array = []
    for y in range(size):
        out.append([])
        for x in range(size):
            if x < half:
                out[y].append(cells[y][x])
            else:
                # Mirror across x = half - 0.5
                out[y].append(cells[y][2 * half - 1 - x])
    return out
```

## Frieze Groups

The 17 wallpaper groups classify 2D periodic patterns. There are also seven frieze groups, which classify patterns that repeat along one axis (borders and stripes). The map implements a subset of wallpaper groups (p1, p2, p4m, p6m) but a full implementation would include all seventeen.

## Rhizomatic Maze Algorithm Details

The rhizomatic maze grows from multiple seeds rather than from a single root. Each seed is effectively a separate recursive-backtracker search, and when two searches' passages touch, they merge into a shared region. The merging is the non-hierarchical feature: a cell in the resulting maze can be reached from multiple seeds via different paths.

```gdscript
var cell_seed: Dictionary = {}  # cell -> seed index

func grow_rhizome() -> void:
    var active_seeds: Array = seeds.duplicate()
    while not active_seeds.is_empty():
        for i in range(active_seeds.size() - 1, -1, -1):
            var seed_cell = active_seeds[i]
            var growth = random_unclaimed_neighbour(seed_cell)
            if growth == null:
                active_seeds.remove_at(i)
            else:
                cell_seed[growth] = cell_seed[seed_cell]
                connect(seed_cell, growth)
                active_seeds[i] = growth
```

## Performance

Symmetric CA is faster than a full CA because only half the cells need to be computed; the rest are copied by mirror. The map exploits this to run larger grids at the same frame rate. For a 256×256 mirrored grid, only the 128×256 left half is updated per step.

The rhizomatic maze completes in O(N) steps for N cells, same as recursive backtracking, but with a larger constant factor because of the merging bookkeeping. At 64×64, generation is imperceptible; at 256×256 it takes a few frames to complete.
