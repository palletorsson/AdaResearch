# Four Machines, One Grid

Four ways to make a pattern, standing in a row. Each machine is a different function from cell coordinates to color — that is the entire secret of the hall.

The loom thinks in threads — a cell shows warp or weft by a rule on its coordinates:

```gdscript
func weave(x: int, y: int) -> Color:
    var over := (x + y * 2) % 4 < 2      # the tie-up: which thread is on top
    return WARP_COLOR if over else WEFT_COLOR
```

Change the modulus and offset and you have twill, satin, plain weave — centuries of textile structure are small integer arithmetic on `(x, y)`.

The print head thinks in stamps — one motif, repeated by translation:

```gdscript
func stamp(x: int, y: int, motif: Array, w: int, h: int) -> Color:
    return motif[(y % h) * w + (x % w)]   # tile the motif by wrapping
```

`%` is the whole technology of wallpaper: coordinates fold back into the motif's little rectangle, so one drawing covers an infinite wall.

The mill thinks in symmetry — it draws one wedge and turns it:

```gdscript
func rotate_cell(x: int, y: int, cx: int, cy: int, times: int) -> Vector2i:
    var p := Vector2i(x - cx, y - cy)
    for i in times:
        p = Vector2i(-p.y, p.x)           # 90° per turn
    return p + Vector2i(cx, cy)

func mill(x: int, y: int) -> Color:
    var sector := wedge_of(x, y)          # which quarter am I in?
    var src := rotate_cell(x, y, CX, CY, sector)
    return base_pattern(src.x, src.y)     # everyone reads from wedge zero
```

Paint one quarter; symmetry manufactures the rest. The wallpaper groups from the pattern editors are exactly this with fancier turn-and-flip sets.

The sequencer thinks in time — the same row over and over, but *when* becomes *where*:

```gdscript
func sequence(x: int, t: float) -> Color:
    var playhead := int(t * 8.0) % WIDTH
    return ACTIVE if x == playhead else pattern_row(x)
```

Try: feed all four machines the same 8×8 motif. Four materially different objects come out — cloth, wallpaper, rosette, rhythm — from one small grid of choices. The pattern was never the picture. It was the rule, and each machine is a different way of *performing* it.
