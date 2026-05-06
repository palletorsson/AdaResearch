# Tutorial Pattern — Technical

Four tile stations compute colours from cell coordinates. Each station exposes a rule, and the rule's output populates a small 2D array that is rendered as a texture.

```gdscript
class_name PatternTile extends Node3D

@export var size: Vector2i = Vector2i(8, 8)
@export var rule: String = "checkerboard"
@export var palette: Array = [Color.BLACK, Color.WHITE, Color(0.9, 0.5, 0.2), Color(0.2, 0.5, 0.9)]

var grid: Array = []  # 2D array of palette indices

func regenerate() -> void:
    grid.clear()
    for y in range(size.y):
        var row: Array = []
        for x in range(size.x):
            row.append(rule_value(x, y))
        grid.append(row)
    update_texture()

func rule_value(x: int, y: int) -> int:
    match rule:
        "checkerboard": return (x + y) % 2
        "stripes": return y % 2
        "wave": return int(sin(x * 0.3) * 2 + 2) % palette.size()
        "radial": return int(Vector2(x - size.x/2, y - size.y/2).length()) % palette.size()
    return 0
```

## Texture Update

The grid is written to an Image, which is pushed to an ImageTexture for rendering. Updating the texture is O(W·H); at 8×8 the cost is negligible.

```gdscript
func update_texture() -> void:
    var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
    for y in range(size.y):
        for x in range(size.x):
            image.set_pixel(x, y, palette[grid[y][x]])
    texture = ImageTexture.create_from_image(image)
```

## Tiling Preview

A large preview board tiles the 8×8 pattern across a much bigger surface. The tiling uses UV coordinates with wrapping enabled.

```gdscript
# Shader UV wrapping
uniform sampler2D tile_texture : repeat_enable;

void fragment() {
    vec2 tiled_uv = UV * vec2(TILE_REPEAT_X, TILE_REPEAT_Y);
    ALBEDO = texture(tile_texture, tiled_uv).rgb;
}
```

## Symmetry Modes

A toggle switches between direct tiling and mirrored tiling. Mirror mode flips alternate tiles horizontally and/or vertically.

```gdscript
// Shader mirror mode
void fragment() {
    vec2 tile_uv = fract(UV * TILE_REPEAT);
    vec2 tile_idx = floor(UV * TILE_REPEAT);
    if (mod(tile_idx.x, 2.0) == 1.0) tile_uv.x = 1.0 - tile_uv.x;
    if (mod(tile_idx.y, 2.0) == 1.0) tile_uv.y = 1.0 - tile_uv.y;
    ALBEDO = texture(tile_texture, tile_uv).rgb;
}
```

## Custom Rule Parser

The fourth station exposes the rule as an editable expression. A small parser converts the expression string into a function the grid can evaluate.

```gdscript
class_name RuleExpression

var expression: String = "(x + y) % 2"

func evaluate(x: int, y: int) -> int:
    var expr := Expression.new()
    var error := expr.parse(expression, ["x", "y"])
    if error != OK: return 0
    var result = expr.execute([x, y])
    if expr.has_execute_failed(): return 0
    return int(result)
```

Godot's built-in Expression class handles parsing and evaluation for simple arithmetic expressions, which is adequate for teaching rule composition.

## Complexity

Rule evaluation is O(1) per cell; full regeneration is O(W·H). At typical tile sizes (up to 16×16) the regeneration is imperceptible even when driven by slider movement.

Within the sequence, Tutorial_Pattern is the pivot from addressing to rhyming. Array_Patterns will next push the technique into wallpaper-group symmetries.

## Palette Storage

Palettes are stored as arrays of Color. The array's length is the palette size; indices into the array reference specific colours. This indirection — cell value is an index, not a colour — allows the palette to be retoned without touching cell data.

```gdscript
var palette: Array[Color] = [Color.BLACK, Color.WHITE, Color(0.9, 0.3, 0.3), Color(0.3, 0.5, 0.9)]

func retone_palette(new_palette: Array[Color]) -> void:
    palette = new_palette
    regenerate()  # re-draw the grid with the new palette
```

## Common Rule Library

A library of built-in rules gives the learner starting points. Each rule takes (x, y) cell coordinates and returns a palette index.

```gdscript
const RULE_LIBRARY := {
    "checkerboard": func(x, y): return (x + y) % 2,
    "diagonal_stripes": func(x, y): return (x + y) % 4 / 2,
    "grid_intersection": func(x, y): return 1 if (x % 3 == 0 or y % 3 == 0) else 0,
    "spiral": func(x, y):
        var cx = size.x / 2
        var cy = size.y / 2
        var angle = atan2(y - cy, x - cx)
        return int((angle + PI) / TAU * palette.size()) % palette.size(),
}
```

## Shader-Based Version

For large tiles or complex rules, a shader-based version runs the rule per-pixel on the GPU. The shader's fragment function takes UV coordinates and returns a colour.

```glsl
void fragment() {
    vec2 cell = floor(UV * tile_size);
    float rule_value = mod(cell.x + cell.y, 2.0);
    ALBEDO = mix(palette[0].rgb, palette[1].rgb, rule_value);
}
```

The shader can evaluate the rule at sub-pixel resolution, producing anti-aliased edges for free.

## Interactive Tile Editing

A fourth mode lets the learner paint cells manually. Each cell is clickable; clicking cycles through palette indices.

```gdscript
func _on_cell_clicked(x: int, y: int) -> void:
    grid[y][x] = (grid[y][x] + 1) % palette.size()
    update_texture()
```

The painted pattern is also tiled across the preview board — the learner's hand-made patterns enter the same compositional frame as the rule-generated ones.
