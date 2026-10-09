# Patterns

Paint sixteen cells and watch them multiply into a floor.

Define the tile grid.

```gdscript
var tile_size := 4
var grid: Array = []

func _initialize_grid_data() -> void:
    grid.clear()
    for y in tile_size:
        var row: Array = []
        for x in tile_size:
            row.append(0)
        grid.append(row)
```

`grid[y][x]` — row first, column second. The outer index is the row; the inner index is the column.

Paint one cell.

```gdscript
func set_cell(x: int, y: int, color_idx: int) -> void:
    grid[y][x] = color_idx
```

`color_idx` is a palette slot, not a Color object. The palette lives separately; the grid stores only integers.

Read the color at any pixel position using modulo.

```gdscript
func get_tiled_color(px: int, py: int) -> int:
    return grid[py % tile_size][px % tile_size]
```

Modulo wraps the coordinate back into the tile. Pixel 7 on a size-4 tile is column 3. The pattern extends infinitely; the array stays small.

Mirror the left half onto the right.

```gdscript
func mirror_x() -> void:
    for y in tile_size:
        for x in range(tile_size / 2):
            grid[y][tile_size - 1 - x] = grid[y][x]
```

Paint the left two columns; the tile completes itself. Kaleidoscope symmetry from eight painted cells.

Add the vertical axis.

```gdscript
func mirror_xy() -> void:
    mirror_x()
    for y in range(tile_size / 2):
        for x in tile_size:
            grid[tile_size - 1 - y][x] = grid[y][x]
```

Four-fold symmetry from four painted cells. P4M — the wallpaper group of bathroom tiles, Islamic geometric panels, Celtic knotwork.

Shift alternate rows by half a tile for brick offset.

```gdscript
func get_brick_color(px: int, py: int) -> int:
    var tile_row: int = py / tile_size
    var offset: int = (tile_row % 2) * (tile_size / 2)
    return grid[py % tile_size][(px + offset) % tile_size]
```

Every second row shifts by half the tile width. Load-bearing masonry has used this rule for four thousand years — here it is two lines of integer arithmetic.

Transpose alternating blocks for herringbone.

```gdscript
func get_herringbone_color(px: int, py: int) -> int:
    var bx: int = px / tile_size
    var by_: int = py / tile_size
    var lx: int = px % tile_size
    var ly: int = py % tile_size
    if (bx + by_) % 2 == 0:
        return grid[ly][lx]
    else:
        return grid[lx][ly]
```

Alternating blocks swap their x and y indices. The woven diagonal emerges from a single transposition — herringbone is the same pattern read in two directions.

Assign a wallpaper group to the puzzle node.

```gdscript
@export var wallpaper_group: WallpaperGroups.Group = WallpaperGroups.Group.P4M
@export var repeat_mode: PatternTilePuzzle.RepeatMode = PatternTilePuzzle.RepeatMode.WALLPAPER
@export var symmetry_mode: PatternTilePuzzle.SymmetryMode = PatternTilePuzzle.SymmetryMode.MIRROR
```

The 17 wallpaper groups are the complete classification of all possible plane symmetries. Proven in 1891. Every textile tradition discovered subsets of them independently.

Analyze any painted grid to identify its symmetry group.

```gdscript
var analyzer := TilingAnalyzer.new()
var result: Dictionary = analyzer.analyze(grid, tile_size, tile_size)
print("Group: ", result.get("group", "unknown"))
print("Period: ", result.get("period", Vector2i.ZERO))
```

The analyzer checks for rotational and mirror axes using the standard classification flowchart. It reads back what symmetry a pattern already has — whether or not the painter intended it.

Configure the VR tile editor to generate a live floor carpet.

```gdscript
@export var tile_size: int = 4
@export var repeat_mode: int = 1
@export var carpet_size: Vector2 = Vector2(3.0, 3.0)
@export var carpet_repeats: Vector2i = Vector2i(8, 8)
@export var carpet_offset: Vector3 = Vector3(0.0, 0.0, -1.5)
```

Scale `carpet_repeats` up: the same 16-cell tile becomes a room. The array does not change; only the number of times it is read changes.

Wire cell edits to the carpet update.

```gdscript
func _on_cell_changed(_x: int, _y: int, _color_index: int) -> void:
    _update_carpet_texture()
```

Every brushstroke propagates to the floor in a single frame. The tile and the carpet are the same 2D array at different scales — one written, one read.

Select a palette for the tiling system.

```gdscript
func set_colors(
        palette: PackedStringArray,
        warp_pat: PackedInt32Array,
        weft_pat: PackedInt32Array) -> void:
    # called on DraftDataStore for loom-based patterns
    pass
```

In the loom simulator, color encodes thread: `warp_pat` and `weft_pat` determine which thread is on top at each crossing. The drawdown recomputes automatically — the same grid logic, but now reading fabric structure instead of floor tiles.

You can now index a 2D grid by row and column, tile it across any surface with modulo, apply mirror and rotation symmetry, identify any painted pattern's wallpaper group, and propagate edits from a small tile to a large floor in real time. The 16 cells you painted encode the same mathematics that weavers compressed into thread for three thousand years.