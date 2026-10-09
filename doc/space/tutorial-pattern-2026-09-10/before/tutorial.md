# Patterns

Rules turn arrays into rhyming data. A small grid tiles into a surface.

Define a rule as a function.

```gdscript
func checkerboard(x: int, y: int) -> int:
    return (x + y) % 2
```

Returns 0 or 1 based on cell coordinates. The classic two-colour pattern.

Populate a grid from a rule.

```gdscript
func populate_grid(size: Vector2i, rule: Callable) -> Array:
    var grid: Array = []
    for y in size.y:
        var row: Array = []
        for x in size.x:
            row.append(rule.call(x, y))
        grid.append(row)
    return grid
```

The rule runs at every cell. The result is a 2D array of palette indices.

Render the grid as a texture.

```gdscript
func grid_to_texture(grid: Array, palette: Array) -> ImageTexture:
    var h := grid.size()
    var w := grid[0].size()
    var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
    for y in h:
        for x in w:
            image.set_pixel(x, y, palette[grid[y][x]])
    return ImageTexture.create_from_image(image)
```

Each cell becomes one pixel. The image can then be applied as a material.

Define a wave rule.

```gdscript
func wave_rule(x: int, y: int) -> int:
    var v: float = sin(x * 0.3) + cos(y * 0.3)
    return int((v + 2.0) * 2) % 4  # maps to palette index 0-3
```

Two sinusoids combine. The result reads as a flowing pattern rather than a discrete grid.

Make a spiral.

```gdscript
func spiral_rule(x: int, y: int, size: Vector2i) -> int:
    var cx = size.x / 2.0; var cy = size.y / 2.0
    var angle: float = atan2(y - cy, x - cx)
    return int((angle + PI) / TAU * 4) % 4
```

The angle from the centre determines the palette index. Four sectors, four colours.

Let the user edit cells directly.

```gdscript
func paint_cell(grid: Array, x: int, y: int, palette_index: int) -> void:
    grid[y][x] = palette_index
```

Direct write. The user's edits override the rule's output.

Tile the grid across a larger surface.

```gdscript
func tiled_color(grid: Array, px: int, py: int, palette: Array) -> Color:
    var h := grid.size()
    var w := grid[0].size()
    return palette[grid[py % h][px % w]]
```

Modulo wraps the coordinate back into the tile. The same 8×8 grid fills an arbitrarily large surface.

You can now write a rule, populate a grid from it, render it as a texture, accept user edits, and tile it across any surface. Array_Patterns extends this with full wallpaper-group symmetries.

Cache the texture for reuse.

```gdscript
var texture_cache: Dictionary = {}

func get_cached_texture(rule_name: String, palette: Array) -> ImageTexture:
    var key: String = rule_name + str(palette)
    if key in texture_cache:
        return texture_cache[key]
    var texture := grid_to_texture(populate_grid(Vector2i(8, 8), rules[rule_name]), palette)
    texture_cache[key] = texture
    return texture
```

Repeated renders of the same rule pull from cache. Useful for tiles that appear in many scenes.
