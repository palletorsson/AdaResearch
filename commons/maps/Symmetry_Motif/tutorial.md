# The Motif

One painted cell decides the whole wall. Before it, the addressable grid must already exist.

Allocate the domain.

```gdscript
@export var tile_size: int = 4
var _grid_data: Array = []

func _initialize_grid_data() -> void:
    _grid_data.clear()
    for y in range(tile_size):
        var row: Array = []
        for x in range(tile_size):
            row.append(_motif_value(x, y))
        _grid_data.append(row)
```

Sixteen integers. Not colours — palette indices. The domain is the smallest thing the pattern cannot do without.

Hand the empty domain an inherited draft.

```gdscript
func _motif_value(x: int, y: int) -> int:
    match motif:
        "checker":
            return 1 if (x + y) % 2 == 0 else 0
        "twill":
            return 1 if ((x + y) % 4) < 2 else 0
        _:
            return 0
```

`blank` returns 0 everywhere and the loom arrives empty. The other drafts are what a textile tradition actually transmits: not the cloth, the instruction for it.

Place one colour by hand.

```gdscript
func set_cell(x: int, y: int, color_idx: int) -> void:
    _grid_data[y][x] = color_idx
    _update_preview()
```

`pattern_tile_cube` is a 4 cm box you pick up and drop into a cell. A pixel is a decision, and this artifact makes you make it.

Read the domain back at any wall coordinate.

```gdscript
func _get_tiled_color(px: int, py: int) -> int:
    var tx: int = px % tile_size
    var ty: int = py % tile_size
    return _grid_data[ty][tx]
```

Modulo is the whole of repetition. Pixel 7 on a size-4 domain is column 3. Nothing is ever stored twice.

Now the floor. Declare the meander's one repeating unit.

```gdscript
const BAND_H := 7
const KEY_W := 8
const KEY_UNIT: Array = [
    [0, 0, 0, 0, 0, 0, 0, 0],
    [1, 1, 1, 1, 1, 1, 0, 1],
    [1, 0, 0, 0, 0, 1, 0, 1],
    [1, 0, 1, 1, 0, 1, 0, 1],
    [1, 0, 1, 0, 0, 1, 0, 1],
    [1, 0, 1, 1, 1, 1, 0, 1],
    [0, 0, 0, 0, 0, 0, 0, 0],
]
```

Column 0 reads `[0,1,1,1,1,1,0]` and so does column 7. The unit abuts itself. That is the only property a Greek key needs.

Run the unit along a side.

```gdscript
func _paint_h_keys(pixels: Array, x0: int, y0: int, length: int, flip: bool) -> void:
    var count: int = length / KEY_W
    for k in range(count):
        for ry in range(BAND_H):
            for rx in range(KEY_W):
                var sy: int = (BAND_H - 1 - ry) if flip else ry
                pixels[y0 + ry][x0 + k * KEY_W + rx] = KEY_UNIT[sy][rx]
```

The top band is the bottom band with `flip` true. Two sides of the border from one bitmap.

Turn the corner.

```gdscript
const CORNER: Array = [
    [0, 0, 0, 0, 0, 0, 0],
    [0, 1, 1, 1, 1, 1, 0],
    [0, 1, 0, 0, 0, 1, 0],
    [0, 1, 0, 1, 1, 1, 0],
    [0, 1, 0, 1, 0, 0, 0],
    [0, 1, 1, 1, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0],
]
```

Three tile types close the border: field, straight, corner. The other three corners are this one rotated.

Render the pixel grid as surfaces.

```gdscript
for py in range(gh):
    for px in range(gw):
        var x: float = px * ps
        var z: float = py * ps
        if pixels[py][px] == 1:
            _add_rect(line_verts, x, z, ps, ps, 0.001)
        else:
            _add_rect(field_verts, x, z, ps, ps, 0.0)
```

One ArrayMesh, one material per colour. Every tessera in the room is a quad, and the whole floor is held in 105 bits of instruction.

You can now allocate a domain, seed it from a draft, edit it a cell at a time, and read it back at any coordinate — and you have seen a two-thousand-year-old border stored as one tileable unit and one corner. Nothing repeats yet. Symmetry_Translation performs the first move.
