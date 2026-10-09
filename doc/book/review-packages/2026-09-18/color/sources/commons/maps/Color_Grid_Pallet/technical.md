# Colour at an address

Pillar evaluated colour at spatial sample positions. Here the same coordinate can receive an explicit edit, then receive a computed value again. The next room, Color_Paint, accumulates strokes.

## The actual implementation

`algorithms/color/gridcolorizer/gridcolorizer.gd` remains the legacy GridColorMutator alias for ordinary placements. Only `#lesson:addresses` activates `address_lesson.gd`, hides the obsolete desktop overlay and disables automatic/global NextCube cycling for this encounter.

The lesson finds its room's GridMultiMesh and GridStructureComponent. It maps each interior floor coordinate to the corresponding instance using `cube_positions`. This matters: the room is rectangular, has stacked boundary walls and omitted cells. A square inferred from instance count does not encode those addresses.

```gdscript
cells[Vector2i(xyz.x, xyz.z)] = i
```

The dictionary includes floor cubes at y=0 with 0<x<18 and 0<z<20. It excludes wall columns on the perimeter. Selection is restricted to x/z 8 through 12; each button wraps that coordinate over five values.

```gdscript
colorizer.multimesh.set_instance_color(cells[selected], INKS[ink_index])
```

COLOUR cycles pink, teal, yellow and white. Reading another cell does not rewrite the previous one. The swatch reads the actual stored instance colour, rather than assuming that the requested value was stored at infinite precision.

```gdscript
var colour_index: int = (address.x + address.y) % palette.size()
colorizer.multimesh.set_instance_color(cells[address], palette[colour_index])
```

Here Vector2i.y represents room z. RULE applies this coordinate-sum assignment to every mapped floor cube. PALETTE selects another existing palette resource and applies the same rule. A single edit is one instance write; a rule pass visits all mapped floor instances. Neither operation changes transforms or collision.

## What this does not implement

There is no ImageTexture palette editor, texture export, palette_changed broadcast, undo stack or saved edit history here. These were generic examples in the former tutorial, not the running artifact. This lesson writes MultiMesh instance colours. Renderer storage has finite precision; focused checks allow a channel error of 1/255 and separately check that only the selected instance changes.

## Verification

`commons/testing/probe_grid_address_lesson.gd` loads the actual museum, emits the real console button signals, inspects buffer writes, checks returning to an address, rule replacement, palette evaluation, preserved geometry, standing reach and a body-sized approach. Tracked-controller pressing and headset comfort require a separate walkthrough.
